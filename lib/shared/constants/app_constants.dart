// lib/shared/constants/app_constants.dart

import 'package:flutter/material.dart';

/// Firestore koleksiyon adları.
class Collections {
  Collections._();
  static const String ilanlar          = 'ilanlar';
  static const String kullanicilar     = 'kullanicilar';
  static const String sohbetler        = 'sohbetler';
  static const String mesajlar         = 'mesajlar';
  static const String favoriler        = 'favoriler';
  static const String goruntulenmeler  = 'goruntulenmeler';
  static const String degerlendirmeler = 'degerlendirmeler';
  static const String sikayetler       = 'sikayetler';
  static const String bildirimler      = 'bildirimler';
  static const String mail             = 'mail';
  static const String takipler                 = 'takipler';
  static const String bekleyenDegerlendirmeler = 'bekleyenDegerlendirmeler';
  static const String ayarlar                  = 'ayarlar';
}

/// İlan tipleri.
class IlanTip {
  IlanTip._();
  static const String istek    = 'istek';
  static const String tasiyici = 'tasiyici';
}

// ── Kategori Node ─────────────────────────────────────────────────────────────

/// Tek bir class ile sonsuz derinlikte kategori ağacı.
/// [yaprakMi] true ise bu node seçilebilir son noktadır.
class KategoriNode {
  final String key;
  final String ad;
  final String emoji;
  final List<KategoriNode> altlar;

  const KategoriNode({
    required this.key,
    required this.ad,
    this.emoji = '',
    this.altlar = const [],
  });

  bool get yaprakMi => altlar.isEmpty;
}

// ── Geriye dönük uyumluluk ────────────────────────────────────────────────────

/// Eski kodların derlenmesi için — yeni kod KategoriNode kullanır.
class AltKategori {
  final String key;
  final String ad;
  const AltKategori({required this.key, required this.ad});
}

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

// ── Kategori Ağacı ────────────────────────────────────────────────────────────

const List<KategoriNode> kKategoriAgaci = [

  // ── 1. KADIN ──────────────────────────────────────────────────────────────
  KategoriNode(
    key: 'kadin', ad: 'Kadın', emoji: '👗',
    altlar: [
      KategoriNode(key: 'kadin_giyim',    ad: 'Giyim'),
      KategoriNode(key: 'kadin_ayakkabi', ad: 'Ayakkabı'),
      KategoriNode(key: 'kadin_guzellik', ad: 'Güzellik & Makyaj & Bakım'),
    ],
  ),

  // ── 2. ERKEK ──────────────────────────────────────────────────────────────
  KategoriNode(
    key: 'erkek', ad: 'Erkek', emoji: '👔',
    altlar: [
      KategoriNode(key: 'erkek_giyim',    ad: 'Giyim'),
      KategoriNode(key: 'erkek_ayakkabi', ad: 'Ayakkabı'),
      KategoriNode(key: 'erkek_aksesuar', ad: 'Aksesuar'),
    ],
  ),

  // ── 3. ÇOCUK ──────────────────────────────────────────────────────────────
  KategoriNode(
    key: 'cocuk', ad: 'Çocuk', emoji: '🧸',
    altlar: [
      KategoriNode(key: 'cocuk_giyim',    ad: 'Giyim'),
      KategoriNode(key: 'cocuk_ayakkabi', ad: 'Ayakkabı'),
      KategoriNode(key: 'cocuk_oyuncak',  ad: 'Oyuncak'),
    ],
  ),

  // ── 4. EV ─────────────────────────────────────────────────────────────────
  KategoriNode(
    key: 'ev', ad: 'Ev', emoji: '🏠',
    altlar: [
      KategoriNode(key: 'ev_dekorasyon', ad: 'Dekorasyon'),
      KategoriNode(key: 'ev_hatira',     ad: 'Hatıra'),
      KategoriNode(key: 'ev_tekstili',   ad: 'Ev Tekstili'),
    ],
  ),

  // ── 5. ELEKTRONİK ─────────────────────────────────────────────────────────
  KategoriNode(
    key: 'elektronik', ad: 'Elektronik', emoji: '📱',
    altlar: [
      KategoriNode(key: 'elektronik_telefon',     ad: 'Cep Telefonu'),
      KategoriNode(key: 'elektronik_playstation', ad: 'Playstation'),
      KategoriNode(key: 'elektronik_bilgisayar',  ad: 'Bilgisayar'),
      KategoriNode(key: 'elektronik_vape',        ad: 'Vape'),
    ],
  ),

  // ── 6. SUPPLEMENT & MEDİKAL ───────────────────────────────────────────────
  KategoriNode(
    key: 'supplement', ad: 'Supplement & Medikal', emoji: '💊',
    altlar: [
      KategoriNode(key: 'supplement_medikal', ad: 'Medikal'),
      KategoriNode(key: 'supplement_besin',   ad: 'Supplement / Besin'),
    ],
  ),

  // ── 7. DİĞER ──────────────────────────────────────────────────────────────
  KategoriNode(key: 'diger', ad: 'Diğer', emoji: '📦'),
];

// ── Yardımcı Fonksiyonlar ─────────────────────────────────────────────────────

/// Key'den node'u bulur (tüm ağaçta recursive arama)
KategoriNode? kategoriNodeBul(String key, [List<KategoriNode>? liste]) {
  final nodes = liste ?? kKategoriAgaci;
  for (final node in nodes) {
    if (node.key == key) return node;
    final alt = kategoriNodeBul(key, node.altlar);
    if (alt != null) return alt;
  }
  return null;
}

/// Key listesinden okunabilir breadcrumb döndürür
String kategoriYoluMetni(List<String> yol) {
  return yol.map((key) {
    final node = kategoriNodeBul(key);
    return node?.ad ?? key;
  }).join(' › ');
}

/// Verilen key'in tüm alt keylerini döndürür (filtreleme için)
Set<String> tumAltKeyler(String key, [List<KategoriNode>? liste]) {
  final result = <String>{};
  final kuyruk = <String>[key];
  while (kuyruk.isNotEmpty) {
    final k = kuyruk.removeLast();
    if (!result.add(k)) continue;
    final node = kategoriNodeBul(k);
    if (node != null) {
      for (final alt in node.altlar) {
        kuyruk.add(alt.key);
      }
    }
  }
  return result;
}

/// Verilen key'in ana kategori key'ini döndürür
String? anaKategoriKeyBul(String key) {
  for (final ana in kKategoriAgaci) {
    if (ana.key == key) return ana.key;
    if (_altlardaVarMi(key, ana.altlar)) return ana.key;
  }
  return null;
}

bool _altlardaVarMi(String key, List<KategoriNode> altlar) {
  for (final alt in altlar) {
    if (alt.key == key) return true;
    if (_altlardaVarMi(key, alt.altlar)) return true;
  }
  return false;
}

/// Geriye dönük uyumluluk — kKategoriler map'i
final Map<String, String> kKategoriler = () {
  final map = <String, String>{};
  void ekle(KategoriNode node) {
    map[node.key] = node.emoji.isNotEmpty ? '${node.emoji} ${node.ad}' : node.ad;
    for (final alt in node.altlar) {
      ekle(alt);
    }
  }
  for (final node in kKategoriAgaci) {
    ekle(node);
  }
  return map;
}();

/// Geriye dönük uyumluluk — kategoriAdi fonksiyonu
String kategoriAdi(String? key) {
  if (key == null || key.isEmpty) return '';
  final node = kategoriNodeBul(key);
  if (node == null) return '📦 Diğer';
  return node.emoji.isNotEmpty ? '${node.emoji} ${node.ad}' : node.ad;
}

/// Firebase Storage klasörleri.
class StoragePaths {
  StoragePaths._();
  static const String ilanResimleri     = 'ilan_resimleri';
  static const String ilanThumbnailleri = 'ilan_thumbnailleri';
  static const String profilFotolari    = 'profil_fotograflari';
  static const String mesajResimleri    = 'mesaj_resimleri';
}

/// Sayfalama sabitleri.
class Pagination {
  Pagination._();
  static const int ilanSayfaBoyutu  = 20;
  static const int mesajSayfaBoyutu = 30;
  static const int degerlendirmeSayfaBoyutu = 20;
  static const int maxResimSayisi   = 4;
}

/// Kargo şirketleri
class KargoSirketi {
  final String key;
  final String ad;
  final int haneSayisi;
  const KargoSirketi({required this.key, required this.ad, required this.haneSayisi});
  static const List<KargoSirketi> hepsi = [
    KargoSirketi(key: 'yurtici', ad: 'Yurtiçi Kargo', haneSayisi: 12),
    KargoSirketi(key: 'mng',     ad: 'MNG Kargo',      haneSayisi: 12),
    KargoSirketi(key: 'surat',   ad: 'Sürat Kargo',    haneSayisi: 14),
    KargoSirketi(key: 'ptt',     ad: 'PTT Kargo',      haneSayisi: 13),
  ];
  static KargoSirketi? fromKey(String key) {
    try { return hepsi.firstWhere((k) => k.key == key); } catch (_) { return null; }
  }
}

// Türkçe alfabetik sıralama karşılaştırıcısı.
// Dart'ın varsayılan sort'u Unicode code-point kullandığından İ ve Ş gibi
// karakterleri Z'nin arkasına atar; bu fonksiyon doğru Türkçe alfabetik
// sırayı uygular.
const _trSira = <String, int>{
  'A': 0,  'a': 0,
  'B': 1,  'b': 1,
  'C': 2,  'c': 2,
  'Ç': 3,  'ç': 3,
  'D': 4,  'd': 4,
  'E': 5,  'e': 5,
  'F': 6,  'f': 6,
  'G': 7,  'g': 7,
  'Ğ': 8,  'ğ': 8,
  'H': 9,  'h': 9,
  'I': 10, 'ı': 10,
  'İ': 11, 'i': 11,
  'J': 12, 'j': 12,
  'K': 13, 'k': 13,
  'L': 14, 'l': 14,
  'M': 15, 'm': 15,
  'N': 16, 'n': 16,
  'O': 17, 'o': 17,
  'Ö': 18, 'ö': 18,
  'P': 19, 'p': 19,
  'R': 20, 'r': 20,
  'S': 21, 's': 21,
  'Ş': 22, 'ş': 22,
  'T': 23, 't': 23,
  'U': 24, 'u': 24,
  'Ü': 25, 'ü': 25,
  'V': 26, 'v': 26,
  'Y': 27, 'y': 27,
  'Z': 28, 'z': 28,
};

int turkceKarsilastir(String a, String b) {
  for (int i = 0; i < a.length && i < b.length; i++) {
    if (a[i] == b[i]) continue;
    final ia = _trSira[a[i]] ?? (a.codeUnitAt(i) + 1000);
    final ib = _trSira[b[i]] ?? (b.codeUnitAt(i) + 1000);
    if (ia != ib) return ia - ib;
  }
  return a.length - b.length;
}

/// Türkiye'nin 81 ili
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

/// Dünya ülkeleri (BM üyesi + tanınan/gözlemci devletler dahil, ~197 ülke)
const List<String> kDunyaUlkeleri = [
  'Türkiye',
  'Almanya',
  'Amerika Birleşik Devletleri',
  'Arjantin',
  'Avustralya',
  'Avusturya',
  'Azerbaycan',
  'Belçika',
  'Birleşik Arap Emirlikleri',
  'Birleşik Krallık',
  'Brezilya',
  'Çin',
  'Danimarka',
  'Endonezya',
  'Fas',
  'Filipinler',
  'Finlandiya',
  'Fransa',
  'Güney Afrika',
  'Güney Kore',
  'Gürcistan',
  'Hindistan',
  'Hollanda',
  'İran',
  'İrlanda',
  'İspanya',
  'İsveç',
  'İsviçre',
  'İtalya',
  'Japonya',
  'Kanada',
  'Katar',
  'Kazakistan',
  'Kuveyt',
  'Lübnan',
  'Macaristan',
  'Malezya',
  'Meksika',
  'Mısır',
  'Norveç',
  'Özbekistan',
  'Pakistan',
  'Polonya',
  'Portekiz',
  'Romanya',
  'Rusya',
  'Suudi Arabistan',
  'Singapur',
  'Tayland',
  'Ukrayna',
  'Ürdün',
  'Vietnam',
  'Yunanistan',
  'Çek Cumhuriyeti',
  'Slovakya',
  'Hırvatistan',
  'Bosna Hersek',
  'Sırbistan',
  'Bulgaristan',
  'Arnavutluk',
  'Karadağ',
  'Kosova',
  'Kıbrıs',
  'Irak',
  'Suriye',
  'İsrail',
  'Filistin',
  'Umman',
  'Bahreyn',
  'Yemen',
  'Afganistan',
  'Bangladeş',
  'Sri Lanka',
  'Nepal',
  'Angola',
  'Antigua ve Barbuda',
  'Belarus',
  'Belize',
  'Benin',
  'Bhutan',
  'Bolivya',
  'Botsvana',
  'Brunei',
  'Burkina Faso',
  'Burundi',
  'Butan',
  'Cibuti',
  'Çad',
  'Dominik Cumhuriyeti',
  'Dominika',
  'Doğu Timor',
  'Ekvador',
  'Ekvator Ginesi',
  'El Salvador',
  'Eritre',
  'Estonya',
  'Esvatini',
  'Etiyopya',
  'Fiji',
  'Gabon',
  'Gambiya',
  'Gana',
  'Gine',
  'Gine-Bissau',
  'Grenada',
  'Guatemala',
  'Guyana',
  'Haiti',
  'Honduras',
  'İzlanda',
  'Jamaika',
  'Kamboçya',
  'Kamerun',
  'Kepverde',
  'Kenya',
  'Kırgızistan',
  'Kiribati',
  'Kolombiya',
  'Komorlar',
  'Kongo Cumhuriyeti',
  'Kongo Demokratik Cumhuriyeti',
  'Kosta Rika',
  'Kuzey Kore',
  'Kuzey Makedonya',
  'Laos',
  'Lesotho',
  'Letonya',
  'Liberya',
  'Libya',
  'Liechtenstein',
  'Litvanya',
  'Lüksemburg',
  'Madagaskar',
  'Malavi',
  'Maldivler',
  'Mali',
  'Malta',
  'Marshall Adaları',
  'Moritanya',
  'Moritius',
  'Moldova',
  'Monako',
  'Moğolistan',
  'Mozambik',
  'Myanmar',
  'Namibya',
  'Nauru',
  'Nikaragua',
  'Nijer',
  'Nijerya',
  'Orta Afrika Cumhuriyeti',
  'Palau',
  'Panama',
  'Papua Yeni Gine',
  'Paraguay',
  'Peru',
  'Polinezya',
  'Ruanda',
  'Saint Kitts ve Nevis',
  'Saint Lucia',
  'Saint Vincent ve Grenadinler',
  'Samoa',
  'San Marino',
  'São Tomé ve Príncipe',
  'Senegal',
  'Seyşeller',
  'Sierra Leone',
  'Solomon Adaları',
  'Somali',
  'Sudan',
  'Surinam',
  'Şili',
  'Tacikistan',
  'Tanzanya',
  'Togo',
  'Tonga',
  'Trinidad ve Tobago',
  'Tunus',
  'Tuvalu',
  'Türkmenistan',
  'Uganda',
  'Uruguay',
  'Vanuatu',
  'Vatikan',
  'Venezuela',
  'Yeni Zelanda',
  'Yeşil Burun Adaları',
  'Zambiya',
  'Zimbabve',
  'Andorra',
  'Ermenistan',
  'Bahamalar',
  'Barbados',
  'Cezayir',
  'Güney Sudan',
  'Kuba',
  'Tayvan',
];

/// Dünya şehirleri
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

// ── Beden Sistemi ─────────────────────────────────────────────────────────────

enum BedenTipi { yok, standart, pantolon, ayakkabi, cocuk }

const _kAyakkabiKeys = {
  'kadin_ayakkabi', 'erkek_ayakkabi', 'cocuk_ayakkabi',
};

const _kCocukGiyimKeys = {
  'cocuk_giyim',
};

const _kStandartBedenKeys = {
  'kadin_giyim', 'erkek_giyim',
};

/// Seçilen kategori yoluna göre hangi beden tipinin gösterileceğini döndürür.
BedenTipi bedenTipiGetir(List<String> yol) {
  if (yol.isEmpty) return BedenTipi.yok;
  for (final k in yol) {
    if (_kAyakkabiKeys.contains(k)) return BedenTipi.ayakkabi;
  }
  for (final k in yol) {
    if (_kCocukGiyimKeys.contains(k)) return BedenTipi.cocuk;
  }
  for (final k in yol) {
    if (_kStandartBedenKeys.contains(k)) return BedenTipi.standart;
  }
  return BedenTipi.yok;
}

/// Kategori yolundan cinsiyet tahmini üretir.
String cinsiyetTahminiGetir(List<String> yol) {
  for (final k in yol) {
    if (k.startsWith('kadin_')) return 'Kadın';
    if (k.startsWith('erkek_')) return 'Erkek';
  }
  return '';
}

/// Beden seçenekleri
const kBedenStandart = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
const kBedenAyakkabi = [
  '34', '35', '36', '37', '38', '39', '40',
  '41', '42', '43', '44', '45', '46', '47', '48',
];
const kBedenPantolonBel = [
  '26', '28', '30', '32', '34', '36', '38', '40', '42', '44', '46',
];
const kBedenPantolonBoy = [
  '28', '29', '30', '31', '32', '33', '34', '36',
];
const kBedenCocuk = [
  '0-6 ay', '6-12 ay', '12-18 ay', '18-24 ay',
  '2-3 yaş', '3-4 yaş', '4-5 yaş', '5-6 yaş',
  '6-8 yaş', '8-10 yaş', '10-12 yaş', '12-14 yaş',
];

enum SiralamaTipi { enYeni, enEski, enCokFavorilenen, onerilen }

extension SiralamaTipiX on SiralamaTipi {
  String get label {
    switch (this) {
      case SiralamaTipi.enYeni:           return 'En yeni';
      case SiralamaTipi.enEski:           return 'En eski';
      case SiralamaTipi.enCokFavorilenen: return 'Favori';
      case SiralamaTipi.onerilen:         return 'Önerilen';
    }
  }

  String get algoliaKey {
    switch (this) {
      case SiralamaTipi.enYeni:           return 'enYeni';
      case SiralamaTipi.enEski:           return 'enEski';
      case SiralamaTipi.enCokFavorilenen: return 'enCokFavorilenen';
      case SiralamaTipi.onerilen:         return 'onerilen';
    }
  }
}

// ── Kategori Rengi ───────────────────────────────────────────────────────────

/// Her ana kategoriye sabit, tutarlı bir renk atar (kart/rozet arka planı için).
Color kategoriRengi(String key) {
  switch (key) {
    case 'kadin':       return const Color(0xFFE91E8C); // pembe
    case 'erkek':       return const Color(0xFF2979FF); // mavi
    case 'cocuk':       return const Color(0xFFFF9100); // turuncu
    case 'ev':          return const Color(0xFF8D6E63); // kahverengi
    case 'elektronik':  return const Color(0xFF7C4DFF); // mor
    case 'supplement':  return const Color(0xFFFFC107); // sarı
    default:            return const Color(0xFF9E9E9E); // gri (diğer)
  }
}