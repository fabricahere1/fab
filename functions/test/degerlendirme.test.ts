// functions/test/degerlendirme.test.ts
//
// hesaplaYeniOrtalamaPuan() SAF bir fonksiyon (hiçbir Firestore
// bağımlılığı yok) — node:test ile doğrudan çalıştırılabiliyor.

import { test } from "node:test";
import assert from "node:assert/strict";
import { hesaplaYeniOrtalamaPuan } from "../src/degerlendirme.ts";

test("1) ilk değerlendirme (eskiSayi=0) → yeniSayi=1, guncelPuan=puan\'ın "
  + "kendisi", () => {
  const sonuc = hesaplaYeniOrtalamaPuan({ eskiSayi: 0, eskiOrtalama: 0, puan: 4 });
  assert.equal(sonuc.yeniSayi, 1);
  assert.equal(sonuc.guncelPuan, 4);
});

test("2) mevcut ortalamaya yeni puan ekleme (eskiSayi=2, eskiOrtalama=4.0, "
  + "puan=5) → (4.0*2+5)/3 = 4.333... → 4.3'e yuvarlanır", () => {
  const sonuc = hesaplaYeniOrtalamaPuan({ eskiSayi: 2, eskiOrtalama: 4.0, puan: 5 });
  assert.equal(sonuc.yeniSayi, 3);
  assert.equal(sonuc.guncelPuan, 4.3);
});

test("3) uç değer: puan=1 (en düşük), mevcut ortalamayı aşağı çeker", () => {
  const sonuc = hesaplaYeniOrtalamaPuan({ eskiSayi: 4, eskiOrtalama: 5.0, puan: 1 });
  // (5.0*4+1)/5 = 21/5 = 4.2
  assert.equal(sonuc.yeniSayi, 5);
  assert.equal(sonuc.guncelPuan, 4.2);
});

test("4) uç değer: puan=5 (en yüksek), mevcut ortalamayı yukarı çeker", () => {
  const sonuc = hesaplaYeniOrtalamaPuan({ eskiSayi: 4, eskiOrtalama: 1.0, puan: 5 });
  // (1.0*4+5)/5 = 9/5 = 1.8
  assert.equal(sonuc.yeniSayi, 5);
  assert.equal(sonuc.guncelPuan, 1.8);
});

test("5) yuvarlama davranışı — Math.round(x*10)/10 ile 1 ondalık basamağa "
  + "yuvarlanıyor (eskiSayi=2, eskiOrtalama=3.0, puan=4 → (3*2+4)/3=3.333... "
  + "→ 3.3)", () => {
  const sonuc = hesaplaYeniOrtalamaPuan({ eskiSayi: 2, eskiOrtalama: 3.0, puan: 4 });
  assert.equal(sonuc.yeniSayi, 3);
  assert.equal(sonuc.guncelPuan, 3.3);
});

test("6) yuvarlama davranışı — tam ondalıkta kalan bir değer (eskiSayi=1, "
  + "eskiOrtalama=3.0, puan=4 → (3*1+4)/2=3.5, zaten 1 ondalık basamak) ve "
  + "yuvarlanması gereken bir değer (eskiSayi=6, eskiOrtalama=3.16, puan=3 "
  + "→ (3.16*6+3)/7=3.1371... → 3.1'e yuvarlanır)", () => {
  const sonucTam = hesaplaYeniOrtalamaPuan({ eskiSayi: 1, eskiOrtalama: 3.0, puan: 4 });
  assert.equal(sonucTam.guncelPuan, 3.5);

  const sonucYuvarlanan = hesaplaYeniOrtalamaPuan({ eskiSayi: 6, eskiOrtalama: 3.16, puan: 3 });
  assert.equal(sonucYuvarlanan.yeniSayi, 7);
  assert.equal(sonucYuvarlanan.guncelPuan, 3.1);
});
