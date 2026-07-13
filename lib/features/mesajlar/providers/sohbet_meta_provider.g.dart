// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sohbet_meta_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sohbetMeta)
final sohbetMetaProvider = SohbetMetaFamily._();

final class SohbetMetaProvider
    extends
        $FunctionalProvider<
          AsyncValue<SohbetMeta>,
          SohbetMeta,
          FutureOr<SohbetMeta>
        >
    with $FutureModifier<SohbetMeta>, $FutureProvider<SohbetMeta> {
  SohbetMetaProvider._({
    required SohbetMetaFamily super.from,
    required ({String sohbetId, String ilanId}) super.argument,
  }) : super(
         retry: null,
         name: r'sohbetMetaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sohbetMetaHash();

  @override
  String toString() {
    return r'sohbetMetaProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SohbetMeta> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SohbetMeta> create(Ref ref) {
    final argument = this.argument as ({String sohbetId, String ilanId});
    return sohbetMeta(
      ref,
      sohbetId: argument.sohbetId,
      ilanId: argument.ilanId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SohbetMetaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sohbetMetaHash() => r'255880a6b76e15b9361e032a22eae8134203bfd4';

final class SohbetMetaFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SohbetMeta>,
          ({String sohbetId, String ilanId})
        > {
  SohbetMetaFamily._()
    : super(
        retry: null,
        name: r'sohbetMetaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SohbetMetaProvider call({required String sohbetId, required String ilanId}) =>
      SohbetMetaProvider._(
        argument: (sohbetId: sohbetId, ilanId: ilanId),
        from: this,
      );

  @override
  String toString() => r'sohbetMetaProvider';
}
