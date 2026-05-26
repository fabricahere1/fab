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

String _$sohbetDurumuHash() => r'0a5c3953d3094bf9d1d600c6e55c56bbc76a8c0e';

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

@ProviderFor(bekleyenDegerlendirmeler)
final bekleyenDegerlendirmelerProvider = BekleyenDegerlendirmelerFamily._();

final class BekleyenDegerlendirmelerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  BekleyenDegerlendirmelerProvider._({
    required BekleyenDegerlendirmelerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bekleyenDegerlendirmelerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bekleyenDegerlendirmelerHash();

  @override
  String toString() {
    return r'bekleyenDegerlendirmelerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return bekleyenDegerlendirmeler(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BekleyenDegerlendirmelerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bekleyenDegerlendirmelerHash() =>
    r'fac5f62d9bb65cb393221536be38138304da230f';

final class BekleyenDegerlendirmelerFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  BekleyenDegerlendirmelerFamily._()
    : super(
        retry: null,
        name: r'bekleyenDegerlendirmelerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BekleyenDegerlendirmelerProvider call(String kullaniciId) =>
      BekleyenDegerlendirmelerProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'bekleyenDegerlendirmelerProvider';
}

@ProviderFor(kullaniciDegerlendirmeleri)
final kullaniciDegerlendirmeleriProvider = KullaniciDegerlendirmeleriFamily._();

final class KullaniciDegerlendirmeleriProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  KullaniciDegerlendirmeleriProvider._({
    required KullaniciDegerlendirmeleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciDegerlendirmeleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciDegerlendirmeleriHash();

  @override
  String toString() {
    return r'kullaniciDegerlendirmeleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return kullaniciDegerlendirmeleri(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciDegerlendirmeleriProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciDegerlendirmeleriHash() =>
    r'c257c3a1f03bb88739b3692ac525ac32fa975020';

final class KullaniciDegerlendirmeleriFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  KullaniciDegerlendirmeleriFamily._()
    : super(
        retry: null,
        name: r'kullaniciDegerlendirmeleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KullaniciDegerlendirmeleriProvider call(String kullaniciId) =>
      KullaniciDegerlendirmeleriProvider._(argument: kullaniciId, from: this);

  @override
  String toString() => r'kullaniciDegerlendirmeleriProvider';
}

@ProviderFor(DegerlendirmeIslemleri)
final degerlendirmeIslemleriProvider = DegerlendirmeIslemleriProvider._();

final class DegerlendirmeIslemleriProvider
    extends $NotifierProvider<DegerlendirmeIslemleri, AsyncValue<void>> {
  DegerlendirmeIslemleriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'degerlendirmeIslemleriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$degerlendirmeIslemleriHash();

  @$internal
  @override
  DegerlendirmeIslemleri create() => DegerlendirmeIslemleri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$degerlendirmeIslemleriHash() =>
    r'32bdca04cc01e585c3300906c257fb6a45187de8';

abstract class _$DegerlendirmeIslemleri extends $Notifier<AsyncValue<void>> {
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
