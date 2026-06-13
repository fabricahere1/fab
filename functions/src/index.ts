import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { algoliasearch } from "algoliasearch";
import * as vision from "@google-cloud/vision";

admin.initializeApp();

const db = admin.firestore();

// ── Algolia ───────────────────────────────────────────────────────────────────

const ALGOLIA_APP_ID  = "NVHD1ZSPLZ";
const ALGOLIA_API_KEY = "f5dc5bff05386fc3d86df1d1888d5bbd";
const ALGOLIA_INDEX   = "ilanlar";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_API_KEY);

// ── Yasaklı kelimeler ─────────────────────────────────────────────────────────

const YASAKLI_KELIMELER: string[] = [
  // Küfür / argo
  "orospu","orsp","orosp","orospu cocugu","orospu çocuğu",
  "siktir","s1kt1r","s1ktir","sikt1r","siктир",
  "amk","amına","amina","amcık","amcik","bok","b0k",
  "yarrak","yarak","y4rak","yarr4k",
  "ibne","1bne","piç","pic","p1c","piçlik","piclik",
  "götveren","gotveren","göt","got",
  "oç","oc","pezevenk","pezeveng",
  "kahpe","kahbe","kaltak","puşt","pust",
  "gavat","g4vat","hıyar","hiyar",
  "sürtük","surtuk","fahişe","fahise",
  "şerefsiz","serefsiz","namussuz","haysiyetsiz",
  "sex","seks","seksi","porn","porno","pornografi",
  "penis","vajina","tecavüz","tecavuz",
  "göğüs","gogus",
  // Hakaret / aşağılama
  "salak","s4lak","aptal","4ptal","ahmak","dangalak",
  "gerizekalı","geri zekalı","gerizekalı",
  "eşşek","esek","eşek","serseri",
  "alçak","alcak","aşağılık","asagilik",
  "rezil","kevaşe","kevase",
  "köpek","kopek","domuz","katil",
  "hırsız","hirsiz","dolandırıcı","dolandirici",
  "sahtekâr","sahtekar",
  // Spam
  "whatsapp","watsap","w4tsapp",
  "telegram","telgram",
  "instagram","instgram",
  "özelden yaz","ozelden yaz",
  "para kazan","kolay para",
  "garantili kazanç","garantili kazanc",
  "yatırım fırsatı","yatirim firsati",
  "ücretsiz kazan","bedava kazan",
  // Kişisel bilgi
  "telefon numarası","telefon numarasi",
  "adresim","eve gel","buluşalım","bulusalaim","numaram",
];

// Rakam→harf, noktalama kaldır
function normalizeMetin(metin: string): string {
  return metin
    .toLowerCase()
    .replace(/0/g, "o").replace(/1/g, "i").replace(/3/g, "e")
    .replace(/4/g, "a").replace(/5/g, "s").replace(/[@]/g, "a")
    .replace(/[.\-_*\s]/g, "");
}

function metinKontrol(metin: string): { uygun: boolean; sebep: string } {
  const kucuk = metin.toLowerCase();
  const norm = normalizeMetin(metin);
  for (const kelime of YASAKLI_KELIMELER) {
    if (kucuk.includes(kelime) || norm.includes(normalizeMetin(kelime))) {
      return { uygun: false, sebep: "İlan açıklaması uygunsuz içerik barındırıyor." };
    }
  }
  if (metin.trim().length > 0 && metin.trim().length < 3) {
    return { uygun: false, sebep: "İlan açıklaması çok kısa." };
  }
  return { uygun: true, sebep: "" };
}

// ── Vision API resim kontrolü ─────────────────────────────────────────────────

const visionClient = new vision.ImageAnnotatorClient();

async function resimKontrol(resimUrller: string[]): Promise<{ uygun: boolean; sebep: string }> {
  if (!resimUrller || resimUrller.length === 0) {
    return { uygun: true, sebep: "" };
  }

  for (const url of resimUrller.slice(0, 4)) {
    try {
      const [result] = await visionClient.safeSearchDetection(url);
      const safe = result.safeSearchAnnotation;
      if (!safe) continue;

      // Sadece VERY_LIKELY ise reddet
      const riskliSeviyeler = ["VERY_LIKELY"];
      const adultStr = typeof safe.adult === "string" ? safe.adult : String(safe.adult ?? "");
      const violenceStr = typeof safe.violence === "string" ? safe.violence : String(safe.violence ?? "");
      const racyStr = typeof safe.racy === "string" ? safe.racy : String(safe.racy ?? "");

      if (
        riskliSeviyeler.includes(adultStr) ||
        riskliSeviyeler.includes(violenceStr) ||
        riskliSeviyeler.includes(racyStr)
      ) {
        return {
          uygun: false,
          sebep: "Resimlerden biri ya da birkaçı ilanınız için uygun değil.",
        };
      }
    } catch (e) {
      // Vision API hatası — resmi geç, diğerine bak
      console.warn("Vision API hatası:", e);
    }
  }
  return { uygun: true, sebep: "" };
}

// ── Güven skoru kontrolü ──────────────────────────────────────────────────────

async function guvenSkoruKontrol(kullaniciId: string): Promise<boolean> {
  const kullaniciSnap = await db.collection("kullanicilar").doc(kullaniciId).get();
  if (!kullaniciSnap.exists) return false;
  const data = kullaniciSnap.data()!;
  const puan = (data.ortalamaPuan as number) ?? 0;
  const degerlendirmeSayisi = (data.degerlendirmeSayisi as number) ?? 0;
  const ilanSayisi = (data.ilanSayisi as number) ?? 0;

  // İlk ilanı — doğrudan onayla (henüz geçmişi yok)
  if (ilanSayisi === 0) return true;

  // 3+ değerlendirme ve 4.0+ puan → otomatik onayla
  if (degerlendirmeSayisi >= 3 && puan >= 4.0) return true;

  // Yeni kullanıcı ama temiz içerik — onayla
  if (degerlendirmeSayisi < 3 && puan === 0) return true;

  return false;
}

// ── FCM bildirimi ─────────────────────────────────────────────────────────────

async function bildirimGonder(
  kullaniciId: string,
  baslik: string,
  mesaj: string,
  tip: string,
  ilanId: string,
): Promise<void> {
  try {
    const kullaniciSnap = await db.collection("kullanicilar").doc(kullaniciId).get();
    const fcmToken = kullaniciSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: { title: baslik, body: mesaj },
      data: { tip, ilanId },
      android: {
        priority: "high",
        notification: { channelId: "ilanlar" },
      },
    });
  } catch (e) {
    console.warn("FCM gönderim hatası:", e);
  }
}

// ── İlan moderasyon fonksiyonu ────────────────────────────────────────────────

export const ilanModerasyonu = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 180, memory: "512MB" })
  .firestore.document("ilanlar/{ilanId}")
  .onCreate(async (snap, context) => {
    const ilanId = context.params.ilanId;
    const data = snap.data();
    if (!data) return;

    const ilanRef = db.collection("ilanlar").doc(ilanId);

    try {
      // 1. Metin kontrolü
      const tumMetin = [
        data.urun ?? "",
        data.notlar ?? "",
        data.nereden ?? "",
        data.nereye ?? "",
      ].join(" ");

      const metinSonuc = metinKontrol(tumMetin);
      if (!metinSonuc.uygun) {
        await ilanRef.update({
          aktif: false,
          durum: "reddedildi",
          redSebebi: metinSonuc.sebep,
        });
        await bildirimGonder(
          data.kullaniciId,
          "İlanın yayınlanamadı",
          metinSonuc.sebep,
          "ilan_red",
          ilanId,
        );
        return;
      }

      // 2. Resim kontrolü (Vision API)
      const resimUrller = (data.resimUrller as string[]) ?? [];
      const resimSonuc = await resimKontrol(resimUrller);
      if (!resimSonuc.uygun) {
        await ilanRef.update({
          aktif: false,
          durum: "reddedildi",
          redSebebi: resimSonuc.sebep,
        });
        await bildirimGonder(
          data.kullaniciId,
          "İlanın yayınlanamadı",
          resimSonuc.sebep,
          "ilan_red",
          ilanId,
        );
        return;
      }

      // 3. Güven skoru kontrolü
      const guvenliMi = await guvenSkoruKontrol(data.kullaniciId);

      if (guvenliMi) {
        // 2 dakika bekle, sonra otomatik onayla
        await new Promise(resolve => setTimeout(resolve, 2 * 60 * 1000));
        await ilanRef.update({
          aktif: true,
          durum: "yayinda",
        });
        await bildirimGonder(
          data.kullaniciId,
          "İlanın yayınlandı! 🎉",
          `"${data.urun || data.nereden + " → " + data.nereye}" ilanın aktif.`,
          "ilan_onayla",
          ilanId,
        );
      } else {
        // Manuel onay kuyruğuna al
        await ilanRef.update({
          aktif: false,
          durum: "onayBekliyor",
        });
        await bildirimGonder(
          data.kullaniciId,
          "İlanın incelemeye alındı",
          "İlanın kısa süre içinde incelenecek ve yayınlanacak.",
          "ilan_bekliyor",
          ilanId,
        );
      }

      // 4. Algolia'ya ekle (sadece aktifse)
      await algoliaClient.saveObject({
        indexName: ALGOLIA_INDEX,
        body: {
          objectID:        ilanId,
          urun:            data.urun            ?? "",
          nereden:         data.nereden         ?? "",
          nereye:          data.nereye          ?? "",
          kategori:        data.kategori        ?? "",
          anaKategori:     data.anaKategori     ?? "",
          kategoriYolu:    data.kategoriYolu    ?? [],
          tip:             data.tip             ?? "",
          aktif:           guvenliMi,
          durum:           guvenliMi ? "yayinda" : "onayBekliyor",
          resimUrl:        resimUrller.length > 0 ? resimUrller[0] : (data.resimUrl ?? ""),
          olusturmaTarihi: data.olusturmaTarihi?.toMillis() ?? Date.now(),
        },
      });

    } catch (e) {
      console.error("Moderasyon hatası:", e);
      // Hata durumunda ilanı yayınla (kullanıcıyı bekletme)
      await ilanRef.update({
        aktif: true,
        durum: "yayinda",
      });
    }
  });

// ── Algolia ───────────────────────────────────────────────────────────────────

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
        aktif:           data.aktif           ?? false,
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
        aktif:           data.aktif           ?? false,
        durum:           data.durum           ?? "onayBekliyor",
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
        aktif:           data.aktif           ?? false,
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
    const { hedefKullaniciId, degerlendireninId, puan } = data as {
      hedefKullaniciId: string; degerlendireninId: string; puan: number;
    };
    const degerlendireninSnap = await db.collection("kullanicilar").doc(degerlendireninId).get();
    const degerlendireninAd = (degerlendireninSnap.data()?.adSoyad as string | undefined) ?? "Biri";
    const hedefSnap = await db.collection("kullanicilar").doc(hedefKullaniciId).get();
    const fcmToken = hedefSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) return;
    const yildizlar = "⭐".repeat(Math.min(puan, 5));
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Yeni değerlendirme aldın!",
        body: `${degerlendireninAd} seni ${yildizlar} olarak değerlendirdi.`,
      },
      data: { tip: "degerlendirme", hedefKullaniciId },
      android: {
        priority: "high",
        notification: { channelId: "genel" },
      },
    });
  });