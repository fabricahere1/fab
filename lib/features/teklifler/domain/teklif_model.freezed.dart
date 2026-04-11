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

 String get id; String get ilanId; String get ilanBaslik; String get ilanSahibiId; String get ilanSahibiAd; String get teklifVerenId; String get teklifVerenAd; double get miktar;// kullanıcının teklifi
 double get ilanMiktar;// ilandaki orijinal fiyat
 TeklifDurum get durum; double? get karsiTeklifMiktar;// ilan sahibinin karşı teklifi
 DateTime? get olusturmaTarihi; DateTime? get guncellemeTarihi;
/// Create a copy of TeklifModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeklifModelCopyWith<TeklifModel> get copyWith => _$TeklifModelCopyWithImpl<TeklifModel>(this as TeklifModel, _$identity);

  /// Serializes this TeklifModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeklifModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ilanId, ilanId) || other.ilanId == ilanId)&&(identical(other.ilanBaslik, ilanBaslik) || other.ilanBaslik == ilanBaslik)&&(identical(other.ilanSahibiId, ilanSahibiId) || other.ilanSahibiId == ilanSahibiId)&&(identical(other.ilanSahibiAd, ilanSahibiAd) || other.ilanSahibiAd == ilanSahibiAd)&&(identical(other.teklifVerenId, teklifVerenId) || other.teklifVerenId == teklifVerenId)&&(identical(other.teklifVerenAd, teklifVerenAd) || other.teklifVerenAd == teklifVerenAd)&&(identical(other.miktar, miktar) || other.miktar == miktar)&&(identical(other.ilanMiktar, ilanMiktar) || other.ilanMiktar == ilanMiktar)&&(identical(other.durum, durum) || other.durum == durum)&&(identical(other.karsiTeklifMiktar, karsiTeklifMiktar) || other.karsiTeklifMiktar == karsiTeklifMiktar)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.guncellemeTarihi, guncellemeTarihi) || other.guncellemeTarihi == guncellemeTarihi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ilanId,ilanBaslik,ilanSahibiId,ilanSahibiAd,teklifVerenId,teklifVerenAd,miktar,ilanMiktar,durum,karsiTeklifMiktar,olusturmaTarihi,guncellemeTarihi);

@override
String toString() {
  return 'TeklifModel(id: $id, ilanId: $ilanId, ilanBaslik: $ilanBaslik, ilanSahibiId: $ilanSahibiId, ilanSahibiAd: $ilanSahibiAd, teklifVerenId: $teklifVerenId, teklifVerenAd: $teklifVerenAd, miktar: $miktar, ilanMiktar: $ilanMiktar, durum: $durum, karsiTeklifMiktar: $karsiTeklifMiktar, olusturmaTarihi: $olusturmaTarihi, guncellemeTarihi: $guncellemeTarihi)';
}


}

/// @nodoc
abstract mixin class $TeklifModelCopyWith<$Res>  {
  factory $TeklifModelCopyWith(TeklifModel value, $Res Function(TeklifModel) _then) = _$TeklifModelCopyWithImpl;
@useResult
$Res call({
 String id, String ilanId, String ilanBaslik, String ilanSahibiId, String ilanSahibiAd, String teklifVerenId, String teklifVerenAd, double miktar, double ilanMiktar, TeklifDurum durum, double? karsiTeklifMiktar, DateTime? olusturmaTarihi, DateTime? guncellemeTarihi
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ilanId = null,Object? ilanBaslik = null,Object? ilanSahibiId = null,Object? ilanSahibiAd = null,Object? teklifVerenId = null,Object? teklifVerenAd = null,Object? miktar = null,Object? ilanMiktar = null,Object? durum = null,Object? karsiTeklifMiktar = freezed,Object? olusturmaTarihi = freezed,Object? guncellemeTarihi = freezed,}) {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ilanId,  String ilanBaslik,  String ilanSahibiId,  String ilanSahibiAd,  String teklifVerenId,  String teklifVerenAd,  double miktar,  double ilanMiktar,  TeklifDurum durum,  double? karsiTeklifMiktar,  DateTime? olusturmaTarihi,  DateTime? guncellemeTarihi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeklifModel() when $default != null:
return $default(_that.id,_that.ilanId,_that.ilanBaslik,_that.ilanSahibiId,_that.ilanSahibiAd,_that.teklifVerenId,_that.teklifVerenAd,_that.miktar,_that.ilanMiktar,_that.durum,_that.karsiTeklifMiktar,_that.olusturmaTarihi,_that.guncellemeTarihi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ilanId,  String ilanBaslik,  String ilanSahibiId,  String ilanSahibiAd,  String teklifVerenId,  String teklifVerenAd,  double miktar,  double ilanMiktar,  TeklifDurum durum,  double? karsiTeklifMiktar,  DateTime? olusturmaTarihi,  DateTime? guncellemeTarihi)  $default,) {final _that = this;
switch (_that) {
case _TeklifModel():
return $default(_that.id,_that.ilanId,_that.ilanBaslik,_that.ilanSahibiId,_that.ilanSahibiAd,_that.teklifVerenId,_that.teklifVerenAd,_that.miktar,_that.ilanMiktar,_that.durum,_that.karsiTeklifMiktar,_that.olusturmaTarihi,_that.guncellemeTarihi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ilanId,  String ilanBaslik,  String ilanSahibiId,  String ilanSahibiAd,  String teklifVerenId,  String teklifVerenAd,  double miktar,  double ilanMiktar,  TeklifDurum durum,  double? karsiTeklifMiktar,  DateTime? olusturmaTarihi,  DateTime? guncellemeTarihi)?  $default,) {final _that = this;
switch (_that) {
case _TeklifModel() when $default != null:
return $default(_that.id,_that.ilanId,_that.ilanBaslik,_that.ilanSahibiId,_that.ilanSahibiAd,_that.teklifVerenId,_that.teklifVerenAd,_that.miktar,_that.ilanMiktar,_that.durum,_that.karsiTeklifMiktar,_that.olusturmaTarihi,_that.guncellemeTarihi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeklifModel implements TeklifModel {
  const _TeklifModel({required this.id, required this.ilanId, required this.ilanBaslik, required this.ilanSahibiId, required this.ilanSahibiAd, required this.teklifVerenId, required this.teklifVerenAd, required this.miktar, required this.ilanMiktar, this.durum = TeklifDurum.bekliyor, this.karsiTeklifMiktar, this.olusturmaTarihi, this.guncellemeTarihi});
  factory _TeklifModel.fromJson(Map<String, dynamic> json) => _$TeklifModelFromJson(json);

@override final  String id;
@override final  String ilanId;
@override final  String ilanBaslik;
@override final  String ilanSahibiId;
@override final  String ilanSahibiAd;
@override final  String teklifVerenId;
@override final  String teklifVerenAd;
@override final  double miktar;
// kullanıcının teklifi
@override final  double ilanMiktar;
// ilandaki orijinal fiyat
@override@JsonKey() final  TeklifDurum durum;
@override final  double? karsiTeklifMiktar;
// ilan sahibinin karşı teklifi
@override final  DateTime? olusturmaTarihi;
@override final  DateTime? guncellemeTarihi;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeklifModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ilanId, ilanId) || other.ilanId == ilanId)&&(identical(other.ilanBaslik, ilanBaslik) || other.ilanBaslik == ilanBaslik)&&(identical(other.ilanSahibiId, ilanSahibiId) || other.ilanSahibiId == ilanSahibiId)&&(identical(other.ilanSahibiAd, ilanSahibiAd) || other.ilanSahibiAd == ilanSahibiAd)&&(identical(other.teklifVerenId, teklifVerenId) || other.teklifVerenId == teklifVerenId)&&(identical(other.teklifVerenAd, teklifVerenAd) || other.teklifVerenAd == teklifVerenAd)&&(identical(other.miktar, miktar) || other.miktar == miktar)&&(identical(other.ilanMiktar, ilanMiktar) || other.ilanMiktar == ilanMiktar)&&(identical(other.durum, durum) || other.durum == durum)&&(identical(other.karsiTeklifMiktar, karsiTeklifMiktar) || other.karsiTeklifMiktar == karsiTeklifMiktar)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.guncellemeTarihi, guncellemeTarihi) || other.guncellemeTarihi == guncellemeTarihi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ilanId,ilanBaslik,ilanSahibiId,ilanSahibiAd,teklifVerenId,teklifVerenAd,miktar,ilanMiktar,durum,karsiTeklifMiktar,olusturmaTarihi,guncellemeTarihi);

@override
String toString() {
  return 'TeklifModel(id: $id, ilanId: $ilanId, ilanBaslik: $ilanBaslik, ilanSahibiId: $ilanSahibiId, ilanSahibiAd: $ilanSahibiAd, teklifVerenId: $teklifVerenId, teklifVerenAd: $teklifVerenAd, miktar: $miktar, ilanMiktar: $ilanMiktar, durum: $durum, karsiTeklifMiktar: $karsiTeklifMiktar, olusturmaTarihi: $olusturmaTarihi, guncellemeTarihi: $guncellemeTarihi)';
}


}

/// @nodoc
abstract mixin class _$TeklifModelCopyWith<$Res> implements $TeklifModelCopyWith<$Res> {
  factory _$TeklifModelCopyWith(_TeklifModel value, $Res Function(_TeklifModel) _then) = __$TeklifModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String ilanId, String ilanBaslik, String ilanSahibiId, String ilanSahibiAd, String teklifVerenId, String teklifVerenAd, double miktar, double ilanMiktar, TeklifDurum durum, double? karsiTeklifMiktar, DateTime? olusturmaTarihi, DateTime? guncellemeTarihi
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ilanId = null,Object? ilanBaslik = null,Object? ilanSahibiId = null,Object? ilanSahibiAd = null,Object? teklifVerenId = null,Object? teklifVerenAd = null,Object? miktar = null,Object? ilanMiktar = null,Object? durum = null,Object? karsiTeklifMiktar = freezed,Object? olusturmaTarihi = freezed,Object? guncellemeTarihi = freezed,}) {
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
as DateTime?,
  ));
}


}

// dart format on
