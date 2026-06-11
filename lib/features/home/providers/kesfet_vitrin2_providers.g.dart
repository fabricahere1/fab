// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kesfet_vitrin2_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kesfetTrendUrunler)
final kesfetTrendUrunlerProvider = KesfetTrendUrunlerProvider._();

final class KesfetTrendUrunlerProvider
    extends
        $FunctionalProvider<List<TrendUrun>, List<TrendUrun>, List<TrendUrun>>
    with $Provider<List<TrendUrun>> {
  KesfetTrendUrunlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kesfetTrendUrunlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kesfetTrendUrunlerHash();

  @$internal
  @override
  $ProviderElement<List<TrendUrun>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<TrendUrun> create(Ref ref) {
    return kesfetTrendUrunler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TrendUrun> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TrendUrun>>(value),
    );
  }
}

String _$kesfetTrendUrunlerHash() =>
    r'851099ce69bdef5b88081536b7b12b4bc3ac6771';

@ProviderFor(kesfetPopulerGuzergahlar)
final kesfetPopulerGuzergahlarProvider = KesfetPopulerGuzergahlarProvider._();

final class KesfetPopulerGuzergahlarProvider
    extends $FunctionalProvider<List<Guzergah>, List<Guzergah>, List<Guzergah>>
    with $Provider<List<Guzergah>> {
  KesfetPopulerGuzergahlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kesfetPopulerGuzergahlarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kesfetPopulerGuzergahlarHash();

  @$internal
  @override
  $ProviderElement<List<Guzergah>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Guzergah> create(Ref ref) {
    return kesfetPopulerGuzergahlar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Guzergah> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Guzergah>>(value),
    );
  }
}

String _$kesfetPopulerGuzergahlarHash() =>
    r'1c60f4064163099716379b26215fc93596c1fdde';

@ProviderFor(kesfetBuHaftaSehirler)
final kesfetBuHaftaSehirlerProvider = KesfetBuHaftaSehirlerProvider._();

final class KesfetBuHaftaSehirlerProvider
    extends
        $FunctionalProvider<
          List<SehirSatiri>,
          List<SehirSatiri>,
          List<SehirSatiri>
        >
    with $Provider<List<SehirSatiri>> {
  KesfetBuHaftaSehirlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kesfetBuHaftaSehirlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kesfetBuHaftaSehirlerHash();

  @$internal
  @override
  $ProviderElement<List<SehirSatiri>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SehirSatiri> create(Ref ref) {
    return kesfetBuHaftaSehirler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SehirSatiri> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SehirSatiri>>(value),
    );
  }
}

String _$kesfetBuHaftaSehirlerHash() =>
    r'71aceaf1d2a709f9860861eab75133e96947f438';
