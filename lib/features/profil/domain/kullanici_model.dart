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
    @Default('') String sehir,
    @Default(false) bool telefonGizli,
    @Default([]) List<String> engellenenler,
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
      sehir:                d['sehir']                as String? ?? '',
      telefonGizli:         d['telefonGizli']         as bool?   ?? false,
      engellenenler:        List<String>.from(d['engellenenler'] ?? []),
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
    'sehir':               sehir,
    'telefonGizli':        telefonGizli,
    'engellenenler':       engellenenler,
  };
 
  bool get tasiyiciMi =>
      kullaniciTipi == 'tasiyici' || kullaniciTipi == 'her_ikisi';
 
  bool get istekMi =>
      kullaniciTipi == 'istek' || kullaniciTipi == 'her_ikisi';
}