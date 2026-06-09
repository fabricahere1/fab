// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'son_goruntulenenler_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sonGoruntulenenlerRepository)
final sonGoruntulenenlerRepositoryProvider =
    SonGoruntulenenlerRepositoryProvider._();

final class SonGoruntulenenlerRepositoryProvider
    extends
        $FunctionalProvider<
          SonGoruntulenenlerRepository,
          SonGoruntulenenlerRepository,
          SonGoruntulenenlerRepository
        >
    with $Provider<SonGoruntulenenlerRepository> {
  SonGoruntulenenlerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonGoruntulenenlerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonGoruntulenenlerRepositoryHash();

  @$internal
  @override
  $ProviderElement<SonGoruntulenenlerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SonGoruntulenenlerRepository create(Ref ref) {
    return sonGoruntulenenlerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonGoruntulenenlerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonGoruntulenenlerRepository>(value),
    );
  }
}

String _$sonGoruntulenenlerRepositoryHash() =>
    r'2315b1f169ba886e6dd2727c288c2cdbaafdac17';
