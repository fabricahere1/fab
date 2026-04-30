// cloud_firestore import YOK — domain katmanı Firebase'i tanımaz
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bildirim_model.freezed.dart';
part 'bildirim_model.g.dart';

enum BildirimTip { mesaj, ilan, sistem, teklif }

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

  // fromFirestore bildirim_repository.dart'ta _bildirimModelCevir — domain Firebase'i tanımaz

  factory BildirimModel.fromJson(Map<String, dynamic> json) =>
      _$BildirimModelFromJson(json);
}

BildirimTip bildirimTipFromString(String tip) {
  switch (tip) {
    case 'mesaj':  return BildirimTip.mesaj;
    case 'ilan':   return BildirimTip.ilan;
    case 'teklif': return BildirimTip.teklif;
    default:       return BildirimTip.sistem;
  }
}
