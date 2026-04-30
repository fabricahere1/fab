// cloud_firestore import YOK — domain katmanı Firebase'i tanımaz
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../ilanlar/domain/ilan_model.dart' show TimestampConverter;

part 'mesaj_model.freezed.dart';
part 'mesaj_model.g.dart';

enum MesajTip { mesaj, sistem }

@freezed
abstract class MesajModel with _$MesajModel {
  const factory MesajModel({
    required String id,
    required String metin,
    required String gondereId,
    @Default(MesajTip.mesaj) MesajTip tip,
    @TimestampConverter() DateTime? zaman,
    @Default(false) bool okundu,
  }) = _MesajModel;

  // fromFirestore repository'de (_mesajMapCevir) — domain Firebase'i tanımaz

  factory MesajModel.fromJson(Map<String, dynamic> json) =>
      _$MesajModelFromJson(json);
}

extension MesajModelX on MesajModel {
  bool get sistemMesaji => tip == MesajTip.sistem;
}

// ── Sohbet Modeli ─────────────────────────────────────────
// kullaniciAdlari KALDIRILDI — karşı kullanıcı adı profil koleksiyonundan alınır

@freezed
abstract class SohbetModel with _$SohbetModel {
  const factory SohbetModel({
    required String id,
    required List<String> kullanicilar,
    required String ilanId,
    @Default('') String ilanBaslik,
    @Default('') String ilanResimUrl,
    String? sonMesaj,
    @TimestampConverter() DateTime? sonMesajZamani,
    @Default('') String sonGondereId,
    @Default({}) Map<String, int> okunmamis,
    @Default({}) Map<String, dynamic> gizli,
    @Default({}) Map<String, bool> sabitlenmis,
    @Default(false) bool degerlendirmeYapildi,
  }) = _SohbetModel;

  // fromFirestore data/mesaj_repository.dart'ta _sohbetModelCevir — domain Firebase'i tanımaz

  factory SohbetModel.fromJson(Map<String, dynamic> json) =>
      _$SohbetModelFromJson(json);
}

extension SohbetModelX on SohbetModel {
  int okunmamisSayisi(String kullaniciId) =>
      okunmamis[kullaniciId] ?? 0;

  // Karşı kullanıcı UID'ini döndürür — asla map'e bakmaz
  String karsiKullaniciId(String benimId) =>
      kullanicilar.firstWhere((id) => id != benimId, orElse: () => '');

  bool sabitMi(String kullaniciId) =>
      sabitlenmis[kullaniciId] ?? false;

  bool gizliMi(String kullaniciId) {
    final gizliDeger = gizli[kullaniciId];
    if (gizliDeger == null) return false;
    if (gizliDeger is bool) return gizliDeger;
    // fromFirestore'da Timestamp → DateTime'a çevrildi
    if (gizliDeger is DateTime && sonMesajZamani != null) {
      return !sonMesajZamani!.isAfter(gizliDeger);
    }
    return false;
  }
}
