// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teklif_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teklifDetay)
final teklifDetayProvider = TeklifDetayFamily._();

final class TeklifDetayProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeklifModel?>,
          TeklifModel?,
          Stream<TeklifModel?>
        >
    with $FutureModifier<TeklifModel?>, $StreamProvider<TeklifModel?> {
  TeklifDetayProvider._({
    required TeklifDetayFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teklifDetayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teklifDetayHash();

  @override
  String toString() {
    return r'teklifDetayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<TeklifModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TeklifModel?> create(Ref ref) {
    final argument = this.argument as String;
    return teklifDetay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeklifDetayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teklifDetayHash() => r'263a4ccbc47f95f713ad2615170b3da9dbfae500';

final class TeklifDetayFamily extends $Family
    with $FunctionalFamilyOverride<Stream<TeklifModel?>, String> {
  TeklifDetayFamily._()
    : super(
        retry: null,
        name: r'teklifDetayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeklifDetayProvider call(String teklifId) =>
      TeklifDetayProvider._(argument: teklifId, from: this);

  @override
  String toString() => r'teklifDetayProvider';
}

@ProviderFor(ilanTeklifOzet)
final ilanTeklifOzetProvider = IlanTeklifOzetFamily._();

final class IlanTeklifOzetProvider
    extends
        $FunctionalProvider<
          AsyncValue<({double? enYuksek, int sayi})>,
          ({double? enYuksek, int sayi}),
          Stream<({double? enYuksek, int sayi})>
        >
    with
        $FutureModifier<({double? enYuksek, int sayi})>,
        $StreamProvider<({double? enYuksek, int sayi})> {
  IlanTeklifOzetProvider._({
    required IlanTeklifOzetFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ilanTeklifOzetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ilanTeklifOzetHash();

  @override
  String toString() {
    return r'ilanTeklifOzetProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<({double? enYuksek, int sayi})> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<({double? enYuksek, int sayi})> create(Ref ref) {
    final argument = this.argument as String;
    return ilanTeklifOzet(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IlanTeklifOzetProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ilanTeklifOzetHash() => r'6c0954a01f5e0e50e9eefebb1d86ce59444a65bc';

final class IlanTeklifOzetFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<({double? enYuksek, int sayi})>,
          String
        > {
  IlanTeklifOzetFamily._()
    : super(
        retry: null,
        name: r'ilanTeklifOzetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IlanTeklifOzetProvider call(String ilanId) =>
      IlanTeklifOzetProvider._(argument: ilanId, from: this);

  @override
  String toString() => r'ilanTeklifOzetProvider';
}

@ProviderFor(ilanKabulTeklifi)
final ilanKabulTeklifiProvider = IlanKabulTeklifiFamily._();

final class IlanKabulTeklifiProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeklifModel?>,
          TeklifModel?,
          Stream<TeklifModel?>
        >
    with $FutureModifier<TeklifModel?>, $StreamProvider<TeklifModel?> {
  IlanKabulTeklifiProvider._({
    required IlanKabulTeklifiFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'ilanKabulTeklifiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ilanKabulTeklifiHash();

  @override
  String toString() {
    return r'ilanKabulTeklifiProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<TeklifModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TeklifModel?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return ilanKabulTeklifi(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is IlanKabulTeklifiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ilanKabulTeklifiHash() => r'6483d3ae6cbb4e44a14d831d15e9e5987a62efdb';

final class IlanKabulTeklifiFamily extends $Family
    with $FunctionalFamilyOverride<Stream<TeklifModel?>, (String, String)> {
  IlanKabulTeklifiFamily._()
    : super(
        retry: null,
        name: r'ilanKabulTeklifiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IlanKabulTeklifiProvider call(String ilanId, String teklifVerenId) =>
      IlanKabulTeklifiProvider._(argument: (ilanId, teklifVerenId), from: this);

  @override
  String toString() => r'ilanKabulTeklifiProvider';
}

@ProviderFor(ilanTeklifleri)
final ilanTeklifleriProvider = IlanTeklifleriFamily._();

final class IlanTeklifleriProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeklifModel>>,
          List<TeklifModel>,
          Stream<List<TeklifModel>>
        >
    with
        $FutureModifier<List<TeklifModel>>,
        $StreamProvider<List<TeklifModel>> {
  IlanTeklifleriProvider._({
    required IlanTeklifleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ilanTeklifleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ilanTeklifleriHash();

  @override
  String toString() {
    return r'ilanTeklifleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TeklifModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TeklifModel>> create(Ref ref) {
    final argument = this.argument as String;
    return ilanTeklifleri(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IlanTeklifleriProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ilanTeklifleriHash() => r'30a41af605cabeae00282b060b4c7642437d3b56';

final class IlanTeklifleriFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TeklifModel>>, String> {
  IlanTeklifleriFamily._()
    : super(
        retry: null,
        name: r'ilanTeklifleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IlanTeklifleriProvider call(String ilanId) =>
      IlanTeklifleriProvider._(argument: ilanId, from: this);

  @override
  String toString() => r'ilanTeklifleriProvider';
}

@ProviderFor(benimTekliflerim)
final benimTekliflerimProvider = BenimTekliflerimFamily._();

final class BenimTekliflerimProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeklifModel>>,
          List<TeklifModel>,
          Stream<List<TeklifModel>>
        >
    with
        $FutureModifier<List<TeklifModel>>,
        $StreamProvider<List<TeklifModel>> {
  BenimTekliflerimProvider._({
    required BenimTekliflerimFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'benimTekliflerimProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$benimTekliflerimHash();

  @override
  String toString() {
    return r'benimTekliflerimProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TeklifModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TeklifModel>> create(Ref ref) {
    final argument = this.argument as String;
    return benimTekliflerim(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BenimTekliflerimProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$benimTekliflerimHash() => r'df2d1c114f3ea2d8caebef7dc03102f4440113f1';

final class BenimTekliflerimFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TeklifModel>>, String> {
  BenimTekliflerimFamily._()
    : super(
        retry: null,
        name: r'benimTekliflerimProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BenimTekliflerimProvider call(String kullaniciId) =>
      BenimTekliflerimProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'benimTekliflerimProvider';
}

@ProviderFor(ilanSahibiTeklifleri)
final ilanSahibiTeklifleriProvider = IlanSahibiTeklifleriFamily._();

final class IlanSahibiTeklifleriProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeklifModel>>,
          List<TeklifModel>,
          Stream<List<TeklifModel>>
        >
    with
        $FutureModifier<List<TeklifModel>>,
        $StreamProvider<List<TeklifModel>> {
  IlanSahibiTeklifleriProvider._({
    required IlanSahibiTeklifleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ilanSahibiTeklifleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ilanSahibiTeklifleriHash();

  @override
  String toString() {
    return r'ilanSahibiTeklifleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TeklifModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TeklifModel>> create(Ref ref) {
    final argument = this.argument as String;
    return ilanSahibiTeklifleri(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IlanSahibiTeklifleriProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ilanSahibiTeklifleriHash() =>
    r'9a4d5f1e00e968336b04ee2a3cc81df2db2c4773';

final class IlanSahibiTeklifleriFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TeklifModel>>, String> {
  IlanSahibiTeklifleriFamily._()
    : super(
        retry: null,
        name: r'ilanSahibiTeklifleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IlanSahibiTeklifleriProvider call(String kullaniciId) =>
      IlanSahibiTeklifleriProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'ilanSahibiTeklifleriProvider';
}

@ProviderFor(teklifTeslim)
final teklifTeslimProvider = TeklifTeslimFamily._();

final class TeklifTeslimProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          Stream<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $StreamProvider<Map<String, dynamic>> {
  TeklifTeslimProvider._({
    required TeklifTeslimFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teklifTeslimProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teklifTeslimHash();

  @override
  String toString() {
    return r'teklifTeslimProvider'
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
    return teklifTeslim(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeklifTeslimProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teklifTeslimHash() => r'af4544b1d7e3f67a82a03aa14e3bec08e728dcc1';

final class TeklifTeslimFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, dynamic>>, String> {
  TeklifTeslimFamily._()
    : super(
        retry: null,
        name: r'teklifTeslimProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeklifTeslimProvider call(String teklifId) =>
      TeklifTeslimProvider._(argument: teklifId, from: this);

  @override
  String toString() => r'teklifTeslimProvider';
}

@ProviderFor(TeslimNotifier)
final teslimProvider = TeslimNotifierProvider._();

final class TeslimNotifierProvider
    extends $NotifierProvider<TeslimNotifier, AsyncValue<void>> {
  TeslimNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teslimProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teslimNotifierHash();

  @$internal
  @override
  TeslimNotifier create() => TeslimNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$teslimNotifierHash() => r'b1c617cc39bba6407aaae7d5202230adb30c5645';

abstract class _$TeslimNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(TeklifNotifier)
final teklifProvider = TeklifNotifierProvider._();

final class TeklifNotifierProvider
    extends $NotifierProvider<TeklifNotifier, AsyncValue<void>> {
  TeklifNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teklifProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teklifNotifierHash();

  @$internal
  @override
  TeklifNotifier create() => TeklifNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$teklifNotifierHash() => r'097a120309d178eab454c1125a2ac2b6a4d3d803';

abstract class _$TeklifNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
