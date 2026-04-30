// cloud_firestore import YOK — domain katmanı Firebase'i tanımaz
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

  // fromFirestore kullanici_repository.dart'ta _kullaniciModelCevir — domain Firebase'i tanımaz

  factory KullaniciModel.fromJson(Map<String, dynamic> json) =>
      _$KullaniciModelFromJson(json);
}

extension KullaniciModelX on KullaniciModel {
  bool get tasiyiciMi =>
      kullaniciTipi == 'tasiyici' || kullaniciTipi == 'her_ikisi';

  bool get istekMi =>
      kullaniciTipi == 'istek' || kullaniciTipi == 'her_ikisi';
}
