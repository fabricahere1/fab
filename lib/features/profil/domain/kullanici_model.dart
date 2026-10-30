import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
 
part 'kullanici_model.freezed.dart';
part 'kullanici_model.g.dart';
 
@freezed
abstract class KullaniciModel with _$KullaniciModel {
  const factory KullaniciModel({
    required String id,
    @Default('') String adSoyad,
    String? fotoUrl,
    String? telefon,
    String? email,
    String? fcmToken,
    @Default(false) bool profilTamamlandi,
    @Default(0.0) double ortalamaPuan,
    @Default(0) int degerlendirmeSayisi,
    @Default('') String kullaniciTipi,
    @Default('') String yasadigiUlke,
    @Default('') String bulunduguSehir,
    @Default([]) List<String> geldigiSehirler,
    @Default('') String hakkinda,
    @Default(false) bool telefonGizli,
    @Default([]) List<String> engellenenler,
    // Kayıt ekranından gelen tercihler
    @Default([]) List<String> ilgiKategorileri,
    bool? dutyFreeIlgileniyor,
    String? istekTeslimatTercihi,
    @Default([]) List<String> kadinUstBeden,
    @Default([]) List<String> kadinAltBeden,
    @Default([]) List<String> erkekUstBeden,
    @Default([]) List<String> erkekAltBeden,
    @Default([]) List<String> kadinAyakkabi,
    @Default([]) List<String> erkekAyakkabi,
    @Default([]) List<String> cocukAyakkabi,
    // Sosyal & güven
    @Default(0) int takipciSayisi,
    @Default(0) int takipSayisi,
    @Default(0) int guvenSkoru,
    @Default([]) List<String> rozetler,
    @Default(false) bool banli,
    @Default('') String banSebebi,
    @Default({}) Map<String, bool> bildirimTercihleri,
    // Hesap silme ekranının yeniden-doğrulama akışını seçmesi için —
    // e-posta/şifre ile kayıtlıysa true, Google/telefon ile girişte false.
    @Default(false) bool sifreVarMi,
  }) = _KullaniciModel;
 
  factory KullaniciModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return KullaniciModel(
      id:                   doc.id,
      adSoyad:              d['adSoyad']              as String? ?? '',
      fotoUrl:              d['fotoUrl']              as String?,
      telefon:              d['telefon']              as String?,
      email:                d['email']                as String?,
      fcmToken:             d['fcmToken']             as String?,
      profilTamamlandi:     d['profilTamamlandi']     as bool?   ?? false,
      ortalamaPuan:         ((d['ortalamaPuan']       as num?)?.toDouble()) ?? 0.0,
      degerlendirmeSayisi:  ((d['degerlendirmeSayisi'] as num?)?.toInt()) ?? 0,
      kullaniciTipi:        d['kullaniciTipi']        as String? ?? '',
      yasadigiUlke:         d['yasadigiUlke']         as String? ?? '',
      bulunduguSehir:       d['bulunduguSehir']       as String? ?? '',
      geldigiSehirler:      List<String>.from(d['geldigiSehirler'] ?? []),
      hakkinda:             d['hakkinda']             as String? ?? '',
      telefonGizli:         d['telefonGizli']         as bool?   ?? false,
      engellenenler:        List<String>.from(d['engellenenler'] ?? []),
      ilgiKategorileri:     List<String>.from(d['ilgiKategorileri'] ?? []),
      dutyFreeIlgileniyor:  d['dutyFreeIlgileniyor'] as bool?,
      istekTeslimatTercihi: d['istekTeslimatTercihi'] as String?,
      kadinUstBeden:        List<String>.from(d['kadinUstBeden'] ?? []),
      kadinAltBeden:        List<String>.from(d['kadinAltBeden'] ?? []),
      erkekUstBeden:        List<String>.from(d['erkekUstBeden'] ?? []),
      erkekAltBeden:        List<String>.from(d['erkekAltBeden'] ?? []),
      kadinAyakkabi:        List<String>.from(d['kadinAyakkabi'] ?? []),
      erkekAyakkabi:        List<String>.from(d['erkekAyakkabi'] ?? []),
      cocukAyakkabi:        List<String>.from(d['cocukAyakkabi'] ?? []),
      takipciSayisi:        ((d['takipciSayisi'] as num?)?.toInt()) ?? 0,
      takipSayisi:          ((d['takipSayisi']   as num?)?.toInt()) ?? 0,
      guvenSkoru:           ((d['guvenSkoru']    as num?)?.toInt()) ?? 0,
      rozetler:             List<String>.from(d['rozetler'] ?? []),
      banli:                d['banli']      as bool?   ?? false,
      banSebebi:            d['banSebebi']  as String? ?? '',
    );
  }
 
  /// AWS backend'inden (GET /v3/kullanicilar/:id, GET /v3/profilim) gelen
  /// JSON'u okur. engellenenler artık burada YOK — ayrı bir uçtan
  /// (GET /v3/engellenenlerim) geliyor, bkz. KullaniciRepository.
  factory KullaniciModel.fromApi(Map<String, dynamic> json) {
    final bedenler = json['bedenTercihleri'] as Map<String, dynamic>? ?? {};
    final bildirimTercihleri = json['bildirimTercihleri'] as Map<String, dynamic>? ?? {};
    return KullaniciModel(
      id: json['id'] as String? ?? '',
      adSoyad: json['adSoyad'] as String? ?? '',
      fotoUrl: (json['fotoUrl'] as String?)?.isEmpty == true ? null : json['fotoUrl'] as String?,
      telefon: (json['telefon'] as String?)?.isEmpty == true ? null : json['telefon'] as String?,
      email: (json['email'] as String?)?.isEmpty == true ? null : json['email'] as String?,
      fcmToken: json['fcmToken'] as String?,
      profilTamamlandi: json['profilTamamlandi'] as bool? ?? false,
      ortalamaPuan: (json['ortalamaPuan'] as num?)?.toDouble() ?? 0.0,
      degerlendirmeSayisi: (json['degerlendirmeSayisi'] as num?)?.toInt() ?? 0,
      kullaniciTipi: json['kullaniciTipi'] as String? ?? '',
      yasadigiUlke: json['yasadigiUlke'] as String? ?? '',
      bulunduguSehir: json['bulunduguSehir'] as String? ?? '',
      geldigiSehirler: List<String>.from(json['geldigiSehirler'] ?? []),
      hakkinda: json['hakkinda'] as String? ?? '',
      telefonGizli: json['telefonGizli'] as bool? ?? false,
      ilgiKategorileri: List<String>.from(json['ilgiKategorileri'] ?? []),
      dutyFreeIlgileniyor: json['dutyFreeIlgileniyor'] as bool?,
      istekTeslimatTercihi: json['istekTeslimatTercihi'] as String?,
      kadinUstBeden: List<String>.from(bedenler['kadinUstBeden'] ?? []),
      kadinAltBeden: List<String>.from(bedenler['kadinAltBeden'] ?? []),
      erkekUstBeden: List<String>.from(bedenler['erkekUstBeden'] ?? []),
      erkekAltBeden: List<String>.from(bedenler['erkekAltBeden'] ?? []),
      kadinAyakkabi: List<String>.from(bedenler['kadinAyakkabi'] ?? []),
      erkekAyakkabi: List<String>.from(bedenler['erkekAyakkabi'] ?? []),
      cocukAyakkabi: List<String>.from(bedenler['cocukAyakkabi'] ?? []),
      takipciSayisi: (json['takipciSayisi'] as num?)?.toInt() ?? 0,
      takipSayisi: (json['takipSayisi'] as num?)?.toInt() ?? 0,
      guvenSkoru: (json['guvenSkoru'] as num?)?.toInt() ?? 0,
      rozetler: List<String>.from(json['rozetler'] ?? []),
      banli: json['banli'] as bool? ?? false,
      banSebebi: json['banSebebi'] as String? ?? '',
      bildirimTercihleri: bildirimTercihleri.map((k, v) => MapEntry(k, v as bool? ?? true)),
      sifreVarMi: json['sifreVarMi'] as bool? ?? false,
    );
  }

  factory KullaniciModel.fromJson(Map<String, dynamic> json) =>
      _$KullaniciModelFromJson(json);
}
 
extension KullaniciModelX on KullaniciModel {
  Map<String, dynamic> toFirestore() => {
    'adSoyad':             adSoyad,
    if (fotoUrl != null)   'fotoUrl':   fotoUrl,
    if (telefon != null)   'telefon':   telefon,
    if (email != null)     'email':     email,
    if (fcmToken != null)  'fcmToken':  fcmToken,
    'profilTamamlandi':    profilTamamlandi,
    'ortalamaPuan':        ortalamaPuan,
    'degerlendirmeSayisi': degerlendirmeSayisi,
    'kullaniciTipi':       kullaniciTipi,
    'yasadigiUlke':        yasadigiUlke,
    'bulunduguSehir':      bulunduguSehir,
    'geldigiSehirler':     geldigiSehirler,
    'hakkinda':            hakkinda,
    'telefonGizli':        telefonGizli,
    'engellenenler':       engellenenler,
    'ilgiKategorileri':    ilgiKategorileri,
    if (dutyFreeIlgileniyor != null) 'dutyFreeIlgileniyor': dutyFreeIlgileniyor,
    if (istekTeslimatTercihi != null) 'istekTeslimatTercihi': istekTeslimatTercihi,
    if (kadinUstBeden.isNotEmpty) 'kadinUstBeden': kadinUstBeden,
    if (kadinAltBeden.isNotEmpty) 'kadinAltBeden': kadinAltBeden,
    if (erkekUstBeden.isNotEmpty) 'erkekUstBeden': erkekUstBeden,
    if (erkekAltBeden.isNotEmpty) 'erkekAltBeden': erkekAltBeden,
    if (kadinAyakkabi.isNotEmpty) 'kadinAyakkabi': kadinAyakkabi,
    if (erkekAyakkabi.isNotEmpty) 'erkekAyakkabi': erkekAyakkabi,
    if (cocukAyakkabi.isNotEmpty) 'cocukAyakkabi': cocukAyakkabi,
    if (takipciSayisi > 0) 'takipciSayisi': takipciSayisi,
    if (takipSayisi   > 0) 'takipSayisi':   takipSayisi,
    if (guvenSkoru    > 0) 'guvenSkoru':    guvenSkoru,
    if (rozetler.isNotEmpty) 'rozetler':    rozetler,
  };
 
  bool get tasiyiciMi =>
      kullaniciTipi == 'tasiyici' || kullaniciTipi == 'her_ikisi';
 
  bool get istekMi =>
      kullaniciTipi == 'istek' || kullaniciTipi == 'her_ikisi';

  String get guvenSkoruEtiketi {
    if (guvenSkoru >= 80) return 'Çok Güvenilir';
    if (guvenSkoru >= 60) return 'Güvenilir';
    if (guvenSkoru >= 40) return 'Orta';
    return 'Düşük';
  }

  String rozetEmoji(String rozet) {
    const emojiler = {
      'dogrulandi':      '✅',
      'hizli_teslimat':  '⚡',
      'guvenilir':       '🛡️',
      'cok_satilan':     '🔥',
      'yeni_uye':        '🌟',
      'premium':         '👑',
    };
    return emojiler[rozet] ?? '🏅';
  }

  String rozetAdi(String rozet) {
    const adlar = {
      'dogrulandi':      'Doğrulandı',
      'hizli_teslimat':  'Hızlı Teslimat',
      'guvenilir':       'Güvenilir',
      'cok_satilan':     'Çok Satan',
      'yeni_uye':        'Yeni Üye',
      'premium':         'Premium',
    };
    return adlar[rozet] ?? rozet;
  }
}