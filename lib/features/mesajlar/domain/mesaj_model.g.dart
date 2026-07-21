// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesaj_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MesajModel _$MesajModelFromJson(Map<String, dynamic> json) => _MesajModel(
  id: json['id'] as String,
  metin: json['metin'] as String,
  gondereId: json['gondereId'] as String,
  tip: $enumDecodeNullable(_$MesajTipEnumMap, json['tip']) ?? MesajTip.mesaj,
  zaman: const TimestampConverter().fromJson(json['zaman']),
  okundu: json['okundu'] as bool? ?? false,
  resimUrl: json['resimUrl'] as String?,
  gonderiliyor: json['gonderiliyor'] as bool? ?? false,
);

Map<String, dynamic> _$MesajModelToJson(_MesajModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'metin': instance.metin,
      'gondereId': instance.gondereId,
      'tip': _$MesajTipEnumMap[instance.tip]!,
      'zaman': const TimestampConverter().toJson(instance.zaman),
      'okundu': instance.okundu,
      'resimUrl': instance.resimUrl,
      'gonderiliyor': instance.gonderiliyor,
    };

const _$MesajTipEnumMap = {
  MesajTip.mesaj: 'mesaj',
  MesajTip.resim: 'resim',
  MesajTip.sistem: 'sistem',
};

_SohbetModel _$SohbetModelFromJson(Map<String, dynamic> json) => _SohbetModel(
  id: json['id'] as String,
  kullanicilar: (json['kullanicilar'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  ilanId: json['ilanId'] as String,
  ilanBaslik: json['ilanBaslik'] as String? ?? '',
  ilanResimUrl: json['ilanResimUrl'] as String? ?? '',
  ilanSahibiId: json['ilanSahibiId'] as String? ?? '',
  ilanTip: json['ilanTip'] as String? ?? 'istek',
  sonMesaj: json['sonMesaj'] as String?,
  sonMesajZamani: const TimestampConverter().fromJson(json['sonMesajZamani']),
  sonAktiviteZamani: const TimestampConverter().fromJson(
    json['sonAktiviteZamani'],
  ),
  sonGondereId: json['sonGondereId'] as String? ?? '',
  okunmamis:
      (json['okunmamis'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  gizli: json['gizli'] as Map<String, dynamic>? ?? const {},
  sabitlenmis:
      (json['sabitlenmis'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  kullaniciAdlari:
      (json['kullaniciAdlari'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  islemDurumlari: json['islemDurumlari'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$SohbetModelToJson(
  _SohbetModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'kullanicilar': instance.kullanicilar,
  'ilanId': instance.ilanId,
  'ilanBaslik': instance.ilanBaslik,
  'ilanResimUrl': instance.ilanResimUrl,
  'ilanSahibiId': instance.ilanSahibiId,
  'ilanTip': instance.ilanTip,
  'sonMesaj': instance.sonMesaj,
  'sonMesajZamani': const TimestampConverter().toJson(instance.sonMesajZamani),
  'sonAktiviteZamani': const TimestampConverter().toJson(
    instance.sonAktiviteZamani,
  ),
  'sonGondereId': instance.sonGondereId,
  'okunmamis': instance.okunmamis,
  'gizli': instance.gizli,
  'sabitlenmis': instance.sabitlenmis,
  'kullaniciAdlari': instance.kullaniciAdlari,
  'islemDurumlari': instance.islemDurumlari,
};
