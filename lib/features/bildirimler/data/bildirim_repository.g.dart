// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bildirim_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bildirimRepository)
final bildirimRepositoryProvider = BildirimRepositoryProvider._();

final class BildirimRepositoryProvider
    extends
        $FunctionalProvider<
          BildirimRepository,
          BildirimRepository,
          BildirimRepository
        >
    with $Provider<BildirimRepository> {
  BildirimRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bildirimRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bildirimRepositoryHash();

  @$internal
  @override
  $ProviderElement<BildirimRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BildirimRepository create(Ref ref) {
    return bildirimRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BildirimRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BildirimRepository>(value),
    );
  }
}

String _$bildirimRepositoryHash() =>
    r'51fb0e0750a4a860540da65edaaeca1868e1f4b1';
