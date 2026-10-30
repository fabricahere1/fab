// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesaj_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Sohbetler)
final sohbetlerProvider = SohbetlerProvider._();

final class SohbetlerProvider
    extends $AsyncNotifierProvider<Sohbetler, List<SohbetModel>> {
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
  Sohbetler create() => Sohbetler();
}

String _$sohbetlerHash() => r'cf54348c17032ee7ca5237dfd0f7523e8aa57587';

abstract class _$Sohbetler extends $AsyncNotifier<List<SohbetModel>> {
  FutureOr<List<SohbetModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<SohbetModel>>, List<SohbetModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SohbetModel>>, List<SohbetModel>>,
              AsyncValue<List<SohbetModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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

@ProviderFor(karsiKullaniciFoto)
final karsiKullaniciFotoProvider = KarsiKullaniciFotoFamily._();

final class KarsiKullaniciFotoProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  KarsiKullaniciFotoProvider._({
    required KarsiKullaniciFotoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'karsiKullaniciFotoProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$karsiKullaniciFotoHash();

  @override
  String toString() {
    return r'karsiKullaniciFotoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return karsiKullaniciFoto(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KarsiKullaniciFotoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$karsiKullaniciFotoHash() =>
    r'b7a81b208be3d7b4865c0637fba1537fcd52ece7';

final class KarsiKullaniciFotoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  KarsiKullaniciFotoFamily._()
    : super(
        retry: null,
        name: r'karsiKullaniciFotoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  KarsiKullaniciFotoProvider call(String uid) =>
      KarsiKullaniciFotoProvider._(argument: uid, from: this);

  @override
  String toString() => r'karsiKullaniciFotoProvider';
}

@ProviderFor(SohbetNotifier)
final sohbetProvider = SohbetNotifierFamily._();

final class SohbetNotifierProvider
    extends $NotifierProvider<SohbetNotifier, SohbetEkraniState> {
  SohbetNotifierProvider._({
    required SohbetNotifierFamily super.from,
    required ({String karsiKullaniciId, String ilanId, String? sohbetId})
    super.argument,
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

String _$sohbetNotifierHash() => r'108581eae5c74243ec72d35622678445078fd049';

final class SohbetNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SohbetNotifier,
          SohbetEkraniState,
          SohbetEkraniState,
          SohbetEkraniState,
          ({String karsiKullaniciId, String ilanId, String? sohbetId})
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
    String? sohbetId,
  }) => SohbetNotifierProvider._(
    argument: (
      karsiKullaniciId: karsiKullaniciId,
      ilanId: ilanId,
      sohbetId: sohbetId,
    ),
    from: this,
  );

  @override
  String toString() => r'sohbetProvider';
}

abstract class _$SohbetNotifier extends $Notifier<SohbetEkraniState> {
  late final _$args =
      ref.$arg as ({String karsiKullaniciId, String ilanId, String? sohbetId});
  String get karsiKullaniciId => _$args.karsiKullaniciId;
  String get ilanId => _$args.ilanId;
  String? get sohbetId => _$args.sohbetId;

  SohbetEkraniState build({
    required String karsiKullaniciId,
    required String ilanId,
    String? sohbetId,
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
        sohbetId: _$args.sohbetId,
      ),
    );
  }
}

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
    r'3f3fe5ec02c4cac7cf659fcea08650921b0fd68c';

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

String _$sohbetIslemleriHash() => r'06474cb84139d7b81011f1816c9880bbd4890d1f';

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
