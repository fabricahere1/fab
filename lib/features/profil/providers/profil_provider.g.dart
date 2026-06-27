// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profil_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(benimKullaniciProfil)
final benimKullaniciProfilProvider = BenimKullaniciProfilProvider._();

final class BenimKullaniciProfilProvider
    extends
        $FunctionalProvider<
          AsyncValue<KullaniciModel?>,
          KullaniciModel?,
          Stream<KullaniciModel?>
        >
    with $FutureModifier<KullaniciModel?>, $StreamProvider<KullaniciModel?> {
  BenimKullaniciProfilProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'benimKullaniciProfilProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$benimKullaniciProfilHash();

  @$internal
  @override
  $StreamProviderElement<KullaniciModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<KullaniciModel?> create(Ref ref) {
    return benimKullaniciProfil(ref);
  }
}

String _$benimKullaniciProfilHash() =>
    r'e314797fa190ba15dd6e6a3c0372faab0b413c72';

@ProviderFor(kullaniciBilgi)
final kullaniciBilgiProvider = KullaniciBilgiFamily._();

final class KullaniciBilgiProvider
    extends
        $FunctionalProvider<
          AsyncValue<KullaniciModel?>,
          KullaniciModel?,
          FutureOr<KullaniciModel?>
        >
    with $FutureModifier<KullaniciModel?>, $FutureProvider<KullaniciModel?> {
  KullaniciBilgiProvider._({
    required KullaniciBilgiFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciBilgiProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciBilgiHash();

  @override
  String toString() {
    return r'kullaniciBilgiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<KullaniciModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<KullaniciModel?> create(Ref ref) {
    final argument = this.argument as String;
    return kullaniciBilgi(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciBilgiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciBilgiHash() => r'c2705ee69ec2e345cc2c21ec16956b58a3422f99';

final class KullaniciBilgiFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<KullaniciModel?>, String> {
  KullaniciBilgiFamily._()
    : super(
        retry: null,
        name: r'kullaniciBilgiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  KullaniciBilgiProvider call(String uid) =>
      KullaniciBilgiProvider._(argument: uid, from: this);

  @override
  String toString() => r'kullaniciBilgiProvider';
}

@ProviderFor(ProfilDuzenle)
final profilDuzenleProvider = ProfilDuzenleProvider._();

final class ProfilDuzenleProvider
    extends $NotifierProvider<ProfilDuzenle, AsyncValue<void>> {
  ProfilDuzenleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilDuzenleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilDuzenleHash();

  @$internal
  @override
  ProfilDuzenle create() => ProfilDuzenle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$profilDuzenleHash() => r'917bdf57e283842dbd0e5c6ed982788f380ad7e9';

abstract class _$ProfilDuzenle extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Engelleme)
final engellemeProvider = EngellemeProvider._();

final class EngellemeProvider
    extends $NotifierProvider<Engelleme, AsyncValue<void>> {
  EngellemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engellemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engellemeHash();

  @$internal
  @override
  Engelleme create() => Engelleme();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$engellemeHash() => r'e471bc895a03b072d0b1fa3ec0fa56648f1c9141';

abstract class _$Engelleme extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(engellenenler)
final engellenenlerProvider = EngellenenlerProvider._();

final class EngellenenlerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  EngellenenlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engellenenlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engellenenlerHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return engellenenler(ref);
  }
}

String _$engellenenlerHash() => r'c75318ff134d7f08cd483e7cc5bd33b22293c3bd';

@ProviderFor(Sikayet)
final sikayetProvider = SikayetProvider._();

final class SikayetProvider
    extends $NotifierProvider<Sikayet, AsyncValue<void>> {
  SikayetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sikayetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sikayetHash();

  @$internal
  @override
  Sikayet create() => Sikayet();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$sikayetHash() => r'3785b707a0666b7295f2b8ae01f9e9f7342b6e9b';

abstract class _$Sikayet extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Kullanıcının kendi ilanlarını real-time dinler.
/// [keepAlive] sayesinde sayfa kapanınca dispose olmaz,
/// tekrar açılınca Firestore'a yeniden bağlanmaz.
/// uid null olduğunda (çıkış yapıldığında) provider invalidate edilir.

@ProviderFor(ilanlarim)
final ilanlarimProvider = IlanlarimProvider._();

/// Kullanıcının kendi ilanlarını real-time dinler.
/// [keepAlive] sayesinde sayfa kapanınca dispose olmaz,
/// tekrar açılınca Firestore'a yeniden bağlanmaz.
/// uid null olduğunda (çıkış yapıldığında) provider invalidate edilir.

final class IlanlarimProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IlanModel>>,
          List<IlanModel>,
          Stream<List<IlanModel>>
        >
    with $FutureModifier<List<IlanModel>>, $StreamProvider<List<IlanModel>> {
  /// Kullanıcının kendi ilanlarını real-time dinler.
  /// [keepAlive] sayesinde sayfa kapanınca dispose olmaz,
  /// tekrar açılınca Firestore'a yeniden bağlanmaz.
  /// uid null olduğunda (çıkış yapıldığında) provider invalidate edilir.
  IlanlarimProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ilanlarimProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ilanlarimHash();

  @$internal
  @override
  $StreamProviderElement<List<IlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<IlanModel>> create(Ref ref) {
    return ilanlarim(ref);
  }
}

String _$ilanlarimHash() => r'e4590c00e1002eb544b796ca09f105886a89ab59';

@ProviderFor(takipciIdleri)
final takipciIdleriProvider = TakipciIdleriFamily._();

final class TakipciIdleriProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  TakipciIdleriProvider._({
    required TakipciIdleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'takipciIdleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$takipciIdleriHash();

  @override
  String toString() {
    return r'takipciIdleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return takipciIdleri(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TakipciIdleriProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$takipciIdleriHash() => r'ee4fb3be5ef06950b82d857c905c07c083c234f2';

final class TakipciIdleriFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, String> {
  TakipciIdleriFamily._()
    : super(
        retry: null,
        name: r'takipciIdleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TakipciIdleriProvider call(String kullaniciId) =>
      TakipciIdleriProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'takipciIdleriProvider';
}

@ProviderFor(takipEdilenIdleri)
final takipEdilenIdleriProvider = TakipEdilenIdleriFamily._();

final class TakipEdilenIdleriProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  TakipEdilenIdleriProvider._({
    required TakipEdilenIdleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'takipEdilenIdleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$takipEdilenIdleriHash();

  @override
  String toString() {
    return r'takipEdilenIdleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return takipEdilenIdleri(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TakipEdilenIdleriProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$takipEdilenIdleriHash() => r'53515c95005fa69fcff5d987bbcd0189f17deea6';

final class TakipEdilenIdleriFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, String> {
  TakipEdilenIdleriFamily._()
    : super(
        retry: null,
        name: r'takipEdilenIdleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TakipEdilenIdleriProvider call(String kullaniciId) =>
      TakipEdilenIdleriProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'takipEdilenIdleriProvider';
}

/// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.

@ProviderFor(takipEdilenTarihleri)
final takipEdilenTarihleriProvider = TakipEdilenTarihleriFamily._();

/// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.

final class TakipEdilenTarihleriProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, DateTime>>,
          Map<String, DateTime>,
          Stream<Map<String, DateTime>>
        >
    with
        $FutureModifier<Map<String, DateTime>>,
        $StreamProvider<Map<String, DateTime>> {
  /// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.
  TakipEdilenTarihleriProvider._({
    required TakipEdilenTarihleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'takipEdilenTarihleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$takipEdilenTarihleriHash();

  @override
  String toString() {
    return r'takipEdilenTarihleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, DateTime>> create(Ref ref) {
    final argument = this.argument as String;
    return takipEdilenTarihleri(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TakipEdilenTarihleriProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$takipEdilenTarihleriHash() =>
    r'8dc98645fb42eb5ebb3d2176ccda0fdc177db366';

/// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.

final class TakipEdilenTarihleriFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, DateTime>>, String> {
  TakipEdilenTarihleriFamily._()
    : super(
        retry: null,
        name: r'takipEdilenTarihleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.

  TakipEdilenTarihleriProvider call(String kullaniciId) =>
      TakipEdilenTarihleriProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'takipEdilenTarihleriProvider';
}

/// 4.0 ve üzeri ortalama puana sahip taşıyıcılar (kendisi hariç).

@ProviderFor(yuksekPuanliTasiyicilar)
final yuksekPuanliTasiyicilarProvider = YuksekPuanliTasiyicilarProvider._();

/// 4.0 ve üzeri ortalama puana sahip taşıyıcılar (kendisi hariç).

final class YuksekPuanliTasiyicilarProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KullaniciModel>>,
          List<KullaniciModel>,
          FutureOr<List<KullaniciModel>>
        >
    with
        $FutureModifier<List<KullaniciModel>>,
        $FutureProvider<List<KullaniciModel>> {
  /// 4.0 ve üzeri ortalama puana sahip taşıyıcılar (kendisi hariç).
  YuksekPuanliTasiyicilarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'yuksekPuanliTasiyicilarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$yuksekPuanliTasiyicilarHash();

  @$internal
  @override
  $FutureProviderElement<List<KullaniciModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KullaniciModel>> create(Ref ref) {
    return yuksekPuanliTasiyicilar(ref);
  }
}

String _$yuksekPuanliTasiyicilarHash() =>
    r'9a9140d403db2f93ed0e051dc874b8a32ae25c6f';

/// 4.0 ve üzeri ortalama puana sahip istekçiler (kendisi hariç).

@ProviderFor(yuksekPuanliIstekciler)
final yuksekPuanliIstekcilerProvider = YuksekPuanliIstekcilerProvider._();

/// 4.0 ve üzeri ortalama puana sahip istekçiler (kendisi hariç).

final class YuksekPuanliIstekcilerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KullaniciModel>>,
          List<KullaniciModel>,
          FutureOr<List<KullaniciModel>>
        >
    with
        $FutureModifier<List<KullaniciModel>>,
        $FutureProvider<List<KullaniciModel>> {
  /// 4.0 ve üzeri ortalama puana sahip istekçiler (kendisi hariç).
  YuksekPuanliIstekcilerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'yuksekPuanliIstekcilerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$yuksekPuanliIstekcilerHash();

  @$internal
  @override
  $FutureProviderElement<List<KullaniciModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KullaniciModel>> create(Ref ref) {
    return yuksekPuanliIstekciler(ref);
  }
}

String _$yuksekPuanliIstekcilerHash() =>
    r'28282d9c305e57ba90b0475fbc9a6c7be1663598';

@ProviderFor(kullaniciBilgisi)
final kullaniciBilgisiProvider = KullaniciBilgisiFamily._();

final class KullaniciBilgisiProvider
    extends
        $FunctionalProvider<
          AsyncValue<KullaniciModel?>,
          KullaniciModel?,
          FutureOr<KullaniciModel?>
        >
    with $FutureModifier<KullaniciModel?>, $FutureProvider<KullaniciModel?> {
  KullaniciBilgisiProvider._({
    required KullaniciBilgisiFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciBilgisiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciBilgisiHash();

  @override
  String toString() {
    return r'kullaniciBilgisiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<KullaniciModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<KullaniciModel?> create(Ref ref) {
    final argument = this.argument as String;
    return kullaniciBilgisi(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciBilgisiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciBilgisiHash() => r'30553ff1b2be11234482d1c3921ac2b6d8eb0397';

final class KullaniciBilgisiFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<KullaniciModel?>, String> {
  KullaniciBilgisiFamily._()
    : super(
        retry: null,
        name: r'kullaniciBilgisiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KullaniciBilgisiProvider call(String uid) =>
      KullaniciBilgisiProvider._(argument: uid, from: this);

  @override
  String toString() => r'kullaniciBilgisiProvider';
}

@ProviderFor(OptimistikTakip)
final optimistikTakipProvider = OptimistikTakipProvider._();

final class OptimistikTakipProvider
    extends $NotifierProvider<OptimistikTakip, Map<String, bool>> {
  OptimistikTakipProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'optimistikTakipProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$optimistikTakipHash();

  @$internal
  @override
  OptimistikTakip create() => OptimistikTakip();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$optimistikTakipHash() => r'b347687a2ded5f8bcf6c26f13000d4c14a950da3';

abstract class _$OptimistikTakip extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(takipEdiyorMu)
final takipEdiyorMuProvider = TakipEdiyorMuFamily._();

final class TakipEdiyorMuProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  TakipEdiyorMuProvider._({
    required TakipEdiyorMuFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'takipEdiyorMuProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$takipEdiyorMuHash();

  @override
  String toString() {
    return r'takipEdiyorMuProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as String;
    return takipEdiyorMu(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TakipEdiyorMuProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$takipEdiyorMuHash() => r'1f89e5ebd027b26b1316601f0aee525ac23d16eb';

final class TakipEdiyorMuFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, String> {
  TakipEdiyorMuFamily._()
    : super(
        retry: null,
        name: r'takipEdiyorMuProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TakipEdiyorMuProvider call(String takipEdilenId) =>
      TakipEdiyorMuProvider._(argument: takipEdilenId, from: this);

  @override
  String toString() => r'takipEdiyorMuProvider';
}

@ProviderFor(TakipIslemleri)
final takipIslemleriProvider = TakipIslemleriProvider._();

final class TakipIslemleriProvider
    extends $NotifierProvider<TakipIslemleri, AsyncValue<void>> {
  TakipIslemleriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'takipIslemleriProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takipIslemleriHash();

  @$internal
  @override
  TakipIslemleri create() => TakipIslemleri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$takipIslemleriHash() => r'f85008a623b713f0b3cf6dfae0a7d461934bf159';

abstract class _$TakipIslemleri extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
