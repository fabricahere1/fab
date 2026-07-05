// lib/features/home/presentation/alisveris_rehberi_bolum.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';

enum _TagTipi { ucuz, ozel, populer }

class _Urun {
  final String ad;
  final String aciklama;
  final _TagTipi tag;
  const _Urun(this.ad, this.aciklama, this.tag);
}

class _Kategori {
  final String ad;
  final IconData ikon;
  final List<_Urun> urunler;
  const _Kategori(this.ad, this.ikon, this.urunler);
}

class _Sehir {
  final String id;
  final String ad;
  final String resimYolu;
  final String baslik;
  final List<_Kategori> kategoriler;
  const _Sehir(this.id, this.ad, this.resimYolu, this.baslik, this.kategoriler);
}

final _sehirler = <_Sehir>[

  _Sehir('ny', 'New York', 'assets/images/rehber/new_york.png', "New York'tan gelecek taşıyıcıdan ne istenir?", [
    _Kategori('Ayakkabı & Spor', Symbols.steps, [
      _Urun('Nike / Jordan özel seri', "Türkiye'ye gelmeyen colorway'ler, outlet'te %40-60 ucuz", _TagTipi.ozel),
      _Urun('New Balance 9060', "Nordstrom Rack'te indirimli, Türkiye fiyatının yarısı", _TagTipi.ucuz),
      _Urun('Adidas Yeezy / Samba', "US'te stok çok bol, fiyatlar %30-50 daha düşük", _TagTipi.ucuz),
      _Urun('Timberland & UGG', "Kış sezonu sonunda outlet'te çok uygun", _TagTipi.ucuz),
      _Urun('Converse & Vans', "ABD markası, Türkiye'de 2-3x pahalı", _TagTipi.ucuz),
      _Urun('Skechers', "ABD markası, fabrika outlet'te çok ucuz", _TagTipi.ucuz),
    ]),
    _Kategori('Kozmetik & Parfüm', Symbols.experiment, [
      _Urun('Rare Beauty', "Türkiye'de resmi satış yok, Sephora'dan al", _TagTipi.ozel),
      _Urun('Rhode', "Türkiye'de resmi satış yok, peptide lip tint popüler", _TagTipi.ozel),
      _Urun('elf Cosmetics', "Türkiye'de çok pahalı, US'te 1-5 dolar arası ürünler var", _TagTipi.ucuz),
      _Urun('Fenty Beauty', "Türkiye'de resmi satış yok veya çok pahalı", _TagTipi.ozel),
      _Urun('Bath & Body Works', "Losyon, vücut spreyi, mum — Türkiye'de resmi mağaza yok", _TagTipi.populer),
      _Urun('Duty Free parfüm JFK', "Chanel, Dior, YSL, Tom Ford — Türkiye fiyatının yarısı", _TagTipi.ucuz),
      _Urun('NYX Professional Makeup', "Türkiye'de 3-4x pahalı, Ulta'dan çok uygun", _TagTipi.ucuz),
      _Urun('Benefit Cosmetics', "Sephora'da set halinde çok uygun", _TagTipi.ucuz),
    ]),
    _Kategori('Elektronik', Symbols.devices, [
      _Urun('Beats kulaklık', "Best Buy'da ABD fiyatı Türkiye'nin %40 altında", _TagTipi.ucuz),
      _Urun('JBL hoparlör', "ABD üretimi, Türkiye'de 2x pahalı", _TagTipi.ucuz),
      _Urun('GoPro & aksesuarlar', "US fiyatı Türkiye'nin %40 altında", _TagTipi.ucuz),
      _Urun('iPad aksesuarları', "Apple Pencil, Magic Keyboard — Türkiye'de 2x pahalı", _TagTipi.ucuz),
      _Urun('Anker şarj cihazları', "ABD markası, doğrudan ülkesinde ucuz", _TagTipi.ucuz),
      _Urun('Gaming aksesuarları', "Razer, SteelSeries — Türkiye'den ucuz", _TagTipi.ucuz),
    ]),
    _Kategori('Vitamin & Takviye', Symbols.nutrition, [
      _Urun('Costco vitamin seti', "Omega-3, D3, B12 — Türkiye'de 3-4x pahalı", _TagTipi.ucuz),
      _Urun('Optimum Nutrition Protein', "5 lb kutu — Türkiye'de 2x fiyatına satılıyor", _TagTipi.ucuz),
      _Urun('Collagen takviyesi', "Vital Proteins — Türkiye'de resmi dağıtım yok", _TagTipi.ozel),
      _Urun('Melatonin gummies', "ABD'de ucuz ve çeşitli, Türkiye'de reçeteli", _TagTipi.ozel),
      _Urun('Pre-workout C4 / Ghost', "Türkiye'de ya yok ya da çok pahalı", _TagTipi.ucuz),
    ]),
    _Kategori('Giyim & Moda', Symbols.styler, [
      _Urun("Levi's 501 jeans", "Türkiye'den 2-3x daha ucuz", _TagTipi.ucuz),
      _Urun('Ralph Lauren Polo', "Outlet'te %50-70 indirimli", _TagTipi.ucuz),
      _Urun('Coach / Kate Spade', "Woodbury Common outlet'te %70'e kadar indirim", _TagTipi.populer),
      _Urun('Tommy Hilfiger & CK', "ABD markası, kendi ülkesinde %40-50 ucuz", _TagTipi.ucuz),
      _Urun('Michael Kors çanta', "Outlet'te Türkiye fiyatının üçte biri", _TagTipi.populer),
      _Urun('Abercrombie & Fitch', "Türkiye'de resmi mağaza yok", _TagTipi.ozel),
    ]),
    _Kategori('Ev & Yaşam', Symbols.home, [
      _Urun('KitchenAid mutfak robotu', "ABD markası, Türkiye'de 3x pahalı", _TagTipi.ucuz),
      _Urun('Lodge dökme demir tava', "TJ Maxx'te çok uygun", _TagTipi.ucuz),
      _Urun('Yankee Candle mum seti', "Türkiye'de 3x pahalı", _TagTipi.ucuz),
      _Urun('Instant Pot', "Türkiye'de resmi garantisi yok, 2x pahalı", _TagTipi.ucuz),
    ]),
  ]),

  _Sehir('london', 'Londra', 'assets/images/rehber/londra.png', "Londra'dan gelecek taşıyıcıdan ne istenir?", [
    _Kategori('Giyim & Moda', Symbols.styler, [
      _Urun('ASOS özel seri', "Sale'de Türkiye fiyatının çok altında", _TagTipi.ucuz),
      _Urun('Burberry outlet', "Bicester Village'da %50-70 indirim", _TagTipi.populer),
      _Urun('Dr Martens', "İngiliz markası, Türkiye'de 2x pahalı", _TagTipi.ucuz),
      _Urun('Ted Baker & Reiss', "İngiliz orta segment, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Barbour ceket', "İngiliz ikonik marka, Türkiye'de resmi satış yok", _TagTipi.ozel),
      _Urun('Next & M&S giyim', "Sale'de çok uygun İngiliz markalar", _TagTipi.ucuz),
    ]),
    _Kategori('Kozmetik', Symbols.experiment, [
      _Urun('Charlotte Tilbury', "İngiliz lüks kozmetik, Türkiye'de resmi satış yok", _TagTipi.ozel),
      _Urun('The Body Shop seti', "Sale'de %50 indirim", _TagTipi.ucuz),
      _Urun('Elemis cilt bakım', "İngiliz premium marka, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Lush el yapımı', "Türkiye'de çok az mağaza, fiyatlar yüksek", _TagTipi.ucuz),
      _Urun('Revolution Beauty', "Çok uygun İngiliz markası, Türkiye'de yok", _TagTipi.ucuz),
    ]),
    _Kategori('Gıda & İçecek', Symbols.grocery, [
      _Urun('Cadbury çikolata seti', "Türkiye'de bulunmayan tatlar: Caramel, Wispa", _TagTipi.ozel),
      _Urun('M&S gıda hediyelik', "Bisküvi seti, çaylar — Türkiye'de yok", _TagTipi.populer),
      _Urun('Yorkshire Tea & Clipper', "Kaliteli İngiliz çayları, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Marmite & HP Sauce', "İngiliz ikonik gıdalar, Türkiye'de bulunmaz", _TagTipi.ozel),
    ]),
    _Kategori('Elektronik', Symbols.devices, [
      _Urun('Dyson Airwrap', "İngiliz markası, UK'de %20-30 ucuz", _TagTipi.ucuz),
      _Urun('Dyson V15 süpürge', "Türkiye'de çok pahalı", _TagTipi.ucuz),
    ]),
  ]),

  _Sehir('paris', 'Paris', 'assets/images/rehber/paris.png', "Paris'ten gelecek taşıyıcıdan ne istenir?", [
    _Kategori('Lüks Moda', Symbols.shopping_bag, [
      _Urun('Longchamp Le Pliage', "Paris'te Türkiye'ye göre %25-30 ucuz", _TagTipi.populer),
      _Urun('APC giyim', "Fransız minimal moda markası, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Sandro & Maje', "Fransız orta segment, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Isabel Marant', "Fransız bohem moda, Türkiye'de yok", _TagTipi.ozel),
    ]),
    _Kategori('Parfüm', Symbols.air_freshener, [
      _Urun('Diptyque mum & parfüm', "Paris'te Türkiye'nin %40 altında", _TagTipi.ozel),
      _Urun('Maison Margiela Replica', "Türkiye'de çok pahalı, Paris'te %30 ucuz", _TagTipi.ucuz),
      _Urun('Byredo parfüm', "Türkiye'de resmi satış yok", _TagTipi.ozel),
      _Urun('Duty Free Chanel / Dior', "CDG'de Türkiye fiyatının yarısı", _TagTipi.ucuz),
      _Urun('Annick Goutal', "Fransız butik parfüm, Türkiye'de yok", _TagTipi.ozel),
    ]),
    _Kategori('Cilt Bakımı', Symbols.face_retouching_natural, [
      _Urun('La Roche-Posay', "Fransız eczane markası, Türkiye'de 2x pahalı", _TagTipi.ucuz),
      _Urun('Vichy Liftactiv', "Paris eczanesinden çok uygun", _TagTipi.ucuz),
      _Urun('Embryolisse krem', "Makyaj sanatçılarının tercihi, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Avène thermal su', "Paris eczanesinden çok ucuz", _TagTipi.ozel),
      _Urun('Nuxe Huile Prodigieuse', "Fransız cilt yağı, Türkiye'de 2x pahalı", _TagTipi.ucuz),
    ]),
    _Kategori('Gıda & Mutfak', Symbols.grocery, [
      _Urun('Valrhona çikolata', "Şeflerin kullandığı Fransız çikolata", _TagTipi.ucuz),
      _Urun('Maille hardal çeşitleri', "Dijon hardalı, Türkiye'de bulunmaz", _TagTipi.ozel),
      _Urun('Fauchon reçel seti', "Fransız gurme gıda, özel tatlar", _TagTipi.ozel),
    ]),
  ]),

  _Sehir('tokyo', 'Tokyo', 'assets/images/rehber/tokyo.png', "Tokyo'dan gelecek taşıyıcıdan ne istenir?", [
    _Kategori('Oyun & Anime', Symbols.sports_esports, [
      _Urun('Nintendo Switch Japonya exclusive', "Japonya'ya özel oyunlar, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Pokemon Center ürünleri', "Türkiye'de yok, orijinal koleksiyon", _TagTipi.populer),
      _Urun('Anime figür orijinal', "Akihabara'dan orijinal, Türkiye'de sahte çok", _TagTipi.populer),
      _Urun('Amiibo figure', "Nintendo koleksiyon, Japonya özel seri", _TagTipi.ozel),
    ]),
    _Kategori('Cilt Bakımı', Symbols.face_retouching_natural, [
      _Urun('SK-II Facial Essence', "Japonya'da %40 ucuz, orijinal garantili", _TagTipi.ucuz),
      _Urun('Shiseido Ultimune', "Japonya'da üretiliyor, %30-40 ucuz", _TagTipi.ucuz),
      _Urun('Hada Labo Gokujyun', "Japonya'da çok ucuz, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Biore / Anessa güneş kremi', "Japon güneş kremleri Türkiye'de yok", _TagTipi.ozel),
      _Urun('DHC Deep Cleansing Oil', "Japonya'da Türkiye'nin çok altında", _TagTipi.ucuz),
    ]),
    _Kategori('Sneaker & Giyim', Symbols.steps, [
      _Urun('Asics Japonya özel seri', "Japan exclusive colorway, hiçbir yerde satılmıyor", _TagTipi.ozel),
      _Urun('Onitsuka Tiger', "Türkiye'de 2x pahalı, Japonya'da geniş koleksiyon", _TagTipi.ucuz),
      _Urun('Uniqlo özel koleksiyon', "HEATTECH serisi çok popüler, Türkiye'de mağaza yok", _TagTipi.populer),
      _Urun('Muji ürünleri', "Japonya'da çok ucuz, Türkiye'de yok", _TagTipi.ucuz),
    ]),
    _Kategori('Gıda & Atıştırmalık', Symbols.grocery, [
      _Urun('Kit Kat özel Japon tatları', "Matcha, Sakura, Wasabi — Türkiye'de yok", _TagTipi.ozel),
      _Urun('Pocky & Pretz özel seri', "Japonya'ya özel tatlar", _TagTipi.ozel),
      _Urun('Meiji çikolata', "Japonya'da üretiliyor, çok ucuz", _TagTipi.ucuz),
    ]),
  ]),

  _Sehir('dubai', 'Dubai', 'assets/images/rehber/dubai.png', "Dubai'den gelecek taşıyıcıdan ne istenir?", [
    _Kategori('Duty Free & Parfüm', Symbols.flight_takeoff, [
      _Urun('Creed Aventus', "Dubai Duty Free'de Türkiye fiyatının %50 altında", _TagTipi.populer),
      _Urun('Amouage Gold / Interlude', "Orta Doğu'da üretilen lüks parfüm, Türkiye'de çok pahalı", _TagTipi.ozel),
      _Urun('Oud & Arap parfümleri', "Ajmal, Abdul Samad — Türkiye'de yok", _TagTipi.ozel),
      _Urun('Tom Ford parfüm', "Dubai Duty Free'de %30-40 ucuz", _TagTipi.ucuz),
      _Urun('Bakhoor & oud tütsü', "Arap geleneği, Türkiye'de yok", _TagTipi.ozel),
    ]),
    _Kategori('Altın & Takı', Symbols.diamond, [
      _Urun('22 ayar altın kolye', "Gold Souk'ta işçilik Türkiye'nin üçte biri", _TagTipi.ucuz),
      _Urun('El yapımı gümüş takı', "Gold Souk'ta çok uygun", _TagTipi.ucuz),
      _Urun('Oud ahşap tespih', "El yapımı, Türkiye'de çok nadir", _TagTipi.ozel),
    ]),
    _Kategori('Elektronik', Symbols.devices, [
      _Urun('iPhone (KDV 0)', "Dubai'de KDV yok, Türkiye'den %20-30 ucuz", _TagTipi.ucuz),
      _Urun('Samsung Galaxy', "Global versiyon, Türkiye fiyatının %20 altında", _TagTipi.ucuz),
      _Urun('Sony & Canon kamera', "KDV avantajı, Türkiye'den %15-20 ucuz", _TagTipi.ucuz),
      _Urun('PS5 oyunları', "KDV avantajı ile Türkiye'den ucuz", _TagTipi.ucuz),
    ]),
    _Kategori('Giyim & Marka', Symbols.styler, [
      _Urun('Ralph Lauren', "Saks Dubai outlet'te %50-90 indirim", _TagTipi.ucuz),
      _Urun('Hugo Boss', "Dubai Mall'da Türkiye'den %20-25 ucuz", _TagTipi.ucuz),
    ]),
  ]),

  _Sehir('berlin', 'Berlin', 'assets/images/rehber/berlin.png', "Berlin'den gelecek taşıyıcıdan ne istenir?", [
    _Kategori('Giyim', Symbols.styler, [
      _Urun('Zalando outlet', "Almanya'da ucuz, Türkiye'ye kargo yok", _TagTipi.ucuz),
      _Urun('Adidas Almanya özel seri', "Alman markası, özel renkler ve koleksiyonlar", _TagTipi.ozel),
      _Urun('Hugo Boss outlet', "Almanya'da %30-40 ucuz", _TagTipi.ucuz),
      _Urun('Birkenstock', "Alman markası, kendi ülkesinde %20-30 ucuz", _TagTipi.ucuz),
    ]),
    _Kategori('Cilt & Saç Bakımı', Symbols.face_retouching_natural, [
      _Urun('Nivea Almanya özel serisi', "Alman formülü Türkiye'dekinden farklı", _TagTipi.ozel),
      _Urun('Weleda doğal bakım', "Alman organik marka, Türkiye'de çok pahalı", _TagTipi.ucuz),
      _Urun('Lavera vegan kozmetik', "Alman sertifikalı organik, Türkiye'de yok", _TagTipi.ozel),
      _Urun('dm Drogerie özel marka', "Çok ucuz ve kaliteli Alman ürünleri", _TagTipi.ucuz),
    ]),
    _Kategori('Gıda', Symbols.grocery, [
      _Urun('Haribo şeker çeşitleri', "Alman markası, Türkiye'de çok pahalı ve az çeşit", _TagTipi.ucuz),
      _Urun('Ritter Sport özel tatlar', "Almanya'ya özel tatlar, Türkiye'de yok", _TagTipi.ozel),
      _Urun('Bahlsen bisküvi seti', "Alman bisküvi, Türkiye'de yok", _TagTipi.ozel),
    ]),
  ]),

  _Sehir('milano', 'Milano', 'assets/images/rehber/milano.png', "Milano'dan gelecek taşıyıcıdan ne istenir?", [
    _Kategori('Deri & Çanta', Symbols.shopping_bag, [
      _Urun('Furla çanta', "İtalyan deri çanta, Türkiye'de 2x pahalı", _TagTipi.ucuz),
      _Urun('Coccinelle çanta', "Milano'da Türkiye'nin yarısı", _TagTipi.ucuz),
      _Urun('Gucci / Prada outlet', "Serravalle outlet'te %30-50 indirim", _TagTipi.populer),
      _Urun('Bottega Veneta aksesuar', "İtalya'da %20-25 ucuz", _TagTipi.ucuz),
    ]),
    _Kategori('Ayakkabı', Symbols.steps, [
      _Urun("Tod's loafer", "İtalyan el yapımı ayakkabı, üretildiği ülkede ucuz", _TagTipi.ucuz),
      _Urun('Geox & Camper', "İtalyan konfor ayakkabı, Türkiye'de 2x pahalı", _TagTipi.ucuz),
      _Urun('Golden Goose sneaker', "İtalyan sneaker, Türkiye'de çok pahalı", _TagTipi.ucuz),
      _Urun('Premiata sneaker', "İtalyan tasarım, Türkiye'de yok", _TagTipi.ozel),
    ]),
    _Kategori('Moda Aksesuar', Symbols.styler, [
      _Urun('Armani / Versace güneş gözlüğü', "İtalya'da %20-30 ucuz, orijinal garantili", _TagTipi.ucuz),
      _Urun('Max Mara trençkot', "İtalyan kalite, Türkiye'de çok pahalı", _TagTipi.ozel),
    ]),
  ]),

  _Sehir('seul', 'Seul', 'assets/images/rehber/seul.png', "Seul'den gelecek taşıyıcıdan ne istenir?", [
    _Kategori('K-Beauty', Symbols.experiment, [
      _Urun('Laneige Water Sleeping Mask', "Kore'de üretiliyor, Türkiye'ye göre %50 ucuz", _TagTipi.ucuz),
      _Urun('COSRX Advanced Snail', "Salyangoz özlü serum, Türkiye'de sahte çok", _TagTipi.populer),
      _Urun('INNISFREE Green Tea Serum', "Türkiye'de resmi satış yok", _TagTipi.ozel),
      _Urun('Sulwhasoo first care', "Kore lüks bakım, Türkiye'de çok pahalı", _TagTipi.ucuz),
      _Urun('Missha Time Revolution', "Kore best seller, Türkiye'de nadir", _TagTipi.ozel),
      _Urun('Beauty of Joseon', "Kore geleneksel bakım, Türkiye'de yok", _TagTipi.ozel),
    ]),
    _Kategori('K-Pop & Koleksiyon', Symbols.music_note, [
      _Urun('BTS / Blackpink merch', "Weverse Shop orijinal, Türkiye'de sahte çok", _TagTipi.populer),
      _Urun('Aespa / NewJeans photocard', "Orijinal album ve photocard, Kore özel", _TagTipi.ozel),
      _Urun('Hybe / SM / JYP mağaza', "Artist exclusive ürünler", _TagTipi.ozel),
    ]),
    _Kategori('K-Fashion', Symbols.styler, [
      _Urun('Gentle Monster gözlük', "Kore tasarım, Türkiye'de %40 pahalı", _TagTipi.ucuz),
      _Urun('Ader Error giyim', "Kore designer marka, Türkiye'de yok", _TagTipi.ozel),
      _Urun('MLB Korea cap', "Kore'de çok popüler, Türkiye'de yok", _TagTipi.ozel),
    ]),
    _Kategori('Elektronik', Symbols.devices, [
      _Urun('Samsung Kore sürümü', "Kore versiyonunda ek özellikler, fiyat Türkiye'den ucuz", _TagTipi.ucuz),
      _Urun('LG gram laptop', "Kore'de üretiliyor, %15-20 ucuz", _TagTipi.ucuz),
    ]),
  ]),
];

class AlisverisRehberiBolum extends StatefulWidget {
  const AlisverisRehberiBolum({super.key});

  @override
  State<AlisverisRehberiBolum> createState() => _AlisverisRehberiBolumState();
}

class _AlisverisRehberiBolumState extends State<AlisverisRehberiBolum> {
  int _seciliIndex = 0;
  final Set<int> _acikKategoriler = {};

  void _sehirDegistir(int index) {
    setState(() {
      _seciliIndex = index;
      _acikKategoriler.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sehir = _sehirler[_seciliIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(children: [
            const Icon(Symbols.travel_explore, size: 16, color: AppColors.red),
            const SizedBox(width: 6),
            Text('İstekçi rehberi',
                style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary)),
          ]),
        ),
        // ── Şehir seçim listesi ──────────────────────────────────
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _sehirler.length,
            itemBuilder: (_, i) {
              final s = _sehirler[i];
              final aktif = i == _seciliIndex;
              return GestureDetector(
                onTap: () => _sehirDegistir(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: aktif ? AppColors.red : Colors.transparent,
                      width: aktif ? 2 : 0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(aktif ? 10 : 12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          s.resimYolu,
                          fit: BoxFit.fill,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.location_city_outlined,
                                color: AppColors.textHint),
                          ),
                        ),
                        // Gradient overlay
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: aktif ? 0.75 : 0.55),
                              ],
                            ),
                          ),
                        ),
                        // Şehir adı
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Text(
                            s.ad,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(sehir.baslik,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: sehir.kategoriler.asMap().entries.map((e) {
              final i = e.key;
              final k = e.value;
              return _KategoriKarti(
                kategori: k,
                acik: _acikKategoriler.contains(i),
                onToggle: () => setState(() {
                  if (_acikKategoriler.contains(i)) {
                    _acikKategoriler.remove(i);
                  } else {
                    _acikKategoriler.add(i);
                  }
                }),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _KategoriKarti extends StatelessWidget {
  final _Kategori kategori;
  final bool acik;
  final VoidCallback onToggle;
  const _KategoriKarti({required this.kategori, required this.acik, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(children: [
                Icon(kategori.ikon, size: 20, weight: 300, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(kategori.ad,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ),
                AnimatedRotation(
                  turns: acik ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Symbols.expand_more, size: 18, color: AppColors.textSecondary),
                ),
              ]),
            ),
          ),
          if (acik)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: Column(
                children: kategori.urunler.asMap().entries.map((e) {
                  final i = e.key;
                  final u = e.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: i < kategori.urunler.length - 1
                          ? Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))
                          : null,
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.ad,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(u.aciklama,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                      height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Tag(u.tag),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final _TagTipi tip;
  const _Tag(this.tip);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color renk;
    final String metin;
    switch (tip) {
      case _TagTipi.ucuz:
        bg = const Color(0xFFE1F5EE); renk = const Color(0xFF0F6E56); metin = 'Ucuz'; break;
      case _TagTipi.ozel:
        bg = const Color(0xFFEDE7F6); renk = const Color(0xFF4527A0); metin = "TR'de yok"; break;
      case _TagTipi.populer:
        bg = const Color(0xFFFCE4EC); renk = const Color(0xFF880E4F); metin = 'Popüler'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(metin,
          style: GoogleFonts.dmSans(
              fontSize: 9, fontWeight: FontWeight.w600, color: renk)),
    );
  }
}