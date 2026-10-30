// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'degerlendirme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bekleyenDegerlendirmelerim)
final bekleyenDegerlendirmelerimProvider =
    BekleyenDegerlendirmelerimProvider._();

final class BekleyenDegerlendirmelerimProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BekleyenDegerlendirme>>,
          List<BekleyenDegerlendirme>,
          FutureOr<List<BekleyenDegerlendirme>>
        >
    with
        $FutureModifier<List<BekleyenDegerlendirme>>,
        $FutureProvider<List<BekleyenDegerlendirme>> {
  BekleyenDegerlendirmelerimProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bekleyenDegerlendirmelerimProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bekleyenDegerlendirmelerimHash();

  @$internal
  @override
  $FutureProviderElement<List<BekleyenDegerlendirme>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BekleyenDegerlendirme>> create(Ref ref) {
    return bekleyenDegerlendirmelerim(ref);
  }
}

String _$bekleyenDegerlendirmelerimHash() =>
    r'4e7925177ac3f6b8dc201a2eaa7b796bc18cb9d1';

@ProviderFor(KullaniciDegerlendirmeleri)
final kullaniciDegerlendirmeleriProvider = KullaniciDegerlendirmeleriFamily._();

final class KullaniciDegerlendirmeleriProvider
    extends
        $NotifierProvider<KullaniciDegerlendirmeleri, DegerlendirmeListeState> {
  KullaniciDegerlendirmeleriProvider._({
    required KullaniciDegerlendirmeleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciDegerlendirmeleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciDegerlendirmeleriHash();

  @override
  String toString() {
    return r'kullaniciDegerlendirmeleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  KullaniciDegerlendirmeleri create() => KullaniciDegerlendirmeleri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DegerlendirmeListeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DegerlendirmeListeState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciDegerlendirmeleriProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciDegerlendirmeleriHash() =>
    r'9f0a0f0f2e038e7fbb01f29d3f789d650dc4f8fe';

final class KullaniciDegerlendirmeleriFamily extends $Family
    with
        $ClassFamilyOverride<
          KullaniciDegerlendirmeleri,
          DegerlendirmeListeState,
          DegerlendirmeListeState,
          DegerlendirmeListeState,
          String
        > {
  KullaniciDegerlendirmeleriFamily._()
    : super(
        retry: null,
        name: r'kullaniciDegerlendirmeleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KullaniciDegerlendirmeleriProvider call(String kullaniciId) =>
      KullaniciDegerlendirmeleriProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'kullaniciDegerlendirmeleriProvider';
}

abstract class _$KullaniciDegerlendirmeleri
    extends $Notifier<DegerlendirmeListeState> {
  late final _$args = ref.$arg as String;
  String get kullaniciId => _$args;

  DegerlendirmeListeState build(String kullaniciId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<DegerlendirmeListeState, DegerlendirmeListeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DegerlendirmeListeState, DegerlendirmeListeState>,
              DegerlendirmeListeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(DegerlendirmeIslemleri)
final degerlendirmeIslemleriProvider = DegerlendirmeIslemleriProvider._();

final class DegerlendirmeIslemleriProvider
    extends $NotifierProvider<DegerlendirmeIslemleri, AsyncValue<void>> {
  DegerlendirmeIslemleriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'degerlendirmeIslemleriProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$degerlendirmeIslemleriHash();

  @$internal
  @override
  DegerlendirmeIslemleri create() => DegerlendirmeIslemleri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$degerlendirmeIslemleriHash() =>
    r'5520b0a13b98653beea3a3177769efb216e11eca';

abstract class _$DegerlendirmeIslemleri extends $Notifier<AsyncValue<void>> {
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
