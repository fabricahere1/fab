# Genel Sağlık Taraması — Hero Banner Serisi Sonrası

Salt-okuma tarama. Hiçbir dosya değiştirilmedi, hiçbir komut deploy edilmedi.

---

## A. Bugünün hero banner değişikliklerine özel kontrol

### A1. flutter analyze — Bilgi, doğrulandı
```
Analyzing iste_v3...
info - Unnecessary use of multiple underscores - sana_ozel_screen.dart:984:34
info - 'appleProvider' is deprecated... - main.dart:49:5
2 issues found.
```
**0 error, 0 warning** — aynı 2 pre-existing/ilgisiz info dışında yeni bir uyarı
sızmamış. Analyzer'ın kendisi `unused_import`/`unused_element` gibi kuralları
zaten kapsıyor (flutter_lints), bu temiz sonuç "kullanılmayan import/ölü kod
yok" iddiasını da büyük ölçüde destekliyor.

### A2. Ölü kod / kalıntı — Bilgi, bulgu yok
`KesfetHeroBanner`'ın (`kesfet_vitrin_tab.dart:528-651`) ve `_SanaOzelHeroBanner`'ın
(`sana_ozel_screen.dart:784-868`) güncel gövdesini uçtan uca okudum — eski
Column yapısından, eski pill butondan, filigran bloğundan hiçbir kalıntı
değişken/fonksiyon/yorum satırı kalmamış. Kod, son halinin (120x160 Stack+
gradyan) temiz bir yansıması.

### A3. CicekBaslikPainter / KartZeminPainter — Bilgi, ikisi de aktif kullanımda
- `CicekBaslikPainter` (`kesfet_vitrin_tab.dart:279-298`) — grep'te tanım dışında
  başka referans bulunamadı; **muhtemelen orphan** ama bu bugünün değişikliğiyle
  ilgili değil (hero banner görevleri bu sınıfa hiç dokunmadı) — ayrı, önceden
  var olabilecek bir bulgu, aşağıda E bölümüne not düşüldü.
- `KartZeminPainter` (`kesfet_vitrin_tab.dart:397-523`) — hem `kesfet_vitrin_tab.dart`
  içinde (2 nokta) hem `sana_ozel_screen.dart`'ta (3 nokta, `show` ile import
  edilerek) aktif kullanılıyor. Orphan değil.

### A4. Duplicate değişken/parametre — Bilgi, bulgu yok
İki widget'ın da `build()` metodunu satır satır okudum, aynı widget içinde iki
kez tanımlanmış bir değişken/parametre yok.

### A5. **Keşfet vs Sana Özel hero banner tutarsızlığı — Orta, BUGÜN ORTAYA ÇIKTI**
**Dosya:** `kesfet_vitrin_tab.dart:597-644` vs `sana_ozel_screen.dart:836-855`

Bugünkü seri görevlerin çoğu **yalnızca `kesfet_vitrin_tab.dart`'a** (KesfetHeroBanner)
uygulandı — spec'ler bunu bilinçli olarak kapsam dışı bıraktı ("_SanaOzelHeroBanner'a
dokunulmuyor, ayrı bir karar gerektirir"). Sonuç olarak şu an iki banner **görsel
olarak tutarsız**:

| | KesfetHeroBanner | _SanaOzelHeroBanner |
|---|---|---|
| Kart boyutu | 120×160 | 95×120 |
| Kart içeriği | Stack + alt gradyan + ürün adı/güzergah yazısı | yalnızca resim (yazı yok) |
| Banner yüksekliği | 236 | 210 |
| Dış çerçeve rengi | `#7C3AED` mor, 1px | `#7C3AED` mor, 1px (aynı — son görevde ikisine de uygulandı) |

Dış çerçeve rengi tutarlı hale getirildi (son görev ikisine de uygulandı), ama
kart boyutu/içeriği hâlâ farklı. Bu bir **kod hatası değil** — her görev kendi
kapsamını doğru uyguladı — ama kullanıcı iki ekran arasında geçiş yaptığında
("Keşfet" ↔ "Sana Özel" sekmeleri) hero banner'ların birbirinden oldukça farklı
görünmesi kasıtsız bir tutarsızlık hissi yaratabilir. Görev talimatlarında da
("iki farklı ama tutarlı vurgu görünmeli" — çerçeve rengi görevinden) tutarlılık
hedeflendiği görülüyor; kart seviyesinde bu hedefe henüz ulaşılmadı.

**Önerilen düzeltme yönü:** Eğer tutarlılık isteniyorsa, `_SanaOzelHeroBanner`'ın
kartlarına da aynı 120×160 Stack+gradyan+metin deseni bilinçli bir sonraki
görevle uygulanabilir. İstenmiyorsa (Sana Özel'in kendi kişiselleştirilmiş
görünümü kasıtlıysa) bu bulgu kapatılabilir — bir tasarım kararı, kod
kalitesiyle ilgili değil.

### A6. Koşullu güzergah mantığı — Bilgi, yalnızca Keşfet'te var, tutarlı
`kesfet_vitrin_tab.dart:632-634`:
```dart
ilan.tip == IlanTip.istek
    ? '→ ${ilan.nereye}'
    : '${ilan.nereden} → ${ilan.nereye}',
```
`IlanTip` içe aktarımı doğru (`app_constants.dart`, satır 14), `flutter analyze`
0 error ile derleme doğruluğunu zaten teyit ediyor. `_SanaOzelHeroBanner`'da bu
mantık hiç yok (A5'te açıklandığı gibi, kartlarında hiç metin katmanı yok) —
"tutarsız uygulanmış" değil, "hiç uygulanmamış", çünkü görev kapsamı oraya
girmedi. Görev talimatındaki "eğer Sana Özel'e de uygulandıysa" koşulu zaten bu
durumu öngörmüştü.

---

## B. Repository kaçakları — Bilgi, temiz

`grep -rn "cloud_firestore\|FirebaseFirestore" lib/features/*/presentation/`
**sıfır sonuç.** `home/presentation/` klasörü (bugün en çok değişen) özellikle
kontrol edildi, temiz.

---

## C. Performans

### C1. Limitsiz Firestore sorguları — Orta, önceden bilinen, DEĞİŞMEMİŞ
- `kullanici_repository.dart:203,211,222` — `takipciIdleriStream`,
  `takipEdilenIdleriStream`, `takipEdilenTarihleriStream` — üçü de hâlâ
  `.limit()` yok.
- `badge_service.dart:38` — hâlâ `snap.size` ile sayıyor, `count()` aggregate'e
  geçilmemiş.

### C2. keepAlive family provider'lar — Yüksek, KISMEN İYİLEŞTİ, hâlâ 3 açık kalem
Tüm `@Riverpod(keepAlive: true)` işaretli provider'lar (10 dosya) tarandı.
**Önemli fark, önceki taramaya göre:** `kullaniciBilgisi` (`profil_provider.dart:204-207`)
artık `@riverpod` (autoDispose) — **düzeltilmiş**, artık keepAlive DEĞİL. Bu iyi
haber, ama neden/ne zaman değiştiği bu oturumun görevlerinden anlaşılmıyor
(hero banner görevleri bu dosyaya hiç dokunmadı) — muhtemelen ayrı bir yerde
ele alınmış.

Hâlâ açık olan 3 gerekçesiz, sınırsız-parametreli `keepAlive` family provider:
- `kullaniciBilgi(Ref ref, String uid)` — `profil_provider.dart:21-24` (**hâlâ keepAlive**)
- `takipEdiyorMu(Ref ref, String takipEdilenId)` — `profil_provider.dart:244-263` (**hâlâ keepAlive**)
- `karsiKullaniciAd(Ref ref, String uid)` — `mesaj_provider.dart:42-53` (**hâlâ keepAlive**)

Ek gözlem: `kullaniciBilgi` ve `kullaniciBilgisi` artık davranış olarak farklı
(biri keepAlive, diğeri autoDispose) ama gövdeleri birebir aynı
(`kullaniciRepositoryProvider.kullaniciGetir(uid)` çağırıyorlar) — bu isim
benzerliği + davranış farkı gelecekte "hangisini çağırmalıyım" karışıklığına
yol açabilir (bkz. E bölümü, duplikasyon notu).

### C3. CachedNetworkImage/Image.network tutarlılığı — Bilgi, değişmemiş
`Image.network(` proje genelinde hâlâ yalnızca 2 sonuç, ikisi de orphan
dosyalarda (`kullanici_profil_panel.dart:471`, `ilan_banner.dart:150`) — aktif
ekranlarda tutarsızlık yok.

---

## D. Bug taraması

### D1. ref.mounted guard eksiklikleri — Orta, önceden bilinen, DEĞİŞMEMİŞ
`ilan_provider.dart` içinde 4 nokta hâlâ aynı asimetriyi taşıyor (try'da guard
var, catch'te state yazan ama guard'sız):
- `istekIlanlar.yenile()` catch — satır 130-132
- `istekIlanlar.dahaFazlaYukle()` catch — satır 156-158
- `tasiyiciIlanlar.yenile()` catch — satır 251-253
- `tasiyiciIlanlar.dahaFazlaYukle()` catch — satır 277-279

Karşılaştırma: aynı dosyadaki `FavoriNotifier.ekle()`/`cikar()` (satır 650-652,
667-668) doğru deseni gösteriyor (`if (!ref.mounted) return;` hem try hem
catch'te). Proje genelinde bu asimetri hâlâ yalnızca `ilan_provider.dart`'a
özgü, izole bir eksiklik.

### D2. Sessiz catch (_) blokları — Orta/Düşük, önceden bilinen, DEĞİŞMEMİŞ
Önceki taramalarda tespit edilen 12 nokta içinden gerçekten log'suz+sessiz olan
ikisi hâlâ aynı: `turkiye_disi_arama_ekrani.dart:57`, `son_goruntulenenler_repository.dart:38`.
Diğerleri (auth_provider.dart, ilan_repository.dart, ilan_form_screen.dart,
ilan_karti.dart, surum_kapisi.dart, degerlendirme_repository.dart,
app_constants.dart) ya kullanıcıya görünür hata döndürüyor ya bilinçli
fail-open/fallback deseni — risk taşımıyor.

### D3. mesaj_repository.dart ilanTip asimetrisi — Orta, önceden bilinen, DEĞİŞMEMİŞ
`mesajGonder()` içinde `'ilanTip': ilanTip` (satır 133) hâlâ guard'sız/koşulsuz;
`efektifIlanBaslik`/diğerleri (satır 141+) hâlâ `if (...isNotEmpty)` guard'lı.
F3'te bilinçli olarak ertelenmişti, durum aynı.

### D4. Koşullu güzergah mantığı — bkz. A6 (bugünün konusu, ayrı D maddesi
gerektirmiyor, A bölümünde ele alındı).

---

## E. Orphan/duplikasyon

### E1. 4 dosya hâlâ orphan — Düşük, önceden bilinen, DEĞİŞMEMİŞ
Sınıf adlarıyla (dosya adı değil) gerçek referans taraması yapıldı:
- `register_screen.dart` (`RegisterScreen`) — hâlâ orphan.
- `kullanici_profil_panel.dart` (`KullaniciProfilPanel`) — hâlâ orphan.
- `arama_widgetlari.dart` (6 sınıf: `AramaCubugu`, `SiralamaButon`, `FiltreButon`,
  `GridToggleButon`, `FiltreBadge`, `KategoriBar`) — hâlâ orphan.
- `ilan_banner.dart` (`IlanBanner`) — hâlâ orphan.

### E2. Beden sabitleri duplikasyonu — Düşük, önceden bilinen, DEĞİŞMEMİŞ
`_kKadinUstHarf`, `_kErkekBeden` hâlâ hem `profil_tamamla_screen.dart:45,49`
hem `profil_duzenle_screen.dart:21,25` içinde ayrı ayrı tanımlı, içerikleri
birebir aynı, `app_constants.dart`'a taşınmamış.

### E3. **Yeni orphan aday — `CicekBaslikPainter`** — Düşük, İLK KEZ NOT EDİLDİ
`kesfet_vitrin_tab.dart:279-298` — tanımı dışında hiçbir referans bulunamadı.
Bugünün görevleriyle ilgisi yok (hiçbiri bu sınıfa dokunmadı), muhtemelen daha
önceden orphan hale gelmiş, bu ilk kez fark edildi. Doğrulama: `grep -rn
"CicekBaslikPainter" lib` yalnızca tanım satırlarını (class, constructor,
shouldRepaint) döndürdü, hiçbir `CustomPaint(painter: CicekBaslikPainter(...))`
çağrısı yok.

### E4. **Repo kökünde untracked debug artifact — `kart_kod.txt`** — Düşük, İLK KEZ NOT EDİLDİ
Repo kökünde `git status`'ta untracked olarak görünen, UTF-16 kodlamalı bir
`git diff` çıktısı içeren dosya (132 satır, muhtemelen bir önceki turda
`git diff > kart_kod.txt` gibi bir komuttan kalma). Kodu etkilemiyor, ama repo
hijyeni açısından temizlenmesi/`.gitignore`'a eklenmesi önerilir — kod
değişikliği değil, dosya yönetimi kararı.

---

## Özet

**Kritik seviyede, launch'ı engelleyen bir şey var mı? HAYIR.**

`flutter analyze` 0 error, repository katmanı temiz, dispose/cancel disiplini
(önceki taramalarda doğrulanmıştı) korunuyor. Bugünkü hero banner serisi kendi
içinde tutarlı ve temiz uygulanmış — kalıntı kod, kullanılmayan import,
duplicate değişken yok.

**Yeni ortaya çıkan tek dikkat noktası (Orta):** Keşfet ve Sana Özel hero
banner'larının artık görsel olarak belirgin şekilde farklı olması (A5) — bir
tasarım kararı bekliyor, kod hatası değil.

**Değişmeyen, launch'ı engellemeyen açık kalemler (Orta/Düşük, hepsi önceden
bilinen):** 3 gerekçesiz keepAlive family provider (C2 — bir tanesi bu arada
düzeltilmiş), `ilan_provider.dart`'taki 4 `ref.mounted` asimetrisi (D1),
`mesajTip` guard asimetrisi (D3), limitsiz takipçi/badge sorguları (C1), 4
orphan dosya + 1 yeni orphan aday (E1, E3), beden sabiti duplikasyonu (E2),
untracked debug dosyası (E4). Hiçbiri bugünün regresyonu değil, hiçbiri acil
değil.
