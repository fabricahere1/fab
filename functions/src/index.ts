import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { algoliasearch } from "algoliasearch";
import * as vision from "@google-cloud/vision";
import * as nodemailer from "nodemailer";

admin.initializeApp();

const db = admin.firestore();

// ── Algolia ───────────────────────────────────────────────────────────────────

const ALGOLIA_INDEX        = "ilanlar";
const ALGOLIA_INDEX_NEREYE = "ilanlar_nereye";

let _algoliaClient: ReturnType<typeof algoliasearch> | null = null;
function getAlgoliaClient() {
  if (!_algoliaClient) {
    _algoliaClient = algoliasearch(
      process.env.ALGOLIA_APP_ID  ?? "",
      process.env.ALGOLIA_API_KEY ?? "",
    );
  }
  return _algoliaClient;
}

// ── Önerilen Puan Hesaplama ───────────────────────────────────────────────────
//
// favoriSayisi × 3 + goruntulenmeSayisi × 1 + kullaniciPuan × 5
// + tazelikPuani (son 24s=10, 3g=6, 7g=3, 30g=1)
// + resimPuani  (5+=5, 3-4=3, 1-2=1, 0=0)

function onerilenPuanHesapla(data: FirebaseFirestore.DocumentData): number {
  const favori      = (data.favoriSayisi      ?? 0) as number;
  const goruntuleme = (data.goruntulenmeSayisi ?? 0) as number;
  const guven       = (data.kullaniciPuan      ?? 0) as number;
  const resimSayisi = ((data.resimUrller as string[] | undefined) ?? []).length;

  const now     = Date.now();
  const tarihMs = (data.olusturmaTarihi as admin.firestore.Timestamp | undefined)?.toMillis?.() ?? now;
  const gunFark = (now - tarihMs) / (1000 * 60 * 60 * 24);
  let tazelik   = 0;
  if      (gunFark < 1)  tazelik = 10;
  else if (gunFark < 3)  tazelik = 6;
  else if (gunFark < 7)  tazelik = 3;
  else if (gunFark < 30) tazelik = 1;

  let resimPuan = 0;
  if      (resimSayisi >= 5) resimPuan = 5;
  else if (resimSayisi >= 3) resimPuan = 3;
  else if (resimSayisi >= 1) resimPuan = 1;

  return Math.round(favori * 3 + goruntuleme * 1 + guven * 5 + tazelik + resimPuan);
}

// ── Yasaklı kelimeler ─────────────────────────────────────────────────────────

const YASAKLI_KELIMELER: string[] = [
  "sik","got","am","yarak","yarrak","orospu","ibne","pic","pust","kahpe",
  "kaltak","orostoban","orostopol","pezevenk","pezeveng","pezevek","kevase",
  "kevaşe","fahise","fahişe","surtuk","sürtük","gavat","kavat","kappe",
  "kahbe","liboş","godoş","gotos","gotveren","dalyarak","dalyarrak",
  "daltassak","tasak","tassak","taşak","taşşak","atmık","bızır",
  "dingil","duduk","çük","malafat","sakso","saxo","dildo","pipi","pipis",
  "amk","amkafa","amcik","amcuk","amcığı","aminako","aminakoyarim",
  "aminakoyim","amına","amina","amindan","amını","amsiz","amsız",
  "amın oglu","amın oğlu","amına koy","amına koyarım","amına koyayım",
  "amına sikem","amına sokam","amınakoyim","amınoğlu","amısına","amısını",
  "siktir","siktirolgit","siktirgit","sikerim","sikeyim","sikiş","sikişme",
  "sikilmis","sikilmiş","sikik","sikim","sikime","sikimle","sikimsonik",
  "sikimtrak","sikmek","siksin","siksiz","siktiğim","siktiğimin",
  "sittir","sittimin","s1kerim","s1ktir","sktrr",
  "gotelek","gotlalesi","gotlu","gotunden","gotune","gotunu","gotveren",
  "götdeliği","götelek","götlek","götoğlanı","götoş","götten","götveren",
  "götünekoyim","gotten","gtveren","koca got",
  "yaraksız","yarragi","yarragimi","yarragina","yarragindan","yarrak",
  "yarraminbası","yarrrak","yrrak",
  "bok","boka","bokbok","bombok","boktan","sıçarım","sıçtığım","ossurduum",
  "ossurmak","ossuruk","osuruk","osururum","agzina sicayim","ağzına sıçayım",
  "salak","aptal","ahmak","dangalak","gerizekalı","geri zekalı","gerzek",
  "eşşek","eşek","esek","hıyar","hiyar","alçak","alcak","aşağılık",
  "asagilik","rezil","namussuz","haysiyetsiz","şerefsiz","serefsiz",
  "beyinsiz","kafasız","kafasiz","ebleh","embesil","idiot","idiyot",
  "angut","atkafası","lavuk","yavşak","yavşaktır","yavuşak","zibidi",
  "manyak","malak","dallama","serseri","sahtekâr","sahtekar","katil",
  "hırsız","hirsiz","dolandırıcı","dolandirici","cenabet","cibiliyetsiz",
  "cibilliyetini","cibilliyetsiz","dinsiz","imansız","imansz",
  "dalaksız","dkerim","geber","geberik","gebertir","gebermek",
  "gebermiş","giberim","gibiş","veled","veled i zina",
  "veledizina","weledizina","weled","zulliyetini","zviyetini","zıkkımım",
  "anani sikerim","anani sikeyim","ananı sikerim","ananı sikeyim",
  "ananın amı","ananın dölü","anasını","anasının am","anasının amı",
  "anneni","annenin","babanı","babanın","babası pezevenk",
  "bacını","bacının","ebeni","ebenin","ebeninki","ecdadını","ecdadini",
  "sülaleni","sulaleni","sülalenizi","slaleni","laciye boyadım",
  "seks","seksi","sex","sexs","porno","porn","pornografi","tecavuz","tecavüz",
  "vajina","vajinanı","penis","boşalmak","bosalmak","otuzbir","domalmak",
  "domaltmak","domalmış","domal","domalan","domaldın","yogurtlayam",
  "yoğurtlayam","meme","memelerini","sevişelim","azdım","azdır","azdırıcı",
  "sakso","saxo","boner","kafam girsin",
  "eroin","esrar","kokain","bonzai","metamfetamin","uyusturucu",
  "fuck","fucker","fuckin","fucking","shit","bitch","ass","asshole",
  "pussy","whore","bastard","goddamn","motherfucker","madafaka",
  "whatsapp","watsap","telegram","instagram","tiktok","snapchat","discord",
  "signal","ozelden yaz","özelden yaz","para kazan","kolay para",
  "garantili kazanc","garantili kazanç","yatirim firsati","yatırım fırsatı",
  "ucretsiz kazan","ücretsiz kazan","bedava kazan","havale","eft",
  "iban","hesap numarasi","kapida ode","kapida odeme",
  "numaram","adresim","eve gel","buluşalım","bulusalaim",
];

function tekrariKaldir(metin: string): string {
  return metin.replace(/(.)\1{2,}/g, "$1");
}

function normalizeMetin(metin: string): string {
  return tekrariKaldir(
    metin
      .toLowerCase()
      .replace(/ş/g, "s").replace(/ç/g, "c").replace(/ğ/g, "g")
      .replace(/ü/g, "u").replace(/ö/g, "o").replace(/ı/g, "i")
      .replace(/0/g, "o").replace(/1/g, "i").replace(/3/g, "e")
      .replace(/4/g, "a").replace(/5/g, "s").replace(/8/g, "b")
      .replace(/[@$]/g, "a").replace(/€/g, "e").replace(/\$/g, "s")
      .replace(/[.\-_*!?+]/g, "")
      .replace(/\s+/g, " ")
      .trim()
  );
}

const TELEFON_REGEX = /(\+90|0090|^0)?[\s\-.]?(5\d{2})[\s\-.]?(\d{3})[\s\-.]?(\d{2})[\s\-.]?(\d{2})/;
const URL_REGEX     = /(https?:\/\/|www\.|\.com|\.net|\.org|\.io|bit\.ly|t\.me)/i;

function regexEscape(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function kelimeRegexCache(): Map<string, RegExp> {
  if (!_kelimeRegexCache) {
    _kelimeRegexCache = new Map();
    for (const kelime of YASAKLI_KELIMELER) {
      // \b kelime sınırı: kelime başka bir kelimenin (örn. "Mozambik" içindeki "am")
      // parçası olarak değil, tek başına geçtiğinde eşleşsin.
      _kelimeRegexCache.set(kelime, new RegExp(`\\b${regexEscape(kelime)}\\b`, "i"));
    }
  }
  return _kelimeRegexCache;
}
let _kelimeRegexCache: Map<string, RegExp> | null = null;

function metinKontrol(metin: string): { uygun: boolean; sebep: string } {
  if (TELEFON_REGEX.test(metin)) {
    return { uygun: false, sebep: "İlanda telefon numarası paylaşılamaz." };
  }
  if (URL_REGEX.test(metin)) {
    return { uygun: false, sebep: "İlanda dış link paylaşılamaz." };
  }
  const kucuk   = metin.toLowerCase();
  const norm    = normalizeMetin(metin);
  const regexes = kelimeRegexCache();
  for (const kelime of YASAKLI_KELIMELER) {
    const regex = regexes.get(kelime)!;
    if (regex.test(kucuk) || regex.test(norm)) {
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
  if (!resimUrller || resimUrller.length === 0) return { uygun: true, sebep: "" };

  const riskliSeviyeler = new Set(["LIKELY", "VERY_LIKELY"]);
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
    const kullaniciData = kullaniciSnap.data() ?? {};
    const ilanTercih    = (kullaniciData.bildirimTercihleri?.ilan ?? true) as boolean;
    if (!ilanTercih) return;
    const fcmToken = kullaniciData.fcmToken as string | undefined;
    if (!fcmToken) return;
    await admin.messaging().send({
      token: fcmToken,
      notification: { title: baslik, body: mesaj },
      data: { tip, ilanId },
      android: { priority: "high", notification: { channelId: "ilanlar" } },
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
    const data   = snap.data();
    if (!data) return;

    const ilanRef     = db.collection("ilanlar").doc(ilanId);
    const kullaniciId = data.kullaniciId as string;

    try {
      // nereden/nereye artık Flutter formunda kapalı listeden (ülke/şehir) seçiliyor,
      // serbest metin girilemiyor — bu yüzden kelime/telefon/link kontrolüne dahil etmiyoruz.
      const tumMetin = [
        data.urun ?? "", data.notlar ?? "",
      ].join(" ");

      const metinSonuc = metinKontrol(tumMetin);
      if (!metinSonuc.uygun) {
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: metinSonuc.sebep });
        await Promise.all([
          bildirimGonder(kullaniciId, "İlanın yayınlanamadı", metinSonuc.sebep, "ilan_red", ilanId),
          db.collection("bildirimler").add({
            kullaniciId, tip: "ilan_red",
            baslik: "İlanın yayınlanamadı", icerik: metinSonuc.sebep,
            okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: ilanId,
          }),
        ]);
        return;
      }

      const resimUrller  = (data.resimUrller as string[]) ?? [];
      const resimSonuc   = await resimKontrol(resimUrller);
      if (!resimSonuc.uygun) {
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: resimSonuc.sebep });
        await Promise.all([
          bildirimGonder(kullaniciId, "İlanın yayınlanamadı", resimSonuc.sebep, "ilan_red", ilanId),
          db.collection("bildirimler").add({
            kullaniciId, tip: "ilan_red",
            baslik: "İlanın yayınlanamadı", icerik: resimSonuc.sebep,
            okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: ilanId,
          }),
        ]);
        return;
      }

      // Yayınla + önerilen puan hesapla
      const onerilenPuan = onerilenPuanHesapla(data);
      await ilanRef.update({ aktif: true, durum: "yayinda", onerilenPuan });

      const ilanAdi = data.urun || `${data.nereden} → ${data.nereye}`;
      try {
        await Promise.all([
          bildirimGonder(kullaniciId, "İlanın yayınlandı", `"${ilanAdi}" ilanın aktif.`, "ilan_onayla", ilanId),
          db.collection("bildirimler").add({
            kullaniciId, tip: "ilan_onayla",
            baslik: "İlanın yayınlandı", icerik: `"${ilanAdi}" ilanın aktif.`,
            okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: ilanId,
          }),
        ]);
      } catch (e) { console.warn("Bildirim gönderilemedi:", e); }

      try {
        await getAlgoliaClient().saveObject({
          indexName: ALGOLIA_INDEX,
          body: {
            objectID:        ilanId,
            urun:            data.urun         ?? "",
            nereden:         data.nereden      ?? "",
            nereye:          data.nereye       ?? "",
            kategori:        data.kategori     ?? "",
            anaKategori:     data.anaKategori  ?? "",
            kategoriYolu:    data.kategoriYolu ?? [],
            tip:             data.tip          ?? "",
            aktif:           true,
            durum:           "yayinda",
            kullaniciId,
            kullaniciAd:        data.kullaniciAd ?? "",
            resimUrl:           resimUrller.length > 0 ? resimUrller[0] : (data.resimUrl ?? ""),
            olusturmaTarihi:    data.olusturmaTarihi?.toMillis() ?? Date.now(),
            favoriSayisi:       data.favoriSayisi       ?? 0,
            goruntulenmeSayisi: data.goruntulenmeSayisi ?? 0,
            onerilenPuan,
          },
        });
      } catch (e) { console.warn("Algolia hatası:", e); }

      // Nereye index'ine yaz
      try {
        await getAlgoliaClient().saveObject({
          indexName: ALGOLIA_INDEX_NEREYE,
          body: {
            objectID: ilanId,
            nereye:   data.nereye ?? "",
          },
        });
      } catch (e) { console.warn("Algolia nereye hatası:", e); }

    } catch (e) {
      console.error("Moderasyon hatası:", e);
      await ilanRef.update({ aktif: false, durum: "onayBekliyor" });
    }
  });

// ── İlan güncelleme moderasyonu ───────────────────────────────────────────────

export const ilanGuncellemeModerasyon = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 180, memory: "512MB" })
  .firestore.document("ilanlar/{ilanId}")
  .onUpdate(async (change, context) => {
    const ilanId = context.params.ilanId;
    const once   = change.before.data();
    const sonra  = change.after.data();
    if (!once || !sonra) return;

    const icerikDegisti =
      once.urun    !== sonra.urun    ||
      once.notlar  !== sonra.notlar  ||
      once.nereden !== sonra.nereden ||
      once.nereye  !== sonra.nereye  ||
      JSON.stringify(once.resimUrller ?? []) !== JSON.stringify(sonra.resimUrller ?? []);
    // İlan reddedilmiş durumdayken kullanıcı "Yayınla"ya basınca durum
    // "reddedildi"→"onayBekliyor" geçişi yapar. once.durum bakarak tetikliyoruz;
    // yoksa sonra.durum zaten "onayBekliyor" olacağı için hiç tetiklenmez.
    const yenidenDenenmeliMi = once.durum === "reddedildi" && sonra.durum === "onayBekliyor";
    if (!icerikDegisti && !yenidenDenenmeliMi) return;

    const ilanRef           = db.collection("ilanlar").doc(ilanId);
    const oncedenReddedilmis = once.durum === "reddedildi";
    const redBaslik          = oncedenReddedilmis ? "İlanın yayınlanamadı" : "İlanın yayından kaldırıldı";

    try {
      // nereden/nereye artık Flutter formunda kapalı listeden (ülke/şehir) seçiliyor,
      // serbest metin girilemiyor — bu yüzden kelime/telefon/link kontrolüne dahil etmiyoruz.
      const tumMetin = [
        sonra.urun ?? "", sonra.notlar ?? "",
      ].join(" ");
      const metinSonuc = metinKontrol(tumMetin);
      if (!metinSonuc.uygun) {
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: metinSonuc.sebep });
        await Promise.all([
          bildirimGonder(sonra.kullaniciId, redBaslik, metinSonuc.sebep, "ilan_red", ilanId),
          db.collection("bildirimler").add({
            kullaniciId: sonra.kullaniciId, tip: "ilan_red",
            baslik: redBaslik, icerik: metinSonuc.sebep,
            okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: ilanId,
          }),
        ]);
        return;
      }

      const resimUrller = (sonra.resimUrller as string[]) ?? [];
      const resimSonuc  = await resimKontrol(resimUrller);
      if (!resimSonuc.uygun) {
        await ilanRef.update({ aktif: false, durum: "reddedildi", redSebebi: resimSonuc.sebep });
        await Promise.all([
          bildirimGonder(sonra.kullaniciId, redBaslik, resimSonuc.sebep, "ilan_red", ilanId),
          db.collection("bildirimler").add({
            kullaniciId: sonra.kullaniciId, tip: "ilan_red",
            baslik: redBaslik, icerik: resimSonuc.sebep,
            okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: ilanId,
          }),
        ]);
        return;
      }

      if (sonra.durum !== "yayinda" || sonra.aktif !== true || (sonra.redSebebi ?? "") !== "") {
        await ilanRef.update({ aktif: true, durum: "yayinda", redSebebi: "" });
        if (oncedenReddedilmis) {
          const onayIcerik = `"${sonra.urun || sonra.nereden + " → " + sonra.nereye}" ilanın artık yayında.`;
          await Promise.all([
            bildirimGonder(sonra.kullaniciId, "İlanın yayınlandı", onayIcerik, "ilan_onayla", ilanId),
            db.collection("bildirimler").add({
              kullaniciId: sonra.kullaniciId, tip: "ilan_onayla",
              baslik: "İlanın yayınlandı", icerik: onayIcerik,
              okundu: false, tarih: admin.firestore.FieldValue.serverTimestamp(), hedefId: ilanId,
            }),
          ]);
        }
      }
    } catch (e) { console.error("Güncelleme moderasyon hatası:", e); }
  });

// ── Algolia güncelleme (favori/görüntülenme değişince önerilen puan da güncellenir) ──────

export const ilanGuncellendi = functions
  .region("europe-west1")
  .firestore.document("ilanlar/{ilanId}")
  .onUpdate(async (change, context) => {
    const data = change.after.data();
    if (!data) return;

    // Sadece yayındaki ilanlar için Algolia'yı güncelle
    if (data.aktif !== true || data.durum !== "yayinda") return;

    const onerilenPuan = onerilenPuanHesapla(data);

    // Firestore'a da yaz (sonsuz döngü yok çünkü ilanGuncellemeModerasyon sadece içerik değişiminde tetiklenir)
    try {
      await db.collection("ilanlar").doc(context.params.ilanId).update({ onerilenPuan });
    } catch (e) { console.warn("onerilenPuan Firestore hatası:", e); }

    try {
      await getAlgoliaClient().saveObject({
        indexName: ALGOLIA_INDEX,
        body: {
          objectID:           context.params.ilanId,
          urun:               data.urun              ?? "",
          nereden:            data.nereden           ?? "",
          nereye:             data.nereye            ?? "",
          kategori:           data.kategori          ?? "",
          anaKategori:        data.anaKategori        ?? "",
          kategoriYolu:       data.kategoriYolu       ?? [],
          tip:                data.tip               ?? "",
          aktif:              data.aktif             ?? false,
          durum:              data.durum             ?? "onayBekliyor",
          kullaniciId:        data.kullaniciId        ?? "",
          kullaniciAd:        data.kullaniciAd        ?? "",
          resimUrl:           (data.resimUrller && data.resimUrller.length > 0)
                                ? data.resimUrller[0] : (data.resimUrl ?? ""),
          olusturmaTarihi:    data.olusturmaTarihi?.toMillis() ?? Date.now(),
          favoriSayisi:       data.favoriSayisi      ?? 0,
          goruntulenmeSayisi: data.goruntulenmeSayisi ?? 0,
          onerilenPuan,
        },
      });
    } catch (e) { console.warn("Algolia hatası:", e); }

    // Nereye index'ini güncelle
    try {
      await getAlgoliaClient().saveObject({
        indexName: ALGOLIA_INDEX_NEREYE,
        body: {
          objectID: context.params.ilanId,
          nereye:   data.nereye ?? "",
        },
      });
    } catch (e) { console.warn("Algolia nereye hatası:", e); }
  });

export const ilanSilindi = functions
  .region("europe-west1")
  .firestore.document("ilanlar/{ilanId}")
  .onDelete(async (snap, context) => {
    const ilanId = context.params.ilanId;
    try {
      await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX, objectID: ilanId });
    } catch (e) { console.warn("Algolia silme hatası:", e); }
    try {
      await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX_NEREYE, objectID: ilanId });
    } catch (e) { console.warn("Algolia nereye silme hatası:", e); }

    for (const koleksiyon of ["favoriler", "goruntulenmeler"]) {
      try {
        const iliskili = await db.collection(koleksiyon).where("ilanId", "==", ilanId).get();
        if (iliskili.empty) continue;
        const batch = db.batch();
        iliskili.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
      } catch (e) { console.warn(`${koleksiyon} temizleme hatası:`, e); }
    }
  });

export const algoliaTopluAktar = functions
  .region("europe-west1")
  .https.onCall(async (_, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }
    const snap    = await db.collection("ilanlar").get();
    const records = snap.docs.map((doc) => {
      const data         = doc.data();
      const onerilenPuan = onerilenPuanHesapla(data);
      return {
        objectID:        doc.id,
        urun:            data.urun         ?? "",
        nereden:         data.nereden      ?? "",
        nereye:          data.nereye       ?? "",
        kategori:        data.kategori     ?? "",
        anaKategori:     data.anaKategori  ?? "",
        kategoriYolu:    data.kategoriYolu ?? [],
        tip:             data.tip          ?? "",
        aktif:           data.aktif        ?? false,
        durum:           data.durum        ?? "onayBekliyor",
        kullaniciId:        data.kullaniciId ?? "",
        kullaniciAd:        data.kullaniciAd ?? "",
        resimUrl:           (data.resimUrller && data.resimUrller.length > 0)
                              ? data.resimUrller[0] : (data.resimUrl ?? ""),
        olusturmaTarihi:    data.olusturmaTarihi?.toMillis() ?? Date.now(),
        favoriSayisi:       data.favoriSayisi       ?? 0,
        goruntulenmeSayisi: data.goruntulenmeSayisi ?? 0,
        onerilenPuan,
      };
    });
    await getAlgoliaClient().saveObjects({ indexName: ALGOLIA_INDEX, objects: records });

    // Nereye index'ini toplu aktar
    const nereyeRecords = snap.docs.map((doc) => ({
      objectID: doc.id,
      nereye:   doc.data().nereye ?? "",
    }));
    await getAlgoliaClient().saveObjects({ indexName: ALGOLIA_INDEX_NEREYE, objects: nereyeRecords });

    return { success: true, count: records.length };
  });

// ── Anlaşma Kabul ─────────────────────────────────────────────────────────────

export const anlasmaKabul = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    const { sohbetId, mesajId } = data as { sohbetId: string; mesajId: string };
    if (!sohbetId || !mesajId) throw new functions.https.HttpsError("invalid-argument", "sohbetId ve mesajId gerekli.");
    const mesajRef  = db.collection("sohbetler").doc(sohbetId).collection("mesajlar").doc(mesajId);
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
    const mesajRef  = db.collection("sohbetler").doc(sohbetId).collection("mesajlar").doc(mesajId);
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
    const { aliciId, gondereAd, ilanBaslik, sohbetId, metin, ilanId, ilanSahibiId } = data as {
      aliciId: string; gondereAd: string; ilanBaslik: string; sohbetId: string; metin: string; ilanId: string; ilanSahibiId: string;
    };
    const gondereId = context.auth.uid;
    const kullaniciSnap = await db.collection("kullanicilar").doc(aliciId).get();
    if (!kullaniciSnap.exists) return { success: false };
    const kullaniciData  = kullaniciSnap.data() ?? {};
    const bildirimMetin  = metin && metin.trim().length > 0 ? metin.trim() : ilanBaslik;

    // Uygulama içi bildirim çanı — push tercihi/token durumundan bağımsız,
    // her zaman yazılır. Bell, bu koleksiyonu dinler.
    await db.collection("bildirimler").add({
      kullaniciId: aliciId,
      tip:         "mesaj",
      baslik:      gondereAd,
      icerik:      `${ilanBaslik} hakkında mesaj gönderdi`,
      okundu:      false,
      tarih:       admin.firestore.FieldValue.serverTimestamp(),
      hedefId:     sohbetId,
      gondereId:   gondereId,
      gondereAd:   gondereAd,
    });

    // Push bildirimi — token yoksa veya kullanıcı kapattıysa sessizce atla.
    const fcmToken    = kullaniciData.fcmToken as string | undefined;
    const mesajTercih = (kullaniciData.bildirimTercihleri?.mesaj ?? true) as boolean;
    if (!fcmToken || !mesajTercih) return { success: true };

    await admin.messaging().send({
      token: fcmToken,
      notification: { title: gondereAd, body: bildirimMetin },
      data: { tip: "mesaj", sohbetId, ilanBaslik, ilanId: ilanId ?? "", ilanSahibiId: ilanSahibiId ?? "", karsiKullaniciId: gondereId, karsiKullaniciAd: gondereAd },
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
    const degerlendireninAd   = (degerlendireninSnap.data()?.adSoyad as string | undefined) ?? "Biri";
    const hedefSnap           = await db.collection("kullanicilar").doc(hedefKullaniciId).get();
    const hedefData           = hedefSnap.data() ?? {};
    const fcmToken            = hedefData.fcmToken as string | undefined;
    if (!fcmToken) return;
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
      android: { priority: "high", notification: { channelId: "genel" } },
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
      konu: string; mesaj: string; gonderenAd: string; gonderenEmail: string;
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
      from:    `"İste App" <${gmailKullanici}>`,
      to:      gmailKullanici,
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

// ── Hesap Sil (Sunucu Tarafı) ──────────────────────────────────────────────
//
// Bu fonksiyon, admin SDK ile çalıştığı için Firestore güvenlik kurallarına
// HİÇ tabi değil — bu yüzden client'ta "karşı tarafın mesajını silme" gibi
// kural gevşetmelerine ihtiyaç kalmıyor. Tüm silme işlemi (kullanicilar +
// ilanlar + favoriler + bildirimler + sohbetler + mesajlar alt-koleksiyonu +
// Firebase Auth kaydı) burada, SIRALI ve TEK YERDEN yönetiliyor — client
// tarafındaki ayrı ayrı batch'lerin arasında bir adım başarısız olup
// "yarım silinmiş hesap" durumuna düşme riski ortadan kalkıyor.
export const hesapSilSunucu = functions
  .region("europe-west1")
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısın.");
    }
    const uid = context.auth.uid;

    try {
      const batch = db.batch();

      batch.delete(db.collection("kullanicilar").doc(uid));

      const ilanlarSnap = await db.collection("ilanlar")
        .where("kullaniciId", "==", uid).get();
      for (const doc of ilanlarSnap.docs) batch.delete(doc.ref);

      const favorilerSnap = await db.collection("favoriler")
        .where("kullaniciId", "==", uid).get();
      for (const doc of favorilerSnap.docs) batch.delete(doc.ref);

      const bildirimlerSnap = await db.collection("bildirimler")
        .where("kullaniciId", "==", uid).get();
      for (const doc of bildirimlerSnap.docs) batch.delete(doc.ref);

      await batch.commit();

      // Sohbetler + mesajlar — subcollection içerdiğinden ayrı siliniyor
      const sohbetlerSnap = await db.collection("sohbetler")
        .where("kullanicilar", "array-contains", uid).get();

      for (const sohbet of sohbetlerSnap.docs) {
        const mesajlarSnap = await sohbet.ref.collection("mesajlar").get();
        const mesajBatch = db.batch();
        for (const mesaj of mesajlarSnap.docs) mesajBatch.delete(mesaj.ref);
        mesajBatch.delete(sohbet.ref);
        await mesajBatch.commit();
      }

      // Firebase Authentication kaydı — EN SON adım. Yukarıdaki Firestore
      // silme işlemlerinden biri patlarsa, buraya hiç ulaşılmaz ve
      // kullanıcı hâlâ giriş yapabilir durumda kalır — bu da onun tekrar
      // deneyebilmesi için doğru davranış.
      await admin.auth().deleteUser(uid);

      return { success: true };
    } catch (e) {
      console.error("hesapSilSunucu hatası:", e);
      throw new functions.https.HttpsError("internal", "Hesap silinemedi.", String(e));
    }
  });

// ── İşlem Paneli Bildirimi ────────────────────────────────────────────────────

const ISLEM_DURUMU_ETIKETLER: Record<string, string> = {
  siparisVerildi:  "🛒 Sipariş Verildi",
  urunAlindi:      "🛍️ Ürün Satın Alındı",
  yolaCikti:       "🚚 Yola Çıktı",
  teslimEdildi:    "📦 Teslim Edildi",
  teslimAlindi:    "✅ Teslim Alındı",
};

export const islemDurumuBildirimiGonder = functions
  .region("europe-west1")
  .firestore.document("sohbetler/{sohbetId}")
  .onUpdate(async (change, context) => {
    const onceki  = change.before.data() as FirebaseFirestore.DocumentData;
    const sonraki = change.after.data()  as FirebaseFirestore.DocumentData;

    const oncekiDurumlar  = (onceki.islemDurumlari  ?? {}) as Record<string, unknown>;
    const sonrakiDurumlar = (sonraki.islemDurumlari ?? {}) as Record<string, unknown>;

    const sohbetId      = context.params.sohbetId as string;
    const ilanBaslik    = (sonraki.ilanBaslik    as string | undefined) ?? "İlan";
    const ilanId        = (sonraki.ilanId        as string | undefined) ?? "";
    const ilanSahibiId  = (sonraki.ilanSahibiId as string | undefined) ?? "";
    const katilimcilar  = (sonraki.kullanicilar  ?? []) as string[];

    // ── Anlaşıldı (iki taraflı) ──────────────────────────────────────────────
    // anlasildi_<uid> anahtarı yeni true oldu mu?
    for (const uid of katilimcilar) {
      const key = `anlasildi_${uid}`;
      if (!oncekiDurumlar[key] && sonrakiDurumlar[key] === true) {
        const yapanUid = uid;
        const aliciId  = katilimcilar.find((u) => u !== yapanUid);
        if (!aliciId) break;

        const karsiZatenOnayladi = sonrakiDurumlar[`anlasildi_${aliciId}`] === true
          && oncekiDurumlar[`anlasildi_${aliciId}`] === true;

        const yapanSnap = await db.collection("kullanicilar").doc(yapanUid).get();
        const yapanAd   = (yapanSnap.data()?.adSoyad as string | undefined) ?? "Kullanıcı";

        const etiket  = karsiZatenOnayladi ? "🤝 Anlaşıldı" : "🤝 Anlaşma Önerildi";
        const icerik  = karsiZatenOnayladi
          ? `${yapanAd}, anlaşmayı kabul etti!`
          : `${yapanAd}, anlaşma önerdi!`;

        await db.collection("bildirimler").add({
          kullaniciId: aliciId,
          tip:         "islem",
          baslik:      etiket,
          icerik,
          okundu:      false,
          tarih:       admin.firestore.FieldValue.serverTimestamp(),
          hedefId:     sohbetId,
          gondereId:   yapanUid,
          gondereAd:   yapanAd,
        });

        const aliciSnap    = await db.collection("kullanicilar").doc(aliciId).get();
        const aliciData    = aliciSnap.data() ?? {};
        const fcmToken     = aliciData.fcmToken as string | undefined;
        const sistemTercih = (aliciData.bildirimTercihleri?.sistem ?? true) as boolean;
        if (!fcmToken || !sistemTercih) break;

        await admin.messaging().send({
          token: fcmToken,
          notification: { title: etiket, body: `${yapanAd} • ${ilanBaslik}` },
          data: {
            tip: "mesaj", sohbetId, ilanBaslik, ilanId,
            ilanSahibiId, karsiKullaniciId: yapanUid, karsiKullaniciAd: yapanAd,
          },
          android: { priority: "high", notification: { channelId: "mesajlar" } },
          apns: { payload: { aps: { badge: 1 } } },
        });
        break;
      }
    }

    // ── Tek taraflı adımlar ───────────────────────────────────────────────────
    let yeniDurum: string | null = null;
    for (const durum of Object.keys(ISLEM_DURUMU_ETIKETLER)) {
      if (!oncekiDurumlar[durum] && sonrakiDurumlar[durum] === true) {
        yeniDurum = durum;
        break;
      }
    }
    if (!yeniDurum) return;

    const yapanUid = sonrakiDurumlar[`${yeniDurum}_yapanUid`] as string | undefined;
    if (!yapanUid) return;

    const aliciId = katilimcilar.find((uid) => uid !== yapanUid);
    if (!aliciId) return;

    const etiket = ISLEM_DURUMU_ETIKETLER[yeniDurum];

    const yapanSnap = await db.collection("kullanicilar").doc(yapanUid).get();
    const yapanAd   = (yapanSnap.data()?.adSoyad as string | undefined) ?? "Kullanıcı";

    await db.collection("bildirimler").add({
      kullaniciId: aliciId,
      tip:         "islem",
      baslik:      etiket,
      icerik:      `${yapanAd}, "${ilanBaslik}" için ${etiket.split(" ").slice(1).join(" ")} adımını onayladı`,
      okundu:      false,
      tarih:       admin.firestore.FieldValue.serverTimestamp(),
      hedefId:     sohbetId,
      gondereId:   yapanUid,
      gondereAd:   yapanAd,
    });

    const aliciSnap    = await db.collection("kullanicilar").doc(aliciId).get();
    const aliciData    = aliciSnap.data() ?? {};
    const fcmToken     = aliciData.fcmToken as string | undefined;
    const sistemTercih = (aliciData.bildirimTercihleri?.sistem ?? true) as boolean;
    if (!fcmToken || !sistemTercih) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: { title: etiket, body: `${yapanAd} • ${ilanBaslik}` },
      data: {
        tip: "mesaj", sohbetId, ilanBaslik, ilanId,
        ilanSahibiId, karsiKullaniciId: yapanUid, karsiKullaniciAd: yapanAd,
      },
      android: { priority: "high", notification: { channelId: "mesajlar" } },
      apns: { payload: { aps: { badge: 1 } } },
    });
  });