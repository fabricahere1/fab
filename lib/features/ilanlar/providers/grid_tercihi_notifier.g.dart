// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_tercihi_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GridTercihi)
final gridTercihiProvider = GridTercihiProvider._();

final class GridTercihiProvider extends $NotifierProvider<GridTercihi, int> {
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
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$gridTercihiHash() => r'a8395c30c4ddefcf192b5ba2d299202887c67a6e';

abstract class _$GridTercihi extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
