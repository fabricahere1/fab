// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surum_kapisi.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(surumDurumu)
final surumDurumuProvider = SurumDurumuProvider._();

final class SurumDurumuProvider
    extends
        $FunctionalProvider<
          AsyncValue<SurumDurumu>,
          SurumDurumu,
          FutureOr<SurumDurumu>
        >
    with $FutureModifier<SurumDurumu>, $FutureProvider<SurumDurumu> {
  SurumDurumuProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'surumDurumuProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$surumDurumuHash();

  @$internal
  @override
  $FutureProviderElement<SurumDurumu> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SurumDurumu> create(Ref ref) {
    return surumDurumu(ref);
  }
}

String _$surumDurumuHash() => r'831326e54adeb4255f1fe578e8f7fe734ff29683';
