// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mesaj_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MesajModel {

 String get id; String get metin; String get gondereId; MesajTip get tip;@TimestampConverter() DateTime? get zaman; bool get okundu; String? get resimUrl; bool get gonderiliyor;
/// Create a copy of MesajModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MesajModelCopyWith<MesajModel> get copyWith => _$MesajModelCopyWithImpl<MesajModel>(this as MesajModel, _$identity);

  /// Serializes this MesajModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MesajModel&&(identical(other.id, id) || other.id == id)&&(identical(other.metin, metin) || other.metin == metin)&&(identical(other.gondereId, gondereId) || other.gondereId == gondereId)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.zaman, zaman) || other.zaman == zaman)&&(identical(other.okundu, okundu) || other.okundu == okundu)&&(identical(other.resimUrl, resimUrl) || other.resimUrl == resimUrl)&&(identical(other.gonderiliyor, gonderiliyor) || other.gonderiliyor == gonderiliyor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,metin,gondereId,tip,zaman,okundu,resimUrl,gonderiliyor);

@override
String toString() {
  return 'MesajModel(id: $id, metin: $metin, gondereId: $gondereId, tip: $tip, zaman: $zaman, okundu: $okundu, resimUrl: $resimUrl, gonderiliyor: $gonderiliyor)';
}


}

/// @nodoc
abstract mixin class $MesajModelCopyWith<$Res>  {
  factory $MesajModelCopyWith(MesajModel value, $Res Function(MesajModel) _then) = _$MesajModelCopyWithImpl;
@useResult
$Res call({
 String id, String metin, String gondereId, MesajTip tip,@TimestampConverter() DateTime? zaman, bool okundu, String? resimUrl, bool gonderiliyor
});




}
/// @nodoc
class _$MesajModelCopyWithImpl<$Res>
    implements $MesajModelCopyWith<$Res> {
  _$MesajModelCopyWithImpl(this._self, this._then);

  final MesajModel _self;
  final $Res Function(MesajModel) _then;

/// Create a copy of MesajModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? metin = null,Object? gondereId = null,Object? tip = null,Object? zaman = freezed,Object? okundu = null,Object? resimUrl = freezed,Object? gonderiliyor = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,metin: null == metin ? _self.metin : metin // ignore: cast_nullable_to_non_nullable
as String,gondereId: null == gondereId ? _self.gondereId : gondereId // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as MesajTip,zaman: freezed == zaman ? _self.zaman : zaman // ignore: cast_nullable_to_non_nullable
as DateTime?,okundu: null == okundu ? _self.okundu : okundu // ignore: cast_nullable_to_non_nullable
as bool,resimUrl: freezed == resimUrl ? _self.resimUrl : resimUrl // ignore: cast_nullable_to_non_nullable
as String?,gonderiliyor: null == gonderiliyor ? _self.gonderiliyor : gonderiliyor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MesajModel].
extension MesajModelPatterns on MesajModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MesajModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MesajModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MesajModel value)  $default,){
final _that = this;
switch (_that) {
case _MesajModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MesajModel value)?  $default,){
final _that = this;
switch (_that) {
case _MesajModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String metin,  String gondereId,  MesajTip tip, @TimestampConverter()  DateTime? zaman,  bool okundu,  String? resimUrl,  bool gonderiliyor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MesajModel() when $default != null:
return $default(_that.id,_that.metin,_that.gondereId,_that.tip,_that.zaman,_that.okundu,_that.resimUrl,_that.gonderiliyor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String metin,  String gondereId,  MesajTip tip, @TimestampConverter()  DateTime? zaman,  bool okundu,  String? resimUrl,  bool gonderiliyor)  $default,) {final _that = this;
switch (_that) {
case _MesajModel():
return $default(_that.id,_that.metin,_that.gondereId,_that.tip,_that.zaman,_that.okundu,_that.resimUrl,_that.gonderiliyor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String metin,  String gondereId,  MesajTip tip, @TimestampConverter()  DateTime? zaman,  bool okundu,  String? resimUrl,  bool gonderiliyor)?  $default,) {final _that = this;
switch (_that) {
case _MesajModel() when $default != null:
return $default(_that.id,_that.metin,_that.gondereId,_that.tip,_that.zaman,_that.okundu,_that.resimUrl,_that.gonderiliyor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MesajModel implements MesajModel {
  const _MesajModel({required this.id, required this.metin, required this.gondereId, this.tip = MesajTip.mesaj, @TimestampConverter() this.zaman, this.okundu = false, this.resimUrl, this.gonderiliyor = false});
  factory _MesajModel.fromJson(Map<String, dynamic> json) => _$MesajModelFromJson(json);

@override final  String id;
@override final  String metin;
@override final  String gondereId;
@override@JsonKey() final  MesajTip tip;
@override@TimestampConverter() final  DateTime? zaman;
@override@JsonKey() final  bool okundu;
@override final  String? resimUrl;
@override@JsonKey() final  bool gonderiliyor;

/// Create a copy of MesajModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MesajModelCopyWith<_MesajModel> get copyWith => __$MesajModelCopyWithImpl<_MesajModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MesajModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MesajModel&&(identical(other.id, id) || other.id == id)&&(identical(other.metin, metin) || other.metin == metin)&&(identical(other.gondereId, gondereId) || other.gondereId == gondereId)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.zaman, zaman) || other.zaman == zaman)&&(identical(other.okundu, okundu) || other.okundu == okundu)&&(identical(other.resimUrl, resimUrl) || other.resimUrl == resimUrl)&&(identical(other.gonderiliyor, gonderiliyor) || other.gonderiliyor == gonderiliyor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,metin,gondereId,tip,zaman,okundu,resimUrl,gonderiliyor);

@override
String toString() {
  return 'MesajModel(id: $id, metin: $metin, gondereId: $gondereId, tip: $tip, zaman: $zaman, okundu: $okundu, resimUrl: $resimUrl, gonderiliyor: $gonderiliyor)';
}


}

/// @nodoc
abstract mixin class _$MesajModelCopyWith<$Res> implements $MesajModelCopyWith<$Res> {
  factory _$MesajModelCopyWith(_MesajModel value, $Res Function(_MesajModel) _then) = __$MesajModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String metin, String gondereId, MesajTip tip,@TimestampConverter() DateTime? zaman, bool okundu, String? resimUrl, bool gonderiliyor
});




}
/// @nodoc
class __$MesajModelCopyWithImpl<$Res>
    implements _$MesajModelCopyWith<$Res> {
  __$MesajModelCopyWithImpl(this._self, this._then);

  final _MesajModel _self;
  final $Res Function(_MesajModel) _then;

/// Create a copy of MesajModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? metin = null,Object? gondereId = null,Object? tip = null,Object? zaman = freezed,Object? okundu = null,Object? resimUrl = freezed,Object? gonderiliyor = null,}) {
  return _then(_MesajModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,metin: null == metin ? _self.metin : metin // ignore: cast_nullable_to_non_nullable
as String,gondereId: null == gondereId ? _self.gondereId : gondereId // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as MesajTip,zaman: freezed == zaman ? _self.zaman : zaman // ignore: cast_nullable_to_non_nullable
as DateTime?,okundu: null == okundu ? _self.okundu : okundu // ignore: cast_nullable_to_non_nullable
as bool,resimUrl: freezed == resimUrl ? _self.resimUrl : resimUrl // ignore: cast_nullable_to_non_nullable
as String?,gonderiliyor: null == gonderiliyor ? _self.gonderiliyor : gonderiliyor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SohbetModel {

 String get id; List<String> get kullanicilar; String get ilanId; String get ilanBaslik; String get ilanResimUrl; String get ilanSahibiId; String get ilanTip; String? get sonMesaj;@TimestampConverter() DateTime? get sonMesajZamani; String get sonGondereId; Map<String, int> get okunmamis; Map<String, dynamic> get gizli; Map<String, bool> get sabitlenmis; Map<String, String> get kullaniciAdlari;
/// Create a copy of SohbetModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SohbetModelCopyWith<SohbetModel> get copyWith => _$SohbetModelCopyWithImpl<SohbetModel>(this as SohbetModel, _$identity);

  /// Serializes this SohbetModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SohbetModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.kullanicilar, kullanicilar)&&(identical(other.ilanId, ilanId) || other.ilanId == ilanId)&&(identical(other.ilanBaslik, ilanBaslik) || other.ilanBaslik == ilanBaslik)&&(identical(other.ilanResimUrl, ilanResimUrl) || other.ilanResimUrl == ilanResimUrl)&&(identical(other.ilanSahibiId, ilanSahibiId) || other.ilanSahibiId == ilanSahibiId)&&(identical(other.ilanTip, ilanTip) || other.ilanTip == ilanTip)&&(identical(other.sonMesaj, sonMesaj) || other.sonMesaj == sonMesaj)&&(identical(other.sonMesajZamani, sonMesajZamani) || other.sonMesajZamani == sonMesajZamani)&&(identical(other.sonGondereId, sonGondereId) || other.sonGondereId == sonGondereId)&&const DeepCollectionEquality().equals(other.okunmamis, okunmamis)&&const DeepCollectionEquality().equals(other.gizli, gizli)&&const DeepCollectionEquality().equals(other.sabitlenmis, sabitlenmis)&&const DeepCollectionEquality().equals(other.kullaniciAdlari, kullaniciAdlari));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(kullanicilar),ilanId,ilanBaslik,ilanResimUrl,ilanSahibiId,ilanTip,sonMesaj,sonMesajZamani,sonGondereId,const DeepCollectionEquality().hash(okunmamis),const DeepCollectionEquality().hash(gizli),const DeepCollectionEquality().hash(sabitlenmis),const DeepCollectionEquality().hash(kullaniciAdlari));

@override
String toString() {
  return 'SohbetModel(id: $id, kullanicilar: $kullanicilar, ilanId: $ilanId, ilanBaslik: $ilanBaslik, ilanResimUrl: $ilanResimUrl, ilanSahibiId: $ilanSahibiId, ilanTip: $ilanTip, sonMesaj: $sonMesaj, sonMesajZamani: $sonMesajZamani, sonGondereId: $sonGondereId, okunmamis: $okunmamis, gizli: $gizli, sabitlenmis: $sabitlenmis, kullaniciAdlari: $kullaniciAdlari)';
}


}

/// @nodoc
abstract mixin class $SohbetModelCopyWith<$Res>  {
  factory $SohbetModelCopyWith(SohbetModel value, $Res Function(SohbetModel) _then) = _$SohbetModelCopyWithImpl;
@useResult
$Res call({
 String id, List<String> kullanicilar, String ilanId, String ilanBaslik, String ilanResimUrl, String ilanSahibiId, String ilanTip, String? sonMesaj,@TimestampConverter() DateTime? sonMesajZamani, String sonGondereId, Map<String, int> okunmamis, Map<String, dynamic> gizli, Map<String, bool> sabitlenmis, Map<String, String> kullaniciAdlari
});




}
/// @nodoc
class _$SohbetModelCopyWithImpl<$Res>
    implements $SohbetModelCopyWith<$Res> {
  _$SohbetModelCopyWithImpl(this._self, this._then);

  final SohbetModel _self;
  final $Res Function(SohbetModel) _then;

/// Create a copy of SohbetModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kullanicilar = null,Object? ilanId = null,Object? ilanBaslik = null,Object? ilanResimUrl = null,Object? ilanSahibiId = null,Object? ilanTip = null,Object? sonMesaj = freezed,Object? sonMesajZamani = freezed,Object? sonGondereId = null,Object? okunmamis = null,Object? gizli = null,Object? sabitlenmis = null,Object? kullaniciAdlari = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kullanicilar: null == kullanicilar ? _self.kullanicilar : kullanicilar // ignore: cast_nullable_to_non_nullable
as List<String>,ilanId: null == ilanId ? _self.ilanId : ilanId // ignore: cast_nullable_to_non_nullable
as String,ilanBaslik: null == ilanBaslik ? _self.ilanBaslik : ilanBaslik // ignore: cast_nullable_to_non_nullable
as String,ilanResimUrl: null == ilanResimUrl ? _self.ilanResimUrl : ilanResimUrl // ignore: cast_nullable_to_non_nullable
as String,ilanSahibiId: null == ilanSahibiId ? _self.ilanSahibiId : ilanSahibiId // ignore: cast_nullable_to_non_nullable
as String,ilanTip: null == ilanTip ? _self.ilanTip : ilanTip // ignore: cast_nullable_to_non_nullable
as String,sonMesaj: freezed == sonMesaj ? _self.sonMesaj : sonMesaj // ignore: cast_nullable_to_non_nullable
as String?,sonMesajZamani: freezed == sonMesajZamani ? _self.sonMesajZamani : sonMesajZamani // ignore: cast_nullable_to_non_nullable
as DateTime?,sonGondereId: null == sonGondereId ? _self.sonGondereId : sonGondereId // ignore: cast_nullable_to_non_nullable
as String,okunmamis: null == okunmamis ? _self.okunmamis : okunmamis // ignore: cast_nullable_to_non_nullable
as Map<String, int>,gizli: null == gizli ? _self.gizli : gizli // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,sabitlenmis: null == sabitlenmis ? _self.sabitlenmis : sabitlenmis // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,kullaniciAdlari: null == kullaniciAdlari ? _self.kullaniciAdlari : kullaniciAdlari // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SohbetModel].
extension SohbetModelPatterns on SohbetModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SohbetModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SohbetModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SohbetModel value)  $default,){
final _that = this;
switch (_that) {
case _SohbetModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SohbetModel value)?  $default,){
final _that = this;
switch (_that) {
case _SohbetModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<String> kullanicilar,  String ilanId,  String ilanBaslik,  String ilanResimUrl,  String ilanSahibiId,  String ilanTip,  String? sonMesaj, @TimestampConverter()  DateTime? sonMesajZamani,  String sonGondereId,  Map<String, int> okunmamis,  Map<String, dynamic> gizli,  Map<String, bool> sabitlenmis,  Map<String, String> kullaniciAdlari)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SohbetModel() when $default != null:
return $default(_that.id,_that.kullanicilar,_that.ilanId,_that.ilanBaslik,_that.ilanResimUrl,_that.ilanSahibiId,_that.ilanTip,_that.sonMesaj,_that.sonMesajZamani,_that.sonGondereId,_that.okunmamis,_that.gizli,_that.sabitlenmis,_that.kullaniciAdlari);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<String> kullanicilar,  String ilanId,  String ilanBaslik,  String ilanResimUrl,  String ilanSahibiId,  String ilanTip,  String? sonMesaj, @TimestampConverter()  DateTime? sonMesajZamani,  String sonGondereId,  Map<String, int> okunmamis,  Map<String, dynamic> gizli,  Map<String, bool> sabitlenmis,  Map<String, String> kullaniciAdlari)  $default,) {final _that = this;
switch (_that) {
case _SohbetModel():
return $default(_that.id,_that.kullanicilar,_that.ilanId,_that.ilanBaslik,_that.ilanResimUrl,_that.ilanSahibiId,_that.ilanTip,_that.sonMesaj,_that.sonMesajZamani,_that.sonGondereId,_that.okunmamis,_that.gizli,_that.sabitlenmis,_that.kullaniciAdlari);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<String> kullanicilar,  String ilanId,  String ilanBaslik,  String ilanResimUrl,  String ilanSahibiId,  String ilanTip,  String? sonMesaj, @TimestampConverter()  DateTime? sonMesajZamani,  String sonGondereId,  Map<String, int> okunmamis,  Map<String, dynamic> gizli,  Map<String, bool> sabitlenmis,  Map<String, String> kullaniciAdlari)?  $default,) {final _that = this;
switch (_that) {
case _SohbetModel() when $default != null:
return $default(_that.id,_that.kullanicilar,_that.ilanId,_that.ilanBaslik,_that.ilanResimUrl,_that.ilanSahibiId,_that.ilanTip,_that.sonMesaj,_that.sonMesajZamani,_that.sonGondereId,_that.okunmamis,_that.gizli,_that.sabitlenmis,_that.kullaniciAdlari);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SohbetModel implements SohbetModel {
  const _SohbetModel({required this.id, required final  List<String> kullanicilar, required this.ilanId, this.ilanBaslik = '', this.ilanResimUrl = '', this.ilanSahibiId = '', this.ilanTip = 'istek', this.sonMesaj, @TimestampConverter() this.sonMesajZamani, this.sonGondereId = '', final  Map<String, int> okunmamis = const {}, final  Map<String, dynamic> gizli = const {}, final  Map<String, bool> sabitlenmis = const {}, final  Map<String, String> kullaniciAdlari = const {}}): _kullanicilar = kullanicilar,_okunmamis = okunmamis,_gizli = gizli,_sabitlenmis = sabitlenmis,_kullaniciAdlari = kullaniciAdlari;
  factory _SohbetModel.fromJson(Map<String, dynamic> json) => _$SohbetModelFromJson(json);

@override final  String id;
 final  List<String> _kullanicilar;
@override List<String> get kullanicilar {
  if (_kullanicilar is EqualUnmodifiableListView) return _kullanicilar;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_kullanicilar);
}

@override final  String ilanId;
@override@JsonKey() final  String ilanBaslik;
@override@JsonKey() final  String ilanResimUrl;
@override@JsonKey() final  String ilanSahibiId;
@override@JsonKey() final  String ilanTip;
@override final  String? sonMesaj;
@override@TimestampConverter() final  DateTime? sonMesajZamani;
@override@JsonKey() final  String sonGondereId;
 final  Map<String, int> _okunmamis;
@override@JsonKey() Map<String, int> get okunmamis {
  if (_okunmamis is EqualUnmodifiableMapView) return _okunmamis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_okunmamis);
}

 final  Map<String, dynamic> _gizli;
@override@JsonKey() Map<String, dynamic> get gizli {
  if (_gizli is EqualUnmodifiableMapView) return _gizli;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_gizli);
}

 final  Map<String, bool> _sabitlenmis;
@override@JsonKey() Map<String, bool> get sabitlenmis {
  if (_sabitlenmis is EqualUnmodifiableMapView) return _sabitlenmis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sabitlenmis);
}

 final  Map<String, String> _kullaniciAdlari;
@override@JsonKey() Map<String, String> get kullaniciAdlari {
  if (_kullaniciAdlari is EqualUnmodifiableMapView) return _kullaniciAdlari;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_kullaniciAdlari);
}


/// Create a copy of SohbetModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SohbetModelCopyWith<_SohbetModel> get copyWith => __$SohbetModelCopyWithImpl<_SohbetModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SohbetModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SohbetModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._kullanicilar, _kullanicilar)&&(identical(other.ilanId, ilanId) || other.ilanId == ilanId)&&(identical(other.ilanBaslik, ilanBaslik) || other.ilanBaslik == ilanBaslik)&&(identical(other.ilanResimUrl, ilanResimUrl) || other.ilanResimUrl == ilanResimUrl)&&(identical(other.ilanSahibiId, ilanSahibiId) || other.ilanSahibiId == ilanSahibiId)&&(identical(other.ilanTip, ilanTip) || other.ilanTip == ilanTip)&&(identical(other.sonMesaj, sonMesaj) || other.sonMesaj == sonMesaj)&&(identical(other.sonMesajZamani, sonMesajZamani) || other.sonMesajZamani == sonMesajZamani)&&(identical(other.sonGondereId, sonGondereId) || other.sonGondereId == sonGondereId)&&const DeepCollectionEquality().equals(other._okunmamis, _okunmamis)&&const DeepCollectionEquality().equals(other._gizli, _gizli)&&const DeepCollectionEquality().equals(other._sabitlenmis, _sabitlenmis)&&const DeepCollectionEquality().equals(other._kullaniciAdlari, _kullaniciAdlari));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_kullanicilar),ilanId,ilanBaslik,ilanResimUrl,ilanSahibiId,ilanTip,sonMesaj,sonMesajZamani,sonGondereId,const DeepCollectionEquality().hash(_okunmamis),const DeepCollectionEquality().hash(_gizli),const DeepCollectionEquality().hash(_sabitlenmis),const DeepCollectionEquality().hash(_kullaniciAdlari));

@override
String toString() {
  return 'SohbetModel(id: $id, kullanicilar: $kullanicilar, ilanId: $ilanId, ilanBaslik: $ilanBaslik, ilanResimUrl: $ilanResimUrl, ilanSahibiId: $ilanSahibiId, ilanTip: $ilanTip, sonMesaj: $sonMesaj, sonMesajZamani: $sonMesajZamani, sonGondereId: $sonGondereId, okunmamis: $okunmamis, gizli: $gizli, sabitlenmis: $sabitlenmis, kullaniciAdlari: $kullaniciAdlari)';
}


}

/// @nodoc
abstract mixin class _$SohbetModelCopyWith<$Res> implements $SohbetModelCopyWith<$Res> {
  factory _$SohbetModelCopyWith(_SohbetModel value, $Res Function(_SohbetModel) _then) = __$SohbetModelCopyWithImpl;
@override @useResult
$Res call({
 String id, List<String> kullanicilar, String ilanId, String ilanBaslik, String ilanResimUrl, String ilanSahibiId, String ilanTip, String? sonMesaj,@TimestampConverter() DateTime? sonMesajZamani, String sonGondereId, Map<String, int> okunmamis, Map<String, dynamic> gizli, Map<String, bool> sabitlenmis, Map<String, String> kullaniciAdlari
});




}
/// @nodoc
class __$SohbetModelCopyWithImpl<$Res>
    implements _$SohbetModelCopyWith<$Res> {
  __$SohbetModelCopyWithImpl(this._self, this._then);

  final _SohbetModel _self;
  final $Res Function(_SohbetModel) _then;

/// Create a copy of SohbetModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kullanicilar = null,Object? ilanId = null,Object? ilanBaslik = null,Object? ilanResimUrl = null,Object? ilanSahibiId = null,Object? ilanTip = null,Object? sonMesaj = freezed,Object? sonMesajZamani = freezed,Object? sonGondereId = null,Object? okunmamis = null,Object? gizli = null,Object? sabitlenmis = null,Object? kullaniciAdlari = null,}) {
  return _then(_SohbetModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kullanicilar: null == kullanicilar ? _self._kullanicilar : kullanicilar // ignore: cast_nullable_to_non_nullable
as List<String>,ilanId: null == ilanId ? _self.ilanId : ilanId // ignore: cast_nullable_to_non_nullable
as String,ilanBaslik: null == ilanBaslik ? _self.ilanBaslik : ilanBaslik // ignore: cast_nullable_to_non_nullable
as String,ilanResimUrl: null == ilanResimUrl ? _self.ilanResimUrl : ilanResimUrl // ignore: cast_nullable_to_non_nullable
as String,ilanSahibiId: null == ilanSahibiId ? _self.ilanSahibiId : ilanSahibiId // ignore: cast_nullable_to_non_nullable
as String,ilanTip: null == ilanTip ? _self.ilanTip : ilanTip // ignore: cast_nullable_to_non_nullable
as String,sonMesaj: freezed == sonMesaj ? _self.sonMesaj : sonMesaj // ignore: cast_nullable_to_non_nullable
as String?,sonMesajZamani: freezed == sonMesajZamani ? _self.sonMesajZamani : sonMesajZamani // ignore: cast_nullable_to_non_nullable
as DateTime?,sonGondereId: null == sonGondereId ? _self.sonGondereId : sonGondereId // ignore: cast_nullable_to_non_nullable
as String,okunmamis: null == okunmamis ? _self._okunmamis : okunmamis // ignore: cast_nullable_to_non_nullable
as Map<String, int>,gizli: null == gizli ? _self._gizli : gizli // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,sabitlenmis: null == sabitlenmis ? _self._sabitlenmis : sabitlenmis // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,kullaniciAdlari: null == kullaniciAdlari ? _self._kullaniciAdlari : kullaniciAdlari // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
