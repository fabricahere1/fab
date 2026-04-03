// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bildirim_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bildirimler)
final bildirimlerProvider = BildirimlerProvider._();

final class BildirimlerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BildirimModel>>,
          List<BildirimModel>,
          Stream<List<BildirimModel>>
        >
    with
        $FutureModifier<List<BildirimModel>>,
        $StreamProvider<List<BildirimModel>> {
  BildirimlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bildirimlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bildirimlerHash();

  @$internal
  @override
  $StreamProviderElement<List<BildirimModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BildirimModel>> create(Ref ref) {
    return bildirimler(ref);
  }
}

String _$bildirimlerHash() => r'45abe9374d338b31e4996cdb3c707a4106b0db9e';

@ProviderFor(okunmamisBildirimSayi)
final okunmamisBildirimSayiProvider = OkunmamisBildirimSayiProvider._();

final class OkunmamisBildirimSayiProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  OkunmamisBildirimSayiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'okunmamisBildirimSayiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$okunmamisBildirimSayiHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return okunmamisBildirimSayi(ref);
  }
}

String _$okunmamisBildirimSayiHash() =>
    r'bfdc7c2f50fd3e153e24feb49b74bbd3475d261c';

@ProviderFor(BildirimNotifier)
final bildirimProvider = BildirimNotifierProvider._();

final class BildirimNotifierProvider
    extends $NotifierProvider<BildirimNotifier, AsyncValue<void>> {
  BildirimNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bildirimProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bildirimNotifierHash();

  @$internal
  @override
  BildirimNotifier create() => BildirimNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$bildirimNotifierHash() => r'58716c69da41fa2e07ed1e6db13972e4d6b84909';

abstract class _$BildirimNotifier extends $Notifier<AsyncValue<void>> {
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
