// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aktif_kullanici_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Eski authStateProvider'ın (Firebase'in Stream&lt;User?&gt;'ı) yerini
/// alıyor — AsyncValue
/// tabanlı olması router'ın (`ref.listen`/`ref.read(...).isLoading` vb.)
/// aynı şekilde çalışmasını sağlıyor.

@ProviderFor(AktifKullaniciNotifier)
final aktifKullaniciProvider = AktifKullaniciNotifierProvider._();

/// Eski authStateProvider'ın (Firebase'in Stream&lt;User?&gt;'ı) yerini
/// alıyor — AsyncValue
/// tabanlı olması router'ın (`ref.listen`/`ref.read(...).isLoading` vb.)
/// aynı şekilde çalışmasını sağlıyor.
final class AktifKullaniciNotifierProvider
    extends $AsyncNotifierProvider<AktifKullaniciNotifier, AktifKullanici?> {
  /// Eski authStateProvider'ın (Firebase'in Stream&lt;User?&gt;'ı) yerini
  /// alıyor — AsyncValue
  /// tabanlı olması router'ın (`ref.listen`/`ref.read(...).isLoading` vb.)
  /// aynı şekilde çalışmasını sağlıyor.
  AktifKullaniciNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aktifKullaniciProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aktifKullaniciNotifierHash();

  @$internal
  @override
  AktifKullaniciNotifier create() => AktifKullaniciNotifier();
}

String _$aktifKullaniciNotifierHash() =>
    r'63b91073ae9f9f678dc9e271ee1f6cd2ae514847';

/// Eski authStateProvider'ın (Firebase'in Stream&lt;User?&gt;'ı) yerini
/// alıyor — AsyncValue
/// tabanlı olması router'ın (`ref.listen`/`ref.read(...).isLoading` vb.)
/// aynı şekilde çalışmasını sağlıyor.

abstract class _$AktifKullaniciNotifier
    extends $AsyncNotifier<AktifKullanici?> {
  FutureOr<AktifKullanici?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AktifKullanici?>, AktifKullanici?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AktifKullanici?>, AktifKullanici?>,
              AsyncValue<AktifKullanici?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Eski `currentUser` (sync, nullable) provider'ının BİREBİR yerini alıyor
/// — uygulama genelindeki `ref.watch(currentUserProvider)?.uid` gibi
/// çağrılar hiç değişmeden çalışmaya devam ediyor.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// Eski `currentUser` (sync, nullable) provider'ının BİREBİR yerini alıyor
/// — uygulama genelindeki `ref.watch(currentUserProvider)?.uid` gibi
/// çağrılar hiç değişmeden çalışmaya devam ediyor.

final class CurrentUserProvider
    extends
        $FunctionalProvider<AktifKullanici?, AktifKullanici?, AktifKullanici?>
    with $Provider<AktifKullanici?> {
  /// Eski `currentUser` (sync, nullable) provider'ının BİREBİR yerini alıyor
  /// — uygulama genelindeki `ref.watch(currentUserProvider)?.uid` gibi
  /// çağrılar hiç değişmeden çalışmaya devam ediyor.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<AktifKullanici?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AktifKullanici? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AktifKullanici? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AktifKullanici?>(value),
    );
  }
}

String _$currentUserHash() => r'1aeba215513abdf886b453b3b8576e29c6b55929';
