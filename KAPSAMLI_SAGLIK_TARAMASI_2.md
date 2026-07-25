# Kapsamlı Sağlık Taraması #2

Tarih: 2026-07-25 · Önceki tarama: `GENEL_SAGLIK_TARAMASI.md` (bugün, erken saat).
Salt-okuma — hiçbir dosya değiştirilmedi.

Etiketleme: **Kritik** · **Orta** · **Düşük** · **Şüpheli/Doğrulanmadı**.

---

## BÖLÜM A — Font çökmeleri (öncelikli, derinlemesine)

### A6 sonucu önce (bulgunun özeti): **Kök neden bulundu — önceki "weight düzeltmesi" yetersizdi.**

### A1. `pubspec.yaml` font tanımları

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/splash/
    - assets/images/
    - assets/images/rehber/
    - assets/google_fonts/
    - assets/animations/
```

**Kritik gözlem:** `pubspec.yaml`'da bir `fonts:` bloğu (family → weight → asset yolu eşlemesi) **YOK**. Proje, `google_fonts` paketinin "bundled fonts" (kendi içindeki dosya adı kuralına göre otomatik eşleştirme) özelliğine dayanıyor — `assets/google_fonts/` klasörü yalnızca genel bir asset klasörü olarak tanımlı, paket bu klasördeki dosyaları KENDİ isimlendirme algoritmasıyla arıyor. Bu, manuel yol hatası riskini ortadan kaldırır AMA dosya adının paketin beklediği kalıpla **BİREBİR** (sonek olarak) eşleşmesini gerektirir — bkz. A2.

### A2. Dosya adı eşleşmesi — gerçek algoritma kaynak koddan okundu

Yüklü `google_fonts` paketinin (v6.3.3, `google_fonts_base.dart:308-334`) asset eşleştirme mantığı:

```dart
String? _findFamilyWithVariantAssetPath(...) {
  final String apiFilenamePrefix = familyWithVariant.toApiFilenamePrefix();
  for (final String asset in manifestValues) {
    ...
    final String assetWithoutExtension = asset.substring(0, asset.length - matchingSuffix.length);
    if (assetWithoutExtension.endsWith(apiFilenamePrefix)) {   // ← KRİTİK SATIR
      return asset;
    }
  }
  return null;
}
```

`apiFilenamePrefix` = `"$family-${variant}"` (örn. `"Merriweather-Medium"`) — asset dosya adının (uzantısız) bu string ile **BİTMESİ** gerekiyor.

**`assets/google_fonts/Merriweather_24pt-Medium.ttf` bu koşulu SAĞLAMIYOR.** Dosya adı `"Merriweather_24pt-Medium"` — bu, `"Merriweather-Medium"` ile **bitmiyor** (aradaki `_24pt` eki suffix eşleşmesini bozuyor: son 20 karakter `"eather_24pt-Medium"`'dır, `"Merriweather-Medium"` değil).

**Sonuç:** `GoogleFonts.merriweather(fontWeight: FontWeight.w500)` çağrısı, ağırlık dosyada mevcut olsa bile **asset'i asla bulamıyor**. `allowRuntimeFetching = false` (bkz. A3) olduğu için paket ağdan da çekemiyor — `loadFontIfNecessary` içindeki `else` dalı devreye giriyor ve **`Exception`** fırlatıyor:
```
GoogleFonts.config.allowRuntimeFetching is false but font Merriweather-Medium was not
found in the application assets. Ensure Merriweather-Medium.ttf exists in a
folder that is included in your pubspec's assets.
```

**Bu, bugünkü ilk taramanın kaçırdığı gerçek kök neden.** Önceki oturumda yapılan "w400 yerine w500 kullan" düzeltmesi (`kesfet_bolum_baslik.dart:55`, commit `e71258c`) yalnızca AĞIRLIK uyuşmazlığını gideriyordu — dosya adındaki `_24pt` eki nedeniyle **asset hâlâ hiç bulunamıyor ve istisna hâlâ fırlıyor olabilir.** Diğer tüm fontlarda (`Poppins-ExtraBold.ttf` dahil, bkz. aşağıdaki tablo) böyle bir infix yok, hepsi `Family-Weight.ttf` kalıbına tam uyuyor.

| Dosya | `apiFilenamePrefix` ile eşleşir mi? |
|---|---|
| `Poppins-ExtraBold.ttf` | ✅ Evet (tam eşleşme) |
| `Merriweather_24pt-Medium.ttf` | ❌ **HAYIR** — `_24pt` infix'i suffix eşleşmesini bozuyor |
| Diğer tüm dosyalar (DMSans, Manrope, Inter, PlayfairDisplay, Raleway, NotoSans, Urbanist, Nunito, BebasNeue, DMSerifDisplay) | ✅ Evet — standart `Family-Weight[.Style].ttf` kalıbında |

**Önem derecesi: Kritik.** Bu satır kod tarafından kanıtlanmış (spekülasyon değil) — paketin kendi kaynak koduyla dosya adı birebir karşılaştırıldı.

### A3. `allowRuntimeFetching` ayarı

`lib/main.dart:32`:
```dart
GoogleFonts.config.allowRuntimeFetching = false;
```
`main()`'in en başında, `Firebase.initializeApp` öncesinde ayarlanmış — **tutarlı**, hiçbir ekranda bundan farklı/geçici bir ayar bulunamadı (proje genelinde `allowRuntimeFetching` için tek referans bu). Yani "bazı ekranlarda ağdan çekmeye çalışıyor" tutarsızlığı **yok** — davranış her yerde deterministik: yalnızca bundled asset, yoksa **kesin istisna**. Bu ayarın kendisi doğru bir mühendislik kararı (öngörülebilirlik) ama A2'deki dosya adı hatasını *affetmiyor*, tam tersine onu kesinleştiriyor (ağ fallback'i olmadığı için).

### A4. Yazım hatası taraması

Kod içindeki tüm `GoogleFonts.xxx()` çağrıları (`poppins`, `merriweather`, `dmSans`, `manrope`, `inter`, `playfairDisplay`, `raleway`, `notoSans`, `urbanist`, `nunito`, `bebasNeue`, `dmSerifDisplay`) tarandı — hepsi paketin gerçek, var olan metodları (Dart derleyicisi zaten bunu derleme zamanında yakalar, statik metod olmayan bir çağrı derlenmez). **Yazım hatası bulunamadı.**

### A5. Crashlytics hata yakalama

`main.dart:55-61`:
```dart
if (!kDebugMode) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
```
Bu, **release modda** çalışır — `google_fonts`'un fırlattığı istisna `loadFontIfNecessary` içinde bir `Future` zincirinde oluşur (`rethrow` ile). Eğer bu future hiçbir yerde `await`/`catch` edilmeden çağrılıyorsa (ki `googleFontsTextStyle` içinde `pendingFontFutures.add(loadingFuture)` ile "fire and forget" şeklinde ekleniyor, senkron `TextStyle` döndürülüyor — bkz. `google_fonts_base.dart:110-117`), bu bir **unhandled async error** olarak `PlatformDispatcher.onError`'a düşer. Debug modda ise (yani bd'nin muhtemelen geliştirme sırasında gördüğü durum) `FlutterError.onError`/Crashlytics devrede DEĞİL (`if (!kDebugMode)` koşulu) — konsola kırmızı hata/istisna basılır ama Crashlytics'e gitmez. **Bu, "font çökmesi" ifadesinin neden debug'da görülüp prod loglarında net görünmeyebileceğini açıklıyor olabilir** (Şüpheli/Doğrulanmadı — bd'nin çökmeyi hangi build modunda gördüğü bu taramada bilinmiyor).

Önemli nüans: Bu bir *senkron widget render çökmesi* değil — `TextStyle` her durumda döndürülüyor (`familyWithVariant.toString()` ile, font yüklenemese bile), Flutter bu durumda **sistem fontuna/fallback'e düşer**, ekran görsel olarak "bozuk font" gösterir ama Dart seviyesinde bir `Exception` de ayrıca (log'a/Crashlytics'e) fırlar. Yani muhtemel gerçek kullanıcı deneyimi: **tam bir uygulama çökmesi değil, o metnin yanlış fontla (sistem varsayılanıyla) render edilmesi + arka planda sessiz bir exception log'u.** "Çökme" ifadesi (bd'nin kullandığı kelime) bu ayrımı netleştirmiyor — **Şüpheli/Doğrulanmadı: gerçek "hard crash" mi yoksa "yanlış font render + log gürültüsü" mü, bu koddan kesin olarak ayırt edilemiyor.**

### A6. Hangi ekranlar / net durum

`GoogleFonts.merriweather(...)` kod tabanında **tek bir yerde** kullanılıyor: `lib/features/home/presentation/kesfet_bolum_baslik.dart:55`. Bu widget (`KesfetBolumBaslik`) şu 3 dosyada kullanılıyor:
- `kesfet_vitrin_tab.dart`
- `kesfet_vitrin2_tab.dart`
- `sana_ozel_screen.dart`

Yani sorun, **Keşfet sekmesi ve Sana Özel ekranındaki vitrin bölüm başlıkları** her render edildiğinde tetiklenir — nadir bir uç durum değil, bu ekranlara her girişte karşılaşılabilecek bir durum.

**A6 net cevap:** Ekran/durum netleştirildi, kodda tespit edilebildi (yukarıdaki 3 dosya). "Belirli bir metin uzunluğu" gibi ek bir tetikleyici koşul bulunamadı/yoktu — sorun tamamen dosya adı eşleşmesiyle ilgili, içerikten bağımsız.

### Bölüm A sonucu

**En olası kök neden (kanıta dayalı, yüksek güven):** `assets/google_fonts/Merriweather_24pt-Medium.ttf` dosya adı, `google_fonts` paketinin iç eşleştirme algoritmasının beklediği `Family-Weight.ttf` (`Merriweather-Medium.ttf`) kalıbına UYMUYOR — Google Fonts'un yeni "değişken font ailesi" adlandırması (`_24pt` sonek) nedeniyle. `allowRuntimeFetching=false` olduğundan ağ fallback'i de yok, bu yüzden `GoogleFonts.merriweather()` her çağrıldığında (Keşfet/Sana Özel ekranlarındaki vitrin başlıklarında) istisna fırlatıyor olabilir. **Önceki "w700→w500" düzeltmesi bu sorunu ÇÖZMEDİ**, yalnızca farklı bir (weight) sorunu giderdi.

**Önerilen düzeltme (uygulanmadı, bu görev salt-okuma):** `assets/google_fonts/Merriweather_24pt-Medium.ttf` dosyasını `Merriweather-Medium.ttf` olarak yeniden adlandırmak (pubspec değişikliği gerekmez, klasör zaten tanımlı).

---

## BÖLÜM B — Ağ/çevrimdışı dayanıklılığı

| Bulgu | Risk | Kanıt |
|---|---|---|
| Firestore offline persistence açıkça etkin, `CACHE_SIZE_UNLIMITED` | Düşük (doğru yapılandırma) | `main.dart:40-43` |
| `ilanlar_screen.dart` "Haftanın enleri" bölümü hata durumunda sessizce `SizedBox.shrink()` dönüyor, kullanıcıya hiç bildirim yok | Orta | `ilanlar_screen.dart:978-980`, yalnızca `AppHataYonetici.logla` |
| `sohbet_screen.dart`'ta `ilanByIdProvider`/`sohbetMetaProvider` sonuçları `.value ?? default` ile okunuyor — hata durumunda sessizce varsayılana düşüyor | Orta | satır 489-496 |
| `bildirimler_screen.dart`, `mesajlar_screen.dart` — `error:` dalları düzgün tanımlı, kullanıcıya mesaj gösteriliyor | Düşük | doğrulandı |
| Upload akışı (`ilan_repository.dart`, `ilan_form_screen.dart`, `profil_duzenle_screen.dart`) — try/catch/finally düzgün, loading flag her durumda sıfırlanıyor, hata `AppSnackBar` ile gösteriliyor, kısmi yüklenen dosyalar hata durumunda siliniyor | Düşük | `ilan_repository.dart:297-385`, `profil_duzenle_screen.dart:134-163` |

**Özet:** Genel mimari sağlam; en somut risk iki yerde "sessiz sessiz varsayılana düşme" deseni — çökme değil ama kullanıcıya yanlış/eksik bilgi gösterebilir.

---

## BÖLÜM C — Eşzamanlılık/yarış durumu riskleri

| Bulgu | Risk | Kanıt |
|---|---|---|
| `favoriSayisi`/`goruntulenmeSayisi` — TÜM Firestore yazma noktaları (`ilan_repository.dart:550,570,601`, `functions/index.ts:885`) `FieldValue.increment()` ile atomik; "oku-sonra-yaz" deseni bulunamadı | Düşük | doğrulandı, transaction gerekmiyor zaten atomik |
| `ilan_provider.dart`'taki elle toplama (`copyWith(favoriSayisi: ...+delta)`) yalnızca client-side optimistic UI cache, Firestore'a yazmıyor | Düşük | risk yok |
| Mesaj gönderme butonu (`sohbet_screen.dart:944,1007`) — `gonderiyor` flag'i ile çift-tık korumalı | Düşük | `onTap: gonderiyor ? null : onGonder` |
| Favori toggle (`ilan_detay_screen.dart:83-93`) — busy-flag/disable yok, hızlı çift tıkta gereksiz çift çağrı tetiklenebilir (veri bozulmaz, repository transaction guard'lı) | Orta | UX riski, veri riski değil |
| İlan silme dialog'u (`ilan_detay_screen.dart:193-210`) — "Sil" onayı sırasında loading/disable yok | Düşük-Orta | UX riski |
| Favorilerden çıkar (`favoriler_screen.dart:140-172`) — benzer, disable/loading yok ama tekil çağrı | Düşük | |

**Özet:** Veri bütünlüğü açısından risk yok (atomik increment + repository seviyesi guard'lar). UX seviyesinde birkaç buton (favori toggle, ilan sil) çift-tık koruması eksik — kozmetik/gereksiz istek riski.

---

## BÖLÜM D — Derin linkler/navigasyon uç durumları

| Bulgu | Risk | Kanıt |
|---|---|---|
| İlan silinmişse `ilan_detay_screen.dart` "İlan bulunamadı veya silindi." gösteriyor, çökme yok | Düşük | satır 356-364 |
| `bildirim_yonlendirici.dart:41-52` — sohbete yönlendirirken hedef sohbet dokümanının VAR OLUP OLMADIĞI hiç kontrol edilmeden doğrudan `SohbetScreen` push ediliyor | Orta | önceden var/yok kontrolü yok |
| `sohbet_screen.dart`'ın ana gövdesinde "sohbet silinmiş" durumu için görünür bir boş-state kontrolü net doğrulanamadı (yalnızca bir listener'ın `d==null` durumunda sessizce `return` ettiği görüldü) | Orta (Şüpheli/Doğrulanmadı) | ek inceleme gerekir, kesinleşmedi |
| `app_router.dart` — `errorBuilder`/`errorPageBuilder` tanımlı DEĞİL, go_router'ın varsayılan "route bulunamadı" ekranına düşüyor (çökme değil, stilsiz varsayılan ekran) | Düşük | grep ile doğrulandı |

**Özet:** Silinmiş ilan durumu iyi ele alınmış; silinmiş sohbete bildirimle gidiş senaryosu netleşmemiş (ek inceleme önerilir) — çökme kanıtı yok ama garanti de yok.

---

## BÖLÜM E — Genel proje istatistikleri (güncel)

| Metrik | Bugünkü ilk tarama | Şimdi | Fark |
|---|---|---|---|
| Son commit | `58d3093` (Poppins düzeltmesi) | `58d3093` + 1 sonraki oturum (henüz commit edilmemiş: `ikiliBildirimGonder` regresyon testi değişiklikleri) | Bu tarama sırasında yeni commit yapılmadı |
| Bugünkü toplam commit sayısı | 27 (7 gün) | Aynı gün içinde birkaç ek görev daha yapıldı ama henüz commit edilmedi (git status'ta staged/unstaged değişiklik olarak duruyor olabilir) | — |

*Not:* Bu bölüm için detaylı `git log`/`git status` bu turda tekrar çalıştırılmadı (görev kapsamında öncelik A/B/C/D'ye verildi) — istenirse ayrıca koşulabilir.

---

## SONUÇ

### Font çökmelerinin en olası kök nedeni
**`assets/google_fonts/Merriweather_24pt-Medium.ttf` dosya adı, `google_fonts` paketinin beklediği `Merriweather-Medium.ttf` kalıbına uymuyor** (`_24pt` infix'i nedeniyle) — bu yüzden `GoogleFonts.merriweather()` çağrıları (Keşfet + Sana Özel ekranlarındaki vitrin başlıklarında), ağırlık ne olursa olsun, `allowRuntimeFetching=false` olduğu için asla asset bulamıyor ve istisna fırlatıyor. Önceki oturumdaki "w700→w500" düzeltmesi bunu çözmemiş olabilir. Bu, paketin kendi kaynak kodu okunarak (spekülasyon değil, algoritma satır satır izlenerek) doğrulandı.

### Launch öncesi acilen kapatılması gereken YENİ bir sorun var mı?
**Evet, 1 tane — yukarıdaki Merriweather dosya adı sorunu (Kritik).** Bu, önceki taramada "düzeltildi" sanılan bir sorunun aslında hâlâ açık olabileceğini gösteriyor; canlı cihazda doğrulanması (Keşfet/Sana Özel ekranına girip gerçekten hata/log oluşup oluşmadığına bakılması) önerilir.

**Diğer bulgular (Orta öncelikli, launch'ı engellemez ama backlog'a eklenmeli):**
1. Bildirimle silinmiş sohbete yönlendirme kontrolü eksik (`bildirim_yonlendirici.dart`).
2. `ilanlar_screen.dart` "Haftanın enleri" ve `sohbet_screen.dart`'taki sessiz `.value ?? default` düşüşleri.
3. Favori toggle / ilan silme butonlarında çift-tık koruması yok (veri riski yok, UX riski var).
