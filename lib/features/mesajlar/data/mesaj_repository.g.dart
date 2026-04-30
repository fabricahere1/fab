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

String _$mesajRepositoryHash() => r'7ed4f58250c2a117b739265c3fadb425b2202e1d';
