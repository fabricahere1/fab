// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ilan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IlanModel _$IlanModelFromJson(Map<String, dynamic> json) => _IlanModel(
  id: json['id'] as String,
  tip: json['tip'] as String,
  nereden: json['nereden'] as String,
  nereye: json['nereye'] as String,
  ucret: json['ucret'] as String? ?? '',
  urun: json['urun'] as String? ?? '',
  notlar: json['notlar'] as String? ?? '',
  kategori: json['kategori'] as String? ?? 'diger',
  kullaniciId: json['kullaniciId'] as String,
  kullaniciAd: json['kullaniciAd'] as String? ?? 'Kullanıcı',
  aktif: json['aktif'] as bool? ?? true,
  tarih: const TimestampConverter().fromJson(json['tarih']),
  olusturmaTarihi: const TimestampConverter().fromJson(json['olusturmaTarihi']),
  resimUrl: json['resimUrl'] as String? ?? '',
  resimThumbUrl: json['resimThumbUrl'] as String? ?? '',
  resimUrller:
      (json['resimUrller'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  urunLinki: json['urunLinki'] as String? ?? '',
  favoriSayisi: (json['favoriSayisi'] as num?)?.toInt() ?? 0,
  goruntulenmeSayisi: (json['goruntulenmeSayisi'] as num?)?.toInt() ?? 0,
  tasimaTercihi: json['tasimaTercihi'] as String? ?? 'hepsi',
  kullaniciPuan: (json['kullaniciPuan'] as num?)?.toDouble() ?? 0.0,
  anaKategori: json['anaKategori'] as String? ?? '',
  kategoriYolu:
      (json['kategoriYolu'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  cinsiyet: json['cinsiyet'] as String? ?? '',
  beden: json['beden'] as String? ?? '',
);

Map<String, dynamic> _$IlanModelToJson(_IlanModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tip': instance.tip,
      'nereden': instance.nereden,
      'nereye': instance.nereye,
      'ucret': instance.ucret,
      'urun': instance.urun,
      'notlar': instance.notlar,
      'kategori': instance.kategori,
      'kullaniciId': instance.kullaniciId,
      'kullaniciAd': instance.kullaniciAd,
      'aktif': instance.aktif,
      'tarih': const TimestampConverter().toJson(instance.tarih),
      'olusturmaTarihi': const TimestampConverter().toJson(
        instance.olusturmaTarihi,
      ),
      'resimUrl': instance.resimUrl,
      'resimThumbUrl': instance.resimThumbUrl,
      'resimUrller': instance.resimUrller,
      'urunLinki': instance.urunLinki,
      'favoriSayisi': instance.favoriSayisi,
      'goruntulenmeSayisi': instance.goruntulenmeSayisi,
      'tasimaTercihi': instance.tasimaTercihi,
      'kullaniciPuan': instance.kullaniciPuan,
      'anaKategori': instance.anaKategori,
      'kategoriYolu': instance.kategoriYolu,
      'cinsiyet': instance.cinsiyet,
      'beden': instance.beden,
    };
