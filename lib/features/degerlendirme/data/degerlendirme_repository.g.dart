// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'degerlendirme_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(degerlendirmeRepository)
final degerlendirmeRepositoryProvider = DegerlendirmeRepositoryProvider._();

final class DegerlendirmeRepositoryProvider
    extends
        $FunctionalProvider<
          DegerlendirmeRepository,
          DegerlendirmeRepository,
          DegerlendirmeRepository
        >
    with $Provider<DegerlendirmeRepository> {
  DegerlendirmeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'degerlendirmeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$degerlendirmeRepositoryHash();

  @$internal
  @override
  $ProviderElement<DegerlendirmeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DegerlendirmeRepository create(Ref ref) {
    return degerlendirmeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DegerlendirmeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DegerlendirmeRepository>(value),
    );
  }
}

String _$degerlendirmeRepositoryHash() =>
    r'73b8010bfae9d7c259cd124e7df5161c3a771729';
