import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const RULES_PATH = path.join(__dirname, '..', 'firestore.rules.oneri.txt');

const results = [];
let stopAt = null;

async function check(id, label, fn) {
  if (stopAt) return;
  try {
    await fn();
    results.push({ id, label, status: 'PASS' });
  } catch (e) {
    results.push({ id, label, status: 'FAIL', error: e.message });
    stopAt = id;
  }
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: 'rules-test-iste-v3',
    firestore: {
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });

  const UID_A = 'kullaniciA';
  const UID_B = 'kullaniciB';
  const asA = testEnv.authenticatedContext(UID_A).firestore();
  const asB = testEnv.authenticatedContext(UID_B).firestore();
  const asC = testEnv.authenticatedContext('kullaniciC').firestore();

  // ── Ortak seed verisi (kural motorunu atlayarak) ──
  const sohbetId = 'sohbet_AB';
  const ilanId = 'ilan_1';

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`kullanicilar/${UID_A}`).set({ ad: 'A' });
    await db.doc(`kullanicilar/${UID_B}`).set({ ad: 'B' });
    await db.doc(`ilanlar/${ilanId}`).set({
      kullaniciId: UID_A,
      durum: 'reddedildi',
      aktif: false,
      redSebebi: 'test-red',
      favoriSayisi: 0,
      goruntulenmeSayisi: 0,
    });
    await db.doc(`sohbetler/${sohbetId}`).set({
      kullanicilar: [UID_A, UID_B],
      islemDurumlari: {},
    });
  });

  // ══════════ A) MEŞRU AKIŞ TESTLERİ ══════════

  // A1 — Yeni sohbette ilk mesaj gönderme
  await check('A1', 'Yeni sohbette ilk mesaj gönderme', async () => {
    const yeniSohbetId = 'sohbet_yeni_A1';
    const batch = asA.batch();
    batch.set(asA.doc(`sohbetler/${yeniSohbetId}`), {
      kullanicilar: [UID_A, UID_B],
      islemDurumlari: {},
    });
    batch.set(asA.doc(`sohbetler/${yeniSohbetId}/mesajlar/m1`), {
      gondereId: UID_A,
      metin: 'merhaba',
    });
    await assertSucceeds(batch.commit());
  });

  // A2 — Karşılıklı cevaplaşma A→B, B→A
  await check('A2', 'Karşılıklı cevaplaşma (A→B, B→A)', async () => {
    await assertSucceeds(
      asA.doc(`sohbetler/${sohbetId}/mesajlar/mA1`).set({
        gondereId: UID_A,
        metin: 'selam B',
      })
    );
    await assertSucceeds(
      asB.doc(`sohbetler/${sohbetId}/mesajlar/mB1`).set({
        gondereId: UID_B,
        metin: 'selam A',
      })
    );
  });

  // A3 — Favori ekleme/çıkarma
  await check('A3', 'Favori ekleme/çıkarma', async () => {
    const favoriId = `${UID_A}_${ilanId}`;
    await assertSucceeds(
      asA.doc(`favoriler/${favoriId}`).set({
        kullaniciId: UID_A,
        ilanId,
      })
    );
    await assertSucceeds(asA.doc(`favoriler/${favoriId}`).delete());
  });

  // A4 — Reddedilen ilanı düzenleyip yeniden gönderme ("Tekrar Yayınla")
  await check('A4', 'Reddedilen ilanı düzenleyip yeniden gönderme', async () => {
    await assertSucceeds(
      asA.doc(`ilanlar/${ilanId}`).update({
        durum: 'onayBekliyor',
        redSebebi: '',
        urun: 'guncellenmis urun',
      })
    );
  });

  // A5 — Kendi ilanını pasife alma
  await check('A5', 'Kendi ilanını pasife alma (ilanPasifYap)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`ilanlar/${ilanId}`).update({ aktif: true, durum: 'yayinda' });
    });
    await assertSucceeds(asA.doc(`ilanlar/${ilanId}`).update({ aktif: false }));
  });

  // A6 — teslimAlindi sonrası değerlendirme yazma
  await check('A6', 'teslimAlindi sonrası değerlendirme yazma', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`sohbetler/${sohbetId}`).update({
        'islemDurumlari.teslimAlindi': true,
        'islemDurumlari.teslimAlindi_yapanUid': UID_B,
      });
    });
    await assertSucceeds(
      asA.collection('degerlendirmeler').add({
        degerlendireninId: UID_A,
        hedefKullaniciId: UID_B,
        puan: 5,
        sohbetId,
      })
    );
  });

  // ══════════ B) İSTİSMAR TESTLERİ ══════════

  // B1 — Kendi ilanına doğrudan {durum:'yayinda', aktif:true} yazma
  await check('B1', "İlanı doğrudan {durum:'yayinda', aktif:true} yapma denemesi", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`ilanlar/${ilanId}`).set({
        kullaniciId: UID_A,
        durum: 'onayBekliyor',
        aktif: false,
        favoriSayisi: 0,
        goruntulenmeSayisi: 0,
      });
    });
    await assertFails(
      asA.doc(`ilanlar/${ilanId}`).update({ durum: 'yayinda', aktif: true })
    );
  });

  // B2 — Sohbetin tarafı olmadan o sohbete mesaj yazma
  await check('B2', 'Sohbetin tarafı olmayan kullanıcının mesaj yazması', async () => {
    await assertFails(
      asC.doc(`sohbetler/${sohbetId}/mesajlar/mC1`).set({
        gondereId: 'kullaniciC',
        metin: 'izinsiz mesaj',
      })
    );
  });

  // B3 — teslimAlindi olmadan/sohbet tarafı olmadan değerlendirme yazma
  await check('B3', 'teslimAlindi olmadan / taraf olmadan değerlendirme yazma', async () => {
    const sohbetId2 = 'sohbet_AB_teslimsiz';
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`sohbetler/${sohbetId2}`).set({
        kullanicilar: [UID_A, UID_B],
        islemDurumlari: {},
      });
    });
    // 3a: teslimAlindi false iken değerlendirme
    await assertFails(
      asA.collection('degerlendirmeler').add({
        degerlendireninId: UID_A,
        hedefKullaniciId: UID_B,
        puan: 5,
        sohbetId: sohbetId2,
      })
    );
    // 3b: sohbetin tarafı olmayan biri değerlendirme yazmaya çalışıyor
    await assertFails(
      asC.collection('degerlendirmeler').add({
        degerlendireninId: 'kullaniciC',
        hedefKullaniciId: UID_B,
        puan: 5,
        sohbetId,
      })
    );
  });

  // B4 — Favoriler dokümanı hiç oluşturmadan favoriSayisi'ni artırma
  await check('B4', 'Favoriler dokümanı oluşturmadan favoriSayisi artırma', async () => {
    await assertFails(
      asA.doc(`ilanlar/${ilanId}`).update({ favoriSayisi: 1 })
    );
  });

  // B4b — Saldırgan ilanın SAHİBİ DEĞİL (kullaniciB), favoriler dokümanı
  // oluşturmadan favoriSayisi artırma
  await check('B4b', 'Sahip olmayan (B) favoriler dokümanı oluşturmadan favoriSayisi artırma', async () => {
    await assertFails(
      asB.doc(`ilanlar/${ilanId}`).update({ favoriSayisi: 1 })
    );
  });

  // B5 — Kendi kendini takip etme
  await check('B5', 'Kendi kendini takip etme denemesi', async () => {
    await assertFails(
      asA.doc(`takipler/${UID_A}_${UID_A}`).set({
        takipciId: UID_A,
        takipEdilenId: UID_A,
      })
    );
  });

  // B6 — Sohbetin tarafı olmayan saldırgan (kullaniciC), hedefId=gerçek
  // sohbetId, kullaniciId=o sohbetin taraflarından biri olacak şekilde
  // sahte bildirim yazmaya çalışıyor. sohbetKatilimcisiMi(hedefId)
  // saldırganı reddetmeli.
  await check('B6', 'Sohbetin tarafı olmayan saldırganın sahte bildirim yazması', async () => {
    await assertFails(
      asC.collection('bildirimler').add({
        gondereId: 'kullaniciC',
        kullaniciId: UID_B,
        hedefId: sohbetId,
      })
    );
  });

  // B7 — Saldırgan (kullaniciA, sohbetin gerçek tarafı) teslimAlindi'yi
  // true yaparken teslimAlindi_yapanUid'i KENDİ uid'i yerine karşı tarafın
  // (B) uid'i olarak yazmaya çalışıyor — sahte onay/imza taklidi.
  // tekTarafliAdimGecerliMi() bunu reddetmeli.
  // NOT: A6 testi sohbetId'nin teslimAlindi alanını zaten true+yapanUid=B
  // yapmış durumda — aynı dokümanda tekrar denersek yazma idempotent
  // (hiçbir alan gerçekten değişmez) olur ve rule "adimDegisti=false"
  // dolayısıyla yanlışlıkla izin verir. Bu yüzden false→true geçişini
  // gerçekten tetiklemek için TAZE bir sohbet dokümanı kullanıyoruz.
  await check('B7', "Karşı tarafın onayını taklit etme (teslimAlindi_yapanUid sahteciliği)", async () => {
    const sohbetId3 = 'sohbet_AB_b7';
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`sohbetler/${sohbetId3}`).set({
        kullanicilar: [UID_A, UID_B],
        islemDurumlari: {},
      });
    });
    await assertFails(
      asA.doc(`sohbetler/${sohbetId3}`).update({
        'islemDurumlari.teslimAlindi': true,
        'islemDurumlari.teslimAlindi_yapanUid': UID_B,
      })
    );
  });

  // B8 — Var olan bir sohbette, alıcı (B) gönderen (A) kişiyi zaten
  // engellemiş — A'nın mesaj göndermesi reddedilmeli.
  await check('B8', 'Var olan sohbette engellenen kullanıcının mesaj göndermesi', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`kullanicilar/${UID_B}`).set(
        { engellenenler: [UID_A] },
        { merge: true }
      );
    });
    await assertFails(
      asA.doc(`sohbetler/${sohbetId}/mesajlar/mEngelli1`).set({
        gondereId: UID_A,
        metin: 'engelliyken mesaj',
      })
    );
  });

  // B9 — TAZE bir sohbette (henüz hiç mesaj yok, ilk temas), alıcı
  // gönderen kişiyi ÖNCEDEN engellemişse İLK mesaj da reddedilmeli.
  // En kritik senaryo: A1 ile AYNI kod yolunu (sohbet+mesaj tek batch'te,
  // getAfter() gerektiren taze sohbet) kullanıyor — bu yüzden A1'in
  // (engelsiz) hâlâ PASS, B9'un (engelli) FAIL vermesi,
  // aliciTarafindanEngellenmemis()'in getAfter() kullandığının en net
  // kanıtı.
  await check('B9', 'TAZE sohbette (ilk temas) önceden engellenmiş kullanıcının mesaj göndermesi', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`kullanicilar/${UID_B}`).set(
        { engellenenler: [UID_A] },
        { merge: true }
      );
    });
    const yeniSohbetId = 'sohbet_yeni_B9';
    const batch = asA.batch();
    batch.set(asA.doc(`sohbetler/${yeniSohbetId}`), {
      kullanicilar: [UID_A, UID_B],
      islemDurumlari: {},
    });
    batch.set(asA.doc(`sohbetler/${yeniSohbetId}/mesajlar/m1`), {
      gondereId: UID_A,
      metin: 'merhaba (engelliyim)',
    });
    await assertFails(batch.commit());
  });

  await testEnv.cleanup();
}

main()
  .then(() => {
    console.log('\n=== SONUÇ ===');
    for (const r of results) {
      console.log(`[${r.status}] ${r.id} — ${r.label}`);
      if (r.status === 'FAIL') console.log(`    Hata: ${r.error}`);
    }
    const anyFail = results.some((r) => r.status === 'FAIL');
    const ranCount = results.length;
    console.log(`\n${ranCount} test çalıştı.`);
    process.exit(anyFail ? 1 : 0);
  })
  .catch((e) => {
    console.error('Test ortamı hatası:', e);
    process.exit(1);
  });
