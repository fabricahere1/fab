// tools/backfill_degerlendirme_tarih.js
//
// Tek seferlik backfill: degerlendirmeler koleksiyonunda 'tarih' alanı eksik
// (yok ya da null) dokümanları doldurur. Task 3'ün yeni composite index'i
// (hedefKullaniciId ASC + tarih DESC) devreye girdiğinde, 'tarih' alanı
// olmayan dokümanlar orderBy('tarih') sorgusundan SESSİZCE ELENİR — bu script
// index deploy edilmeden önce bu boşluğu kapatmak için var.
//
// Kullanım (repo kökünden):
//   node tools/backfill_degerlendirme_tarih.js            → DRY RUN (varsayılan), yazmaz
//   node tools/backfill_degerlendirme_tarih.js --uygula    → yazma modu
//
// Ön koşul: GOOGLE_APPLICATION_CREDENTIALS ortam değişkeni bir service
// account JSON dosyasına işaret etmeli.
//
// firebase-admin, functions/node_modules altındaki mevcut kuruluma (v13.8.0,
// package.json'da doğrulandı) referans verir; ayrı bir kurulum gerekmez.

const path = require('path');
const { createRequire } = require('module');
const requireFromFunctions = createRequire(
  path.join(__dirname, '..', 'functions', 'package.json'),
);
const admin = requireFromFunctions('firebase-admin');
const { getFirestore, Timestamp } = requireFromFunctions('firebase-admin/firestore');

const DATABASE_ID = 'iste-eu';
const COLLECTION = 'degerlendirmeler';
const GRUP_BOYUTU = 490;
const TARAMA_UYARI_ESIGI = 5000;

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

  // ⚠️ DİKKAT: named database — admin.firestore() / getFirestore(admin.app())
  // (ikinci argümansız) DEFAULT DB'ye bağlanır ve bu koleksiyon orada
  // bulunmadığı için sıfır doküman döndürüp yanlışlıkla "temiz" sonucu verir.
  // Bu yüzden ikinci argüman olarak DATABASE_ID ('iste-eu') zorunlu.
  const db = getFirestore(admin.app(), DATABASE_ID);

  console.log(`Mod: ${uygula ? 'UYGULA (yazacak)' : 'DRY RUN (yazmayacak)'}`);
  console.log(`Veritabanı: ${DATABASE_ID}, koleksiyon: ${COLLECTION}\n`);

  const snap = await db.collection(COLLECTION).get();
  const taranan = snap.docs.length;

  console.log(`Taranan doküman sayısı: ${taranan}`);
  if (taranan > TARAMA_UYARI_ESIGI) {
    console.warn(
      `⚠️  UYARI: ${taranan} doküman ${TARAMA_UYARI_ESIGI}'i aşıyor — bu script tek ` +
      'seferlik tam koleksiyon taraması için yazıldı, sayfalı taramaya geçmeden önce ' +
      'bd ile onaylanmalı. Devam ediliyor ama bu eşik artık geçerli değil, dikkat.',
    );
  }

  // Eksik doküman: { ref, deger, kaynak }
  const eksikler = [];
  let kaynakOlusturmaTarihi = 0;
  let kaynakCreateTime = 0;

  for (const doc of snap.docs) {
    const tarih = doc.get('tarih');
    if (tarih !== undefined && tarih !== null) continue;

    const olusturmaTarihi = doc.get('olusturmaTarihi');
    let deger;
    let kaynak;
    if (olusturmaTarihi !== undefined && olusturmaTarihi !== null) {
      deger = olusturmaTarihi;
      kaynak = 'olusturmaTarihi';
      kaynakOlusturmaTarihi++;
    } else {
      deger = Timestamp.fromDate(doc.createTime.toDate());
      kaynak = 'createTime';
      kaynakCreateTime++;
    }
    eksikler.push({ ref: doc.ref, id: doc.id, deger, kaynak });
  }

  console.log(`'tarih' alanı eksik doküman sayısı: ${eksikler.length}\n`);

  if (eksikler.length > 0) {
    console.log('Eksik dokümanlar:');
    for (const e of eksikler) {
      console.log(`  id=${e.id}  kullanilacakDeger=${e.deger.toDate().toISOString()}  kaynak=${e.kaynak}`);
    }
    console.log('');
    console.log('Kaynak dağılımı:');
    console.log(`  olusturmaTarihi'nden: ${kaynakOlusturmaTarihi}`);
    console.log(`  createTime'dan:      ${kaynakCreateTime}`);
    console.log('');
  }

  let yazilan = 0;

  if (uygula && eksikler.length > 0) {
    for (let i = 0; i < eksikler.length; i += GRUP_BOYUTU) {
      const grup = eksikler.slice(i, i + GRUP_BOYUTU);
      const batch = db.batch();
      for (const e of grup) {
        // update() kullanılıyor — set()/set(merge) DEĞİL: doküman yoksa
        // hata verir, yanlışlıkla yeni alan/doküman yaratma riskini
        // yapısal olarak kapatır.
        batch.update(e.ref, { tarih: e.deger });
      }
      await batch.commit();
      yazilan += grup.length;
      console.log(`${yazilan}/${eksikler.length} yazıldı`);
    }
  }

  console.log('\n── Özet ──');
  console.log(`Taranan:       ${taranan}`);
  console.log(`Eksik bulunan: ${eksikler.length}`);
  console.log(`Yazılan:       ${uygula ? yazilan : 0}${uygula ? '' : ' (dry run — yazılmadı)'}`);
}

main().catch((e) => {
  console.error('Script hata verdi:', e);
  process.exit(1);
});
