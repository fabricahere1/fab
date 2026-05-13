// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesaj_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sohbetler)
final sohbetlerProvider = SohbetlerProvider._();

final class SohbetlerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SohbetModel>>,
          List<SohbetModel>,
          Stream<List<SohbetModel>>
        >
    with
        $FutureModifier<List<SohbetModel>>,
        $StreamProvider<List<SohbetModel>> {
  SohbetlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sohbetlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sohbetlerHash();

  @$internal
  @override
  $StreamProviderElement<List<SohbetModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SohbetModel>> create(Ref ref) {
    return sohbetler(ref);
  }
}

String _$sohbetlerHash() => r'dfb5057bee78bc0e6caa5ccd3cc69e19ab60d26c';

@ProviderFor(okunmamisSayi)
final okunmamisSayiProvider = OkunmamisSayiProvider._();

final class OkunmamisSayiProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  OkunmamisSayiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'okunmamisSayiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$okunmamisSayiHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return okunmamisSayi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$okunmamisSayiHash() => r'2e7df4de9216004e8724351c2c00662402e0ee1b';

@ProviderFor(karsiKullaniciAd)
final karsiKullaniciAdProvider = KarsiKullaniciAdFamily._();

final class KarsiKullaniciAdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  KarsiKullaniciAdProvider._({
    required KarsiKullaniciAdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'karsiKullaniciAdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$karsiKullaniciAdHash();

  @override
  String toString() {
    return r'karsiKullaniciAdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    final argument = this.argument as String;
    return karsiKullaniciAd(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KarsiKullaniciAdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$karsiKullaniciAdHash() => r'3d27a2edbe1c028f4e7a05011c0801e6bb6bcd3f';

final class KarsiKullaniciAdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String>, String> {
  KarsiKullaniciAdFamily._()
    : super(
        retry: null,
        name: r'karsiKullaniciAdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KarsiKullaniciAdProvider call(String uid) =>
      KarsiKullaniciAdProvider._(argument: uid, from: this);

  @override
  String toString() => r'karsiKullaniciAdProvider';
}

@ProviderFor(SohbetNotifier)
final sohbetProvider = SohbetNotifierFamily._();

final class SohbetNotifierProvider
    extends $NotifierProvider<SohbetNotifier, SohbetEkraniState> {
  SohbetNotifierProvider._({
    required SohbetNotifierFamily super.from,
    required ({String karsiKullaniciId, String ilanId}) super.argument,
  }) : super(
         retry: null,
         name: r'sohbetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sohbetNotifierHash();

  @override
  String toString() {
    return r'sohbetProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SohbetNotifier create() => SohbetNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SohbetEkraniState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SohbetEkraniState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SohbetNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sohbetNotifierHash() => r'b07d626c7c26d68c598d5c8b6b686f817795754c';

final class SohbetNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SohbetNotifier,
          SohbetEkraniState,
          SohbetEkraniState,
          SohbetEkraniState,
          ({String karsiKullaniciId, String ilanId})
        > {
  SohbetNotifierFamily._()
    : super(
        retry: null,
        name: r'sohbetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SohbetNotifierProvider call({
    required String karsiKullaniciId,
    required String ilanId,
  }) => SohbetNotifierProvider._(
    argument: (karsiKullaniciId: karsiKullaniciId, ilanId: ilanId),
    from: this,
  );

  @override
  String toString() => r'sohbetProvider';
}

abstract class _$SohbetNotifier extends $Notifier<SohbetEkraniState> {
  late final _$args = ref.$arg as ({String karsiKullaniciId, String ilanId});
  String get karsiKullaniciId => _$args.karsiKullaniciId;
  String get ilanId => _$args.ilanId;

  SohbetEkraniState build({
    required String karsiKullaniciId,
    required String ilanId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SohbetEkraniState, SohbetEkraniState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SohbetEkraniState, SohbetEkraniState>,
              SohbetEkraniState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        karsiKullaniciId: _$args.karsiKullaniciId,
        ilanId: _$args.ilanId,
      ),
    );
  }
}

@ProviderFor(kullaniciProfil)
final kullaniciProfilProvider = KullaniciProfilFamily._();

final class KullaniciProfilProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  KullaniciProfilProvider._({
    required KullaniciProfilFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciProfilProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciProfilHash();

  @override
  String toString() {
    return r'kullaniciProfilProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as String;
    return kullaniciProfil(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciProfilProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciProfilHash() => r'254506d0c08fe28db3299cff7f59ae8620ed418c';

final class KullaniciProfilFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, dynamic>?>, String> {
  KullaniciProfilFamily._()
    : super(
        retry: null,
        name: r'kullaniciProfilProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KullaniciProfilProvider call(String uid) =>
      KullaniciProfilProvider._(argument: uid, from: this);

  @override
  String toString() => r'kullaniciProfilProvider';
}

@ProviderFor(benimProfil)
final benimProfilProvider = BenimProfilProvider._();

final class BenimProfilProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  BenimProfilProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'benimProfilProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$benimProfilHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    return benimProfil(ref);
  }
}

String _$benimProfilHash() => r'4391d383b930a8c55321342f716c9083ad2a7053';
