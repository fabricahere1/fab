# İSTE — Launch Öncesi Kapsamlı Sağlık Taraması

**Tarih:** 2026-08-08
**Yöntem:** 3 paralel agent (Güvenlik+Veri Bütünlüğü / Kod Kalitesi+Tutarlılık / Cihazda Canlı Fonksiyonel Test), önceki denetim raporları (SILME_TARAMA.md, ALGOLIA_DENETIM.md, ETKILESIM_DENETIMI.md) teyit edilerek güncellendi.
**Kapsam:** Sadece bulgu/raporlama — bu turda kod değişikliği yapılmadı.

---

## ÖNCELİK SIRALI BİRLEŞTİRİLMİŞ BULGU LİSTESİ

### 🔴 Kritik (launch'ı engelleyecek nitelikte hiçbir bulgu yok)
Hiçbir agent kritik/launch-engelleyici bir güvenlik açığı veya veri bütünlüğü sorunu bulmadı. Firestore rules ve Cloud Functions genel olarak olgun ve iyi savunmalı.

### 🟠 Orta (launch sonrası ilk sırada ele alınmalı)

1. **`.limit()` eksik sorgular — "İlanlarım" regresyonunun tekrarı riski.** `sohbetlerStream` ve `toplamOkunmamisStream` (`lib/features/mesajlar/data/mesaj_repository.dart:181-189, 304-317`), `favorilerStream` (`lib/features/ilanlar/data/ilan_repository.dart:632-641`), `takipEdilenTarihleriStream` (`lib/features/profil/data/kullanici_repository.dart:236-244`) — hiçbirinde `.limit()` yok. Kullanıcı aktif mesajlaştıkça/favori ekledikçe sınırsız büyüyecek, maliyet ve performans riski. En kritik ikisi: sohbet listesi ve okunmamış-mesaj sayacı (her snapshot'ta TÜM sohbetleri okuyor).
2. **Hesap silmede Storage dosyaları temizlenmiyor.** `hesapSilSunucu` (`functions/src/index.ts:855-930`) profil fotoğrafı ve ilan resimlerini Storage'dan silmiyor. KVKK/GDPR açısından risk: kullanıcı hesabını silse de görselleri herkese açık URL'de kalmaya devam ediyor.
3. **Hesap silmede `değerlendirmeler` koleksiyonu temizlenmiyor.** Bilinen ve BACKLOG.md'de kayıtlı, kasıtlı ertelenmiş (fan-out gerektiriyor). Silinen kullanıcının verdiği/aldığı değerlendirmeler artık var olmayan bir uid'e işaret ederek kalıcı kalıyor.
4. **`iletisimGonder` Cloud Function: rate-limit yok + HTML injection.** (`functions/src/index.ts:833-844`) Kimlik doğrulanmış herhangi bir kullanıcı sınırsız e-posta gönderebilir (spam/mail-bombing riski); `konu`/`gonderenAd`/`mesaj` escape edilmeden e-posta HTML gövdesine enjekte ediliyor.
5. **İlan silme sessiz hata verebiliyor.** `profil_screen.dart:721` → `IlanIslemleriNotifier.sil()` (`lib/features/ilanlar/.../ilan_provider.dart:691-696`) try/catch içermiyor; Firestore silme başarısız olursa kullanıcıya bildirim yok.
6. **Favori kalp butonu davranışı belirsiz (giriş yapılmamış durumda).** Cihaz testinde: kalp ikonuna dokunulduğunda ne giriş gate'i çıktı ne görsel geri bildirim oldu, logcat'te de çıktı yoktu. Gerçek hesapla ayrıca doğrulanmalı — ayrıca favori toggle genel olarak (`favoriler_screen`, `ilan_detay_screen`, `swipe_karti`, `ilan_karti`) fire-and-forget, hata durumunda sessizce state geri alınıyor, snackbar yok.

### 🟡 Düşük (launch'ı engellemez, temizlik backlog'una eklenebilir)

7. **DRY ihlalleri (memory backlog'unda zaten kayıtlı, bu turda yeniden teyit edildi):**
   - Göreli zaman formatlama: 2 dosya (`mesajlar_screen.dart`, `bildirimler_screen.dart`) ayrı fonksiyonlar.
   - Avatar baş harfi mantığı: 4 dosya, merkezi widget (`avatar_widget.dart`) var ama kullanılmıyor.
   - Resim URL fallback: 6 dosyada elle tekrarlanmış, model'de merkezi getter olmasına rağmen.
   - **Güven skoru renk eşiği** (`>=80/>=60/>=40`): `kullanici_profil_screen.dart:247-250` ve `profil_screen.dart:377-380` birebir kopya — ikinci kez teyit edildi.
   - Fiyat formatlama: 9 dosyada potansiyel duplike (elle örnekleme ile doğrulanmalı).
8. **`catchError((_) {})` — sessiz hata yutan 5 nokta:** `bildirimler_screen.dart:55`, `mesaj_provider.dart:340,413`, `ilan_repository.dart:395,398`. Bazıları best-effort (dosya silme) olarak kabul edilebilir ama `mesaj_provider.dart`/`bildirimler_screen.dart` gözden geçirilmeli.
9. **`guvenSkoruHesapla` scheduled function** — kullanıcı sayısı büyürse tek `batch.commit()` 500-yazma limitini aşıp hata verebilir. Şimdilik düşük risk, gelecekte zamanlayıcı bomba.
10. **`takipler` koleksiyonu herkes tarafından okunabilir** (`firestore.rules:491-499`) — kod içinde yorumla belgelenmiş bilinçli tasarım kararı, gizlilik ihlali değil ama not edilmeye değer.
11. Sohbeti sil/gizle akışı ve ilan formu resim ekleme hata yönetimi bu turda tam doğrulanamadı — kod tekrar okunmalı.

### ✅ Doğrulanan sağlam noktalar

- Firestore rules uçtan uca olgun: owner-check, rate-limit, sayaç manipülasyon koruması, tek-taraflı işlem taklidi koruması hepsi mevcut. "if true" tarzı gevşek kural yok.
- Cloud Functions'ın büyük çoğunluğunda try/catch, input validation, dar admin-SDK kapsamı mevcut.
- Önceki raporun en ciddi 3 bulgusu (Engelle/Takip/Şikayet'te sessiz hata) **düzeltilmiş** — artık hepsi `Future<bool>` dönüp `AppSnackBar` ile kullanıcıya bildirim veriyor.
- `favoriSayisi` sayaç drift bug'ı (SILME_TARAMA.md'de bulunmuştu) düzeltilmiş.
- Hesap silmenin ana akışı (kullanıcı, ilanlar, favoriler, bildirimler, görüntülenmeler, takipler, sohbetler+mesajlar, Auth kaydı) doğru ve eksiksiz — sadece 2. ve 3. maddedeki istisnalar var.
- `flutter analyze`: 2 info-seviye uyarı (kritik değil), `flutter test`: 56 test, 0 başarısız.
- Symbols.* (material_symbols_icons) kullanımı 7 dosyada var ama tamamı statik/const referans — release'de görünmeme riski düşük (cihazda görsel teyit önerilir).
- TODO/FIXME/XXX/HACK yorumu projede hiç yok.
- Karşılama ekranı 3 buton, tanıtım turu dialogu, arama, arka plan/ön plan geçişinde state koruma — cihazda test edilebilen kısımlar sorunsuz çalıştı, çökme gözlenmedi.

---

## AGENT 1 — Güvenlik + Veri Bütünlüğü (tam rapor)

### firestore.rules
| Koleksiyon | Durum | Not |
|---|---|---|
| kullanicilar | ✅ | owner-only update, sayaç/rozet korunuyor |
| ilanlar | ✅ | list limit≤100, create 30sn rate-limit, moderasyon alanları client'tan enjekte edilemiyor |
| sohbetler | ✅ | katılımcı-only, işlem adımı beyaz-liste + doğrulama |
| mesajlar (alt-koleksiyon) | ✅ | katılımcı+engelleme+1sn hız sınırı kontrolü |
| favoriler/goruntulenmeler | ✅ | doc-ID kilitli, 2sn cooldown |
| degerlendirmeler | ✅ | gerçek sohbet ilişkisi + teslim şartı + tekrar engeli |
| bildirimler | ✅ | alıcı doğrulaması |
| sikayetler | ✅ | gizli (get/list:false), 15sn cooldown |
| takipler | ⚠️ | herkes okuyabilir — kasıtlı, belgelenmiş |
| ayarlar/trendler | ✅ | read-only |

### Cloud Functions (15 export, `functions/src/index.ts`)
Genel olarak try/catch, input validation, dar admin-SDK kapsamı mevcut. İstisnalar: `iletisimGonder` (rate-limit yok, HTML injection — bkz. öncelik listesi #4), `guvenSkoruHesapla` (batch limit riski — #9), `algoliaTopluAktar` (hardcoded admin e-posta whitelist, kırılgan ama admin-only olduğu için düşük risk).

### StreamProvider/FutureProvider `.limit()` taraması
4 sorguda eksik: `sohbetlerStream`, `toplamOkunmamisStream`, `favorilerStream`, `takipEdilenTarihleriStream` (bkz. öncelik listesi #1). Ana besleme sorguları, ilanlarım, takipçi listeleri, bildirimler zaten `.limit()` içeriyor.

### Client-side input sanitization
Flutter'da klasik XSS riski yapısal olarak yok (Text widget HTML yorumlamaz). Tek gerçek risk yüzeyi: `iletisimGonder` Cloud Function'ının e-posta HTML gövdesi. Algolia sorguları parametrik işlendiği için injection riski yok.

### Hesap silme akışı — kapsam netleştirmesi
Temizlenenler: kullanıcı dokümanı+bekleyen değerlendirmeler, ilanlar (+Algolia dolaylı), favoriler (+sayaç düzeltmesi düzeltilmiş), bildirimler, görüntülenmeler, takipler (iki yön), sohbetler+mesajlar (gerçek silme), Auth kaydı.
Temizlenmeyenler: **değerlendirmeler koleksiyonu**, **Storage dosyaları** (profil fotoğrafı + ilan resimleri), kozmetik kalıntılar (başkalarının `engellenenler` dizisindeki eski uid, karşı tarafın bildirimleri).

---

## AGENT 2 — Kod Kalitesi + Tutarlılık (tam rapor)

### onTap/onPressed taraması
- Tamamen boş handler: yalnızca 1 yerde (`neden_iste_bar.dart:78`), kasıtlı ve yorumla belgelenmiş.
- Engelle/Takip/Şikayet: **önceki raporun bulguları düzeltilmiş**, artık hepsi hata durumunda `AppSnackBar.hata` gösteriyor.
- İlan silme (`profil_screen.dart:721`): hâlâ try/catch yok — bkz. öncelik listesi #5.
- `catchError((_) {})`: 5 nokta — bkz. öncelik listesi #8.
- Favori toggle: fire-and-forget, sessiz — bkz. öncelik listesi #6.
- Sohbet gizle/sil ve ilan formu resim ekleme: bu turda doğrulanamadı, tekrar bakılmalı.

### Symbols.* kullanımı
7 dosya, tamamı statik/const referans (switch-case veya const liste literalleri): `ilanlar_screen.dart`, `sana_ozel_screen.dart`, `gelenler_filtre_ekrani.dart`, `ilan_karti.dart`, `alisveris_rehberi_bolum.dart`, `beden_donusturucu_bolum.dart`, `tasiyici_ipuclari_bolum.dart`. Tree-shake riski düşük (dinamik/computed kullanım yok), yine de cihazda görsel teyit önerilir.

### DRY backlog teyidi
Bkz. öncelik listesi #7 — 4/5 madde hâlâ duplike, güven skoru renk eşiği ikinci kez teyit edildi.

### flutter analyze / flutter test
- `analyze`: 2 info uyarısı (`unnecessary_underscores`, `deprecated_member_use: appleProvider`) — hata yok.
- `test`: 56 test, 0 başarısız (3 kasıtlı skip).

### TODO/FIXME/XXX/HACK
Proje genelinde sıfır sonuç (grep'in yakaladığı beden kodları/telefon placeholder'ları yanlış-pozitif).

---

## AGENT 3 — Cihazda Canlı Fonksiyonel Test (tam rapor)

**Ortam:** CPH2581, Android 16, cihaz id 95e6a66b, **debug build** kullanıldı (release build denenmedi). Gradle derlemesi ~2 dk sürdü, imza uyuşmazlığı nedeniyle eski sürüm kaldırılıp yeniden kuruldu (normal davranış). Çökme gözlenmedi.

**Kısıt:** Gerçek kimlik bilgisi (e-posta doğrulama kodu, Google OAuth, SMS kodu) sağlanamadığı için giriş yapılamadı; giriş-sonrası akışların (6-18) büyük kısmı test edilemedi.

| # | Akış | Sonuç |
|---|---|---|
| 1 | Email kayıt/doğrulama/giriş | ⚠️ MANUEL GEREKLİ |
| 2 | Google giriş/çıkış/tekrar giriş | ⚠️ MANUEL GEREKLİ |
| 3 | Telefon/SMS giriş | ⚠️ MANUEL GEREKLİ |
| 4 | Karşılama ekranı 3 buton | ✅ Katıl/Giriş Yap/Atla doğru render, Atla ve Giriş Yap test edildi |
| 5 | Tanıtım turu dialogu | ✅ Görünüyor, "Geç" test edildi, sorunsuz |
| 6 | İlan oluştur/yayınla | ❌ Giriş gate'i engelliyor |
| 7 | İlan düzenle/sil | ❌ Giriş gerekiyor |
| 8 | Mesaj/resim gönder, sohbet sil/gizle | ❌ Giriş gerekiyor |
| 9 | Favori ekle/çıkar | ⚠️ Davranış belirsiz — bkz. öncelik listesi #6 |
| 10 | Engelle/kaldır | ❌ Giriş gerekiyor |
| 11 | Şikayet gönder | ❌ Giriş gerekiyor |
| 12 | Takip et/bırak | ❌ Giriş gerekiyor |
| 13 | Arama + filtre | ✅ Kısmen — arama giriş gerektirmeden çalıştı, 7 sonuç geldi, detay açıldı; sıralama filtreleri test edilmedi |
| 14 | Bildirimler, tümünü oku | ⚠️ Kısmi — zil tepki veriyor, giriş gate'i açılıyor, "tümünü oku" test edilemedi |
| 15 | Profil düzenle | ❌ Giriş gerekiyor |
| 16 | Telefon numarası değiştir | ⚠️ MANUEL GEREKLİ |
| 17 | Hesap sil (test hesabı) | ❌ Test hesabı oluşturulamadı |
| 18 | Arka plan/ön plan state | ✅ BAŞARILI — HOME ile arka plana alıp geri getirmede state korunuyor. (Back tuşuyla tam kapanma sonrası onboarding'e dönmesi beklenen/normal davranış) |
| 19 | İnternet kesme | ⚠️ MANUEL GEREKLİ |
| 20 | Nav bar gezinme | ⚠️ Kısmi — Ana sayfa/arama sorunsuz, diğer sekmeler zaman kısıtından test edilmedi |

Ekran görüntüleri: agent'ın scratchpad dizininde (`01_launch.png` … `19_iletisim.png`).

**Öneri:** Kapsamlı cihaz testi için gerçek bir test hesabı (email+şifre veya SMS doğrulamalı test numarası) sağlanırsa akış 6-18'in kalanı tamamlanabilir.

---

## SONUÇ

Launch'ı engelleyen kritik bir bulgu yok. Launch sonrası ilk sprint için öncelik: (1) sohbet/okunmamış-sayaç sorgularına `.limit()` eklemek, (2) hesap silmede Storage temizliği, (3) `iletisimGonder`'a rate-limit + HTML escape, (4) ilan silmede try/catch + kullanıcı bildirimi, (5) favori kalp butonu davranışının gerçek hesapla doğrulanması. Giriş gerektiren akışların (kayıt, Google, SMS, hesap silme, ilan/mesaj/favori/takip/engelleme CRUD'ları) gerçek bir test hesabıyla manuel olarak doğrulanması launch öncesi son adım olarak öneriliyor.
