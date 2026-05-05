/// Firestore koleksiyon adları.
/// String literal yerine bu sabitleri kullan — yazım hatalarını önler.
class Collections {
  Collections._();
  static const String ilanlar          = 'ilanlar';
  static const String kullanicilar     = 'kullanicilar';
  static const String sohbetler        = 'sohbetler';
  static const String mesajlar         = 'mesajlar';
  static const String favoriler        = 'favoriler';
  static const String degerlendirmeler = 'degerlendirmeler';
  static const String sikayetler       = 'sikayetler';
  static const String bildirimler      = 'bildirimler';
  static const String mail             = 'mail';
}

/// İlan tipleri.
class IlanTip {
  IlanTip._();
  static const String istek    = 'istek';
  static const String tasiyici = 'tasiyici';
}

/// Alt kategori modeli.
class AltKategori {
  final String key;
  final String ad;
  const AltKategori({required this.key, required this.ad});
}

/// Ana kategori modeli.
class AnaKategori {
  final String key;
  final String ad;
  final String emoji;
  final List<AltKategori> altlar;
  const AnaKategori({
    required this.key,
    required this.ad,
    required this.emoji,
    this.altlar = const [],
  });
}

/// Tüm kategori ağacı.
/// Yeni kategori/alt kategori eklemek için sadece buraya eklemek yeterli.
const List<AnaKategori> kKategoriAgaci = [
  AnaKategori(
    key: 'giyim',
    ad: 'Giyim & Aksesuar',
    emoji: '👗',
    altlar: [
      AltKategori(key: 'giyim_ust',      ad: 'Üst Giyim'),
      AltKategori(key: 'giyim_dis',      ad: 'Dış Giyim'),
      AltKategori(key: 'giyim_alt',      ad: 'Alt Giyim'),
      AltKategori(key: 'giyim_elbise',   ad: 'Elbise'),
      AltKategori(key: 'giyim_bebek',    ad: 'Bebek Giyim'),
      AltKategori(key: 'giyim_ev',       ad: 'Ev Giyim'),
      AltKategori(key: 'giyim_ic',       ad: 'İç Giyim'),
      AltKategori(key: 'giyim_tesettur', ad: 'Tesettür Giyim'),
      AltKategori(key: 'giyim_spor',     ad: 'Spor Giyim'),
      AltKategori(key: 'giyim_takim',    ad: 'İkili Takım'),
      AltKategori(key: 'giyim_abiye',    ad: 'Abiye & Mezuniyet'),
      AltKategori(key: 'giyim_aksesuar', ad: 'Aksesuar'),
    ],
  ),
  AnaKategori(
    key: 'elektronik',
    ad: 'Elektronik',
    emoji: '📱',
    altlar: [
      AltKategori(key: 'elek_telefon',    ad: 'Telefon'),
      AltKategori(key: 'elek_bilgisayar', ad: 'Bilgisayar'),
      AltKategori(key: 'elek_tablet',     ad: 'Tablet'),
      AltKategori(key: 'elek_tv',         ad: 'TV & Görüntü'),
      AltKategori(key: 'elek_ses',        ad: 'Ses Sistemleri'),
      AltKategori(key: 'elek_oyun',       ad: 'Oyun & Konsol'),
      AltKategori(key: 'elek_kamera',     ad: 'Fotoğraf & Kamera'),
      AltKategori(key: 'elek_aksesuar',   ad: 'Aksesuar'),
    ],
  ),
  AnaKategori(
    key: 'guzellik',
    ad: 'Güzellik & Sağlık',
    emoji: '💄',
    altlar: [
      AltKategori(key: 'guz_makyaj',  ad: 'Makyaj'),
      AltKategori(key: 'guz_cilt',    ad: 'Cilt Bakımı'),
      AltKategori(key: 'guz_sac',     ad: 'Saç Bakımı'),
      AltKategori(key: 'guz_parfum',  ad: 'Parfüm'),
      AltKategori(key: 'guz_saglik',  ad: 'Sağlık Ürünleri'),
    ],
  ),
  AnaKategori(
    key: 'ev',
    ad: 'Ev & Yaşam',
    emoji: '🏠',
    altlar: [
      AltKategori(key: 'ev_mobilya',  ad: 'Mobilya'),
      AltKategori(key: 'ev_mutfak',   ad: 'Mutfak'),
      AltKategori(key: 'ev_dekor',    ad: 'Dekorasyon'),
      AltKategori(key: 'ev_tekstil',  ad: 'Ev Tekstili'),
      AltKategori(key: 'ev_bahce',    ad: 'Bahçe'),
    ],
  ),
  AnaKategori(
    key: 'spor',
    ad: 'Spor & Outdoor',
    emoji: '⚽',
    altlar: [
      AltKategori(key: 'spor_ekipman',  ad: 'Spor Ekipmanı'),
      AltKategori(key: 'spor_giyim',    ad: 'Spor Giyim'),
      AltKategori(key: 'spor_ayakkabi', ad: 'Spor Ayakkabı'),
      AltKategori(key: 'spor_outdoor',  ad: 'Outdoor & Kamp'),
      AltKategori(key: 'spor_bisiklet', ad: 'Bisiklet'),
    ],
  ),
  AnaKategori(
    key: 'kultur',
    ad: 'Kültür & Eğlence',
    emoji: '📚',
    altlar: [
      AltKategori(key: 'kul_kitap',      ad: 'Kitap'),
      AltKategori(key: 'kul_muzik',      ad: 'Müzik'),
      AltKategori(key: 'kul_film',       ad: 'Film & Dizi'),
      AltKategori(key: 'kul_oyuncak',    ad: 'Oyuncak & Hobi'),
      AltKategori(key: 'kul_koleksiyon', ad: 'Koleksiyon'),
    ],
  ),
  AnaKategori(
    key: 'gida',
    ad: 'Gıda & İçecek',
    emoji: '🍫',
    altlar: [
      AltKategori(key: 'gida_yiyecek', ad: 'Yiyecek'),
      AltKategori(key: 'gida_icecek',  ad: 'İçecek'),
      AltKategori(key: 'gida_organik', ad: 'Organik & Doğal'),
    ],
  ),
  AnaKategori(
    key: 'diger',
    ad: 'Diğer',
    emoji: '📦',
    altlar: [],
  ),
];

/// Geriye dönük uyumluluk için düz map — ilan kaydetme/okumada kullanılır.
/// kKategoriAgaci'ndan otomatik üretilir, ayrıca güncellemeye gerek yok.
final Map<String, String> kKategoriler = () {
  final map = <String, String>{};
  for (final ana in kKategoriAgaci) {
    map[ana.key] = '${ana.emoji} ${ana.ad}';
    for (final alt in ana.altlar) {
      map[alt.key] = alt.ad;
    }
  }
  return map;
}();

/// Kategori anahtarından okunabilir ad döndürür.
String kategoriAdi(String? key) {
  if (key == null || key.isEmpty) return '';
  for (final ana in kKategoriAgaci) {
    if (ana.key == key) return '${ana.emoji} ${ana.ad}';
    for (final alt in ana.altlar) {
      if (alt.key == key) return alt.ad;
    }
  }
  return '📦 Diğer';
}

/// Firebase Storage klasörleri.
class StoragePaths {
  StoragePaths._();
  static const String ilanResimleri  = 'ilan_resimleri';
  static const String profilFotolari = 'profil_fotograflari';
  static const String mesajResimleri = 'mesaj_resimleri';
}

/// Sayfalama sabitleri.
class Pagination {
  Pagination._();
  static const int ilanSayfaBoyutu  = 20;
  static const int mesajSayfaBoyutu = 30;
  static const int maxResimSayisi   = 4;
}

/// Kargo şirketleri ve takip numarası kuralları.
class KargoSirketi {
  final String key;
  final String ad;
  final int haneSayisi;

  const KargoSirketi({
    required this.key,
    required this.ad,
    required this.haneSayisi,
  });

  static const List<KargoSirketi> hepsi = [
    KargoSirketi(key: 'yurtici', ad: 'Yurtiçi Kargo', haneSayisi: 12),
    KargoSirketi(key: 'mng',     ad: 'MNG Kargo',      haneSayisi: 12),
    KargoSirketi(key: 'surat',   ad: 'Sürat Kargo',    haneSayisi: 14),
    KargoSirketi(key: 'ptt',     ad: 'PTT Kargo',      haneSayisi: 13),
  ];

  static KargoSirketi? fromKey(String key) {
    try {
      return hepsi.firstWhere((k) => k.key == key);
    } catch (_) {
      return null;
    }
  }
}

/// Türkiye'nin 81 ili — profil tamamlama ve düzenleme ekranlarında kullanılır.
const List<String> kTurkiyeSehirleri = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya',
  'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir',
  'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis',
  'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
  'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
  'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
  'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
  'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu',
  'Kayseri', 'Kilis', 'Kırıkkale', 'Kırklareli', 'Kırşehir',
  'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Mardin',
  'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye',
  'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Şanlıurfa',
  'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak',
  'Van', 'Yalova', 'Yozgat', 'Zonguldak',
];

/// Dünya ülkeleri — profil tamamlama ve ilan formlarında kullanılır.
const List<String> kDunyaUlkeleri = [
  'Türkiye',
  'Almanya', 'Amerika Birleşik Devletleri', 'Arjantin', 'Avustralya',
  'Avusturya', 'Azerbaycan', 'Belçika', 'Birleşik Arap Emirlikleri',
  'Birleşik Krallık', 'Brezilya', 'Çin', 'Danimarka', 'Endonezya',
  'Fas', 'Filipinler', 'Finlandiya', 'Fransa', 'Güney Afrika',
  'Güney Kore', 'Gürcistan', 'Hindistan', 'Hollanda', 'İran',
  'İrlanda', 'İspanya', 'İsveç', 'İsviçre', 'İtalya', 'Japonya',
  'Kanada', 'Katar', 'Kazakistan', 'Kuveyt', 'Lübnan', 'Macaristan',
  'Malezya', 'Meksika', 'Mısır', 'Norveç', 'Özbekistan', 'Pakistan',
  'Polonya', 'Portekiz', 'Romanya', 'Rusya', 'Suudi Arabistan',
  'Singapur', 'Tayland', 'Ukrayna', 'Ürdün', 'Vietnam', 'Yunanistan',
  'Çek Cumhuriyeti', 'Slovakya', 'Hırvatistan', 'Bosna Hersek',
  'Sırbistan', 'Bulgaristan', 'Arnavutluk', 'Karadağ', 'Kosova',
  'Kıbrıs', 'Irak', 'Suriye', 'İsrail', 'Filistin', 'Umman',
  'Bahreyn', 'Yemen', 'Afganistan', 'Bangladeş', 'Sri Lanka', 'Nepal',
];

/// Dünya şehirleri — ilan formlarında nereden/nereye alanlarında kullanılır.
const List<String> kDunyaSehirleri = [
  'Adana', 'Ankara', 'Antalya', 'Bursa', 'Diyarbakır', 'Eskişehir',
  'Gaziantep', 'İstanbul', 'İzmir', 'Kayseri', 'Konya', 'Mersin',
  'Samsun', 'Trabzon', 'Adıyaman', 'Afyonkarahisar',
  'Amsterdam', 'Antwerp', 'Athens', 'Atlanta', 'Auckland',
  'Bangkok', 'Barcelona', 'Beijing', 'Berlin', 'Boston', 'Brussels',
  'Budapest', 'Buenos Aires', 'Cairo', 'Calgary', 'Cape Town',
  'Chicago', 'Copenhagen', 'Dallas', 'Delhi', 'Denver', 'Doha',
  'Dubai', 'Dublin', 'Düsseldorf', 'Edinburgh', 'Frankfurt',
  'Geneva', 'Hamburg', 'Helsinki', 'Hong Kong', 'Houston',
  'Jakarta', 'Johannesburg', 'Karachi', 'Kuala Lumpur', 'Kuwait City',
  'Lagos', 'Lahore', 'Las Vegas', 'Lisbon', 'London', 'Los Angeles',
  'Lyon', 'Madrid', 'Manchester', 'Manila', 'Melbourne', 'Mexico City',
  'Miami', 'Milan', 'Montreal', 'Moscow', 'Mumbai', 'Munich',
  'Nairobi', 'New York', 'Nice', 'Osaka', 'Oslo', 'Paris',
  'Prague', 'Riyadh', 'Rome', 'San Francisco', 'Santiago',
  'São Paulo', 'Seoul', 'Shanghai', 'Singapore', 'Stockholm',
  'Sydney', 'Taipei', 'Tehran', 'Tel Aviv', 'Tokyo', 'Toronto',
  'Vancouver', 'Vienna', 'Warsaw', 'Washington DC', 'Zurich',
  'Almaty', 'Baku', 'Tbilisi', 'Tashkent', 'Kyiv', 'Minsk',
  'Bucharest', 'Sofia', 'Belgrade', 'Zagreb', 'Sarajevo',
  'Beirut', 'Amman', 'Baghdad', 'Damascus', 'Muscat', 'Abu Dhabi',
  'Islamabad', 'Dhaka', 'Colombo', 'Kathmandu',
];