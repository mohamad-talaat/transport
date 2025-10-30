// ============================================
// 🔐 Cloud Function: منع قبول الرحلة من أكثر من سائق
// ============================================
// ضع هذا الكود في Firebase Functions
// ============================================

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// ✅ قفل الرحلة عند أول قبول
exports.lockTripOnAccept = functions.firestore
  .document('trip_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // التحقق: هل تم تغيير الحالة لـ 'accepted'؟
    if (before.status !== 'accepted' && after.status === 'accepted') {
      const tripId = after.tripId;
      const acceptedDriverId = after.driverId;
      
      try {
        // استخدام Transaction لضمان عدم قبول أكثر من سائق
        await db.runTransaction(async (transaction) => {
          const tripRef = db.collection('trips').doc(tripId);
          const tripDoc = await transaction.get(tripRef);
          
          if (!tripDoc.exists) {
            throw new Error('الرحلة غير موجودة');
          }
          
          const tripData = tripDoc.data();
          
          // التحقق: هل الرحلة مقبولة بالفعل؟
          if (tripData.status === 'accepted' && tripData.driverId) {
            // الرحلة محجوزة بالفعل - إلغاء هذا الطلب
            const requestRef = db.collection('trip_requests').doc(context.params.requestId);
            transaction.update(requestRef, {
              status: 'rejected',
              rejectionReason: 'تم قبول الرحلة من سائق آخر',
              rejectedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            
            // إرسال إشعار للسائق
            await sendNotificationToDriver(acceptedDriverId, 'رحلة محجوزة', 'تم قبول الرحلة من سائق آخر');
            
            return;
          }
          
          // الرحلة متاحة - قبولها
          transaction.update(tripRef, {
            status: 'accepted',
            driverId: acceptedDriverId,
            acceptedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
          // إلغاء باقي الطلبات للسائقين الآخرين
          const otherRequestsSnapshot = await db.collection('trip_requests')
            .where('tripId', '==', tripId)
            .where('status', '==', 'pending')
            .get();
          
          const batch = db.batch();
          otherRequestsSnapshot.docs.forEach(doc => {
            if (doc.id !== context.params.requestId) {
              batch.update(doc.ref, {
                status: 'cancelled',
                cancellationReason: 'تم قبول الرحلة من سائق آخر',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp()
              });
            }
          });
          
          await batch.commit();
          
          console.log(`✅ تم قبول الرحلة ${tripId} من السائق ${acceptedDriverId}`);
        });
        
      } catch (error) {
        console.error('❌ خطأ في قفل الرحلة:', error);
      }
    }
  });

// دالة مساعدة لإرسال الإشعارات
async function sendNotificationToDriver(driverId, title, body) {
  try {
    const driverDoc = await db.collection('users').doc(driverId).get();
    if (!driverDoc.exists) return;
    
    const fcmToken = driverDoc.data().fcmToken;
    if (!fcmToken) return;
    
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: title,
        body: body
      },
      android: {
        priority: 'high'
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    });
  } catch (error) {
    console.error('خطأ في إرسال الإشعار:', error);
  }
}

// ============================================
// 📝 ملاحظات التثبيت:
// ============================================
// 1. ثبت Firebase Functions CLI:
//    npm install -g firebase-tools
//
// 2. في مجلد المشروع:
//    firebase init functions
//
// 3. انسخ هذا الكود في functions/index.js
//
// 4. نشر الـ Function:
//    firebase deploy --only functions
//
// 5. تأكد من وجود Index في Firestore:
//    Collection: trip_requests
//    Fields: tripId (Ascending), status (Ascending)
// ============================================
