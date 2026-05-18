// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bildirim_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BildirimModel _$BildirimModelFromJson(Map<String, dynamic> json) =>
    _BildirimModel(
      id: json['id'] as String,
      kullaniciId: json['kullaniciId'] as String,
      tip:
          $enumDecodeNullable(_$BildirimTipEnumMap, json['tip']) ??
          BildirimTip.sistem,
      baslik: json['baslik'] as String? ?? '',
      icerik: json['icerik'] as String? ?? '',
      okundu: json['okundu'] as bool? ?? false,
      tarih: json['tarih'] == null
          ? null
          : DateTime.parse(json['tarih'] as String),
      hedefId: json['hedefId'] as String? ?? '',
      gondereId: json['gondereId'] as String? ?? '',
      gondereAd: json['gondereAd'] as String? ?? '',
    );

Map<String, dynamic> _$BildirimModelToJson(_BildirimModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kullaniciId': instance.kullaniciId,
      'tip': _$BildirimTipEnumMap[instance.tip]!,
      'baslik': instance.baslik,
      'icerik': instance.icerik,
      'okundu': instance.okundu,
      'tarih': instance.tarih?.toIso8601String(),
      'hedefId': instance.hedefId,
      'gondereId': instance.gondereId,
      'gondereAd': instance.gondereAd,
    };

const _$BildirimTipEnumMap = {
  BildirimTip.mesaj: 'mesaj',
  BildirimTip.ilan: 'ilan',
  BildirimTip.sistem: 'sistem',
  BildirimTip.degerlendirme: 'degerlendirme',
  BildirimTip.anlasildi: 'anlasildi',
};
