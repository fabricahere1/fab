// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kullanici_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kullaniciRepository)
final kullaniciRepositoryProvider = KullaniciRepositoryProvider._();

final class KullaniciRepositoryProvider
    extends
        $FunctionalProvider<
          KullaniciRepository,
          KullaniciRepository,
          KullaniciRepository
        >
    with $Provider<KullaniciRepository> {
  KullaniciRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kullaniciRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kullaniciRepositoryHash();

  @$internal
  @override
  $ProviderElement<KullaniciRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KullaniciRepository create(Ref ref) {
    return kullaniciRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KullaniciRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KullaniciRepository>(value),
    );
  }
}

String _$kullaniciRepositoryHash() =>
    r'bc80f7ce06d6631e88f72d9a1e3df7559b736c62';
