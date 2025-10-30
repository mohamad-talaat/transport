
// ✅ Firebase v2 modular imports
const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

setGlobalOptions({ maxInstances: 10 });

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * 📨 إرسال إشعار FCM مع صوت
 */
async function sendFCMNotification(userId, title, body, type = "general", data = {}) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.error(`❌ User not found: ${userId}`);
      return false;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    if (!fcmToken) {
      console.error(`❌ No FCM token for user: ${userId}`);
      return false;
    }

    let soundFile = "default";
    let channelId = "general_notifications";
    let priority = "default";

    if (["new_trip", "driver_arrived", "trip_accepted"].includes(type)) {
      soundFile = "notification";
      channelId = "critical_notifications";
      priority = "high";
    } else if (type === "chat") {
      soundFile = "message";
      channelId = "chat_notifications";
      priority = "high";
    }

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: {
        ...data,
        type,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        notification: {
          channelId,
          priority,
          sound: soundFile,
          defaultSound: false,
        },
        priority,
      },
      apns: {
        payload: {
          aps: {
            sound: `${soundFile}.mp3`,
            badge: 1,
            "content-available": 1,
          },
        },
      },
    };

    const response = await messaging.send(message);
    console.log(`✅ إشعار مرسل: ${response}`);

    await db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .add({
        title,
        body,
        type,
        data,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });

    return true;
  } catch (error) {
    console.error(`❌ Error sending notification:`, error);
    return false;
  }
}

/**
 * 🚗 تغيير حالة الرحلة
 */
exports.onTripStatusChanged = onDocumentUpdated("trips/{tripId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === after.status) return null;

  const { tripId } = event.params;
  const {
    riderId,
    driverId,
    status,
    driverName,
    riderName,
    pickupAddress,
    destinationAddress,
    fare,
  } = after;

  try {
    switch (status) {
      case "accepted":
        await sendFCMNotification(
          riderId,
          "🚗 تم العثور على سائق!",
          `السائق ${driverName} في الطريق إليك`,
          "trip_accepted",
          { tripId, action: "open_tracking" }
        );
        break;

      case "driverArrived":
        await sendFCMNotification(
          riderId,
          "✅ السائق وصل!",
          `${driverName} ينتظرك عند ${pickupAddress}`,
          "driver_arrived",
          { tripId, action: "driver_arrived" }
        );
        break;

      case "started":
        await sendFCMNotification(
          riderId,
          "🚀 بدأت رحلتك",
          `أنت في الطريق إلى ${destinationAddress}`,
          "trip_started",
          { tripId, action: "open_tracking" }
        );
        break;

      case "completed":
        await sendFCMNotification(
          riderId,
          "🎉 وصلت بأمان",
          `التكلفة النهائية: ${fare} د.ع`,
          "trip_completed",
          { tripId, action: "rate_trip" }
        );

        await sendFCMNotification(
          driverId,
          "✅ تم إكمال الرحلة",
          `أرباحك: ${after.driverEarnings || fare} د.ع`,
          "trip_completed",
          { tripId, action: "view_earnings" }
        );
        break;

      case "cancelled":
        const targetUserId = after.cancelledBy === "rider" ? driverId : riderId;
        const cancellerName = after.cancelledBy === "rider" ? "الراكب" : "السائق";
        await sendFCMNotification(
          targetUserId,
          "❌ تم إلغاء الرحلة",
          `قام ${cancellerName} بإلغاء الرحلة`,
          "trip_cancelled",
          { tripId, action: "trip_cancelled" }
        );
        break;
    }
  } catch (error) {
    console.error("❌ Error in trip status handler:", error);
  }

  return null;
});

/**
 * 💬 رسائل الشات الجديدة
 */
exports.onNewChatMessage = onDocumentCreated(
  "trip_chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const { senderId, senderName } = message;
    const { chatId } = event.params;

    const [userId1, userId2] = chatId.split("_");
    const receiverId = senderId === userId1 ? userId2 : userId1;

    try {
      await sendFCMNotification(
        receiverId,
        `💬 رسالة من ${senderName}`,
        message.message.length > 100
          ? message.message.substring(0, 100) + "..."
          : message.message,
        "chat",
        { chatId, senderId, action: "open_chat" }
      );
    } catch (error) {
      console.error("❌ Error sending chat notification:", error);
    }
  }
);

/**
 * 🎉 الموافقة على الحساب
 */
exports.onAccountApproved = onDocumentUpdated("users/{userId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (!before.isApproved && after.isApproved) {
    const { userId } = event.params;
    const userType = after.userType === "driver" ? "سائق" : "راكب";

    await sendFCMNotification(
      userId,
      "🎉 تمت الموافقة على حسابك!",
      `مرحباً بك في تطبيق تكسي البصرة كـ${userType}`,
      "account_approved",
      { action: "account_approved" }
    );
  }

  return null;
});

/**
 * 📍 تعديل الوجهة أثناء الرحلة
 */
exports.onTripDestinationChanged = onDocumentUpdated("trips/{tripId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  const destinationChanged =
    (before.destinationLocation?.address || "") !==
    (after.destinationLocation?.address || "");
  const stopsChanged =
    JSON.stringify(before.additionalStops || []) !==
    JSON.stringify(after.additionalStops || []);

  if ((destinationChanged || stopsChanged) && after.status === "started") {
    await sendFCMNotification(
      after.driverId,
      "📍 تغييرت وجهة الرحلة",
      "قام الراكب بتعديل وجهة الرحلة",
      "destination_changed",
      { tripId: event.params.tripId, action: "destination_changed" }
    );
  }

  return null;
});

/**
 * 🚕 عند إنشاء رحلة جديدة
 */
exports.onNewTripRequest = onDocumentCreated("trips/{tripId}", async (event) => {
  const trip = event.data.data();
  if (trip.status !== "pending") return null;

  const driversSnapshot = await db
    .collection("users")
    .where("userType", "==", "driver")
    .where("additionalData.isOnline", "==", true)
    .where("additionalData.isAvailable", "==", true)
    .get();

  const notifyDrivers = driversSnapshot.docs.map((doc) =>
    sendFCMNotification(
      doc.id,
      "🚗 طلب رحلة جديد",
      `من ${trip.pickupAddress} إلى ${trip.destinationAddress}\nالتكلفة: ${trip.fare} د.ع`,
      "new_trip",
      { tripId: event.params.tripId, action: "new_trip_request" }
    )
  );

  await Promise.all(notifyDrivers);
  console.log(`✅ تم إشعار ${driversSnapshot.size} سائق`);
  return null;
});

/**
 * 🧪 دالة اختبار الإشعارات
 */
exports.sendTestNotification = onCall(async (request) => {
  const { userId, title, body, type, additionalData } = request.data;

  if (!userId || !title || !body) {
    throw new HttpsError("invalid-argument", "Missing parameters: userId, title, body");
  }

  const result = await sendFCMNotification(
    userId,
    title,
    body,
    type || "general",
    additionalData || {}
  );

  return { success: result };
});

// const {setGlobalOptions} = require("firebase-functions");
// const {onRequest} = require("firebase-functions/https");
// const logger = require("firebase-functions/logger");
// setGlobalOptions({maxInstances: 10});

// const functions = require("firebase-functions");
// const admin = require("firebase-admin");

// admin.initializeApp();

// /**
//  * 📨 إرسال إشعار FCM مع صوت
//  */
// async function sendFCMNotification(userId, title, body, type = "general", data = {}) {
//   try {
//     // جلب FCM Token
//     const userDoc = await admin.firestore().collection("users").doc(userId).get();
//     if (!userDoc.exists) {
//       console.error(`❌ User not found: ${userId}`);
//       return false;
//     }

//     const userData = userDoc.data();
//     const fcmToken = userData.fcmToken;

//     if (!fcmToken) {
//       console.error(`❌ No FCM token for user: ${userId}`);
//       return false;
//     }

//     // تحديد الصوت والأولوية حسب النوع
//     let soundFile = "default";
//     let channelId = "general_notifications";
//     let priority = "default";

//     if (type === "new_trip" || type === "driver_arrived" || type === "trip_accepted") {
//       soundFile = "notification";
//       channelId = "critical_notifications";
//       priority = "high";
//     } else if (type === "chat") {
//       soundFile = "message";
//       channelId = "chat_notifications";
//       priority = "high";
//     }

//     // بناء رسالة FCM
//     const message = {
//       token: fcmToken,
//       notification: {
//         title: title,
//         body: body,
//       },
//       data: {
//         ...data,
//         type: type,
//         click_action: "FLUTTER_NOTIFICATION_CLICK",
//       },
//       android: {
//         notification: {
//           channelId: channelId,
//           priority: priority,
//           sound: soundFile,
//           defaultSound: false,
//         },
//         priority: priority,
//       },
//       apns: {
//         payload: {
//           aps: {
//             "sound": `${soundFile}.mp3`,
//             "badge": 1,
//             "content-available": 1,
//           },
//         },
//       },
//     };

//     // إرسال الإشعار
//     const response = await admin.messaging().send(message);
//     console.log(`✅ تم إرسال الإشعار: ${response}`);

//     // حفظ الإشعار في Firestore
//     await admin.firestore()
//         .collection("users")
//         .doc(userId)
//         .collection("notifications")
//         .add({
//           title: title,
//           body: body,
//           type: type,
//           data: data,
//           isRead: false,
//           createdAt: admin.firestore.FieldValue.serverTimestamp(),
//         });

//     return true;
//   } catch (error) {
//     console.error(`❌ Error sending notification:`, error);
//     return false;
//   }
// }

// /**
//  * 🚗 مراقبة تغييرات حالة الرحلة
//  */
// exports.onTripStatusChanged = functions.firestore
//     .document("trips/{tripId}")
//     .onUpdate(async (change, context) => {
//       const before = change.before.data();
//       const after = change.after.data();

//       // لو الحالة مش متغيرة، ما نعمل شي
//       if (before.status === after.status) return null;

//       const {tripId} = context.params;
//       const {
//         riderId,
//         driverId,
//         status,
//         driverName,
//         riderName,
//         pickupAddress,
//         destinationAddress,
//         fare,
//       } = after;

//       try {
//         switch (status) {
//           case "accepted":
//           // إشعار للراكب: تم قبول الرحلة
//             await sendFCMNotification(
//                 riderId,
//                 "🚗 تم العثور على سائق!",
//                 `السائق ${driverName} في الطريق إليك`,
//                 "trip_accepted",
//                 {tripId: tripId, action: "open_tracking"},
//             );
//             break;

//           case "driverArrived":
//           // إشعار للراكب: السائق وصل
//             await sendFCMNotification(
//                 riderId,
//                 "✅ السائق وصل!",
//                 `${driverName} ينتظرك عند ${pickupAddress}`,
//                 "driver_arrived",
//                 {tripId: tripId, action: "driver_arrived"},
//             );
//             break;

//           case "started":
//           // إشعار للراكب: بدأت الرحلة
//             await sendFCMNotification(
//                 riderId,
//                 "🚀 بدأت رحلتك",
//                 `أنت في الطريق إلى ${destinationAddress}`,
//                 "trip_started",
//                 {tripId: tripId, action: "open_tracking"},
//             );
//             break;

//           case "completed":
//           // إشعار للراكب: وصلت بأمان
//             await sendFCMNotification(
//                 riderId,
//                 "🎉 وصلت بأمان",
//                 `التكلفة النهائية: ${fare} د.ع`,
//                 "trip_completed",
//                 {tripId: tripId, action: "rate_trip"},
//             );

//             // إشعار للسائق: تم إكمال الرحلة
//             await sendFCMNotification(
//                 driverId,
//                 "✅ تم إكمال الرحلة",
//                 `أرباحك: ${after.driverEarnings || fare} د.ع`,
//                 "trip_completed",
//                 {tripId: tripId, action: "view_earnings"},
//             );
//             break;

//           case "cancelled":
//           // تحديد من ألغى
//             const targetUserId = after.cancelledBy === "rider" ? driverId : riderId;
//             const cancellerName = after.cancelledBy === "rider" ? "الراكب" : "السائق";

//             await sendFCMNotification(
//                 targetUserId,
//                 "❌ تم إلغاء الرحلة",
//                 `قام ${cancellerName} بإلغاء الرحلة`,
//                 "trip_cancelled",
//                 {tripId: tripId, action: "trip_cancelled"},
//             );
//             break;
//         }

//         return null;
//       } catch (error) {
//         console.error("❌ Error in trip status handler:", error);
//         return null;
//       }
//     });

// /**
//  * 💬 مراقبة الرسائل الجديدة في الشات
//  */
// exports.onNewChatMessage = functions.firestore
//     .document("trip_chats/{chatId}/messages/{messageId}")
//     .onCreate(async (snap, context) => {
//       const message = snap.data();
//       const {senderId, senderName} = message;
//       const {chatId} = context.params;

//       try {
//       // استخراج معرفات المستخدمين من chatId
//         const parts = chatId.split("_");
//         const userId1 = parts[0];
//         const userId2 = parts[1];

//         // تحديد المستقبل (اللي مش هو المرسل)
//         const receiverId = senderId === userId1 ? userId2 : userId1;

//         // إرسال إشعار الرسالة
//         await sendFCMNotification(
//             receiverId,
//             `💬 رسالة من ${senderName}`,
//         message.message.length > 100 ?
//           message.message.substring(0, 100) + "..." :
//           message.message,
//         "chat",
//         {
//           chatId: chatId,
//           senderId: senderId,
//           action: "open_chat",
//         },
//         );

//         return null;
//       } catch (error) {
//         console.error("❌ Error sending chat notification:", error);
//         return null;
//       }
//     });

// /**
//  * 🎉 مراقبة الموافقة على الحساب
//  */
// exports.onAccountApproved = functions.firestore
//     .document("users/{userId}")
//     .onUpdate(async (change, context) => {
//       const before = change.before.data();
//       const after = change.after.data();

//       // لو تمت الموافقة على الحساب
//       if (before.isApproved === false && after.isApproved === true) {
//         const {userId} = context.params;
//         const userType = after.userType === "driver" ? "سائق" : "راكب";

//         try {
//           await sendFCMNotification(
//               userId,
//               "🎉 تمت الموافقة على حسابك!",
//               `مرحباً بك في تطبيق تكسي البصرة كـ${userType}`,
//               "account_approved",
//               {action: "account_approved"},
//           );

//           return null;
//         } catch (error) {
//           console.error("❌ Error sending approval notification:", error);
//           return null;
//         }
//       }

//       return null;
//     });

// /**
//  * 📍 مراقبة تغيير وجهة الرحلة
//  */
// exports.onTripDestinationChanged = functions.firestore
//     .document("trips/{tripId}")
//     .onUpdate(async (change, context) => {
//       const before = change.before.data();
//       const after = change.after.data();

//       // التحقق من تغيير الوجهة أو نقاط التوقف
//       const destinationChanged =
//   (before.destinationLocation && before.destinationLocation.address) !==
//   (after.destinationLocation && after.destinationLocation.address);

//       const stopsChanged =
//   JSON.stringify(before.additionalStops || []) !==
//   JSON.stringify(after.additionalStops || []);

//       if ((destinationChanged || stopsChanged) && after.status === "started") {
//         try {
//           await sendFCMNotification(
//               after.driverId,
//               "📍 تغييرت وجهة الرحلة",
//               "قام الراكب بتعديل وجهة الرحلة",
//               "destination_changed",
//               {
//                 tripId: context.params.tripId,
//                 action: "destination_changed",
//               },
//           );

//           return null;
//         } catch (error) {
//           console.error("❌ Error sending destination change notification:", error);
//           return null;
//         }
//       }

//       return null;
//     });

// /**
//  * 🚕 إشعار السائقين القريبين عند طلب رحلة جديد
//  */
// exports.onNewTripRequest = functions.firestore
//     .document("trips/{tripId}")
//     .onCreate(async (snap, context) => {
//       const trip = snap.data();

//       if (trip.status !== "pending") return null;

//       try {
//       // جلب جميع السائقين المتاحين والقريبين
//         const driversSnapshot = await admin.firestore()
//             .collection("users")
//             .where("userType", "==", "driver")
//             .where("additionalData.isOnline", "==", true)
//             .where("additionalData.isAvailable", "==", true)
//             .get();

//         // إرسال إشعار لكل سائق
//         const notificationPromises = driversSnapshot.docs.map(async (doc) => {
//           const driverId = doc.id;

//           return sendFCMNotification(
//               driverId,
//               "🚗 طلب رحلة جديد",
//               `من ${trip.pickupAddress} إلى ${trip.destinationAddress}\nالتكلفة: ${trip.fare} د.ع`,
//               "new_trip",
//               {
//                 tripId: context.params.tripId,
//                 action: "new_trip_request",
//               },
//           );
//         });

//         await Promise.all(notificationPromises);
//         console.log(`✅ تم إشعار ${driversSnapshot.size} سائق`);

//         return null;
//       } catch (error) {
//         console.error("❌ Error notifying drivers:", error);
//         return null;
//       }
//     });

// /**
//  * 🧪 دالة اختبار الإشعارات (HTTP Function)
//  */
// exports.sendTestNotification = functions.https.onCall(async (data, context) => {
//   const {userId, title, body, type} = data;

//   if (!userId || !title || !body) {
//     throw new functions.https.HttpsError(
//         "invalid-argument",
//         "Missing required parameters: userId, title, body",
//     );
//   }

//   try {
//     const result = await sendFCMNotification(
//         userId,
//         title,
//         body,
//         type || "general",
//         data.additionalData || {},
//     );

//     return {success: result};
//   } catch (error) {
//     console.error("Error in test notification:", error);
//     throw new functions.https.HttpsError("internal", error.message);
//   }
// });
