// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bildirim_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Bildirimler)
final bildirimlerProvider = BildirimlerProvider._();

final class BildirimlerProvider
    extends $AsyncNotifierProvider<Bildirimler, List<BildirimModel>> {
  BildirimlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bildirimlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bildirimlerHash();

  @$internal
  @override
  Bildirimler create() => Bildirimler();
}

String _$bildirimlerHash() => r'0a9e79c74b95ee7bc672ac48b635c34e6a4edbfd';

abstract class _$Bildirimler extends $AsyncNotifier<List<BildirimModel>> {
  FutureOr<List<BildirimModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BildirimModel>>, List<BildirimModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BildirimModel>>, List<BildirimModel>>,
              AsyncValue<List<BildirimModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(OkunmamisBildirimSayi)
final okunmamisBildirimSayiProvider = OkunmamisBildirimSayiProvider._();

final class OkunmamisBildirimSayiProvider
    extends $AsyncNotifierProvider<OkunmamisBildirimSayi, int> {
  OkunmamisBildirimSayiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'okunmamisBildirimSayiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$okunmamisBildirimSayiHash();

  @$internal
  @override
  OkunmamisBildirimSayi create() => OkunmamisBildirimSayi();
}

String _$okunmamisBildirimSayiHash() =>
    r'295cd106ee0c7e69e779369b5e464b0efc4ede80';

abstract class _$OkunmamisBildirimSayi extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Bildirim işlemleri — okuma, silme.

@ProviderFor(BildirimNotifier)
final bildirimProvider = BildirimNotifierProvider._();

/// Bildirim işlemleri — okuma, silme.
final class BildirimNotifierProvider
    extends $NotifierProvider<BildirimNotifier, AsyncValue<void>> {
  /// Bildirim işlemleri — okuma, silme.
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

String _$bildirimNotifierHash() => r'7bcada0ef69065f4d489d2569ab839f06e32ecec';

/// Bildirim işlemleri — okuma, silme.

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
