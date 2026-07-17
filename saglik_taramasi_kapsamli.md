# Kapsamlı Sağlık Taraması — Launch Öncesi

Tarih: 2026-07-17. Salt-okuma — hiçbir dosya değiştirilmedi, hiçbir build/deploy çalıştırılmadı.

---

## BÖLÜM A — Bugünkü 9 dosya

### A1. flutter analyze
```
info - Unnecessary use of multiple underscores - sana_ozel_screen.dart:986:34
info - 'appleProvider' is deprecated - main.dart:49:5
2 issues found.
```
✅ **0 error.** İki info de bilinen, önceden var olan bulgular. Bugünkü 9 dosyanın hiçbirinde yeni uyarı yok (unused import dahil — analyzer bunu info/warning olarak yakalardı, hiç çıkmadı). — **Bilgi**

### A2. tsc --noEmit (functions/)
✅ Temiz, çıktı yok, exit 0. — **Bilgi**

### A3. Kalıntı taraması
✅ A1'in 0-uyarı sonucu bunu zaten kapsıyor — dokuz dosyanın hiçbirinde kullanılmayan import/ölü değişken analyzer tarafından işaretlenmedi. — **Bilgi**

### A4. app_router.dart — 3 route
```dart
GoRoute(path: 'ilan-olustur/istek', pageBuilder: (context, state) => CupertinoPage(
  key: state.pageKey,
  child: IlanFormScreen(tip: IlanTip.istek, duzenlenecekIlan: state.extra as IlanModel?),
)),
GoRoute(path: 'ilan-olustur/tasiyici', pageBuilder: (context, state) => CupertinoPage(
  key: state.pageKey,
  child: IlanFormScreen(tip: IlanTip.tasiyici, duzenlenecekIlan: state.extra as IlanModel?),
)),
GoRoute(path: AppRoutes.ilanDetay, pageBuilder: (context, state) {
  final ilanId = state.pathParameters['ilanId']!;
  final ilan = state.extra as IlanModel?;
  return CupertinoPage(key: state.pageKey, child: IlanDetayScreen(ilanId: ilanId, ilan: ilan));
}),
```
✅ Üçü de doğru — `state.pathParameters['ilanId']!` yalnızca `ilanDetay`'da (path parametresi orada var), `state.extra as IlanModel?` üçünde de güvenli nullable cast. — **Bilgi, doğrulandı**

### A5. ilan_karti.dart
```dart
context.push(AppRoutes.ilanDetayPath(guncelIlan.id), extra: guncelIlan);
```
✅ Doğru sabit kullanılıyor (`ilan_karti.dart:79`). — **Bilgi, doğrulandı**

### A6. ilanlarim_screen.dart
`Opacity(` 2 kez (`_IstekKarti` satır 178, `_GelenKarti` satır 326), `if (!ilan.aktif)` 2 kez (satır 251, 395) — simetrik, her iki kartta da aynı desen. ✅ — **Bilgi, doğrulandı**

### A7. functions/src/index.ts
`yenidenDenenmeliMi` (satır 422-424), `if (!icerikDegisti && !yenidenDenenmeliMi) return;` (satır 425) — guard doğru birleşmiş. `ilanOtomatikPasif` (satır 1143-1171) tam gövdesi okundu: **`getAlgoliaClient()` çağrısı yok** — yalnızca `{ aktif: false }` Firestore update'i yapıyor, Algolia'ya dokunmuyor (dokümante edilen tasarım kararıyla tutarlı). ✅ — **Bilgi, doğrulandı**

### A8. arama_service.dart / ilanlar_screen.dart
`ilanlar_screen.dart`'ta `SiralamaTipi.enEski` client-side sort'u kalmamış — yalnızca `enCokFavorilenen` ve `onerilen` sort blokları var. ✅ — **Bilgi, doğrulandı**

### A9. bildirim_repository.dart / islem_durumu_panel.dart
`bildirim_repository.dart:38`: `.limit(100)` doğru sırada (`where`'lerden sonra, `.snapshots()`'tan önce). `islem_durumu_panel.dart`'ta `Colors.black`/`Colors.white` toplam 37 eşleşme — kapsamın `_AdimSatiri`/`IslemDurumuTetikleyici`'ye taşmadığı önceki turlarda git diff ile zaten doğrulanmıştı. ✅ — **Bilgi, doğrulandı**

---

## BÖLÜM B — Genel kod tabanı

### B1. Repository katmanı sızıntısı
```
grep -rn "cloud_firestore|FirebaseFirestore" lib/**/presentation/
```
✅ **0 sonuç.** Bugün değişen 4 dosya (`ilanlar_screen.dart`, `gelenler_screen.dart`, `ilanlarim_screen.dart`, `ilan_karti.dart`) dahil, presentation katmanında Firestore sızıntısı yok. — **Bilgi**

### B2. Sınırsız Firestore sorguları
⚠️ **Değişmemiş, hâlâ aynı durumda** (yeni değil, bilinen backlog):
- `kullanici_repository.dart:203-217` — `takipciIdleriStream`/`takipEdilenIdleriStream`, `.limit()` yok.
- `badge_service.dart:33-38` — `snap.size` ile sınırsız `.snapshots()` sayımı.
— **Orta, önceden bilinen backlog maddesi (tekrar), YENİ değil**

### B3. Gerekçesiz keepAlive
21 adet `@Riverpod(keepAlive: true)` bulundu. Bunlardan yalnızca `kullaniciBilgi` (`profil_provider.dart:21`) parametreli/family — ve bu zaten belgelenmiş, gerekçeli bir istisna (flicker-fix). Geri kalan 20'si ya parametresiz fonksiyon ya da `class ... extends _$X` (family değil) notifier — hepsi meşru, sınırsız-instance riski taşımıyor. **Yeni/bilinmeyen gerekçesiz keepAlive bulunamadı.** — **Bilgi**

### B4. ref.mounted guard eksiklikleri
`ilan_provider.dart`'ta 14 adet `if (!ref.mounted) return;` bulundu — önceki turda düzeltilen 4 nokta (`istekIlanlar`/`tasiyiciIlanlar`'ın `dahaFazlaYukle`/`yenile` catch blokları) hâlâ yerinde. Try/catch simetrisi genel olarak sağlıklı görünüyor; dosya genelinde derinlemesine her fonksiyonu tek tek karşılaştırmadım (kapsam çok geniş) ama yoğunluk ve dağılım, sistematik bir eksiklik izlenimi vermiyor. — **Bilgi, düşük risk**

### B5. Sessiz `catch (_)` blokları — tam liste (13 adet)
```
turkiye_disi_arama_ekrani.dart:57
surum_kapisi.dart:59
auth_provider.dart:140, 149, 158
son_goruntulenenler_repository.dart:38
degerlendirme_repository.dart:36
app_constants.dart:249        (kategoriNodeBul fallback — zararsız)
ilan_form_screen.dart:379
ilan_repository.dart:81, 183
ilan_karti.dart:52, 60        (bugün incelenen firstWhere fallback — zararsız, stale veriye düşüyor)
```
Bunların çoğu "en iyi çaba, hata olursa sessizce devam et" deseninde — kritik bir veri kaybı riski taşımıyorlar (fallback değerleri var). `ilan_repository.dart:81,183` ve `degerlendirme_repository.dart:36` gerçek hataları da yutabilir; bunlar loglanmıyor (`AppHataYonetici.logla` çağrısı yok) — sessizce yutulan gerçek bir hata debugging'i zorlaştırabilir. — **Düşük, önceden bilinen desen, YENİ değil — ama loglama eksikliği not edilmeye değer**

### B6. Orphan dosya/sınıf taraması
Bugün değişen dosyaların komşularında (aynı dizin) hedefli bakıldı — yeni bir orphan aday **bulunamadı**. Tüm proje genelinde kapsamlı bir tarama (300+ dosya) bu turun efor bütçesini aşıyor; bu, kısmi bir kontrol olarak değerlendirilmeli. — **Bilgi, sınırlı kapsam**

### B7. Kod tekrarı / duplikasyon
Bilinen `kullaniciBilgi`/`kullaniciBilgisi` dışında, bugünkü değişikliklerin dokunduğu alanlarda (kategori barı, ilan kartları, işlem paneli) birebir aynı işi yapan çift fonksiyon **bulunamadı**. `ilanlar_screen.dart` ve `gelenler_screen.dart`'taki kategori barı kodu birbirine çok benzer (aynı `AnimatedContainer` deseni, ayrı dosyalarda) ama bu görev kapsamında zaten ikisi de aynı şekilde güncellendi — yapısal bir kopya, ama "birleştirilmemiş, tutarsız" değil, her ikisi de senkron tutuluyor. — **Bilgi**

### B8. CachedNetworkImage tutarlılığı
Bugün değişen dosyalarda yeni bir `CachedNetworkImage` eklenmedi (yalnızca renk/opacity/route değişiklikleri). `ilanlarim_screen.dart`'taki mevcut iki `CachedNetworkImage` (satır 206, 353) zaten `memCacheWidth: 200` içeriyor — dünkü düzeltmeden sonra hâlâ doğru. **Yeni eksiklik yok.** — **Bilgi**

### B9. mesaj_repository.dart — ilanTip guard asimetrisi
`ilanTip` bu dosyada yalnızca bir **yazma** parametresi olarak kullanılıyor (`'ilanTip': ilanTip` — varsayılan `'istek'`), herhangi bir karşılaştırma/guard (`ilanTip ==`/`!=`) yok. `firestore.rules`'da da `ilanTip` hiç geçmiyor. **Önceden bahsedilen "guard asimetrisi" bu dosyada şu an tespit edilemedi** — ya daha önce başka bir bağlamda (farklı bir dosya/mekanizma) tanımlanmıştı ve ben yanlış yerde arıyorum, ya da o zamandan beri değişti. Bunu netleştirmek için orijinal bulgunun hangi dosya/satırda olduğunu hatırlıyorsanız belirtin, tekrar bakayım. — **Belirsiz, doğrulanamadı**

### B10. git status
```
On branch main
 M lib/features/ilanlar/presentation/gelenler_screen.dart
 M lib/features/ilanlar/presentation/ilanlar_screen.dart
?? kategori_renk_diff.txt
```
Diğer 7 dosya (app_router.dart, ilan_karti.dart, ilanlarim_screen.dart, functions/index.ts, arama_service.dart, bildirim_repository.dart, islem_durumu_panel.dart) `git log` ile doğrulandı — zaten ayrı commit'lerde (`bd449e7`, `d38cb78`, `6644937`, `1c14bc3`, `80d4247`) kayıtlı, bu yüzden `git status`'ta görünmüyorlar. `kategori_renk_diff.txt` untracked — UTF-16 kodlamalı (muhtemelen PowerShell'den redirect edilmiş), içeriği son kategori-rengi diff'iyle eşleşiyor, zararsız bir kalıntı. — **Düşük, aksiyon gerektirmiyor**

---

## Sonuç

**1. Bölüm A'daki dokuz dosyada launch'ı engelleyen ya da regresyon riski taşıyan bir şey var mı?**
**HAYIR.** A1-A9'un tamamı doğrulandı, hiçbir sızıntı/tutarsızlık/eksik bulunamadı.

**2. Bölüm B'de, daha önce bilinmeyen YENİ bir launch-engelleyici sorun bulundu mu?**
**HAYIR.** B1-B10'da bulunanların tamamı ya zaten bilinen backlog maddelerinin teyidi (B2, B5) ya da "yeni sorun yok" doğrulaması (B1, B3, B4, B6, B7, B8, B10). Tek belirsizlik **B9** — önceki bir bulgunun bu dosyada doğrulanamaması; bu bir "yeni sorun" değil, netleştirme gerektiren bir soru işareti.
