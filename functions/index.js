const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

exports.mesajBildirimiGonder = functions.firestore
  .onDocumentCreated(
    "sohbetler/{sohbetId}/mesajlar/{mesajId}",
    async (event) => {
      const mesaj = event.data.data();
      const sohbetId = event.params.sohbetId;

      const gondereId = mesaj.gondereId;
      const gondereAd = mesaj.gondereAd ?? "Biri";
      const metin = mesaj.metin ?? "";

      const sohbetDoc = await admin
        .firestore()
        .collection("sohbetler")
        .doc(sohbetId)
        .get();

      if (!sohbetDoc.exists) return;

      const sohbet = sohbetDoc.data();
      const kullanicilar = sohbet.kullanicilar ?? [];

      const aliciId = kullanicilar.find((uid) => uid !== gondereId);
      if (!aliciId) return;

      const aliciDoc = await admin
        .firestore()
        .collection("kullanicilar")
        .doc(aliciId)
        .get();

      if (!aliciDoc.exists) return;

      const fcmToken = aliciDoc.data().fcmToken;
      if (!fcmToken) return;

      const ilanBaslik = sohbet.ilanBaslik ?? "";
      const bildirimBaslik = gondereAd;
      const bildirimMetin = metin.length > 100
        ? metin.substring(0, 100) + "..."
        : metin;

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: bildirimBaslik,
            body: bildirimMetin || "Yeni mesaj",
          },
          data: {
            sohbetId: sohbetId,
            gondereId: gondereId,
            gondereAd: gondereAd,
            ilanBaslik: ilanBaslik,
            tip: "mesaj",
          },
          android: {
            notification: {
              channelId: "mesaj_bildirimleri",
              priority: "high",
              sound: "default",
            },
          },
        });
      } catch (hata) {
        if (
          hata.code === "messaging/registration-token-not-registered" ||
          hata.code === "messaging/invalid-registration-token"
        ) {
          await admin
            .firestore()
            .collection("kullanicilar")
            .doc(aliciId)
            .update({ fcmToken: admin.firestore.FieldValue.delete() });
        }
      }
    }
  );