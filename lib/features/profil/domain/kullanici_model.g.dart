// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kullanici_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KullaniciModel _$KullaniciModelFromJson(Map<String, dynamic> json) =>
    _KullaniciModel(
      id: json['id'] as String,
      adSoyad: json['adSoyad'] as String? ?? '',
      fotoUrl: json['fotoUrl'] as String?,
      telefon: json['telefon'] as String?,
      email: json['email'] as String?,
      fcmToken: json['fcmToken'] as String?,
      profilTamamlandi: json['profilTamamlandi'] as bool? ?? false,
      ortalamaPuan: (json['ortalamaPuan'] as num?)?.toDouble() ?? 0.0,
      degerlendirmeSayisi: (json['degerlendirmeSayisi'] as num?)?.toInt() ?? 0,
      kullaniciTipi: json['kullaniciTipi'] as String? ?? '',
      yasadigiUlke: json['yasadigiUlke'] as String? ?? '',
      bulunduguSehir: json['bulunduguSehir'] as String? ?? '',
      geldigiSehirler:
          (json['geldigiSehirler'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hakkinda: json['hakkinda'] as String? ?? '',
      sehir: json['sehir'] as String? ?? '',
      telefonGizli: json['telefonGizli'] as bool? ?? false,
      engellenenler:
          (json['engellenenler'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      ilgiKategorileri:
          (json['ilgiKategorileri'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      dutyFreeIlgileniyor: json['dutyFreeIlgileniyor'] as bool?,
      istekTeslimatTercihi: json['istekTeslimatTercihi'] as String?,
      kadinUstBeden:
          (json['kadinUstBeden'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      kadinAltBeden:
          (json['kadinAltBeden'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      erkekUstBeden:
          (json['erkekUstBeden'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      erkekAltBeden:
          (json['erkekAltBeden'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      kadinAyakkabi:
          (json['kadinAyakkabi'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      erkekAyakkabi:
          (json['erkekAyakkabi'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      cocukAyakkabi:
          (json['cocukAyakkabi'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$KullaniciModelToJson(_KullaniciModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'adSoyad': instance.adSoyad,
      'fotoUrl': instance.fotoUrl,
      'telefon': instance.telefon,
      'email': instance.email,
      'fcmToken': instance.fcmToken,
      'profilTamamlandi': instance.profilTamamlandi,
      'ortalamaPuan': instance.ortalamaPuan,
      'degerlendirmeSayisi': instance.degerlendirmeSayisi,
      'kullaniciTipi': instance.kullaniciTipi,
      'yasadigiUlke': instance.yasadigiUlke,
      'bulunduguSehir': instance.bulunduguSehir,
      'geldigiSehirler': instance.geldigiSehirler,
      'hakkinda': instance.hakkinda,
      'sehir': instance.sehir,
      'telefonGizli': instance.telefonGizli,
      'engellenenler': instance.engellenenler,
      'ilgiKategorileri': instance.ilgiKategorileri,
      'dutyFreeIlgileniyor': instance.dutyFreeIlgileniyor,
      'istekTeslimatTercihi': instance.istekTeslimatTercihi,
      'kadinUstBeden': instance.kadinUstBeden,
      'kadinAltBeden': instance.kadinAltBeden,
      'erkekUstBeden': instance.erkekUstBeden,
      'erkekAltBeden': instance.erkekAltBeden,
      'kadinAyakkabi': instance.kadinAyakkabi,
      'erkekAyakkabi': instance.erkekAyakkabi,
      'cocukAyakkabi': instance.cocukAyakkabi,
    };
