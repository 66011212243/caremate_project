const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

const TITLE = "มีงานใหม่";
const BODY = "มีผู้รับบริการประกาศงานใหม่";

const DEAD_TOKEN_CODES = [
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
];

const chunk = (arr, size) => {
  const out = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
};

exports.notifyProvidersNewJob = onDocumentCreated(
    "jobs/{jobId}",
    async (event) => {
      const jobId = event.params.jobId;

      const providersSnapshot = await db
          .collection("users")
          .where("role", "==", 1)
          .get();

      console.log("จำนวน Provider:", providersSnapshot.size);

      // 1. บันทึกประวัติแจ้งเตือนให้ทุกคน (แม้ยังไม่มี token) แบบ batch
      for (const docs of chunk(providersSnapshot.docs, 400)) {
        const batch = db.batch();
        docs.forEach((doc) => {
          batch.set(db.collection("notifications").doc(), {
            user_id: doc.id,
            title: TITLE,
            body: BODY,
            type: "new_job",
            related_id: jobId,
            is_read: false,
            created_at: FieldValue.serverTimestamp(),
          });
        });
        await batch.commit();
      }

      // 2. รวบรวม token (กันซ้ำด้วย Map: token -> uid)
      const tokenToUid = new Map();
      providersSnapshot.forEach((doc) => {
        const token = doc.get("fcm_token");
        if (token) tokenToUid.set(token, doc.id);
      });
      const tokens = [...tokenToUid.keys()];
      console.log("จำนวน Token:", tokens.length);

      if (tokens.length === 0) {
        console.log("ไม่มี Provider ที่มี FCM Token");
        return null;
      }

      // 3. ส่งทีละไม่เกิน 500 token
      const deadUids = [];
      let success = 0;
      let failure = 0;

      for (const part of chunk(tokens, 500)) {
        const response = await messaging.sendEachForMulticast({
          tokens: part,
          notification: {title: TITLE, body: BODY},
          data: {type: "new_job", job_id: jobId},
          android: {
            notification: {channelId: "high_importance_channel"},
          },
        });

        success += response.successCount;
        failure += response.failureCount;

        response.responses.forEach((r, i) => {
          if (!r.success && DEAD_TOKEN_CODES.includes(r.error.code)) {
            deadUids.push(tokenToUid.get(part[i]));
          }
        });
      }

      console.log("ส่งสำเร็จ:", success, "ไม่สำเร็จ:", failure);

      // 4. ลบ token ที่ใช้ไม่ได้แล้ว
      await Promise.all(
          deadUids.map((uid) =>
            db.collection("users").doc(uid).update({
              fcm_token: FieldValue.delete(),
            }),
          ),
      );

      return null;
    },
);
