// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ilan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IlanModel {

 String get id; String get tip; String get nereden; String get nereye; String get ucret; String get urun; String get notlar; String get kategori; String get kullaniciId; String get kullaniciAd; bool get aktif;@TimestampConverter() DateTime? get tarih;@TimestampConverter() DateTime? get olusturmaTarihi; String get resimUrl; List<String> get resimUrller; String get urunLinki; int get favoriSayisi; String get tasimaTercihi;
/// Create a copy of IlanModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IlanModelCopyWith<IlanModel> get copyWith => _$IlanModelCopyWithImpl<IlanModel>(this as IlanModel, _$identity);

  /// Serializes this IlanModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.nereden, nereden) || other.nereden == nereden)&&(identical(other.nereye, nereye) || other.nereye == nereye)&&(identical(other.ucret, ucret) || other.ucret == ucret)&&(identical(other.urun, urun) || other.urun == urun)&&(identical(other.notlar, notlar) || other.notlar == notlar)&&(identical(other.kategori, kategori) || other.kategori == kategori)&&(identical(other.kullaniciId, kullaniciId) || other.kullaniciId == kullaniciId)&&(identical(other.kullaniciAd, kullaniciAd) || other.kullaniciAd == kullaniciAd)&&(identical(other.aktif, aktif) || other.aktif == aktif)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.resimUrl, resimUrl) || other.resimUrl == resimUrl)&&const DeepCollectionEquality().equals(other.resimUrller, resimUrller)&&(identical(other.urunLinki, urunLinki) || other.urunLinki == urunLinki)&&(identical(other.favoriSayisi, favoriSayisi) || other.favoriSayisi == favoriSayisi)&&(identical(other.tasimaTercihi, tasimaTercihi) || other.tasimaTercihi == tasimaTercihi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tip,nereden,nereye,ucret,urun,notlar,kategori,kullaniciId,kullaniciAd,aktif,tarih,olusturmaTarihi,resimUrl,const DeepCollectionEquality().hash(resimUrller),urunLinki,favoriSayisi,tasimaTercihi);

@override
String toString() {
  return 'IlanModel(id: $id, tip: $tip, nereden: $nereden, nereye: $nereye, ucret: $ucret, urun: $urun, notlar: $notlar, kategori: $kategori, kullaniciId: $kullaniciId, kullaniciAd: $kullaniciAd, aktif: $aktif, tarih: $tarih, olusturmaTarihi: $olusturmaTarihi, resimUrl: $resimUrl, resimUrller: $resimUrller, urunLinki: $urunLinki, favoriSayisi: $favoriSayisi, tasimaTercihi: $tasimaTercihi)';
}


}

/// @nodoc
abstract mixin class $IlanModelCopyWith<$Res>  {
  factory $IlanModelCopyWith(IlanModel value, $Res Function(IlanModel) _then) = _$IlanModelCopyWithImpl;
@useResult
$Res call({
 String id, String tip, String nereden, String nereye, String ucret, String urun, String notlar, String kategori, String kullaniciId, String kullaniciAd, bool aktif,@TimestampConverter() DateTime? tarih,@TimestampConverter() DateTime? olusturmaTarihi, String resimUrl, List<String> resimUrller, String urunLinki, int favoriSayisi, String tasimaTercihi
});




}
/// @nodoc
class _$IlanModelCopyWithImpl<$Res>
    implements $IlanModelCopyWith<$Res> {
  _$IlanModelCopyWithImpl(this._self, this._then);

  final IlanModel _self;
  final $Res Function(IlanModel) _then;

/// Create a copy of IlanModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tip = null,Object? nereden = null,Object? nereye = null,Object? ucret = null,Object? urun = null,Object? notlar = null,Object? kategori = null,Object? kullaniciId = null,Object? kullaniciAd = null,Object? aktif = null,Object? tarih = freezed,Object? olusturmaTarihi = freezed,Object? resimUrl = null,Object? resimUrller = null,Object? urunLinki = null,Object? favoriSayisi = null,Object? tasimaTercihi = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as String,nereden: null == nereden ? _self.nereden : nereden // ignore: cast_nullable_to_non_nullable
as String,nereye: null == nereye ? _self.nereye : nereye // ignore: cast_nullable_to_non_nullable
as String,ucret: null == ucret ? _self.ucret : ucret // ignore: cast_nullable_to_non_nullable
as String,urun: null == urun ? _self.urun : urun // ignore: cast_nullable_to_non_nullable
as String,notlar: null == notlar ? _self.notlar : notlar // ignore: cast_nullable_to_non_nullable
as String,kategori: null == kategori ? _self.kategori : kategori // ignore: cast_nullable_to_non_nullable
as String,kullaniciId: null == kullaniciId ? _self.kullaniciId : kullaniciId // ignore: cast_nullable_to_non_nullable
as String,kullaniciAd: null == kullaniciAd ? _self.kullaniciAd : kullaniciAd // ignore: cast_nullable_to_non_nullable
as String,aktif: null == aktif ? _self.aktif : aktif // ignore: cast_nullable_to_non_nullable
as bool,tarih: freezed == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as DateTime?,olusturmaTarihi: freezed == olusturmaTarihi ? _self.olusturmaTarihi : olusturmaTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,resimUrl: null == resimUrl ? _self.resimUrl : resimUrl // ignore: cast_nullable_to_non_nullable
as String,resimUrller: null == resimUrller ? _self.resimUrller : resimUrller // ignore: cast_nullable_to_non_nullable
as List<String>,urunLinki: null == urunLinki ? _self.urunLinki : urunLinki // ignore: cast_nullable_to_non_nullable
as String,favoriSayisi: null == favoriSayisi ? _self.favoriSayisi : favoriSayisi // ignore: cast_nullable_to_non_nullable
as int,tasimaTercihi: null == tasimaTercihi ? _self.tasimaTercihi : tasimaTercihi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IlanModel].
extension IlanModelPatterns on IlanModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IlanModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IlanModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IlanModel value)  $default,){
final _that = this;
switch (_that) {
case _IlanModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IlanModel value)?  $default,){
final _that = this;
switch (_that) {
case _IlanModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tip,  String nereden,  String nereye,  String ucret,  String urun,  String notlar,  String kategori,  String kullaniciId,  String kullaniciAd,  bool aktif, @TimestampConverter()  DateTime? tarih, @TimestampConverter()  DateTime? olusturmaTarihi,  String resimUrl,  List<String> resimUrller,  String urunLinki,  int favoriSayisi,  String tasimaTercihi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IlanModel() when $default != null:
return $default(_that.id,_that.tip,_that.nereden,_that.nereye,_that.ucret,_that.urun,_that.notlar,_that.kategori,_that.kullaniciId,_that.kullaniciAd,_that.aktif,_that.tarih,_that.olusturmaTarihi,_that.resimUrl,_that.resimUrller,_that.urunLinki,_that.favoriSayisi,_that.tasimaTercihi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tip,  String nereden,  String nereye,  String ucret,  String urun,  String notlar,  String kategori,  String kullaniciId,  String kullaniciAd,  bool aktif, @TimestampConverter()  DateTime? tarih, @TimestampConverter()  DateTime? olusturmaTarihi,  String resimUrl,  List<String> resimUrller,  String urunLinki,  int favoriSayisi,  String tasimaTercihi)  $default,) {final _that = this;
switch (_that) {
case _IlanModel():
return $default(_that.id,_that.tip,_that.nereden,_that.nereye,_that.ucret,_that.urun,_that.notlar,_that.kategori,_that.kullaniciId,_that.kullaniciAd,_that.aktif,_that.tarih,_that.olusturmaTarihi,_that.resimUrl,_that.resimUrller,_that.urunLinki,_that.favoriSayisi,_that.tasimaTercihi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tip,  String nereden,  String nereye,  String ucret,  String urun,  String notlar,  String kategori,  String kullaniciId,  String kullaniciAd,  bool aktif, @TimestampConverter()  DateTime? tarih, @TimestampConverter()  DateTime? olusturmaTarihi,  String resimUrl,  List<String> resimUrller,  String urunLinki,  int favoriSayisi,  String tasimaTercihi)?  $default,) {final _that = this;
switch (_that) {
case _IlanModel() when $default != null:
return $default(_that.id,_that.tip,_that.nereden,_that.nereye,_that.ucret,_that.urun,_that.notlar,_that.kategori,_that.kullaniciId,_that.kullaniciAd,_that.aktif,_that.tarih,_that.olusturmaTarihi,_that.resimUrl,_that.resimUrller,_that.urunLinki,_that.favoriSayisi,_that.tasimaTercihi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IlanModel implements IlanModel {
  const _IlanModel({required this.id, required this.tip, required this.nereden, required this.nereye, this.ucret = '', this.urun = '', this.notlar = '', this.kategori = 'diger', required this.kullaniciId, this.kullaniciAd = 'Kullanıcı', this.aktif = true, @TimestampConverter() this.tarih, @TimestampConverter() this.olusturmaTarihi, this.resimUrl = '', final  List<String> resimUrller = const [], this.urunLinki = '', this.favoriSayisi = 0, this.tasimaTercihi = 'hepsi'}): _resimUrller = resimUrller;
  factory _IlanModel.fromJson(Map<String, dynamic> json) => _$IlanModelFromJson(json);

@override final  String id;
@override final  String tip;
@override final  String nereden;
@override final  String nereye;
@override@JsonKey() final  String ucret;
@override@JsonKey() final  String urun;
@override@JsonKey() final  String notlar;
@override@JsonKey() final  String kategori;
@override final  String kullaniciId;
@override@JsonKey() final  String kullaniciAd;
@override@JsonKey() final  bool aktif;
@override@TimestampConverter() final  DateTime? tarih;
@override@TimestampConverter() final  DateTime? olusturmaTarihi;
@override@JsonKey() final  String resimUrl;
 final  List<String> _resimUrller;
@override@JsonKey() List<String> get resimUrller {
  if (_resimUrller is EqualUnmodifiableListView) return _resimUrller;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resimUrller);
}

@override@JsonKey() final  String urunLinki;
@override@JsonKey() final  int favoriSayisi;
@override@JsonKey() final  String tasimaTercihi;

/// Create a copy of IlanModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IlanModelCopyWith<_IlanModel> get copyWith => __$IlanModelCopyWithImpl<_IlanModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IlanModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.nereden, nereden) || other.nereden == nereden)&&(identical(other.nereye, nereye) || other.nereye == nereye)&&(identical(other.ucret, ucret) || other.ucret == ucret)&&(identical(other.urun, urun) || other.urun == urun)&&(identical(other.notlar, notlar) || other.notlar == notlar)&&(identical(other.kategori, kategori) || other.kategori == kategori)&&(identical(other.kullaniciId, kullaniciId) || other.kullaniciId == kullaniciId)&&(identical(other.kullaniciAd, kullaniciAd) || other.kullaniciAd == kullaniciAd)&&(identical(other.aktif, aktif) || other.aktif == aktif)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.resimUrl, resimUrl) || other.resimUrl == resimUrl)&&const DeepCollectionEquality().equals(other._resimUrller, _resimUrller)&&(identical(other.urunLinki, urunLinki) || other.urunLinki == urunLinki)&&(identical(other.favoriSayisi, favoriSayisi) || other.favoriSayisi == favoriSayisi)&&(identical(other.tasimaTercihi, tasimaTercihi) || other.tasimaTercihi == tasimaTercihi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tip,nereden,nereye,ucret,urun,notlar,kategori,kullaniciId,kullaniciAd,aktif,tarih,olusturmaTarihi,resimUrl,const DeepCollectionEquality().hash(_resimUrller),urunLinki,favoriSayisi,tasimaTercihi);

@override
String toString() {
  return 'IlanModel(id: $id, tip: $tip, nereden: $nereden, nereye: $nereye, ucret: $ucret, urun: $urun, notlar: $notlar, kategori: $kategori, kullaniciId: $kullaniciId, kullaniciAd: $kullaniciAd, aktif: $aktif, tarih: $tarih, olusturmaTarihi: $olusturmaTarihi, resimUrl: $resimUrl, resimUrller: $resimUrller, urunLinki: $urunLinki, favoriSayisi: $favoriSayisi, tasimaTercihi: $tasimaTercihi)';
}


}

/// @nodoc
abstract mixin class _$IlanModelCopyWith<$Res> implements $IlanModelCopyWith<$Res> {
  factory _$IlanModelCopyWith(_IlanModel value, $Res Function(_IlanModel) _then) = __$IlanModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String tip, String nereden, String nereye, String ucret, String urun, String notlar, String kategori, String kullaniciId, String kullaniciAd, bool aktif,@TimestampConverter() DateTime? tarih,@TimestampConverter() DateTime? olusturmaTarihi, String resimUrl, List<String> resimUrller, String urunLinki, int favoriSayisi, String tasimaTercihi
});




}
/// @nodoc
class __$IlanModelCopyWithImpl<$Res>
    implements _$IlanModelCopyWith<$Res> {
  __$IlanModelCopyWithImpl(this._self, this._then);

  final _IlanModel _self;
  final $Res Function(_IlanModel) _then;

/// Create a copy of IlanModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tip = null,Object? nereden = null,Object? nereye = null,Object? ucret = null,Object? urun = null,Object? notlar = null,Object? kategori = null,Object? kullaniciId = null,Object? kullaniciAd = null,Object? aktif = null,Object? tarih = freezed,Object? olusturmaTarihi = freezed,Object? resimUrl = null,Object? resimUrller = null,Object? urunLinki = null,Object? favoriSayisi = null,Object? tasimaTercihi = null,}) {
  return _then(_IlanModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as String,nereden: null == nereden ? _self.nereden : nereden // ignore: cast_nullable_to_non_nullable
as String,nereye: null == nereye ? _self.nereye : nereye // ignore: cast_nullable_to_non_nullable
as String,ucret: null == ucret ? _self.ucret : ucret // ignore: cast_nullable_to_non_nullable
as String,urun: null == urun ? _self.urun : urun // ignore: cast_nullable_to_non_nullable
as String,notlar: null == notlar ? _self.notlar : notlar // ignore: cast_nullable_to_non_nullable
as String,kategori: null == kategori ? _self.kategori : kategori // ignore: cast_nullable_to_non_nullable
as String,kullaniciId: null == kullaniciId ? _self.kullaniciId : kullaniciId // ignore: cast_nullable_to_non_nullable
as String,kullaniciAd: null == kullaniciAd ? _self.kullaniciAd : kullaniciAd // ignore: cast_nullable_to_non_nullable
as String,aktif: null == aktif ? _self.aktif : aktif // ignore: cast_nullable_to_non_nullable
as bool,tarih: freezed == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as DateTime?,olusturmaTarihi: freezed == olusturmaTarihi ? _self.olusturmaTarihi : olusturmaTarihi // ignore: cast_nullable_to_non_nullable
as DateTime?,resimUrl: null == resimUrl ? _self.resimUrl : resimUrl // ignore: cast_nullable_to_non_nullable
as String,resimUrller: null == resimUrller ? _self._resimUrller : resimUrller // ignore: cast_nullable_to_non_nullable
as List<String>,urunLinki: null == urunLinki ? _self.urunLinki : urunLinki // ignore: cast_nullable_to_non_nullable
as String,favoriSayisi: null == favoriSayisi ? _self.favoriSayisi : favoriSayisi // ignore: cast_nullable_to_non_nullable
as int,tasimaTercihi: null == tasimaTercihi ? _self.tasimaTercihi : tasimaTercihi // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
