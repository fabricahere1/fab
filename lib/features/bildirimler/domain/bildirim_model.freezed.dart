// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bildirim_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BildirimModel {

 String get id; String get kullaniciId; BildirimTip get tip; String get baslik; String get icerik; bool get okundu; DateTime? get tarih; String get hedefId; String get gondereId; String get gondereAd;
/// Create a copy of BildirimModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BildirimModelCopyWith<BildirimModel> get copyWith => _$BildirimModelCopyWithImpl<BildirimModel>(this as BildirimModel, _$identity);

  /// Serializes this BildirimModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BildirimModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kullaniciId, kullaniciId) || other.kullaniciId == kullaniciId)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.baslik, baslik) || other.baslik == baslik)&&(identical(other.icerik, icerik) || other.icerik == icerik)&&(identical(other.okundu, okundu) || other.okundu == okundu)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.hedefId, hedefId) || other.hedefId == hedefId)&&(identical(other.gondereId, gondereId) || other.gondereId == gondereId)&&(identical(other.gondereAd, gondereAd) || other.gondereAd == gondereAd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kullaniciId,tip,baslik,icerik,okundu,tarih,hedefId,gondereId,gondereAd);

@override
String toString() {
  return 'BildirimModel(id: $id, kullaniciId: $kullaniciId, tip: $tip, baslik: $baslik, icerik: $icerik, okundu: $okundu, tarih: $tarih, hedefId: $hedefId, gondereId: $gondereId, gondereAd: $gondereAd)';
}


}

/// @nodoc
abstract mixin class $BildirimModelCopyWith<$Res>  {
  factory $BildirimModelCopyWith(BildirimModel value, $Res Function(BildirimModel) _then) = _$BildirimModelCopyWithImpl;
@useResult
$Res call({
 String id, String kullaniciId, BildirimTip tip, String baslik, String icerik, bool okundu, DateTime? tarih, String hedefId, String gondereId, String gondereAd
});




}
/// @nodoc
class _$BildirimModelCopyWithImpl<$Res>
    implements $BildirimModelCopyWith<$Res> {
  _$BildirimModelCopyWithImpl(this._self, this._then);

  final BildirimModel _self;
  final $Res Function(BildirimModel) _then;

/// Create a copy of BildirimModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kullaniciId = null,Object? tip = null,Object? baslik = null,Object? icerik = null,Object? okundu = null,Object? tarih = freezed,Object? hedefId = null,Object? gondereId = null,Object? gondereAd = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kullaniciId: null == kullaniciId ? _self.kullaniciId : kullaniciId // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as BildirimTip,baslik: null == baslik ? _self.baslik : baslik // ignore: cast_nullable_to_non_nullable
as String,icerik: null == icerik ? _self.icerik : icerik // ignore: cast_nullable_to_non_nullable
as String,okundu: null == okundu ? _self.okundu : okundu // ignore: cast_nullable_to_non_nullable
as bool,tarih: freezed == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as DateTime?,hedefId: null == hedefId ? _self.hedefId : hedefId // ignore: cast_nullable_to_non_nullable
as String,gondereId: null == gondereId ? _self.gondereId : gondereId // ignore: cast_nullable_to_non_nullable
as String,gondereAd: null == gondereAd ? _self.gondereAd : gondereAd // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BildirimModel].
extension BildirimModelPatterns on BildirimModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BildirimModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BildirimModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BildirimModel value)  $default,){
final _that = this;
switch (_that) {
case _BildirimModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BildirimModel value)?  $default,){
final _that = this;
switch (_that) {
case _BildirimModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kullaniciId,  BildirimTip tip,  String baslik,  String icerik,  bool okundu,  DateTime? tarih,  String hedefId,  String gondereId,  String gondereAd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BildirimModel() when $default != null:
return $default(_that.id,_that.kullaniciId,_that.tip,_that.baslik,_that.icerik,_that.okundu,_that.tarih,_that.hedefId,_that.gondereId,_that.gondereAd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kullaniciId,  BildirimTip tip,  String baslik,  String icerik,  bool okundu,  DateTime? tarih,  String hedefId,  String gondereId,  String gondereAd)  $default,) {final _that = this;
switch (_that) {
case _BildirimModel():
return $default(_that.id,_that.kullaniciId,_that.tip,_that.baslik,_that.icerik,_that.okundu,_that.tarih,_that.hedefId,_that.gondereId,_that.gondereAd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kullaniciId,  BildirimTip tip,  String baslik,  String icerik,  bool okundu,  DateTime? tarih,  String hedefId,  String gondereId,  String gondereAd)?  $default,) {final _that = this;
switch (_that) {
case _BildirimModel() when $default != null:
return $default(_that.id,_that.kullaniciId,_that.tip,_that.baslik,_that.icerik,_that.okundu,_that.tarih,_that.hedefId,_that.gondereId,_that.gondereAd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BildirimModel implements BildirimModel {
  const _BildirimModel({required this.id, required this.kullaniciId, this.tip = BildirimTip.sistem, this.baslik = '', this.icerik = '', this.okundu = false, this.tarih, this.hedefId = '', this.gondereId = '', this.gondereAd = ''});
  factory _BildirimModel.fromJson(Map<String, dynamic> json) => _$BildirimModelFromJson(json);

@override final  String id;
@override final  String kullaniciId;
@override@JsonKey() final  BildirimTip tip;
@override@JsonKey() final  String baslik;
@override@JsonKey() final  String icerik;
@override@JsonKey() final  bool okundu;
@override final  DateTime? tarih;
@override@JsonKey() final  String hedefId;
@override@JsonKey() final  String gondereId;
@override@JsonKey() final  String gondereAd;

/// Create a copy of BildirimModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BildirimModelCopyWith<_BildirimModel> get copyWith => __$BildirimModelCopyWithImpl<_BildirimModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BildirimModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BildirimModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kullaniciId, kullaniciId) || other.kullaniciId == kullaniciId)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.baslik, baslik) || other.baslik == baslik)&&(identical(other.icerik, icerik) || other.icerik == icerik)&&(identical(other.okundu, okundu) || other.okundu == okundu)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.hedefId, hedefId) || other.hedefId == hedefId)&&(identical(other.gondereId, gondereId) || other.gondereId == gondereId)&&(identical(other.gondereAd, gondereAd) || other.gondereAd == gondereAd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kullaniciId,tip,baslik,icerik,okundu,tarih,hedefId,gondereId,gondereAd);

@override
String toString() {
  return 'BildirimModel(id: $id, kullaniciId: $kullaniciId, tip: $tip, baslik: $baslik, icerik: $icerik, okundu: $okundu, tarih: $tarih, hedefId: $hedefId, gondereId: $gondereId, gondereAd: $gondereAd)';
}


}

/// @nodoc
abstract mixin class _$BildirimModelCopyWith<$Res> implements $BildirimModelCopyWith<$Res> {
  factory _$BildirimModelCopyWith(_BildirimModel value, $Res Function(_BildirimModel) _then) = __$BildirimModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String kullaniciId, BildirimTip tip, String baslik, String icerik, bool okundu, DateTime? tarih, String hedefId, String gondereId, String gondereAd
});




}
/// @nodoc
class __$BildirimModelCopyWithImpl<$Res>
    implements _$BildirimModelCopyWith<$Res> {
  __$BildirimModelCopyWithImpl(this._self, this._then);

  final _BildirimModel _self;
  final $Res Function(_BildirimModel) _then;

/// Create a copy of BildirimModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kullaniciId = null,Object? tip = null,Object? baslik = null,Object? icerik = null,Object? okundu = null,Object? tarih = freezed,Object? hedefId = null,Object? gondereId = null,Object? gondereAd = null,}) {
  return _then(_BildirimModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kullaniciId: null == kullaniciId ? _self.kullaniciId : kullaniciId // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as BildirimTip,baslik: null == baslik ? _self.baslik : baslik // ignore: cast_nullable_to_non_nullable
as String,icerik: null == icerik ? _self.icerik : icerik // ignore: cast_nullable_to_non_nullable
as String,okundu: null == okundu ? _self.okundu : okundu // ignore: cast_nullable_to_non_nullable
as bool,tarih: freezed == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as DateTime?,hedefId: null == hedefId ? _self.hedefId : hedefId // ignore: cast_nullable_to_non_nullable
as String,gondereId: null == gondereId ? _self.gondereId : gondereId // ignore: cast_nullable_to_non_nullable
as String,gondereAd: null == gondereAd ? _self.gondereAd : gondereAd // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
