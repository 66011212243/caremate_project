const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

exports.notifyProvidersNewJob = onDocumentCreated(
    "jobs/{jobId}",
    async (event) => {
      const jobId = event.params.jobId;
      const jobData = event.data.data();

      console.log("มีงานใหม่:", jobId);
      console.log("ข้อมูล Job:", jobData);

      const providersSnapshot = await db
          .collection("users")
          .where("role", "==", 1)
          .get();

      console.log("จำนวน Provider:", providersSnapshot.size);

      const tokens = [];
      const notificationPromises = [];

      providersSnapshot.forEach((doc) => {
        const providerData = doc.data();

        if (providerData.fcm_token) {
          tokens.push(providerData.fcm_token);

          const notificationData = {
            user_id: doc.id,
            title: "มีงานใหม่",
            body: "มีผู้รับบริการประกาศงานใหม่",
            type: "new_job",
            related_id: jobId,
            is_read: false,
            created_at: new Date(),
          };

          notificationPromises.push(
              db.collection("notifications").add(notificationData),
          );
        }
      });

      await Promise.all(notificationPromises);

      console.log("จำนวน Token:", tokens.length);

      if (tokens.length > 0) {
        const message = {
          notification: {
            title: "มีงานใหม่",
            body: "มีผู้รับบริการประกาศงานใหม่",
          },
          data: {
            type: "new_job",
            job_id: jobId,
          },
          tokens: tokens,
        };

        const response = await messaging.sendEachForMulticast(message);

        console.log("ส่งสำเร็จ:", response.successCount);
        console.log("ส่งไม่สำเร็จ:", response.failureCount);
      } else {
        console.log("ไม่มี Provider ที่มี FCM Token");
      }

      return null;
    },
);
