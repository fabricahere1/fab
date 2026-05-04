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

    // Bildirim içeriği:
    // title  → gönderenin adı
    // body   → mesaj metni (ilan adı değil, gerçek mesaj)
    // ticker → ilan adı (bildirim çekmecesinde küçük satır)
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
        // collapseKey: aynı sohbetten gelen bildirimler tek slotta birleşir
        // Arka arkaya mesaj gelirse her biri ayrı bildirim açmaz,
        // mevcut bildirimi günceller (tray'de tek satır kalır)
        collapseKey: sohbetId,
        notification: {
          // tag: aynı sohbet = aynı tag = eski bildirimi güncelle
          tag: sohbetId,
          channelId: "mesajlar",
          // ticker: bildirim geldiğinde status bar'da kısa süre görünen metin
          ticker: `${gondereAd}: ${bildirimMetin}`,
          // Birden fazla mesaj varsa sayıyı göster
          notificationCount: 1,
        },
      },
      apns: {
        // iOS için thread-id ile aynı sohbet bildirimleri gruplanır
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
    if (!fcmToken) return;

    const yildiz = "⭐".repeat(Math.min(Math.round(puan), 5));

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Yeni değerlendirme aldın!",
        body: `${degerlendireninAd} seni değerlendirdi ${yildiz}`,
      },
      data: {
        tip: "degerlendirme",
        hedefKullaniciId: hedefKullaniciId,
      },
      android: {
        priority: "high",
      },
    });
  });