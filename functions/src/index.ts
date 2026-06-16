import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { algoliasearch } from "algoliasearch";
import * as vision from "@google-cloud/vision";
import * as nodemailer from "nodemailer";

admin.initializeApp();

const db = admin.firestore();

// ── Algolia ───────────────────────────────────────────────────────────────────

const ALGOLIA_APP_ID  = "NVHD1ZSPLZ";
const ALGOLIA_API_KEY = "f5dc5bff05386fc3d86df1d1888d5bbd";
const ALGOLIA_INDEX   = "ilanlar";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_API_KEY);

// ── Yasaklı kelimeler ─────────────────────────────────────────────────────────

const YASAKLI_KELIMELER: string[] = [
  // ── Temel kökler (normalize sonrası eşleşir) ──────────────────────────────
  "sik","got","am","yarak","yarrak","orospu","ibne","pic","pust","kahpe",
  "kaltak","orostoban","orostopol","pezevenk","pezeveng","pezevek","kevase",
  "kevaşe","fahise","fahişe","surtuk","sürtük","gavat","kavat","kappe",
  "kahbe","liboş","godoş","gotos","gotveren","dalyarak","dalyarrak",
  "daltassak","tasak","tassak","tasak","taşak","taşşak","atmık","bızır",
  "dingil","duduk","çük","malafat","sakso","saxo","dildo","pipi","pipis",
  // ── am türevleri ──────────────────────────────────────────────────────────
  "amk","amkafa","amcik","amcuk","amcığı","aminako","aminakoyarim",
  "aminakoyim","amına","amina","amindan","amını","amsiz","amsız",
  "amın oglu","amın oğlu","amına koy","amına koyarım","amına koyayım",
  "amına sikem","amına sokam","amınakoyim","amınoğlu","amısına","amısını",
  // ── sik türevleri ─────────────────────────────────────────────────────────
  "siktir","siktirolgit","siktirgit","sikerim","sikeyim","sikiş","sikişme",
  "sikilmis","sikilmiş","sikik","sikim","sikime","sikimle","sikimsonik",
  "sikimtrak","sikmek","siksin","siksiz","siktiğim","siktiğimin",
  "sittir","sittimin","s1kerim","s1ktir","sktrr",
  // ── got türevleri ─────────────────────────────────────────────────────────
  "gotelek","gotlalesi","gotlu","gotunden","gotune","gotunu","gotveren",
  "götdeliği","götelek","götlek","götoğlanı","götoş","götten","götveren",
  "götünekoyim","gotten","gtveren","koca got",
  // ── yarak türevleri ───────────────────────────────────────────────────────
  "yaraksız","yarragi","yarragimi","yarragina","yarragindan","yarrak",
  "yarraminbası","yarrrak","yrrak",
  // ── bok/osur ──────────────────────────────────────────────────────────────
  "bok","boka","bokbok","bombok","boktan","sıçarım","sıçtığım","ossurduum",
  "ossurmak","ossuruk","osuruk","osururum","agzina sicayim","ağzına sıçayım",
  // ── hakaret ───────────────────────────────────────────────────────────────
  "salak","aptal","ahmak","dangalak","gerizekalı","geri zekalı","gerzek",
  "eşşek","eşek","esek","hıyar","hiyar","alçak","alcak","aşağılık",
  "asagilik","rezil","namussuz","haysiyetsiz","şerefsiz","serefsiz",
  "beyinsiz","kafasız","kafasiz","ebleh","embesil","idiot","idiyot",
  "angut","atkafası","lavuk","yavşak","yavşaktır","yavuşak","zibidi",
  "manyak","malak","dallama","serseri","sahtekâr","sahtekar","katil",
  "hırsız","hirsiz","dolandırıcı","dolandirici","cenabet","cibiliyetsiz",
  "cibilliyetini","cibilliyetsiz","dinsiz","imansız","imansz","ebleh",
  "dalaksız","dingil","dkerim","geber","geberik","gebertir","gebermek",
  "gebermiş","giberim","gibiş","revizyon","veled","veled i zina",
  "veledizina","weledizina","weled","zulliyetini","zviyetini","zıkkımım",
  // ── ana/baba hakaretleri ──────────────────────────────────────────────────
  "anani sikerim","anani sikeyim","ananı sikerim","ananı sikeyim",
  "ananın amı","ananın dölü","anasını","anasının am","anasının amı",
  "anasının","anneni","annenin","babanı","babanın","babası pezevenk",
  "bacını","bacının","ebeni","ebenin","ebeninki","ecdadını","ecdadini",
  "sülaleni","sulaleni","sülalenizi","slaleni","laciye boyadım",
  // ── cinsel içerik ─────────────────────────────────────────────────────────
  "seks","seksi","sex","sexs","porno","porn","pornografi","tecavuz","tecavüz",
  "vajina","vajinanı","penis","boşalmak","bosalmak","otuzbir","domalmak",
  "domaltmak","domalmış","domal","domalan","domaldın","yogurtlayam",
  "yoğurtlayam","meme","memelerini","sevişelim","azdım","azdır","azdırıcı",
  "sakso","saxo","boner","kafam girsin",
  // ── uyuşturucu ────────────────────────────────────────────────────────────
  "eroin","esrar","kokain","bonzai","metamfetamin","uyusturucu",
  // ── ingilizce küfür ───────────────────────────────────────────────────────
  "fuck","fucker","fuckin","fucking","shit","bitch","ass","asshole",
  "pussy","whore","bastard","goddamn","motherfucker","madafaka","idiot",
  // ── spam / sosyal medya ───────────────────────────────────────────────────
  "whatsapp","watsap","telegram","instagram","tiktok","snapchat","discord",
  "signal","ozelden yaz","özelden yaz","para kazan","kolay para",
  "garantili kazanc","garantili kazanç","yatirim firsati","yatırım fırsatı",
  "ucretsiz kazan","ücretsiz kazan","bedava kazan","havale","eft",
  "iban","hesap numarasi","kapida ode","kapida odeme",
  // ── kişisel iletişim ──────────────────────────────────────────────────────
  "numaram","adresim","eve gel","buluşalım","bulusalaim",
];

// Tekrar eden harfleri teke indir: "sssikk" → "sik"
function tekrariKaldir(metin: string): string {
  return metin.replace(/(.)\1{2,}/g, "$1");
}

// Türkçe + rakam + sembol normalize
function normalizeMetin(metin: string): string {
  return tekrariKaldir(
    metin
      .toLowerCase()
      // Türkçe karakterler
      .replace(/ş/g, "s").replace(/ç/g, "c").replace(/ğ/g, "g")
      .replace(/ü/g, "u").replace(/ö/g, "o").replace(/ı/g, "i")
      // Rakam bypass
      .replace(/0/g, "o").replace(/1/g, "i").replace(/3/g, "e")
      .replace(/4/g, "a").replace(/5/g, "s").replace(/8/g, "b")
      // Sembol bypass
      .replace(/[@$]/g, "a").replace(/€/g, "e").replace(/\$/g, "s")
      // Noktalama ve boşluk sil
      .replace(/[.\-_*\s!?+]/g, "")
  );
}

// Telefon numarası regex: 05xx, +90, 00 90 vb.
const TELEFON_REGEX = /(\+90|0090|^0)?[\s\-.]?(5\d{2})[\s\-.]?(\d{3})[\s\-.]?(\d{2})[\s\-.]?(\d{2})/;

// URL / link regex
const URL_REGEX = /(https?:\/\/|www\.|\.com|\.net|\.org|\.io|bit\.ly|t\.me)/i;

function metinKontrol(metin: string): { uygun: boolean; sebep: string } {
  if (TELEFON_REGEX.test(metin)) {
    return { uygun: false, sebep: "İlanda telefon numarası paylaşılamaz." };
  }
  if (URL_REGEX.test(metin)) {
    return { uygun: false, sebep: "İlanda dış link paylaşılamaz." };
  }

  const kucuk = metin.toLowerCase();
  const norm  = normalizeMetin(metin);

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

  // LIKELY veya VERY_LIKELY → reddet
  const riskliSeviyeler = new Set(["LIKELY", "VERY_LIKELY"]);

  // Label Detection'da yasaklı etiketler
  const YASAKLI_ETIKETLER = [
    "gun","firearm","weapon","knife","rifle","pistol","explosive",
    "drug","narcotics","cannabis","cocaine","heroin",
    "nudity","explicit","pornography",
  ];

  for (const url of resimUrller.slice(0, 5)) {
    try {
      const [safeResult] = await visionClient.safeSearchDetection(url);
      const safe = safeResult.safeSearchAnnotation;

      if (safe) {
        const str = (v: unknown) => (typeof v === "string" ? v : String(v ?? ""));
        if (
          riskliSeviyeler.has(str(safe.adult)) ||
          riskliSeviyeler.has(str(safe.violence)) ||
          riskliSeviyeler.has(str(safe.racy))
        ) {
          return { uygun: false, sebep: "Resimlerden biri ya da birkaçı ilanınız için uygun değil." };
        }
      }

      // Label detection — silah, uyuşturucu, müstehcen etiket kontrolü
      const [labelResult] = await visionClient.labelDetection(url);
      const etiketler = (labelResult.labelAnnotations ?? []).map(
        (l) => (l.description ?? "").toLowerCase()
      );
      for (const etiket of etiketler) {
        if (YASAKLI_ETIKETLER.some((y) => etiket.includes(y))) {
          return { uygun: false, sebep: "Resimlerden biri ya da birkaçı ilanınız için uygun değil." };
        }
      }
    } catch (e) {
      console.warn("Vision API hatası:", e);
    }
  }
  return { uygun: true, sebep: "" };
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
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: metinSonuc.sebep });
        await Promise.all([
          bildirimGonder(data.kullaniciId, "İlanın yayınlanamadı", metinSonuc.sebep, "ilan_red", ilanId),
          db.collection("bildirimler").add({
            kullaniciId: data.kullaniciId,
            tip:         "ilan_red",
            baslik:      "İlanın yayınlanamadı",
            icerik:      metinSonuc.sebep,
            okundu:      false,
            tarih:       admin.firestore.FieldValue.serverTimestamp(),
            hedefId:     ilanId,
          }),
        ]);
        return;
      }

      // 2. Resim kontrolü (Vision API)
      const resimUrller = (data.resimUrller as string[]) ?? [];
      const resimSonuc = await resimKontrol(resimUrller);
      if (!resimSonuc.uygun) {
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: resimSonuc.sebep });
        await Promise.all([
          bildirimGonder(data.kullaniciId, "İlanın yayınlanamadı", resimSonuc.sebep, "ilan_red", ilanId),
          db.collection("bildirimler").add({
            kullaniciId: data.kullaniciId,
            tip:         "ilan_red",
            baslik:      "İlanın yayınlanamadı",
            icerik:      resimSonuc.sebep,
            okundu:      false,
            tarih:       admin.firestore.FieldValue.serverTimestamp(),
            hedefId:     ilanId,
          }),
        ]);
        return;
      }

      // 3. Metin ve resim geçti → anında yayınla
      await ilanRef.update({ aktif: true, durum: "yayinda" });

      // 4. Bildirim — hata olursa ilanı geri alma, sadece logla
      const ilanAdi = data.urun || `${data.nereden} → ${data.nereye}`;
      try {
        await Promise.all([
          bildirimGonder(
            data.kullaniciId,
            "İlanın yayınlandı",
            `"${ilanAdi}" ilanın aktif.`,
            "ilan_onayla",
            ilanId,
          ),
          db.collection("bildirimler").add({
            kullaniciId: data.kullaniciId,
            tip:         "ilan_onayla",
            baslik:      "İlanın yayınlandı",
            icerik:      `"${ilanAdi}" ilanın aktif.`,
            okundu:      false,
            tarih:       admin.firestore.FieldValue.serverTimestamp(),
            hedefId:     ilanId,
          }),
        ]);
      } catch (e) {
        console.warn("Bildirim gönderilemedi:", e);
      }

      // 5. Algolia — hata olursa ilanı geri alma, sadece logla
      try {
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
            aktif:           true,
            durum:           "yayinda",
            resimUrl:        resimUrller.length > 0 ? resimUrller[0] : (data.resimUrl ?? ""),
            olusturmaTarihi: data.olusturmaTarihi?.toMillis() ?? Date.now(),
          },
        });
      } catch (e) {
        console.warn("Algolia hatası:", e);
      }

    } catch (e) {
      console.error("Moderasyon hatası:", e);
      await ilanRef.update({ aktif: false, durum: "onayBekliyor" });
    }
  });

// ── İlan güncelleme moderasyonu ───────────────────────────────────────────────
// Her içerik düzenlemesinde (metin/resim) yeniden modere eder:
//  • Reddedilmiş ilan uygun hale gelirse → yayınlanır.
//  • Yayındaki ilan uygunsuz hale getirilirse → yayından kaldırılır (reddedilir).

export const ilanGuncellemeModerasyon = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 180, memory: "512MB" })
  .firestore.document("ilanlar/{ilanId}")
  .onUpdate(async (change, context) => {
    const ilanId = context.params.ilanId;
    const once = change.before.data();
    const sonra = change.after.data();
    if (!once || !sonra) return;

    // Sadece içerik (metin/resim) gerçekten değiştiğinde modere et. Böylece
    // favoriSayisi/goruntulenme veya moderasyonun kendi durum/aktif/redSebebi
    // yazımları yeniden moderasyonu tetiklemez → sonsuz döngü olmaz.
    const icerikDegisti =
      once.urun !== sonra.urun ||
      once.notlar !== sonra.notlar ||
      once.nereden !== sonra.nereden ||
      once.nereye !== sonra.nereye ||
      JSON.stringify(once.resimUrller ?? []) !== JSON.stringify(sonra.resimUrller ?? []);
    if (!icerikDegisti) return;

    const ilanRef = db.collection("ilanlar").doc(ilanId);
    const oncedenReddedilmis = sonra.durum === "reddedildi";
    const redBaslik = oncedenReddedilmis ? "İlanın yayınlanamadı" : "İlanın yayından kaldırıldı";

    try {
      // 1. Metin kontrolü
      const tumMetin = [
        sonra.urun ?? "",
        sonra.notlar ?? "",
        sonra.nereden ?? "",
        sonra.nereye ?? "",
      ].join(" ");
      const metinSonuc = metinKontrol(tumMetin);
      if (!metinSonuc.uygun) {
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: metinSonuc.sebep });
        await bildirimGonder(sonra.kullaniciId, redBaslik, metinSonuc.sebep, "ilan_red", ilanId);
        return;
      }

      // 2. Resim kontrolü (Vision API)
      const resimUrller = (sonra.resimUrller as string[]) ?? [];
      const resimSonuc = await resimKontrol(resimUrller);
      if (!resimSonuc.uygun) {
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: resimSonuc.sebep });
        await bildirimGonder(sonra.kullaniciId, redBaslik, resimSonuc.sebep, "ilan_red", ilanId);
        return;
      }

      // 3. Uygun → yayında olduğundan emin ol (zaten yayındaysa gereksiz yazma yok)
      if (sonra.durum !== "yayinda" || sonra.aktif !== true || (sonra.redSebebi ?? "") !== "") {
        await ilanRef.update({ aktif: true, durum: "yayinda", redSebebi: "" });
        // Bildirim sadece daha önce reddedilmiş bir ilan yeniden yayınlanınca anlamlı.
        if (oncedenReddedilmis) {
          await bildirimGonder(
            sonra.kullaniciId,
            "İlanın yayınlandı",
            `"${sonra.urun || sonra.nereden + " → " + sonra.nereye}" ilanın artık yayında.`,
            "ilan_onayla",
            ilanId,
          );
        }
      }
    } catch (e) {
      // Moderasyon hatasında ilanın mevcut durumunu değiştirmeden bırak.
      console.error("Güncelleme moderasyon hatası:", e);
    }
  });

// ── Algolia ───────────────────────────────────────────────────────────────────

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
    const ilanId = context.params.ilanId;

    // Algolia'dan kaldır
    try {
      await algoliaClient.deleteObject({ indexName: ALGOLIA_INDEX, objectID: ilanId });
    } catch (e) {
      console.warn("Algolia silme hatası:", e);
    }

    // İlişkili favoriler ve goruntulenmeler temizliği (admin yetkisiyle — kuralları bypass eder)
    for (const koleksiyon of ["favoriler", "goruntulenmeler"]) {
      try {
        const iliskili = await db.collection(koleksiyon).where("ilanId", "==", ilanId).get();
        if (iliskili.empty) continue;
        const batch = db.batch();
        iliskili.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
      } catch (e) {
        console.warn(`${koleksiyon} temizleme hatası:`, e);
      }
    }
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
    const kullaniciData = kullaniciSnap.data() ?? {};
    const fcmToken = kullaniciData.fcmToken as string | undefined;
    if (!fcmToken) return { success: false };
    // Mesaj bildirimi kapalıysa gönderme
    const mesajTercih = (kullaniciData.bildirimTercihleri?.mesaj ?? true) as boolean;
    if (!mesajTercih) return { success: false };
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
    const hedefData = hedefSnap.data() ?? {};
    const fcmToken = hedefData.fcmToken as string | undefined;
    if (!fcmToken) return;
    // Sistem bildirimi kapalıysa gönderme
    const sistemTercih = (hedefData.bildirimTercihleri?.sistem ?? true) as boolean;
    if (!sistemTercih) return;
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

// ── Bize Ulaşın — Email Gönder ────────────────────────────────────────────────

export const iletisimGonder = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }

    const { konu, mesaj, gonderenAd, gonderenEmail } = data as {
      konu: string;
      mesaj: string;
      gonderenAd: string;
      gonderenEmail: string;
    };

    if (!konu || !mesaj) {
      throw new functions.https.HttpsError("invalid-argument", "Konu ve mesaj zorunlu.");
    }

    const gmailKullanici = process.env.GMAIL_KULLANICI;
    const gmailSifre     = process.env.GMAIL_SIFRE;

    if (!gmailKullanici || !gmailSifre) {
      throw new functions.https.HttpsError("internal", "Email yapılandırması eksik.");
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: { user: gmailKullanici, pass: gmailSifre },
    });

    await transporter.sendMail({
      from: `"İste App" <${gmailKullanici}>`,
      to: gmailKullanici,
      subject: `[İste Destek] ${konu}`,
      html: `
        <h3>${konu}</h3>
        <p><b>Gönderen:</b> ${gonderenAd} (${gonderenEmail})</p>
        <p><b>Kullanıcı ID:</b> ${context.auth.uid}</p>
        <hr/>
        <p>${mesaj.replace(/\n/g, "<br/>")}</p>
      `,
    });

    return { success: true };
  });