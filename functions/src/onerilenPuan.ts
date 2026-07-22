// functions/src/onerilenPuan.ts
//
// onerilenPuanHesapla()'nın index.ts'ten davranış değiştirilmeden BİREBİR
// taşınmış hali — index.ts'in kendi iç relative importları (ör. "./guvenSkoru",
// uzantısız) Node'un native ESM test çalıştırıcısında çözülemediği için,
// bu fonksiyonu doğrudan index.ts'ten import edip test etmek mümkün değildi
// (guvenSkoru.ts/ilanModerasyon.ts ile AYNI gerekçe, aynı çözüm).

export function onerilenPuanHesapla(data: FirebaseFirestore.DocumentData): number {
  const n = 3;
  const puan        = (data.kullaniciPuan ?? 0) as number;
  const duzeltilmis = (puan * n + 4.0 * 5) / (n + 5); // Bayesian

  const favori      = (data.favoriSayisi       ?? 0) as number;
  const goruntuleme = (data.goruntulenmeSayisi ?? 0) as number;
  const resimSayisi = ((data.resimUrller as string[] | undefined) ?? []).length;

  const favoriPay       = Math.min(Math.log(favori + 1)      / Math.log(50),  1.0);
  const goruntulenmePay = Math.min(Math.log(goruntuleme + 1) / Math.log(500), 1.0);
  const resimPay        = Math.min(resimSayisi / 5, 1.0);
  // Resim = formüldeki tek "emek" sinyali; manipülasyona en kapalı bileşen.
  const ilgi = 0.6 * favoriPay + 0.25 * goruntulenmePay + 0.15 * resimPay;

  // 0-14 arası kova (×20): aynı kovadakiler arasında Algolia ikincil
  // sırası (olusturmaTarihi desc) devreye girer.
  return Math.round((0.5 * (duzeltilmis / 5) + 0.2 * ilgi) * 20);
}
