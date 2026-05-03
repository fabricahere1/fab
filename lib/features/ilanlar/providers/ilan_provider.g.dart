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

String _$istekIlanlarHash() => r'8d5ac178bb07d5a3b13d0b32ffd9e3dab02a7e2b';

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
        isAutoDispose: true,
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

String _$tasiyiciIlanlarHash() => r'6997248c77caf1538c79e3824c96a395122aed39';

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
        isAutoDispose: true,
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

String _$ilanOlusturHash() => r'a2cae6a720e7f66be2e0332357a5d0d17167bda1';

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

/// Sadece ilanId ile Firestore'dan güncel ilan verisini izler.
/// IlanDetayScreen bu provider'ı kullanır.

@ProviderFor(ilanById)
final ilanByIdProvider = IlanByIdFamily._();

/// Sadece ilanId ile Firestore'dan güncel ilan verisini izler.
/// IlanDetayScreen bu provider'ı kullanır.

final class IlanByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<IlanModel?>,
          IlanModel?,
          Stream<IlanModel?>
        >
    with $FutureModifier<IlanModel?>, $StreamProvider<IlanModel?> {
  /// Sadece ilanId ile Firestore'dan güncel ilan verisini izler.
  /// IlanDetayScreen bu provider'ı kullanır.
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

/// Sadece ilanId ile Firestore'dan güncel ilan verisini izler.
/// IlanDetayScreen bu provider'ı kullanır.

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

  /// Sadece ilanId ile Firestore'dan güncel ilan verisini izler.
  /// IlanDetayScreen bu provider'ı kullanır.

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
         isAutoDispose: true,
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
    r'a77ed489851dce352f3d8a361c56e258163b1e90';

final class KullaniciIlanlarStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<IlanModel>>, String> {
  KullaniciIlanlarStreamFamily._()
    : super(
        retry: null,
        name: r'kullaniciIlanlarStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
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
