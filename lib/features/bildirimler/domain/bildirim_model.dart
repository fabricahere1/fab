import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
 
part 'bildirim_model.freezed.dart';
part 'bildirim_model.g.dart';
 
enum BildirimTip { mesaj, ilan, sistem, teklif } // ← teklif eklendi
 
@freezed
abstract class BildirimModel with _$BildirimModel {
  const factory BildirimModel({
    required String id,
    required String kullaniciId,
    @Default(BildirimTip.sistem) BildirimTip tip,
    @Default('') String baslik,
    @Default('') String icerik,
    @Default(false) bool okundu,
    DateTime? tarih,
    @Default('') String hedefId,
    @Default('') String gondereId,
    @Default('') String gondereAd,
  }) = _BildirimModel;
 
  factory BildirimModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BildirimModel(
      id: doc.id,
      kullaniciId: d['kullaniciId'] as String? ?? '',
      tip: _tipFromString(d['tip'] as String? ?? 'sistem'),
      baslik: d['baslik'] as String? ?? '',
      icerik: d['icerik'] as String? ?? '',
      okundu: d['okundu'] as bool? ?? false,
      tarih: (d['tarih'] as Timestamp?)?.toDate(),
      hedefId: d['hedefId'] as String? ?? '',
      gondereId: d['gondereId'] as String? ?? '',
      gondereAd: d['gondereAd'] as String? ?? '',
    );
  }
 
  factory BildirimModel.fromJson(Map<String, dynamic> json) =>
      _$BildirimModelFromJson(json);
}
 
BildirimTip _tipFromString(String tip) {
  switch (tip) {
    case 'mesaj':   return BildirimTip.mesaj;
    case 'ilan':    return BildirimTip.ilan;
    case 'teklif':  return BildirimTip.teklif; // ← eklendi
    default:        return BildirimTip.sistem;
  }
}
 
extension BildirimModelX on BildirimModel {
  Map<String, dynamic> toFirestore() => {
    'kullaniciId': kullaniciId,
    'tip':         tip.name,
    'baslik':      baslik,
    'icerik':      icerik,
    'okundu':      okundu,
    'tarih':       tarih != null
        ? Timestamp.fromDate(tarih!)
        : FieldValue.serverTimestamp(),
    'hedefId':    hedefId,
    'gondereId':  gondereId,
    'gondereAd':  gondereAd,
  };
}