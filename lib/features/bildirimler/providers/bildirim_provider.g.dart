// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bildirim_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kullanıcının tüm bildirimlerini real-time dinler.
/// [keepAlive] ile tab değişimlerinde dispose olmaz, Firestore bağlantısı korunur.
/// uid null olduğunda (çıkış yapıldığında) provider temizlenir.

@ProviderFor(bildirimler)
final bildirimlerProvider = BildirimlerProvider._();

/// Kullanıcının tüm bildirimlerini real-time dinler.
/// [keepAlive] ile tab değişimlerinde dispose olmaz, Firestore bağlantısı korunur.
/// uid null olduğunda (çıkış yapıldığında) provider temizlenir.

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
  /// Kullanıcının tüm bildirimlerini real-time dinler.
  /// [keepAlive] ile tab değişimlerinde dispose olmaz, Firestore bağlantısı korunur.
  /// uid null olduğunda (çıkış yapıldığında) provider temizlenir.
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
  $StreamProviderElement<List<BildirimModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BildirimModel>> create(Ref ref) {
    return bildirimler(ref);
  }
}

String _$bildirimlerHash() => r'818b64acbaad44d1503e5214dd93b3ea15cb31b3';

/// Okunmamış bildirim sayısı — navigation badge için.
/// [keepAlive] ile uygulama boyunca aktif kalır.

@ProviderFor(okunmamisBildirimSayi)
final okunmamisBildirimSayiProvider = OkunmamisBildirimSayiProvider._();

/// Okunmamış bildirim sayısı — navigation badge için.
/// [keepAlive] ile uygulama boyunca aktif kalır.

final class OkunmamisBildirimSayiProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Okunmamış bildirim sayısı — navigation badge için.
  /// [keepAlive] ile uygulama boyunca aktif kalır.
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
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return okunmamisBildirimSayi(ref);
  }
}

String _$okunmamisBildirimSayiHash() =>
    r'b4f591d0a85ca7d718686a3b1c54179f1c9428d5';

/// Bildirim işlemleri — okuma, silme, gönderme.

@ProviderFor(BildirimNotifier)
final bildirimProvider = BildirimNotifierProvider._();

/// Bildirim işlemleri — okuma, silme, gönderme.
final class BildirimNotifierProvider
    extends $NotifierProvider<BildirimNotifier, AsyncValue<void>> {
  /// Bildirim işlemleri — okuma, silme, gönderme.
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

/// Bildirim işlemleri — okuma, silme, gönderme.

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
