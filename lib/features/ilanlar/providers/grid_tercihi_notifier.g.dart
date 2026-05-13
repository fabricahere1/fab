// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_tercihi_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GridTercihi)
final gridTercihiProvider = GridTercihiProvider._();

final class GridTercihiProvider
    extends $NotifierProvider<GridTercihi, GoruntulemeModeli> {
  GridTercihiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gridTercihiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gridTercihiHash();

  @$internal
  @override
  GridTercihi create() => GridTercihi();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoruntulemeModeli value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoruntulemeModeli>(value),
    );
  }
}

String _$gridTercihiHash() => r'81893a2ca386e42dbbdb5c04cef641ab7a126310';

abstract class _$GridTercihi extends $Notifier<GoruntulemeModeli> {
  GoruntulemeModeli build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GoruntulemeModeli, GoruntulemeModeli>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoruntulemeModeli, GoruntulemeModeli>,
              GoruntulemeModeli,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
