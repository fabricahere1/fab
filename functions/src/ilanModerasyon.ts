// functions/src/ilanModerasyon.ts
//
// ilanGuncellemeModerasyon (onDocumentUpdated, index.ts) içindeki
// yenidenDenenmeliMi hesaplamasının SAF hali — hiçbir Firestore event
// nesnesine bağımlı değil, yalnızca once/sonra'nın kullanılan iki alanını
// (durum, aktif) parametre olarak alır. Mantık, index.ts'ten davranış
// değiştirilmeden BİREBİR taşındı (dün "kilitlenme" bug'ı düzeltilirken
// eklenen once.aktif===false dalı dahil).

export function yenidenDenenmeliMiHesapla(
  once: { durum?: string; aktif?: boolean },
  sonra: { durum?: string }
): boolean {
  return (
    (once.durum === "reddedildi" && sonra.durum === "onayBekliyor") ||
    (once.aktif === false && sonra.durum === "onayBekliyor")
  );
}

// ── İkili bildirim gönderimi (push + Firestore) ─────────────────────────
//
// index.ts'teki ilanModerasyonu (onay bildirimi) bloğundan taşındı.
// push ve Firestore yazımı Promise.allSettled ile birbirinden BAĞIMSIZ
// çalışır — biri reddedilse bile diğeri sonuna kadar tamamlanır. Firebase
// Admin SDK'ya (admin.messaging()/db) doğrudan bağımlı değil, push/yazma
// işlemlerini thunk (parametre) olarak alır — bu sayede emulator/mock
// kurmadan node:test ile doğrudan test edilebiliyor.
export async function ikiliBildirimGonder(
  pushGonder: () => Promise<unknown>,
  firestoreYaz: () => Promise<unknown>,
  logla: (mesaj: string, hata: unknown) => void = console.warn
): Promise<{ pushBasarili: boolean; firestoreBasarili: boolean }> {
  const [pushSonucu, firestoreSonucu] = await Promise.allSettled([
    pushGonder(),
    firestoreYaz(),
  ]);

  if (pushSonucu.status === "rejected") {
    logla("Bildirim gönderilemedi (push):", pushSonucu.reason);
  }
  if (firestoreSonucu.status === "rejected") {
    logla("Bildirim gönderilemedi (firestore):", firestoreSonucu.reason);
  }

  return {
    pushBasarili: pushSonucu.status === "fulfilled",
    firestoreBasarili: firestoreSonucu.status === "fulfilled",
  };
}
