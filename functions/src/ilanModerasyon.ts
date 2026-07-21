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
