# Genel Sağlık Taraması

Tarih: 2026-07-25 · Kapsam: Client (Flutter), Sunucu (Cloud Functions), Veri (Firestore), Test kapsamı.
Bu, salt-okuma bir tarama raporudur — hiçbir kod değiştirilmedi.

Etiketleme: **Kritik** (çökme/güvenlik/veri kaybı riski) · **Orta** (fonksiyonel ama kusurlu) · **Düşük** (kozmetik/teorik) · **Şüpheli/Doğrulanmadı** (kanıt zayıf, ayrıca bakılmalı).

---

## Bölüm A — Client (Flutter) sağlığı

### A1. GoogleFonts ↔ `assets/google_fonts/` eşleşmesi

`assets/google_fonts/` içindeki dosyalar taranıp kod içindeki her `GoogleFonts.xxx(fontWeight: ...)` çağrısıyla tek tek karşılaştırıldı.

| Font ailesi | Kodda kullanılan ağırlıklar | Klasördeki dosya(lar) | Durum |
|---|---|---|---|
| `poppins` | w800 (3 yerde) | `Poppins-ExtraBold.ttf` | ✅ Eşleşiyor (bu oturumda düzeltildi) |
| `merriweather` | w500 | `Merriweather_24pt-Medium.ttf` | ✅ Eşleşiyor (bu oturumda düzeltildi) |
| `dmSans` | geniş kullanım (w200-w900 arası) | Italic, ExtraLight, Light, Black, Regular, Medium, SemiBold, Bold, ExtraBold | ✅ Tam kapsıyor |
| `manrope` | w400-w700 | Regular, Medium, SemiBold, Bold | ✅ Eşleşiyor |
| `inter` | w400, w600, w700 | Regular, SemiBold, Bold | ✅ Eşleşiyor |
| `playfairDisplay` | w500, w700 | Medium, Bold (+ Italic, BoldItalic) | ✅ Eşleşiyor |
| `raleway` | w500, w700 | Medium, Bold | ✅ Eşleşiyor |
| `notoSans` | w400, w500 | Regular, Medium | ✅ Eşleşiyor |
| `urbanist` | w700 | Bold | ✅ Eşleşiyor |
| `nunito` | w600 | SemiBold | ✅ Eşleşiyor |
| `bebasNeue` | varsayılan (fontWeight verilmemiş → w400) | Regular | ✅ Eşleşiyor |
| `dmSerifDisplay` | varsayılan (fontWeight verilmemiş → w400) | Regular | ✅ Eşleşiyor |

**Sonuç: Bilinen 2 çökme riski (Poppins w700, Merriweather w400) bu oturumda düzeltildi. Taramada BAŞKA eksik ağırlık bulunmadı — tüm 12 font ailesi, kullanılan her ağırlık için diskte karşılığı olan bir dosyaya sahip.** (Düşük risk kalmadı.)

### A2. Dispose() denetimi

`lib/` genelinde `AnimationController`, `TextEditingController`, `ScrollController`, `StreamSubscription`, `TabController` bildirimleri (61 occurrence / 29 dosya) tek tek `dispose()`/`.cancel()`/`.close()` çağrılarıyla eşleştirildi (30 dosya, ~55 class-level field tarandı).

**Sonuç: 0 eksik bulundu.** Tüm class-level controller/subscription alanları kendi `State.dispose()` metodunda temizleniyor (bkz. `banner_service.dart`, `fcm_service.dart` — 4 stream, `app_router.dart` — 3 stream `.close()` ile, `ilan_overlay_widget.dart` — 6 AnimationController, vb.). `ayarlar_screen.dart` içindeki bazı controller'lar (`ctrl`, `sifreCtrl`, `kodCtrl`) dialog metodları içinde **local** oluşturuluyor — class field'ı olmadıkları için dispose zorunluluğu yok, kapsam dışı bırakıldı.

*Not:* BACKLOG.md'de "C7 — hiç bakılmamış" olarak işaretliydi; bu tarama ile **C7 artık doğrulanmış: temiz.**

### A3. `flutter analyze` — tam çıktı

```
Analyzing iste_v3...
   info - Unnecessary use of multiple underscores - lib\features\home\presentation\sana_ozel_screen.dart:1034:34 - unnecessary_underscores
   info - 'appleProvider' is deprecated and shouldn't be used. Use providerApple instead. - lib\main.dart:49:5 - deprecated_member_use
2 issues found.
```

İkisi de **Düşük** — biri kozmetik lint (`_`), diğeri gelecekte kaldırılacak bir API kullanımı (henüz çalışıyor, acil değil). Hiçbir `error` yok.

---

## Bölüm B — Sunucu (Cloud Functions) sağlığı

### B1. Sessizce başarısız olan kritik işlemler

`functions/src/index.ts`'teki tüm 24 `catch` bloğu tek tek okundu (`degerlendirme.ts`, `guvenSkoru.ts`, `ilanModerasyon.ts`, `onerilenPuan.ts`'de hiç catch yok — saf fonksiyonlar).

| Konum | Risk | Bulgu |
|---|---|---|
| `index.ts:317-326` (`ilanModerasyonu`, onay bildirimi) | **Kritik** | `Promise.all([bildirimGonder(...), db.collection("bildirimler").add(...)])` TEK bir try içinde. FCM push'u başarısız olursa (örn. bayat/geçersiz token — yaygın bir senaryo), `Promise.all` reddedilir ve **Firestore'a in-app bildirim dokümanı da hiç yazılmaz** — kullanıcı ilanının onaylandığını HİÇBİR kanaldan öğrenemez. Sadece `console.warn`, retry/ayrım yok. Doğrulandı, kod okunarak teyit edildi (satır 318-326). |
| `index.ts:351-353` (`ilanModerasyonu`, Algolia ana index) | Orta | Algolia yazımı başarısız olursa `ilanRef.update({algoliaHata:true})` denemesi de kendi `.catch(()=>{})`'i ile sessizce yutuluyor — hata bayrağı bile Firestore'a düşmeyebilir, ilan aramada hiç görünmez ama kimse fark etmez. |
| `index.ts:496-498` (`ilanGuncellendi`, onerilenPuan) | Orta | `onerilenPuan` Algolia'ya yazılamazsa sıralama algoritması sessizce eski/yanlış puanla çalışmaya devam eder. |
| `index.ts:806-810` (`degerlendirmePuanGuncelle`, kullaniciPuan fan-out) | Orta | Satıcının aktif ilanlarındaki denormalize `kullaniciPuan` güncellenemezse, düzenli bir yeniden-senkron mekanizması yoksa kalıcı olarak eski puan gösterilebilir. |
| `index.ts:928-931` (`hesapSilSunucu`) | Düşük (doğru) | Hata yutulmuyor — `console.error` + `HttpsError("internal", ...)` düzgün fırlatılıyor. |
| Algolia silme/pasifleştirme blokları (482-486, 524-556) | Düşük | Yalnızca arama index tutarlılığı, kullanıcıya doğrudan zarar yok. |

**Özet: 1 Kritik, 3 Orta bulgu.** En acil olanı `ilanModerasyonu`'daki bildirim kaybı (satır 326) — bu, launch sonrası "ilanım onaylandı ama haber alamadım" şikayetlerinin muhtemel bir kaynağı olabilir.

### B2. `npx tsc --noEmit`

Çıktı **boş** — 0 tip hatası.

### B3. `npm test` (functions/)

```
tests 27
pass 27
fail 0
cancelled 0
skipped 0
```

Tüm testler geçiyor (`degerlendirme.test.ts`, `guvenSkoru.test.ts`, `ilanModerasyon.test.ts`, `oneriSkoru.test.ts`).

---

## Bölüm C — Veri (Firestore) tutarlılığı

### C1. BACKLOG.md açık maddeleri — geçerlilik teyidi

| Madde | Doğrulama |
|---|---|
| **`hesapSilSunucu` / `degerlendirmeler` temizlenmiyor** | `index.ts:869-932` okundu — hesap silme akışında `degerlendirmeler` koleksiyonuna dokunulmuyor, backlog'daki teşhis hâlâ geçerli. **Hâlâ açık.** |
| **`degerlendirmePuanGuncelle` yalnızca `onDocumentCreated`** | `index.ts:770-810` teyit edildi, silinme (`onDocumentDeleted`) için fan-out yok. **Hâlâ açık**, yukarıdaki maddeyle bağlantılı ön koşul. |
| **App Check (`AndroidProvider.debug`)** | Kod tarafında değişmemiş, launch sonrası kontrol maddesi olarak duruyor. **Hâlâ açık**, kapsam dışı (deploy/prod doğrulaması gerektiriyor, bu taramada test edilemedi). |
| **Test kapsamı düşük (`sohbet_model_test.dart` ile sınırlı)** | **GÜNCEL DEĞİL** — bu not eskimiş. Şu an `test/` altında 8 dosya, 56 test var (Bölüm D). Backlog'un bu maddesi güncellenmeli. |
| **Orphan dosya/sınıf taraması (C6, proje geneli)** | Bu tur kapsamında yeniden taranmadı. **Hâlâ "İncelenmedi".** |
| **go_router standardizasyonu** | Bu tur kapsamında yeniden taranmadı. **Hâlâ açık.** |
| **`oneriSkoru`/`onerilenPuan` parity notu** | Bug değil, bilinçli fark — bu turda dokunulmadı, hâlâ geçerli not. |
| **B3/B4/C5/C7/D1/D2/E1-E3/F1/F2 (hiç bakılmamış)** | C7 (dispose) bu turda taranıp **temiz bulundu** (A2), backlog'dan çıkarılabilir. Diğerleri (B3, B4, C5, D1, D2, E1-E3, F1, F2) bu turun kapsamı dışında kaldı, hâlâ "İncelenmedi". |

### C2. Orphan veri riskleri — güncel durum teyidi

- **Storage temizliği:** Bu turda ayrıca doğrulanmadı (kapsam dışı bırakıldı, zaman kısıtı) — **Şüpheli/Doğrulanmadı**, önceki bulgunun hâlâ geçerli olduğu varsayılıyor ama bu oturumda kod okunarak yeniden teyit edilmedi.
- **Değerlendirmeler fan-out (silme):** Yukarıda (C1) `index.ts:869-932` ve `770-810` okunarak **doğrulandı — hâlâ aynı durumda, düzeltme yapılmamış.**

---

## Bölüm D — Test kapsamı özeti

**`flutter test`:**
```
56 tests, 56 passed (1 kasıtlı skip: kullanici_repository_test.dart — 
"kendi kendini takip etme" senaryosu, rules seviyesinde test edildiği için client'ta kapsam dışı bırakılmış)
```
Test dosyaları: `sana_ozel_providers_test.dart`, `ilan_model_test.dart`, `sohbet_model_test.dart`, `mesajlar_screen_test.dart`, `kullanici_model_test.dart`, `kullanici_repository_test.dart`, `oneri_skoru_test.dart`, `widget_test.dart` (placeholder).

**`npm test` (functions/):**
```
27 tests, 27 passed, 0 skipped
```

**Toplam: 83 test, 83 geçti, 1 kasıtlı skip.**

---

## Bölüm E — Genel proje istatistikleri

| Metrik | Değer |
|---|---|
| Toplam Dart dosyası (`lib/`) | 133 |
| Toplam kod satırı (`lib/`) | 45.814 |
| Toplam kod satırı (`functions/src/`) | 1.290 (5 dosya) |
| Toplam Cloud Functions (export edilen) | 16 |
| Son 7 gün içindeki commit sayısı | 27 |

---

## Sonuç: Launch öncesi acilen kapatılması gereken YENİ bir sorun var mı?

**Evet — 1 tane, bugüne kadar bulunanların dışında yeni bir bulgu:**

1. **[Kritik]** `functions/src/index.ts:317-326` — `ilanModerasyonu` fonksiyonunda ilan onay bildirimi (push + in-app), `Promise.all` ile tek bir try/catch'e sarılmış. FCM push başarısız olursa (yaygın bir senaryo — geçersiz/bayat token), in-app Firestore bildirimi de **hiç yazılmıyor**, kullanıcı ilanının onaylandığından habersiz kalıyor. Öneri: iki `await`'i ayrı try/catch'lere ayırıp, en azından Firestore bildirim yazımının push hatasından bağımsız çalışmasını sağlamak.

Diğer bulgular (Poppins/Merriweather font, dispose taraması, Algolia sessiz hatalar) ya bu oturumda zaten düzeltildi ya da Orta/Düşük öncelikli, launch'ı engellemeyecek nitelikte — BACKLOG.md'ye eklenmeye uygun.

**Öncelik sırası (yeni bulgular):**
1. `ilanModerasyonu` bildirim kaybı (Kritik) — launch öncesi bakılmalı.
2. Algolia `algoliaHata` flag'inin de sessizce kaybolabilmesi (Orta) — launch sonrası ilk hafta.
3. `onerilenPuan`/`kullaniciPuan` senkron hatalarının sessiz kalması (Orta) — launch sonrası ilk hafta.
