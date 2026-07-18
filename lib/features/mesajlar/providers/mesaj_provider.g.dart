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
        isAutoDispose: false,
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

String _$sohbetlerHash() => r'a262ef544fcacda3e2c3f3cd71c657ca5efb85d0';

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

String _$okunmamisSayiHash() => r'11447a5893307acb2b16d972cea6c98b755bd565';

@ProviderFor(karsiKullaniciAd)
final karsiKullaniciAdProvider = KarsiKullaniciAdFamily._();

final class KarsiKullaniciAdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  KarsiKullaniciAdProvider._({
    required KarsiKullaniciAdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'karsiKullaniciAdProvider',
         isAutoDispose: false,
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
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
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

String _$karsiKullaniciAdHash() => r'a97e9aa1ba001cd59875a636cfff78dadbfad64a';

final class KarsiKullaniciAdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  KarsiKullaniciAdFamily._()
    : super(
        retry: null,
        name: r'karsiKullaniciAdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
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

String _$sohbetNotifierHash() => r'b775ef1e3117612f14d39948cd68e90da8088391';

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

@ProviderFor(IslemDurumuIslemleri)
final islemDurumuIslemleriProvider = IslemDurumuIslemleriFamily._();

final class IslemDurumuIslemleriProvider
    extends $NotifierProvider<IslemDurumuIslemleri, AsyncValue<void>> {
  IslemDurumuIslemleriProvider._({
    required IslemDurumuIslemleriFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'islemDurumuIslemleriProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$islemDurumuIslemleriHash();

  @override
  String toString() {
    return r'islemDurumuIslemleriProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IslemDurumuIslemleri create() => IslemDurumuIslemleri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IslemDurumuIslemleriProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$islemDurumuIslemleriHash() =>
    r'349843fa074193f7b109258d10f3345eaa53a54f';

final class IslemDurumuIslemleriFamily extends $Family
    with
        $ClassFamilyOverride<
          IslemDurumuIslemleri,
          AsyncValue<void>,
          AsyncValue<void>,
          AsyncValue<void>,
          String
        > {
  IslemDurumuIslemleriFamily._()
    : super(
        retry: null,
        name: r'islemDurumuIslemleriProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IslemDurumuIslemleriProvider call(String sohbetId) =>
      IslemDurumuIslemleriProvider._(argument: sohbetId, from: this);

  @override
  String toString() => r'islemDurumuIslemleriProvider';
}

abstract class _$IslemDurumuIslemleri extends $Notifier<AsyncValue<void>> {
  late final _$args = ref.$arg as String;
  String get sohbetId => _$args;

  AsyncValue<void> build(String sohbetId);
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
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(SohbetIslemleri)
final sohbetIslemleriProvider = SohbetIslemleriProvider._();

final class SohbetIslemleriProvider
    extends $NotifierProvider<SohbetIslemleri, AsyncValue<void>> {
  SohbetIslemleriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sohbetIslemleriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sohbetIslemleriHash();

  @$internal
  @override
  SohbetIslemleri create() => SohbetIslemleri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$sohbetIslemleriHash() => r'c54a0b2a85d6270b333fc9a30f4ea2938ff7c6e5';

abstract class _$SohbetIslemleri extends $Notifier<AsyncValue<void>> {
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
