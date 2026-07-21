// functions/test/ilanModerasyon.test.ts
//
// yenidenDenenmeliMiHesapla() SAF bir fonksiyon — Firestore event
// nesnesine bağımlı değil, node:test ile doğrudan çalıştırılabiliyor.
//
// Çalıştırma: node --test test/ilanModerasyon.test.ts   (functions/ kökünden)

import { test } from "node:test";
import assert from "node:assert/strict";
import { yenidenDenenmeliMiHesapla } from "../src/ilanModerasyon.ts";

test("1) once.durum='reddedildi', sonra.durum='onayBekliyor' → true "
  + "(orijinal, her zaman çalışan senaryo)", () => {
  const sonuc = yenidenDenenmeliMiHesapla(
    { durum: "reddedildi" },
    { durum: "onayBekliyor" }
  );
  assert.equal(sonuc, true);
});

test("2) once.aktif=false, sonra.durum='onayBekliyor' → true — dün "
  + "eklenen kilitlenme düzeltmesi, EN KRİTİK regresyon testi", () => {
  const sonuc = yenidenDenenmeliMiHesapla(
    { durum: "yayinda", aktif: false },
    { durum: "onayBekliyor" }
  );
  assert.equal(sonuc, true);
});

test("3) once.durum='yayinda' (ne 'reddedildi' ne 'aktif:false' geçmişi) "
  + "→ false — gerçek kod yalnızca bu iki spesifik geçmişi tetikleyici "
  + "sayıyor, salt bir durum değişikliğini değil", () => {
  const sonuc = yenidenDenenmeliMiHesapla(
    { durum: "yayinda" },
    { durum: "onayBekliyor" }
  );
  assert.equal(sonuc, false);
});

test("4) once.durum='onayBekliyor', sonra.durum='onayBekliyor' (hiç "
  + "değişiklik yok) → false — gereksiz yeniden deneme olmamalı", () => {
  const sonuc = yenidenDenenmeliMiHesapla(
    { durum: "onayBekliyor" },
    { durum: "onayBekliyor" }
  );
  assert.equal(sonuc, false);
});

test("5) once.aktif=true, sonra.durum='onayBekliyor' → false — aktif "
  + "zaten true'ydu, dünkü düzeltmenin kapsamadığı durum", () => {
  const sonuc = yenidenDenenmeliMiHesapla(
    { durum: "yayinda", aktif: true },
    { durum: "onayBekliyor" }
  );
  assert.equal(sonuc, false);
});
