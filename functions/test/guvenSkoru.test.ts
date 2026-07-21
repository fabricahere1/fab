// functions/test/guvenSkoru.test.ts
//
// hesaplaGuvenSkoru() SAF bir fonksiyon (hiçbir Firebase/Firestore
// bağımlılığı yok) — bu yüzden emulator olmadan, doğrudan node:test ile
// çalıştırılabiliyor. Node 22+ TypeScript'i doğrudan (transpiler
// olmadan) çalıştırabildiği için ek bir test runner'a gerek yok.
//
// Çalıştırma: node --test test/guvenSkoru.test.ts   (functions/ kökünden)

import { test } from "node:test";
import assert from "node:assert/strict";
import { hesaplaGuvenSkoru, type GuvenSkoruParams } from "../src/guvenSkoru.ts";

const bos: GuvenSkoruParams = {
  ortalamaPuan: 0,
  degerlendirmeSayisi: 0,
  aktifIlanSayisi: 0,
  adSoyadVar: false,
  telefonVar: false,
  sehirVar: false,
  hakkindaVar: false,
};

test("1) hiç geçmişi olmayan yeni kullanıcı → skor 0", () => {
  assert.equal(hesaplaGuvenSkoru(bos), 0);
});

test("2) maksimum değerlendirme (puan:5, sayı:5+) → degerlendirmePuani tam 50 "
  + "(diğer bileşenler 0 iken toplam skor da 50 olmalı)", () => {
  const skor = hesaplaGuvenSkoru({
    ...bos,
    ortalamaPuan: 5,
    degerlendirmeSayisi: 5,
  });
  assert.equal(skor, 50);
});

test("3) az değerlendirme sayısı (sayı:2, puan:5) → min(1, sayı/5) oranı "
  + "devreye girip puan 50'den düşük çıkar (gerçek formül: 5/5*50*min(1,2/5) "
  + "= 50*0.4 = 20)", () => {
  const skor = hesaplaGuvenSkoru({
    ...bos,
    ortalamaPuan: 5,
    degerlendirmeSayisi: 2,
  });
  assert.ok(skor < 50, `beklenen < 50, gelen: ${skor}`);
  assert.equal(skor, 20);
});

test("4) 10+ aktif ilan → aktivitePuani tavana (30) ulaşır, üstüne çıkmaz", () => {
  const skorOnda = hesaplaGuvenSkoru({ ...bos, aktifIlanSayisi: 10 });
  const skorYirmide = hesaplaGuvenSkoru({ ...bos, aktifIlanSayisi: 20 });

  assert.equal(skorOnda, 30);
  assert.equal(skorYirmide, 30); // 20*3=60, ama Math.min(30, ...) tavana çarpar
});

test("5) tüm profil alanları dolu → profilPuani tam 20", () => {
  const skor = hesaplaGuvenSkoru({
    ...bos,
    adSoyadVar: true,
    telefonVar: true,
    sehirVar: true,
    hakkindaVar: true,
  });
  assert.equal(skor, 20);
});

test("6) toplam skor hiçbir girdi kombinasyonunda 100'ü aşmaz (üst sınır)", () => {
  const maksimum = hesaplaGuvenSkoru({
    ortalamaPuan: 5,
    degerlendirmeSayisi: 100, // min(1, sayı/5) tavana vursun diye bilinçli aşırı değer
    aktifIlanSayisi: 100,
    adSoyadVar: true,
    telefonVar: true,
    sehirVar: true,
    hakkindaVar: true,
  });
  assert.ok(maksimum <= 100, `beklenen <= 100, gelen: ${maksimum}`);
  // Formülün gerçek tavanı: 50 (degerlendirme) + 30 (aktivite) + 20 (profil) = 100
  assert.equal(maksimum, 100);
});
