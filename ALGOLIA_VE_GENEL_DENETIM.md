# Algolia Sıralama + Genel Kılcal Damar Denetimi

Bu rapor SALT-OKUMA bir denetimin sonucudur. `flutter analyze` ve `flutter test`
dışında hiçbir komut çalıştırılmadı, hiçbir dosya değiştirilmedi, hiçbir deploy
yapılmadı.

**Not:** Repo kökünde bu denetimden önce yazılmış `ALGOLIA_DENETIM.md` zaten var
ve Bölüm A/B/C/D'yi (senkronizasyon, filtre/sıralama tutarlılığı, index ayarları,
geçmiş bulgular) kapsamlı işlemiş. Bu rapor onun bulgularını doğrulayıp, bu
görevin istediği ek açılardan (client-taraflı yeniden-sıralama, replica
seçiminin TAM kod yolu, favori ekranı ile favori sıralaması arasındaki fark,
genel kılcal damar taraması) genişletiyor. Çelişki bulunmadı.

---

## BÖLÜM A — Algolia Sıralama Mantığı

### A.1 — Index/replica yapılandırması

`functions/src/index.ts:33-34`:
```ts
const ALGOLIA_INDEX        = "ilanlar";
const ALGOLIA_INDEX_NEREYE = "ilanlar_nereye";
```

Repo içinde `customRanking`/`ranking`/`attributesForFaceting`/`setSettings`
için **sıfır sonuç** (`grep -rn` ile doğrulandı, hem `functions/src/` hem
`lib/` genelinde). Kullanılan 4 replica adı yalnızca **client tarafında**,
string sabit olarak geçiyor (`arama_service.dart:235-240`):
`ilanlar` (varsayılan/en yeni), `ilanlar_favori`, `ilanlar_onerilen`,
`ilanlar_eski`.

**Sonuç:** Index/replica'ların `customRanking` ayarları (hangi alana göre
asc/desc sıralandığı) kodda **hiçbir yerde tanımlı değil** — yalnızca Algolia
Dashboard'da manuel yapılandırılmış olabilir. Bu, versiyon kontrolünde
olmayan, tekrarlanabilir olmayan bir konfigürasyon riski. **⚠️ DOĞRULANAMADI**
(kod dışı).

### A.2 — "En yeni" sıralaması

`app_constants.dart:618-635`'teki `SiralamaTipi.enYeni` → `algoliaKey` =
`'enYeni'` → `arama_service.dart:235-240`:
```dart
final indexAdi = switch (siralama) {
  'enCokFavorilenen' => 'ilanlar_favori',
  'onerilen'         => 'ilanlar_onerilen',
  'enEski'           => 'ilanlar_eski',
  _                  => _kAlgoliaIndex,   // 'enYeni' burada düşer — varsayılan/ana index
};
```
`'enYeni'` switch'te **açıkça listelenmiyor** — `default` dalına düşerek ana
`ilanlar` index'ine gidiyor. Fonksiyonel olarak doğru (ana index'in
`customRanking`'i `olusturmaTarihi desc` olarak ayarlanmışsa "en yeni" tam
istenen sonucu verir), ama **kırılgan**: `'enYeni'` yerine yanlış yazılmış
bir string (`'enyeni'`, boşluklu, vb.) sessizce aynı `default` dalına düşer
— gerçek bir hata olsa bile fark edilmez, çünkü davranış görünürde "doğru"
kalır (ana index'e gider). Bu satırda `'enYeni' => _kAlgoliaIndex,` şeklinde
**açık** bir dal olsaydı hem niyet netleşir hem de gerçek bir yazım hatası
(örn. yanlışlıkla `'enEski'` yazılması) derhal görünür olurdu.

**Sonuç — "En Yeni": ✅ çalışıyor** (ana `ilanlar` index'ine yönleniyor),
**⚠️ kırılgan switch tasarımı** (default-fallthrough, açık case değil).

### A.3 — "Önerilen" sıralaması

`onerilenPuan` alanının Algolia'ya **gerçekten** senkronize edildiği
doğrulandı — üç yazım noktasının hepsinde (`index.ts:313-347` ilan
oluşturma, `:492-521` ilan güncelleme, `:574-596` toplu aktarım) `onerilenPuan:
onerilenPuanHesapla(data)` hesaplanıp hem Firestore'a hem Algolia
`saveObject`/`saveObjects` çağrısına body içinde yazılıyor. Dönüş değeri
bilinçli olarak **kovalanmış tamsayı** (`onerilenPuan.ts:26`, `Math.round(...
* 20)` → 0-14 arası kova) — bu, ikincil kriterin (muhtemelen
`olusturmaTarihi desc`) aynı kovadakiler arasında devreye girmesi için
tasarlanmış (kod yorumu `index.ts:51-52`'de açıkça belirtiyor).

Client → sunucu formül farkı (`lib/shared/utils/oneri_skoru.dart` vs
`functions/src/onerilenPuan.ts`) BACKLOG.md'de zaten "bilinçli tasarım
farkı, bug değil" olarak not düşülmüş ve golden-value testleriyle (`test/
shared/utils/oneri_skoru_test.dart`, 10 ortak girdi) doğrulanmış —
**tekrar sorun olarak raporlanmadı**, görev talimatına uygun.

`ilanlar_onerilen` replikasının gerçekten `onerilenPuan desc` olarak
sıralandığı Dashboard konfigürasyonuna bağlı, kod içinden doğrulanamıyor
(bkz. A.1).

**Sonuç — "Önerilen": ✅ `onerilenPuan` alanı 3/3 yazım noktasında doğru
hesaplanıp Algolia'ya senkronize ediliyor**, ⚠️ replikanın gerçek
`customRanking` ayarı doğrulanamadı (dashboard'a bağlı).

### A.4 — "Favori" sıralama/filtre — çapraz ekran haritalama

İki **tamamen farklı** "favori" kavramı var, karıştırılabilir ama kodda
ayrık ve tutarlı:

| Ekran/özellik | Veri kaynağı | Ne yapıyor |
|---|---|---|
| **"Favorilerim" ekranı** (`lib/features/favoriler/presentation/favoriler_screen.dart`) | **Firestore** — `favorilerProvider` → `ilan_repository.dart:632-641` `favorilerStream()`, `favoriler` koleksiyonundan `kullaniciId` filtresiyle, `eklemeTarihi desc` sıralı | Kullanıcının kendi favorilediği ilanları listeler |
| **"Favori" sıralama seçeneği** (İlanlar/Gelenler arama ekranları) | **Algolia** — `SiralamaTipi.enCokFavorilenen` → `ilanlar_favori` replikası (`arama_service.dart:236`) | Tüm arama sonuçlarını `favoriSayisi`'ye göre sıralar (kullanıcının kendi favorileriyle ilgisi yok) |

Bu bir tutarsızlık değil, bilinçli bir ayrım — ama isimlendirme
("Favori"/"Favorilerim") kafa karıştırıcı olabilir; kod seviyesinde hata
yok.

**Ek bulgu — client-taraflı YENİDEN sıralama (ekranlar arası TUTARSIZ):**
`ilanlar_screen.dart:244-251`:
```dart
var yeniIlanlar = sonuc.ilanlar.map(_hittenIlan).toList();
// enCokFavorilenen icin siralama
if (_siralama == SiralamaTipi.enCokFavorilenen) {
  yeniIlanlar.sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi));
}
// onerilen icin siralama
if (_siralama == SiralamaTipi.onerilen) {
  oneriSkoruylasirala(yeniIlanlar);
}
```
İlanlar (istekler) ekranı, Algolia'dan gelen sonucu **client tarafında
tekrar sıralıyor** — ama bu yalnızca o anki **sayfa** (`hitsPerPage: 24`)
içinde yapılıyor, tüm sonuç kümesinde değil. `gelenler_screen.dart` ise
(`:169-182`, `_gHittenIlan` map'i) **hiçbir client-taraflı yeniden sıralama
yapmıyor** — doğrudan Algolia'nın döndürdüğü sırayı kullanıyor.

**Pratik etki:**
1. İki ekran arasında **tutarsız davranış** — İlanlar ekranı Algolia
   replikasına güvenmiyor/onu client'ta ezip duruyor, Gelenler ekranı
   güveniyor. Biri "doğru" replika ayarına bağımlı değilken diğeri bağımlı.
2. "Daha fazla yükle" (sayfalama) ile ilanlar ekranında her yeni sayfa
   kendi içinde ayrı sıralanıp listeye ekleniyor (`benzersizYeni` ile
   birleştiriliyor, `:253-260`) — bu, **sayfa sınırları arasında global
   sıralamanın bozulabileceği** anlamına geliyor (örn. 2. sayfadaki en
   yüksek favori sayılı ilan, 1. sayfadaki en düşük favori sayılı ilandan
   sonra görünebilir, çünkü sıralama yalnızca kendi 24'lük sayfası içinde
   yapılıyor).

**Sonuç — "Favori" sıralaması: ⚠️ İlanlar ekranında sayfa-içi client
yeniden-sıralama var (global sıralamayı sayfalar arası bozabilir), Gelenler
ekranında yok — ekranlar arası TUTARSIZ.**

### A.5 — Filtre ekranlarının sıralama parametresi geçirme doğrulaması

`SiralamaTipi` enum'ı (`app_constants.dart:618`) tek bir kaynaktan geliyor
ve UI'da hem `filtre_ekrani.dart:863` hem `gelenler_filtre_ekrani.dart:604`
`SiralamaTipi.values.map(...)` ile **generic** olarak render ediliyor —
her seçenek için ayrı, elle yazılmış bir dal YOK, yani "bir seçeneğin
başka birinin mantığını kullanması" tarzı kopyala-yapıştır hatasına yapısal
olarak kapalı (`onSecim` callback'i her zaman tıklanan `tip`'i taşıyor).
Filtre ekranından ana ekrana `_modalSiralama` → `secim.siralama` →
`_siralama` → `.algoliaKey` → `algoliaFiltrele(siralama: ...)` zinciri her
iki ekranda da (`ilanlar_screen.dart:236`, `gelenler_screen.dart` üzerinden
`_filtreAc` → `onUygula`) doğrudan aktarılıyor, ara adımda dönüşüm/eşleme
hatası yok.

**Sonuç — Filtre → Algolia parametre eşlemesi: ✅ kopyala-yapıştır riski
yapısal olarak yok** (enum-driven, elle yazılmış dal yok).

### A.6 — `kullaniciPuan` alanının Algolia senkronizasyonu

BACKLOG.md'nin işaret ettiği 3 nokta tek tek kontrol edildi:

| Fonksiyon | `kullaniciPuan` Algolia body'sinde var mı? |
|---|---|
| `ilanModerasyonu` (`index.ts:327-348`) | ❌ Yok |
| `ilanGuncellendi` (`index.ts:499-521`) | ❌ Yok |
| `algoliaTopluAktar` (`index.ts:572-596`) | ❌ Yok |

**Hâlâ geçerli — BACKLOG.md'deki not doğru.** Etki hâlâ düşük:
`onerilenPuanHesapla()` (`onerilenPuan.ts:11`) `data.kullaniciPuan`'ı
**Firestore dokümanından** okuyor (Algolia'dan değil), bu yüzden
`onerilenPuan` kompozit skoru doğru hesaplanıyor ve sıralama etkilenmiyor.
Ham `kullaniciPuan` yalnızca Algolia-kaynaklı bir listede (ör. arama
sonucu kartında) doğrudan gösterilmek istenirse eksik kalır — şu an hiçbir
ekran bunu Algolia hit'inden okumuyor (`ilanlar_screen.dart:_hittenIlan`,
`gelenler_screen.dart:_gHittenIlan` ikisi de bu alanı map etmiyor).

**Sonuç: ❌ Eksik (3/3), ama pratik etki düşük** — sıralamayı bozmuyor,
sadece gelecekte potansiyel bir UI özelliği için veri eksik bırakıyor.

---

### ÖZET TABLO — Sıralama Seçenekleri

| Seçenek | Replica/Index | Kod yolu doğrulandı mı | Sonuç |
|---|---|---|---|
| En yeni | `ilanlar` (ana index, default fallthrough) | ✅ | ✅ çalışıyor, ⚠️ kırılgan switch (açık case yok) |
| Önerilen | `ilanlar_onerilen` | ✅ | ✅ `onerilenPuan` senkron doğru, ⚠️ replika ayarı dashboard'a bağlı (doğrulanamadı) |
| En çok favorilenen | `ilanlar_favori` | ✅ | ⚠️ İlanlar ekranında sayfa-içi client re-sort var, Gelenler'de yok — tutarsız |
| En eski | `ilanlar_eski` | ✅ | ✅ çalışıyor (replika ayarı doğrulanamadı) |
| kullaniciPuan → Algolia | — | ✅ | ❌ 3/3 fonksiyonda eksik, düşük etki (BACKLOG'da zaten kayıtlı) |

---

## BÖLÜM B — Genel Kılcal Damar Taraması

### B.1 — `.limit()` içermeyen stream/query'ler

| Konum | Sorgu | Durum |
|---|---|---|
| `lib/core/services/badge_service.dart:32-39` | `bildirimler` — `kullaniciId==` + `okundu==false`, `.snapshots()`, **limit yok** | ⚠️ Bildirim rozetinde kullanılıyor (`AppBadgePlus.updateBadge(snap.size)`), pratikte okunmamış bildirim sayısı sınırlı kalır ama teorik olarak sınırsız büyüyebilir |
| `lib/features/ilanlar/data/ilan_repository.dart:632-641` | `favoriler` — `kullaniciId==`, `orderBy(eklemeTarihi desc)`, `.snapshots()`, **limit yok** | ⚠️ "Favorilerim" ekranının canlı veri kaynağı — çok favorisi olan bir kullanıcı için sınırsız büyüyen liste riski |
| `lib/features/profil/data/kullanici_repository.dart:236-244` | `takipEdilenTarihleriStream()` — `takipler`, `takipciId==`, **limit yok** | ⚠️ Kardeş fonksiyonlar (`takipciIdleriStream`, `takipEdilenIdleriStream`, aynı dosya `:215-231`) `.limit(500)` kullanıyor, bu üçüncü fonksiyon **tutarsız şekilde** limit'siz bırakılmış |
| `lib/features/ilanlar/data/ilan_repository.dart:526-536` (`favorideMi`) | `favoriler` — `kullaniciId==` + `ilanId==`, **limit yok** | Düşük risk — sonuç yapısal olarak en fazla 1 doküman (favoriId sabit, doküman ID kilitli), limit eklense de fark etmez |

`bildirim_banner_service.dart:48-52` zaten `.limit(20)` kullanıyor — aynı
`bildirimler` koleksiyonuna erişen `badge_service.dart`'ın limit'siz
bırakılması, aynı dosyada/serviste tutarsızlık örneği.

**Sonuç: ⚠️ 3 gerçek bulgu** (badge_service, favorilerStream,
takipEdilenTarihleriStream) — hiçbiri launch'ı acilen engellemiyor (pratik
kullanıcı senaryosunda binlerce favoriye/takibe ulaşmak uzun zaman alır),
ama regresyon riski olarak not edilmeye değer; ikisi (favorilerStream,
takipEdilenTarihleriStream) doğrudan kardeş fonksiyonlarla tutarsız.

### B.2 — Cloud Functions hata yönetimi

`functions/src/index.ts`'teki 16 export edilen fonksiyonun tamamı tarandı:

| Fonksiyon | try/catch var mı | Sessiz hata yutma (yalnızca log, kullanıcıya geri bildirim yok) |
|---|---|---|
| `ilanModerasyonu` | ✅ (dış + Algolia için ayrı) | Algolia hatası `console.error` + `algoliaHata:true` flag (kullanıcıya görünmez ama en azından iz bırakıyor) |
| `ilanGuncellemeModerasyon` | ✅ | Genel catch, yalnızca `console.error` |
| `ilanGuncellendi` | ✅ (her Algolia çağrısı ayrı try/catch) | Algolia/onerilenPuan hataları yalnızca `console.warn` |
| `ilanSilindi` | ✅ (her adım ayrı try/catch) | Algolia silme hataları yalnızca `console.warn` — **ilan Firestore'dan silinse bile Algolia'da "hayalet" kayıt kalabilir, hiçbir yerde retry/dead-letter yok** |
| `algoliaTopluAktar` | ❌ **YOK** | `saveObjects` çağrıları try/catch'siz — hata olursa `onCall` otomatik `internal` hatası fırlatır (bu durumda kabul edilebilir, çünkü zaten `onCall` ve admin arayüzünden manuel tetikleniyor, kullanıcı hemen hata görür) |
| `mesajBildirimiGonder` | ✅ (FCM için) | FCM hatası yalnızca `console.warn`, ama fonksiyon `{success:true}` dönüyor — **çağıran client'a mesaj bildirimi gönderilemediği hiç bildirilmiyor** (düşük risk, mesajın kendisi zaten ayrı yazılmış oluyor) |
| `degerlendirmeBildirimiGonder` | ✅ (FCM için) | Aynı desen, sessiz `console.warn` |
| `takipOlustuSayacArttir` / `takipSilindiSayacAzalt` | ❌ **YOK** | Batch commit hatası olursa fonksiyon crash olur (Cloud Functions otomatik retry yapmaz, `onDocumentCreated`'te varsayılan retry kapalı) — **sayaç güncellenmeden sessizce başarısız olabilir** |
| `degerlendirmePuanGuncelle` | ✅ (transaction + fan-out ayrı) | Fan-out hatası `console.error`, yorum satırında bilinçli olarak "sadece logla" deniyor (kabul edilebilir tasarım) |
| `iletisimGonder` | ❌ **YOK** (dış try/catch yok) | `transporter.sendMail` hatası olursa `onCall` otomatik `internal` hatasına döner — kullanıcı en azından bir hata görür (kabul edilebilir) |
| `hesapSilSunucu` | ✅ | Hata `HttpsError` olarak client'a fırlatılıyor — **iyi örnek** |
| `islemDurumuBildirimiGonder` | ✅ (FCM için, kısmi) | FCM hataları sessiz `console.warn`, ama asıl Firestore `bildirimler` yazımı try/catch'siz (satır 978-988, 1038-1048) — **eğer bu `db.collection('bildirimler').add()` başarısız olursa tüm fonksiyon crash olur** |
| `goruntulenmeTemizle` / `ilanOtomatikPasif` | ❌ **YOK** | `onSchedule`, try/catch yok — hata olursa Cloud Scheduler'ın kendi retry/log mekanizmasına düşer (zamanlı görevler için makul, kritik değil) |
| `guvenSkoruHesapla` | ❌ **YOK** | Aynı, `onSchedule` — döngü içinde tek bir kullanıcının `ilanSnap` sorgusu patlarsa **tüm batch işlemi durur**, kalan kullanıcılar güncellenmez |

**En dikkat çekici 2 bulgu:**
1. **`takipOlustuSayacArttir`/`takipSilindiSayacAzalt`** — try/catch yok,
   batch commit hatası fonksiyonu sessizce crash ettirebilir, sayaç
   (`takipSayisi`/`takipciSayisi`) senkron dışı kalabilir, hiçbir retry/log
   yok (`index.ts:717-749`).
2. **`islemDurumuBildirimiGonder`** — asıl `bildirimler` Firestore yazımı
   try/catch'siz (yalnızca sonrasındaki FCM gönderimi korunuyor), Firestore
   yazma hatası (ör. kural ihlali, kota) fonksiyonun tamamını crash ettirir.

**Sonuç: ⚠️ 6/16 fonksiyonda ya try/catch tamamen yok ya da kritik bir
adım korunmasız** — çoğu düşük-orta risk (scheduled/trigger fonksiyonları,
Cloud Functions kendi crash/log mekanizmasına düşüyor), ama sayaç
fonksiyonları (`takipOlustuSayacArttir`/`takipSilindiSayacAzalt`) launch
sonrası ilk haftalarda veri tutarsızlığına (yanlış takipçi sayısı) yol
açabilir.

### B.3 — `firestore.rules` uçtan uca inceleme

523 satır tamamen okundu. **Hiçbir `allow write: if true` veya benzeri aşırı
gevşek kural bulunamadı.** Tüm koleksiyonlar (`kullanicilar`, `ilanlar`,
`sohbetler`/`mesajlar`, `favoriler`, `goruntulenmeler`, `degerlendirmeler`,
`bildirimler`, `sikayetler`, `takipler`, `ayarlar`, `trendler`) için
`create`/`update`/`delete` kuralları kimlik doğrulama + sahiplik + (birçok
yerde) sunucu-otoritesi alan koruması + hız sınırlaması (rate limiting)
içeriyor. `list` sorguları scraping korumalı (`request.query.limit <= 100`).
Kod yorumları geçmiş güvenlik açıklarının (ör. `favoriSayisi`'nin sahiplik
dalında hiç kısıtlı olmaması) düzeltildiğini ve gerekçesini belgeliyor —
**sağlıklı, olgun bir güvenlik kuralı seti.**

**Sonuç: ✅ Aşırı gevşek kural yok, kurallar iyi belgelenmiş ve savunmacı.**

### B.4 — `flutter analyze` (TAM ÇIKTI)

```
Analyzing iste_v3...

   info - Unnecessary use of multiple underscores - lib\features\home\presentation\sana_ozel_screen.dart:1036:34 - unnecessary_underscores
   info - 'appleProvider' is deprecated and shouldn't be used. Use providerApple instead. This parameter will be removed in a future major release - lib\main.dart:54:5 - deprecated_member_use

2 issues found. (ran in 24.6s)
```

**Sonuç: ✅ Sıfır hata/uyarı, yalnızca 2 bilgi-seviyesi not (biri stil, biri
deprecated API kullanımı — kritik değil).**

### B.5 — `flutter test` (TAM SONUÇ)

56 test, tamamı geçti, 1 tanesi kasıtlı olarak atlandı (`kendi kendini
takip etme` senaryosu — yorum satırında "rules'ın işi, kapsam dışı" diye
belgelenmiş, bug değil):

```
00:04 +56 ~1: All tests passed!
```

**Sonuç: ✅ Tüm testler geçiyor.**

### B.6 — TODO/FIXME/XXX/HACK taraması

`lib/` genelinde `grep -rn "TODO|FIXME|XXX|HACK"` çalıştırıldı. **Gerçek bir
TODO/FIXME/HACK yorumu bulunamadı** — tüm eşleşmeler yanlış pozitif (beden
etiketleri: `XS`, `XXL`, `XXXL`, telefon format ipucu `05XX XXX XX XX`).

**Sonuç: ✅ Kod tabanında açık bırakılmış TODO/FIXME işareti yok.**

---

## GENEL ÖZET

| # | Bulgu | Durum |
|---|---|---|
| A.1 | Index/replica `customRanking` ayarları kod dışı (dashboard'a bağlı) | ⚠️ |
| A.2 | "En yeni" → ana index, ama default-fallthrough switch (açık case yok) | ✅/⚠️ |
| A.3 | "Önerilen" → `onerilenPuan` senkronu 3/3 doğru | ✅ |
| A.4 | "Favori" sıralaması — İlanlar ekranında sayfa-içi client re-sort, Gelenler'de yok | ⚠️ |
| A.5 | Filtre → Algolia parametre eşlemesi (kopyala-yapıştır riski) | ✅ |
| A.6 | `kullaniciPuan` Algolia'ya 3/3 fonksiyonda eksik (BACKLOG'da zaten kayıtlı) | ❌ (düşük etki) |
| B.1 | 3 stream `.limit()` içermiyor (badge_service, favorilerStream, takipEdilenTarihleriStream) | ⚠️ |
| B.2 | 6/16 Cloud Function'da eksik/kısmi try-catch, en riskli 2'si sayaç fonksiyonları | ⚠️ |
| B.3 | `firestore.rules` — aşırı gevşek kural yok | ✅ |
| B.4 | `flutter analyze` — 0 hata, 2 bilgi notu | ✅ |
| B.5 | `flutter test` — 56/56 geçti | ✅ |
| B.6 | TODO/FIXME/XXX/HACK — bulunamadı | ✅ |

**Toplam:** 7 ✅, 6 ⚠️, 1 ❌ (düşük etkili, zaten BACKLOG'da kayıtlı).

**Launch'ı acilen engelleyen bir sorun yok.** En değerli 3 yeni bulgu
(önceki `ALGOLIA_DENETIM.md`'de yoktu):
1. **A.4** — İlanlar ekranı "En çok favorilenen" sıralamasını Algolia
   replikasından geldikten sonra client'ta tekrar sıralıyor, ama yalnızca
   sayfa-içi (24 kayıt) — sayfalar arası global sıralama garantisi yok, ve
   Gelenler ekranı aynı şeyi yapmıyor (ekranlar arası tutarsız davranış).
2. **B.2** — `takipOlustuSayacArttir`/`takipSilindiSayacAzalt`
   (`index.ts:717-749`) try/catch'siz; batch commit hatası sayaçları
   (`takipSayisi`/`takipciSayisi`) sessizce senkron dışı bırakabilir.
3. **B.1** — `favorilerStream` (`ilan_repository.dart:632-641`,
   "Favorilerim" ekranının canlı kaynağı) ve `takipEdilenTarihleriStream`
   (`kullanici_repository.dart:236-244`, kardeş fonksiyonlarının aksine)
   `.limit()` içermiyor — düşük olasılıklı ama gerçek "sınırsız büyüyen
   liste" riski.
