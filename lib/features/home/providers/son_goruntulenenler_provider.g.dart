// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'son_goruntulenenler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SonGoruntulenenler)
final sonGoruntulenenlerProvider = SonGoruntulenenlerProvider._();

final class SonGoruntulenenlerProvider
    extends $NotifierProvider<SonGoruntulenenler, List<IlanModel>> {
  SonGoruntulenenlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonGoruntulenenlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonGoruntulenenlerHash();

  @$internal
  @override
  SonGoruntulenenler create() => SonGoruntulenenler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$sonGoruntulenenlerHash() =>
    r'16150b00db55fd6ed3a233371615115b4ce3d36d';

abstract class _$SonGoruntulenenler extends $Notifier<List<IlanModel>> {
  List<IlanModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<IlanModel>, List<IlanModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<IlanModel>, List<IlanModel>>,
              List<IlanModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(sonGoruntulenenlerListesi)
final sonGoruntulenenlerListesiProvider = SonGoruntulenenlerListesiProvider._();

final class SonGoruntulenenlerListesiProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  SonGoruntulenenlerListesiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonGoruntulenenlerListesiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonGoruntulenenlerListesiHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return sonGoruntulenenlerListesi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$sonGoruntulenenlerListesiHash() =>
    r'1bee174e10fcebfc14f3b3ed17f96934d152f819';
