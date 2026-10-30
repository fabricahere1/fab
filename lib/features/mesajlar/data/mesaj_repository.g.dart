// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesaj_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mesajRepository)
final mesajRepositoryProvider = MesajRepositoryProvider._();

final class MesajRepositoryProvider
    extends
        $FunctionalProvider<MesajRepository, MesajRepository, MesajRepository>
    with $Provider<MesajRepository> {
  MesajRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mesajRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mesajRepositoryHash();

  @$internal
  @override
  $ProviderElement<MesajRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MesajRepository create(Ref ref) {
    return mesajRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MesajRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MesajRepository>(value),
    );
  }
}

String _$mesajRepositoryHash() => r'c84a3c1dfb25eb8ad3e7a704f35ce3284a45e10d';
