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

String _$benimTekliflerimHash() => r'ec7cee63fa0bb38d60be6fc79d2a2fdd9f81cfa9';

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
