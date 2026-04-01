/// Firestore koleksiyon adları.
/// String literal yerine bu sabitleri kullan — yazım hatalarını önler.
class Collections {
  Collections._();
  static const String ilanlar       = 'ilanlar';
  static const String kullanicilar  = 'kullanicilar';
  static const String sohbetler     = 'sohbetler';
  static const String mesajlar      = 'mesajlar';
  static const String favoriler     = 'favoriler';
  static const String degerlendirmeler = 'degerlendirmeler';
  static const String sikayetler    = 'sikayetler';
  static const String mail          = 'mail';
}
 
/// İlan tipleri.
class IlanTip {
  IlanTip._();
  static const String istek    = 'istek';
  static const String tasiyici = 'tasiyici';
}
 
/// Kategori anahtar → görünen ad eşleşmesi.
/// Yeni kategori eklemek için sadece buraya eklemek yeterli.
const Map<String, String> kKategoriler = {
  'giyim'     : '👗 Giyim & Aksesuar',
  'elektronik': '📱 Elektronik',
  'guzellik'  : '💄 Güzellik & Sağlık',
  'ev'        : '🏠 Ev & Yaşam',
  'spor'      : '⚽ Spor & Outdoor',
  'kultur'    : '📚 Kültür & Eğlence',
  'gida'      : '🍫 Gıda & İçecek',
  'diger'     : '📦 Diğer',
};
 
/// Kategori anahtarından okunabilir ad döndürür.
String kategoriAdi(String? key) {
  if (key == null || key.isEmpty) return '';
  return kKategoriler[key] ?? '📦 Diğer';
}
 
/// Firebase Storage klasörleri.
class StoragePaths {
  StoragePaths._();
  static const String ilanResimleri    = 'ilan_resimleri';
  static const String profilFotolari   = 'profil_fotograflari';
}
 
/// Sayfalama sabitleri.
class Pagination {
  Pagination._();
  static const int ilanSayfaBoyutu   = 20;
  static const int mesajSayfaBoyutu  = 30;
  static const int maxResimSayisi    = 4;
}