/**
 * TEK SEFERLİK ONARIM ARACI — çalıştırılmadı, arşivde bekliyor.
 * Gerekirse dry-run ile başla (--apply olmadan); service account
 * anahtarı indirmeden önce gerçek kullanıcı verisi olup olmadığını
 * doğrula. Test verisi için çalıştırmaya değmez.
 *
 * TEK SEFERLİK ONARIM SCRIPT'İ — tekrar çalıştırma.
 *
 * Sorun: mesajGonder'daki koşulsuz merge, ilanResimUrl'si olmayan
 *        (örn. mesaj bildirimi yoluyla açılan) sohbetlerde alanı
 *        boş string ile eziyordu.
 *
 * Bu script:
 *   1. ilanId dolu + ilanResimUrl boş/yok olan tüm sohbetleri tarar.
 *   2. Her sohbet için ilanlar/{ilanId} belgesini çeker.
 *   3. DRY-RUN (varsayılan): sadece rapor yazar, hiçbir şey yazmaz.
 *   4. --apply bayrağıyla: resimThumbUrl (yoksa resimUrl) alanını yazar.
 *
 * Kullanım:
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *   npx ts-node tools/onarSohbetResimler.ts            # dry-run
 *   npx ts-node tools/onarSohbetResimler.ts --apply    # gerçek yazma
 */

import * as admin from "firebase-admin";

const APPLY = process.argv.includes("--apply");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});
const db = admin.firestore();

async function main() {
  console.log(`\n=== Sohbet Resim Onarımı — ${APPLY ? "APPLY" : "DRY-RUN"} ===\n`);

  // ilanId dolu + ilanResimUrl boş olan sohbetler
  const snap = await db
    .collection("sohbetler")
    .where("ilanId", "!=", "")
    .get();

  const adaylar = snap.docs.filter((doc) => {
    const d = doc.data();
    const url = (d.ilanResimUrl as string | undefined) ?? "";
    return url === "";
  });

  console.log(`ilanId dolu + ilanResimUrl boş: ${adaylar.length} sohbet\n`);

  let onarilabilir = 0;
  let silinmis = 0;
  let zatenDolu = 0; // filtre sonrası olmamalı ama güvence için

  const yazilacaklar: { ref: FirebaseFirestore.DocumentReference; resimUrl: string; sohbetId: string }[] = [];

  for (const doc of adaylar) {
    const data = doc.data();
    const ilanId = data.ilanId as string;

    const ilanSnap = await db.collection("ilanlar").doc(ilanId).get();

    if (!ilanSnap.exists) {
      console.log(`  [ATLA]    sohbet=${doc.id}  ilan=${ilanId} → ilan silinmiş`);
      silinmis++;
      continue;
    }

    const ilanData = ilanSnap.data()!;
    const resimUrl =
      (ilanData.resimThumbUrl as string | undefined) ||
      (ilanData.resimUrl     as string | undefined) ||
      "";

    if (!resimUrl) {
      console.log(`  [ATLA]    sohbet=${doc.id}  ilan=${ilanId} → ilan resmi yok`);
      silinmis++;
      continue;
    }

    console.log(`  [ONARILACAK] sohbet=${doc.id}  ilan=${ilanId}  resim=${resimUrl.slice(0, 60)}…`);
    yazilacaklar.push({ ref: doc.ref, resimUrl, sohbetId: doc.id });
    onarilabilir++;
  }

  console.log(`\n── Özet ──────────────────────────────────────────`);
  console.log(`  Toplam aday    : ${adaylar.length}`);
  console.log(`  Onarılabilir   : ${onarilabilir}`);
  console.log(`  Atlanacak      : ${silinmis}  (ilan silinmiş veya resim yok)`);

  if (!APPLY) {
    console.log(`\nDRY-RUN bitti — yazmak için --apply bayrağıyla çalıştır.\n`);
    process.exit(0);
  }

  // ── APPLY ──────────────────────────────────────────────────────────────────
  console.log(`\nYazılıyor…`);
  const BATCH_SIZE = 400;
  let toplam = 0;

  for (let i = 0; i < yazilacaklar.length; i += BATCH_SIZE) {
    const dilim = yazilacaklar.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const { ref, resimUrl } of dilim) {
      batch.update(ref, { ilanResimUrl: resimUrl });
    }
    await batch.commit();
    toplam += dilim.length;
    console.log(`  ${toplam}/${yazilacaklar.length} yazıldı`);
  }

  console.log(`\nTamamlandı — ${toplam} sohbet onarıldı.\n`);
  process.exit(0);
}

main().catch((err) => {
  console.error("HATA:", err);
  process.exit(1);
});
