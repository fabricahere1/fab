// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teklif_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeklifModel {

 String get id; String get ilanId; String get ilanBaslik; String get ilanSahibiId; String get ilanSahibiAd; String get teklifVerenId; String get teklifVerenAd; double get miktar; double get ilanMiktar; TeklifDurum get durum; double? get karsiTeklifMiktar; DateTime? get olusturmaTarihi; DateTime? get guncellemeTarihi; String get olusumTipi; String get teslimDurumu; String get teslimatTipi; String get getirenTeslimBeyan; String get isteyenTeslimOnay; String get kargoSirketi; String get kargoTakipNo; DateTime? get teslimOnayTarihi; bool get isteyenDegerlendirdiMi; bool get getirenDegerlendirdiMi; DateTime? get degerlendirmeAcilmaTarihi;
/// Create a copy of TeklifModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeklifModelCopyWith<TeklifModel> get copyWith => _$TeklifModelCopyWithImpl<TeklifModel>(this as TeklifModel, _$identity);

  /// Serializes this TeklifModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeklifModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ilanId, ilanId) || other.ilanId == ilanId)&&(identical(other.ilanBaslik, ilanBaslik) || other.ilanBaslik == ilanBaslik)&&(identical(other.ilanSahibiId, ilanSahibiId) || other.ilanSahibiId == ilanSahibiId)&&(identical(other.ilanSahibiAd, ilanSahibiAd) || other.ilanSahibiAd == ilanSahibiAd)&&(identical(other.teklifVerenId, teklifVerenId) || other.teklifVerenId == teklifVerenId)&&(identical(other.teklifVerenAd, teklifVerenAd) || other.teklifVerenAd == teklifVerenAd)&&(identical(other.miktar, miktar) || other.miktar == miktar)&&(identical(other.ilanMiktar, ilanMiktar) || other.ilanMiktar == ilanMiktar)&&(identical(other.durum, durum) || other.durum == durum)&&(identical(other.karsiTeklifMiktar, karsiTeklifMiktar) || other.karsiTeklifMiktar == karsiTeklifMiktar)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.guncellemeTarihi, guncellemeTarihi) || other.guncellemeTarihi == guncellemeTarihi)&&(identical(other.olusumTipi, olusumTipi) || other.olusumTipi == olusumTipi)&&(identical(other.teslimDurumu, teslimDurumu) || other.teslimDurumu == teslimDurumu)&&(identical(other.teslimatTipi, teslimatTipi) || other.teslimatTipi == teslimatTipi)&&(identical(other.getirenTeslimBeyan, getirenTeslimBeyan) || other.getirenTeslimBeyan == getirenTeslimBeyan)&&(identical(other.isteyenTeslimOnay, isteyenTeslimOnay) || other.isteyenTeslimOnay == isteyenTeslimOnay)&&(identical(other.kargoSirketi, kargoSirketi) || other.kargoSirketi == kargoSirketi)&&(identical(other.kargoTakipNo, kargoTakipNo) || other.kargoTakipNo == kargoTakipNo)&&(identical(other.teslimOnayTarihi, teslimOnayTarihi) || other.teslimOnayTarihi == teslimOnayTarihi)&&(identical(other.isteyenDegerlendirdiMi, isteyenDegerlendirdiMi) || other.isteyenDegerlendirdiMi == isteyenDegerlendirdiMi)&&(identical(other.getirenDegerlendirdiMi, getirenDegerlendirdiMi) || other.getirenDegerlendirdiMi == getirenDegerlendirdiMi)&&(identical(other.degerlendirmeAcilmaTarihi, degerlendirmeAcilmaTarihi) || other.degerlendirmeAcilmaTarihi == degerlendirmeAcilmaTarihi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ilanId,ilanBaslik,ilanSahibiId,ilanSahibiAd,teklifVerenId,teklifVerenAd,miktar,ilanMiktar,durum,karsiTeklifMiktar,olusturmaTarihi,guncellemeTarihi,olusumTipi,teslimDurumu,teslimatTipi,getirenTeslimBeyan,isteyenTeslimOnay,kargoSirketi,kargoTakipNo,teslimOnayTarihi,isteyenDegerlendirdiMi,getirenDegerlendirdiMi,degerlendirmeAcilmaTarihi]);

@override
String toString() {
  return 'TeklifModel(id: $id, ilanId: $ilanId, ilanBaslik: $ilanBaslik, ilanSahibiId: $ilanSahibiId, ilanSahibiAd: $ilanSahibiAd, teklifVerenId: $teklifVerenId, teklifVerenAd: $teklifVerenAd, miktar: $miktar, ilanMiktar: $ilanMiktar, durum: $durum, karsiTeklifMiktar: $karsiTeklifMiktar, olusturmaTarihi: $olusturmaTarihi, guncellemeTarihi: $guncellemeTarihi, olusumTipi: $olusumTipi, teslimDurumu: $teslimDurumu, teslimatTipi: $teslimatTipi, getirenTeslimBeyan: $getirenTeslimBeyan, isteyenTeslimOnay: $isteyenTeslimOnay, kargoSirketi: $kargoSirketi, kargoTakipNo: $kargoTakipNo, teslimOnayTarihi: $teslimOnayTarihi, isteyenDegerlendirdiMi: $isteyenDegerlendirdiMi, getirenDegerlendirdiMi: $getirenDegerlendirdiMi, degerlendirmeAcilmaTarihi: $degerlendirmeAcilmaTarihi)';
}


}

/// @nodoc
abstract mixin class $TeklifModelCopyWith<$Res>  {
  factory $TeklifModelCopyWith(TeklifModel value, $Res Function(TeklifModel) _then) = _$TeklifModelCopyWithImpl;
@useResult
$Res call({
 String id, String ilanId, String ilanBaslik, String ilanSahibiId, String ilanSahibiAd, String teklifVerenId, String teklifVerenAd, double miktar, double ilanMiktar, TeklifDurum durum, double? karsiTeklifMiktar, DateTime? olusturmaTarihi, DateTime? guncellemeTarihi, String olusumTipi, String teslimDurumu, String teslimatTipi, String getirenTeslimBeyan, String isteyenTeslimOnay, String kargoSirketi, String kargoTakipNo, DateTime? teslimOnayTarihi, bool isteyenDegerlendirdiMi, bool getirenDegerlendirdiMi, DateTime? degerlendirmeAcilmaTarihi
});




}
/// @nodoc
class _$TeklifModelCopyWithImpl<$Res>
    implements $TeklifModelCopyWith<$Res> {
  _$TeklifModelCopyWithImpl(this._self, this._then);

  final TeklifModel _self;
  final $Res Function(TeklifModel) _then;

/// Create a copy of TeklifModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ilanId = null,Object? ilanBaslik = null,Object? ilanSahibiId = null,Object? ilanSahibiAd = null,Object? teklifVerenId = null,Object? teklifVerenAd = null,Object? miktar = null,Object? ilanMiktar = null,Object? durum = null,Object? karsiTeklifMiktar = freezed,Object? olusturmaTarihi = freezed,Object? guncellemeTarihi = freezed,Object? olusumTipi = null,Object? teslimDurumu = null,Object? teslimatTipi = null,Object? getirenTeslimBeyan = null,Object? isteyenTeslimOnay = null,Object? kargoSirketi = null,Object? kargoTakipNo = null,Object? teslimOnayTarihi = freezed,Object? isteyenDegerlendirdiMi = null,Object? getirenDegerlendirdiMi = null,Object? degerlendirmeAcilmaTarihi = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ilanId: null == ilanId ? _self.ilanId : ilanId // ignore: cast_nullable_to_non_nullable
as String,ilanBaslik: null == ilanBaslik ? _self.ilanBaslik : ilanBaslik // ignore: cast_nullable_to_non_nullable
as String,ilanSahibiId: null == ilanSahibiId ? _self.ilanSahibiId : ilanSahibiId // ignore: cast_nullable_to_non_nullable
as String,ilanSahibiAd: null == ilanSahibiAd ? _self.ilanSahibiAd : ilanSahibiAd // ignore: cast_nullable_to_non_nullable
as String,teklifVerenId: null == teklifVerenId ? _self.teklifVerenId : teklifVerenId // ignore: cast_nullable_to_non_nullable
as String,teklifVerenAd: null == teklifVerenAd ? _self.teklifVerenAd : teklifVerenAd // ignore: cast_nullable_to_non_nullable
as String,miktar: null == miktar ? _self.miktar : miktar // ignore: cast_nullable_to_non_nullable
as double,ilanMiktar: null == ilanMiktar ? _self.ilanMiktar : ilanMiktar // ignore: cast_nullable_to_non_nullable
as double,durum: null == durum ? _self.durum : durum // ignore: cast_nullable_to_non_nullable
as TeklifDurum,karsiTeklifMiktar: freezed == karsiTeklifMiktar ? _self.karsiTeklifMiktar : karsiTeklifMiktar // ignore: cast_nullable_to_non_nullable
as double?,olusturmaTarihi: freezed == olusturmaTarihi ? _self.olusturmaTarihi : olusturmaTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,guncellemeTarihi: freezed == guncellemeTarihi ? _self.guncellemeTarihi : guncellemeTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,olusumTipi: null == olusumTipi ? _self.olusumTipi : olusumTipi // ignore: cast_nullable_to_non_nullable
as String,teslimDurumu: null == teslimDurumu ? _self.teslimDurumu : teslimDurumu // ignore: cast_nullable_to_non_nullable
as String,teslimatTipi: null == teslimatTipi ? _self.teslimatTipi : teslimatTipi // ignore: cast_nullable_to_non_nullable
as String,getirenTeslimBeyan: null == getirenTeslimBeyan ? _self.getirenTeslimBeyan : getirenTeslimBeyan // ignore: cast_nullable_to_non_nullable
as String,isteyenTeslimOnay: null == isteyenTeslimOnay ? _self.isteyenTeslimOnay : isteyenTeslimOnay // ignore: cast_nullable_to_non_nullable
as String,kargoSirketi: null == kargoSirketi ? _self.kargoSirketi : kargoSirketi // ignore: cast_nullable_to_non_nullable
as String,kargoTakipNo: null == kargoTakipNo ? _self.kargoTakipNo : kargoTakipNo // ignore: cast_nullable_to_non_nullable
as String,teslimOnayTarihi: freezed == teslimOnayTarihi ? _self.teslimOnayTarihi : teslimOnayTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,isteyenDegerlendirdiMi: null == isteyenDegerlendirdiMi ? _self.isteyenDegerlendirdiMi : isteyenDegerlendirdiMi // ignore: cast_nullable_to_non_nullable
as bool,getirenDegerlendirdiMi: null == getirenDegerlendirdiMi ? _self.getirenDegerlendirdiMi : getirenDegerlendirdiMi // ignore: cast_nullable_to_non_nullable
as bool,degerlendirmeAcilmaTarihi: freezed == degerlendirmeAcilmaTarihi ? _self.degerlendirmeAcilmaTarihi : degerlendirmeAcilmaTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TeklifModel].
extension TeklifModelPatterns on TeklifModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeklifModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeklifModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeklifModel value)  $default,){
final _that = this;
switch (_that) {
case _TeklifModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeklifModel value)?  $default,){
final _that = this;
switch (_that) {
case _TeklifModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ilanId,  String ilanBaslik,  String ilanSahibiId,  String ilanSahibiAd,  String teklifVerenId,  String teklifVerenAd,  double miktar,  double ilanMiktar,  TeklifDurum durum,  double? karsiTeklifMiktar,  DateTime? olusturmaTarihi,  DateTime? guncellemeTarihi,  String olusumTipi,  String teslimDurumu,  String teslimatTipi,  String getirenTeslimBeyan,  String isteyenTeslimOnay,  String kargoSirketi,  String kargoTakipNo,  DateTime? teslimOnayTarihi,  bool isteyenDegerlendirdiMi,  bool getirenDegerlendirdiMi,  DateTime? degerlendirmeAcilmaTarihi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeklifModel() when $default != null:
return $default(_that.id,_that.ilanId,_that.ilanBaslik,_that.ilanSahibiId,_that.ilanSahibiAd,_that.teklifVerenId,_that.teklifVerenAd,_that.miktar,_that.ilanMiktar,_that.durum,_that.karsiTeklifMiktar,_that.olusturmaTarihi,_that.guncellemeTarihi,_that.olusumTipi,_that.teslimDurumu,_that.teslimatTipi,_that.getirenTeslimBeyan,_that.isteyenTeslimOnay,_that.kargoSirketi,_that.kargoTakipNo,_that.teslimOnayTarihi,_that.isteyenDegerlendirdiMi,_that.getirenDegerlendirdiMi,_that.degerlendirmeAcilmaTarihi);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ilanId,  String ilanBaslik,  String ilanSahibiId,  String ilanSahibiAd,  String teklifVerenId,  String teklifVerenAd,  double miktar,  double ilanMiktar,  TeklifDurum durum,  double? karsiTeklifMiktar,  DateTime? olusturmaTarihi,  DateTime? guncellemeTarihi,  String olusumTipi,  String teslimDurumu,  String teslimatTipi,  String getirenTeslimBeyan,  String isteyenTeslimOnay,  String kargoSirketi,  String kargoTakipNo,  DateTime? teslimOnayTarihi,  bool isteyenDegerlendirdiMi,  bool getirenDegerlendirdiMi,  DateTime? degerlendirmeAcilmaTarihi)  $default,) {final _that = this;
switch (_that) {
case _TeklifModel():
return $default(_that.id,_that.ilanId,_that.ilanBaslik,_that.ilanSahibiId,_that.ilanSahibiAd,_that.teklifVerenId,_that.teklifVerenAd,_that.miktar,_that.ilanMiktar,_that.durum,_that.karsiTeklifMiktar,_that.olusturmaTarihi,_that.guncellemeTarihi,_that.olusumTipi,_that.teslimDurumu,_that.teslimatTipi,_that.getirenTeslimBeyan,_that.isteyenTeslimOnay,_that.kargoSirketi,_that.kargoTakipNo,_that.teslimOnayTarihi,_that.isteyenDegerlendirdiMi,_that.getirenDegerlendirdiMi,_that.degerlendirmeAcilmaTarihi);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ilanId,  String ilanBaslik,  String ilanSahibiId,  String ilanSahibiAd,  String teklifVerenId,  String teklifVerenAd,  double miktar,  double ilanMiktar,  TeklifDurum durum,  double? karsiTeklifMiktar,  DateTime? olusturmaTarihi,  DateTime? guncellemeTarihi,  String olusumTipi,  String teslimDurumu,  String teslimatTipi,  String getirenTeslimBeyan,  String isteyenTeslimOnay,  String kargoSirketi,  String kargoTakipNo,  DateTime? teslimOnayTarihi,  bool isteyenDegerlendirdiMi,  bool getirenDegerlendirdiMi,  DateTime? degerlendirmeAcilmaTarihi)?  $default,) {final _that = this;
switch (_that) {
case _TeklifModel() when $default != null:
return $default(_that.id,_that.ilanId,_that.ilanBaslik,_that.ilanSahibiId,_that.ilanSahibiAd,_that.teklifVerenId,_that.teklifVerenAd,_that.miktar,_that.ilanMiktar,_that.durum,_that.karsiTeklifMiktar,_that.olusturmaTarihi,_that.guncellemeTarihi,_that.olusumTipi,_that.teslimDurumu,_that.teslimatTipi,_that.getirenTeslimBeyan,_that.isteyenTeslimOnay,_that.kargoSirketi,_that.kargoTakipNo,_that.teslimOnayTarihi,_that.isteyenDegerlendirdiMi,_that.getirenDegerlendirdiMi,_that.degerlendirmeAcilmaTarihi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeklifModel extends TeklifModel {
  const _TeklifModel({required this.id, required this.ilanId, required this.ilanBaslik, required this.ilanSahibiId, required this.ilanSahibiAd, required this.teklifVerenId, required this.teklifVerenAd, required this.miktar, required this.ilanMiktar, this.durum = TeklifDurum.bekliyor, this.karsiTeklifMiktar, this.olusturmaTarihi, this.guncellemeTarihi, this.olusumTipi = OlusumTipi.teklif, this.teslimDurumu = 'beklemede', this.teslimatTipi = 'beklemede', this.getirenTeslimBeyan = 'yok', this.isteyenTeslimOnay = 'yok', this.kargoSirketi = '', this.kargoTakipNo = '', this.teslimOnayTarihi, this.isteyenDegerlendirdiMi = false, this.getirenDegerlendirdiMi = false, this.degerlendirmeAcilmaTarihi}): super._();
  factory _TeklifModel.fromJson(Map<String, dynamic> json) => _$TeklifModelFromJson(json);

@override final  String id;
@override final  String ilanId;
@override final  String ilanBaslik;
@override final  String ilanSahibiId;
@override final  String ilanSahibiAd;
@override final  String teklifVerenId;
@override final  String teklifVerenAd;
@override final  double miktar;
@override final  double ilanMiktar;
@override@JsonKey() final  TeklifDurum durum;
@override final  double? karsiTeklifMiktar;
@override final  DateTime? olusturmaTarihi;
@override final  DateTime? guncellemeTarihi;
@override@JsonKey() final  String olusumTipi;
@override@JsonKey() final  String teslimDurumu;
@override@JsonKey() final  String teslimatTipi;
@override@JsonKey() final  String getirenTeslimBeyan;
@override@JsonKey() final  String isteyenTeslimOnay;
@override@JsonKey() final  String kargoSirketi;
@override@JsonKey() final  String kargoTakipNo;
@override final  DateTime? teslimOnayTarihi;
@override@JsonKey() final  bool isteyenDegerlendirdiMi;
@override@JsonKey() final  bool getirenDegerlendirdiMi;
@override final  DateTime? degerlendirmeAcilmaTarihi;

/// Create a copy of TeklifModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeklifModelCopyWith<_TeklifModel> get copyWith => __$TeklifModelCopyWithImpl<_TeklifModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeklifModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeklifModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ilanId, ilanId) || other.ilanId == ilanId)&&(identical(other.ilanBaslik, ilanBaslik) || other.ilanBaslik == ilanBaslik)&&(identical(other.ilanSahibiId, ilanSahibiId) || other.ilanSahibiId == ilanSahibiId)&&(identical(other.ilanSahibiAd, ilanSahibiAd) || other.ilanSahibiAd == ilanSahibiAd)&&(identical(other.teklifVerenId, teklifVerenId) || other.teklifVerenId == teklifVerenId)&&(identical(other.teklifVerenAd, teklifVerenAd) || other.teklifVerenAd == teklifVerenAd)&&(identical(other.miktar, miktar) || other.miktar == miktar)&&(identical(other.ilanMiktar, ilanMiktar) || other.ilanMiktar == ilanMiktar)&&(identical(other.durum, durum) || other.durum == durum)&&(identical(other.karsiTeklifMiktar, karsiTeklifMiktar) || other.karsiTeklifMiktar == karsiTeklifMiktar)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.guncellemeTarihi, guncellemeTarihi) || other.guncellemeTarihi == guncellemeTarihi)&&(identical(other.olusumTipi, olusumTipi) || other.olusumTipi == olusumTipi)&&(identical(other.teslimDurumu, teslimDurumu) || other.teslimDurumu == teslimDurumu)&&(identical(other.teslimatTipi, teslimatTipi) || other.teslimatTipi == teslimatTipi)&&(identical(other.getirenTeslimBeyan, getirenTeslimBeyan) || other.getirenTeslimBeyan == getirenTeslimBeyan)&&(identical(other.isteyenTeslimOnay, isteyenTeslimOnay) || other.isteyenTeslimOnay == isteyenTeslimOnay)&&(identical(other.kargoSirketi, kargoSirketi) || other.kargoSirketi == kargoSirketi)&&(identical(other.kargoTakipNo, kargoTakipNo) || other.kargoTakipNo == kargoTakipNo)&&(identical(other.teslimOnayTarihi, teslimOnayTarihi) || other.teslimOnayTarihi == teslimOnayTarihi)&&(identical(other.isteyenDegerlendirdiMi, isteyenDegerlendirdiMi) || other.isteyenDegerlendirdiMi == isteyenDegerlendirdiMi)&&(identical(other.getirenDegerlendirdiMi, getirenDegerlendirdiMi) || other.getirenDegerlendirdiMi == getirenDegerlendirdiMi)&&(identical(other.degerlendirmeAcilmaTarihi, degerlendirmeAcilmaTarihi) || other.degerlendirmeAcilmaTarihi == degerlendirmeAcilmaTarihi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ilanId,ilanBaslik,ilanSahibiId,ilanSahibiAd,teklifVerenId,teklifVerenAd,miktar,ilanMiktar,durum,karsiTeklifMiktar,olusturmaTarihi,guncellemeTarihi,olusumTipi,teslimDurumu,teslimatTipi,getirenTeslimBeyan,isteyenTeslimOnay,kargoSirketi,kargoTakipNo,teslimOnayTarihi,isteyenDegerlendirdiMi,getirenDegerlendirdiMi,degerlendirmeAcilmaTarihi]);

@override
String toString() {
  return 'TeklifModel(id: $id, ilanId: $ilanId, ilanBaslik: $ilanBaslik, ilanSahibiId: $ilanSahibiId, ilanSahibiAd: $ilanSahibiAd, teklifVerenId: $teklifVerenId, teklifVerenAd: $teklifVerenAd, miktar: $miktar, ilanMiktar: $ilanMiktar, durum: $durum, karsiTeklifMiktar: $karsiTeklifMiktar, olusturmaTarihi: $olusturmaTarihi, guncellemeTarihi: $guncellemeTarihi, olusumTipi: $olusumTipi, teslimDurumu: $teslimDurumu, teslimatTipi: $teslimatTipi, getirenTeslimBeyan: $getirenTeslimBeyan, isteyenTeslimOnay: $isteyenTeslimOnay, kargoSirketi: $kargoSirketi, kargoTakipNo: $kargoTakipNo, teslimOnayTarihi: $teslimOnayTarihi, isteyenDegerlendirdiMi: $isteyenDegerlendirdiMi, getirenDegerlendirdiMi: $getirenDegerlendirdiMi, degerlendirmeAcilmaTarihi: $degerlendirmeAcilmaTarihi)';
}


}

/// @nodoc
abstract mixin class _$TeklifModelCopyWith<$Res> implements $TeklifModelCopyWith<$Res> {
  factory _$TeklifModelCopyWith(_TeklifModel value, $Res Function(_TeklifModel) _then) = __$TeklifModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String ilanId, String ilanBaslik, String ilanSahibiId, String ilanSahibiAd, String teklifVerenId, String teklifVerenAd, double miktar, double ilanMiktar, TeklifDurum durum, double? karsiTeklifMiktar, DateTime? olusturmaTarihi, DateTime? guncellemeTarihi, String olusumTipi, String teslimDurumu, String teslimatTipi, String getirenTeslimBeyan, String isteyenTeslimOnay, String kargoSirketi, String kargoTakipNo, DateTime? teslimOnayTarihi, bool isteyenDegerlendirdiMi, bool getirenDegerlendirdiMi, DateTime? degerlendirmeAcilmaTarihi
});




}
/// @nodoc
class __$TeklifModelCopyWithImpl<$Res>
    implements _$TeklifModelCopyWith<$Res> {
  __$TeklifModelCopyWithImpl(this._self, this._then);

  final _TeklifModel _self;
  final $Res Function(_TeklifModel) _then;

/// Create a copy of TeklifModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ilanId = null,Object? ilanBaslik = null,Object? ilanSahibiId = null,Object? ilanSahibiAd = null,Object? teklifVerenId = null,Object? teklifVerenAd = null,Object? miktar = null,Object? ilanMiktar = null,Object? durum = null,Object? karsiTeklifMiktar = freezed,Object? olusturmaTarihi = freezed,Object? guncellemeTarihi = freezed,Object? olusumTipi = null,Object? teslimDurumu = null,Object? teslimatTipi = null,Object? getirenTeslimBeyan = null,Object? isteyenTeslimOnay = null,Object? kargoSirketi = null,Object? kargoTakipNo = null,Object? teslimOnayTarihi = freezed,Object? isteyenDegerlendirdiMi = null,Object? getirenDegerlendirdiMi = null,Object? degerlendirmeAcilmaTarihi = freezed,}) {
  return _then(_TeklifModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ilanId: null == ilanId ? _self.ilanId : ilanId // ignore: cast_nullable_to_non_nullable
as String,ilanBaslik: null == ilanBaslik ? _self.ilanBaslik : ilanBaslik // ignore: cast_nullable_to_non_nullable
as String,ilanSahibiId: null == ilanSahibiId ? _self.ilanSahibiId : ilanSahibiId // ignore: cast_nullable_to_non_nullable
as String,ilanSahibiAd: null == ilanSahibiAd ? _self.ilanSahibiAd : ilanSahibiAd // ignore: cast_nullable_to_non_nullable
as String,teklifVerenId: null == teklifVerenId ? _self.teklifVerenId : teklifVerenId // ignore: cast_nullable_to_non_nullable
as String,teklifVerenAd: null == teklifVerenAd ? _self.teklifVerenAd : teklifVerenAd // ignore: cast_nullable_to_non_nullable
as String,miktar: null == miktar ? _self.miktar : miktar // ignore: cast_nullable_to_non_nullable
as double,ilanMiktar: null == ilanMiktar ? _self.ilanMiktar : ilanMiktar // ignore: cast_nullable_to_non_nullable
as double,durum: null == durum ? _self.durum : durum // ignore: cast_nullable_to_non_nullable
as TeklifDurum,karsiTeklifMiktar: freezed == karsiTeklifMiktar ? _self.karsiTeklifMiktar : karsiTeklifMiktar // ignore: cast_nullable_to_non_nullable
as double?,olusturmaTarihi: freezed == olusturmaTarihi ? _self.olusturmaTarihi : olusturmaTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,guncellemeTarihi: freezed == guncellemeTarihi ? _self.guncellemeTarihi : guncellemeTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,olusumTipi: null == olusumTipi ? _self.olusumTipi : olusumTipi // ignore: cast_nullable_to_non_nullable
as String,teslimDurumu: null == teslimDurumu ? _self.teslimDurumu : teslimDurumu // ignore: cast_nullable_to_non_nullable
as String,teslimatTipi: null == teslimatTipi ? _self.teslimatTipi : teslimatTipi // ignore: cast_nullable_to_non_nullable
as String,getirenTeslimBeyan: null == getirenTeslimBeyan ? _self.getirenTeslimBeyan : getirenTeslimBeyan // ignore: cast_nullable_to_non_nullable
as String,isteyenTeslimOnay: null == isteyenTeslimOnay ? _self.isteyenTeslimOnay : isteyenTeslimOnay // ignore: cast_nullable_to_non_nullable
as String,kargoSirketi: null == kargoSirketi ? _self.kargoSirketi : kargoSirketi // ignore: cast_nullable_to_non_nullable
as String,kargoTakipNo: null == kargoTakipNo ? _self.kargoTakipNo : kargoTakipNo // ignore: cast_nullable_to_non_nullable
as String,teslimOnayTarihi: freezed == teslimOnayTarihi ? _self.teslimOnayTarihi : teslimOnayTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,isteyenDegerlendirdiMi: null == isteyenDegerlendirdiMi ? _self.isteyenDegerlendirdiMi : isteyenDegerlendirdiMi // ignore: cast_nullable_to_non_nullable
as bool,getirenDegerlendirdiMi: null == getirenDegerlendirdiMi ? _self.getirenDegerlendirdiMi : getirenDegerlendirdiMi // ignore: cast_nullable_to_non_nullable
as bool,degerlendirmeAcilmaTarihi: freezed == degerlendirmeAcilmaTarihi ? _self.degerlendirmeAcilmaTarihi : degerlendirmeAcilmaTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
