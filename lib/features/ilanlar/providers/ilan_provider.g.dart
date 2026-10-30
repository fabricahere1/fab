// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ilan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IstekIlanlar)
final istekIlanlarProvider = IstekIlanlarProvider._();

final class IstekIlanlarProvider
    extends $NotifierProvider<IstekIlanlar, IlanListeState> {
  IstekIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'istekIlanlarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$istekIlanlarHash();

  @$internal
  @override
  IstekIlanlar create() => IstekIlanlar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IlanListeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IlanListeState>(value),
    );
  }
}

String _$istekIlanlarHash() => r'82bcbb2d5c4d0027c2a20cbf0e04b9baaed10f9b';

abstract class _$IstekIlanlar extends $Notifier<IlanListeState> {
  IlanListeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<IlanListeState, IlanListeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IlanListeState, IlanListeState>,
              IlanListeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(TasiyiciIlanlar)
final tasiyiciIlanlarProvider = TasiyiciIlanlarProvider._();

final class TasiyiciIlanlarProvider
    extends $NotifierProvider<TasiyiciIlanlar, IlanListeState> {
  TasiyiciIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tasiyiciIlanlarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tasiyiciIlanlarHash();

  @$internal
  @override
  TasiyiciIlanlar create() => TasiyiciIlanlar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IlanListeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IlanListeState>(value),
    );
  }
}

String _$tasiyiciIlanlarHash() => r'0b4dfa2103f8fff2d0c2a237afb38447363cf6d1';

abstract class _$TasiyiciIlanlar extends $Notifier<IlanListeState> {
  IlanListeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<IlanListeState, IlanListeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IlanListeState, IlanListeState>,
              IlanListeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(IlanOlustur)
final ilanOlusturProvider = IlanOlusturProvider._();

final class IlanOlusturProvider
    extends $NotifierProvider<IlanOlustur, IlanOlusturState> {
  IlanOlusturProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ilanOlusturProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ilanOlusturHash();

  @$internal
  @override
  IlanOlustur create() => IlanOlustur();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IlanOlusturState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IlanOlusturState>(value),
    );
  }
}

String _$ilanOlusturHash() => r'6e6f7691ddd5b0f570d6e0c887f919d7c219ec22';

abstract class _$IlanOlustur extends $Notifier<IlanOlusturState> {
  IlanOlusturState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<IlanOlusturState, IlanOlusturState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IlanOlusturState, IlanOlusturState>,
              IlanOlusturState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ilanById)
final ilanByIdProvider = IlanByIdFamily._();

final class IlanByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<IlanModel?>,
          IlanModel?,
          FutureOr<IlanModel?>
        >
    with $FutureModifier<IlanModel?>, $FutureProvider<IlanModel?> {
  IlanByIdProvider._({
    required IlanByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ilanByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ilanByIdHash();

  @override
  String toString() {
    return r'ilanByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<IlanModel?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<IlanModel?> create(Ref ref) {
    final argument = this.argument as String;
    return ilanById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IlanByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ilanByIdHash() => r'53e8aa75e26a198dc3de0e918b3c41f52cbb9205';

final class IlanByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<IlanModel?>, String> {
  IlanByIdFamily._()
    : super(
        retry: null,
        name: r'ilanByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IlanByIdProvider call(String ilanId) =>
      IlanByIdProvider._(argument: ilanId, from: this);

  @override
  String toString() => r'ilanByIdProvider';
}

@ProviderFor(son24SaatIlanlar)
final son24SaatIlanlarProvider = Son24SaatIlanlarProvider._();

final class Son24SaatIlanlarProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IlanModel>>,
          List<IlanModel>,
          FutureOr<List<IlanModel>>
        >
    with $FutureModifier<List<IlanModel>>, $FutureProvider<List<IlanModel>> {
  Son24SaatIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'son24SaatIlanlarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$son24SaatIlanlarHash();

  @$internal
  @override
  $FutureProviderElement<List<IlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IlanModel>> create(Ref ref) {
    return son24SaatIlanlar(ref);
  }
}

String _$son24SaatIlanlarHash() => r'fd977ab21f94538d7d39f8cb091b0be974f250da';

@ProviderFor(haftaninEnleri)
final haftaninEnleriProvider = HaftaninEnleriProvider._();

final class HaftaninEnleriProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IlanModel>>,
          List<IlanModel>,
          FutureOr<List<IlanModel>>
        >
    with $FutureModifier<List<IlanModel>>, $FutureProvider<List<IlanModel>> {
  HaftaninEnleriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'haftaninEnleriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$haftaninEnleriHash();

  @$internal
  @override
  $FutureProviderElement<List<IlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IlanModel>> create(Ref ref) {
    return haftaninEnleri(ref);
  }
}

String _$haftaninEnleriHash() => r'9f01918edefcd89d9674cafd1586e6e0e8314f3e';

@ProviderFor(favoriler)
final favorilerProvider = FavorilerProvider._();

final class FavorilerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IlanModel>>,
          List<IlanModel>,
          FutureOr<List<IlanModel>>
        >
    with $FutureModifier<List<IlanModel>>, $FutureProvider<List<IlanModel>> {
  FavorilerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favorilerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favorilerHash();

  @$internal
  @override
  $FutureProviderElement<List<IlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IlanModel>> create(Ref ref) {
    return favoriler(ref);
  }
}

String _$favorilerHash() => r'69ca1ccb80e1dac87f72e01ed3be5a01ce3b83cb';

@ProviderFor(kullaniciIlanlariGetir)
final kullaniciIlanlariGetirProvider = KullaniciIlanlariGetirFamily._();

final class KullaniciIlanlariGetirProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IlanModel>>,
          List<IlanModel>,
          FutureOr<List<IlanModel>>
        >
    with $FutureModifier<List<IlanModel>>, $FutureProvider<List<IlanModel>> {
  KullaniciIlanlariGetirProvider._({
    required KullaniciIlanlariGetirFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciIlanlariGetirProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciIlanlariGetirHash();

  @override
  String toString() {
    return r'kullaniciIlanlariGetirProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<IlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IlanModel>> create(Ref ref) {
    final argument = this.argument as String;
    return kullaniciIlanlariGetir(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciIlanlariGetirProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciIlanlariGetirHash() =>
    r'40674f2bbc450d1e4594d8651605a551d81d7e1a';

final class KullaniciIlanlariGetirFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<IlanModel>>, String> {
  KullaniciIlanlariGetirFamily._()
    : super(
        retry: null,
        name: r'kullaniciIlanlariGetirProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KullaniciIlanlariGetirProvider call(String kullaniciId) =>
      KullaniciIlanlariGetirProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'kullaniciIlanlariGetirProvider';
}

@ProviderFor(BreadcrumbIlanTipi)
final breadcrumbIlanTipiProvider = BreadcrumbIlanTipiProvider._();

final class BreadcrumbIlanTipiProvider
    extends $NotifierProvider<BreadcrumbIlanTipi, String> {
  BreadcrumbIlanTipiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'breadcrumbIlanTipiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$breadcrumbIlanTipiHash();

  @$internal
  @override
  BreadcrumbIlanTipi create() => BreadcrumbIlanTipi();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$breadcrumbIlanTipiHash() =>
    r'4e290bcb51baabe96a24bc01ecb9794b8a78c9dc';

abstract class _$BreadcrumbIlanTipi extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(BreadcrumbKategoriFiltresi)
final breadcrumbKategoriFiltresiProvider =
    BreadcrumbKategoriFiltresiProvider._();

final class BreadcrumbKategoriFiltresiProvider
    extends $NotifierProvider<BreadcrumbKategoriFiltresi, List<String>> {
  BreadcrumbKategoriFiltresiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'breadcrumbKategoriFiltresiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$breadcrumbKategoriFiltresiHash();

  @$internal
  @override
  BreadcrumbKategoriFiltresi create() => BreadcrumbKategoriFiltresi();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$breadcrumbKategoriFiltresiHash() =>
    r'0eb767c7360362aa66bf18e36804691eda81066a';

abstract class _$BreadcrumbKategoriFiltresi extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SayacDelta)
final sayacDeltaProvider = SayacDeltaProvider._();

final class SayacDeltaProvider
    extends $NotifierProvider<SayacDelta, SayacDeltaState> {
  SayacDeltaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sayacDeltaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sayacDeltaHash();

  @$internal
  @override
  SayacDelta create() => SayacDelta();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SayacDeltaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SayacDeltaState>(value),
    );
  }
}

String _$sayacDeltaHash() => r'a835b1523963d49d598f49e8bfa77e0e57e68ffb';

abstract class _$SayacDelta extends $Notifier<SayacDeltaState> {
  SayacDeltaState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SayacDeltaState, SayacDeltaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SayacDeltaState, SayacDeltaState>,
              SayacDeltaState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(OptimistikFavori)
final optimistikFavoriProvider = OptimistikFavoriProvider._();

final class OptimistikFavoriProvider
    extends $NotifierProvider<OptimistikFavori, Map<String, bool>> {
  OptimistikFavoriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'optimistikFavoriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$optimistikFavoriHash();

  @$internal
  @override
  OptimistikFavori create() => OptimistikFavori();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$optimistikFavoriHash() => r'f583497affb1f1da58a218fb61bc14e8a127a080';

abstract class _$OptimistikFavori extends $Notifier<Map<String, bool>> {
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

@ProviderFor(favoriliIlanIdler)
final favoriliIlanIdlerProvider = FavoriliIlanIdlerProvider._();

final class FavoriliIlanIdlerProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  FavoriliIlanIdlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriliIlanIdlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriliIlanIdlerHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return favoriliIlanIdler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$favoriliIlanIdlerHash() => r'cde10325a9c8e9ffb8df79ad2ae9d6d6341eb2ea';

/// Eski Stream&lt;bool&gt; favorideMi provider'ının yerini alıyor —
/// favoriliIlanIdler zaten senkron ve polling'e göre daha ucuz.

@ProviderFor(ilanFavorideMi)
final ilanFavorideMiProvider = IlanFavorideMiFamily._();

/// Eski Stream&lt;bool&gt; favorideMi provider'ının yerini alıyor —
/// favoriliIlanIdler zaten senkron ve polling'e göre daha ucuz.

final class IlanFavorideMiProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Eski Stream&lt;bool&gt; favorideMi provider'ının yerini alıyor —
  /// favoriliIlanIdler zaten senkron ve polling'e göre daha ucuz.
  IlanFavorideMiProvider._({
    required IlanFavorideMiFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ilanFavorideMiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ilanFavorideMiHash();

  @override
  String toString() {
    return r'ilanFavorideMiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return ilanFavorideMi(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IlanFavorideMiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ilanFavorideMiHash() => r'38736276518ed136020323c7d0f4798b1bc64b5f';

/// Eski Stream&lt;bool&gt; favorideMi provider'ının yerini alıyor —
/// favoriliIlanIdler zaten senkron ve polling'e göre daha ucuz.

final class IlanFavorideMiFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IlanFavorideMiFamily._()
    : super(
        retry: null,
        name: r'ilanFavorideMiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Eski Stream&lt;bool&gt; favorideMi provider'ının yerini alıyor —
  /// favoriliIlanIdler zaten senkron ve polling'e göre daha ucuz.

  IlanFavorideMiProvider call(String ilanId) =>
      IlanFavorideMiProvider._(argument: ilanId, from: this);

  @override
  String toString() => r'ilanFavorideMiProvider';
}

@ProviderFor(FavoriNotifier)
final favoriProvider = FavoriNotifierProvider._();

final class FavoriNotifierProvider
    extends $NotifierProvider<FavoriNotifier, AsyncValue<void>> {
  FavoriNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriNotifierHash();

  @$internal
  @override
  FavoriNotifier create() => FavoriNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$favoriNotifierHash() => r'9b7987c3fd609e9c8d87fc4bd091cea176a2abea';

abstract class _$FavoriNotifier extends $Notifier<AsyncValue<void>> {
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

@ProviderFor(IlanIslemleri)
final ilanIslemleriProvider = IlanIslemleriProvider._();

final class IlanIslemleriProvider
    extends $NotifierProvider<IlanIslemleri, AsyncValue<void>> {
  IlanIslemleriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ilanIslemleriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ilanIslemleriHash();

  @$internal
  @override
  IlanIslemleri create() => IlanIslemleri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$ilanIslemleriHash() => r'29036ec2ee930bb74c784f78fb48e08de912ac48';

abstract class _$IlanIslemleri extends $Notifier<AsyncValue<void>> {
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

@ProviderFor(NavBarGizli)
final navBarGizliProvider = NavBarGizliProvider._();

final class NavBarGizliProvider extends $NotifierProvider<NavBarGizli, bool> {
  NavBarGizliProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navBarGizliProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navBarGizliHash();

  @$internal
  @override
  NavBarGizli create() => NavBarGizli();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$navBarGizliHash() => r'1057d3da606757c7f46b024f8ba1c00932e49d2e';

abstract class _$NavBarGizli extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
