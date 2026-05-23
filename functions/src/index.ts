import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { algoliasearch } from "algoliasearch";

admin.initializeApp();

const db = admin.firestore();

// ── Algolia ───────────────────────────────────────────────────────────────────

const ALGOLIA_APP_ID  = "NVHD1ZSPLZ";
const ALGOLIA_API_KEY = "f5dc5bff05386fc3d86df1d1888d5bbd";
const ALGOLIA_INDEX   = "ilanlar";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_API_KEY);

// İlan eklenince → Algolia'ya ekle
export const ilanEklendi = functions
  .region("europe-west1")
  .firestore.document("ilanlar/{ilanId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return;

    await algoliaClient.saveObject({
      indexName: ALGOLIA_INDEX,
      body: {
        objectID:        context.params.ilanId,
        urun:            data.urun            ?? "",
        nereden:         data.nereden         ?? "",
        nereye:          data.nereye          ?? "",
        kategori:        data.kategori        ?? "",
        anaKategori:     data.anaKategori     ?? "",
        kategoriYolu:    data.kategoriYolu    ?? [],
        tip:             data.tip             ?? "",
        aktif:           data.aktif           ?? true,
        resimUrl:        (data.resimUrller && data.resimUrller.length > 0) ? data.resimUrller[0] : (data.resimUrl ?? ""),
        olusturmaTarihi: data.olusturmaTarihi?.toMillis() ?? Date.now(),
      },
    });
  });

// İlan güncellenince → Algolia'yı güncelle
export const ilanGuncellendi = functions
  .region("europe-west1")
  .firestore.document("ilanlar/{ilanId}")
  .onUpdate(async (change, context) => {
    const data = change.after.data();
    if (!data) return;

    await algoliaClient.saveObject({
      indexName: ALGOLIA_INDEX,
      body: {
        objectID:        context.params.ilanId,
        urun:            data.urun            ?? "",
        nereden:         data.nereden         ?? "",
        nereye:          data.nereye          ?? "",
        kategori:        data.kategori        ?? "",
        anaKategori:     data.anaKategori     ?? "",
        kategoriYolu:    data.kategoriYolu    ?? [],
        tip:             data.tip             ?? "",
        aktif:           data.aktif           ?? true,
        resimUrl:        (data.resimUrller && data.resimUrller.length > 0) ? data.resimUrller[0] : (data.resimUrl ?? ""),
        olusturmaTarihi: data.olusturmaTarihi?.toMillis() ?? Date.now(),
      },
    });
  });

// İlan silinince → Algolia'dan sil
export const ilanSilindi = functions
  .region("europe-west1")
  .firestore.document("ilanlar/{ilanId}")
  .onDelete(async (snap, context) => {
    await algoliaClient.deleteObject({
      indexName: ALGOLIA_INDEX,
      objectID:  context.params.ilanId,
    });
  });

// Mevcut ilanları Algolia'ya toplu aktar (bir kez çalıştır)
export const algoliaTopluAktar = functions
  .region("europe-west1")
  .https.onCall(async (_, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }

    const snap = await db.collection("ilanlar").get();
    const records = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        objectID:        doc.id,
        urun:            data.urun            ?? "",
        nereden:         data.nereden         ?? "",
        nereye:          data.nereye          ?? "",
        kategori:        data.kategori        ?? "",
        anaKategori:     data.anaKategori     ?? "",
        kategoriYolu:    data.kategoriYolu    ?? [],
        tip:             data.tip             ?? "",
        aktif:           data.aktif           ?? true,
        resimUrl:        (data.resimUrller && data.resimUrller.length > 0) ? data.resimUrller[0] : (data.resimUrl ?? ""),
        olusturmaTarihi: data.olusturmaTarihi?.toMillis() ?? Date.now(),
      };
    });

    await algoliaClient.saveObjects({
      indexName: ALGOLIA_INDEX,
      objects:   records,
    });

    return { success: true, count: records.length };
  });

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

// ── Teslim Alındı Trigger ─────────────────────────────────────────────────────
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

// ── İşlem Durumu FCM Trigger ──────────────────────────────────────────────────
export const islemDurumuFcmTrigger = functions
  .region("europe-west1")
  .firestore.document("sohbetler/{sohbetId}")
  .onUpdate(async (change, context) => {
    const onceki = change.before.data();
    const sonraki = change.after.data();

    if (!onceki || !sonraki) return;

    const oncekiDurumlar = (onceki.islemDurumlari as Record<string, boolean>) ?? {};
    const sonrakiDurumlar = (sonraki.islemDurumlari as Record<string, boolean>) ?? {};

    const ilanBaslik: string = sonraki.ilanBaslik ?? "İlan";
    const kullanicilar: string[] = sonraki.kullanicilar ?? [];
    const sohbetId = context.params.sohbetId;

    const durumBilgileri: Record<string, { baslik: string; icerik: (ad: string) => string }> = {
      yolaCikti: {
        baslik: "Ürün yola çıktı! 🚀",
        icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü yola çıkardı.`,
      },
      teslimEdildi: {
        baslik: "Ürün teslim edildi! 📦",
        icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü teslim etti.`,
      },
      teslimAlindi: {
        baslik: "Ürün teslim alındı! ✅",
        icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü teslim aldı.`,
      },
      siparisVerildi: {
        baslik: "Sipariş verildi!",
        icerik: (ad) => `${ad}, "${ilanBaslik}" için sipariş verdi.`,
      },
      urunAlindi: {
        baslik: "Ürün alındı!",
        icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü aldı.`,
      },
    };

    for (const [key, bilgi] of Object.entries(durumBilgileri)) {
      const eskiDeger = oncekiDurumlar[key] === true;
      const yeniDeger = sonrakiDurumlar[key] === true;

      if (!eskiDeger && yeniDeger) {
        for (const uid of kullanicilar) {
          const kullaniciSnap = await db.collection("kullanicilar").doc(uid).get();
          if (!kullaniciSnap.exists) continue;

          const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
          if (!fcmToken) continue;

          const karsiUid = kullanicilar.find((id) => id !== uid) ?? "";
          if (!karsiUid) continue;

          const karsiSnap = await db.collection("kullanicilar").doc(karsiUid).get();
          const karsiAd = (karsiSnap.data()?.adSoyad as string | undefined) ?? "Karşı taraf";

          try {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: bilgi.baslik,
                body: bilgi.icerik(karsiAd),
              },
              data: {
                tip: "islem",
                sohbetId: sohbetId,
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "islem_durumu",
                  tag: `${sohbetId}_${key}`,
                },
              },
            });
          } catch (_) {}
        }
      }
    }

    for (const uid of kullanicilar) {
      const benimKey = `anlasildi_${uid}`;
      const eskiOnay = oncekiDurumlar[benimKey] === true;
      const yeniOnay = sonrakiDurumlar[benimKey] === true;

      if (!eskiOnay && yeniOnay) {
        const karsiUid = kullanicilar.find((id) => id !== uid) ?? "";
        if (!karsiUid) continue;

        const karsiSnap = await db.collection("kullanicilar").doc(karsiUid).get();
        if (!karsiSnap.exists) continue;

        const fcmToken = karsiSnap.data()?.fcmToken as string | undefined;
        if (!fcmToken) continue;

        const benimSnap = await db.collection("kullanicilar").doc(uid).get();
        const benimAd = (benimSnap.data()?.adSoyad as string | undefined) ?? "Karşı taraf";

        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "Anlaşma onaylandı! 🤝",
              body: `${benimAd}, "${ilanBaslik}" için anlaşmayı onayladı.`,
            },
            data: {
              tip: "islem",
              sohbetId: sohbetId,
            },
            android: {
              priority: "high",
              notification: {
                channelId: "islem_durumu",
                tag: `${sohbetId}_anlasildi_${uid}`,
              },
            },
          });
        } catch (_) {}
      }
    }
  });