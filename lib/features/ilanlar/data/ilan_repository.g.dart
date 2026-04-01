// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ilan_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ilanRepository)
final ilanRepositoryProvider = IlanRepositoryProvider._();

final class IlanRepositoryProvider
    extends $FunctionalProvider<IlanRepository, IlanRepository, IlanRepository>
    with $Provider<IlanRepository> {
  IlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ilanRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ilanRepositoryHash();

  @$internal
  @override
  $ProviderElement<IlanRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IlanRepository create(Ref ref) {
    return ilanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IlanRepository>(value),
    );
  }
}

String _$ilanRepositoryHash() => r'e511946b1fa2aab8744881907ce7718b8faef28f';
