const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * 📨 إرسال إشعار FCM مع صوت
 */
async function sendFCMNotification(userId, title, body, type = 'general', data = {}) {
  try {
    // جلب FCM Token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
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

    // تحديد الصوت والأولوية حسب النوع
    let soundFile = 'default';
    let channelId = 'general_notifications';
    let priority = 'default';

    if (type === 'new_trip' || type === 'driver_arrived' || type === 'trip_accepted') {
      soundFile = 'notification';
      channelId = 'critical_notifications';
      priority = 'high';
    } else if (type === 'chat') {
      soundFile = 'message';
      channelId = 'chat_notifications';
      priority = 'high';
    }

    // بناء رسالة FCM
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        type: type,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        notification: {
          channelId: channelId,
          priority: priority,
          sound: soundFile,
          defaultSound: false,
        },
        priority: priority,
      },
      apns: {
        payload: {
          aps: {
            sound: `${soundFile}.mp3`,
            badge: 1,
            'content-available': 1,
          },
        },
      },
    };

    // إرسال الإشعار
    const response = await admin.messaging().send(message);
    console.log(`✅ تم إرسال الإشعار: ${response}`);

    // حفظ الإشعار في Firestore
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        title: title,
        body: body,
        type: type,
        data: data,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return true;
  } catch (error) {
    console.error(`❌ Error sending notification:`, error);
    return false;
  }
}

/**
 * 🚗 مراقبة تغييرات حالة الرحلة
 */
exports.onTripStatusChanged = functions.firestore
  .document('trips/{tripId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // لو الحالة مش متغيرة، ما نعمل شي
    if (before.status === after.status) return null;

    const { tripId } = context.params;
    const { 
      riderId, 
      driverId, 
      status, 
      driverName, 
      riderName,
      pickupAddress, 
      destinationAddress, 
      fare 
    } = after;

    try {
      switch (status) {
        case 'accepted':
          // إشعار للراكب: تم قبول الرحلة
          await sendFCMNotification(
            riderId,
            '🚗 تم العثور على سائق!',
            `السائق ${driverName} في الطريق إليك`,
            'trip_accepted',
            { tripId: tripId, action: 'open_tracking' }
          );
          break;

        case 'driverArrived':
          // إشعار للراكب: السائق وصل
          await sendFCMNotification(
            riderId,
            '✅ السائق وصل!',
            `${driverName} ينتظرك عند ${pickupAddress}`,
            'driver_arrived',
            { tripId: tripId, action: 'driver_arrived' }
          );
          break;

        case 'started':
          // إشعار للراكب: بدأت الرحلة
          await sendFCMNotification(
            riderId,
            '🚀 بدأت رحلتك',
            `أنت في الطريق إلى ${destinationAddress}`,
            'trip_started',
            { tripId: tripId, action: 'open_tracking' }
          );
          break;

        case 'completed':
          // إشعار للراكب: وصلت بأمان
          await sendFCMNotification(
            riderId,
            '🎉 وصلت بأمان',
            `التكلفة النهائية: ${fare} د.ع`,
            'trip_completed',
            { tripId: tripId, action: 'rate_trip' }
          );

          // إشعار للسائق: تم إكمال الرحلة
          await sendFCMNotification(
            driverId,
            '✅ تم إكمال الرحلة',
            `أرباحك: ${after.driverEarnings || fare} د.ع`,
            'trip_completed',
            { tripId: tripId, action: 'view_earnings' }
          );
          break;

        case 'cancelled':
          // تحديد من ألغى
          const targetUserId = after.cancelledBy === 'rider' ? driverId : riderId;
          const cancellerName = after.cancelledBy === 'rider' ? 'الراكب' : 'السائق';

          await sendFCMNotification(
            targetUserId,
            '❌ تم إلغاء الرحلة',
            `قام ${cancellerName} بإلغاء الرحلة`,
            'trip_cancelled',
            { tripId: tripId, action: 'trip_cancelled' }
          );
          break;
      }

      return null;
    } catch (error) {
      console.error('❌ Error in trip status handler:', error);
      return null;
    }
  });

/**
 * 💬 مراقبة الرسائل الجديدة في الشات
 */
exports.onNewChatMessage = functions.firestore
  .document('trip_chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { senderId, senderName } = message;
    const { chatId } = context.params;

    try {
      // استخراج معرفات المستخدمين من chatId
      const parts = chatId.split('_');
      const userId1 = parts[0];
      const userId2 = parts[1];

      // تحديد المستقبل (اللي مش هو المرسل)
      const receiverId = senderId === userId1 ? userId2 : userId1;

      // إرسال إشعار الرسالة
      await sendFCMNotification(
        receiverId,
        `💬 رسالة من ${senderName}`,
        message.message.length > 100 
          ? message.message.substring(0, 100) + '...' 
          : message.message,
        'chat',
        { 
          chatId: chatId,
          senderId: senderId,
          action: 'open_chat' 
        }
      );

      return null;
    } catch (error) {
      console.error('❌ Error sending chat notification:', error);
      return null;
    }
  });

/**
 * 🎉 مراقبة الموافقة على الحساب
 */
exports.onAccountApproved = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // لو تمت الموافقة على الحساب
    if (before.isApproved === false && after.isApproved === true) {
      const { userId } = context.params;
      const userType = after.userType === 'driver' ? 'سائق' : 'راكب';

      try {
        await sendFCMNotification(
          userId,
          '🎉 تمت الموافقة على حسابك!',
          `مرحباً بك في تطبيق تكسي البصرة كـ${userType}`,
          'account_approved',
          { action: 'account_approved' }
        );

        return null;
      } catch (error) {
        console.error('❌ Error sending approval notification:', error);
        return null;
      }
    }

    return null;
  });

/**
 * 📍 مراقبة تغيير وجهة الرحلة
 */
exports.onTripDestinationChanged = functions.firestore
  .document('trips/{tripId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // التحقق من تغيير الوجهة أو نقاط التوقف
    const destinationChanged = 
      before.destinationLocation?.address !== after.destinationLocation?.address;
    const stopsChanged = 
      JSON.stringify(before.additionalStops) !== JSON.stringify(after.additionalStops);

    if ((destinationChanged || stopsChanged) && after.status === 'started') {
      try {
        await sendFCMNotification(
          after.driverId,
          '📍 تغييرت وجهة الرحلة',
          'قام الراكب بتعديل وجهة الرحلة',
          'destination_changed',
          { 
            tripId: context.params.tripId,
            action: 'destination_changed' 
          }
        );

        return null;
      } catch (error) {
        console.error('❌ Error sending destination change notification:', error);
        return null;
      }
    }

    return null;
  });

/**
 * 🚕 إشعار السائقين القريبين عند طلب رحلة جديد
 */
exports.onNewTripRequest = functions.firestore
  .document('trips/{tripId}')
  .onCreate(async (snap, context) => {
    const trip = snap.data();

    if (trip.status !== 'pending') return null;

    try {
      // جلب جميع السائقين المتاحين والقريبين
      const driversSnapshot = await admin.firestore()
        .collection('users')
        .where('userType', '==', 'driver')
        .where('additionalData.isOnline', '==', true)
        .where('additionalData.isAvailable', '==', true)
        .get();

      // إرسال إشعار لكل سائق
      const notificationPromises = driversSnapshot.docs.map(async (doc) => {
        const driverId = doc.id;
        
        return sendFCMNotification(
          driverId,
          '🚗 طلب رحلة جديد',
          `من ${trip.pickupAddress} إلى ${trip.destinationAddress}\nالتكلفة: ${trip.fare} د.ع`,
          'new_trip',
          { 
            tripId: context.params.tripId,
            action: 'new_trip_request' 
          }
        );
      });

      await Promise.all(notificationPromises);
      console.log(`✅ تم إشعار ${driversSnapshot.size} سائق`);

      return null;
    } catch (error) {
      console.error('❌ Error notifying drivers:', error);
      return null;
    }
  });

/**
 * 🎯 منع قبول أكثر من سائق لنفس الرحلة (أهم دالة!)
 */
exports.onTripRequestAccepted = functions.firestore
  .document('trip_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // ✅ لو السائق قبل الرحلة
    if (before.status !== 'accepted' && after.status === 'accepted') {
      const { tripId, driverId } = after;

      try {
        const db = admin.firestore();
        const batch = db.batch();

        // ✅ 1. تحديث حالة الرحلة (أول سائق يقبل)
        const tripRef = db.collection('trips').doc(tripId);
        const tripDoc = await tripRef.get();

        if (!tripDoc.exists) {
          console.error(`❌ Trip ${tripId} not found`);
          return null;
        }

        const tripData = tripDoc.data();

        // ✅ تحقق: لو الرحلة already accepted، ارفض هذا السائق
        if (tripData.status === 'accepted' || tripData.driverId) {
          console.log(`⚠️ Trip ${tripId} already accepted by another driver`);
          
          // ارفض هذا السائق
          batch.update(change.after.ref, {
            status: 'rejected',
            rejectedReason: 'Trip already accepted by another driver',
            rejectedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          await batch.commit();

          // أرسل إشعار للسائق المرفوض
          await sendFCMNotification(
            driverId,
            '❌ الرحلة محجوزة',
            'قام سائق آخر بقبول الرحلة قبلك',
            'trip_taken',
            { tripId: tripId }
          );

          return null;
        }

        // ✅ 2. تعيين أول سائق يقبل
        batch.update(tripRef, {
          status: 'accepted',
          driverId: driverId,
          acceptedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // ✅ 3. رفض باقي الطلبات للسائقين الآخرين
        const otherRequestsSnapshot = await db.collection('trip_requests')
          .where('tripId', '==', tripId)
          .where('status', '==', 'pending')
          .get();

        console.log(`🚫 Found ${otherRequestsSnapshot.size} pending requests to reject`);

        otherRequestsSnapshot.docs.forEach(doc => {
          if (doc.id !== context.params.requestId) {
            batch.update(doc.ref, {
              status: 'expired',
              expiredReason: 'Trip accepted by another driver',
              expiredAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // أرسل إشعار لكل سائق تم رفضه
            const rejectedDriverId = doc.data().driverId;
            sendFCMNotification(
              rejectedDriverId,
              '❌ الرحلة محجوزة',
              'قام سائق آخر بقبول الرحلة',
              'trip_taken',
              { tripId: tripId }
            ).catch(err => console.error(`Error sending rejection notification: ${err}`));
          }
        });

        // ✅ 4. تنفيذ جميع التحديثات دفعة واحدة
        await batch.commit();

        console.log(`✅ Trip ${tripId} accepted by driver ${driverId}`);
        console.log(`✅ ${otherRequestsSnapshot.size} other requests rejected`);

        return null;
      } catch (error) {
        console.error(`❌ Error handling trip acceptance:`, error);
        return null;
      }
    }

    return null;
  });

/**
 * 🧪 دالة اختبار الإشعارات (HTTP Function)
 */
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  const { userId, title, body, type } = data;

  if (!userId || !title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required parameters: userId, title, body'
    );
  }

  try {
    const result = await sendFCMNotification(
      userId,
      title,
      body,
      type || 'general',
      data.additionalData || {}
    );

    return { success: result };
  } catch (error) {
    console.error('Error in test notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
