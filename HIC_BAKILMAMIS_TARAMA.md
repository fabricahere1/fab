# Hiç Bakılmamış Tarama Raporu

Tarih: 2026-07-18 (salt-okuma tarama; hiçbir kod dosyası değiştirilmedi)

## Bulgular (önem sırasına göre)

### 1. [Yüksek] Her rebuild'de yeni `PageController` yaratılıyor ve eskisi dispose edilmiyor — sızıntı
**Dosya:** `lib/features/ilanlar/presentation/ilan_detay_screen.dart:1364-1365`
**Durum:** Doğrulandı (kod okundu)

`_ResimBuyukEkranState.build()` içinde:
```dart
body: PageView.builder(
  controller: PageController(initialPage: widget.baslangicIndex),
  ...
  onPageChanged: (i) {
    setState(() => _aktif = i);
    ...
```
`PageController` `build()` metodu içinde inline oluşturuluyor, bir field'a atanmıyor ve `dispose()` içinde kapatılmıyor (dispose() yalnızca `_zoomCtrl` ve `_transformController`'ı kapatıyor, satır 1312-1316). `onPageChanged` her tetiklendiğinde `setState` çağrılıyor, bu da `build()`'i yeniden çalıştırıp **yeni bir `PageController`** yaratıyor; önceki controller hiçbir zaman `.dispose()` edilmiyor. Kullanıcı resim galerisinde çok sayfa gezinirse controller nesneleri birikir (sızıntı). Kritik olmamasının sebebi: ekran kapanınca eski controller'lar GC'ye tabi olabilir (Flutter'da unattached PageController'lar hard-leak olmayabilir), ama yine de "kaynak temiz kapatılmıyor" ilkesine aykırı ve yanlış desen — düzeltilmesi önerilir (controller'ı field yapıp initState'te bir kere oluşturup dispose'ta kapatmak).

### 2. Diğer tüm dispose kontrolleri — TEMİZ (Doğrulandı)
Aşağıdaki dosyalar tek tek okunarak (initState + dispose satırları) doğrulandı; hepsinde oluşturulan controller/subscription'lar dispose()/cancel() içinde düzgün kapatılıyor:

| Dosya | Kaynaklar | Dispose durumu |
|---|---|---|
| `lib/features/profil/presentation/takip_listesi_screen.dart:34,42-44` | `TabController` | Kapatılıyor |
| `lib/router/app_router.dart:60-69` (ProviderSubscription x3), `270-295` (AnimationController) | `_authSub/_profilSub/_surumSub`, `_ctrl` | Kapatılıyor |
| `lib/features/ilanlar/presentation/ilan_detay_screen.dart:36-47` (PageController - üst seviye ekran) | `_pageController` | Kapatılıyor |
| `lib/features/mesajlar/presentation/sohbet_screen.dart:48-49,293-296` ve `1385-1413` (`_shakeCtrl`) | TextEditingController, ScrollController, AnimationController | Kapatılıyor |
| `lib/features/mesajlar/presentation/islem_durumu_panel.dart:502-572,776-812` | 2 ayrı AnimationController (`_ctrl`) | Her ikisi de kapatılıyor |
| `lib/features/profil/presentation/ilanlarim_screen.dart:28-39` | `TabController` | Kapatılıyor |
| `lib/features/ilanlar/presentation/widgets/ilan_karti.dart:175-181,433-451,567-605` | PageController + 2 AnimationController | Kapatılıyor |
| `lib/features/home/presentation/sana_ozel_screen.dart:536-549` | AnimationController | Kapatılıyor |
| `lib/features/home/presentation/kesfet_vitrin2_tab.dart:513-533` | AnimationController | Kapatılıyor |
| `lib/features/home/presentation/kesfet_screen.dart:34-52` | TabController | Kapatılıyor |
| `lib/features/ilanlar/presentation/widgets/swipe_karti.dart:39-101` | 2 AnimationController (`_animCtrl`,`_favCtrl`) | Kapatılıyor |
| `lib/core/services/banner_service.dart:119-139` | AnimationController | Kapatılıyor |
| `lib/features/ilanlar/presentation/widgets/ilan_overlay_widget.dart:33-130` | 6 AnimationController | Hepsi tek tek kapatılıyor |

StreamSubscription kullanan servis/provider dosyaları da tek tek doğrulandı:

| Dosya | Sub'lar | Cancel durumu |
|---|---|---|
| `lib/features/mesajlar/providers/mesaj_provider.dart:109,149-150` | `_mesajSub` | `.cancel()` çağrılıyor |
| `lib/features/ilanlar/providers/ilan_provider.dart:394-415` | lokal `sub` | `.cancel()` çağrılıyor |
| `lib/core/services/fcm_service.dart:31-34,174-177` | 4 subscription | Hepsi `dispose()`'ta cancel ediliyor |
| `lib/core/services/badge_service.dart:17-45` | `_authSub`,`_bildirimSub` | `dispose()`'ta cancel ediliyor |
| `lib/core/services/bildirim_banner_service.dart:31-84` | `_authSub`,`_bildirimSub` | `dispose()`'ta cancel ediliyor |

Not: 23 dosyalık TextEditingController/ScrollController/AnimationController grep listesinden yukarıdaki 13'ü zaten Bölüm A'nın "öncelikli" listesindeydi; kalan 10 dosya (`ilanlar_screen.dart`, `profil_screen.dart`, `gelenler_screen.dart`, `iletisim_form_sheet.dart`, `ilan_form_screen.dart`, `mesajlar_screen.dart`, `ayarlar_screen.dart`, `arama_screen.dart`, `profil_duzenle_screen.dart`, `login_screen.dart`, `degerlendirme_screen.dart`, `profil_tamamla_screen.dart`, `profil_tamamla_widgets.dart`) context sınırı nedeniyle bu turda tek tek dispose() doğrulaması yapılmadı — **İNCELENMEDİ**, ayrı bir taramada ele alınmalı.

## Bölüm B — Performans

**B1 — İNCELENMEDİ (kısmi).** Zaman kısıtı nedeniyle `ilanlar_screen.dart`, `sohbet_screen.dart`, `home_screen.dart`, `sana_ozel_screen.dart`, `ilan_detay_screen.dart` içindeki `setState()` çağrılarının etki alanı derinlemesine analiz edilmedi. Yalnızca yüzeysel sayım yapıldı: `ilanlar_screen.dart` içinde 8 adet `setState` çağrısı bulundu, `sohbet_screen.dart` içinde 0 (StateNotifier/Riverpod ile yönetiliyor olabilir — ayrıca doğrulanmalı). Widget ağacının hangi kısmının etkilendiği tek tek incelenmedi; bu nedenle kesin bir "aşırı geniş setState" bulgusu iddia edilmiyor. **Ayrı bir taramada ele alınmalı.**

**B2 — İNCELENMEDİ.** `build()` içinde ağır senkron işlem (büyük JSON parse, sort/where zincirleri) olup olmadığı bu turda taranmadı.

## Bölüm C — UI/UX tutarlılığı

### C1. Boş durum (empty state) ekranları

| Ekran | Boş durum widget'ı var mı | Kanıt (dosya:satır) |
|---|---|---|
| `favoriler_screen.dart` | Var | satır 52-55, `favoriler.isEmpty` → `Center(Column(...))` |
| `arama_screen.dart` | Var (2 farklı durum: hiç arama yok / sonuç yok) | satır 199-218, `_BosHal` ve `_SonucYokHal` widget'ları |
| `bildirimler_screen.dart` | Var | satır 87-90, `bildirimler.isEmpty` → `Center(Column(...))` |
| `mesajlar_screen.dart` | Var | satır 134-137, `gorunenler.isEmpty` → `Center(Column(...))` |
| `gelenler_screen.dart` | Var | satır 199-201/317-319, `ilanlar.isEmpty` → `_BosEkran` widget'ı (yükleniyor/hata/boş durumları ayrı ayrı ele alınmış) |
| `degerlendirmeler_liste_screen.dart` | Var | satır 28-69, `state.liste.isEmpty` (yükleniyor/hata/boş ayrı ayrı) |
| `takip_listesi_screen.dart` | Var | satır 141-143, `_sabitIdler!.isEmpty` → `Center(Column(...))` |

**Sonuç:** Taranan 7 ekranın hepsinde boş durum widget'ı mevcut — bu bölümde eksik bulunmadı (Doğrulandı).

### C2. Hata mesajı gösterim tutarlılığı — Şüpheli/Doğrulanmadı (yüzeysel)

Grep sonucuna göre proje genelinde 3 farklı hata gösterim mekanizması bir arada kullanılıyor gibi görünüyor:
- `lib/shared/utils/app_snackbar.dart` — merkezi bir SnackBar yardımcı sınıfı var (9 kullanım noktası kendi içinde)
- `lib/shared/utils/app_hata_yonetici.dart` — merkezi log/hata yöneticisi (3 iç kullanım, ama 122 toplam eşleşme çoğu dosyada `AppHataYonetici.logla` çağrısı olarak geçiyor)
- Çeşitli ekranlarda (`ayarlar_screen.dart`: 18, `sohbet_screen.dart`: 8, `ilan_detay_screen.dart`: 9, `ilan_provider.dart`: 9) yoğun SnackBar/AlertDialog/log karışımı var

Bu sadece bir grep sayımı; her dosyanın SnackBar mi AlertDialog mu yoksa sessiz log mu kullandığını, ve bunun kullanıcı senaryosuna göre tutarlı olup olmadığını satır satır doğrulamak için zaman kalmadı. **İNCELENMEDİ (derinlemesine)** — mevcut veri, en azından merkezi bir `AppSnackbar` ve `AppHataYonetici` yardımcı sınıfının var olduğunu ve kullanıldığını gösteriyor ki bu iyi bir işaret, ama ekran bazında tutarlılık iddiası bu turda doğrulanamadı.

## Bölüm D — Bağımlılık sürümleri

### D1. `pubspec.yaml` (proje kökü)

| Paket | Kullanılan sürüm |
|---|---|
| flutter_riverpod | ^3.1.0 |
| riverpod_annotation | ^4.0.0 |
| freezed_annotation | ^3.1.0 |
| json_annotation | ^4.9.0 |
| firebase_core | ^4.6.0 |
| firebase_auth | ^6.3.0 |
| cloud_firestore | ^6.2.0 |
| firebase_storage | ^13.2.0 |
| firebase_messaging | ^16.1.3 |
| firebase_app_check | 0.4.2 (sabit, `^` yok) |
| google_sign_in | ^6.2.2 |
| go_router | ^14.8.1 *(zaten bilinen/doğrulanmış bulgu: "3 majör geride" — burada tekrar tartışılmadı)* |
| google_fonts | ^6.3.3 |
| cached_network_image | ^3.4.1 |
| flutter_staggered_grid_view | ^0.7.0 |
| shimmer | ^3.0.0 |
| flutter_map | ^7.0.0 |
| latlong2 | ^0.9.0 |
| animations | ^2.0.11 |
| material_symbols_icons | ^4.2.1 |
| image_picker | ^1.1.2 |
| flutter_image_compress | ^2.3.0 |
| path_provider | ^2.1.4 |
| url_launcher | ^6.3.1 |
| shared_preferences | ^2.5.5 |
| app_badge_plus | ^1.0.0 |
| connectivity_plus | ^6.0.0 |
| cupertino_icons | ^1.0.8 |
| flutter_cache_manager | ^3.4.1 |
| cloud_functions | ^6.2.0 |
| flutter_native_splash | ^2.4.3 |
| http | 1.2.2 (sabit, `^` yok) |
| firebase_crashlytics | ^5.2.0 |
| package_info_plus | ^8.1.2 |
| flutter_lints (dev) | ^6.0.0 |
| build_runner (dev) | ^2.4.14 |
| riverpod_generator (dev) | ^4.0.0+1 |
| freezed (dev) | ^3.2.3 |
| json_serializable (dev) | ^6.11.2 |
| flutter_launcher_icons (dev) | ^0.14.1 |

Diğer paketlerde majör sürüm farkı olup olmadığı bu taramada doğrulanamadı — pub.dev güncel sürüm bilgisi zaman içinde değişir, bu konu ayrı bir web araştırmasıyla doğrulanmalı.

### D2. `functions/package.json`

| Paket | Kullanılan sürüm |
|---|---|
| @google-cloud/vision | ^5.3.7 |
| @types/nodemailer | ^8.0.1 |
| algoliasearch | ^5.52.1 |
| axios | ^1.17.0 |
| firebase-admin | ^13.8.0 |
| firebase-functions | ^7.2.5 |
| nodemailer | ^6.10.1 |
| firebase-functions-test (dev) | ^3.4.1 |
| typescript (dev) | ^6.0.0 |
| node (engines) | 22 |

Aynı şekilde: bu paketlerde majör sürüm farkı olup olmadığı doğrulanamadı, ayrı bir web araştırması gerekir.

---

## SONUÇ

**Bu dört bölümde (A/B/C/D) launch'ı engelleyen DOĞRULANMIŞ bir sorun var mı?**

HAYIR — bu taramada doğrulanan tek somut kaynak-yönetimi bulgusu (`ilan_detay_screen.dart:1364-1365`, PageController'ın build() içinde inline oluşturulup dispose edilmemesi) launch'ı engelleyecek kritik seviyede değil, yalnızca "Yüksek" öncelikli bir temizlik/best-practice sorunu; boş durum ekranları taranan 7 ekranda da mevcut ve bağımlılık sürümleri sadece bilgi amaçlı listelendi (karşılaştırma yapılmadı). Bölüm B ve C2 derinlemesine incelenemedi, bu nedenle bu bölümler için "temiz" garantisi verilmiyor.
