// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baglanti_banner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(baglantiDurumu)
final baglantiDurumuProvider = BaglantiDurumuProvider._();

final class BaglantiDurumuProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  BaglantiDurumuProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baglantiDurumuProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baglantiDurumuHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return baglantiDurumu(ref);
  }
}

String _$baglantiDurumuHash() => r'4e0c786f6a89e672538c16b8b9a975f0d398c2ad';
