// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kullanici_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KullaniciModel {

 String get id; String get adSoyad; String? get fotoUrl; String? get telefon; String? get email; String? get fcmToken; bool get profilTamamlandi; double get ortalamaPuan; int get degerlendirmeSayisi; String get kullaniciTipi; String get yasadigiUlke; String get bulunduguSehir; List<String> get geldigiSehirler; String get hakkinda; String get sehir; bool get telefonGizli; List<String> get engellenenler; int get guvenSkoru; List<String> get rozetler; int get takipciSayisi; int get takipSayisi;
/// Create a copy of KullaniciModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KullaniciModelCopyWith<KullaniciModel> get copyWith => _$KullaniciModelCopyWithImpl<KullaniciModel>(this as KullaniciModel, _$identity);

  /// Serializes this KullaniciModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KullaniciModel&&(identical(other.id, id) || other.id == id)&&(identical(other.adSoyad, adSoyad) || other.adSoyad == adSoyad)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl)&&(identical(other.telefon, telefon) || other.telefon == telefon)&&(identical(other.email, email) || other.email == email)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.profilTamamlandi, profilTamamlandi) || other.profilTamamlandi == profilTamamlandi)&&(identical(other.ortalamaPuan, ortalamaPuan) || other.ortalamaPuan == ortalamaPuan)&&(identical(other.degerlendirmeSayisi, degerlendirmeSayisi) || other.degerlendirmeSayisi == degerlendirmeSayisi)&&(identical(other.kullaniciTipi, kullaniciTipi) || other.kullaniciTipi == kullaniciTipi)&&(identical(other.yasadigiUlke, yasadigiUlke) || other.yasadigiUlke == yasadigiUlke)&&(identical(other.bulunduguSehir, bulunduguSehir) || other.bulunduguSehir == bulunduguSehir)&&const DeepCollectionEquality().equals(other.geldigiSehirler, geldigiSehirler)&&(identical(other.hakkinda, hakkinda) || other.hakkinda == hakkinda)&&(identical(other.sehir, sehir) || other.sehir == sehir)&&(identical(other.telefonGizli, telefonGizli) || other.telefonGizli == telefonGizli)&&const DeepCollectionEquality().equals(other.engellenenler, engellenenler)&&(identical(other.guvenSkoru, guvenSkoru) || other.guvenSkoru == guvenSkoru)&&const DeepCollectionEquality().equals(other.rozetler, rozetler)&&(identical(other.takipciSayisi, takipciSayisi) || other.takipciSayisi == takipciSayisi)&&(identical(other.takipSayisi, takipSayisi) || other.takipSayisi == takipSayisi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,adSoyad,fotoUrl,telefon,email,fcmToken,profilTamamlandi,ortalamaPuan,degerlendirmeSayisi,kullaniciTipi,yasadigiUlke,bulunduguSehir,const DeepCollectionEquality().hash(geldigiSehirler),hakkinda,sehir,telefonGizli,const DeepCollectionEquality().hash(engellenenler),guvenSkoru,const DeepCollectionEquality().hash(rozetler),takipciSayisi,takipSayisi]);

@override
String toString() {
  return 'KullaniciModel(id: $id, adSoyad: $adSoyad, fotoUrl: $fotoUrl, telefon: $telefon, email: $email, fcmToken: $fcmToken, profilTamamlandi: $profilTamamlandi, ortalamaPuan: $ortalamaPuan, degerlendirmeSayisi: $degerlendirmeSayisi, kullaniciTipi: $kullaniciTipi, yasadigiUlke: $yasadigiUlke, bulunduguSehir: $bulunduguSehir, geldigiSehirler: $geldigiSehirler, hakkinda: $hakkinda, sehir: $sehir, telefonGizli: $telefonGizli, engellenenler: $engellenenler, guvenSkoru: $guvenSkoru, rozetler: $rozetler, takipciSayisi: $takipciSayisi, takipSayisi: $takipSayisi)';
}


}

/// @nodoc
abstract mixin class $KullaniciModelCopyWith<$Res>  {
  factory $KullaniciModelCopyWith(KullaniciModel value, $Res Function(KullaniciModel) _then) = _$KullaniciModelCopyWithImpl;
@useResult
$Res call({
 String id, String adSoyad, String? fotoUrl, String? telefon, String? email, String? fcmToken, bool profilTamamlandi, double ortalamaPuan, int degerlendirmeSayisi, String kullaniciTipi, String yasadigiUlke, String bulunduguSehir, List<String> geldigiSehirler, String hakkinda, String sehir, bool telefonGizli, List<String> engellenenler, int guvenSkoru, List<String> rozetler, int takipciSayisi, int takipSayisi
});




}
/// @nodoc
class _$KullaniciModelCopyWithImpl<$Res>
    implements $KullaniciModelCopyWith<$Res> {
  _$KullaniciModelCopyWithImpl(this._self, this._then);

  final KullaniciModel _self;
  final $Res Function(KullaniciModel) _then;

/// Create a copy of KullaniciModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? adSoyad = null,Object? fotoUrl = freezed,Object? telefon = freezed,Object? email = freezed,Object? fcmToken = freezed,Object? profilTamamlandi = null,Object? ortalamaPuan = null,Object? degerlendirmeSayisi = null,Object? kullaniciTipi = null,Object? yasadigiUlke = null,Object? bulunduguSehir = null,Object? geldigiSehirler = null,Object? hakkinda = null,Object? sehir = null,Object? telefonGizli = null,Object? engellenenler = null,Object? guvenSkoru = null,Object? rozetler = null,Object? takipciSayisi = null,Object? takipSayisi = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adSoyad: null == adSoyad ? _self.adSoyad : adSoyad // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,telefon: freezed == telefon ? _self.telefon : telefon // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,profilTamamlandi: null == profilTamamlandi ? _self.profilTamamlandi : profilTamamlandi // ignore: cast_nullable_to_non_nullable
as bool,ortalamaPuan: null == ortalamaPuan ? _self.ortalamaPuan : ortalamaPuan // ignore: cast_nullable_to_non_nullable
as double,degerlendirmeSayisi: null == degerlendirmeSayisi ? _self.degerlendirmeSayisi : degerlendirmeSayisi // ignore: cast_nullable_to_non_nullable
as int,kullaniciTipi: null == kullaniciTipi ? _self.kullaniciTipi : kullaniciTipi // ignore: cast_nullable_to_non_nullable
as String,yasadigiUlke: null == yasadigiUlke ? _self.yasadigiUlke : yasadigiUlke // ignore: cast_nullable_to_non_nullable
as String,bulunduguSehir: null == bulunduguSehir ? _self.bulunduguSehir : bulunduguSehir // ignore: cast_nullable_to_non_nullable
as String,geldigiSehirler: null == geldigiSehirler ? _self.geldigiSehirler : geldigiSehirler // ignore: cast_nullable_to_non_nullable
as List<String>,hakkinda: null == hakkinda ? _self.hakkinda : hakkinda // ignore: cast_nullable_to_non_nullable
as String,sehir: null == sehir ? _self.sehir : sehir // ignore: cast_nullable_to_non_nullable
as String,telefonGizli: null == telefonGizli ? _self.telefonGizli : telefonGizli // ignore: cast_nullable_to_non_nullable
as bool,engellenenler: null == engellenenler ? _self.engellenenler : engellenenler // ignore: cast_nullable_to_non_nullable
as List<String>,guvenSkoru: null == guvenSkoru ? _self.guvenSkoru : guvenSkoru // ignore: cast_nullable_to_non_nullable
as int,rozetler: null == rozetler ? _self.rozetler : rozetler // ignore: cast_nullable_to_non_nullable
as List<String>,takipciSayisi: null == takipciSayisi ? _self.takipciSayisi : takipciSayisi // ignore: cast_nullable_to_non_nullable
as int,takipSayisi: null == takipSayisi ? _self.takipSayisi : takipSayisi // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [KullaniciModel].
extension KullaniciModelPatterns on KullaniciModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KullaniciModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KullaniciModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KullaniciModel value)  $default,){
final _that = this;
switch (_that) {
case _KullaniciModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KullaniciModel value)?  $default,){
final _that = this;
switch (_that) {
case _KullaniciModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String adSoyad,  String? fotoUrl,  String? telefon,  String? email,  String? fcmToken,  bool profilTamamlandi,  double ortalamaPuan,  int degerlendirmeSayisi,  String kullaniciTipi,  String yasadigiUlke,  String bulunduguSehir,  List<String> geldigiSehirler,  String hakkinda,  String sehir,  bool telefonGizli,  List<String> engellenenler,  int guvenSkoru,  List<String> rozetler,  int takipciSayisi,  int takipSayisi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KullaniciModel() when $default != null:
return $default(_that.id,_that.adSoyad,_that.fotoUrl,_that.telefon,_that.email,_that.fcmToken,_that.profilTamamlandi,_that.ortalamaPuan,_that.degerlendirmeSayisi,_that.kullaniciTipi,_that.yasadigiUlke,_that.bulunduguSehir,_that.geldigiSehirler,_that.hakkinda,_that.sehir,_that.telefonGizli,_that.engellenenler,_that.guvenSkoru,_that.rozetler,_that.takipciSayisi,_that.takipSayisi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String adSoyad,  String? fotoUrl,  String? telefon,  String? email,  String? fcmToken,  bool profilTamamlandi,  double ortalamaPuan,  int degerlendirmeSayisi,  String kullaniciTipi,  String yasadigiUlke,  String bulunduguSehir,  List<String> geldigiSehirler,  String hakkinda,  String sehir,  bool telefonGizli,  List<String> engellenenler,  int guvenSkoru,  List<String> rozetler,  int takipciSayisi,  int takipSayisi)  $default,) {final _that = this;
switch (_that) {
case _KullaniciModel():
return $default(_that.id,_that.adSoyad,_that.fotoUrl,_that.telefon,_that.email,_that.fcmToken,_that.profilTamamlandi,_that.ortalamaPuan,_that.degerlendirmeSayisi,_that.kullaniciTipi,_that.yasadigiUlke,_that.bulunduguSehir,_that.geldigiSehirler,_that.hakkinda,_that.sehir,_that.telefonGizli,_that.engellenenler,_that.guvenSkoru,_that.rozetler,_that.takipciSayisi,_that.takipSayisi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String adSoyad,  String? fotoUrl,  String? telefon,  String? email,  String? fcmToken,  bool profilTamamlandi,  double ortalamaPuan,  int degerlendirmeSayisi,  String kullaniciTipi,  String yasadigiUlke,  String bulunduguSehir,  List<String> geldigiSehirler,  String hakkinda,  String sehir,  bool telefonGizli,  List<String> engellenenler,  int guvenSkoru,  List<String> rozetler,  int takipciSayisi,  int takipSayisi)?  $default,) {final _that = this;
switch (_that) {
case _KullaniciModel() when $default != null:
return $default(_that.id,_that.adSoyad,_that.fotoUrl,_that.telefon,_that.email,_that.fcmToken,_that.profilTamamlandi,_that.ortalamaPuan,_that.degerlendirmeSayisi,_that.kullaniciTipi,_that.yasadigiUlke,_that.bulunduguSehir,_that.geldigiSehirler,_that.hakkinda,_that.sehir,_that.telefonGizli,_that.engellenenler,_that.guvenSkoru,_that.rozetler,_that.takipciSayisi,_that.takipSayisi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KullaniciModel implements KullaniciModel {
  const _KullaniciModel({required this.id, this.adSoyad = '', this.fotoUrl, this.telefon, this.email, this.fcmToken, this.profilTamamlandi = false, this.ortalamaPuan = 0.0, this.degerlendirmeSayisi = 0, this.kullaniciTipi = '', this.yasadigiUlke = '', this.bulunduguSehir = '', final  List<String> geldigiSehirler = const [], this.hakkinda = '', this.sehir = '', this.telefonGizli = false, final  List<String> engellenenler = const [], this.guvenSkoru = 0, final  List<String> rozetler = const [], this.takipciSayisi = 0, this.takipSayisi = 0}): _geldigiSehirler = geldigiSehirler,_engellenenler = engellenenler,_rozetler = rozetler;
  factory _KullaniciModel.fromJson(Map<String, dynamic> json) => _$KullaniciModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String adSoyad;
@override final  String? fotoUrl;
@override final  String? telefon;
@override final  String? email;
@override final  String? fcmToken;
@override@JsonKey() final  bool profilTamamlandi;
@override@JsonKey() final  double ortalamaPuan;
@override@JsonKey() final  int degerlendirmeSayisi;
@override@JsonKey() final  String kullaniciTipi;
@override@JsonKey() final  String yasadigiUlke;
@override@JsonKey() final  String bulunduguSehir;
 final  List<String> _geldigiSehirler;
@override@JsonKey() List<String> get geldigiSehirler {
  if (_geldigiSehirler is EqualUnmodifiableListView) return _geldigiSehirler;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_geldigiSehirler);
}

@override@JsonKey() final  String hakkinda;
@override@JsonKey() final  String sehir;
@override@JsonKey() final  bool telefonGizli;
 final  List<String> _engellenenler;
@override@JsonKey() List<String> get engellenenler {
  if (_engellenenler is EqualUnmodifiableListView) return _engellenenler;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_engellenenler);
}

@override@JsonKey() final  int guvenSkoru;
 final  List<String> _rozetler;
@override@JsonKey() List<String> get rozetler {
  if (_rozetler is EqualUnmodifiableListView) return _rozetler;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rozetler);
}

@override@JsonKey() final  int takipciSayisi;
@override@JsonKey() final  int takipSayisi;

/// Create a copy of KullaniciModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KullaniciModelCopyWith<_KullaniciModel> get copyWith => __$KullaniciModelCopyWithImpl<_KullaniciModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KullaniciModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KullaniciModel&&(identical(other.id, id) || other.id == id)&&(identical(other.adSoyad, adSoyad) || other.adSoyad == adSoyad)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl)&&(identical(other.telefon, telefon) || other.telefon == telefon)&&(identical(other.email, email) || other.email == email)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.profilTamamlandi, profilTamamlandi) || other.profilTamamlandi == profilTamamlandi)&&(identical(other.ortalamaPuan, ortalamaPuan) || other.ortalamaPuan == ortalamaPuan)&&(identical(other.degerlendirmeSayisi, degerlendirmeSayisi) || other.degerlendirmeSayisi == degerlendirmeSayisi)&&(identical(other.kullaniciTipi, kullaniciTipi) || other.kullaniciTipi == kullaniciTipi)&&(identical(other.yasadigiUlke, yasadigiUlke) || other.yasadigiUlke == yasadigiUlke)&&(identical(other.bulunduguSehir, bulunduguSehir) || other.bulunduguSehir == bulunduguSehir)&&const DeepCollectionEquality().equals(other._geldigiSehirler, _geldigiSehirler)&&(identical(other.hakkinda, hakkinda) || other.hakkinda == hakkinda)&&(identical(other.sehir, sehir) || other.sehir == sehir)&&(identical(other.telefonGizli, telefonGizli) || other.telefonGizli == telefonGizli)&&const DeepCollectionEquality().equals(other._engellenenler, _engellenenler)&&(identical(other.guvenSkoru, guvenSkoru) || other.guvenSkoru == guvenSkoru)&&const DeepCollectionEquality().equals(other._rozetler, _rozetler)&&(identical(other.takipciSayisi, takipciSayisi) || other.takipciSayisi == takipciSayisi)&&(identical(other.takipSayisi, takipSayisi) || other.takipSayisi == takipSayisi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,adSoyad,fotoUrl,telefon,email,fcmToken,profilTamamlandi,ortalamaPuan,degerlendirmeSayisi,kullaniciTipi,yasadigiUlke,bulunduguSehir,const DeepCollectionEquality().hash(_geldigiSehirler),hakkinda,sehir,telefonGizli,const DeepCollectionEquality().hash(_engellenenler),guvenSkoru,const DeepCollectionEquality().hash(_rozetler),takipciSayisi,takipSayisi]);

@override
String toString() {
  return 'KullaniciModel(id: $id, adSoyad: $adSoyad, fotoUrl: $fotoUrl, telefon: $telefon, email: $email, fcmToken: $fcmToken, profilTamamlandi: $profilTamamlandi, ortalamaPuan: $ortalamaPuan, degerlendirmeSayisi: $degerlendirmeSayisi, kullaniciTipi: $kullaniciTipi, yasadigiUlke: $yasadigiUlke, bulunduguSehir: $bulunduguSehir, geldigiSehirler: $geldigiSehirler, hakkinda: $hakkinda, sehir: $sehir, telefonGizli: $telefonGizli, engellenenler: $engellenenler, guvenSkoru: $guvenSkoru, rozetler: $rozetler, takipciSayisi: $takipciSayisi, takipSayisi: $takipSayisi)';
}


}

/// @nodoc
abstract mixin class _$KullaniciModelCopyWith<$Res> implements $KullaniciModelCopyWith<$Res> {
  factory _$KullaniciModelCopyWith(_KullaniciModel value, $Res Function(_KullaniciModel) _then) = __$KullaniciModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String adSoyad, String? fotoUrl, String? telefon, String? email, String? fcmToken, bool profilTamamlandi, double ortalamaPuan, int degerlendirmeSayisi, String kullaniciTipi, String yasadigiUlke, String bulunduguSehir, List<String> geldigiSehirler, String hakkinda, String sehir, bool telefonGizli, List<String> engellenenler, int guvenSkoru, List<String> rozetler, int takipciSayisi, int takipSayisi
});




}
/// @nodoc
class __$KullaniciModelCopyWithImpl<$Res>
    implements _$KullaniciModelCopyWith<$Res> {
  __$KullaniciModelCopyWithImpl(this._self, this._then);

  final _KullaniciModel _self;
  final $Res Function(_KullaniciModel) _then;

/// Create a copy of KullaniciModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? adSoyad = null,Object? fotoUrl = freezed,Object? telefon = freezed,Object? email = freezed,Object? fcmToken = freezed,Object? profilTamamlandi = null,Object? ortalamaPuan = null,Object? degerlendirmeSayisi = null,Object? kullaniciTipi = null,Object? yasadigiUlke = null,Object? bulunduguSehir = null,Object? geldigiSehirler = null,Object? hakkinda = null,Object? sehir = null,Object? telefonGizli = null,Object? engellenenler = null,Object? guvenSkoru = null,Object? rozetler = null,Object? takipciSayisi = null,Object? takipSayisi = null,}) {
  return _then(_KullaniciModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adSoyad: null == adSoyad ? _self.adSoyad : adSoyad // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,telefon: freezed == telefon ? _self.telefon : telefon // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,profilTamamlandi: null == profilTamamlandi ? _self.profilTamamlandi : profilTamamlandi // ignore: cast_nullable_to_non_nullable
as bool,ortalamaPuan: null == ortalamaPuan ? _self.ortalamaPuan : ortalamaPuan // ignore: cast_nullable_to_non_nullable
as double,degerlendirmeSayisi: null == degerlendirmeSayisi ? _self.degerlendirmeSayisi : degerlendirmeSayisi // ignore: cast_nullable_to_non_nullable
as int,kullaniciTipi: null == kullaniciTipi ? _self.kullaniciTipi : kullaniciTipi // ignore: cast_nullable_to_non_nullable
as String,yasadigiUlke: null == yasadigiUlke ? _self.yasadigiUlke : yasadigiUlke // ignore: cast_nullable_to_non_nullable
as String,bulunduguSehir: null == bulunduguSehir ? _self.bulunduguSehir : bulunduguSehir // ignore: cast_nullable_to_non_nullable
as String,geldigiSehirler: null == geldigiSehirler ? _self._geldigiSehirler : geldigiSehirler // ignore: cast_nullable_to_non_nullable
as List<String>,hakkinda: null == hakkinda ? _self.hakkinda : hakkinda // ignore: cast_nullable_to_non_nullable
as String,sehir: null == sehir ? _self.sehir : sehir // ignore: cast_nullable_to_non_nullable
as String,telefonGizli: null == telefonGizli ? _self.telefonGizli : telefonGizli // ignore: cast_nullable_to_non_nullable
as bool,engellenenler: null == engellenenler ? _self._engellenenler : engellenenler // ignore: cast_nullable_to_non_nullable
as List<String>,guvenSkoru: null == guvenSkoru ? _self.guvenSkoru : guvenSkoru // ignore: cast_nullable_to_non_nullable
as int,rozetler: null == rozetler ? _self._rozetler : rozetler // ignore: cast_nullable_to_non_nullable
as List<String>,takipciSayisi: null == takipciSayisi ? _self.takipciSayisi : takipciSayisi // ignore: cast_nullable_to_non_nullable
as int,takipSayisi: null == takipSayisi ? _self.takipSayisi : takipSayisi // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
