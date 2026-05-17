import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

// ── Anlaşma Kabul ─────────────────────────────────────────────────────────────
export const anlasmaKabul = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }

    const { sohbetId, mesajId } = data as { sohbetId: string; mesajId: string };

    if (!sohbetId || !mesajId) {
      throw new functions.https.HttpsError("invalid-argument", "sohbetId ve mesajId gerekli.");
    }

    const mesajRef = db
      .collection("sohbetler")
      .doc(sohbetId)
      .collection("mesajlar")
      .doc(mesajId);

    const mesajSnap = await mesajRef.get();
    if (!mesajSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Mesaj bulunamadı.");
    }

    const mesaj = mesajSnap.data()!;

    if (mesaj.gondereId === context.auth.uid) {
      throw new functions.https.HttpsError("permission-denied", "Kendi anlaşmanı onaylayamazsın.");
    }

    await mesajRef.update({ anlasmaEvet: true });

    return { success: true };
  });

// ── Anlaşma Red ──────────────────────────────────────────────────────────────
export const anlasmaRed = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }

    const { sohbetId, mesajId } = data as { sohbetId: string; mesajId: string };

    if (!sohbetId || !mesajId) {
      throw new functions.https.HttpsError("invalid-argument", "sohbetId ve mesajId gerekli.");
    }

    const mesajRef = db
      .collection("sohbetler")
      .doc(sohbetId)
      .collection("mesajlar")
      .doc(mesajId);

    const mesajSnap = await mesajRef.get();
    if (!mesajSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Mesaj bulunamadı.");
    }

    const mesaj = mesajSnap.data()!;

    if (mesaj.gondereId === context.auth.uid) {
      throw new functions.https.HttpsError("permission-denied", "Kendi anlaşmanı reddedemezsin.");
    }

    await mesajRef.update({ anlasmaRed: true });

    return { success: true };
  });

// ── Mesaj Bildirimi ───────────────────────────────────────────────────────────
export const mesajBildirimiGonder = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }

    const { aliciId, gondereAd, ilanBaslik, sohbetId, metin } = data as {
      aliciId: string;
      gondereAd: string;
      ilanBaslik: string;
      sohbetId: string;
      metin: string;
    };

    const kullaniciSnap = await db.collection("kullanicilar").doc(aliciId).get();
    if (!kullaniciSnap.exists) return { success: false };

    const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) return { success: false };

    const bildirimMetin = metin && metin.trim().length > 0 ? metin.trim() : ilanBaslik;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: gondereAd,
        body: bildirimMetin,
      },
      data: {
        tip: "mesaj",
        sohbetId: sohbetId,
        ilanBaslik: ilanBaslik,
      },
      android: {
        priority: "high",
        collapseKey: sohbetId,
        notification: {
          tag: sohbetId,
          channelId: "mesajlar",
          ticker: `${gondereAd}: ${bildirimMetin}`,
          notificationCount: 1,
        },
      },
      apns: {
        headers: {
          "apns-collapse-id": sohbetId.substring(0, 64),
        },
        payload: {
          aps: {
            threadId: sohbetId,
            badge: 1,
          },
        },
      },
    });

    return { success: true };
  });

// ── Değerlendirme Bildirimi ───────────────────────────────────────────────────
export const degerlendirmeBildirimiGonder = functions
  .region("europe-west1")
  .firestore.document("degerlendirmeler/{degId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    if (!data) return;

    const { hedefKullaniciId, degerlendireninId, puan } = data as {
      hedefKullaniciId: string;
      degerlendireninId: string;
      puan: number;
    };

    const degerlendireninSnap = await db
      .collection("kullanicilar")
      .doc(degerlendireninId)
      .get();
    const degerlendireninAd =
      (degerlendireninSnap.data()?.adSoyad as string | undefined) ?? "Biri";

    const hedefSnap = await db
      .collection("kullanicilar")
      .doc(hedefKullaniciId)
      .get();
    const fcmToken = hedefSnap.data()?.fcmToken as string | undefined;

    const yildiz = "⭐".repeat(Math.min(Math.round(puan), 5));
    const bildirimBaslik = "Yeni değerlendirme aldın!";
    const bildirimIcerik = `${degerlendireninAd} seni değerlendirdi ${yildiz}`;

    if (fcmToken) {
      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: bildirimBaslik,
            body: bildirimIcerik,
          },
          data: {
            tip: "degerlendirme",
            hedefKullaniciId: hedefKullaniciId,
          },
          android: {
            priority: "high",
          },
        });
      } catch (_) {}
    }

    await db.collection("bildirimler").add({
      kullaniciId: hedefKullaniciId,
      tip: "sistem",
      baslik: bildirimBaslik,
      icerik: bildirimIcerik,
      okundu: false,
      tarih: admin.firestore.FieldValue.serverTimestamp(),
      hedefId: "",
      gondereId: degerlendireninId,
      gondereAd: degerlendireninAd,
    });
  });

// ── Teslim Alındı Trigger — Her iki kullanıcıya bekleyen değerlendirme yaz ───
export const teslimAlindiTrigger = functions
  .region("europe-west1")
  .firestore.document("sohbetler/{sohbetId}")
  .onUpdate(async (change, context) => {
    const onceki = change.before.data();
    const sonraki = change.after.data();

    if (!onceki || !sonraki) return;

    const oncekiTeslim = onceki?.islemDurumlari?.teslimAlindi === true;
    const sonrakiTeslim = sonraki?.islemDurumlari?.teslimAlindi === true;

    if (oncekiTeslim || !sonrakiTeslim) return;

    const sohbetId = context.params.sohbetId;
    const kullanicilar: string[] = sonraki.kullanicilar ?? [];
    const ilanBaslik: string = sonraki.ilanBaslik ?? "İlan";

    if (kullanicilar.length < 2) return;

    const batch = db.batch();

    for (const uid of kullanicilar) {
      const zatenYapildi = sonraki[`degerlendirmeYapildi_${uid}`] === true;
      if (zatenYapildi) continue;

      const bekleyenRef = db
        .collection("kullanicilar")
        .doc(uid)
        .collection("bekleyenDegerlendirmeler")
        .doc(sohbetId);

      const mevcutSnap = await bekleyenRef.get();
      if (!mevcutSnap.exists) {
        batch.set(bekleyenRef, {
          sohbetId: sohbetId,
          tarih: admin.firestore.FieldValue.serverTimestamp(),
          tamamlandi: false,
        });
      }

      const kullaniciSnap = await db.collection("kullanicilar").doc(uid).get();
      const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
      if (!fcmToken) continue;

      const karsiUid = kullanicilar.find((id) => id !== uid) ?? "";
      let karsiAd = "Karşı taraf";
      if (karsiUid) {
        const karsiSnap = await db.collection("kullanicilar").doc(karsiUid).get();
        karsiAd = (karsiSnap.data()?.adSoyad as string | undefined) ?? "Karşı taraf";
      }

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Değerlendirme zamanı!",
            body: `"${ilanBaslik}" ilanı tamamlandı. ${karsiAd} için değerlendirme yap.`,
          },
          data: {
            tip: "degerlendirme",
            sohbetId: sohbetId,
          },
          android: {
            priority: "high",
          },
        });
      } catch (_) {}

      const bildirimRef = db.collection("bildirimler").doc();
      batch.set(bildirimRef, {
        kullaniciId: uid,
        tip: "degerlendirme",
        baslik: "Değerlendirme zamanı!",
        icerik: `"${ilanBaslik}" ilanı tamamlandı. ${karsiAd} için değerlendirme yap.`,
        okundu: false,
        tarih: admin.firestore.FieldValue.serverTimestamp(),
        hedefId: sohbetId,
        gondereId: karsiUid,
        gondereAd: karsiAd,
      });
    }

    await batch.commit();
  });

// ── İşlem Durumu Bildirimi ────────────────────────────────────────────────────
export const islemDurumiBildirimiGonder = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }

    const { aliciId, gondereAd, ilanBaslik, sohbetId, durum } = data as {
      aliciId: string;
      gondereAd: string;
      ilanBaslik: string;
      sohbetId: string;
      durum: string;
    };

    const kullaniciSnap = await db.collection("kullanicilar").doc(aliciId).get();
    if (!kullaniciSnap.exists) return { success: false };

    const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) return { success: false };

    let bildirimBaslik = "";
    let bildirimIcerik = "";

    switch (durum) {
      case "anlasildi":
        bildirimBaslik = "Anlaşma onaylandı!";
        bildirimIcerik = `${gondereAd}, "${ilanBaslik}" için anlaşmayı onayladı.`;
        break;
      case "yolaCikti":
        bildirimBaslik = "Ürün yola çıktı! 🚀";
        bildirimIcerik = `${gondereAd}, "${ilanBaslik}" ürününü yola çıkardı.`;
        break;
      case "teslimEdildi":
        bildirimBaslik = "Ürün teslim edildi! 📦";
        bildirimIcerik = `${gondereAd}, "${ilanBaslik}" ürününü teslim etti.`;
        break;
      case "teslimAlindi":
        bildirimBaslik = "Ürün teslim alındı! ✅";
        bildirimIcerik = `${gondereAd}, "${ilanBaslik}" ürününü teslim aldı.`;
        break;
      default:
        return { success: false };
    }

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: bildirimBaslik,
        body: bildirimIcerik,
      },
      data: {
        tip: "islem",
        sohbetId: sohbetId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "islem_durumu",
          tag: sohbetId,
        },
      },
    });

    await db.collection("bildirimler").add({
      kullaniciId: aliciId,
      tip: "islem",
      baslik: bildirimBaslik,
      icerik: bildirimIcerik,
      okundu: false,
      tarih: admin.firestore.FieldValue.serverTimestamp(),
      hedefId: sohbetId,
      gondereId: context.auth.uid,
      gondereAd: gondereAd,
    });

    return { success: true };
  });