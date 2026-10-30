// tools/ilan_no_migrasyon.js
//
// Tek seferlik backfill: ilanlar koleksiyonundaki mevcut ilanlara,
// olusturmaTarihi'ne göre sıralı bir ilanNo atar. sayaclar/ilanlar.sonNo'yu
// atanan en yüksek numaraya set eder ki ilanModerasyonu Cloud Function'ı
// (functions/src/index.ts, siradakiIlanNo()) bundan sonraki ilanlara devam
// eden numaralar versin.
//
// Kullanım (repo kökünden):
//   node tools/ilan_no_migrasyon.js            → DRY RUN (varsayılan), yazmaz
//   node tools/ilan_no_migrasyon.js --uygula    → yazma modu
//
// Ön koşul: GOOGLE_APPLICATION_CREDENTIALS ortam değişkeni bir service
// account JSON dosyasına işaret etmeli.

const path = require('path');
const { createRequire } = require('module');
const requireFromFunctions = createRequire(
  path.join(__dirname, '..', 'functions', 'package.json'),
);
const admin = requireFromFunctions('firebase-admin');
const { getFirestore } = requireFromFunctions('firebase-admin/firestore');

const DATABASE_ID = 'iste-eu';
const COLLECTION = 'ilanlar';
const SAYAC_DOC = 'ilanlar';
const GRUP_BOYUTU = 490;

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error(
      'HATA: GOOGLE_APPLICATION_CREDENTIALS ortam değişkeni tanımlı değil.\n' +
      'Bir service account JSON dosyasının yolunu bu değişkene ata ve tekrar dene.',
    );
    process.exit(1);
  }

  const uygula = process.argv.includes('--uygula');

  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = getFirestore(admin.app(), DATABASE_ID);

  console.log(`Mod: ${uygula ? 'UYGULA (yazacak)' : 'DRY RUN (yazmayacak)'}`);
  console.log(`Veritabanı: ${DATABASE_ID}, koleksiyon: ${COLLECTION}\n`);

  const snap = await db.collection(COLLECTION).get();
  console.log(`Taranan doküman sayısı: ${snap.docs.length}`);

  // ilanNo zaten atanmış olanları atla (script tekrar çalıştırılırsa idempotent olsun).
  const numarasizlar = snap.docs.filter((doc) => {
    const mevcut = doc.get('ilanNo');
    return mevcut === undefined || mevcut === null || mevcut === 0;
  });

  numarasizlar.sort((a, b) => {
    const ta = a.get('olusturmaTarihi')?.toMillis?.() ?? a.createTime.toMillis();
    const tb = b.get('olusturmaTarihi')?.toMillis?.() ?? b.createTime.toMillis();
    return ta - tb;
  });

  // Mevcut en yüksek ilanNo'yu bul (zaten numaralı olanlar arasında) — sıfırdan
  // başlamayıp kaldığı yerden devam etsin.
  let enYuksek = 0;
  for (const doc of snap.docs) {
    const n = doc.get('ilanNo');
    if (typeof n === 'number' && n > enYuksek) enYuksek = n;
  }

  console.log(`Numarasız ilan sayısı: ${numarasizlar.length}`);
  console.log(`Başlangıç numarası: ${enYuksek + 1}\n`);

  const atamalar = numarasizlar.map((doc, i) => ({
    ref: doc.ref,
    id: doc.id,
    ilanNo: enYuksek + 1 + i,
  }));

  for (const a of atamalar) {
    console.log(`  id=${a.id}  ilanNo=${a.ilanNo}`);
  }

  const sonNo = enYuksek + atamalar.length;

  if (uygula && atamalar.length > 0) {
    for (let i = 0; i < atamalar.length; i += GRUP_BOYUTU) {
      const grup = atamalar.slice(i, i + GRUP_BOYUTU);
      const batch = db.batch();
      for (const a of grup) {
        batch.update(a.ref, { ilanNo: a.ilanNo });
      }
      await batch.commit();
      console.log(`${Math.min(i + GRUP_BOYUTU, atamalar.length)}/${atamalar.length} yazıldı`);
    }

    await db.collection('sayaclar').doc(SAYAC_DOC).set({ sonNo }, { merge: true });
    console.log(`sayaclar/${SAYAC_DOC}.sonNo = ${sonNo} olarak set edildi`);
  }

  console.log('\n── Özet ──');
  console.log(`Taranan:        ${snap.docs.length}`);
  console.log(`Numaralandırılan: ${atamalar.length}`);
  console.log(`Yeni sonNo:     ${sonNo}${uygula ? '' : ' (dry run — yazılmadı)'}`);
}

main().catch((e) => {
  console.error('Script hata verdi:', e);
  process.exit(1);
});
