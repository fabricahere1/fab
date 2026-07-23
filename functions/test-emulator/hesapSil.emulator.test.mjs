// Firestore + Auth emulator gerektiren izole entegrasyon testi — hesapSilSunucu.
// Çalıştırma: bkz. functions/test-emulator/README.md (firebase emulators:exec ile).
//
// Bu, functions/test/*.test.ts'teki saf-fonksiyon testlerinden FARKLI — gerçek
// Cloud Function'ı (Firestore batch silmeler + Auth kullanıcı silme dahil)
// canlı emulator'a karşı çalıştırır. `npm test`'in glob'una dahil DEĞİL,
// ayrı ve manuel çalıştırılır.

import assert from 'node:assert/strict';
import { test } from 'node:test';

process.env.FIRESTORE_EMULATOR_HOST ??= 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= 'localhost:9099';
process.env.GCLOUD_PROJECT = 'demo-hesapsil-test';

const admin = (await import('firebase-admin')).default;
const { getFirestore } = await import('firebase-admin/firestore');
const functionsTest = (await import('firebase-functions-test')).default();

// Cloud Function modülü admin.initializeApp()'i kendi içinde çağırıyor —
// env değişkenleri ayarlandıktan SONRA import edilmesi şart.
const { hesapSilSunucu } = await import('../lib/index.js');

const wrappedHesapSil = functionsTest.wrap(hesapSilSunucu);

// hesapSilSunucu'nun kendisi de "iste-eu" adlı (default OLMAYAN) veritabanını
// kullanıyor — test verisi de AYNI veritabanına yazılmalı, yoksa fonksiyon
// hiçbir şey bulamaz.
const DATABASE_ID = 'iste-eu';
const db = getFirestore(admin.app(), DATABASE_ID);

async function temizle() {
  // Test verisini emulator'da baştan temiz başlatmak için ilgili dokümanları sil.
  const koleksiyonlar = ['kullanicilar', 'ilanlar', 'favoriler'];
  for (const kol of koleksiyonlar) {
    const snap = await db.collection(kol).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

test('hesapSilSunucu — favoriSayisi drift düzeltmesi + doğru kapsam', async (t) => {
  await temizle();

  const testUid  = 'test_uid';
  const baskaUid = 'baska_uid';

  // Auth emulator'da gerçek kullanıcılar (admin.auth().deleteUser(testUid) başarısız olmasın diye)
  await admin.auth().createUser({ uid: testUid,  email: 'test@ornek.com' });
  await admin.auth().createUser({ uid: baskaUid, email: 'baska@ornek.com' });

  // ── Senaryo verisi ──
  // ilan_A: BAŞKASININ ilanı (baskaUid'e ait) — test_uid'nin hesabı silinince
  // silinMEMELİ.
  await db.collection('ilanlar').doc('ilan_A').set({
    kullaniciId: baskaUid, urun: 'A ürünü', tip: 'tasiyici',
    aktif: true, durum: 'yayinda', favoriSayisi: 1,
  });

  // ilan_B: test_uid'nin KENDİ ilanı — hesap silinince silinMELİ.
  await db.collection('ilanlar').doc('ilan_B').set({
    kullaniciId: testUid, urun: 'B ürünü', tip: 'tasiyici',
    aktif: true, durum: 'yayinda', favoriSayisi: 0,
  });

  // baskaUid, ilan_A'yı favorilemiş (kendi ilanı, kendi favorisi) — test_uid'nin
  // hesap silmesiyle HİÇ ilgisi yok, dokunulmamalı.
  await db.collection('favoriler').doc(`${baskaUid}_ilan_A`).set({
    kullaniciId: baskaUid, ilanId: 'ilan_A',
  });

  // KRİTİK senaryo: test_uid, BAŞKASININ ilanını (ilan_A) favorilemiş.
  // Hesabı silinince bu favori dokümanı silinmeli VE ilan_A'nın favoriSayisi
  // 1 azalmalı (dünkü favoriSayisi drift düzeltmesinin gerçek kanıtı).
  await db.collection('favoriler').doc(`${testUid}_ilan_A`).set({
    kullaniciId: testUid, ilanId: 'ilan_A',
  });

  // ── hesapSilSunucu'yu çağır ──
  await wrappedHesapSil({ auth: { uid: testUid } });

  // ── Doğrulamalar ──
  const ilanASnap = await db.collection('ilanlar').doc('ilan_A').get();
  const ilanBSnap = await db.collection('ilanlar').doc('ilan_B').get();
  const baskaFavoriSnap = await db.collection('favoriler').doc(`${baskaUid}_ilan_A`).get();
  const testFavoriSnap  = await db.collection('favoriler').doc(`${testUid}_ilan_A`).get();

  await t.test('a) ilan_A (başkasının ilanı) hâlâ var', () => {
    assert.equal(ilanASnap.exists, true);
  });

  await t.test('b) ilan_A favoriSayisi 1\'den 0\'a düştü (drift düzeltmesi kanıtı)', () => {
    assert.equal(ilanASnap.data().favoriSayisi, 0);
  });

  await t.test('c) ilan_B (test_uid\'nin kendi ilanı) silindi', () => {
    assert.equal(ilanBSnap.exists, false);
  });

  await t.test('d) baskaUid\'nin favori dokümanı etkilenmedi', () => {
    assert.equal(baskaFavoriSnap.exists, true);
  });

  await t.test('e) test_uid\'nin favori dokümanı silindi', () => {
    assert.equal(testFavoriSnap.exists, false);
  });

  await t.test('f) Auth kullanıcısı silindi', async () => {
    await assert.rejects(() => admin.auth().getUser(testUid));
  });

  functionsTest.cleanup();
});
