// cloud_firestore import YOK — domain katmanı Firebase'i tanımaz
import 'package:freezed_annotation/freezed_annotation.dart';

part 'teklif_model.freezed.dart';
part 'teklif_model.g.dart';

enum TeklifDurum { bekliyor, kabul, reddedildi, karsiTeklif }

extension TeklifDurumX on TeklifDurum {
  String get label {
    switch (this) {
      case TeklifDurum.bekliyor:    return 'Bekliyor';
      case TeklifDurum.kabul:       return 'Kabul Edildi';
      case TeklifDurum.reddedildi:  return 'Reddedildi';
      case TeklifDurum.karsiTeklif: return 'Karşı Teklif';
    }
  }

  String get firestoreKey {
    switch (this) {
      case TeklifDurum.bekliyor:    return 'bekliyor';
      case TeklifDurum.kabul:       return 'kabul';
      case TeklifDurum.reddedildi:  return 'reddedildi';
      case TeklifDurum.karsiTeklif: return 'karsi_teklif';
    }
  }

  static TeklifDurum fromString(String v) {
    switch (v) {
      case 'kabul':        return TeklifDurum.kabul;
      case 'reddedildi':   return TeklifDurum.reddedildi;
      case 'karsi_teklif': return TeklifDurum.karsiTeklif;
      default:             return TeklifDurum.bekliyor;
    }
  }
}

class OlusumTipi {
  static const teklif          = 'teklif';
  static const sohbetAnlasmasi = 'sohbet_anlasmasi';
}

@freezed
abstract class TeklifModel with _$TeklifModel {
  const TeklifModel._();

  const factory TeklifModel({
    required String id,
    required String ilanId,
    required String ilanBaslik,
    required String ilanSahibiId,
    required String ilanSahibiAd,
    required String teklifVerenId,
    required String teklifVerenAd,
    required double miktar,
    required double ilanMiktar,
    @Default(TeklifDurum.bekliyor) TeklifDurum durum,
    double? karsiTeklifMiktar,
    DateTime? olusturmaTarihi,
    DateTime? guncellemeTarihi,
    @Default(OlusumTipi.teklif) String olusumTipi,
    @Default('beklemede') String teslimDurumu,
    @Default('beklemede') String teslimatTipi,
    @Default('yok') String getirenTeslimBeyan,
    @Default('yok') String isteyenTeslimOnay,
    @Default('') String kargoSirketi,
    @Default('') String kargoTakipNo,
    DateTime? teslimOnayTarihi,
    @Default(false) bool isteyenDegerlendirdiMi,
    @Default(false) bool getirenDegerlendirdiMi,
    DateTime? degerlendirmeAcilmaTarihi,
  }) = _TeklifModel;

  bool get teslimEdildiMi     => teslimDurumu == 'teslim_edildi';
  bool get kargoIleGonderildi => teslimatTipi == 'kargo';
  bool get eldenTeslimEdildi  => teslimatTipi == 'elden';
  bool get ikisiDeDegerlendirdi =>
      isteyenDegerlendirdiMi && getirenDegerlendirdiMi;

  bool get degerlendirmeAcikMi {
    if (degerlendirmeAcilmaTarihi == null) return false;
    return DateTime.now().isAfter(degerlendirmeAcilmaTarihi!);
  }

  Duration? get degerlendirmeKalanSure {
    if (degerlendirmeAcilmaTarihi == null) return null;
    final kalan = degerlendirmeAcilmaTarihi!.difference(DateTime.now());
    return kalan.isNegative ? Duration.zero : kalan;
  }

  // fromFirestore teklif_repository.dart'ta _teklifModelCevir — domain Firebase'i tanımaz

  factory TeklifModel.fromJson(Map<String, dynamic> json) =>
      _$TeklifModelFromJson(json);
}
