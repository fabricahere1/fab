// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'degerlendirme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sohbetDurumu)
final sohbetDurumuProvider = SohbetDurumuFamily._();

final class SohbetDurumuProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          Stream<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $StreamProvider<Map<String, dynamic>> {
  SohbetDurumuProvider._({
    required SohbetDurumuFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sohbetDurumuProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sohbetDurumuHash();

  @override
  String toString() {
    return r'sohbetDurumuProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as String;
    return sohbetDurumu(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SohbetDurumuProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sohbetDurumuHash() => r'cd31d7e1852322c0cd517c630d6888ecc9dac6c3';

final class SohbetDurumuFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, dynamic>>, String> {
  SohbetDurumuFamily._()
    : super(
        retry: null,
        name: r'sohbetDurumuProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SohbetDurumuProvider call(String sohbetId) =>
      SohbetDurumuProvider._(argument: sohbetId, from: this);

  @override
  String toString() => r'sohbetDurumuProvider';
}
