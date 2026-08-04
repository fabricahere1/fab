# İste Uygulaması — Üretim Öncesi Denetim Raporu

Tarih: 2026-08-02
Çalışma dizini: `C:\src\iste_v3`
Yöntem: Salt-okuma statik denetim. `flutter analyze` ve `flutter test` çalıştırıldı, hiçbir dosya değiştirilmedi.

---

## BÖLÜM A — İzinler ve Manifest

`android/app/src/main/AndroidManifest.xml` içindeki tüm `<uses-permission>` satırları:

| İzin | Kod Tabanında Karşılığı | Dosya:Satır (kanıt) |
|---|---|---|
| `INTERNET` | Firebase/Firestore/HTTP her yerde kullanılıyor | (genel) |
| `CAMERA` | `image_picker` paketi (kamera ile fotoğraf çekme) | `lib/features/ilanlar/presentation/ilan_form_screen.dart:13,70`, `lib/features/mesajlar/presentation/sohbet_screen.dart:4,781` |
| `READ_MEDIA_IMAGES` | `image_picker` (galeriden görsel seçme, Android 13+) | aynı yukarıdaki dosyalar |
| `READ_EXTERNAL_STORAGE` (maxSdk 32) | `image_picker` + `path_provider` eski Android sürümleri için | `lib/features/ilanlar/data/ilan_repository.dart:8`, `ilan_form_screen.dart:14` |
| `WRITE_EXTERNAL_STORAGE` (maxSdk 28) | `path_provider` ile geçici dosya işlemleri (eski Android) | aynı |

**Bulgu:** Tüm izinler kodda karşılığını buluyor. Konum (`ACCESS_FINE_LOCATION` vb.) izni manifest'te YOK ve kodda da `Geolocator`/`location` paketi kullanımı bulunamadı — şehir/ülke bilgisi kullanıcı tarafından elle giriliyor gibi görünüyor (bkz. Bölüm B). Bildirim izni (`POST_NOTIFICATIONS`, Android 13+) manifest'te açıkça görünmüyor; Firebase Messaging plugin'i bunu genelde kendi manifest merge'i ile ekler — **Şüpheli/Doğrulanmadı**, derlenmiş APK manifestinde (merged manifest) doğrulanmalı.

| Bulgu | Dosya:Satır | Önem | Açıklama |
|---|---|---|---|
| Kullanılmayan izin yok | — | Düşük | Tüm izinler kodda karşılığını buluyor, fazlalık izin bulunamadı |
| POST_NOTIFICATIONS manifestte açık değil | AndroidManifest.xml | Düşük | FCM plugin'i genelde otomatik ekler, merged manifest kontrolü önerilir — Şüpheli/Doğrulanmadı |

---

## BÖLÜM B — Gizlilik Politikası ve Veri Toplama Tutarlılığı

Politika sayfası (`https://fabricahere1.github.io/iste-gizlilik`) beyan ettiği veri kategorileri:
- Ad/soyad, profil fotoğrafı, e-posta/telefon
- İlanlar, ilan fotoğrafları, mesajlar
- Takip ilişkileri, platform güvenilirlik skoru
- Yaşanılan şehir/ülke, seyahat edilen şehirler, giyim/beden tercihleri, ilgi alanı kategorileri, duty-free tercihleri
- Kullanım istatistikleri, OS/uygulama sürümü, push notification token (`fcmToken`)

Kod tabanında `KullaniciModel` (`lib/features/profil/domain/kullanici_model.dart`) ve Firestore yazımları incelendi. Gerçekte toplanan/saklanan alanlar: `adSoyad`, `fotoUrl`, `telefon`, `email`, `fcmToken` (`lib/core/services/fcm_service.dart:107,122,140`), `yasadigiUlke`, `bulunduguSehir`, `geldigiSehirler`, `hakkinda`, `ilgiKategorileri`, `dutyFreeIlgileniyor`, `istekTeslimatTercihi`, beden bilgileri (`kadinUstBeden`, `kadinAltBeden`, `erkekUstBeden`, `erkekAltBeden`, `kadinAyakkabi`, `erkekAyakkabi`, `cocukAyakkabi`), `takipciSayisi`, `takipSayisi`, `guvenSkoru`, `rozetler`, `engellenenler`.

| Bulgu | Dosya:Satır | Önem | Açıklama |
|---|---|---|---|
| Politika ↔ kod tutarlılığı | `lib/features/profil/domain/kullanici_model.dart` | Düşük | İncelenen tüm alanlar (isim, foto, iletişim, şehir/ülke, ilgi alanı, beden, duty-free, güven skoru, push token, ilan/mesaj) politika metninde karşılık buluyor. Belirgin bir tutarsızlık **bulunamadı**. |
| `engellenenler` (blok listesi) ve `rozetler` alanları politikada açıkça adlandırılmamış | `kullanici_model.dart` (freezed alan listesi) | Düşük | Bunlar "platform aktiviteleri" kapsamında zımnen sayılabilir ama politika metninde ayrı ayrı geçmiyor — **Şüpheli/Doğrulanmadı**, hukuki gözden geçirme önerilir. |
| Konum verisi elle giriliyor, GPS/hassas konum toplanmıyor | — | Düşük | Kodda coğrafi konum (Geolocator vb.) paketi kullanımı yok; politika da "yaşanılan şehir/ülke" diyor, GPS bahsi yok — tutarlı. |

---

## BÖLÜM C — İçerik Politikası Riskleri

`kKategoriAgaci` (`lib/shared/constants/app_constants.dart:76-154`) incelendi: Kadın, Erkek, Çocuk, Ev, Elektronik, Supplement & Medikal, Diğer — 7 ana kategori. Alkol, silah, tütün, kumar, uyuşturucu gibi yaş kısıtlı/yasaklı bir kategori düğümü **bulunamadı**. "Vape" önceki hafta kaldırılmış; benzer bir kalıntı yok.

`tasiyici_ipuclari_bolum.dart:57-58` içinde alkol geçiyor ama bu bir kategori değil, "taşıyıcı ipuçları" bilgilendirme metninde "Kişisel kullanım için 1 litre alkollü içecek getirilebilir" şeklinde gümrük/mevzuat bilgisi — ürün kategorisi olarak satılığa çıkarılmıyor.

`kullanim_kosullari_screen.dart:126` kullanım şartlarında "Uyuşturucu, silah veya yasadışı madde taşınmasının talep edilmesi veya kabul edilmesi" açıkça yasaklanmış — olumlu bir bulgu.

Yanıltıcı iddia taraması ("garanti", "%100 güvenli", "resmi"): Sonuçların tamamı ya kod yorumları (`.dart` içi teknik yorum, kullanıcıya gösterilmiyor) ya da ürün-karşılaştırma bilgilendirme metinleri (`alisveris_rehberi_bolum.dart` — "Türkiye'de resmi garantisi yok" gibi dürüst/uyarı niteliğinde ifadeler) ya da gizlilik/kullanım şartları metinlerinde standart hukuki dil ("%100 güvenli olduğu garanti edilemez" — tam tersi, dürüst uyarı).

| Bulgu | Dosya:Satır | Önem | Açıklama |
|---|---|---|---|
| Yaş kısıtlı/yasaklı kategori kalıntısı yok | `lib/shared/constants/app_constants.dart:76-154` | — | Doğrulandı, risk yok |
| Yanıltıcı "garanti/%100 güvenli/resmi" iddiası kullanıcıya gösterilen metinlerde yok | (taranan tüm eşleşmeler) | — | Doğrulandı, risk yok |

---

## BÖLÜM D — Kararlılık/Çökme Riski

**Crashlytics:** `lib/main.dart:59-66` içinde `!kDebugMode` koşuluyla `FlutterError.onError` ve `PlatformDispatcher.instance.onError` Crashlytics'e bağlanmış — release modda tüm fatal hatalar yakalanıyor. Ayrıca `lib/shared/utils/app_hata_yonetici.dart:54` içinde manuel `recordError` çağrısı var (merkezi hata yöneticisi). Kurulum doğru görünüyor.

**Son 2 günlük commit'ler:** `git log --since="2 days ago"` yalnızca **1 commit** gösterdi: `ece6ae1 "ikon oncesi"`. Bu commit'in diff'inde eklenen satırlar arasında yeni `!` (bang) operatörü veya güvensiz `as Type` cast'i **bulunamadı** (grep ile arandı, eşleşme yok).

**`flutter analyze` tam çıktısı:**
```
Analyzing iste_v3...

   info - Unnecessary use of multiple underscores - lib\features\home\presentation\sana_ozel_screen.dart:1036:34 - unnecessary_underscores
   info - 'appleProvider' is deprecated and shouldn't be used. Use providerApple instead. This parameter will be removed in a future major release - lib\main.dart:54:5 - deprecated_member_use

2 issues found. (ran in 19.3s)
```

**`flutter test` sonucu:** Tüm testler geçti — **56/56 test PASSED** (1 skip: kasıtlı, kod yorumunda gerekçesi açıklanmış — kendi kendini takip etme kontrolü firestore.rules sorumluluğunda, client testi kapsam dışı bırakılmış).

| Bulgu | Dosya:Satır | Önem | Açıklama |
|---|---|---|---|
| Crashlytics doğru kurulu | `lib/main.dart:59-66` | — | Release modda fatal ve non-fatal hatalar yakalanıyor |
| Son 2 günde riskli `!`/`as` kullanımı yok | (git diff, ece6ae1) | — | Doğrulandı |
| `flutter analyze`: 2 info-seviye uyarı | `sana_ozel_screen.dart:1036`, `main.dart:54` | Düşük | Hata/uyarı değil, sadece bilgi (info) seviyesinde; derleme veya davranışı etkilemez |
| `appleProvider` deprecated kullanımı | `lib/main.dart:54` | Düşük | Gelecekte kaldırılacak API, `providerApple` ile değiştirilmesi önerilir ama şu an çalışıyor |
| `flutter test`: 56/56 geçti | — | — | Kararlılık açısından olumlu sinyal |

---

## BÖLÜM E — Debug/Test Kalıntıları

| Bulgu | Dosya:Satır | Önem | Açıklama |
|---|---|---|---|
| `COACH_MARK_DEBUG` debug log'ları hâlâ kodda | `lib/features/mesajlar/presentation/sohbet_screen.dart:176,178` | Düşük | `debugPrint('[COACH_MARK_DEBUG] ...')` — `debugPrint` release modda no-op'a yakın davranır (varsayılan olarak sadece debug console'a yazar, performans/güvenlik riski yaratmaz) ama isimlendirmesi "debug flag" gibi göründüğünden unutulmuş geliştirme kalıntısı izlenimi veriyor. Kaldırılması veya `kDebugMode` guard'ına alınması önerilir. |
| Çıplak `print(` kullanımı yok | — | — | Taranan sonuçlarda `print(` (debugPrint hariç) bulunamadı — olumlu |
| `kDebugMode`/`kReleaseMode` kullanımları mantıksal olarak doğru | `lib/main.dart:51-56,60`, `lib/core/services/fcm_service.dart:48`, `lib/shared/utils/app_hata_yonetici.dart:50` | — | Ters kullanım (örn. release'de debug provider aktif etme) tespit edilmedi |
| Hardcoded test kimlik bilgisi | — | — | Taramada bulunamadı (Firebase test telefon numarası hariç zaten kapsam dışı tutuldu, ayrıca da rastlanmadı) |

---

## BÖLÜM F — Genel Uygulama Kalitesi

| Bulgu | Dosya:Satır | Önem | Açıklama |
|---|---|---|---|
| TODO/FIXME/Lorem ipsum yok | (lib/ geneli tarandı) | — | Ana ekranlarda (ilan detay, sohbet, profil) hiçbir TODO/FIXME/placeholder metin bulunamadı |
| Boş `onTap: () {}` — E-posta satırı | `lib/features/profil/presentation/ayarlar_screen.dart:128` | **Orta** | Ayarlar ekranında "E-posta" satırının `onTap: () {}` şeklinde boş bırakılmış — kullanıcı e-posta satırına dokunduğunda hiçbir şey olmuyor. Diğer satırlar (telefon vb.) muhtemelen aktif; bu tutarsızlık kullanıcıda "kırık buton" hissi yaratabilir. Ya aktif bir aksiyon eklenmeli ya da satır tamamen tıklanamaz/dokunma efektsiz yapılmalı. |
| Boş `onTap: () {}` — kasıtlı (bubble tıklama engelleme) | `lib/shared/widgets/neden_iste_bar.dart:78` | Düşük | Yorumla açıklanmış: "iç tıklamalar kapanmasın" — kasıtlı, sorun değil |
| Tanımlı route'ların tamamı en az bir yerden çağrılıyor | `lib/router/app_router.dart` (AppRoutes sınıfı) | — | `splash`, `login`, `register`, `profilTamamla`, `home`, `ilanDetay`, `gelenler`, `ilanOlusturIstek`/`Tasiyici`, `guncellemeGerekli`, `takip-listesi` route'larının her biri için en az bir `context.go/push` veya `ref.read(routerProvider).go` çağrısı doğrulandı. Referanssız/ölü route bulunamadı. |

---

## Üretim İncelemesini Engelleyebilecek YENİ Bir Risk Var mı?

**HAYIR.** Taranan alanlarda Google Play üretim incelemesini doğrudan engelleyecek kritik bir bulguya rastlanmadı (yasaklı kategori kalıntısı yok, yanıltıcı iddia yok, izin/veri tutarsızlığı yok, testler geçiyor, analyze temiz, Crashlytics kurulu).

Yine de önem sırasına göre iyileştirilmesi önerilen bulgular:

1. **(Orta)** `lib/features/profil/presentation/ayarlar_screen.dart:128` — Ayarlar ekranındaki "E-posta" satırının boş `onTap: () {}` içermesi; kullanıcıya işlevsiz bir dokunma alanı sunuyor, launch öncesi düzeltilmesi veya tıklanamaz yapılması önerilir.
2. **(Düşük)** `lib/features/mesajlar/presentation/sohbet_screen.dart:176,178` — `COACH_MARK_DEBUG` etiketli `debugPrint` kalıntıları; işlevsel risk yok ama temizlik için kaldırılması önerilir.
3. **(Düşük)** `lib/main.dart:54` — `appleProvider` deprecated API kullanımı; gelecekteki bir Firebase App Check sürüm yükseltmesinde derleme hatasına dönüşebilir, `providerApple` ile değiştirilmesi önerilir.
4. **(Düşük / Şüpheli-Doğrulanmadı)** `engellenenler` ve `rozetler` alanlarının gizlilik politikasında ayrı ayrı adlandırılmamış olması; hukuki/metin gözden geçirmesi önerilir ama kanıt kesin değil, politika metni bunları zımnen kapsıyor olabilir.
