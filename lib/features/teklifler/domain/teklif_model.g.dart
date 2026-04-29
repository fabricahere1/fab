// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teklif_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeklifModel _$TeklifModelFromJson(Map<String, dynamic> json) => _TeklifModel(
  id: json['id'] as String,
  ilanId: json['ilanId'] as String,
  ilanBaslik: json['ilanBaslik'] as String,
  ilanSahibiId: json['ilanSahibiId'] as String,
  ilanSahibiAd: json['ilanSahibiAd'] as String,
  teklifVerenId: json['teklifVerenId'] as String,
  teklifVerenAd: json['teklifVerenAd'] as String,
  miktar: (json['miktar'] as num).toDouble(),
  ilanMiktar: (json['ilanMiktar'] as num).toDouble(),
  durum:
      $enumDecodeNullable(_$TeklifDurumEnumMap, json['durum']) ??
      TeklifDurum.bekliyor,
  karsiTeklifMiktar: (json['karsiTeklifMiktar'] as num?)?.toDouble(),
  olusturmaTarihi: json['olusturmaTarihi'] == null
      ? null
      : DateTime.parse(json['olusturmaTarihi'] as String),
  guncellemeTarihi: json['guncellemeTarihi'] == null
      ? null
      : DateTime.parse(json['guncellemeTarihi'] as String),
  olusumTipi: json['olusumTipi'] as String? ?? OlusumTipi.teklif,
  teslimDurumu: json['teslimDurumu'] as String? ?? 'beklemede',
  teslimatTipi: json['teslimatTipi'] as String? ?? 'beklemede',
  getirenTeslimBeyan: json['getirenTeslimBeyan'] as String? ?? 'yok',
  isteyenTeslimOnay: json['isteyenTeslimOnay'] as String? ?? 'yok',
  kargoSirketi: json['kargoSirketi'] as String? ?? '',
  kargoTakipNo: json['kargoTakipNo'] as String? ?? '',
  teslimOnayTarihi: json['teslimOnayTarihi'] == null
      ? null
      : DateTime.parse(json['teslimOnayTarihi'] as String),
  isteyenDegerlendirdiMi: json['isteyenDegerlendirdiMi'] as bool? ?? false,
  getirenDegerlendirdiMi: json['getirenDegerlendirdiMi'] as bool? ?? false,
  degerlendirmeAcilmaTarihi: json['degerlendirmeAcilmaTarihi'] == null
      ? null
      : DateTime.parse(json['degerlendirmeAcilmaTarihi'] as String),
);

Map<String, dynamic> _$TeklifModelToJson(_TeklifModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ilanId': instance.ilanId,
      'ilanBaslik': instance.ilanBaslik,
      'ilanSahibiId': instance.ilanSahibiId,
      'ilanSahibiAd': instance.ilanSahibiAd,
      'teklifVerenId': instance.teklifVerenId,
      'teklifVerenAd': instance.teklifVerenAd,
      'miktar': instance.miktar,
      'ilanMiktar': instance.ilanMiktar,
      'durum': _$TeklifDurumEnumMap[instance.durum]!,
      'karsiTeklifMiktar': instance.karsiTeklifMiktar,
      'olusturmaTarihi': instance.olusturmaTarihi?.toIso8601String(),
      'guncellemeTarihi': instance.guncellemeTarihi?.toIso8601String(),
      'olusumTipi': instance.olusumTipi,
      'teslimDurumu': instance.teslimDurumu,
      'teslimatTipi': instance.teslimatTipi,
      'getirenTeslimBeyan': instance.getirenTeslimBeyan,
      'isteyenTeslimOnay': instance.isteyenTeslimOnay,
      'kargoSirketi': instance.kargoSirketi,
      'kargoTakipNo': instance.kargoTakipNo,
      'teslimOnayTarihi': instance.teslimOnayTarihi?.toIso8601String(),
      'isteyenDegerlendirdiMi': instance.isteyenDegerlendirdiMi,
      'getirenDegerlendirdiMi': instance.getirenDegerlendirdiMi,
      'degerlendirmeAcilmaTarihi': instance.degerlendirmeAcilmaTarihi
          ?.toIso8601String(),
    };

const _$TeklifDurumEnumMap = {
  TeklifDurum.bekliyor: 'bekliyor',
  TeklifDurum.kabul: 'kabul',
  TeklifDurum.reddedildi: 'reddedildi',
  TeklifDurum.karsiTeklif: 'karsiTeklif',
};
