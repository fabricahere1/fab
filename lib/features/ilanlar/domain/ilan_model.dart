import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ilan_model.freezed.dart';
part 'ilan_model.g.dart';

// ── İlan durumları ────────────────────────────────────────────────────────────

class IlanDurum {
  static const String onayBekliyor = 'onayBekliyor';
  static const String yayinda      = 'yayinda';
  static const String reddedildi   = 'reddedildi';
}

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
    @Default(false) bool aktif,
    @Default(IlanDurum.onayBekliyor) String durum,
    @Default('') String redSebebi,
    @TimestampConverter() DateTime? tarih,
    @TimestampConverter() DateTime? olusturmaTarihi,
    @Default('') String resimUrl,
    @Default('') String resimThumbUrl,
    @Default([]) List<String> resimUrller,
    @Default('') String urunLinki,
    @Default(0) int favoriSayisi,
    @Default(0) int goruntulenmeSayisi,
    @Default('hepsi') String tasimaTercihi,
    @Default(0.0) double kullaniciPuan,
    @Default('') String anaKategori,
    @Default([]) List<String> kategoriYolu,
    @Default('') String cinsiyet,
    @Default('') String beden,
    String? sahipIstekTeslimatTercihi,
    @Default(false) bool sahipDutyFree,
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
      aktif:           data['aktif']        as bool?   ?? false,
      durum:           data['durum']        as String? ?? IlanDurum.onayBekliyor,
      redSebebi:       data['redSebebi']    as String? ?? '',
      tarih:           (data['tarih']       as Timestamp?)?.toDate(),
      olusturmaTarihi: (data['olusturmaTarihi'] as Timestamp?)?.toDate(),
      resimUrl:        data['resimUrl']      as String? ?? '',
      resimThumbUrl:   data['resimThumbUrl'] as String? ?? '',
      resimUrller:     List<String>.from(data['resimUrller'] ?? []),
      urunLinki:       data['urunLinki']    as String? ?? '',
      favoriSayisi:         (data['favoriSayisi']         as num?)?.toInt() ?? 0,
      goruntulenmeSayisi:   (data['goruntulenmeSayisi']   as num?)?.toInt() ?? 0,
      tasimaTercihi:   data['tasimaTercihi'] as String? ?? 'hepsi',
      kullaniciPuan:   (data['kullaniciPuan'] as num?)?.toDouble() ?? 0.0,
      anaKategori:     data['anaKategori']   as String? ?? '',
      kategoriYolu:    List<String>.from(data['kategoriYolu'] ?? []),
      cinsiyet:        data['cinsiyet']      as String? ?? '',
      beden:           data['beden']         as String? ?? '',
      sahipIstekTeslimatTercihi: data['sahipIstekTeslimatTercihi'] as String?,
      sahipDutyFree:   data['sahipDutyFree'] as bool? ?? false,
    );
  }

  factory IlanModel.fromJson(Map<String, dynamic> json) =>
      _$IlanModelFromJson(json);
}

extension IlanModelX on IlanModel {
  String get gridResim {
    if (resimThumbUrl.isNotEmpty) return resimThumbUrl;
    if (resimUrl.isNotEmpty) return resimUrl;
    if (resimUrller.isNotEmpty) return resimUrller.first;
    return '';
  }

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
    'aktif':           false,           // Cloud Function onaylayana kadar false
    'durum':           IlanDurum.onayBekliyor,
    'tasimaTercihi':   tasimaTercihi,
    'kullaniciPuan':   kullaniciPuan,
    'anaKategori':     anaKategori,
    'kategoriYolu':    kategoriYolu,
    if (cinsiyet.isNotEmpty) 'cinsiyet': cinsiyet,
    if (beden.isNotEmpty)    'beden':    beden,
    if (sahipIstekTeslimatTercihi != null)
      'sahipIstekTeslimatTercihi': sahipIstekTeslimatTercihi,
    if (sahipDutyFree) 'sahipDutyFree': sahipDutyFree,
    if (tarih != null) 'tarih': Timestamp.fromDate(tarih!),
    'olusturmaTarihi': FieldValue.serverTimestamp(),
    if (resimUrl.isNotEmpty)      'resimUrl':      resimUrl,
    if (resimThumbUrl.isNotEmpty) 'resimThumbUrl': resimThumbUrl,
    if (resimUrller.isNotEmpty)   'resimUrller':   resimUrller,
  };
}