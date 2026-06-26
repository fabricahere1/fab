// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bildirim_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kullanıcının tüm bildirimlerini real-time dinler.
/// uid değişince (hesap geçişi) provider otomatik yeniden başlar.

@ProviderFor(bildirimler)
final bildirimlerProvider = BildirimlerProvider._();

/// Kullanıcının tüm bildirimlerini real-time dinler.
/// uid değişince (hesap geçişi) provider otomatik yeniden başlar.

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
  /// uid değişince (hesap geçişi) provider otomatik yeniden başlar.
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

/// Okunmamış bildirim sayısı — navigation badge için.

@ProviderFor(okunmamisBildirimSayi)
final okunmamisBildirimSayiProvider = OkunmamisBildirimSayiProvider._();

/// Okunmamış bildirim sayısı — navigation badge için.

final class OkunmamisBildirimSayiProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Okunmamış bildirim sayısı — navigation badge için.
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
    r'c74335f3f0c942d6b4dd8b3014ffdf11e9c1718f';

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

String _$bildirimNotifierHash() => r'c8d49d604f3d2a3902a29f059d2fbfadf9f1c841';

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
