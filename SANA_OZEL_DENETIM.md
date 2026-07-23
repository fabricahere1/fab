# Sana Özel Denetimi — Kişiselleştirme Sistemi Doğrulama Raporu

Bu rapor SALT-OKUMA bir denetimin sonucudur. Hiçbir dosya değiştirilmedi.
Amaç: "Sana Özel" sekmesindeki kişiselleştirme mantığının (kategori/beden
eşleştirme, sıralama, boş durum davranışı) gerçekten doğru çalışıp
çalışmadığını doğrulamak.

---

## BÖLÜM A — Kullanıcı Tercihleri Doğru Okunuyor mu

### A.1 — Kişiselleştirme alanları (`kullanici_model.dart:9-42`)

| Alan | Tip | Nerede dolduruluyor |
|---|---|---|
| `kullaniciTipi` | `String` | `profil_tamamla_screen.dart` (kayıt akışı, Adım 1) |
| `yasadigiUlke` | `String` | `profil_tamamla_screen.dart` — `_kYasadigiUlkeler` sabit listesinden seçim |
| `bulunduguSehir` | `String` | `profil_tamamla_screen.dart` |
| `geldigiSehirler` | `List<String>` | `profil_tamamla_screen.dart` (taşıyıcı tarafı — seyahat edeceği şehirler) |
| `ilgiKategorileri` | `List<String>` | `profil_tamamla_screen.dart:1067-1070` — **yalnızca `_kullaniciTipi != 'tasiyici'` iken gösteriliyor**, yani yalnızca istekçiler bu alanı dolduruyor. `profil_duzenle_screen.dart:86,177` üzerinden de güncellenebiliyor. |
| `dutyFreeIlgileniyor` | `bool?` | Profil ekranlarında toplanıyor (kullanılmadığı Bölüm B.3'te not edildi) |
| `kadinUstBeden`/`kadinAltBeden`/`erkekUstBeden`/`erkekAltBeden`/`kadinAyakkabi`/`erkekAyakkabi`/`cocukAyakkabi` | `List<String>` | `profil_tamamla_screen.dart` — `_kKadinUstHarf`, `_kKadinUstNumarik`, `_kErkekBeden`, `_kAyakkabiKadin`, `_kAyakkabiErkek`, `_kAyakkabiCocuk` sabit listelerinden çoklu seçim |

**Sonuç — A.1: DOĞRU ÇALIŞIYOR.** Alanlar iki ekrandan (`profil_tamamla_screen.dart`, `profil_duzenle_screen.dart`) tutarlı şekilde dolduruluyor, model alanlarıyla isim/tip uyumu doğrulandı.

### A.2 — Provider sorgu mantığı (`sana_ozel_providers.dart`)

Tüm provider'ların TAM kodu okundu (dosyanın tamamı, 283 satır). Özet tablo:

| Provider | Sorgu mantığı |
|---|---|
| `sehirGelecekIlanlar` (:19-28) | `tasiyiciIlanlarProvider` → `nereye.toLowerCase() == profil.bulunduguSehir.toLowerCase()` |
| `kategorilereGoreIlanlar` (:32-43) | `tasiyiciIlanlarProvider` → `ilgiKategorileri` seti `anaKategori` veya `kategori` ile kesişiyor mu |
| `bedenGoreIlanlar` (:47-80) | `_bedenEslesiyor()` yardımcı fonksiyonu — bkz. Bölüm B.2 |
| `populerKategoriIstekleri` (:84-95) | `istekIlanlarProvider` → kategori eşleşmesi + `favoriSayisi`'ne göre azalan sıralama, ilk 20 |
| `dutyFreeYapabilecekIlanlar` (:99-105) | `tasiyiciIlanlarProvider` → yalnızca `i.sahipDutyFree` — bkz. Bölüm B.3 |
| `gecmisGoruntulenenlereBenzerIlanlar` (:110-130) | `sonGoruntulenenlerProvider`'daki kategorilerle eşleşen, henüz görülmemiş ilanlar |
| `favoriKategorilerYeniIlanlar` (:135-161) | Favorilerin kategorileriyle eşleşen, son 7 günde açılmış, favorilenmemiş ilanlar |
| `takipEdilenTasiyicilarinYeniIlanlari` (:165-179) | Takip tarihinden SONRA açılmış ilanlar |
| (Taşıyıcı tarafı) `seyahatSehriIlanlar`, `kargoKabulIstekler`, `eldenKabulIstekler`, `onayliIstekler`, `favoriKategorilerYeniIstekIlanlari`, `takipEdilenIstekcilerinYeniIlanlari` | Aynı desenlerin istekçi/taşıyıcı simetriği |

**Sonuç — A.2: DOĞRU ÇALIŞIYOR** (beden hariç — bkz. B.2).

---

## BÖLÜM B — Eşleştirme Mantığı Gerçekten Doğru mu

### B.1 — Kategori eşleştirmesi: **DOĞRU ÇALIŞIYOR**

`ilgiKategorileri` değerleri (`profil_tamamla_screen.dart:37-43`, `_kIlgiKategoriler`):
```
'kadin_giyim', 'erkek_giyim', 'cocuk_giyim', 'elektronik', 'ev'
```

İlan tarafındaki kategori ağacı (`app_constants.dart:74-125`, `kKategoriAgaci`):
```
KategoriNode(key: 'kadin', altlar: [KategoriNode(key: 'kadin_giyim', ...), KategoriNode(key: 'kadin_ayakkabi', ...), ...])
KategoriNode(key: 'erkek', altlar: [KategoriNode(key: 'erkek_giyim', ...), ...])
KategoriNode(key: 'cocuk', altlar: [KategoriNode(key: 'cocuk_giyim', ...), ...])
KategoriNode(key: 'ev', altlar: [...])
KategoriNode(key: 'elektronik', altlar: [...])
```

`kategorilereGoreIlanlar` (:39-41):
```dart
kategoriler.contains(i.anaKategori) || kategoriler.contains(i.kategori)
```

**Format tam uyumlu — büyük/küçük harf, snake_case, tüm değerler birebir aynı.** Semantik olarak da doğru: `ilgiKategorileri`'nde `'kadin_giyim'` gibi bir alt-kategori (leaf) seçilmişse, ilanın `kategori` alanı (leaf) ile eşleşiyor (yalnızca giyim, ayakkabı/güzellik dahil değil — bu bilinçli bir tasarım, aşırı geniş eşleşme değil). `'elektronik'`/`'ev'` gibi doğrudan ana-kategori seviyesinde seçilenler ise `anaKategori` ile eşleşiyor. İki farklı granülerlik seviyesi (`anaKategori` VEYA `kategori`) OR ile birleştirildiği için her iki durumda da doğru çalışıyor. String encoding/casing uyuşmazlığı **yok**.

### B.2 — Beden eşleştirmesi: **BOZUK — 2 AYRI DOĞRULANMIŞ BUG**

`_bedenEslesiyor()` (`sana_ozel_providers.dart:57-80`):
```dart
bool _bedenEslesiyor(IlanModel ilan, KullaniciModel profil) {
  final b = ilan.beden.trim();
  if (b.isEmpty) return false;
  switch (ilan.cinsiyet.toLowerCase()) {
    case 'kadin':
      return profil.kadinUstBeden.contains(b) ||
          profil.kadinAltBeden.contains(b) ||
          profil.kadinAyakkabi.contains(b);
    case 'erkek':
      return profil.erkekUstBeden.contains(b) ||
          profil.erkekAltBeden.contains(b) ||
          profil.erkekAyakkabi.contains(b);
    case 'cocuk':
      return profil.cocukAyakkabi.contains(b);
    default:
      return profil.kadinUstBeden.contains(b) ||
          profil.kadinAltBeden.contains(b) ||
          profil.kadinAyakkabi.contains(b) ||
          profil.erkekUstBeden.contains(b) ||
          profil.erkekAltBeden.contains(b) ||
          profil.erkekAyakkabi.contains(b) ||
          profil.cocukAyakkabi.contains(b);
  }
}
```

İlan tarafındaki gerçek `cinsiyet` değerleri (`ilan_form_screen.dart:1240-1242`):
```dart
List<String> get _cinsiyetler => tip == BedenTipi.cocuk
    ? ['Kız', 'Erkek', 'Unisex']
    : ['Kadın', 'Erkek', 'Unisex'];
```

**BUG 1 — "Kadın" hiçbir zaman `case 'kadin'`'e düşmüyor (Türkçe ı/i karakter uyuşmazlığı).**

`'Kadın'` kelimesindeki son "ı" Türkçe **noktasız ı** (U+0131), kod içindeki `case 'kadin':` ise **noktalı i** (U+0069) ile yazılmış. Dart'ın `toLowerCase()`'i locale-aware değildir; noktasız "ı" zaten küçük harf kabul edildiği için hiçbir dönüşüme uğramaz. Ampirik olarak doğrulandı:

```
'Kadın'.toLowerCase()            → "kadın"   (codeUnits: [107, 97, 100, 305, 110])
'kadin'  (literal, kodda yazılı) → "kadin"   (codeUnits: [107, 97, 100, 105, 110])
'Kadın'.toLowerCase() == 'kadin' → false
```

Sonuç: **kadın ilanları asla `case 'kadin':` dalına girmiyor**, doğrudan `default:` dalına düşüyor. `default` dalı kadın/erkek/çocuk TÜM beden listelerini birlikte kontrol ettiği için:
- Kadın bir ilan, kullanıcının yalnızca `erkekUstBeden`'inde olan bir beden değeriyle (ör. ikisi de "M" gibi ortak harf-beden kullanıyorsa) **yanlışlıkla eşleşebilir** (kadın ilanı, erkek bedenine göre öneriliyor).
- Ya da tam tersi, kullanıcının GERÇEKTEN `kadinUstBeden` alanında beden bilgisi varsa bu zaten `default` içinde de kontrol edildiği için o kısım için yanlış pozitif değil ama tasarım niyeti olan "yalnızca kadın bedenine bak" mantığı hiç çalışmıyor — sonuç kazayla doğru gelebilir ama bu **doğru tasarımdan değil, geniş `default` davranışından** kaynaklanıyor.

**BUG 2 — "cocuk" case'i tamamen ölü kod (unreachable).**

`case 'cocuk':` yalnızca `ilan.cinsiyet.toLowerCase() == 'cocuk'` olduğunda çalışır. Ama `ilan_form_screen.dart:1240-1242`'de görüldüğü gibi, çocuk kategorisindeki bir ilanın `cinsiyet` alanı **hiçbir zaman `"cocuk"` yazmıyor** — yalnızca `"Kız"`, `"Erkek"` veya `"Unisex"` değerlerini alıyor. Doğrulandı: `grep -rn "cinsiyet.*=.*'[Cc]ocuk"` proje genelinde **sıfır sonuç** verdi.

Sonuç: **`case 'cocuk':` hiçbir zaman tetiklenmiyor.** Bir çocuk ürünü (ör. `cinsiyet: 'Erkek'`, `beden: '30'` — çocuk ayakkabı numarası) `.toLowerCase()` sonrası `'erkek'` olduğu için `case 'erkek':` dalına düşer, bu dal ise `erkekUstBeden`/`erkekAltBeden`/`erkekAyakkabi` (yetişkin erkek bedenleri, ör. ayakkabı 38-48) listeleriyle karşılaştırır — çocuk ayakkabı numarası (25-35 aralığı) bu listelerde **asla bulunamaz**. `cocukAyakkabi` alanı Firestore'da dolu olsa bile hiçbir zaman kontrol edilmiyor.

**Sonuç — B.2: ŞÜPHELİ/BOZUK, DOĞRULANDI.** Önceki raporun şüphesi ("hiçbir ilan eşleşmez") tam olarak "sıfır eşleşme" değil ama iki ayrı, kanıtlanmış, kod-seviyesinde kesin bug var:
1. Kadın ilanları için niyet edilen dar eşleştirme hiç çalışmıyor, geniş `default`'a düşüyor (yanlış pozitif/negatif riski).
2. Çocuk ürünleri için `cocukAyakkabi` alanı fiilen hiçbir zaman kullanılmıyor (çocuk ayakkabı numaraları yetişkin ayakkabı listeleriyle karşılaştırılıyor, hiç eşleşmiyor).

### B.3 — `dutyFreeYapabilecekIlanlar`: **DOĞRU ÇALIŞIYOR (profil bağımsız, doğrulandı)**

```dart
@riverpod
List<IlanModel> dutyFreeYapabilecekIlanlar(Ref ref) {
  return ref
      .watch(tasiyiciIlanlarProvider)
      .filtrelenmis
      .where((i) => i.sahipDutyFree)
      .toList();
}
```

`profil`'e hiç referans yok, yalnızca `ilan.sahipDutyFree` bayrağına bakıyor. Önceki raporda belirtilen "profil bağımsız" iddiası **doğrulandı** — bu, kasıtlı bir tasarım (duty-free yapabilecek TÜM taşıyıcıları göster, kullanıcının `dutyFreeIlgileniyor` tercihine bakmaksızın). Not: `dutyFreeIlgileniyor` alanı modelde var ama bu provider'da (ya da denetlenen başka hiçbir provider'da) hiç okunmuyor — yani kullanıcı bu tercihi doldursa da hiçbir filtrelemede kullanılmıyor. Bu bug değil, kapsam dışı bir gözlem (görev metninde "profil bağımsız olduğu belirtilmişti" ifadesiyle zaten uyumlu).

---

## BÖLÜM C — Sıralama (oneriSkoru) Gerçekten Uygulanıyor mu

### C.1/C.2 — Sonuç: **ŞÜPHELİ/BOZUK — oneriSkoru Sana Özel'de HİÇ kullanılmıyor**

`grep -rln "oneriSkoru" lib` sonucu yalnızca 4 dosya:
```
lib/features/home/providers/kesfet_vitrin_providers.dart
lib/features/ilanlar/data/ilan_repository.dart
lib/features/ilanlar/presentation/ilanlar_screen.dart
lib/shared/utils/oneri_skoru.dart
```

`sana_ozel_providers.dart` ve `sana_ozel_screen.dart` bu listede **yok** — ne import ne kullanım var (doğrulandı: `grep -n "oneriSkoru\|sort(" sana_ozel_screen.dart` sıfır sonuç verdi).

`sana_ozel_providers.dart` içinde yalnızca 2 provider kendi lokal sıralamasını yapıyor:
- `populerKategoriIstekleri` → `favoriSayisi`'ne göre azalan sıralama (:92)
- `favoriKategorilerYeniIlanlar` / `favoriKategorilerYeniIstekIlanlari` → `olusturmaTarihi`'ne göre azalan sıralama (:158-159, :261-262)

Geri kalan TÜM provider'lar (`kategorilereGoreIlanlar`, `bedenGoreIlanlar`, `dutyFreeYapabilecekIlanlar`, `takipEdilenTasiyicilarinYeniIlanlari`, `sehirGelecekIlanlar`, `gecmisGoruntulenenlereBenzerIlanlar`, ve taşıyıcı tarafı eşdeğerleri) **hiçbir sıralama uygulamıyor** — sonuç, kaynak provider'ın (`tasiyiciIlanlarProvider`/`istekIlanlarProvider`) döndürdüğü ham sırada geliyor (muhtemelen Firestore sorgu sırası, örn. `olusturmaTarihi` azalan — ama bu proje kararı olarak `oneriSkoru`'nun "ilgi" bileşenini hiç yansıtmıyor).

**Sonuç:** `oneriSkoru()` formülü **var, doğru test edilmiş** (golden-value testleri geçiyor — önceki tur), **ama Sana Özel ekranının hiçbir bölümünde çağrılmıyor.** Bu, formülün "kullanılmayan kod" olduğu anlamına gelmez (Keşfet ve İlanlar sekmelerinde aktif kullanılıyor), ama Sana Özel'in kişiselleştirilmiş bölümleri kendi içinde `oneriSkoru`'ya göre alaka sırasına dizilmiyor — yalnızca filtreleniyor.

---

## BÖLÜM D — Gerçek Veriyle Örnek Doğrulama

**Kod okuması ile doğrulandı, canlı veriyle/fake_cloud_firestore ile test edilmedi.** Bu görev SALT-OKUMA kapsamında tutuldu; `bedenGoreIlanlar` ve `kategorilereGoreIlanlar` için mevcut `fake_cloud_firestore` altyapısı (önceki turlarda `takipEt()`/`takipiBirak()` testlerinde kullanılmıştı) teorik olarak bu senaryoyu simüle edebilir, ama bu, Riverpod provider'larının (`Ref` üzerinden okunan, generated `.g.dart` kodlu) izole test edilmesini gerektirir — kapsam dışı bırakıldı. B.2'deki bug'lar zaten statik kod okumasıyla (Dart `toLowerCase()` davranışının ampirik testi dahil) yeterince kesin doğrulandığı için, canlı veri testi ek bir kanıt sağlamayacaktı.

---

## BÖLÜM E — Boş Sonuç Senaryosu (sessiz boşluk mu, fallback mı)

`sana_ozel_screen.dart:106-115` (istekçi tarafı):
```dart
final tumu = [
  _BolumData('Senin şehrine gelecek taşıyıcılar', ...),
  _BolumData('Senin kategorilerin', kategoriler, ...),
  _BolumData('Senin bedenine göre ilanlar', ref.watch(bedenGoreIlanlarProvider), ...),
  ...
].where((b) => b.ilanlar.isNotEmpty).toList();
```

Ve satır 130-136:
```dart
final items = <Widget>[
  if (profilBannerVar) const _ProfilTamamlaBanner(),
  _SanaOzelHeroBanner(ilanlar: bannerListe),
  if (sectionWidgets.isEmpty)
    SizedBox(..., child: const _BosEkran(mesaj: 'Henüz sana özel içerik yok...'))
  else
    ...sectionWidgets,
  const _IlanAcCagriBolumu(),
];
```

**Sonuç — E: SESSİZ BOŞLUK, DOĞRULANDI.** `.where((b) => b.ilanlar.isNotEmpty)` filtresi, herhangi bir bölümün (ör. `bedenGoreIlanlar`) boş dönmesi durumunda o bölümü **listeden tamamen çıkarıyor** — ne bir uyarı, ne bir "bu bölüm boş" mesajı, ne bir görsel iz bırakıyor. `_BosEkran` fallback'i yalnızca **TÜM bölümler birden boşsa** devreye giriyor (satır 130: `sectionWidgets.isEmpty`).

Bu, tam olarak görevde tarif edilen "tespit edilmesi en zor türden bug" — B.2'deki beden eşleştirme hatası nedeniyle "Senin bedenine göre ilanlar" bölümü sistematik olarak boş dönen kullanıcılar için bu bölüm sessizce kayboluyor, geri kalan bölümler (kategori, şehir vb.) doluysa kullanıcı hiçbir şeyin eksik olduğunu fark etmiyor — sayfa normal görünüyor, yalnızca bir bölüm eksik.

---

## ÖZET TABLO

| Bölüm | Konu | Durum |
|---|---|---|
| A.1 | Kullanıcı tercihi alanları | DOĞRU ÇALIŞIYOR |
| A.2 | Provider sorgu mantığı (genel yapı) | DOĞRU ÇALIŞIYOR |
| B.1 | Kategori eşleştirme (string format/casing) | DOĞRU ÇALIŞIYOR |
| B.2 | Beden eşleştirme | **ŞÜPHELİ/BOZUK — 2 doğrulanmış bug** |
| B.3 | Duty Free (profil bağımsızlığı) | DOĞRU ÇALIŞIYOR (kasıtlı tasarım, doğrulandı) |
| C | oneriSkoru sıralaması | **KULLANILMIYOR** (formül var, Sana Özel'de hiç çağrılmıyor) |
| D | Canlı veri testi | DOĞRULANAMADI (kapsam dışı bırakıldı, kod okumasıyla yeterli kesinlik sağlandı) |
| E | Boş sonuç UI davranışı | Sessiz boşluk (bölüm bazında), yalnızca TÜM bölümler boşsa fallback var |

---

## Sana Özel sisteminde kullanıcıya gerçekten yanlış/eşleşmeyen içerik gösteren, DOĞRULANMIŞ bir bug var mı?

**EVET.** İki doğrulanmış, kod-seviyesinde kesin bug:

1. **Kadın kullanıcılar/ilanlar için beden eşleştirmesi tasarlandığı gibi çalışmıyor** (`sana_ozel_providers.dart:60-64`) — Türkçe "ı"/"i" karakter uyuşmazlığı yüzünden `case 'kadin':` hiç tetiklenmiyor, kadın ilanları geniş `default` dalına düşüyor. Bu, kullanıcıya **potansiyel olarak yanlış cinsiyetteki bir bedenle eşleşen** ilanlar gösterebilir (ör. kadın ilanı, yalnızca erkek beden bilgisi girmiş bir kullanıcıya, ortak beden etiketi — "M" gibi — üzerinden yanlışlıkla önerilebilir).
2. **Çocuk ürünleri için `cocukAyakkabi` alanı fiilen hiç kullanılmıyor** (`case 'cocuk':` ölü kod) — çocuk ayakkabı numaraları yanlışlıkla yetişkin erkek ayakkabı listesiyle karşılaştırılıyor, bu yüzden çocuk ürünleri kullanıcının gerçek çocuk beden tercihiyle **asla eşleşmiyor** (sistematik false-negative).

Her iki bug da Bölüm E'deki "sessiz boşluk" davranışı yüzünden **kullanıcıya tamamen görünmez** — "Senin bedenine göre ilanlar" bölümü ya hiç görünmüyor (false-negative durumunda) ya da yanlış ürünler gösteriyor (false-positive durumunda), kullanıcı bunun bir hata olduğunu fark edemiyor.

**Öncelik notu:** Bu, launch'ı engelleyecek bir güvenlik/veri bütünlüğü sorunu değil, ama kişiselleştirme özelliğinin reklam ettiği değeri (kullanıcıya doğru bedenler gösterme) fiilen sağlamıyor — düzeltme kapsamı küçük (yalnızca `_bedenEslesiyor()` fonksiyonu, string karşılaştırmasını normalize etmek + `cinsiyet` alanını "Kız"/"Erkek"/"Unisex" değerleriyle `BedenTipi.cocuk` bilgisiyle birlikte değerlendirmek).
