// cloud_firestore import YOK — domain katmanı Firebase'i tanımaz
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ilan_model.freezed.dart';
part 'ilan_model.g.dart';

// TimestampConverter burada kalıyor — Freezed JSON serialization için gerekli
// ama cloud_firestore yerine dynamic kullanıyor
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? date) {
    if (date == null) return null;
    return date.toIso8601String();
  }
}

@freezed
abstract class IlanModel with _$IlanModel {
  const factory IlanModel({
    required String id,
    required String tip,
    required String nereden,
    required String nereye,
    @Default('') String ucret,
    @Default('') String urun,
    @Default('') String notlar,
    @Default('diger') String kategori,
    required String kullaniciId,
    @Default('Kullanıcı') String kullaniciAd,
    @Default(true) bool aktif,
    @TimestampConverter() DateTime? tarih,
    @TimestampConverter() DateTime? olusturmaTarihi,
    @Default('') String resimUrl,
    @Default([]) List<String> resimUrller,
    @Default('') String urunLinki,
    @Default(0) int favoriSayisi,
    @Default('hepsi') String tasimaTercihi,
  }) = _IlanModel;

  // fromFirestore ilan_repository.dart'ta _ilanModelCevir — domain Firebase'i tanımaz

  factory IlanModel.fromJson(Map<String, dynamic> json) =>
      _$IlanModelFromJson(json);
}

extension IlanModelX on IlanModel {
  List<String> get tumResimler {
    if (resimUrller.isNotEmpty) return resimUrller;
    if (resimUrl.isNotEmpty) return [resimUrl];
    return [];
  }
}
