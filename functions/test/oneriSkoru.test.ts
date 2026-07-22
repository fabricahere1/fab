// functions/test/oneriSkoru.test.ts
//
// onerilenPuanHesapla(), index.ts'ten ./onerilenPuan.ts'e davranış
// değiştirilmeden taşındı (guvenSkoru.ts/ilanModerasyon.ts ile aynı
// gerekçe — index.ts'in kendi iç relative importları Node'un native ESM
// test çalıştırıcısında çözülemiyor, bu yüzden doğrudan index.ts'ten
// import edilemiyordu). AYNI 10 golden girdi, Dart tarafında
// (oneri_skoru_test.dart) GERÇEK oneriSkoru() fonksiyonu çalıştırılarak
// üretildi.
//
// ÖNEMLİ — PARITY SINIRI (bug DEĞİL, bilinçli tasarım farkı):
// oneri_skoru.dart'ın kendisi bunu belgeliyor: Dart formülünde "tazelik"
// bileşeni (0.3 ağırlıklı) var, sunucu tarafında (bu dosya) YOK — Algolia'nın
// olusturmaTarihi ikincil sıralama kriteri bu işi görüyor. Ayrıca bu
// fonksiyonun dönüşü ×20 kovalanmış bir TAMSAYI (float değil). Bu yüzden
// burada TAM formül parity'si test EDİLMİYOR — yalnızca ortak olması
// gereken "çekirdek" (Bayesian düzeltme + ilgi bileşeni), Dart tarafında
// tazelik=1.0'a sabitlenip izole edildikten sonra üretilen golden
// "goldenBucket" tamsayılarıyla karşılaştırılıyor.

import { test } from "node:test";
import assert from "node:assert/strict";
import { onerilenPuanHesapla } from "../src/onerilenPuan.ts";

const goldenler: Array<{
  kullaniciPuan: number;
  favoriSayisi: number;
  goruntulenmeSayisi: number;
  resimSayisi: number;
  goldenBucket: number;
}> = [
  { kullaniciPuan: 0.0, favoriSayisi: 0,   goruntulenmeSayisi: 0,    resimSayisi: 0,  goldenBucket: 5 },
  { kullaniciPuan: 5.0, favoriSayisi: 0,   goruntulenmeSayisi: 0,    resimSayisi: 0,  goldenBucket: 9 },
  { kullaniciPuan: 3.0, favoriSayisi: 10,  goruntulenmeSayisi: 100,  resimSayisi: 3,  goldenBucket: 10 },
  { kullaniciPuan: 4.5, favoriSayisi: 49,  goruntulenmeSayisi: 499,  resimSayisi: 5,  goldenBucket: 12 },
  { kullaniciPuan: 2.0, favoriSayisi: 1,   goruntulenmeSayisi: 1,    resimSayisi: 1,  goldenBucket: 7 },
  { kullaniciPuan: 5.0, favoriSayisi: 100, goruntulenmeSayisi: 1000, resimSayisi: 10, goldenBucket: 13 },
  { kullaniciPuan: 1.0, favoriSayisi: 5,   goruntulenmeSayisi: 50,   resimSayisi: 2,  goldenBucket: 8 },
  { kullaniciPuan: 3.5, favoriSayisi: 0,   goruntulenmeSayisi: 500,  resimSayisi: 0,  goldenBucket: 9 },
  { kullaniciPuan: 4.0, favoriSayisi: 25,  goruntulenmeSayisi: 0,    resimSayisi: 4,  goldenBucket: 10 },
  { kullaniciPuan: 0.5, favoriSayisi: 2,   goruntulenmeSayisi: 2,    resimSayisi: 1,  goldenBucket: 6 },
];

for (const g of goldenler) {
  test(
    `puan=${g.kullaniciPuan} favori=${g.favoriSayisi} goruntulenme=${g.goruntulenmeSayisi} `
    + `resim=${g.resimSayisi} → goldenBucket=${g.goldenBucket} (Dart'tan alınan referans)`,
    () => {
      const data = {
        kullaniciPuan: g.kullaniciPuan,
        favoriSayisi: g.favoriSayisi,
        goruntulenmeSayisi: g.goruntulenmeSayisi,
        resimUrller: Array.from({ length: g.resimSayisi }, (_, i) => `r${i}`),
      };

      const sonuc = onerilenPuanHesapla(data);

      assert.equal(sonuc, g.goldenBucket);
    }
  );
}
