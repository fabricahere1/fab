// functions/src/degerlendirme.ts
//
// degerlendirmePuanGuncelle (onDocumentCreated, index.ts) içindeki
// ortalama puan hesaplamasının SAF hali — transaction'ın kendisinden
// (tx.get/tx.update) ayrıştırıldı, hiçbir Firestore bağımlılığı yok.
// Mantık, index.ts'ten davranış değiştirilmeden BİREBİR taşındı.

export interface YeniOrtalamaPuanParams {
  eskiSayi: number;
  eskiOrtalama: number;
  puan: number;
}

export interface YeniOrtalamaPuanSonuc {
  yeniSayi: number;
  guncelPuan: number;
}

export function hesaplaYeniOrtalamaPuan(
  params: YeniOrtalamaPuanParams
): YeniOrtalamaPuanSonuc {
  const { eskiSayi, eskiOrtalama, puan } = params;
  const yeniSayi = eskiSayi + 1;
  const yeniOrtalama = (eskiOrtalama * eskiSayi + puan) / yeniSayi;
  const guncelPuan = Math.round(yeniOrtalama * 10) / 10;
  return { yeniSayi, guncelPuan };
}
