// functions/src/guvenSkoru.ts
//
// guvenSkoruHesapla (onSchedule, index.ts) tarafından çağrılan SAF hesaplama
// fonksiyonu — hiçbir Firebase/Firestore bağımlılığı yok, bu yüzden emulator
// olmadan doğrudan unit test edilebilir. Mantık, index.ts'teki onSchedule
// callback'inin İÇİNDEN, davranış değiştirilmeden BİREBİR buraya taşındı.

export interface GuvenSkoruParams {
  ortalamaPuan: number;
  degerlendirmeSayisi: number;
  aktifIlanSayisi: number;
  adSoyadVar: boolean;
  telefonVar: boolean;
  sehirVar: boolean;
  hakkindaVar: boolean;
}

export function hesaplaGuvenSkoru(params: GuvenSkoruParams): number {
  const {
    ortalamaPuan,
    degerlendirmeSayisi,
    aktifIlanSayisi,
    adSoyadVar,
    telefonVar,
    sehirVar,
    hakkindaVar,
  } = params;

  const degerlendirmePuani = Math.min(
    50,
    (ortalamaPuan / 5) * 50 * Math.min(1, degerlendirmeSayisi / 5)
  );
  const aktivitePuani = Math.min(30, aktifIlanSayisi * 3);

  let profilPuani = 0;
  if (adSoyadVar) profilPuani += 5;
  if (telefonVar) profilPuani += 5;
  if (sehirVar) profilPuani += 5;
  if (hakkindaVar) profilPuani += 5;

  return Math.round(degerlendirmePuani + aktivitePuani + profilPuani);
}
