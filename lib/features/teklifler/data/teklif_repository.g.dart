// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teklif_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teklifRepository)
final teklifRepositoryProvider = TeklifRepositoryProvider._();

final class TeklifRepositoryProvider
    extends
        $FunctionalProvider<
          TeklifRepository,
          TeklifRepository,
          TeklifRepository
        >
    with $Provider<TeklifRepository> {
  TeklifRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teklifRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teklifRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeklifRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeklifRepository create(Ref ref) {
    return teklifRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeklifRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeklifRepository>(value),
    );
  }
}

String _$teklifRepositoryHash() => r'22472fb1f67f1c8ebfbaee9e77455249faee4386';
