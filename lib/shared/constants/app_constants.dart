// lib/shared/constants/app_constants.dart

/// Firestore koleksiyon adları.
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

  // ── 1. GİYİM & AKSESUAR ───────────────────────────────────────────────────
  KategoriNode(
    key: 'giyim', ad: 'Giyim & Aksesuar', emoji: '👗',
    altlar: [
      KategoriNode(
        key: 'kadin_giyim', ad: 'Kadın Giyim', emoji: '👩',
        altlar: [
          KategoriNode(key: 'kadin_ust', ad: 'Üst Giyim', altlar: [
            KategoriNode(key: 'kadin_tisort', ad: 'Tişört'),
            KategoriNode(key: 'kadin_bluz', ad: 'Bluz'),
            KategoriNode(key: 'kadin_gomlek', ad: 'Gömlek'),
            KategoriNode(key: 'kadin_kazak', ad: 'Kazak & Süveter'),
            KategoriNode(key: 'kadin_hirka', ad: 'Hırka'),
            KategoriNode(key: 'kadin_sweat', ad: 'Sweatshirt & Hoodie'),
          ]),
          KategoriNode(key: 'kadin_alt', ad: 'Alt Giyim', altlar: [
            KategoriNode(key: 'kadin_pantolon', ad: 'Pantolon'),
            KategoriNode(key: 'kadin_etek', ad: 'Etek'),
            KategoriNode(key: 'kadin_sort', ad: 'Şort'),
            KategoriNode(key: 'kadin_tayt', ad: 'Tayt & Boru Paça'),
          ]),
          KategoriNode(key: 'kadin_dis', ad: 'Dış Giyim', altlar: [
            KategoriNode(key: 'kadin_mont', ad: 'Mont & Kaban'),
            KategoriNode(key: 'kadin_trenc', ad: 'Trençkot'),
            KategoriNode(key: 'kadin_yagmurluk', ad: 'Yağmurluk'),
            KategoriNode(key: 'kadin_deri_ceket', ad: 'Deri Ceket'),
            KategoriNode(key: 'kadin_blazer', ad: 'Blazer & Ceket'),
          ]),
          KategoriNode(key: 'kadin_elbise', ad: 'Elbise & Tulum', altlar: [
            KategoriNode(key: 'kadin_gunluk_elbise', ad: 'Günlük Elbise'),
            KategoriNode(key: 'kadin_abiye', ad: 'Abiye & Mezuniyet'),
            KategoriNode(key: 'kadin_tulum', ad: 'Tulum'),
          ]),
          KategoriNode(key: 'kadin_spor', ad: 'Spor Giyim', altlar: [
            KategoriNode(key: 'kadin_spor_tayt', ad: 'Spor Tayt & Şort'),
            KategoriNode(key: 'kadin_spor_ust', ad: 'Spor Üst'),
            KategoriNode(key: 'kadin_spor_esofman', ad: 'Eşofman Takımı'),
          ]),
          KategoriNode(key: 'kadin_ic', ad: 'İç Giyim & Pijama', altlar: [
            KategoriNode(key: 'kadin_sutyen', ad: 'Sütyen'),
            KategoriNode(key: 'kadin_kilot', ad: 'Külot & İç Çamaşırı'),
            KategoriNode(key: 'kadin_pijama', ad: 'Pijama & Gecelik'),
          ]),
          KategoriNode(key: 'kadin_tesettur', ad: 'Tesettür', altlar: [
            KategoriNode(key: 'kadin_tesettur_elbise', ad: 'Tesettür Elbise'),
            KategoriNode(key: 'kadin_tesettur_ust', ad: 'Tesettür Üst Giyim'),
            KategoriNode(key: 'kadin_esarp', ad: 'Eşarp & Türban'),
          ]),
        ],
      ),

      KategoriNode(
        key: 'erkek_giyim', ad: 'Erkek Giyim', emoji: '👨',
        altlar: [
          KategoriNode(key: 'erkek_ust', ad: 'Üst Giyim', altlar: [
            KategoriNode(key: 'erkek_tisort', ad: 'Tişört'),
            KategoriNode(key: 'erkek_gomlek', ad: 'Gömlek'),
            KategoriNode(key: 'erkek_kazak', ad: 'Kazak & Süveter'),
            KategoriNode(key: 'erkek_sweat', ad: 'Sweatshirt & Hoodie'),
            KategoriNode(key: 'erkek_polo', ad: 'Polo Yaka'),
          ]),
          KategoriNode(key: 'erkek_alt', ad: 'Alt Giyim', altlar: [
            KategoriNode(key: 'erkek_pantolon', ad: 'Pantolon'),
            KategoriNode(key: 'erkek_sort', ad: 'Şort'),
            KategoriNode(key: 'erkek_esofman_alt', ad: 'Eşofman Altı'),
            KategoriNode(key: 'erkek_kot', ad: 'Kot Pantolon'),
          ]),
          KategoriNode(key: 'erkek_dis', ad: 'Dış Giyim', altlar: [
            KategoriNode(key: 'erkek_mont', ad: 'Mont & Kaban'),
            KategoriNode(key: 'erkek_yagmurluk', ad: 'Yağmurluk'),
            KategoriNode(key: 'erkek_deri_ceket', ad: 'Deri Ceket'),
            KategoriNode(key: 'erkek_blazer', ad: 'Blazer & Ceket'),
          ]),
          KategoriNode(key: 'erkek_takim', ad: 'Takım Elbise', altlar: [
            KategoriNode(key: 'erkek_takim_elbise', ad: 'Takım Elbise'),
            KategoriNode(key: 'erkek_yelek', ad: 'Yelek'),
          ]),
          KategoriNode(key: 'erkek_spor', ad: 'Spor Giyim', altlar: [
            KategoriNode(key: 'erkek_spor_sort', ad: 'Spor Şort'),
            KategoriNode(key: 'erkek_spor_ust', ad: 'Spor Üst'),
            KategoriNode(key: 'erkek_esofman', ad: 'Eşofman Takımı'),
          ]),
          KategoriNode(key: 'erkek_ic', ad: 'İç Giyim & Pijama', altlar: [
            KategoriNode(key: 'erkek_ic_camasir', ad: 'İç Çamaşırı'),
            KategoriNode(key: 'erkek_pijama', ad: 'Pijama'),
            KategoriNode(key: 'erkek_atlet', ad: 'Atlet & Fanila'),
          ]),
        ],
      ),

      KategoriNode(
        key: 'cocuk_giyim', ad: 'Çocuk & Bebek Giyim', emoji: '👶',
        altlar: [
          KategoriNode(key: 'bebek_giyim', ad: 'Bebek (0-2 yaş)', altlar: [
            KategoriNode(key: 'bebek_tulum', ad: 'Bebek Tulum & Body'),
            KategoriNode(key: 'bebek_ust', ad: 'Bebek Üst Giyim'),
            KategoriNode(key: 'bebek_alt', ad: 'Bebek Alt Giyim'),
          ]),
          KategoriNode(key: 'kiz_cocuk', ad: 'Kız Çocuk (2-14 yaş)', altlar: [
            KategoriNode(key: 'kiz_ust', ad: 'Üst Giyim'),
            KategoriNode(key: 'kiz_alt', ad: 'Alt Giyim'),
            KategoriNode(key: 'kiz_elbise', ad: 'Elbise & Etek'),
            KategoriNode(key: 'kiz_dis', ad: 'Dış Giyim'),
          ]),
          KategoriNode(key: 'erkek_cocuk', ad: 'Erkek Çocuk (2-14 yaş)', altlar: [
            KategoriNode(key: 'erkek_c_ust', ad: 'Üst Giyim'),
            KategoriNode(key: 'erkek_c_alt', ad: 'Alt Giyim'),
            KategoriNode(key: 'erkek_c_dis', ad: 'Dış Giyim'),
          ]),
        ],
      ),

      KategoriNode(
        key: 'ayakkabi', ad: 'Ayakkabı', emoji: '👟',
        altlar: [
          KategoriNode(key: 'kadin_ayakkabi', ad: 'Kadın Ayakkabı', altlar: [
            KategoriNode(key: 'kadin_spor_ayakkabi', ad: 'Spor Ayakkabı'),
            KategoriNode(key: 'kadin_topuklu', ad: 'Topuklu & Stiletto'),
            KategoriNode(key: 'kadin_bot', ad: 'Bot & Çizme'),
            KategoriNode(key: 'kadin_sandalet', ad: 'Sandalet & Terlik'),
            KategoriNode(key: 'kadin_loafer', ad: 'Loafer & Babet'),
          ]),
          KategoriNode(key: 'erkek_ayakkabi', ad: 'Erkek Ayakkabı', altlar: [
            KategoriNode(key: 'erkek_spor_ayakkabi', ad: 'Spor Ayakkabı'),
            KategoriNode(key: 'erkek_klasik', ad: 'Klasik & Deri'),
            KategoriNode(key: 'erkek_bot', ad: 'Bot & Çizme'),
            KategoriNode(key: 'erkek_sandalet', ad: 'Sandalet & Terlik'),
          ]),
          KategoriNode(key: 'cocuk_ayakkabi', ad: 'Çocuk Ayakkabı', altlar: [
            KategoriNode(key: 'cocuk_spor_ayakkabi', ad: 'Spor Ayakkabı'),
            KategoriNode(key: 'cocuk_gunluk_ayakkabi', ad: 'Günlük Ayakkabı'),
            KategoriNode(key: 'bebek_ayakkabi', ad: 'Bebek Ayakkabısı'),
          ]),
        ],
      ),

      KategoriNode(
        key: 'canta', ad: 'Çanta & Cüzdan', emoji: '👜',
        altlar: [
          KategoriNode(key: 'kadin_canta', ad: 'Kadın Çanta', altlar: [
            KategoriNode(key: 'kadin_omuz_canta', ad: 'Omuz Çantası'),
            KategoriNode(key: 'kadin_el_canta', ad: 'El Çantası'),
            KategoriNode(key: 'kadin_sirt_canta', ad: 'Sırt Çantası'),
            KategoriNode(key: 'kadin_clutch', ad: 'Clutch & El Çantası'),
          ]),
          KategoriNode(key: 'erkek_canta', ad: 'Erkek Çanta', altlar: [
            KategoriNode(key: 'erkek_sirt_canta', ad: 'Sırt Çantası'),
            KategoriNode(key: 'erkek_evrak_canta', ad: 'Evrak & Laptop Çantası'),
            KategoriNode(key: 'erkek_bel_canta', ad: 'Bel Çantası'),
          ]),
          KategoriNode(key: 'cuzdanlar', ad: 'Cüzdan & Kartlık', altlar: [
            KategoriNode(key: 'kadin_cuzdan', ad: 'Kadın Cüzdanı'),
            KategoriNode(key: 'erkek_cuzdan', ad: 'Erkek Cüzdanı'),
            KategoriNode(key: 'kartlik', ad: 'Kartlık'),
          ]),
        ],
      ),

      KategoriNode(
        key: 'aksesuar', ad: 'Aksesuar', emoji: '💍',
        altlar: [
          KategoriNode(key: 'taki', ad: 'Takı & Mücevher', altlar: [
            KategoriNode(key: 'kolye', ad: 'Kolye'),
            KategoriNode(key: 'bileklik', ad: 'Bileklik & Bilezik'),
            KategoriNode(key: 'kupe', ad: 'Küpe'),
            KategoriNode(key: 'yuzuk', ad: 'Yüzük'),
          ]),
          KategoriNode(key: 'saat', ad: 'Saat', altlar: [
            KategoriNode(key: 'kadin_saat', ad: 'Kadın Saati'),
            KategoriNode(key: 'erkek_saat', ad: 'Erkek Saati'),
            KategoriNode(key: 'akilli_saat', ad: 'Akıllı Saat'),
          ]),
          KategoriNode(key: 'sapka', ad: 'Şapka & Bere', altlar: [
            KategoriNode(key: 'sapka_kasket', ad: 'Şapka & Kasket'),
            KategoriNode(key: 'bere', ad: 'Bere & Balaklava'),
          ]),
          KategoriNode(key: 'esarp_atki', ad: 'Eşarp & Atkı', altlar: [
            KategoriNode(key: 'esarp', ad: 'Eşarp'),
            KategoriNode(key: 'atki', ad: 'Atkı & Boyunluk'),
          ]),
          KategoriNode(key: 'kemer', ad: 'Kemer', altlar: [
            KategoriNode(key: 'kadin_kemer', ad: 'Kadın Kemeri'),
            KategoriNode(key: 'erkek_kemer', ad: 'Erkek Kemeri'),
          ]),
        ],
      ),
    ],
  ),

  // ── 2. ELEKTRONİK ─────────────────────────────────────────────────────────
  KategoriNode(
    key: 'elektronik', ad: 'Elektronik', emoji: '📱',
    altlar: [
      KategoriNode(
        key: 'telefon', ad: 'Telefon', emoji: '📱',
        altlar: [
          KategoriNode(key: 'apple_iphone', ad: 'Apple iPhone', altlar: [
            KategoriNode(key: 'iphone_16_serisi', ad: 'iPhone 16 Serisi', altlar: [
              KategoriNode(key: 'iphone_16_pro_max', ad: 'iPhone 16 Pro Max'),
              KategoriNode(key: 'iphone_16_pro', ad: 'iPhone 16 Pro'),
              KategoriNode(key: 'iphone_16_plus', ad: 'iPhone 16 Plus'),
              KategoriNode(key: 'iphone_16', ad: 'iPhone 16'),
            ]),
            KategoriNode(key: 'iphone_15_serisi', ad: 'iPhone 15 Serisi', altlar: [
              KategoriNode(key: 'iphone_15_pro_max', ad: 'iPhone 15 Pro Max'),
              KategoriNode(key: 'iphone_15_pro', ad: 'iPhone 15 Pro'),
              KategoriNode(key: 'iphone_15_plus', ad: 'iPhone 15 Plus'),
              KategoriNode(key: 'iphone_15', ad: 'iPhone 15'),
            ]),
            KategoriNode(key: 'iphone_14_serisi', ad: 'iPhone 14 Serisi', altlar: [
              KategoriNode(key: 'iphone_14_pro_max', ad: 'iPhone 14 Pro Max'),
              KategoriNode(key: 'iphone_14_pro', ad: 'iPhone 14 Pro'),
              KategoriNode(key: 'iphone_14_plus', ad: 'iPhone 14 Plus'),
              KategoriNode(key: 'iphone_14', ad: 'iPhone 14'),
            ]),
            KategoriNode(key: 'iphone_13_serisi', ad: 'iPhone 13 Serisi', altlar: [
              KategoriNode(key: 'iphone_13_pro_max', ad: 'iPhone 13 Pro Max'),
              KategoriNode(key: 'iphone_13_pro', ad: 'iPhone 13 Pro'),
              KategoriNode(key: 'iphone_13_mini', ad: 'iPhone 13 Mini'),
              KategoriNode(key: 'iphone_13', ad: 'iPhone 13'),
            ]),
            KategoriNode(key: 'iphone_diger', ad: 'Diğer iPhone'),
          ]),
          KategoriNode(key: 'samsung_telefon', ad: 'Samsung', altlar: [
            KategoriNode(key: 'samsung_s25', ad: 'Galaxy S25 Serisi', altlar: [
              KategoriNode(key: 'samsung_s25_ultra', ad: 'Galaxy S25 Ultra'),
              KategoriNode(key: 'samsung_s25_plus', ad: 'Galaxy S25+'),
              KategoriNode(key: 'samsung_s25_base', ad: 'Galaxy S25'),
            ]),
            KategoriNode(key: 'samsung_s24', ad: 'Galaxy S24 Serisi', altlar: [
              KategoriNode(key: 'samsung_s24_ultra', ad: 'Galaxy S24 Ultra'),
              KategoriNode(key: 'samsung_s24_plus', ad: 'Galaxy S24+'),
              KategoriNode(key: 'samsung_s24', ad: 'Galaxy S24'),
            ]),
            KategoriNode(key: 'samsung_z', ad: 'Galaxy Z Serisi', altlar: [
              KategoriNode(key: 'samsung_z_fold6', ad: 'Galaxy Z Fold 6'),
              KategoriNode(key: 'samsung_z_flip6', ad: 'Galaxy Z Flip 6'),
              KategoriNode(key: 'samsung_z_diger', ad: 'Diğer Z Serisi'),
            ]),
            KategoriNode(key: 'samsung_a', ad: 'Galaxy A Serisi', altlar: [
              KategoriNode(key: 'samsung_a55', ad: 'Galaxy A55'),
              KategoriNode(key: 'samsung_a35', ad: 'Galaxy A35'),
              KategoriNode(key: 'samsung_a25', ad: 'Galaxy A25'),
              KategoriNode(key: 'samsung_a15', ad: 'Galaxy A15'),
              KategoriNode(key: 'samsung_a_diger', ad: 'Diğer A Serisi'),
            ]),
            KategoriNode(key: 'samsung_diger', ad: 'Diğer Samsung'),
          ]),
          KategoriNode(key: 'google_pixel', ad: 'Google Pixel', altlar: [
            KategoriNode(key: 'pixel_9', ad: 'Pixel 9 Serisi'),
            KategoriNode(key: 'pixel_8', ad: 'Pixel 8 Serisi'),
            KategoriNode(key: 'pixel_diger', ad: 'Diğer Pixel'),
          ]),
          KategoriNode(key: 'oneplus', ad: 'OnePlus', altlar: [
            KategoriNode(key: 'oneplus_13', ad: 'OnePlus 13'),
            KategoriNode(key: 'oneplus_12', ad: 'OnePlus 12'),
            KategoriNode(key: 'oneplus_diger', ad: 'Diğer OnePlus'),
          ]),
          KategoriNode(key: 'xiaomi', ad: 'Xiaomi', altlar: [
            KategoriNode(key: 'xiaomi_15', ad: 'Xiaomi 15 Serisi'),
            KategoriNode(key: 'xiaomi_14', ad: 'Xiaomi 14 Serisi'),
            KategoriNode(key: 'redmi', ad: 'Redmi Serisi'),
            KategoriNode(key: 'xiaomi_diger', ad: 'Diğer Xiaomi'),
          ]),
          KategoriNode(key: 'huawei', ad: 'Huawei', altlar: [
            KategoriNode(key: 'huawei_p', ad: 'Huawei P Serisi'),
            KategoriNode(key: 'huawei_mate', ad: 'Huawei Mate Serisi'),
            KategoriNode(key: 'huawei_diger', ad: 'Diğer Huawei'),
          ]),
          KategoriNode(key: 'sony_telefon', ad: 'Sony Xperia'),
          KategoriNode(key: 'diger_telefon', ad: 'Diğer Marka Telefon'),
        ],
      ),

      KategoriNode(
        key: 'bilgisayar', ad: 'Bilgisayar', emoji: '💻',
        altlar: [
          KategoriNode(key: 'laptop', ad: 'Laptop', altlar: [
            KategoriNode(key: 'macbook', ad: 'Apple MacBook', altlar: [
              KategoriNode(key: 'macbook_pro', ad: 'MacBook Pro'),
              KategoriNode(key: 'macbook_air', ad: 'MacBook Air'),
            ]),
            KategoriNode(key: 'windows_laptop', ad: 'Windows Laptop', altlar: [
              KategoriNode(key: 'dell_laptop', ad: 'Dell'),
              KategoriNode(key: 'hp_laptop', ad: 'HP'),
              KategoriNode(key: 'lenovo_laptop', ad: 'Lenovo'),
              KategoriNode(key: 'asus_laptop', ad: 'Asus'),
              KategoriNode(key: 'microsoft_surface', ad: 'Microsoft Surface'),
              KategoriNode(key: 'diger_laptop', ad: 'Diğer'),
            ]),
            KategoriNode(key: 'gaming_laptop', ad: 'Gaming Laptop', altlar: [
              KategoriNode(key: 'asus_rog', ad: 'Asus ROG'),
              KategoriNode(key: 'msi_laptop', ad: 'MSI'),
              KategoriNode(key: 'razer', ad: 'Razer'),
              KategoriNode(key: 'diger_gaming_laptop', ad: 'Diğer'),
            ]),
          ]),
          KategoriNode(key: 'masaustu', ad: 'Masaüstü', altlar: [
            KategoriNode(key: 'imac', ad: 'Apple iMac'),
            KategoriNode(key: 'windows_masaustu', ad: 'Windows Masaüstü'),
            KategoriNode(key: 'mini_pc', ad: 'Mini PC'),
          ]),
          KategoriNode(key: 'bilgisayar_aksesuar', ad: 'Bilgisayar Aksesuar', altlar: [
            KategoriNode(key: 'monitor', ad: 'Monitör'),
            KategoriNode(key: 'klavye', ad: 'Klavye'),
            KategoriNode(key: 'mouse', ad: 'Mouse'),
            KategoriNode(key: 'webcam', ad: 'Webcam'),
            KategoriNode(key: 'harddisk', ad: 'Harddisk & SSD'),
          ]),
        ],
      ),

      KategoriNode(
        key: 'tablet', ad: 'Tablet', emoji: '📲',
        altlar: [
          KategoriNode(key: 'ipad', ad: 'Apple iPad', altlar: [
            KategoriNode(key: 'ipad_pro', ad: 'iPad Pro'),
            KategoriNode(key: 'ipad_air', ad: 'iPad Air'),
            KategoriNode(key: 'ipad_mini', ad: 'iPad Mini'),
            KategoriNode(key: 'ipad_standard', ad: 'iPad (Standart)'),
          ]),
          KategoriNode(key: 'samsung_tablet', ad: 'Samsung Galaxy Tab', altlar: [
            KategoriNode(key: 'galaxy_tab_s', ad: 'Galaxy Tab S Serisi'),
            KategoriNode(key: 'galaxy_tab_a', ad: 'Galaxy Tab A Serisi'),
          ]),
          KategoriNode(key: 'diger_tablet', ad: 'Diğer Tablet'),
        ],
      ),

      KategoriNode(
        key: 'kulaklik_ses', ad: 'Kulaklık & Ses', emoji: '🎧',
        altlar: [
          KategoriNode(key: 'kablosuz_kulaklik', ad: 'Kablosuz Kulaklık', altlar: [
            KategoriNode(key: 'airpods', ad: 'Apple AirPods'),
            KategoriNode(key: 'sony_kulaklik', ad: 'Sony'),
            KategoriNode(key: 'bose_kulaklik', ad: 'Bose'),
            KategoriNode(key: 'samsung_buds', ad: 'Samsung Galaxy Buds'),
            KategoriNode(key: 'diger_kablosuz', ad: 'Diğer'),
          ]),
          KategoriNode(key: 'kablolu_kulaklik', ad: 'Kablolu Kulaklık'),
          KategoriNode(key: 'bluetooth_hoparlor', ad: 'Bluetooth Hoparlör'),
          KategoriNode(key: 'soundbar', ad: 'Soundbar'),
        ],
      ),

      KategoriNode(
        key: 'tv_gorunty', ad: 'TV & Görüntü', emoji: '📺',
        altlar: [
          KategoriNode(key: 'akilli_tv', ad: 'Akıllı TV', altlar: [
            KategoriNode(key: 'samsung_tv', ad: 'Samsung TV'),
            KategoriNode(key: 'lg_tv', ad: 'LG TV'),
            KategoriNode(key: 'sony_tv', ad: 'Sony TV'),
            KategoriNode(key: 'diger_tv', ad: 'Diğer TV'),
          ]),
          KategoriNode(key: 'projektor', ad: 'Projektör'),
        ],
      ),

      KategoriNode(
        key: 'oyun_konsol', ad: 'Oyun & Konsol', emoji: '🎮',
        altlar: [
          KategoriNode(key: 'playstation', ad: 'PlayStation', altlar: [
            KategoriNode(key: 'ps5', ad: 'PlayStation 5'),
            KategoriNode(key: 'ps4', ad: 'PlayStation 4'),
            KategoriNode(key: 'ps_aksesuar', ad: 'PlayStation Aksesuar'),
          ]),
          KategoriNode(key: 'xbox', ad: 'Xbox', altlar: [
            KategoriNode(key: 'xbox_series_x', ad: 'Xbox Series X'),
            KategoriNode(key: 'xbox_series_s', ad: 'Xbox Series S'),
            KategoriNode(key: 'xbox_aksesuar', ad: 'Xbox Aksesuar'),
          ]),
          KategoriNode(key: 'nintendo', ad: 'Nintendo', altlar: [
            KategoriNode(key: 'nintendo_switch', ad: 'Nintendo Switch'),
            KategoriNode(key: 'nintendo_aksesuar', ad: 'Nintendo Aksesuar'),
          ]),
          KategoriNode(key: 'gaming_aksesuar', ad: 'Gaming Aksesuar'),
        ],
      ),

      KategoriNode(
        key: 'fotograf_kamera', ad: 'Fotoğraf & Kamera', emoji: '📷',
        altlar: [
          KategoriNode(key: 'dslr_aynasiz', ad: 'DSLR & Aynasız', altlar: [
            KategoriNode(key: 'canon', ad: 'Canon'),
            KategoriNode(key: 'nikon', ad: 'Nikon'),
            KategoriNode(key: 'sony_kamera', ad: 'Sony'),
            KategoriNode(key: 'diger_kamera', ad: 'Diğer'),
          ]),
          KategoriNode(key: 'aksiyon_kamera', ad: 'Aksiyon Kamera', altlar: [
            KategoriNode(key: 'gopro', ad: 'GoPro'),
            KategoriNode(key: 'diger_aksiyon', ad: 'Diğer'),
          ]),
          KategoriNode(key: 'drone', ad: 'Drone', altlar: [
            KategoriNode(key: 'dji_drone', ad: 'DJI'),
            KategoriNode(key: 'diger_drone', ad: 'Diğer'),
          ]),
        ],
      ),

      KategoriNode(key: 'diger_elektronik', ad: 'Diğer Elektronik'),
    ],
  ),

  // ── 3. GÜZELLİK & SAĞLIK ─────────────────────────────────────────────────
  KategoriNode(
    key: 'guzellik', ad: 'Güzellik & Sağlık', emoji: '💄',
    altlar: [
      KategoriNode(
        key: 'cilt_bakimi', ad: 'Cilt Bakımı',
        altlar: [
          KategoriNode(key: 'nemlendirici', ad: 'Nemlendirici & Krem'),
          KategoriNode(key: 'serum', ad: 'Serum & Ampul'),
          KategoriNode(key: 'temizleyici', ad: 'Temizleyici & Tonik'),
          KategoriNode(key: 'gunes_koruyucu', ad: 'Güneş Koruyucu'),
          KategoriNode(key: 'goz_bakimi', ad: 'Göz Çevresi Bakımı'),
          KategoriNode(key: 'maske', ad: 'Yüz Maskesi'),
        ],
      ),
      KategoriNode(
        key: 'makyaj', ad: 'Makyaj',
        altlar: [
          KategoriNode(key: 'yuz_makyaj', ad: 'Yüz (Fondöten, Allık, Pudra)'),
          KategoriNode(key: 'goz_makyaj', ad: 'Göz (Maskara, Eyeliner, Far)'),
          KategoriNode(key: 'dudak_makyaj', ad: 'Dudak (Ruj, Parlatıcı)'),
          KategoriNode(key: 'makyaj_firca', ad: 'Makyaj Fırçası & Aksesuar'),
        ],
      ),
      KategoriNode(
        key: 'sac_bakimi', ad: 'Saç Bakımı',
        altlar: [
          KategoriNode(key: 'sampuan', ad: 'Şampuan & Saç Kremi'),
          KategoriNode(key: 'sac_maskesi', ad: 'Saç Maskesi & Serum'),
          KategoriNode(key: 'sac_sekillendirici', ad: 'Saç Şekillendirici'),
          KategoriNode(key: 'sac_boyasi', ad: 'Saç Boyası'),
        ],
      ),
      KategoriNode(
        key: 'parfum', ad: 'Parfüm & Deodorant',
        altlar: [
          KategoriNode(key: 'kadin_parfum', ad: 'Kadın Parfümü'),
          KategoriNode(key: 'erkek_parfum', ad: 'Erkek Parfümü'),
          KategoriNode(key: 'unisex_parfum', ad: 'Unisex Parfüm'),
          KategoriNode(key: 'deodorant', ad: 'Deodorant & Vücut Spreyi'),
        ],
      ),
      KategoriNode(
        key: 'saglik_takviye', ad: 'Sağlık & Takviye',
        altlar: [
          KategoriNode(key: 'vitamin', ad: 'Vitamin & Mineral'),
          KategoriNode(key: 'protein', ad: 'Protein & Spor Takviyesi'),
          KategoriNode(key: 'medikal', ad: 'Medikal Ürünler'),
        ],
      ),
      KategoriNode(
        key: 'kisisel_bakim', ad: 'Kişisel Bakım',
        altlar: [
          KategoriNode(key: 'agiz_dis', ad: 'Ağız & Diş Bakımı'),
          KategoriNode(key: 'el_ayak', ad: 'El & Ayak Bakımı'),
          KategoriNode(key: 'tiras', ad: 'Tıraş & Epilasyon'),
        ],
      ),
    ],
  ),

  // ── 4. EV & YAŞAM ─────────────────────────────────────────────────────────
  KategoriNode(
    key: 'ev', ad: 'Ev & Yaşam', emoji: '🏠',
    altlar: [
      KategoriNode(
        key: 'mobilya', ad: 'Mobilya',
        altlar: [
          KategoriNode(key: 'oturma_odasi', ad: 'Oturma Odası'),
          KategoriNode(key: 'yatak_odasi', ad: 'Yatak Odası'),
          KategoriNode(key: 'mutfak_mobilya', ad: 'Mutfak & Yemek Odası'),
          KategoriNode(key: 'calisma_odasi', ad: 'Çalışma Odası'),
        ],
      ),
      KategoriNode(
        key: 'ev_aletleri', ad: 'Mutfak & Ev Aletleri',
        altlar: [
          KategoriNode(key: 'kucuk_ev_aletleri', ad: 'Küçük Ev Aletleri'),
          KategoriNode(key: 'buyuk_ev_aletleri', ad: 'Büyük Ev Aletleri'),
          KategoriNode(key: 'mutfak_gerecleri', ad: 'Mutfak Gereçleri'),
        ],
      ),
      KategoriNode(
        key: 'dekorasyon', ad: 'Dekorasyon',
        altlar: [
          KategoriNode(key: 'aydinlatma', ad: 'Aydınlatma'),
          KategoriNode(key: 'tablo_duvar', ad: 'Tablo & Duvar Dekoru'),
          KategoriNode(key: 'vazo_biblo', ad: 'Vazo & Biblo'),
        ],
      ),
      KategoriNode(
        key: 'ev_tekstili', ad: 'Ev Tekstili',
        altlar: [
          KategoriNode(key: 'nevresim', ad: 'Yatak Örtüsü & Nevresim'),
          KategoriNode(key: 'havlu', ad: 'Havlu & Banyo'),
          KategoriNode(key: 'perde_hali', ad: 'Perde & Halı'),
        ],
      ),
      KategoriNode(
        key: 'bahce', ad: 'Bahçe & Balkon',
        altlar: [
          KategoriNode(key: 'bahce_mobilya', ad: 'Bahçe Mobilyası'),
          KategoriNode(key: 'bahce_aletleri', ad: 'Bahçe Aletleri'),
          KategoriNode(key: 'saksi_bitki', ad: 'Saksı & Bitki'),
        ],
      ),
    ],
  ),

  // ── 5. SPOR & OUTDOOR ─────────────────────────────────────────────────────
  KategoriNode(
    key: 'spor', ad: 'Spor & Outdoor', emoji: '⚽',
    altlar: [
      KategoriNode(
        key: 'spor_ekipman', ad: 'Spor Ekipmanı',
        altlar: [
          KategoriNode(key: 'fitness_gym', ad: 'Fitness & Gym'),
          KategoriNode(key: 'takim_sporlari', ad: 'Takım Sporları'),
          KategoriNode(key: 'raket_sporlari', ad: 'Raket Sporları'),
          KategoriNode(key: 'su_sporlari', ad: 'Su Sporları'),
        ],
      ),
      KategoriNode(
        key: 'spor_giyim', ad: 'Spor Giyim',
        altlar: [
          KategoriNode(key: 'kadin_spor_giyim', ad: 'Kadın Spor Giyim'),
          KategoriNode(key: 'erkek_spor_giyim', ad: 'Erkek Spor Giyim'),
          KategoriNode(key: 'cocuk_spor_giyim', ad: 'Çocuk Spor Giyim'),
        ],
      ),
      KategoriNode(
        key: 'spor_ayakkabi_cat', ad: 'Spor Ayakkabı',
        altlar: [
          KategoriNode(key: 'kadin_spor_ay', ad: 'Kadın Spor Ayakkabı'),
          KategoriNode(key: 'erkek_spor_ay', ad: 'Erkek Spor Ayakkabı'),
          KategoriNode(key: 'cocuk_spor_ay', ad: 'Çocuk Spor Ayakkabı'),
        ],
      ),
      KategoriNode(
        key: 'outdoor_kamp', ad: 'Outdoor & Kamp',
        altlar: [
          KategoriNode(key: 'kamp_ekipman', ad: 'Kamp Ekipmanı'),
          KategoriNode(key: 'trekking', ad: 'Trekking & Dağcılık'),
          KategoriNode(key: 'balikcilik', ad: 'Balıkçılık'),
        ],
      ),
      KategoriNode(
        key: 'bisiklet_scooter', ad: 'Bisiklet & Scooter',
        altlar: [
          KategoriNode(key: 'bisiklet', ad: 'Bisiklet'),
          KategoriNode(key: 'elektrikli_scooter', ad: 'Elektrikli Scooter'),
          KategoriNode(key: 'bisiklet_aksesuar', ad: 'Aksesuar'),
        ],
      ),
    ],
  ),

  // ── 6. KÜLTÜR & EĞLENCE ───────────────────────────────────────────────────
  KategoriNode(
    key: 'kultur', ad: 'Kültür & Eğlence', emoji: '📚',
    altlar: [
      KategoriNode(
        key: 'kitap', ad: 'Kitap',
        altlar: [
          KategoriNode(key: 'roman_edebiyat', ad: 'Roman & Edebiyat'),
          KategoriNode(key: 'kisisel_gelisim', ad: 'Kişisel Gelişim'),
          KategoriNode(key: 'bilim_teknoloji_kitap', ad: 'Bilim & Teknoloji'),
          KategoriNode(key: 'tarih_biyografi', ad: 'Tarih & Biyografi'),
          KategoriNode(key: 'cocuk_kitap', ad: 'Çocuk Kitapları'),
        ],
      ),
      KategoriNode(
        key: 'muzik', ad: 'Müzik',
        altlar: [
          KategoriNode(key: 'enstruman', ad: 'Enstrüman', altlar: [
            KategoriNode(key: 'gitar', ad: 'Gitar'),
            KategoriNode(key: 'piyano_klavye', ad: 'Piyano & Klavye'),
            KategoriNode(key: 'davul_perkusyon', ad: 'Davul & Perküsyon'),
            KategoriNode(key: 'diger_enstruman', ad: 'Diğer Enstrüman'),
          ]),
          KategoriNode(key: 'plak_cd', ad: 'Plak & CD'),
        ],
      ),
      KategoriNode(
        key: 'oyuncak_hobi', ad: 'Oyuncak & Hobi',
        altlar: [
          KategoriNode(key: 'oyuncak', ad: 'Oyuncak (0-12 yaş)'),
          KategoriNode(key: 'lego', ad: 'LEGO & Yapı Setleri'),
          KategoriNode(key: 'puzzle_kutu', ad: 'Puzzle & Kutu Oyunları'),
          KategoriNode(key: 'koleksiyon_figur', ad: 'Koleksiyon & Figür'),
        ],
      ),
      KategoriNode(
        key: 'film_dizi', ad: 'Film & Dizi',
        altlar: [
          KategoriNode(key: 'dvd_bluray', ad: 'DVD & Blu-ray'),
          KategoriNode(key: 'poster_memorabilia', ad: 'Poster & Memorabilia'),
        ],
      ),
    ],
  ),

  // ── 7. GIDA & İÇECEK ──────────────────────────────────────────────────────
  KategoriNode(
    key: 'gida', ad: 'Gıda & İçecek', emoji: '🍫',
    altlar: [
      KategoriNode(
        key: 'atistirmalik', ad: 'Atıştırmalık & Çikolata',
        altlar: [
          KategoriNode(key: 'cikolata', ad: 'Çikolata'),
          KategoriNode(key: 'sekerleme', ad: 'Şekerleme & Gummy'),
          KategoriNode(key: 'cips_kraker', ad: 'Cips & Kraker'),
          KategoriNode(key: 'kuruyemis', ad: 'Kuruyemiş'),
        ],
      ),
      KategoriNode(
        key: 'icecek', ad: 'İçecek',
        altlar: [
          KategoriNode(key: 'kahve_cay', ad: 'Kahve & Çay'),
          KategoriNode(key: 'enerji_icecek', ad: 'Enerji & Spor İçeceği'),
          KategoriNode(key: 'meyve_suyu', ad: 'Meyve Suyu & Smoothie'),
          KategoriNode(key: 'alkolsuz', ad: 'Alkolsüz İçecek'),
        ],
      ),
      KategoriNode(
        key: 'organik_dogal', ad: 'Organik & Doğal',
        altlar: [
          KategoriNode(key: 'organik_gida', ad: 'Organik Gıda'),
          KategoriNode(key: 'glutensiz_vegan', ad: 'Glutensiz & Vegan'),
          KategoriNode(key: 'dogal_takviye', ad: 'Doğal Takviye'),
        ],
      ),
      KategoriNode(
        key: 'ozel_urunler', ad: 'Özel Ürünler',
        altlar: [
          KategoriNode(key: 'ithal_urunler', ad: 'İthal Ürünler'),
          KategoriNode(key: 'yoresel', ad: 'Yöresel Ürünler'),
          KategoriNode(key: 'ozel_gunler', ad: 'Özel Günler'),
        ],
      ),
    ],
  ),

  // ── 8. DİĞER ──────────────────────────────────────────────────────────────
  KategoriNode(
    key: 'diger', ad: 'Diğer', emoji: '📦',
    altlar: [],
  ),
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
/// Örn: ['giyim', 'erkek_giyim', 'erkek_gomlek'] → 'Giyim & Aksesuar › Erkek Giyim › Gömlek'
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
    if (!result.add(k)) continue; // zaten ziyaret edildi
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

/// Geriye dönük uyumluluk — eski kKategoriler map'i
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

/// Dünya ülkeleri
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