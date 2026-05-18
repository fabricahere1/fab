import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ilan_model.freezed.dart';
part 'ilan_model.g.dart';

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
    @Default(0.0) double kullaniciPuan,
    @Default('') String anaKategori,
    @Default([]) List<String> kategoriYolu,
  }) = _IlanModel;

  factory IlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IlanModel(
      id:              doc.id,
      tip:             data['tip']          as String? ?? '',
      nereden:         data['nereden']      as String? ?? '',
      nereye:          data['nereye']       as String? ?? '',
      ucret:           data['ucret']        as String? ?? '',
      urun:            data['urun']         as String? ?? '',
      notlar:          data['notlar']       as String? ?? '',
      kategori:        data['kategori']     as String? ?? 'diger',
      kullaniciId:     data['kullaniciId']  as String? ?? '',
      kullaniciAd:     data['kullaniciAd']  as String? ?? 'Kullanıcı',
      aktif:           data['aktif']        as bool?   ?? true,
      tarih:           (data['tarih']       as Timestamp?)?.toDate(),
      olusturmaTarihi: (data['olusturmaTarihi'] as Timestamp?)?.toDate(),
      resimUrl:        data['resimUrl']     as String? ?? '',
      resimUrller:     List<String>.from(data['resimUrller'] ?? []),
      urunLinki:       data['urunLinki']    as String? ?? '',
      favoriSayisi:    (data['favoriSayisi'] as num?)?.toInt() ?? 0,
      tasimaTercihi:   data['tasimaTercihi'] as String? ?? 'hepsi',
      kullaniciPuan:   (data['kullaniciPuan'] as num?)?.toDouble() ?? 0.0,
      anaKategori:     data['anaKategori']   as String? ?? '',
      kategoriYolu:    List<String>.from(data['kategoriYolu'] ?? []),
    );
  }

  factory IlanModel.fromJson(Map<String, dynamic> json) =>
      _$IlanModelFromJson(json);
}

extension IlanModelX on IlanModel {
  List<String> get tumResimler {
    if (resimUrller.isNotEmpty) return resimUrller;
    if (resimUrl.isNotEmpty) return [resimUrl];
    return [];
  }

  Map<String, dynamic> toFirestore() => {
    'tip':             tip,
    'nereden':         nereden,
    'nereye':          nereye,
    'ucret':           ucret,
    'urun':            urun,
    'notlar':          notlar,
    'urunLinki':       urunLinki,
    'kategori':        kategori,
    'kullaniciId':     kullaniciId,
    'kullaniciAd':     kullaniciAd,
    'aktif':           aktif,
    'tasimaTercihi':   tasimaTercihi,
    'kullaniciPuan':   kullaniciPuan,
    'anaKategori':     anaKategori,
    'kategoriYolu':    kategoriYolu,
    if (tarih != null) 'tarih': Timestamp.fromDate(tarih!),
    'olusturmaTarihi': FieldValue.serverTimestamp(),
    if (resimUrl.isNotEmpty) 'resimUrl': resimUrl,
    if (resimUrller.isNotEmpty) 'resimUrller': resimUrller,
  };
}