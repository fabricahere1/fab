// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kesfet_akis_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(KesfetAkis)
final kesfetAkisProvider = KesfetAkisFamily._();

final class KesfetAkisProvider
    extends $NotifierProvider<KesfetAkis, KesfetAkisState> {
  KesfetAkisProvider._({
    required KesfetAkisFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kesfetAkisProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kesfetAkisHash();

  @override
  String toString() {
    return r'kesfetAkisProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  KesfetAkis create() => KesfetAkis();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KesfetAkisState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KesfetAkisState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KesfetAkisProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kesfetAkisHash() => r'5bd4bf71e5f388403e801e21930d22e569030ea5';

final class KesfetAkisFamily extends $Family
    with
        $ClassFamilyOverride<
          KesfetAkis,
          KesfetAkisState,
          KesfetAkisState,
          KesfetAkisState,
          String
        > {
  KesfetAkisFamily._()
    : super(
        retry: null,
        name: r'kesfetAkisProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  KesfetAkisProvider call(String tip) =>
      KesfetAkisProvider._(argument: tip, from: this);

  @override
  String toString() => r'kesfetAkisProvider';
}

abstract class _$KesfetAkis extends $Notifier<KesfetAkisState> {
  late final _$args = ref.$arg as String;
  String get tip => _$args;

  KesfetAkisState build(String tip);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<KesfetAkisState, KesfetAkisState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KesfetAkisState, KesfetAkisState>,
              KesfetAkisState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
