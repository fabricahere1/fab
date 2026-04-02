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

String _$istekIlanlarHash() => r'819f96fe90d3b17728ca9c88b750f9fd11df1f34';

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

String _$tasiyiciIlanlarHash() => r'1d1c1a3c58f241233929d7a00d89c00828fb76a1';

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
