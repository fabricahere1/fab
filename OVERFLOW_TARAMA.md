# Overflow Taraması Raporu

Tarih: 2026-07-19
Kapsam: lib/ altında statik kod okuması (Read ile widget ağacı incelendi, sadece grep ile "Row/Column var" tespiti yapılmadı). Hiçbir dosya değiştirilmedi, hiçbir build/run komutu çalıştırılmadı.

Önem dereceleri: **Kritik** (kesin taşar), **Orta** (uzun girdide taşabilir), **Düşük** (teorik, pratikte olası değil).
Doğrulama durumu: **Doğrulandı** (widget ağacı okunarak constraint ilişkisi teyit edildi) / **Şüpheli-Doğrulanmadı** (emin olunamadı, cihazda test gerekir).

---

## Bulgular (önem sırasına göre)

### 1. [ORTA] lib/features/ilanlar/presentation/ilan_detay_screen.dart:579-615 — kategori + tip rozetleri yan yana, Expanded/Flexible yok
Kalıp: **1** (Row içinde esnek olmayan, değişken uzunluktaki metinler yan yana).
`Row(children: [...])` içinde iki `Container` var: biri `kategoriAdiStr` metnini gösteriyor (satır 588, `Text(kategoriAdiStr, ...)` — **maxLines/overflow YOK**), diğeri sabit metinli "📦 İstek" / "✈️ Taşıyıcı" rozeti (satır 603). Row'un hiçbir çocuğunda Expanded/Flexible yok; Row, `Container(padding 20,20,20,16)` içinde ekran genişliğine sabitlenmiş bir Column'un doğrudan çocuğu.
Senaryo: `kategoriAdi()` fonksiyonundan dönen kategori adı uzun bir alt kategori ismi ise (örn. "Elektronik & Bilgisayar Aksesuarları" gibi çok kelimeli bir kategori adı), bu Row ekran genişliğini (yaklaşık 335dp, 20+20 padding düşülünce) aşabilir ve klasik "RenderFlex overflowed by X pixels" hatası verir. Kategori adlarının gerçek maksimum uzunluğu kod tabanında doğrulanmadı (kategori sabitleri ayrı dosyada).
Doğrulama durumu: **Doğrulandı** (widget ağacı okundu, Expanded eksikliği kesin) ama gerçek kategori adı uzunlukları incelenmedi — bu yüzden "kesin taşar" değil "taşabilir" (Orta).

### 2. [ORTA] lib/features/profil/presentation/kullanici_profil_screen.dart:117-119 — SliverAppBar title, maxLines yok
Kalıp: **2** (uzun kullanıcı adı gösteren Text'te maxLines/overflow eksik).
`title: Text(ad, style: ...)` — `ad` kullanıcının adı/soyadı (kullanıcı girdisi), maxLines/overflow belirtilmemiş. AppBar'ın `leading` (geri butonu) var, `actions` yok. AppBar title alanı sabit yükseklikli (`toolbarHeight` varsayılan ~56dp) bir sliver; title Text genişliği ekran genişliği ile sınırlı ama maxLines olmadığı için iki satıra sarabilir, bu da sabit yükseklikli AppBar içinde dikey overflow'a yol açabilir.
Senaryo: Kullanıcı adı "Muhammed Abdurrahman Yılmazoğlu Özkan" gibi 25+ karakterse, AppBar title iki satıra sarar ve sabit toolbar yüksekliğini aşarak RenderFlex/overflow uyarısı verebilir.
Doğrulama durumu: **Şüpheli-Doğrulanmadı** — SliverAppBar'ın title widget'ının gerçek davranışı (bazı Flutter sürümlerinde otomatik tek satır+clip uygulanabiliyor) cihazda test edilmeden kesinleştirilemez.

### 3. [ORTA] lib/features/degerlendirme/presentation/degerlendirmeler_liste_screen.dart:127-131 — AppBar title, kullanıcı adı + sabit metin birleşimi
Kalıp: **2**.
`Text('$kullaniciAd · Değerlendirmeler', style: ...)` — normal `AppBar` (Scaffold appBar), maxLines/overflow belirtilmemiş. `kullaniciAd` kullanıcı girdisi olduğundan uzun olursa AppBar title alanını taşırabilir.
Senaryo: Uzun kullanıcı adında AppBar başlığı iki satıra sarıp sabit toolbar yüksekliğini aşabilir.
Doğrulama durumu: **Şüpheli-Doğrulanmadı** (AppBar title'ın gerçek clip davranışı cihaz testi gerektirir).

### 4. [DÜŞÜK] lib/features/profil/presentation/takip_listesi_screen.dart:328-335 (_ProfilSatiri) — isim Text'inde maxLines yok
Kalıp: **2**, kısmen **5** (avatar + isim + buton Row'u).
`Text(profil.adSoyad, ...)` maxLines/overflow yok, ancak bu Text `Expanded(child: Column(...))` içinde — Row'da `AvatarWidget` (sabit 44dp), `Expanded(Column[isim, şehir])`, ardından `takipButonu` (sabit/instrinsic genişlikli buton) sırayla yer alıyor. Expanded olduğu için **yatay** RenderFlex overflow riski yok (isim satırı sarar, Row taşmaz). Ancak isim çok uzunsa (örn. 3-4 kelime), 2-3 satıra sararak satırın dikey yüksekliğini artırır; bu ListView.builder içinde olduğundan (sabit yükseklik kısıtı yok) gerçek bir overflow hatası oluşturmaz, sadece kartın boyu büyür ve buton dikey ortalanmış görünür — görsel bir tutarsızlık, kesin overflow değil.
Doğrulama durumu: **Doğrulandı** (Expanded var, dikey esneklik mevcut, gerçek RenderFlex hatası oluşmaz).

### 5. [DÜŞÜK] lib/features/degerlendirme/presentation/degerlendirmeler_liste_screen.dart:307-313 (DegerlendirmeKarti) — isim Text'inde maxLines yok
Kalıp: **2**, **5**.
`Text(ad.isNotEmpty ? ad : 'Kullanıcı', ...)` maxLines yok, ama `Expanded(child: Column(...))` içinde; Row'da `CircleAvatar` (sabit 32dp) + `Expanded(isim/tarih)` + sabit genişlikli 5 yıldız Row'u (`mainAxisSize: MainAxisSize.min`) var. Expanded sayesinde yatay overflow olmaz; isim uzunsa sadece kart yüksekliği büyür (Column içinde, ListView.builder'da sorun yaratmaz).
Doğrulama durumu: **Doğrulandı**.

### 6. [DÜŞÜK/ŞÜPHELİ] lib/features/mesajlar/presentation/sohbet_screen.dart:1096-1136 — mesaj balonu metni, uzun/boşluksuz tek kelime senaryosu
Kalıp: **2** (özel durum: kırılmaz tek kelime).
Mesaj balonu `Container(constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 80))` ile genişliği sınırlı, içindeki `Text(metin, style: ...)` maxLines/overflow belirtilmemiş — bu normalde DOĞRU bir kalıptır (Text sınırlı genişlikte serbestçe sarar, dikey büyüme sorun değildir, mesaj balonları için beklenen davranış). Ancak kullanıcı mesajı boşluksuz çok uzun tek bir "kelime" içeriyorsa (örn. uzun bir URL, uzun bir e-posta adresi veya boşluksuz yapıştırılmış metin), Flutter'ın varsayılan `TextOverflow.clip` davranışı nedeniyle metin balonun `maxWidth` sınırını yatayda hafifçe aşıp görsel taşmaya (kesin RenderFlex hatası değil, görsel clip/taşma) yol açabilir.
Doğrulama durumu: **Şüpheli-Doğrulanmadı** — gerçek bir overflow hatası değil, kenar durum; cihazda uzun-tek-kelime mesajıyla test edilmeli.

---

## İncelenip TEMİZ bulunan alanlar (Doğrulandı — overflow riski yok)

- `lib/features/ilanlar/presentation/ilanlar_screen.dart` (_Son24SaatBolumu, satır ~936-1144): "nereden → nereye" Positioned metni `maxLines: 1, overflow: TextOverflow.ellipsis` ile korunuyor (satır 1086-1087). "YENİ" rozeti sabit boyutlu container içinde sabit metin. "Haftanın Öne Çıkanları" başlığı `Expanded` içinde, maxLines yok ama Row dikeyde esnek (Padding, sabit yükseklik kısıtı yok) — sarma olursa sadece Row'u büyütür, overflow üretmez.
- `lib/features/home/presentation/kesfet_vitrin_tab.dart` (KesfetHeroBanner, satır 506-647): "Bu hafta öne çıkanlar" başlığı `maxLines: 1, overflow: TextOverflow.ellipsis` (540-542). Kart içi ürün adı ve güzergah metinleri `maxLines: 1, overflow: ellipsis` ile korunuyor (614-627). `SizedBox(height: 236)` sabit yükseklik var ama iç yapı `Expanded`/`ListView` ile bu yüksekliğe uyumlu.
- `lib/features/home/presentation/sana_ozel_screen.dart` (_SanaOzelHeroBanner, satır 794-889): Benzer desen, güvenli — üst kısımdaki "Senin için önerilen" ve "İlgi alanlarına göre seçildi" metinleri tek satır sabit stil, resim kartlarında metin yok (sadece resim).
- `lib/shared/widgets/giris_gerekli_widget.dart`: `Center > Column` içinde mesaj Text'i maxLines yok ama Column dikeyde serbest, genişlik ekran genişliği ile doğal sarma — overflow riski yok.
- `lib/features/ilanlar/presentation/widgets/ilan_karti.dart` (IlanKarti, _IlanKartiIcerik): Ürün adı `maxLines:2, ellipsis` (809-817), güzergah `Expanded + maxLines:1 + ellipsis` (824-834), kategori rozeti `maxLines:1, ellipsis` (854-861), beden/cinsiyet şeridi `maxLines:1, ellipsis` (717-729), sayaç widget'ı `Flexible + maxLines:1 + ellipsis` (671-684) — kart tasarımı overflow'a karşı sistemli şekilde korunmuş, 3'lü grid'de `Expanded` ile sabit yükseklik senkronize ediliyor (satır 780-884 açıklaması: "Expanded kullanır — kalan alanı doldurur, overflow'u önler").
- `lib/features/degerlendirme/presentation/degerlendirmeler_liste_screen.dart`: "İlan badge" satırı `Expanded + maxLines:1 + ellipsis` (208-218) ile korunuyor. Yorum metni maxLines yok ama Column içinde serbestçe sarıyor (Stack + Padding, sabit yükseklik kısıtı yok) — overflow riski yok, sadece kart boyu büyür.
- `lib/features/ilanlar/presentation/ilan_detay_screen.dart`: "İlan Sahibi" kartı, `_IlanBilgiSatiri` (satır 948-966) `Expanded` içinde metin sarıyor — güvenli. Satır 715-724 ve 960-962, 1161-1163: ürün başlığı metinleri `maxLines:1, overflow: ellipsis` ile korunmuş.
- `lib/features/profil/presentation/profil_screen.dart`: Kart içi ürün başlıkları `maxLines:1, ellipsis` (960-962); AppBar title'ları ("Profil", "Reddedilen İlanlar", "Bekleyen Değerlendirmeler") sabit Türkçe metinler, kullanıcı girdisi değil — risk yok.

---

## İNCELENMEDİ (context sınırı / kapsam nedeniyle taranmadı)

- `lib/features/ilanlar/presentation/ilan_detay_screen.dart` dosyasının tamamı satır satır incelenmedi (yalnızca belirli bölümler: 240-330, 570-620, 774-1200, 1450-1470 civarı örnekleme yapıldı). Özellikle resim galerisi, yorum/soru bölümleri, harita/konum gösterimi gibi diğer bölümler taranmadı.
- `lib/features/profil/presentation/profil_screen.dart` dosyasının tamamı incelenmedi — yalnızca grep ile Row/title örnekleri örneklendi, avatar+isim üst bölüm (satır 214-330 civarı) kısmen görüldü ama tam widget ağacı doğrulanmadı.
- `lib/features/mesajlar/presentation/sohbet_screen.dart` dosyasında mesaj listesi (`_MesajListesi`), input bar (`_InputBar`) ve üst kullanıcı bilgisi bloğunun tamamı satır satır okunmadı; yalnızca grep örnekleme + belirli aralıklar (495-655, 1080-1140) okundu.
- GridView/ListView `childAspectRatio` (Kalıp 4) için proje genelinde ayrı bir arama yapılmadı — bu kalıba özgü dosyalar tespit edilip doğrulanmadı.
- `lib/features/profil/presentation/kullanici_profil_screen.dart` dosyasının ilan listesi/alt sekmeleri (satır 370+) detaylıca incelenmedi.
- Kategori isimlerinin gerçek maksimum uzunluğu (bulgu #1 ile ilgili) — kategori sabitleri dosyası açılmadı, bu yüzden #1 "kesin taşar" olarak değil "taşabilir" olarak işaretlendi.
- Diğer presentation/ dizinleri (ör. ilan_form ekranları, arama/filtre ekranları, bildirimler, ayarlar) hiç açılmadı.

---

## Launch öncesi düzeltilmesi gereken, KESİN overflow riski taşıyan (Kritik) konum var mı?

**Hayır — kod okumasıyla "kesin taşar" seviyesinde (Kritik) doğrulanmış bir bulgu YOK.**

En yüksek risk taşıyan 3 konum (Orta seviye, launch öncesi gözden geçirilmesi önerilir ama kesin çökme/overflow garantisi yok):

1. `lib/features/ilanlar/presentation/ilan_detay_screen.dart:579-615` — kategori rozeti Text'ine `maxLines:1, overflow: TextOverflow.ellipsis` eklenmesi veya Row'a `Flexible` sarılması önerilir (kategori adı uzun olursa Row taşabilir).
2. `lib/features/profil/presentation/kullanici_profil_screen.dart:117-119` — SliverAppBar title'a `maxLines:1, overflow: TextOverflow.ellipsis` eklenmesi önerilir.
3. `lib/features/degerlendirme/presentation/degerlendirmeler_liste_screen.dart:127-131` — AppBar title'a `maxLines:1, overflow: TextOverflow.ellipsis` eklenmesi önerilir.

Bu üçü de "uzun kullanıcı girdisi/kategori adı" durumunda taşma riski taşır ancak gerçek maksimum uzunluklar doğrulanmadığından Kritik değil Orta olarak sınıflandırıldı. Geri kalan bulgular (4-6) düşük risklidir ve kart/liste yapıları zaten Expanded/Flexible ile korunmuş olduğundan pratik bir sorun oluşturması olası değildir.
