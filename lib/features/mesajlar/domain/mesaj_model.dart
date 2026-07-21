import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../ilanlar/domain/ilan_model.dart' show TimestampConverter;

part 'mesaj_model.freezed.dart';
part 'mesaj_model.g.dart';

enum MesajTip { mesaj, resim, sistem }

@freezed
abstract class MesajModel with _$MesajModel {
  const factory MesajModel({
    required String id,
    required String metin,
    required String gondereId,
    @Default(MesajTip.mesaj) MesajTip tip,
    @TimestampConverter() DateTime? zaman,
    @Default(false) bool okundu,
    String? resimUrl,
    @Default(false) bool gonderiliyor,
  }) = _MesajModel;

  factory MesajModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final tipStr = d['tip'] as String? ?? 'mesaj';
    return MesajModel(
      id:           doc.id,
      metin:        d['metin']     as String? ?? '',
      gondereId:    d['gondereId'] as String? ?? '',
      tip:          tipStr == 'sistem'
          ? MesajTip.sistem
          : tipStr == 'resim'
              ? MesajTip.resim
              : MesajTip.mesaj,
      zaman:        (d['zaman'] as Timestamp?)?.toDate() ?? DateTime.now(),
      okundu:       d['okundu']    as bool?   ?? false,
      resimUrl:     d['resimUrl']  as String?,
      gonderiliyor: doc.metadata.hasPendingWrites,
    );
  }

  factory MesajModel.fromJson(Map<String, dynamic> json) =>
      _$MesajModelFromJson(json);
}

extension MesajModelX on MesajModel {
  bool get sistemMesaji => tip == MesajTip.sistem;
}

// Bir katılımcı listesinde (sohbetler/{id}.kullanicilar ya da benzeri)
// "karşı taraf"ı bulan TEK kaynak — SohbetModelX, mesaj_repository.dart
// ve bildirimler_screen.dart hepsi buradan okur. Ham List<String> alır
// (Model'e ihtiyaç duymaz), böylece Firestore'dan henüz Model'e
// dönüştürülmemiş veri üzerinde çalışan yerler de kullanabilir.
String karsiTarafiBul(List<String> kullanicilar, String benimUid) =>
    kullanicilar.firstWhere((id) => id != benimUid, orElse: () => '');

@freezed
abstract class SohbetModel with _$SohbetModel {
  const factory SohbetModel({
    required String id,
    required List<String> kullanicilar,
    required String ilanId,
    @Default('') String ilanBaslik,
    @Default('') String ilanResimUrl,
    @Default('') String ilanSahibiId,
    @Default('istek') String ilanTip,
    String? sonMesaj,
    @TimestampConverter() DateTime? sonMesajZamani,
    @TimestampConverter() DateTime? sonAktiviteZamani,
    @Default('') String sonGondereId,
    @Default({}) Map<String, int> okunmamis,
    @Default({}) Map<String, dynamic> gizli,
    @Default({}) Map<String, bool> sabitlenmis,
    @Default({}) Map<String, String> kullaniciAdlari,
    @Default({}) Map<String, dynamic> islemDurumlari,
  }) = _SohbetModel;

  factory SohbetModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SohbetModel(
      id:            doc.id,
      kullanicilar:  List<String>.from(d['kullanicilar'] ?? []),
      ilanId:        d['ilanId']       as String? ?? '',
      ilanBaslik:    d['ilanBaslik']   as String? ?? '',
      ilanResimUrl:  d['ilanResimUrl'] as String? ?? '',
      ilanSahibiId:  d['ilanSahibiId'] as String? ?? '',
      ilanTip:       d['ilanTip']       as String? ?? 'istek',
      sonMesaj:      d['sonMesaj']     as String?,
      sonMesajZamani: (d['sonMesajZamani'] as Timestamp?)?.toDate(),
      sonAktiviteZamani: (d['sonAktiviteZamani'] as Timestamp?)?.toDate(),
      sonGondereId:  d['sonGondereId'] as String? ?? '',
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
      kullaniciAdlari: Map<String, String>.from(
        (d['kullaniciAdlari'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ?? {},
      ),
      islemDurumlari: Map<String, dynamic>.from(d['islemDurumlari'] ?? {}),
    );
  }

  factory SohbetModel.fromJson(Map<String, dynamic> json) =>
      _$SohbetModelFromJson(json);
}

extension SohbetModelX on SohbetModel {
  int okunmamisSayisi(String kullaniciId) =>
      okunmamis[kullaniciId] ?? 0;

  String karsiKullaniciId(String benimId) =>
      karsiTarafiBul(kullanicilar, benimId);

  String karsiKullaniciAdi(String benimId) {
    final karsiId = karsiKullaniciId(benimId);
    return kullaniciAdlari[karsiId] ?? '';
  }

  bool sabitMi(String kullaniciId) =>
      sabitlenmis[kullaniciId] ?? false;

  bool gizliMi(String kullaniciId) {
    final gizliDeger = gizli[kullaniciId];
    if (gizliDeger == null) return false;
    if (gizliDeger is bool) return gizliDeger;
    if (gizliDeger is Timestamp && sonMesajZamani != null) {
      return !sonMesajZamani!.isAfter(gizliDeger.toDate());
    }
    return false;
  }

  // islem_durumu_panel.dart'taki _baslik getter'ının kullandığı aynı
  // benimOnayim/karsiOnayi mantığı — tek kaynak burası, panel de liste
  // satırı da buradan okur.
  bool anlasmaOnerildi(String benimUid) {
    final karsiUid = karsiKullaniciId(benimUid);
    final benimOnayim = islemDurumlari['anlasildi_$benimUid'] == true;
    final karsiOnayi = karsiUid.isNotEmpty &&
        islemDurumlari['anlasildi_$karsiUid'] == true;
    return karsiOnayi && !benimOnayim;
  }
}