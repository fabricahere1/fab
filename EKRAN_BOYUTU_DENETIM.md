# Ekran Boyutu Uyumluluğu Denetimi

Bu rapor SALT-OKUMA bir statik kod analizinin sonucudur. Hiçbir dosya
değiştirilmedi, hiçbir build/run/cihaz testi yapılmadı. Amaç: uygulamanın
küçük telefon, büyük telefon ve tablet ekranlarında olası taşma/kırılma
risklerini kod okumasıyla tespit etmek.

**Önemli genel bulgu (Bölüm D'yi doğrudan etkiliyor):** `main.dart:141`,
`MediaQuery(...).copyWith(textScaler: TextScaler.noScaling)` — uygulama,
kullanıcının sistem genelinde ayarladığı font büyütme tercihini **tamamen
görmezden geliyor**. Bu, "büyük font → taşma" riskini pratikte ortadan
kaldırıyor (metinler her zaman tasarımdaki sabit boyutta render ediliyor),
ama bunun kendisi bir erişilebilirlik ödünü — görme zorluğu çeken
kullanıcılar sistem ayarlarından yazıyı büyütemiyor. Bölüm D bu bulguyu
temel alıyor.

---

## BÖLÜM A — Sabit Piksel Değerleri

### A.1 — Genel tarama

`grep -rn "width: [3-9][0-9][0-9]\b"` (300px ve üzeri sabit genişlik) taraması
projede yalnızca **tek bir sonuç** verdi:

**`lib/features/mesajlar/presentation/islem_durumu_panel.dart:58`**
```dart
child: Container(
  width: 300,
  height: double.infinity,
```
Bu, sohbet ekranındaki "İşlem Paneli"nin (anlaşma durumu takibi) genişliği —
`Align` içinde sağdan açılan bir panel olarak kullanılıyor (`sohbet_screen.dart:100-103`,
`Align(alignment: Alignment.centerRight, child: IslemDurumuPanel(...))`).

**Önem: Orta.** 300px sabit genişlik, **320px genişliğindeki bir ekranda**
(en dar yaygın Android cihazlar, ör. eski bütçe telefonlar) ekranın
**%94'ünü** kaplıyor — geriye yalnızca 20px kalıyor, panelin sol kenarındaki
"geri planı görme" hissi neredeyse kayboluyor ama **taşma/kırılma
oluşmuyor** (Align widget'ı taşan içeriği kırpmaz, panel her zaman
ekran genişliğinden küçük kalır çünkü 300 < 320). 360px ve üzeri (yaygın
orta-segment telefonlar) ekranlarda sorun yok. **Şüpheli/Doğrulanmadı:**
tam 300px'in altında bir ekran genişliği (ör. bazı eski/nadir cihazlarda
280-300px arası) varsa bu panel ekranı tamamen kaplayabilir — bu, statik
kod okumasıyla kesin doğrulanamaz, gerçek cihaz/emülatör testi gerektirir.

### A.2 — Bugün üzerinde çalışılan widget'lar

**`KesfetHeroBanner`** (`kesfet_vitrin_tab.dart:513-525`) ve **`_SanaOzelHeroBanner`**
(`sana_ozel_screen.dart` benzer desen) — `Container`'ın kendisinde **sabit
genişlik yok**, yalnızca sabit **yükseklik** (`SizedBox(height: 236)` /
`210`). Genişlik, sarmalayıcı `Padding(fromLTRB(10,8,10,4))` üzerinden
ekran genişliğine göre otomatik ayarlanıyor. **Önem: Düşük.** Dekoratif
ikonlar (`Positioned(right: 195, ...)` gibi) 320px genişlikte bile
container'ın (320-20=300px) içinde kalıyor — en sağdaki ikon `right: 195,
size: 34` için gereken minimum genişlik 229px, 300px'e rahatça sığıyor.
Taşma riski yok.

**"Haftanın Öne Çıkanları" kartı** (`ilanlar_screen.dart:949-950`, `cardW = 140.0`,
`cardH = 200.0`) — sabit değerler ama bu kartlar **yatay kaydırmalı
`ListView.builder`** (`scrollDirection: Axis.horizontal`) içinde. **Önem:
Düşük.** Sabit genişlikteki kartlar yatay bir listede sorun oluşturmaz —
ekran ne kadar dar olursa olsun kartlar kaydırılabilir kalır, yalnızca
ekrana sığan kart sayısı değişir (kırılma yok, bu normal ve beklenen bir
UX deseni).

**`GirisGerekli`** (`giris_gerekli_widget.dart:30-53`) ve **`_LoginSheet`**
(`login_gerektiren_aksiyon.dart:55-142`) — hiçbir büyük sabit genişlik
yok. `GirisGerekli` bir `Center`/`Column` (intrinsic boyut), `_LoginSheet`'teki
butonlar `width: double.infinity`. **Önem: Yok — risk tespit edilmedi.**

---

## BÖLÜM B — MediaQuery/LayoutBuilder Kullanımı

### B.1 — Kullanım oranı

```
Toplam .dart dosyası (lib/):        131
MediaQuery kullanan dosya sayısı:    22  (%17)
LayoutBuilder kullanan dosya sayısı:  1  (%1)
```

**Bulgu:** Duyarlı tasarım araçları (`MediaQuery`, `LayoutBuilder`) proje
genelinde **sınırlı** kullanılıyor — dosyaların yalnızca ~%17'si
`MediaQuery`'e dokunuyor, `LayoutBuilder` neredeyse hiç kullanılmıyor
(1 dosya). Bir yardımcı sınıf da var:

**`lib/shared/utils/app_layout.dart`** — `isCompact`/`isLarge`/`isTablet`/`fs()`
(font ölçekleme) fonksiyonları tanımlı, `MediaQuery.sizeOf`/`shortestSide`
eşiklerine göre. Ama bu sınıf **yalnızca 2 dosyada** kullanılıyor
(`ilan_detay_screen.dart`, `ilan_karti.dart`) — kendi başına iyi tasarlanmış
bir duyarlı-tasarım altyapısı var, ama proje genelinde neredeyse hiç
benimsenmemiş; 131 dosyanın yalnızca 2'si ondan faydalanıyor.

### B.2 — Grid/liste sütun sayısı

```
grep -rn "crossAxisCount" lib
favoriler_screen.dart:87            crossAxisCount: 2,
kesfet_bolum_detay_screen.dart:74   crossAxisCount: 2,
kesfet_screen.dart:329              crossAxisCount: 2,
gelenler_screen.dart:332            crossAxisCount: 2,
ilanlar_screen.dart:387             crossAxisCount: 3,
ilanlar_screen.dart:406             crossAxisCount: mod.kolonSayisi,
ilanlar_screen.dart:1244            crossAxisCount: 2,
filtre_ekrani.dart:387              crossAxisCount: 2,
ilan_karti.dart:513                 crossAxisCount: kolonSayisi,
```

**Kesin doğrulandı: TÜM `crossAxisCount` değerleri SABİT** (2 veya 3, ya da
çağıran ekrandan sabit bir int olarak geçirilen `kolonSayisi`/`mod.kolonSayisi`).
**Hiçbiri ekran genişliğine bölünerek hesaplanmıyor.** `ilan_karti.dart:39`'daki
tek istisna (`kartGenisligi = (MediaQuery.of(context).size.width - 24 - 12) / 3`)
yalnızca **kart YÜKSEKLİĞİNİ** (görsel oranını) hesaplamak için kullanılıyor,
sütun SAYISINI belirlemiyor — sütun sayısı orada da sabit `kolonSayisi == 3`
kontrolüyle geliyor.

**Önem: Orta (tablet/büyük ekran için).** Bir tablette (ör. 800px+ genişlik)
`crossAxisCount: 2` sabit kalması, her kartın çok geniş (aşırı gerilmiş)
görünmesine yol açar — bu bir taşma/kırılma değil, ama tasarım amacının
dışında bir görsel sonuç (bkz. Bölüm C).

---

## BÖLÜM C — Tablet/Büyük Ekran Durumu

### C.1 — Tablet-özel düzen var mı?

```
grep -rln "isTablet|shortestSide" lib → yalnızca app_layout.dart (tanım)
```

**Kesin doğrulandı: Hiçbir yerde tablet-özel bir düzen (2 sütunlu
master-detail, farklı grid yapısı vb.) uygulanmıyor.** `isTablet()`
fonksiyonu tanımlı ama hiçbir ekranda gerçek bir dallanma (`if (AppLayout.isTablet(context))`)
için çağrılmıyor — yalnızca `fs()` (font boyutu ölçekleme) üzerinden dolaylı
olarak, ve o da yalnızca 2 dosyada. **Sonuç: Tablette de aynı 2 sütunlu
telefon grid'i, aynı tek-sütunlu dikey akış kullanılıyor.**

**Önem: Orta.** 800-1200px genişliğindeki bir tablette, `crossAxisCount: 2`
sabit kaldığı için her ilan kartı ~380-580px genişliğe geriliyor —
tasarımın hedeflediği "kompakt kart" görünümü bozuluyor, kart içindeki
resim/metin oranları telefon için optimize edildiğinden aşırı büyük/boş
görünebilir. Bu, **kesin bir kırılma değil**, ama gözle görülür bir
"telefon uygulaması tablette gerilmiş" hissi yaratır.

### C.2 — Manifest/pubspec kısıtlaması

```
AndroidManifest.xml: screenOrientation/supports-screens/compatible-screens → hiçbiri yok
pubspec.yaml: ekran boyutu kısıtlaması yok
```

**Kesin doğrulandı: Hiçbir ekran boyutu/yoğunluk kısıtlaması tanımlı
değil.** Bu, Play Store'da **varsayılan olarak tüm ekran boyutlarının
(tablet dahil) desteklendiği** anlamına geliyor — yani tabletler
mağazada görünür/indirilebilir durumda, ama Bölüm C.1'de gösterildiği gibi
uygulama onlar için özel olarak tasarlanmamış. Bu bir çelişki: **tablet
kullanıcıları uygulamayı indirebiliyor ama gerilmiş bir telefon arayüzü
görüyor.**

---

## BÖLÜM D — Font/Erişilebilirlik Ölçeklendirmesi

`main.dart:138-143`:
```dart
builder: (context, child) {
  return MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.noScaling),
    child: BaglantiSarmalayici(child: child!),
  );
},
```

**Kesin doğrulandı: Uygulama genelinde `textScaler: TextScaler.noScaling`
zorlanıyor.** Bu, kullanıcının cihaz ayarlarından (Android Ayarlar >
Ekran > Yazı tipi boyutu) yaptığı büyütme/küçültme tercihini **tamamen
etkisiz kılıyor** — uygulama içindeki her `Text` widget'ı, sistem ayarı
ne olursa olsun, kodda yazılan `fontSize` değerini birebir kullanıyor.

**Sonuç — Bölüm D:** Görevde sorulan "kullanıcı font boyutunu büyütürse
sabit yükseklikli container'lar taşar mı" sorusunun cevabı **"hiçbir
zaman, çünkü böyle bir senaryo uygulama içinde hiç gerçekleşemiyor."**
Bu, bugünkü genel overflow taramasında bulunan `maxLines`/`ellipsis`
eksikliği olan yerlerle (varsa) çakışmıyor çünkü o riskler yalnızca
metnin kendisi (çeviri/kullanıcı girdisi) uzun olduğunda ortaya çıkar,
sistem font ölçeklendirmesinden bağımsızdır.

**Önem: Bilgi/Not (bug değil, bilinçli bir tasarım kararı gibi görünüyor)** —
ama bu, WCAG/erişilebilirlik açısından bir geri adım: görme zorluğu
yaşayan kullanıcılar metni büyütemiyor. Launch öncesi teknik bir risk
değil, ama ürün/erişilebilirlik kararı olarak bilinçli şekilde
alınıp alınmadığı netleştirilmeye değer.

---

## BÖLÜM E — Bugünkü Çalışmadan Riskli Widget'lar

### E.1 — `ilan_karti.dart` (masonry grid)

`_resimYuksekligi()` (`ilan_karti.dart:37-43`):
```dart
double _resimYuksekligi(BuildContext context) {
  if (kolonSayisi == 3) {
    final kartGenisligi = (MediaQuery.of(context).size.width - 24 - 12) / 3;
    return kartGenisligi * 1.0;
  }
  return resimYukseklikleri[ilan.id.hashCode.abs() % resimYukseklikleri.length];
}
```
**Önem: Düşük.** `kolonSayisi == 3` durumunda (yalnızca `ilanlar_screen.dart:387`'de
kullanılıyor) yükseklik doğru şekilde ekran genişliğinden hesaplanıyor — bu
kısım aslında **iyi bir örnek**, dar ekranlarda da orantılı kalıyor.
`kolonSayisi == 2` olan (favoriler, gelenler, kesfet gibi çoğu ekran)
durumda ise `kResimYukseklikleri = [176.0, 208.0, 160.0, 192.0, 224.0, 168.0]`
(`ilan_karti.dart:21`) — **sabit** yükseklik listesi, genişlikten
bağımsız. **Somut senaryo:** 320px genişlikte bir ekranda, 2 sütunlu bir
kart genişliği `(320-24-12)/2 ≈ 142px` olur; kartın resmi ise sabit 224px'e
kadar çıkabilir — bu, kartı **anormal derecede dikey/uzun** gösterir (dar
kart + yüksek resim oranı), taşma değil ama görsel dengesizlik riski
taşır. **Şüpheli/Doğrulanmadı:** Bunun gerçekten "kötü" görünüp
görünmeyeceği masonry grid'in genel tasarım diline bağlı (bilinçli bir
"çeşitlilik" efekti olabilir), kesin bir kırılma değil.

### E.2 — `swipe_karti.dart`

Kart konteynerinin kendisi `MediaQuery.of(context).size.width` ile doğru
şekilde hesaplanıyor (satır 198, 226, 274, 816-817) — **iyi pratik**. Alt
buton satırı (`Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)`,
satır 426-457) üç sabit boyutlu daire buton içeriyor (52+68+52 = 172px
toplam sabit genişlik) ama `spaceEvenly` aralarındaki **boşluğu** esnek
tutuyor, toplam genişliği zorlamıyor. **Önem: Düşük.** 172px, 320px
genişliğindeki en dar ekranlarda bile rahatça sığıyor (boşluklar sıkışır
ama butonlar asla kesilmez/taşmaz). Ürün başlığı/fiyat metinleri
(`swipe_karti.dart:706-746`) `maxLines`/`overflow: TextOverflow.ellipsis`
ile korunuyor — taşma riski yok.

### E.3 — `mesajlar_screen.dart` (`_SohbetKarti`)

Tüm ana metinler (`ilanBaslik`, `karsiAd`, `sonMesaj`) `maxLines: 1` +
`overflow: TextOverflow.ellipsis` ile korunuyor (satır 298-329). Sağdaki
`zamanYazi` metni (satır 353-364) `maxLines`/`overflow` içermiyor ama
içeriği her zaman kısa, önceden hesaplanmış string'ler (`'5 dk'`, `'2 gün'`,
tarih formatı) — **Önem: Düşük**, gerçek bir taşma senaryosu üretilemez
çünkü içerik uzunluğu kod tarafından sınırlı.

---

## ÖZET TABLO

| Bölüm | Bulgu | Dosya:Satır | Önem |
|---|---|---|---|
| A.1 | İşlem paneli 300px sabit genişlik | `islem_durumu_panel.dart:58` | Orta (320px altı ekranlarda doğrulanamadı) |
| A.2 | Hero banner'lar, "Öne Çıkanlar" kartı, giriş ekranları | — | Risk yok |
| B.1 | MediaQuery/LayoutBuilder kullanımı sınırlı (%17/%1) | — | Düşük (yapısal gözlem) |
| B.2 / C.1 | Tüm grid sütun sayıları sabit, tablet-özel düzen yok | 9 dosya, bkz. B.2 tablosu | **Orta** (tablette gerilmiş görünüm) |
| C.2 | Manifest'te ekran kısıtlaması yok → tabletler Play Store'da görünür | `AndroidManifest.xml` | Orta (C.1 ile birleşince) |
| D | `textScaler: TextScaler.noScaling` — font büyütme etkisiz | `main.dart:141` | Bilgi/erişilebilirlik notu |
| E.1 | `ilan_karti.dart` 2-sütun modunda sabit resim yüksekliği | `ilan_karti.dart:21,42` | Düşük/Şüpheli |
| E.2 | `swipe_karti.dart` — doğru MediaQuery kullanımı, taşma yok | — | Risk yok |
| E.3 | `_SohbetKarti` — ana metinler korunuyor | — | Risk yok |

---

## Launch öncesi acilen test edilmesi/düzeltilmesi gereken bir ekran boyutu sorunu var mı?

**Hayır, kesin/kritik bir "taşar veya kırılır" sorunu bulunamadı.** Statik
kod okumasıyla tespit edilen tüm bulgular en fazla **Orta** önemde ve
"görsel dengesizlik" seviyesinde — hiçbiri uygulamanın çökmesine, bir
ekranın kullanılamaz hale gelmesine, ya da kritik bir butonun erişilemez
olmasına yol açmıyor.

**Launch sonrası, öncelik sırasına göre bakılmaya değer:**

1. **Tablet deneyimi (Bölüm B.2/C.1/C.2)** — en somut, en yaygın etkilenecek
   grup. Manifest tabletleri kısıtlamadığı için Play Store'da görünür
   durumdalar, ama hiçbir ekran onlar için optimize edilmemiş. Ya
   `AppLayout.isTablet()` gerçekten kullanılıp grid sütun sayıları/max-genişlik
   sınırları eklenmeli, ya da (daha basit, hızlı bir çözüm olarak)
   `AndroidManifest.xml`'e tablet hariç tutma kısıtlaması eklenip bu konu
   bilinçli olarak launch sonrasına ertelenmeli.
2. **`islem_durumu_panel.dart:58` — 300px sabit genişlik** — yalnızca çok
   dar (320px altı) cihazlarda risk taşıyabilir, gerçek cihaz/emülatör
   testiyle doğrulanmalı (bu rapor kapsamında yapılamadı).
3. **`ilan_karti.dart` 2-sütun modunda sabit resim yüksekliği** — düşük
   öncelik, muhtemelen kasıtlı bir görsel çeşitlilik efekti, yine de dar
   ekranlarda gözle kontrol edilmeye değer.

Hiçbiri "acil" kategorisinde değil — hepsi launch sonrası, sakin bir
turda ele alınabilir.
