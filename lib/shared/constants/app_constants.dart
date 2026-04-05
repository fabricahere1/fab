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
      AltKategori(key: 'elek_telefon',  ad: 'Telefon'),
      AltKategori(key: 'elek_bilgisayar', ad: 'Bilgisayar'),
      AltKategori(key: 'elek_tablet',   ad: 'Tablet'),
      AltKategori(key: 'elek_tv',       ad: 'TV & Görüntü'),
      AltKategori(key: 'elek_ses',      ad: 'Ses Sistemleri'),
      AltKategori(key: 'elek_oyun',     ad: 'Oyun & Konsol'),
      AltKategori(key: 'elek_kamera',   ad: 'Fotoğraf & Kamera'),
      AltKategori(key: 'elek_aksesuar', ad: 'Aksesuar'),
    ],
  ),
  AnaKategori(
    key: 'guzellik',
    ad: 'Güzellik & Sağlık',
    emoji: '💄',
    altlar: [
      AltKategori(key: 'guz_makyaj',    ad: 'Makyaj'),
      AltKategori(key: 'guz_cilt',      ad: 'Cilt Bakımı'),
      AltKategori(key: 'guz_sac',       ad: 'Saç Bakımı'),
      AltKategori(key: 'guz_parfum',    ad: 'Parfüm'),
      AltKategori(key: 'guz_saglik',    ad: 'Sağlık Ürünleri'),
    ],
  ),
  AnaKategori(
    key: 'ev',
    ad: 'Ev & Yaşam',
    emoji: '🏠',
    altlar: [
      AltKategori(key: 'ev_mobilya',    ad: 'Mobilya'),
      AltKategori(key: 'ev_mutfak',     ad: 'Mutfak'),
      AltKategori(key: 'ev_dekor',      ad: 'Dekorasyon'),
      AltKategori(key: 'ev_tekstil',    ad: 'Ev Tekstili'),
      AltKategori(key: 'ev_bahce',      ad: 'Bahçe'),
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
      AltKategori(key: 'kul_kitap',     ad: 'Kitap'),
      AltKategori(key: 'kul_muzik',     ad: 'Müzik'),
      AltKategori(key: 'kul_film',      ad: 'Film & Dizi'),
      AltKategori(key: 'kul_oyuncak',   ad: 'Oyuncak & Hobi'),
      AltKategori(key: 'kul_koleksiyon', ad: 'Koleksiyon'),
    ],
  ),
  AnaKategori(
    key: 'gida',
    ad: 'Gıda & İçecek',
    emoji: '🍫',
    altlar: [
      AltKategori(key: 'gida_yiyecek',  ad: 'Yiyecek'),
      AltKategori(key: 'gida_icecek',   ad: 'İçecek'),
      AltKategori(key: 'gida_organik',  ad: 'Organik & Doğal'),
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
Map<String, String> get kKategoriler {
  final map = <String, String>{};
  for (final ana in kKategoriAgaci) {
    map[ana.key] = '${ana.emoji} ${ana.ad}';
    for (final alt in ana.altlar) {
      map[alt.key] = alt.ad;
    }
  }
  return map;
}

/// Kategori anahtarından okunabilir ad döndürür.
String kategoriAdi(String? key) {
  if (key == null || key.isEmpty) return '';
  // Önce alt kategorilerde ara
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
}

/// Sayfalama sabitleri.
class Pagination {
  Pagination._();
  static const int ilanSayfaBoyutu  = 20;
  static const int mesajSayfaBoyutu = 30;
  static const int maxResimSayisi   = 4;
}