import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { algoliasearch } from "algoliasearch";
import * as vision from "@google-cloud/vision";
import * as nodemailer from "nodemailer";
import { hesaplaGuvenSkoru } from "./guvenSkoru";
import { yenidenDenenmeliMiHesapla } from "./ilanModerasyon";

admin.initializeApp();

// ── VERİTABANI ────────────────────────────────────────────────────────────
// TEK DEĞİŞİKLİK NOKTASI: "iste-eu" ismini burada değiştirmen yeterli,
// tüm fonksiyonlar bu tek db referansını kullanıyor.
const DATABASE_ID = "iste-eu";
const db = getFirestore(admin.app(), DATABASE_ID);

// Tüm fonksiyonlar için ortak bölge + veritabanı ayarı — her fonksiyonda
// tekrar tekrar yazmamak için global tanımlıyoruz.
setGlobalOptions({ region: "europe-west1" });

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
// KAYNAK TANIM: lib/shared/utils/oneri_skoru.dart ile senkron tutulmalı —
// birini değiştiren diğerini de değiştirir. Tazelik bileşeni SUNUCUDA YOK
// — Algolia replica'nın ikincil kriteri (olusturmaTarihi desc) karşılıyor.
// Bu iş bölümünün çalışması için dönüş KOVALANMIŞ TAMSAYI olmalı: float
// skorda eşitlik neredeyse hiç oluşmaz ve ikincil kriter hiç konuşamaz.
// kullaniciDegerlendirmeSayisi denormalize edilmedi — n=3 sabit (ayrı görev).

function onerilenPuanHesapla(data: FirebaseFirestore.DocumentData): number {
  const n = 3;
  const puan        = (data.kullaniciPuan ?? 0) as number;
  const duzeltilmis = (puan * n + 4.0 * 5) / (n + 5); // Bayesian

  const favori      = (data.favoriSayisi       ?? 0) as number;
  const goruntuleme = (data.goruntulenmeSayisi ?? 0) as number;
  const resimSayisi = ((data.resimUrller as string[] | undefined) ?? []).length;

  const favoriPay       = Math.min(Math.log(favori + 1)      / Math.log(50),  1.0);
  const goruntulenmePay = Math.min(Math.log(goruntuleme + 1) / Math.log(500), 1.0);
  const resimPay        = Math.min(resimSayisi / 5, 1.0);
  // Resim = formüldeki tek "emek" sinyali; manipülasyona en kapalı bileşen.
  const ilgi = 0.6 * favoriPay + 0.25 * goruntulenmePay + 0.15 * resimPay;

  // 0-14 arası kova (×20): aynı kovadakiler arasında Algolia ikincil
  // sırası (olusturmaTarihi desc) devreye girer.
  return Math.round((0.5 * (duzeltilmis / 5) + 0.2 * ilgi) * 20);
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

let _kelimeRegexCache: Map<string, RegExp> | null = null;
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
  if (metin.trim().length < 3) {
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

// ── FCM yardımcıları ──────────────────────────────────────────────────────────

/** Bayat/silinmiş token hatası gelince Firestore'dan temizler. */
async function bayatTokenTemizle(err: unknown, hedefUid: string): Promise<void> {
  const kod = (err as { errorInfo?: { code?: string } })?.errorInfo?.code ?? "";
  if (kod === "messaging/registration-token-not-registered") {
    try {
      await db.collection("kullanicilar").doc(hedefUid)
        .update({ fcmToken: admin.firestore.FieldValue.delete() });
      console.log(`[FCM] Bayat token temizlendi uid=${hedefUid}`);
    } catch (e) {
      console.warn("[FCM] Bayat token temizlenemedi:", e);
    }
  }
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
    await bayatTokenTemizle(e, kullaniciId);
    console.warn("FCM gönderim hatası:", e);
  }
}

// ── İlan moderasyon fonksiyonu ────────────────────────────────────────────────

export const ilanModerasyonu = onDocumentCreated(
  {
    document: "ilanlar/{ilanId}",
    database: DATABASE_ID,
    timeoutSeconds: 180,
    memory: "512MiB",
  },
  async (event) => {
    const ilanId = event.params.ilanId;
    const data   = event.data?.data();
    if (!data) return;

    const ilanRef     = db.collection("ilanlar").doc(ilanId);
    const kullaniciId = data.kullaniciId as string;

    try {
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
      } catch (e) {
        console.error("Algolia ana index hatası:", e);
        await ilanRef.update({ algoliaHata: true }).catch(() => {});
      }

      try {
        await getAlgoliaClient().saveObject({
          indexName: ALGOLIA_INDEX_NEREYE,
          body: {
            objectID: ilanId,
            nereye:   data.nereye ?? "",
          },
        });
      } catch (e) { console.error("Algolia nereye index hatası:", e); }

    } catch (e) {
      console.error("Moderasyon hatası:", e);
      try {
        await ilanRef.update({ aktif: false, durum: "onayBekliyor" });
        await db.collection("bildirimler").add({
          kullaniciId,
          tip: "ilan_red",
          baslik: "İlanın şu an değerlendirilemedi",
          icerik: "Teknik bir sorun oluştu. Lütfen birkaç dakika sonra tekrar dene.",
          okundu: false,
          tarih: admin.firestore.FieldValue.serverTimestamp(),
          hedefId: ilanId,
        });
      } catch (innerErr) {
        console.error("Moderasyon hata bildirimi de gönderilemedi:", innerErr);
      }
    }
  }
);

// ── İlan güncelleme moderasyonu ───────────────────────────────────────────────

export const ilanGuncellemeModerasyon = onDocumentUpdated(
  {
    document: "ilanlar/{ilanId}",
    database: DATABASE_ID,
    timeoutSeconds: 180,
    memory: "512MiB",
  },
  async (event) => {
    const ilanId = event.params.ilanId;
    const once   = event.data?.before.data();
    const sonra  = event.data?.after.data();
    if (!once || !sonra) return;

    const icerikDegisti =
      once.urun    !== sonra.urun    ||
      once.notlar  !== sonra.notlar  ||
      once.nereden !== sonra.nereden ||
      once.nereye  !== sonra.nereye  ||
      JSON.stringify(once.resimUrller ?? []) !== JSON.stringify(sonra.resimUrller ?? []);
    const yenidenDenenmeliMi = yenidenDenenmeliMiHesapla(once, sonra);
    if (!icerikDegisti && !yenidenDenenmeliMi) return;

    const ilanRef            = db.collection("ilanlar").doc(ilanId);
    const oncedenReddedilmis = once.durum === "reddedildi";
    const redBaslik          = oncedenReddedilmis ? "İlanın yayınlanamadı" : "İlanın yayından kaldırıldı";

    try {
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
  }
);

// ── Algolia güncelleme (favori/görüntülenme değişince önerilen puan da güncellenir) ──────

export const ilanGuncellendi = onDocumentUpdated(
  { document: "ilanlar/{ilanId}", database: DATABASE_ID },
  async (event) => {
    const once  = event.data?.before.data();
    const sonra = event.data?.after.data();
    if (!sonra) return;

    const oncedenAktifti = once ? (once.aktif === true && once.durum === "yayinda") : false;
    const simdiAktif     = sonra.aktif === true && sonra.durum === "yayinda";

    // aktif → pasif GEÇİŞİ: Algolia'dan sil, ilanSilindi'deki İKİ index'lik
    // silme deseninin birebir aynısı (yalnızca ana index'i silmek yetmez —
    // ALGOLIA_INDEX_NEREYE'de de kalır, arama sonuçlarında görünmeye devam eder).
    if (oncedenAktifti && !simdiAktif) {
      try {
        await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX, objectID: event.params.ilanId });
      } catch (e) { console.warn("Algolia silme hatası (pasife alma):", e); }
      try {
        await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX_NEREYE, objectID: event.params.ilanId });
      } catch (e) { console.warn("Algolia nereye silme hatası (pasife alma):", e); }
      return;
    }

    // Zaten pasifti, hâlâ pasif — geçiş yok, Algolia'ya dokunma (gereksiz çağrı yapma).
    if (!simdiAktif) return;

    const data = sonra;
    const onerilenPuan = onerilenPuanHesapla(data);

    try {
      await db.collection("ilanlar").doc(event.params.ilanId).update({ onerilenPuan });
    } catch (e) { console.warn("onerilenPuan Firestore hatası:", e); }

    try {
      await getAlgoliaClient().saveObject({
        indexName: ALGOLIA_INDEX,
        body: {
          objectID:           event.params.ilanId,
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

    try {
      await getAlgoliaClient().saveObject({
        indexName: ALGOLIA_INDEX_NEREYE,
        body: {
          objectID: event.params.ilanId,
          nereye:   data.nereye ?? "",
        },
      });
    } catch (e) { console.warn("Algolia nereye hatası:", e); }
  }
);

export const ilanSilindi = onDocumentDeleted(
  { document: "ilanlar/{ilanId}", database: DATABASE_ID },
  async (event) => {
    const ilanId = event.params.ilanId;
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
  }
);

export const algoliaTopluAktar = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  }

  // Client tarafındaki admin kontrolüyle (ayarlar_screen.dart:310,312)
  // AYNI e-posta — Firebase Console'dan doğrulandı, bu hesap Google ile
  // giriş yapıyor, token.email güvenilir şekilde dolu gelir.
  if (request.auth.token.email !== "fabricahere@gmail.com") {
    throw new HttpsError("permission-denied", "Bu işlem için yetkin yok.");
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

  const nereyeRecords = snap.docs.map((doc) => ({
    objectID: doc.id,
    nereye:   doc.data().nereye ?? "",
  }));
  await getAlgoliaClient().saveObjects({ indexName: ALGOLIA_INDEX_NEREYE, objects: nereyeRecords });

  return { success: true, count: records.length };
});

// ── Mesaj Bildirimi ───────────────────────────────────────────────────────────

export const mesajBildirimiGonder = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  const { aliciId, gondereAd, ilanBaslik, sohbetId, metin, ilanId, ilanSahibiId, ilanResimUrl, mesajId, mesajZaman } = request.data as {
    aliciId: string; gondereAd: string; ilanBaslik: string; sohbetId: string; metin: string; ilanId: string; ilanSahibiId: string; ilanResimUrl: string; mesajId?: string; mesajZaman?: string;
  };
  const gondereId = request.auth.uid;

  // Katılımcılık doğrulaması — çağıranın gerçekten bu sohbette olduğunu,
  // aliciId'nin de aynı sohbetin diğer tarafı olduğunu kontrol et. Bu
  // olmadan, giriş yapmış herhangi biri rastgele aliciId/sohbetId ile
  // sahte bildirim gönderebilirdi.
  const sohbetSnap = await db.collection("sohbetler").doc(sohbetId).get();
  if (!sohbetSnap.exists) {
    throw new HttpsError("not-found", "Sohbet bulunamadı.");
  }
  const sohbetData = sohbetSnap.data() ?? {};
  const katilimcilar = (sohbetData.kullanicilar ?? []) as string[];
  if (!katilimcilar.includes(gondereId) || !katilimcilar.includes(aliciId)) {
    throw new HttpsError("permission-denied", "Bu sohbetin bir parçası değilsin.");
  }

  const kullaniciSnap = await db.collection("kullanicilar").doc(aliciId).get();
  if (!kullaniciSnap.exists) return { success: false };
  const kullaniciData  = kullaniciSnap.data() ?? {};
  const engellenenler  = (kullaniciData.engellenenler ?? []) as string[];
  if (engellenenler.includes(gondereId)) return { success: true };
  const bildirimMetin  = metin && metin.trim().length > 0 ? metin.trim() : ilanBaslik;

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

  const fcmToken    = kullaniciData.fcmToken as string | undefined;
  const mesajTercih = (kullaniciData.bildirimTercihleri?.mesaj ?? true) as boolean;
  if (!fcmToken || !mesajTercih) return { success: true };

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title: gondereAd, body: bildirimMetin },
      data: { tip: "mesaj", sohbetId, ilanBaslik, ilanId: ilanId ?? "", ilanSahibiId: ilanSahibiId ?? "", ilanResimUrl: ilanResimUrl ?? "", karsiKullaniciId: gondereId, karsiKullaniciAd: gondereAd, mesajId: mesajId ?? "", mesajMetin: metin ?? "", mesajZaman: mesajZaman ?? "" },
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
  } catch (e) {
    await bayatTokenTemizle(e, aliciId);
    console.warn("[FCM] mesajBildirimi gönderilemedi:", e);
  }
  return { success: true };
});

// ── Değerlendirme Bildirimi ───────────────────────────────────────────────────

export const degerlendirmeBildirimiGonder = onDocumentCreated(
  { document: "degerlendirmeler/{degId}", database: DATABASE_ID },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { hedefKullaniciId, degerlendireninId, puan } = data as {
      hedefKullaniciId: string; degerlendireninId: string; puan: number;
    };
    const degerlendireninSnap = await db.collection("kullanicilar").doc(degerlendireninId).get();
    const degerlendireninAd   = (degerlendireninSnap.data()?.adSoyad as string | undefined) ?? "Biri";
    const hedefSnap           = await db.collection("kullanicilar").doc(hedefKullaniciId).get();
    const hedefData           = hedefSnap.data() ?? {};
    const hedefEngellenenler  = (hedefData.engellenenler ?? []) as string[];
    if (hedefEngellenenler.includes(degerlendireninId)) return;
    const fcmToken            = hedefData.fcmToken as string | undefined;
    if (!fcmToken) return;
    const sistemTercih = (hedefData.bildirimTercihleri?.sistem ?? true) as boolean;
    if (!sistemTercih) return;
    const yildizlar = "⭐".repeat(Math.min(puan, 5));
    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "Yeni değerlendirme aldın!",
          body: `${degerlendireninAd} seni ${yildizlar} olarak değerlendirdi.`,
        },
        data: { tip: "degerlendirme", hedefKullaniciId },
        android: { priority: "high", notification: { channelId: "genel" } },
      });
    } catch (e) {
      await bayatTokenTemizle(e, hedefKullaniciId);
      console.warn("[FCM] degerlendirmeBildirimi gönderilemedi:", e);
    }
  }
);

// ── Takip Sayaç Trigger'ları ─────────────────────────────────────────────────

export const takipOlustuSayacArttir = onDocumentCreated(
  { document: "takipler/{takipId}", database: DATABASE_ID },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { takipciId, takipEdilenId } = data as { takipciId: string; takipEdilenId: string };
    if (!takipciId || !takipEdilenId) return;
    const takipciRef     = db.collection("kullanicilar").doc(takipciId);
    const takipEdilenRef = db.collection("kullanicilar").doc(takipEdilenId);
    const batch = db.batch();
    const [takipciSnap, takipEdilenSnap] = await Promise.all([takipciRef.get(), takipEdilenRef.get()]);
    if (takipciSnap.exists)     batch.update(takipciRef,     { takipSayisi:   admin.firestore.FieldValue.increment(1) });
    if (takipEdilenSnap.exists) batch.update(takipEdilenRef, { takipciSayisi: admin.firestore.FieldValue.increment(1) });
    await batch.commit();
  }
);

export const takipSilindiSayacAzalt = onDocumentDeleted(
  { document: "takipler/{takipId}", database: DATABASE_ID },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { takipciId, takipEdilenId } = data as { takipciId: string; takipEdilenId: string };
    if (!takipciId || !takipEdilenId) return;
    const takipciRef     = db.collection("kullanicilar").doc(takipciId);
    const takipEdilenRef = db.collection("kullanicilar").doc(takipEdilenId);
    const batch = db.batch();
    const [takipciSnap, takipEdilenSnap] = await Promise.all([takipciRef.get(), takipEdilenRef.get()]);
    if (takipciSnap.exists)     batch.update(takipciRef,     { takipSayisi:   admin.firestore.FieldValue.increment(-1) });
    if (takipEdilenSnap.exists) batch.update(takipEdilenRef, { takipciSayisi: admin.firestore.FieldValue.increment(-1) });
    await batch.commit();
  }
);

// ── Değerlendirme Puan Güncelle (sunucu tarafı) ───────────────────────────────

export const degerlendirmePuanGuncelle = onDocumentCreated(
  { document: "degerlendirmeler/{degId}", database: DATABASE_ID },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { hedefKullaniciId, puan } = data as { hedefKullaniciId: string; puan: number };
    if (!hedefKullaniciId || typeof puan !== "number" || puan < 1 || puan > 5) return;
    const kullaniciRef = db.collection("kullanicilar").doc(hedefKullaniciId);
    let guncelPuan: number | null = null;
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(kullaniciRef);
      if (!snap.exists) return;
      const d = snap.data()!;
      const eskiSayi: number = (d.degerlendirmeSayisi as number) || 0;
      const eskiOrtalama: number = (d.ortalamaPuan as number) || 0;
      const yeniSayi = eskiSayi + 1;
      const yeniOrtalama = (eskiOrtalama * eskiSayi + puan) / yeniSayi;
      guncelPuan = Math.round(yeniOrtalama * 10) / 10;
      tx.update(kullaniciRef, {
        degerlendirmeSayisi: yeniSayi,
        ortalamaPuan: guncelPuan,
      });
    });

    // Kullanıcı dokümanı yoktu → transaction hiçbir şey yazmadı, fan-out da yapılmaz.
    if (guncelPuan === null) return;

    // ── kullaniciPuan fan-out ──────────────────────────────────────────────
    // Satıcının AKTİF ilanlarındaki denormalize kullaniciPuan'ı tazele.
    // onerilenPuan + Algolia senkronu için EK İŞ GEREKMEZ: bu yazmaların her
    // biri ilanGuncellendi trigger'ını tetikler; o trigger yeni kullaniciPuan
    // ile onerilenPuan'ı yeniden hesaplayıp Firestore + Algolia'ya yazar.
    // Zincir sönümlüdür: değer değişmeyen yazma yeni update event'i üretmez.
    try {
      const ilanlarSnap = await db.collection("ilanlar")
        .where("kullaniciId", "==", hedefKullaniciId)
        .where("aktif", "==", true)
        .get();
      if (!ilanlarSnap.empty) {
        const docs = ilanlarSnap.docs;
        for (let i = 0; i < docs.length; i += 450) {  // batch limiti 500 — pay bırak
          const batch = db.batch();
          for (const doc of docs.slice(i, i + 450)) {
            batch.update(doc.ref, { kullaniciPuan: guncelPuan });
          }
          await batch.commit();
        }
      }
    } catch (e) {
      // Fan-out hatası ortalamaPuan yazımını geri almaz — puan güncellendi,
      // ilanlar bir sonraki değerlendirmede yakalar. Sadece logla.
      console.error("kullaniciPuan fan-out hatası:", e);
    }
  }
);

// ── Bize Ulaşın — Email Gönder ────────────────────────────────────────────────

export const iletisimGonder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  }
  const { konu, mesaj, gonderenAd, gonderenEmail } = request.data as {
    konu: string; mesaj: string; gonderenAd: string; gonderenEmail: string;
  };
  if (!konu || !mesaj) {
    throw new HttpsError("invalid-argument", "Konu ve mesaj zorunlu.");
  }
  const gmailKullanici = process.env.GMAIL_KULLANICI;
  const gmailSifre     = process.env.GMAIL_SIFRE;
  if (!gmailKullanici || !gmailSifre) {
    throw new HttpsError("internal", "Email yapılandırması eksik.");
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
      <p><b>Kullanıcı ID:</b> ${request.auth.uid}</p>
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
// Firebase Auth kaydı) burada, SIRALI ve TEK YERDEN yönetiliyor.
export const hesapSilSunucu = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  }
  const uid = request.auth.uid;

  try {
    const batch = db.batch();

    await db.recursiveDelete(
      db.collection("kullanicilar").doc(uid).collection("bekleyenDegerlendirmeler")
    );

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

    const goruntulenmelerSnap = await db.collection("goruntulenmeler")
      .where("kullaniciId", "==", uid).get();
    for (const doc of goruntulenmelerSnap.docs) batch.delete(doc.ref);

    const takipciSnap = await db.collection("takipler")
      .where("takipciId", "==", uid).get();
    for (const doc of takipciSnap.docs) batch.delete(doc.ref);

    const takipEdilenSnap = await db.collection("takipler")
      .where("takipEdilenId", "==", uid).get();
    for (const doc of takipEdilenSnap.docs) batch.delete(doc.ref);

    await batch.commit();

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
    throw new HttpsError("internal", "Hesap silinemedi.", String(e));
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

export const islemDurumuBildirimiGonder = onDocumentUpdated(
  { document: "sohbetler/{sohbetId}", database: DATABASE_ID },
  async (event) => {
    const onceki  = event.data?.before.data() as FirebaseFirestore.DocumentData | undefined;
    const sonraki = event.data?.after.data()  as FirebaseFirestore.DocumentData | undefined;
    if (!onceki || !sonraki) return;

    const oncekiDurumlar  = (onceki.islemDurumlari  ?? {}) as Record<string, unknown>;
    const sonrakiDurumlar = (sonraki.islemDurumlari ?? {}) as Record<string, unknown>;

    const sohbetId      = event.params.sohbetId as string;
    const ilanBaslik    = (sonraki.ilanBaslik    as string | undefined) ?? "İlan";
    const ilanId        = (sonraki.ilanId        as string | undefined) ?? "";
    const ilanSahibiId  = (sonraki.ilanSahibiId  as string | undefined) ?? "";
    const ilanResimUrl  = (sonraki.ilanResimUrl  as string | undefined) ?? "";
    const katilimcilar  = (sonraki.kullanicilar  ?? []) as string[];

    // ── Anlaşıldı (iki taraflı) ──────────────────────────────────────────────
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
        const aliciEngel1  = (aliciData.engellenenler ?? []) as string[];
        if (aliciEngel1.includes(yapanUid)) break;
        const fcmToken     = aliciData.fcmToken as string | undefined;
        const sistemTercih = (aliciData.bildirimTercihleri?.sistem ?? true) as boolean;
        if (!fcmToken || !sistemTercih) break;

        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: { title: etiket, body: `${yapanAd} • ${ilanBaslik}` },
            data: {
              tip: "mesaj", islem: "true", sohbetId, ilanBaslik, ilanId,
              ilanResimUrl, ilanSahibiId, karsiKullaniciId: yapanUid, karsiKullaniciAd: yapanAd,
            },
            android: { priority: "high", notification: { channelId: "mesajlar" } },
            apns: { payload: { aps: { badge: 1 } } },
          });
        } catch (e) {
          await bayatTokenTemizle(e, aliciId);
          console.warn("[FCM] anlasildiBildirimi gönderilemedi:", e);
        }
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
    const aliciEngel2  = (aliciData.engellenenler ?? []) as string[];
    if (aliciEngel2.includes(yapanUid)) return;
    const fcmToken     = aliciData.fcmToken as string | undefined;
    const sistemTercih = (aliciData.bildirimTercihleri?.sistem ?? true) as boolean;
    if (!fcmToken || !sistemTercih) return;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title: etiket, body: `${yapanAd} • ${ilanBaslik}` },
        data: {
          tip: "mesaj", islem: "true", sohbetId, ilanBaslik, ilanId,
          ilanResimUrl, ilanSahibiId, karsiKullaniciId: yapanUid, karsiKullaniciAd: yapanAd,
        },
        android: { priority: "high", notification: { channelId: "mesajlar" } },
        apns: { payload: { aps: { badge: 1 } } },
      });
    } catch (e) {
      await bayatTokenTemizle(e, aliciId);
      console.warn("[FCM] islemDurumBildirimi gönderilemedi:", e);
    }
  }
);
// ── GÖRÜNTÜLENME TEMİZLİĞİ ────────────────────────────────────────────────
export const goruntulenmeTemizle = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "Europe/Istanbul",
    region: "europe-west1",
  },
  async (event) => {
    const doksanGunOnce = new Date();
    doksanGunOnce.setDate(doksanGunOnce.getDate() - 90);

    const snap = await db
      .collection("goruntulenmeler")
      .where("sonTarih", "<", doksanGunOnce)
      .limit(500)
      .get();

    if (snap.empty) {
      console.log("Silinecek eski görüntülenme kaydı yok.");
      return;
    }

    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    console.log(`${snap.size} adet eski görüntülenme kaydı silindi.`);
  }
);

// ── İLAN OTOMATİK PASİFLEŞTİRME ──────────────────────────────────────────
// Client-side _otuzGunKontrol (ilan_detay_screen.dart) yalnızca ilan sahibi
// kendi ilanına girip baktığında çalışıyordu — sunucu tarafında bir eşdeğeri
// yoktu. Bu fonksiyon, 30+ gün önce oluşturulmuş hâlâ aktif ilanları günlük
// olarak pasife düşürür. Yalnızca 'aktif': false güncelleniyor — Algolia'ya
// ayrı bir silme çağrısı YAPILMIYOR, mevcut ilanGuncellendi (onDocumentUpdated)
// tetikleyicisi bu alan değişikliğini zaten yakalayıp Algolia'nın her iki
// index'inden de siliyor (C7'de doğrulandı).
export const ilanOtomatikPasif = onSchedule(
  {
    schedule: "every day 04:00",
    timeZone: "Europe/Istanbul",
    region: "europe-west1",
  },
  async (event) => {
    const otuzGunOnce = new Date();
    otuzGunOnce.setDate(otuzGunOnce.getDate() - 30);

    const snap = await db
      .collection("ilanlar")
      .where("aktif", "==", true)
      .where("olusturmaTarihi", "<", otuzGunOnce)
      .limit(500)
      .get();

    if (snap.empty) {
      console.log("Otomatik pasife düşürülecek ilan yok.");
      return;
    }

    const batch = db.batch();
    snap.docs.forEach((doc) => batch.update(doc.ref, { aktif: false }));
    await batch.commit();

    console.log(`${snap.size} adet ilan otomatik pasife düşürüldü.`);
  }
);

// ── Güven Skoru Hesaplama (Scheduled) ───────────────────────────────────────
export const guvenSkoruHesapla = onSchedule(
  {
    schedule: "every 24 hours",
    region: "europe-west1",
  },
  async () => {
    const kullaniciSnap = await db.collection("kullanicilar").get();
    const batch = db.batch();
    for (const kullaniciDoc of kullaniciSnap.docs) {
      const kullanici = kullaniciDoc.data();
      const ortalamaPuan = (kullanici.ortalamaPuan as number) ?? 0;
      const degerlendirmeSayisi = (kullanici.degerlendirmeSayisi as number) ?? 0;
      const ilanSnap = await db.collection("ilanlar")
        .where("kullaniciId", "==", kullaniciDoc.id)
        .where("aktif", "==", true)
        .get();
      const toplamSkor = hesaplaGuvenSkoru({
        ortalamaPuan,
        degerlendirmeSayisi,
        aktifIlanSayisi: ilanSnap.size,
        adSoyadVar: !!kullanici.adSoyad,
        telefonVar: !!kullanici.telefon,
        sehirVar: !!(kullanici.bulunduguSehir || kullanici.yasadigiUlke),
        hakkindaVar: !!kullanici.hakkinda,
      });
      batch.update(kullaniciDoc.ref, { guvenSkoru: toplamSkor });
    }
    await batch.commit();
    console.log(`[guvenSkoruHesapla] ${kullaniciSnap.size} kullanıcının güven skoru güncellendi.`);
  }
);
