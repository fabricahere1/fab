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

export const ilanSilindi = functions
  .region("europe-west1")
  .firestore.document("ilanlar/{ilanId}")
  .onDelete(async (snap, context) => {
    await algoliaClient.deleteObject({
      indexName: ALGOLIA_INDEX,
      objectID:  context.params.ilanId,
    });
  });

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
    await algoliaClient.saveObjects({ indexName: ALGOLIA_INDEX, objects: records });
    return { success: true, count: records.length };
  });

// ── Anlaşma Kabul ─────────────────────────────────────────────────────────────
export const anlasmaKabul = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    const { sohbetId, mesajId } = data as { sohbetId: string; mesajId: string };
    if (!sohbetId || !mesajId) throw new functions.https.HttpsError("invalid-argument", "sohbetId ve mesajId gerekli.");
    const mesajRef = db.collection("sohbetler").doc(sohbetId).collection("mesajlar").doc(mesajId);
    const mesajSnap = await mesajRef.get();
    if (!mesajSnap.exists) throw new functions.https.HttpsError("not-found", "Mesaj bulunamadı.");
    if (mesajSnap.data()!.gondereId === context.auth.uid) throw new functions.https.HttpsError("permission-denied", "Kendi anlaşmanı onaylayamazsın.");
    await mesajRef.update({ anlasmaEvet: true });
    return { success: true };
  });

// ── Anlaşma Red ───────────────────────────────────────────────────────────────
export const anlasmaRed = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    const { sohbetId, mesajId } = data as { sohbetId: string; mesajId: string };
    if (!sohbetId || !mesajId) throw new functions.https.HttpsError("invalid-argument", "sohbetId ve mesajId gerekli.");
    const mesajRef = db.collection("sohbetler").doc(sohbetId).collection("mesajlar").doc(mesajId);
    const mesajSnap = await mesajRef.get();
    if (!mesajSnap.exists) throw new functions.https.HttpsError("not-found", "Mesaj bulunamadı.");
    if (mesajSnap.data()!.gondereId === context.auth.uid) throw new functions.https.HttpsError("permission-denied", "Kendi anlaşmanı reddedemezsin.");
    await mesajRef.update({ anlasmaRed: true });
    return { success: true };
  });

// ── Mesaj Bildirimi ───────────────────────────────────────────────────────────
export const mesajBildirimiGonder = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    const { aliciId, gondereAd, ilanBaslik, sohbetId, metin } = data as {
      aliciId: string; gondereAd: string; ilanBaslik: string; sohbetId: string; metin: string;
    };
    const kullaniciSnap = await db.collection("kullanicilar").doc(aliciId).get();
    if (!kullaniciSnap.exists) return { success: false };
    const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) return { success: false };
    const bildirimMetin = metin && metin.trim().length > 0 ? metin.trim() : ilanBaslik;
    await admin.messaging().send({
      token: fcmToken,
      notification: { title: gondereAd, body: bildirimMetin },
      data: { tip: "mesaj", sohbetId, ilanBaslik },
      android: {
        priority: "high",
        collapseKey: sohbetId,
        notification: { tag: sohbetId, channelId: "mesajlar", ticker: `${gondereAd}: ${bildirimMetin}`, notificationCount: 1 },
      },
      apns: {
        headers: { "apns-collapse-id": sohbetId.substring(0, 64) },
        payload: { aps: { threadId: sohbetId, badge: 1 } },
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
    const { hedefKullaniciId, degerlendireninId, puan } = data as { hedefKullaniciId: string; degerlendireninId: string; puan: number; };
    const degerlendireninSnap = await db.collection("kullanicilar").doc(degerlendireninId).get();
    const degerlendireninAd = (degerlendireninSnap.data()?.adSoyad as string | undefined) ?? "Biri";
    const hedefSnap = await db.collection("kullanicilar").doc(hedefKullaniciId).get();
    const fcmToken = hedefSnap.data()?.fcmToken as string | undefined;
    const yildiz = "⭐".repeat(Math.min(Math.round(puan), 5));
    const bildirimBaslik = "Yeni değerlendirme aldın!";
    const bildirimIcerik = `${degerlendireninAd} seni değerlendirdi ${yildiz}`;
    if (fcmToken) {
      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: { title: bildirimBaslik, body: bildirimIcerik },
          data: { tip: "degerlendirme", hedefKullaniciId },
          android: { priority: "high" },
        });
      } catch (_) {}
    }
    await db.collection("bildirimler").add({
      kullaniciId: hedefKullaniciId, tip: "sistem", baslik: bildirimBaslik, icerik: bildirimIcerik,
      okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: "", gondereId: degerlendireninId, gondereAd: degerlendireninAd,
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
    if (onceki?.islemDurumlari?.teslimAlindi === true || sonraki?.islemDurumlari?.teslimAlindi !== true) return;
    const sohbetId = context.params.sohbetId;
    const kullanicilar: string[] = sonraki.kullanicilar ?? [];
    const ilanBaslik: string = sonraki.ilanBaslik ?? "İlan";
    if (kullanicilar.length < 2) return;
    const batch = db.batch();
    for (const uid of kullanicilar) {
      if (sonraki[`degerlendirmeYapildi_${uid}`] === true) continue;
      const bekleyenRef = db.collection("kullanicilar").doc(uid).collection("bekleyenDegerlendirmeler").doc(sohbetId);
      const mevcutSnap = await bekleyenRef.get();
      if (!mevcutSnap.exists) {
        batch.set(bekleyenRef, { sohbetId, tarih: admin.firestore.FieldValue.serverTimestamp(), tamamlandi: false });
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
          notification: { title: "Değerlendirme zamanı!", body: `"${ilanBaslik}" ilanı tamamlandı. ${karsiAd} için değerlendirme yap.` },
          data: { tip: "degerlendirme", sohbetId },
          android: { priority: "high" },
        });
      } catch (_) {}
      const bildirimRef = db.collection("bildirimler").doc();
      batch.set(bildirimRef, {
        kullaniciId: uid, tip: "degerlendirme", baslik: "Değerlendirme zamanı!",
        icerik: `"${ilanBaslik}" ilanı tamamlandı. ${karsiAd} için değerlendirme yap.`,
        okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: sohbetId, gondereId: karsiUid, gondereAd: karsiAd,
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
      yolaCikti: { baslik: "Ürün yola çıktı! 🚀", icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü yola çıkardı.` },
      teslimEdildi: { baslik: "Ürün teslim edildi! 📦", icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü teslim etti.` },
      teslimAlindi: { baslik: "Ürün teslim alındı! ✅", icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü teslim aldı.` },
      siparisVerildi: { baslik: "Sipariş verildi!", icerik: (ad) => `${ad}, "${ilanBaslik}" için sipariş verdi.` },
      urunAlindi: { baslik: "Ürün alındı!", icerik: (ad) => `${ad}, "${ilanBaslik}" ürününü aldı.` },
    };
    for (const [key, bilgi] of Object.entries(durumBilgileri)) {
      if (oncekiDurumlar[key] === true || sonrakiDurumlar[key] !== true) continue;
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
            notification: { title: bilgi.baslik, body: bilgi.icerik(karsiAd) },
            data: { tip: "islem", sohbetId },
            android: { priority: "high", notification: { channelId: "islem_durumu", tag: `${sohbetId}_${key}` } },
          });
        } catch (_) {}
      }
    }
    for (const uid of kullanicilar) {
      const benimKey = `anlasildi_${uid}`;
      if (oncekiDurumlar[benimKey] === true || sonrakiDurumlar[benimKey] !== true) continue;
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
          notification: { title: "Anlaşma onaylandı! 🤝", body: `${benimAd}, "${ilanBaslik}" için anlaşmayı onayladı.` },
          data: { tip: "islem", sohbetId },
          android: { priority: "high", notification: { channelId: "islem_durumu", tag: `${sohbetId}_anlasildi_${uid}` } },
        });
      } catch (_) {}
    }
  });

// ── 1. İlan Otomatik Pasif (Scheduled) ───────────────────────────────────────
export const ilanOtomatikPasif = functions
  .region("europe-west1")
  .pubsub.schedule("every 24 hours")
  .onRun(async () => {
    const otuzGunOnce = new Date();
    otuzGunOnce.setDate(otuzGunOnce.getDate() - 30);
    const snap = await db.collection("ilanlar")
      .where("aktif", "==", true)
      .where("olusturmaTarihi", "<", admin.firestore.Timestamp.fromDate(otuzGunOnce))
      .get();
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.update(doc.ref, { aktif: false }));
    await batch.commit();
    console.log(`[ilanOtomatikPasif] ${snap.size} ilan pasifleştirildi.`);
  });

// ── 2. İlan Yenileme Hatırlatması (Scheduled) ────────────────────────────────
export const ilanYenilemeHatirlatma = functions
  .region("europe-west1")
  .pubsub.schedule("every 24 hours")
  .onRun(async () => {
    const yirmiYediGunOnce = new Date();
    yirmiYediGunOnce.setDate(yirmiYediGunOnce.getDate() - 27);
    const yirmiSekizGunOnce = new Date();
    yirmiSekizGunOnce.setDate(yirmiSekizGunOnce.getDate() - 28);
    const snap = await db.collection("ilanlar")
      .where("aktif", "==", true)
      .where("olusturmaTarihi", "<", admin.firestore.Timestamp.fromDate(yirmiYediGunOnce))
      .where("olusturmaTarihi", ">", admin.firestore.Timestamp.fromDate(yirmiSekizGunOnce))
      .get();
    for (const doc of snap.docs) {
      const ilan = doc.data();
      const kullaniciId = ilan.kullaniciId as string;
      if (!kullaniciId) continue;
      const kullaniciSnap = await db.collection("kullanicilar").doc(kullaniciId).get();
      const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
      const baslik = "İlanın kapanmak üzere!";
      const icerik = `"${ilan.urun ?? "İlanın"}" 3 gün sonra otomatik kapanacak.`;
      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: { title: baslik, body: icerik },
            data: { tip: "ilan", ilanId: doc.id },
            android: { priority: "high" },
          });
        } catch (_) {}
      }
      await db.collection("bildirimler").add({
        kullaniciId, tip: "sistem", baslik, icerik, okundu: false,
        tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: doc.id, gondereId: "", gondereAd: "İSTE",
      });
    }
    console.log(`[ilanYenilemeHatirlatma] ${snap.size} kullanıcıya bildirim gönderildi.`);
  });

// ── 3. Taşıyıcı-İstekçi Otomatik Eşleştirme ─────────────────────────────────
export const tasiyiciIlanEslestirme = functions
  .region("europe-west1")
  .firestore.document("ilanlar/{ilanId}")
  .onCreate(async (snap, context) => {
    const ilan = snap.data();
    if (!ilan || ilan.tip !== "tasiyici" || !ilan.aktif) return;
    const { nereden, nereye, kullaniciId: tasiyiciId } = ilan as { nereden: string; nereye: string; kullaniciId: string; };
    if (!nereden || !nereye) return;
    const istekSnap = await db.collection("ilanlar")
      .where("tip", "==", "istek")
      .where("aktif", "==", true)
      .where("nereye", "==", nereden)
      .where("nereden", "==", nereye)
      .get();
    const bildirimGonderilen = new Set<string>();
    for (const istekDoc of istekSnap.docs) {
      const istekciId = istekDoc.data().kullaniciId as string;
      if (istekciId === tasiyiciId || bildirimGonderilen.has(istekciId)) continue;
      bildirimGonderilen.add(istekciId);
      const kullaniciSnap = await db.collection("kullanicilar").doc(istekciId).get();
      const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
      const baslik = "Taşıyıcı bulundu!";
      const icerik = `${nereden} → ${nereye} güzergahında yeni bir taşıyıcı var.`;
      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: { title: baslik, body: icerik },
            data: { tip: "ilan", ilanId: context.params.ilanId },
            android: { priority: "high" },
          });
        } catch (_) {}
      }
      await db.collection("bildirimler").add({
        kullaniciId: istekciId, tip: "sistem", baslik, icerik, okundu: false,
        tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: context.params.ilanId, gondereId: tasiyiciId, gondereAd: "İSTE",
      });
    }
    console.log(`[tasiyiciIlanEslestirme] ${bildirimGonderilen.size} istekçiye bildirim gönderildi.`);
  });

// ── 4. Güven Skoru Hesaplama (Scheduled) ─────────────────────────────────────
export const guvenSkoruHesapla = functions
  .region("europe-west1")
  .pubsub.schedule("every 24 hours")
  .onRun(async () => {
    const kullaniciSnap = await db.collection("kullanicilar").get();
    const batch = db.batch();
    for (const kullaniciDoc of kullaniciSnap.docs) {
      const kullanici = kullaniciDoc.data();
      const ortalamaPuan = (kullanici.ortalamaPuan as number) ?? 0;
      const degerlendirmeSayisi = (kullanici.degerlendirmeSayisi as number) ?? 0;
      const degerlendirmePuani = Math.min(50, (ortalamaPuan / 5) * 50 * Math.min(1, degerlendirmeSayisi / 5));
      const ilanSnap = await db.collection("ilanlar")
        .where("kullaniciId", "==", kullaniciDoc.id)
        .where("aktif", "==", true)
        .get();
      const aktivitePuani = Math.min(30, ilanSnap.size * 3);
      let profilPuani = 0;
      if (kullanici.adSoyad) profilPuani += 5;
      if (kullanici.telefon) profilPuani += 5;
      if (kullanici.bulunduguSehir || kullanici.yasadigiUlke) profilPuani += 5;
      if (kullanici.hakkinda) profilPuani += 5;
      const toplamSkor = Math.round(degerlendirmePuani + aktivitePuani + profilPuani);
      batch.update(kullaniciDoc.ref, { guvenSkoru: toplamSkor });
    }
    await batch.commit();
    console.log(`[guvenSkoruHesapla] ${kullaniciSnap.size} kullanıcının güven skoru güncellendi.`);
  });

// ── 5. Rozet Sistemi ──────────────────────────────────────────────────────────
export const rozetKontrol = functions
  .region("europe-west1")
  .firestore.document("degerlendirmeler/{degId}")
  .onCreate(async (snap) => {
    const deg = snap.data();
    if (!deg) return;
    const hedefId = deg.hedefKullaniciId as string;
    if (!hedefId) return;
    const kullaniciRef = db.collection("kullanicilar").doc(hedefId);
    const kullaniciSnap = await kullaniciRef.get();
    if (!kullaniciSnap.exists) return;
    const kullanici = kullaniciSnap.data()!;
    const degerlendirmeSayisi = (kullanici.degerlendirmeSayisi as number) ?? 0;
    const ortalamaPuan = (kullanici.ortalamaPuan as number) ?? 0;
    const mevcutRozetler: string[] = (kullanici.rozetler as string[]) ?? [];
    const yeniRozetler: string[] = [];
    if (degerlendirmeSayisi >= 1 && !mevcutRozetler.includes("ilk_degerlendirme")) yeniRozetler.push("ilk_degerlendirme");
    if (degerlendirmeSayisi >= 10 && !mevcutRozetler.includes("deneyimli")) yeniRozetler.push("deneyimli");
    if (degerlendirmeSayisi >= 50 && !mevcutRozetler.includes("uzman")) yeniRozetler.push("uzman");
    if (degerlendirmeSayisi >= 100 && !mevcutRozetler.includes("efsane")) yeniRozetler.push("efsane");
    if (degerlendirmeSayisi >= 20 && ortalamaPuan >= 4.5 && !mevcutRozetler.includes("super_tasiyici")) yeniRozetler.push("super_tasiyici");
    if (degerlendirmeSayisi >= 10 && ortalamaPuan >= 4.0 && !mevcutRozetler.includes("onayli_istekci")) yeniRozetler.push("onayli_istekci");
    if (yeniRozetler.length === 0) return;
    await kullaniciRef.update({ rozetler: admin.firestore.FieldValue.arrayUnion(...yeniRozetler) });
    const fcmToken = kullanici.fcmToken as string | undefined;
    const rozetAdi: Record<string, string> = {
      ilk_degerlendirme: "İlk Değerlendirme", deneyimli: "Deneyimli Kullanıcı",
      uzman: "Uzman", efsane: "Efsane", super_tasiyici: "Süper Taşıyıcı", onayli_istekci: "Onaylı İstekçi",
    };
    for (const rozet of yeniRozetler) {
      const baslik = "Yeni rozet kazandın!";
      const icerik = `"${rozetAdi[rozet] ?? rozet}" rozetini kazandın.`;
      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: { title: baslik, body: icerik },
            data: { tip: "rozet", rozet },
            android: { priority: "normal" },
          });
        } catch (_) {}
      }
      await db.collection("bildirimler").add({
        kullaniciId: hedefId, tip: "rozet", baslik, icerik, okundu: false,
        tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: "", gondereId: "", gondereAd: "İSTE",
      });
    }
    console.log(`[rozetKontrol] ${hedefId} için ${yeniRozetler.join(", ")} rozeti verildi.`);
  });

// ── 6. Spam Tespiti (Scheduled) ───────────────────────────────────────────────
export const spamTespiti = functions
  .region("europe-west1")
  .pubsub.schedule("every 24 hours")
  .onRun(async () => {
    const birGunOnce = new Date();
    birGunOnce.setDate(birGunOnce.getDate() - 1);
    const snap = await db.collection("ilanlar")
      .where("olusturmaTarihi", ">", admin.firestore.Timestamp.fromDate(birGunOnce))
      .get();
    const sayac: Record<string, number> = {};
    snap.docs.forEach((doc) => {
      const uid = doc.data().kullaniciId as string;
      if (uid) sayac[uid] = (sayac[uid] ?? 0) + 1;
    });
    const batch = db.batch();
    let sayililanlar = 0;
    for (const [uid, sayi] of Object.entries(sayac)) {
      if (sayi > 5) {
        batch.update(db.collection("kullanicilar").doc(uid), {
          spamUyarisi: true,
          spamTarihi: admin.firestore.FieldValue.serverTimestamp(),
          spamIlanSayisi: sayi,
        });
        sayililanlar++;
      }
    }
    await batch.commit();
    console.log(`[spamTespiti] ${sayililanlar} kullanıcı spam olarak işaretlendi.`);
  });

// ── 7. Trend Raporu (Scheduled) ───────────────────────────────────────────────
export const trendRaporu = functions
  .region("europe-west1")
  .pubsub.schedule("every monday 00:00")
  .onRun(async () => {
    const yediGunOnce = new Date();
    yediGunOnce.setDate(yediGunOnce.getDate() - 7);
    const snap = await db.collection("ilanlar")
      .where("tip", "==", "istek")
      .where("olusturmaTarihi", ">", admin.firestore.Timestamp.fromDate(yediGunOnce))
      .get();
    const kategoriSayac: Record<string, number> = {};
    const urunSayac: Record<string, number> = {};
    snap.docs.forEach((doc) => {
      const data = doc.data();
      const kategori = data.kategori as string;
      const urun = (data.urun as string)?.toLowerCase().trim();
      if (kategori) kategoriSayac[kategori] = (kategoriSayac[kategori] ?? 0) + 1;
      if (urun) urunSayac[urun] = (urunSayac[urun] ?? 0) + 1;
    });
    const topUrunler = Object.entries(urunSayac).sort(([, a], [, b]) => b - a).slice(0, 10).map(([urun, sayi]) => ({ urun, sayi }));
    const topKategoriler = Object.entries(kategoriSayac).sort(([, a], [, b]) => b - a).slice(0, 5).map(([kategori, sayi]) => ({ kategori, sayi }));
    await db.collection("trendler").add({
      hafta: admin.firestore.Timestamp.fromDate(yediGunOnce),
      topUrunler, topKategoriler, toplamIlan: snap.size,
      olusturmaTarihi: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`[trendRaporu] Haftalık trend raporu oluşturuldu. ${snap.size} ilan analiz edildi.`);
  });