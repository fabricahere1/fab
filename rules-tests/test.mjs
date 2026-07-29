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
  const UID_E = 'kullaniciE';
  const asE = testEnv.authenticatedContext(UID_E).firestore();

  // ── Ortak seed verisi (kural motorunu atlayarak) ──
  const sohbetId = 'sohbet_AB';
  const ilanId = 'ilan_1';

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`kullanicilar/${UID_A}`).set({ ad: 'A' });
    await db.doc(`kullanicilar/${UID_B}`).set({ ad: 'B' });
    await db.doc(`kullanicilar/${UID_E}`).set({ ad: 'E', ortalamaPuan: 2 });
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
  // birbiriniEngellememis()'in getAfter() kullandığının en net kanıtı.
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

  // B10 — Var olan bir sohbette, GÖNDEREN (A) alıcıyı (B) engellemiş
  // (B8'in tersi yönü) — A'nın mesaj göndermesi yine reddedilmeli.
  await check('B10', 'Var olan sohbette GÖNDERENİN alıcıyı engellemiş olması (B8\'in tersi)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      // B8/B9'dan kalan durumu sıfırla — yalnızca "A, B'yi engellemiş"
      // yönünü izole ediyoruz, B'nin A'yı engellemesi bu testte YOK.
      const db = ctx.firestore();
      await db.doc(`kullanicilar/${UID_B}`).set({ engellenenler: [] }, { merge: true });
      await db.doc(`kullanicilar/${UID_A}`).set({ engellenenler: [UID_B] }, { merge: true });
    });
    await assertFails(
      asA.doc(`sohbetler/${sohbetId}/mesajlar/mEngelli2`).set({
        gondereId: UID_A,
        metin: 'ben seni engelledim ama mesaj atmayi deniyorum',
      })
    );
  });

  // B11 — TAZE bir sohbette (ilk temas), GÖNDEREN alıcıyı ÖNCEDEN
  // engellemişse İLK mesaj da reddedilmeli (B9'un tersi yönü). Yine A1
  // ile AYNI kod yolu (sohbet+mesaj tek batch'te) — bu karşılaştırma
  // birbiriniEngellememis()'in gönderen tarafı için de getAfter()'a
  // (alıcıyı bulmak için) doğru bağlandığının kanıtı.
  await check('B11', 'TAZE sohbette GÖNDERENİN alıcıyı ÖNCEDEN engellemiş olması (B9\'un tersi)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc(`kullanicilar/${UID_A}`).set({ engellenenler: [UID_B] }, { merge: true });
      await db.doc(`kullanicilar/${UID_B}`).set({ engellenenler: [] }, { merge: true });
    });
    const yeniSohbetId = 'sohbet_yeni_B11';
    const batch = asA.batch();
    batch.set(asA.doc(`sohbetler/${yeniSohbetId}`), {
      kullanicilar: [UID_A, UID_B],
      islemDurumlari: {},
    });
    batch.set(asA.doc(`sohbetler/${yeniSohbetId}/mesajlar/m1`), {
      gondereId: UID_A,
      metin: 'merhaba (ben seni engellemistim)',
    });
    await assertFails(batch.commit());
  });

  // B12 — Regresyon (3dde4f6, 2026-07-05): HENÜZ hiç görüntülenmemiş bir
  // ilanı ilk kez görüntüleme. goruntulenmeler/{UID_A}_{ilanId} dokümanı
  // henüz yok — transaction get() sırasında resource null olur. read
  // kuralı bunu reddetmemeli (goruntulenmeyiKaydet()'in gerçek client
  // kod yoluyla birebir aynı: get → set + goruntulenmeSayisi++ tek
  // transaction'da).
  await check('B12', 'İlk kez görüntüleme — henüz var olmayan goruntulenmeler dokümanının transaction get() ile okunabilmesi', async () => {
    const goruntulenmeId = `${UID_A}_${ilanId}`;
    await assertSucceeds(
      asA.runTransaction(async (txn) => {
        const kayitRef = asA.doc(`goruntulenmeler/${goruntulenmeId}`);
        const snap = await txn.get(kayitRef);
        if (snap.exists) return;
        txn.set(kayitRef, {
          kullaniciId: UID_A,
          ilanId,
          sonTarih: new Date(),
        });
        txn.update(asA.doc(`ilanlar/${ilanId}`), {
          goruntulenmeSayisi: 1,
        });
      })
    );
  });

  // B13 — Regresyon (bkz. TAM_SAGLIK_TARAMASI.md, firestore.rules.oneri.txt
  // düzeltmesi): HENÜZ hiç oluşturulmamış bir sohbeti get() ile sorgulama
  // (ör. "bu ilan için A ile B arasında zaten sohbet var mı" kontrolü).
  // resource null olur — read kuralı bunu reddetmemeli. Ardından, doküman
  // GERÇEKTEN var olduğunda katılımcı olmayan (C) kullanıcının HÂLÂ
  // erişemediğini doğrulayarak asıl güvenliğin bozulmadığını teyit ediyoruz.
  await check('B13', 'Henüz var olmayan bir sohbeti get() ile sorgulama PERMISSION_DENIED fırlatmamalı', async () => {
    const yokSohbetId = 'sohbet_hic_olusmadi_B13';
    await assertSucceeds(asA.doc(`sohbetler/${yokSohbetId}`).get());
  });

  await check('B13b', 'Sohbet gerçekten oluşunca, katılımcı olmayan (C) kullanıcı HÂLÂ okuyamamalı', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc(`sohbetler/sohbet_b13_var`).set({
        kullanicilar: [UID_A, UID_B],
        islemDurumlari: {},
      });
    });
    await assertFails(asC.doc(`sohbetler/sohbet_b13_var`).get());
  });

  // ══════════ C) İLAN OLUŞTURMA HIZ SINIRLAMASI (COOLDOWN) ══════════
  // kullaniciId=UID_B kullanılıyor — seed verisinde B'nin henüz hiç ilanı
  // ve sonIlanOlusturmaZamani alanı yok, bu yüzden temiz bir başlangıç.

  const ilanCreateVerisi = (ekstra = {}) => ({
    kullaniciId: UID_B,
    durum: 'onayBekliyor',
    aktif: false,
    ...ekstra,
  });

  const ilanVeCooldownYaz = (ilanKey) => {
    const batch = asB.batch();
    batch.set(asB.doc(`ilanlar/${ilanKey}`), ilanCreateVerisi());
    batch.set(
      asB.doc(`kullanicilar/${UID_B}`),
      { sonIlanOlusturmaZamani: new Date() },
      { merge: true }
    );
    return batch.commit();
  };

  // C1 — Kullanıcının hiç sonIlanOlusturmaZamani'ı yokken ilk ilanı
  // oluşturması engellenmemeli (yeni kullanıcı kilitlenmesin).
  await check('C1', 'Hiç cooldown damgası yokken ilk ilan oluşturma başarılı olmalı', async () => {
    await assertSucceeds(ilanVeCooldownYaz('ilan_ratelimit_1'));
  });

  // C2 — C1'in hemen ardından (30sn dolmadan) ikinci bir ilan denemesi
  // REDDEDİLMELİ — asıl hız sınırlaması testi.
  await check('C2', '30 saniye dolmadan ikinci ilan denemesi reddedilmeli', async () => {
    await assertFails(ilanVeCooldownYaz('ilan_ratelimit_2'));
  });

  // C3 — Kullanıcının son ilanı 30 saniyeden ESKİYSE (burada test ortamında
  // gerçek zamanı 30sn beklemek yerine damgayı geriye alıyoruz), yeni ilan
  // oluşturma yine başarılı olmalı — normal hızda kullanım kırılmamalı.
  await check('C3', '30 saniyeden eski cooldown damgasıyla normal hızda ilan oluşturma başarılı olmalı', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`kullanicilar/${UID_B}`).set(
        { sonIlanOlusturmaZamani: new Date(Date.now() - 40_000) },
        { merge: true }
      );
    });
    await assertSucceeds(ilanVeCooldownYaz('ilan_ratelimit_3'));
  });

  // ══════════ D) İLAN CREATE'TE İTİBAR/SAYAÇ ALANI ENJEKSİYONU ══════════
  // kullaniciId=UID_E kullanılıyor — profilinde gerçek ortalamaPuan=2 var,
  // C-serisindeki cooldown'dan bağımsız temiz bir kullanıcı.

  // D1 — Yeni ilanı doğrudan favoriSayisi:50 ile doğurmaya çalışma.
  await check('D1', 'CREATE sırasında favoriSayisi enjekte etme reddedilmeli', async () => {
    await assertFails(
      asE.doc(`ilanlar/ilan_inject_1`).set(
        { kullaniciId: UID_E, durum: 'onayBekliyor', aktif: false, favoriSayisi: 50 }
      )
    );
  });

  // D2 — Yeni ilanı doğrudan onerilenPuan ile doğurmaya çalışma (yalnızca
  // Admin SDK/Cloud Function yazabilmeli).
  await check('D2', 'CREATE sırasında onerilenPuan enjekte etme reddedilmeli', async () => {
    await assertFails(
      asE.doc(`ilanlar/ilan_inject_2`).set(
        { kullaniciId: UID_E, durum: 'onayBekliyor', aktif: false, onerilenPuan: 99 }
      )
    );
  });

  // D3 — Gerçek profil puanı (2) yerine sahte yüksek bir kullaniciPuan (5)
  // ile ilan oluşturma — itibar sahteciliği reddedilmeli.
  await check('D3', 'CREATE sırasında gerçek profil puanından farklı kullaniciPuan reddedilmeli', async () => {
    await assertFails(
      asE.doc(`ilanlar/ilan_inject_3`).set(
        { kullaniciId: UID_E, durum: 'onayBekliyor', aktif: false, kullaniciPuan: 5 }
      )
    );
  });

  // D4 — Gerçek profil puanıyla (2) eşleşen kullaniciPuan ile normal ilan
  // oluşturma başarılı olmalı — meşru akış kırılmamalı.
  await check('D4', 'CREATE sırasında gerçek profil puanıyla eşleşen kullaniciPuan başarılı olmalı', async () => {
    await assertSucceeds(
      asE.doc(`ilanlar/ilan_inject_4`).set(
        { kullaniciId: UID_E, durum: 'onayBekliyor', aktif: false, kullaniciPuan: 2 }
      )
    );
  });

  // ══════════ E) ŞİKAYET (RAPOR) HIZ SINIRLAMASI ══════════
  // asA kullanılıyor — A'nın henüz sonSikayetZamani'ı yok, temiz başlangıç.

  const sikayetVeCooldownYaz = (sikayetKey) => {
    const batch = asA.batch();
    batch.set(asA.doc(`sikayetler/${sikayetKey}`), {
      sikayetEdenId: UID_A,
      hedefId: UID_B,
      hedefAd: 'B',
      sebep: 'spam',
      ilanId,
    });
    batch.set(
      asA.doc(`kullanicilar/${UID_A}`),
      { sonSikayetZamani: new Date() },
      { merge: true }
    );
    return batch.commit();
  };

  // E1 — Hiç sonSikayetZamani'ı yokken ilk şikayeti gönderme başarılı olmalı.
  await check('E1', 'Hiç cooldown damgası yokken ilk şikayet gönderme başarılı olmalı', async () => {
    await assertSucceeds(sikayetVeCooldownYaz('sikayet_ratelimit_1'));
  });

  // E2 — E1'in hemen ardından (15sn dolmadan) ikinci bir şikayet denemesi
  // REDDEDİLMELİ — kitlesel/taciz amaçlı şikayet spam'ini önleyen asıl test.
  await check('E2', '15 saniye dolmadan ikinci şikayet denemesi reddedilmeli', async () => {
    await assertFails(sikayetVeCooldownYaz('sikayet_ratelimit_2'));
  });

  // E3 — 15 saniyeden eski cooldown damgasıyla normal hızda şikayet
  // gönderme yine başarılı olmalı — meşru akış kırılmamalı.
  await check('E3', '15 saniyeden eski cooldown damgasıyla normal hızda şikayet gönderme başarılı olmalı', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`kullanicilar/${UID_A}`).set(
        { sonSikayetZamani: new Date(Date.now() - 20_000) },
        { merge: true }
      );
    });
    await assertSucceeds(sikayetVeCooldownYaz('sikayet_ratelimit_3'));
  });

  // ══════════ F) MESAJ HIZ SINIRLAMASI (FLOOD/SPAM) ══════════
  // Taze bir sohbet (sohbet_hiz_F) kullanılıyor — A ve B arasında, diğer
  // testlerin sonGondereId/sonMesajZamani alanlarını hiç dokunmadığı temiz
  // bir başlangıç. NOT: B11 testi kullanicilar/A.engellenenler=[B] bırakıyor
  // ve sıfırlamıyor — burada temizlemezsek birbiriniEngellememis() bu
  // seride A/B arası HER mesajı (benim yeni kodumla ilgisiz bir sebeple)
  // reddeder.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`kullanicilar/${UID_A}`).set({ engellenenler: [] }, { merge: true });
    await db.doc(`kullanicilar/${UID_B}`).set({ engellenenler: [] }, { merge: true });
  });

  const sohbetIdF = 'sohbet_hiz_F';
  const mesajGonderF = (asKim, mesajKey, gondereId) => {
    const batch = asKim.batch();
    batch.set(
      asKim.doc(`sohbetler/${sohbetIdF}`),
      {
        kullanicilar: [UID_A, UID_B],
        sonGondereId: gondereId,
        sonMesajZamani: new Date(),
      },
      { merge: true }
    );
    batch.set(asKim.doc(`sohbetler/${sohbetIdF}/mesajlar/${mesajKey}`), {
      gondereId,
      metin: 'test',
    });
    return batch.commit();
  };

  // F1 — Taze sohbette (ilk temas) A'nın ilk mesajı başarılı olmalı.
  await check('F1', 'Taze sohbette A\'nın ilk mesajı başarılı olmalı', async () => {
    await assertSucceeds(mesajGonderF(asA, 'mF1', UID_A));
  });

  // F2 — F1'in hemen ardından (1sn dolmadan) AYNI gönderenin (A) ikinci
  // mesajı REDDEDİLMELİ — asıl flood/spam koruması testi.
  await check('F2', '1 saniye dolmadan AYNI göndereninin ikinci mesajı reddedilmeli', async () => {
    await assertFails(mesajGonderF(asA, 'mF2', UID_A));
  });

  // F3 — Karşı tarafın (B) hemen cevap yazması, timing'den BAĞIMSIZ olarak
  // başarılı olmalı — cooldown yalnızca AYNI göndereni sınırlıyor.
  await check('F3', 'Karşı tarafın (B) hemen cevap yazması timing\'den bağımsız başarılı olmalı', async () => {
    await assertSucceeds(mesajGonderF(asB, 'mF3', UID_B));
  });

  // F4 — 1 saniyeden eski bir sonMesajZamani ile AYNI göndereninin (A) tekrar
  // mesaj göndermesi yine başarılı olmalı — meşru akış kırılmamalı.
  await check('F4', '1 saniyeden eski damgayla AYNI göndereninin tekrar mesajı başarılı olmalı', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`sohbetler/${sohbetIdF}`).set(
        { sonGondereId: UID_A, sonMesajZamani: new Date(Date.now() - 2_000) },
        { merge: true }
      );
    });
    await assertSucceeds(mesajGonderF(asA, 'mF4', UID_A));
  });

  // ══════════ G) SCRAPING/TOPLU-DÖKME KORUMASI (list limit tavanı) ══════════

  // G1 — Normal sayfalama boyutuyla (uygulamanın kendi sayfa boyutu 20'nin
  // altında bir örnek) ilanlar listesi sorgulama başarılı olmalı.
  await check('G1', 'ilanlar: limit(10) ile normal liste sorgusu başarılı olmalı', async () => {
    await assertSucceeds(asA.collection('ilanlar').limit(10).get());
  });

  // G2 — Tek seferde tüm koleksiyonu dökmeye çalışan aşırı büyük bir limit
  // REDDEDİLMELİ — asıl scraping koruması testi.
  await check('G2', 'ilanlar: limit(5000) ile toplu-dökme denemesi reddedilmeli', async () => {
    await assertFails(asA.collection('ilanlar').limit(5000).get());
  });

  // G3 — degerlendirmeler için de aynı tavan geçerli olmalı.
  await check('G3', 'degerlendirmeler: limit(5000) ile toplu-dökme denemesi reddedilmeli', async () => {
    await assertFails(asA.collection('degerlendirmeler').limit(5000).get());
  });

  // ══════════ H) FAVORİ EKLE/SİL TOGGLE-SPAM HIZ SINIRLAMASI ══════════
  // asC kullanılıyor — henüz hiç favorisi ve sonFavoriZamani'ı olmayan
  // temiz bir kullanıcı (diğer serilerden bağımsız).

  const favoriVeCooldownYaz = (uid, asKim, favoriIlanId) => {
    const favoriId = `${uid}_${favoriIlanId}`;
    const batch = asKim.batch();
    batch.set(asKim.doc(`favoriler/${favoriId}`), {
      kullaniciId: uid,
      ilanId: favoriIlanId,
    });
    batch.set(
      asKim.doc(`kullanicilar/${uid}`),
      { sonFavoriZamani: new Date() },
      { merge: true }
    );
    return batch.commit();
  };

  // H1 — Hiç sonFavoriZamani'ı yokken ilk favori ekleme başarılı olmalı.
  await check('H1', 'Hiç cooldown damgası yokken ilk favori ekleme başarılı olmalı', async () => {
    await assertSucceeds(favoriVeCooldownYaz('kullaniciC', asC, 'ilan_h1'));
  });

  // H2 — H1'in hemen ardından (2sn dolmadan), aynı favoriyi sil(rules
  // bypass ile simüle)-tekrar-ekle denemesi REDDEDİLMELİ — asıl toggle-spam
  // koruması testi (ekle/sil/ekle döngüsü).
  await check('H2', '2 saniye dolmadan ikinci favori ekleme denemesi reddedilmeli', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`favoriler/kullaniciC_ilan_h1`).delete();
    });
    await assertFails(favoriVeCooldownYaz('kullaniciC', asC, 'ilan_h1'));
  });

  // H3 — 2 saniyeden eski cooldown damgasıyla normal hızda favori ekleme
  // yine başarılı olmalı — meşru akış kırılmamalı.
  await check('H3', '2 saniyeden eski cooldown damgasıyla normal hızda favori ekleme başarılı olmalı', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`kullanicilar/kullaniciC`).set(
        { sonFavoriZamani: new Date(Date.now() - 3_000) },
        { merge: true }
      );
    });
    await assertSucceeds(favoriVeCooldownYaz('kullaniciC', asC, 'ilan_h1'));
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
