# Misafir Kullanıcı Giriş Akışları — Tutarlılık Kontrolü

Tarih: 2026-07-20
Kapsam: bugün değişen 4 dosya (login_gerektiren_aksiyon.dart, bildirim_cani_widget.dart,
swipe_karti.dart, favoriler_screen.dart) — salt-okuma denetim, hiçbir dosya değiştirilmedi.

## A1 — flutter analyze (proje geneli)

**Temiz.** `flutter analyze` çıktısı:
```
2 issues found.
- info: Unnecessary use of multiple underscores — lib/features/home/presentation/sana_ozel_screen.dart:1005 (bugünkü değişikliklerle ilgisiz, önceden var)
- info: 'appleProvider' is deprecated — lib/main.dart:49 (bugünkü değişikliklerle ilgisiz, önceden var)
```
0 error. İki `info` uyarısı da bugün değişen dosyaların dışında, bu görevle ilgisiz.

## A2 — favoriler_screen.dart (buton eklenip sonra kaldırıldı)

**Temiz.** Net diff (HEAD'e göre) sadece şunu gösteriyor:
- `Text(...)` → `GestureDetector(onTap: () => context.go(AppRoutes.login), child: Text(...))`
- Stil `AppColors.textSecondary` → `AppColors.red` + `decoration: TextDecoration.underline`

`ElevatedButton`, `loginBottomSheet` çağrısı ve importu (`login_gerektiren_aksiyon.dart`) dosyada **hiç kalmamış** — grep ile doğrulandı, dosyada `loginBottomSheet` veya `ElevatedButton` string'i yok (satır 37-49 aralığında sadece `GestureDetector`/`Text`). Yarım kalmış widget parçası, kapanmamış parantez veya ölü import yok.

## A3 — login_gerektiren_aksiyon.dart (Lottie)

**Temiz**, ama küçük bir kozmetik gözlem var (bkz. aşağı).

`_LoginSheet.build()` tam güncel hali (satır 60-168):
```dart
Widget build(BuildContext context) {
  return Container(
    ...
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(width: 36, height: 4, ...),
        const SizedBox(height: 24),

        const SizedBox(height: 16),
        Lottie.asset(
          ['assets/animations/bukalemun.json', 'assets/animations/timsah.json']
              [Random().nextInt(2)],
          width: 100,
          height: 100,
        ),

        // Başlık
        Text('Devam etmek için giriş yap', ...),
        const SizedBox(height: 8),
        Text('Mesaj göndermek, favori eklemek ve ilan vermek için hesabına giriş yapman gerekiyor.', ...),
        const SizedBox(height: 28),
        // Giriş Yap butonu (ElevatedButton, context.go(AppRoutes.login))
        const SizedBox(height: 12),
        // Kayıt Ol butonu (OutlinedButton, context.go(AppRoutes.register))
      ],
    ),
  );
}
```
`dart:math` (`Random`) ve `package:lottie/lottie.dart` (`Lottie.asset`) importları **gerçekten kullanılıyor** — `flutter analyze` bunu 0 error ile doğruluyor (önceki turlarda IDE'nin gösterdiği "unused import" uyarıları, edit sonrası analizin henüz yenilenmemiş olmasından kaynaklanan geçici/stale bir durumdu; gerçek `flutter analyze` çalıştırması hep temiz çıktı verdi).

**Küçük gözlem (sorun değil, kozmetik):** satır 79 ve 81'de art arda `SizedBox(height: 24)` + `SizedBox(height: 16)` var — toplam 40px boşluk oluşuyor. Muhtemelen önceki "Handle sonrası" boşluk (24px) korunmuş, üstüne yeni 16px eklenmiş. İşlevsel bir hata değil, sadece iki ayrı SizedBox yerine tek bir `SizedBox(height: 40)` da yazılabilirdi. Görsel olarak muhtemelen fark edilmeyecek kadar küçük.

## A4 — bildirim_cani_widget.dart

**Temiz.** Git diff'e göre `PageRouteBuilder`/`SlideTransition`/`Tween`/`CurvedAnimation`/`transitionDuration: 280ms` bloğunun içeriği **birebir orijinaliyle aynı** — sadece bu blok, yeni eklenen `if (uid == null) { loginBottomSheet(context); return; }` kontrolünden sonra çalışacak şekilde `onPressed: () => Navigator.push(...)` (tek satır arrow fn) yerine `onPressed: () { ...; Navigator.push(...); }` (blok gövdeli fn) haline getirilmiş. İç mantığa dokunulmamış, sadece sarmalanmış.

## A5 — swipe_karti.dart

**Temiz.** Güncel `_favToggle` (satır 300-313):
```dart
Future<void> _favToggle(IlanModel ilan) async {
  if (ref.read(currentUserProvider) == null) {
    loginBottomSheet(context);
    return;
  }
  final isFav = ref.read(favoriliIlanIdlerProvider).contains(ilan.id);
  if (isFav) {
    await ref.read(favoriProvider.notifier).cikar(ilan.id);
  } else {
    _favCtrl.forward(from: 0).then((_) {
      if (mounted) _favCtrl.reverse();
    });
    await ref.read(favoriProvider.notifier).ekle(ilan);
  }
}
```
`isFav`/`favoriProvider`/`_favCtrl` animasyon mantığına hiç dokunulmamış — yalnızca eski tek satırlık `return;` bir `if` bloğuna genişletilip içine `loginBottomSheet(context);` eklenmiş.

## A6 — ilan_detay_screen.dart

**Temiz.** `git diff -- lib/features/ilanlar/presentation/ilan_detay_screen.dart` **tamamen boş** (0 satır) — bu dosyaya bugün hiç dokunulmadı, doğrulandı.

Kendi `loginBottomSheet(returnRoute: ...)` çağrıları hâlâ orijinal haliyle çalışıyor:
- `_favorToggle` (satır 82-86): `loginBottomSheet(context, returnRoute: AppRoutes.ilanDetayPath(ilan.id));`
- `_mesajGonder` (satır 94-98): aynı `returnRoute` deseni

Her ikisi de `loginBottomSheet` fonksiyonunun `{String? returnRoute}` opsiyonel parametresini kullanıyor — imza bugün değişmedi, geriye dönük uyumlu.

## A7 — Proje genelinde `loginBottomSheet(` çağrıları (grep sonucu)

Toplam **14 çağrı yeri**, 6 dosyada:

| Dosya:satır | Parametre | Durum |
|---|---|---|
| `home_screen.dart:150` | `returnRoute: AppRoutes.ilanOlusturIstek` | temiz |
| `home_screen.dart:173` | `returnRoute: AppRoutes.ilanOlusturTasiyici` | temiz |
| `home_screen.dart:250` | (parametresiz) | temiz |
| `home_screen.dart:269` | (parametresiz) | temiz |
| `sana_ozel_screen.dart:739` | `returnRoute: AppRoutes.ilanOlusturIstek` | temiz |
| `sana_ozel_screen.dart:761` | `returnRoute: AppRoutes.ilanOlusturTasiyici` | temiz |
| `ilan_detay_screen.dart:84` | `returnRoute: AppRoutes.ilanDetayPath(ilan.id)` | temiz (bugün değişmedi) |
| `ilan_detay_screen.dart:96` | `returnRoute: AppRoutes.ilanDetayPath(ilan.id)` | temiz (bugün değişmedi) |
| `swipe_karti.dart:302` | (parametresiz) | **bugün eklendi** |
| `bildirim_cani_widget.dart:34` | (parametresiz) | **bugün eklendi** |
| `login_gerektiren_aksiyon.dart:39` | (parametresiz, `LoginGerektirenAksiyon._kontrol` içinde) | temiz — fonksiyonun kendi tanımı |
| `neden_iste_bar.dart:135` | `returnRoute: AppRoutes.ilanOlusturIstek` | temiz |
| `neden_iste_bar.dart:154` | `returnRoute: AppRoutes.ilanOlusturTasiyici` | temiz |
| `login_gerektiren_aksiyon.dart:46` | (fonksiyon tanımı, `void loginBottomSheet(BuildContext context, {String? returnRoute})`) | tanım satırı |

Hepsi fonksiyonun tek imzasına (`BuildContext context, {String? returnRoute}`) uygun çağrılıyor; yanlış/fazladan parametre geçiren yok. `bildirim_cani_widget.dart` ve `swipe_karti.dart` bilinçli olarak `returnRoute` **vermiyor** — bu tutarlı bir tasarım kararı, çünkü her iki widget da kalıcı bir "geri dönülecek rota" bağlamında değil (bildirim çanı her ekrandan erişilebilir bir AppBar ikonu, swipe kartı da tek bir ilan sayfası değil bir liste akışı içinde); `ilan_detay_screen.dart`'ta ise belirli bir ilan sayfasına geri dönmek anlamlı olduğu için `returnRoute` veriliyor. Tutarsızlık yok, kasıtlı fark var.

Import kontrolü: `loginBottomSheet` her çağıran dosyada `login_gerektiren_aksiyon.dart`'tan (doğrudan veya `shared/widgets/login_gerektiren_aksiyon.dart` göreli yoluyla) import ediliyor — `flutter analyze`'ın 0 error dönmesi bunu zaten doğruluyor (import eksik olsaydı derleme hatası verirdi).

## A8 — Proje genelinde `GirisGerekli` widget kullanımı

**Sadece 2 dosyada, toplam 1 kullanım yeri + 1 tanım:**
- `giris_gerekli_widget.dart:9-54` — `GirisGerekli extends StatelessWidget` tanımı. Parametreleri: `icon` (IconData), `mesaj` (String), `onGirisYap` (VoidCallback). **`returnRoute` veya `loginBottomSheet` ile ilgili hiçbir parametre yok** — tamamen ayrı, bağımsız bir sistem.
- `sana_ozel_screen.dart:49` — `return GirisGerekli(...)` çağrısı (tek kullanım yeri).

**Karışma riski yok:** `GirisGerekli` kendi içinde bağımsız bir Lottie animasyonu + mesaj + `onGirisYap` callback'i alan tam sayfa CTA widget'ı; `loginBottomSheet` ise bir `showModalBottomSheet` açan fonksiyon. İkisi de aynı 2 Lottie dosyasını (`bukalemun.json`/`timsah.json`) rastgele seçiyor (kod tekrarı var ama bu bugünün kapsamı dışında, önceden beri böyle) — parametre imzaları birbirine karışmıyor, `GirisGerekli`'ye yanlışlıkla `returnRoute` geçilmiş bir yer yok.

## Sonuç

**Bugünkü misafir-girişi değişikliklerinde yamalı/yarım kalmış, DOĞRULANMIŞ bir sorun var mı? HAYIR.**

`flutter analyze` 0 error, dört dosyadaki tüm diff'ler amaçlanan değişiklikle birebir örtüşüyor, `ilan_detay_screen.dart` dokunulmadan kalmış, `loginBottomSheet` ve `GirisGerekli` sistemleri birbirine karışmamış. Tek not: `login_gerektiren_aksiyon.dart`'ta art arda gelen iki `SizedBox` (24+16px) kozmetik bir küçük fazlalık — işlevsel değil, isteğe bağlı bir temizlik önerisi.

**Kapsam dışı gözlem (bilgi amaçlı):** repo kökünde bu konuşma sırasında oluşmuş görünen iki izlenmeyen (untracked) dosya var: `favoriler_login_diff.txt`, `login_sheet_uc_dosya_diff.txt`. Bu görevin kapsamında değiller ve dokunulmadı, ama kim oluşturduysa bilsin diye not düşülüyor.
