// lib/features/teklifler/domain/teklif_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'teklif_model.freezed.dart';
part 'teklif_model.g.dart';

// ── Durum enum ────────────────────────────────────────────────────────────────

enum TeklifDurum {
  bekliyor,
  kabul,
  reddedildi,
  karsiTeklif,
}

extension TeklifDurumX on TeklifDurum {
  String get label {
    switch (this) {
      case TeklifDurum.bekliyor:     return 'Bekliyor';
      case TeklifDurum.kabul:        return 'Kabul Edildi';
      case TeklifDurum.reddedildi:   return 'Reddedildi';
      case TeklifDurum.karsiTeklif:  return 'Karşı Teklif';
    }
  }

  String get firestoreKey {
    switch (this) {
      case TeklifDurum.bekliyor:     return 'bekliyor';
      case TeklifDurum.kabul:        return 'kabul';
      case TeklifDurum.reddedildi:   return 'reddedildi';
      case TeklifDurum.karsiTeklif:  return 'karsi_teklif';
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

// ── Model ─────────────────────────────────────────────────────────────────────

@freezed
abstract class TeklifModel with _$TeklifModel {
  const factory TeklifModel({
    required String id,
    required String ilanId,
    required String ilanBaslik,
    required String ilanSahibiId,
    required String ilanSahibiAd,
    required String teklifVerenId,
    required String teklifVerenAd,
    required double miktar,           // kullanıcının teklifi
    required double ilanMiktar,       // ilandaki orijinal fiyat
    @Default(TeklifDurum.bekliyor) TeklifDurum durum,
    double? karsiTeklifMiktar,        // ilan sahibinin karşı teklifi
    DateTime? olusturmaTarihi,
    DateTime? guncellemeTarihi,
  }) = _TeklifModel;

  factory TeklifModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeklifModel(
      id:               doc.id,
      ilanId:           d['ilanId']         as String? ?? '',
      ilanBaslik:       d['ilanBaslik']      as String? ?? '',
      ilanSahibiId:     d['ilanSahibiId']    as String? ?? '',
      ilanSahibiAd:     d['ilanSahibiAd']    as String? ?? '',
      teklifVerenId:    d['teklifVerenId']   as String? ?? '',
      teklifVerenAd:    d['teklifVerenAd']   as String? ?? '',
      miktar:           (d['miktar']         as num?)?.toDouble() ?? 0,
      ilanMiktar:       (d['ilanMiktar']     as num?)?.toDouble() ?? 0,
      durum:            TeklifDurumX.fromString(d['durum'] as String? ?? ''),
      karsiTeklifMiktar:(d['karsiTeklifMiktar'] as num?)?.toDouble(),
      olusturmaTarihi:  (d['olusturmaTarihi'] as Timestamp?)?.toDate(),
      guncellemeTarihi: (d['guncellemeTarihi'] as Timestamp?)?.toDate(),
    );
  }

  factory TeklifModel.fromJson(Map<String, dynamic> json) =>
      _$TeklifModelFromJson(json);
}