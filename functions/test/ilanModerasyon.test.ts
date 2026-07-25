// functions/test/ilanModerasyon.test.ts
//
// yenidenDenenmeliMiHesapla() SAF bir fonksiyon — Firestore event
// nesnesine bağımlı değil, node:test ile doğrudan çalıştırılabiliyor.
//
// Çalıştırma: node --test test/ilanModerasyon.test.ts   (functions/ kökünden)

import { test } from "node:test";
import assert from "node:assert/strict";
import { yenidenDenenmeliMiHesapla, ikiliBildirimGonder } from "../src/ilanModerasyon.ts";

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

// ── ikiliBildirimGonder ────────────────────────────────────────────────
//
// Regresyon testi: ilanModerasyonu'nda push (admin.messaging()) ve
// Firestore yazımı Promise.allSettled ile birbirinden bağımsız
// çalışmalı — push hata fırlatsa bile Firestore yazımı GERÇEKTEN
// tamamlanmalı (önceki Promise.all deseninde, push reddedilince
// Firestore yazımı da hiç yapılmamış gibi sayılıyor, sessizce
// kayboluyordu).

test("6) ikiliBildirimGonder: push reddedilse bile Firestore yazımı "
  + "GERÇEKTEN çalışır ve tamamlanır", async () => {
  let firestoreYazildiMi = false;
  const loglar: unknown[][] = [];

  const sonuc = await ikiliBildirimGonder(
    () => Promise.reject(new Error("push token geçersiz")),
    async () => {
      // Gerçek bir Firestore yazma işlemini simüle etmek için küçük bir
      // async gecikme — "await edildi ve tamamlandı" olduğunu kanıtlar.
      await new Promise((resolve) => setTimeout(resolve, 5));
      firestoreYazildiMi = true;
      return { id: "sahte-doc-id" };
    },
    (mesaj, hata) => loglar.push([mesaj, hata])
  );

  assert.equal(firestoreYazildiMi, true, "Firestore yazımı push hatasından etkilenmemeli");
  assert.equal(sonuc.pushBasarili, false);
  assert.equal(sonuc.firestoreBasarili, true);
  assert.equal(loglar.length, 1, "yalnızca push hatası loglanmalı, firestore için loglanmamalı");
  assert.match(String(loglar[0][0]), /push/);
});

test("7) ikiliBildirimGonder: Firestore reddedilse bile push GERÇEKTEN "
  + "çalışır ve tamamlanır (simetrik senaryo)", async () => {
  let pushGonderildiMi = false;

  const sonuc = await ikiliBildirimGonder(
    async () => {
      pushGonderildiMi = true;
      return { messageId: "sahte-msg-id" };
    },
    () => Promise.reject(new Error("firestore izin hatası")),
    () => {}
  );

  assert.equal(pushGonderildiMi, true, "Push, firestore hatasından etkilenmemeli");
  assert.equal(sonuc.pushBasarili, true);
  assert.equal(sonuc.firestoreBasarili, false);
});

test("8) ikiliBildirimGonder: ikisi de başarılı olursa hiç loglama "
  + "yapılmaz", async () => {
  const loglar: unknown[][] = [];

  const sonuc = await ikiliBildirimGonder(
    async () => "ok",
    async () => "ok",
    (mesaj, hata) => loglar.push([mesaj, hata])
  );

  assert.equal(sonuc.pushBasarili, true);
  assert.equal(sonuc.firestoreBasarili, true);
  assert.equal(loglar.length, 0);
});
