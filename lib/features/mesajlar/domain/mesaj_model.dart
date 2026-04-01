import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
 
part 'mesaj_model.freezed.dart';
part 'mesaj_model.g.dart';
 
// ── Timestamp Converter ───────────────────────────────────
 
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();
 
  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    return null;
  }
 
  @override
  Object? toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}
 
// ── Mesaj Tipi ────────────────────────────────────────────
 
enum MesajTip { mesaj, sistem }
 
// ── Mesaj Modeli ──────────────────────────────────────────
 
@freezed
abstract class MesajModel with _$MesajModel {
  const factory MesajModel({
    required String id,
    required String metin,
    required String gondereId,
    @Default('') String gondereAd,
    @Default(MesajTip.mesaj) MesajTip tip,
    @TimestampConverter() DateTime? zaman,
    @Default(false) bool okundu,
  }) = _MesajModel;
 
  factory MesajModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MesajModel(
      id:        doc.id,
      metin:     d['metin']     as String? ?? '',
      gondereId: d['gondereId'] as String? ?? '',
      gondereAd: d['gondereAd'] as String? ?? '',
      tip:       d['tip'] == 'sistem' ? MesajTip.sistem : MesajTip.mesaj,
      zaman:     (d['zaman'] as Timestamp?)?.toDate(),
      okundu:    d['okundu']    as bool?   ?? false,
    );
  }
 
  factory MesajModel.fromJson(Map<String, dynamic> json) =>
      _$MesajModelFromJson(json);
}
 
extension MesajModelX on MesajModel {
  bool get sistemMesaji => tip == MesajTip.sistem;
 
  Map<String, dynamic> toFirestore() => {
    'metin':     metin,
    'gondereId': gondereId,
    'gondereAd': gondereAd,
    'tip':       tip == MesajTip.sistem ? 'sistem' : 'mesaj',
    'zaman':     FieldValue.serverTimestamp(),
    'okundu':    okundu,
  };
}
 
// ── Sohbet Modeli ─────────────────────────────────────────
 
@freezed
abstract class SohbetModel with _$SohbetModel {
  const factory SohbetModel({
    required String id,
    required List<String> kullanicilar,
    @Default({}) Map<String, String> kullaniciAdlari,
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
 
  factory SohbetModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SohbetModel(
      id:             doc.id,
      kullanicilar:   List<String>.from(d['kullanicilar'] ?? []),
      kullaniciAdlari: Map<String, String>.from(
        (d['kullaniciAdlari'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ?? {},
      ),
      ilanId:         d['ilanId']      as String? ?? '',
      ilanBaslik:     d['ilanBaslik']  as String? ?? '',
      ilanResimUrl:   d['ilanResimUrl'] as String? ?? '',
      sonMesaj:       d['sonMesaj']    as String?,
      sonMesajZamani: (d['sonMesajZamani'] as Timestamp?)?.toDate(),
      sonGondereId:   d['sonGondereId'] as String? ?? '',
      okunmamis: Map<String, int>.from(
        (d['okunmamis'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ) ?? {},
      ),
      gizli: Map<String, dynamic>.from(d['gizli'] ?? {}),
      sabitlenmis: Map<String, bool>.from(
        (d['sabitlenmis'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v as bool),
        ) ?? {},
      ),
      degerlendirmeYapildi: d['degerlendirmeYapildi'] as bool? ?? false,
    );
  }
 
  factory SohbetModel.fromJson(Map<String, dynamic> json) =>
      _$SohbetModelFromJson(json);
}
 
extension SohbetModelX on SohbetModel {
  int okunmamisSayisi(String kullaniciId) =>
      okunmamis[kullaniciId] ?? 0;
 
  String karsiKullaniciId(String benimId) =>
      kullanicilar.firstWhere((id) => id != benimId, orElse: () => '');
 
  bool sabitMi(String kullaniciId) =>
      sabitlenmis[kullaniciId] ?? false;
}