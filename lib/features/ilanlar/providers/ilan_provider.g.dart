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
        isAutoDispose: true,
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

String _$istekIlanlarHash() => r'da7b0a73b47907c9d269a98f00748d40ca3ea0dd';

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

String _$tasiyiciIlanlarHash() => r'7eab74c145453fc8d54b38ce251e5a1bcf28e5fe';

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

String _$ilanOlusturHash() => r'd041787584c84d5897fc5edc0ac70e0e73d7cfce';

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
          Stream<IlanModel?>
        >
    with $FutureModifier<IlanModel?>, $StreamProvider<IlanModel?> {
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
  $StreamProviderElement<IlanModel?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<IlanModel?> create(Ref ref) {
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

String _$ilanByIdHash() => r'8d240a8d24b31e8adc4a01b60f7877f170ffc24d';

final class IlanByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<IlanModel?>, String> {
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

@ProviderFor(favoriler)
final favorilerProvider = FavorilerProvider._();

final class FavorilerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
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
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return favoriler(ref);
  }
}

String _$favorilerHash() => r'f68b10f139c1a84397778ace385f4dc2d904c3f0';

@ProviderFor(ilanFavorideMi)
final ilanFavorideMiProvider = IlanFavorideMiFamily._();

final class IlanFavorideMiProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
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
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as String;
    return ilanFavorideMi(ref, argument);
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

String _$ilanFavorideMiHash() => r'39086f5abf7d8fd9fd72c73f57260652e945e9a4';

final class IlanFavorideMiFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, String> {
  IlanFavorideMiFamily._()
    : super(
        retry: null,
        name: r'ilanFavorideMiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IlanFavorideMiProvider call(String ilanId) =>
      IlanFavorideMiProvider._(argument: ilanId, from: this);

  @override
  String toString() => r'ilanFavorideMiProvider';
}

@ProviderFor(kullaniciIlanlarStream)
final kullaniciIlanlarStreamProvider = KullaniciIlanlarStreamFamily._();

final class KullaniciIlanlarStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IlanModel>>,
          List<IlanModel>,
          Stream<List<IlanModel>>
        >
    with $FutureModifier<List<IlanModel>>, $StreamProvider<List<IlanModel>> {
  KullaniciIlanlarStreamProvider._({
    required KullaniciIlanlarStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciIlanlarStreamProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciIlanlarStreamHash();

  @override
  String toString() {
    return r'kullaniciIlanlarStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<IlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<IlanModel>> create(Ref ref) {
    final argument = this.argument as String;
    return kullaniciIlanlarStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciIlanlarStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciIlanlarStreamHash() =>
    r'708ffde71c4c9d4e00c11355ac2a56e56c834c6b';

final class KullaniciIlanlarStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<IlanModel>>, String> {
  KullaniciIlanlarStreamFamily._()
    : super(
        retry: null,
        name: r'kullaniciIlanlarStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  KullaniciIlanlarStreamProvider call(String kullaniciId) =>
      KullaniciIlanlarStreamProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'kullaniciIlanlarStreamProvider';
}

@ProviderFor(ilanFavoriSayisi)
final ilanFavoriSayisiProvider = IlanFavoriSayisiFamily._();

final class IlanFavoriSayisiProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  IlanFavoriSayisiProvider._({
    required IlanFavoriSayisiFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ilanFavoriSayisiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ilanFavoriSayisiHash();

  @override
  String toString() {
    return r'ilanFavoriSayisiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return ilanFavoriSayisi(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IlanFavoriSayisiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ilanFavoriSayisiHash() => r'6b53d2c725b07deadb774514c62f9782a19772f7';

final class IlanFavoriSayisiFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  IlanFavoriSayisiFamily._()
    : super(
        retry: null,
        name: r'ilanFavoriSayisiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IlanFavoriSayisiProvider call(String ilanId) =>
      IlanFavoriSayisiProvider._(argument: ilanId, from: this);

  @override
  String toString() => r'ilanFavoriSayisiProvider';
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

String _$favoriliIlanIdlerHash() => r'a18c9f8fac3da1192de2351098dcbea327a3aaaf';

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
        isAutoDispose: true,
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

String _$favoriNotifierHash() => r'acf9c4eca2bc807bc3f564124d6e96f437789db9';

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

String _$ilanIslemleriHash() => r'2e5fd37f316269be1446756b0c7887944de02367';

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
