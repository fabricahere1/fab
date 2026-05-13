// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profil_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(benimKullaniciProfil)
final benimKullaniciProfilProvider = BenimKullaniciProfilProvider._();

final class BenimKullaniciProfilProvider
    extends
        $FunctionalProvider<
          AsyncValue<KullaniciModel?>,
          KullaniciModel?,
          Stream<KullaniciModel?>
        >
    with $FutureModifier<KullaniciModel?>, $StreamProvider<KullaniciModel?> {
  BenimKullaniciProfilProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'benimKullaniciProfilProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$benimKullaniciProfilHash();

  @$internal
  @override
  $StreamProviderElement<KullaniciModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<KullaniciModel?> create(Ref ref) {
    return benimKullaniciProfil(ref);
  }
}

String _$benimKullaniciProfilHash() =>
    r'e314797fa190ba15dd6e6a3c0372faab0b413c72';

@ProviderFor(kullaniciBilgi)
final kullaniciBilgiProvider = KullaniciBilgiFamily._();

final class KullaniciBilgiProvider
    extends
        $FunctionalProvider<
          AsyncValue<KullaniciModel?>,
          KullaniciModel?,
          FutureOr<KullaniciModel?>
        >
    with $FutureModifier<KullaniciModel?>, $FutureProvider<KullaniciModel?> {
  KullaniciBilgiProvider._({
    required KullaniciBilgiFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kullaniciBilgiProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kullaniciBilgiHash();

  @override
  String toString() {
    return r'kullaniciBilgiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<KullaniciModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<KullaniciModel?> create(Ref ref) {
    final argument = this.argument as String;
    return kullaniciBilgi(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KullaniciBilgiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kullaniciBilgiHash() => r'c2705ee69ec2e345cc2c21ec16956b58a3422f99';

final class KullaniciBilgiFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<KullaniciModel?>, String> {
  KullaniciBilgiFamily._()
    : super(
        retry: null,
        name: r'kullaniciBilgiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  KullaniciBilgiProvider call(String uid) =>
      KullaniciBilgiProvider._(argument: uid, from: this);

  @override
  String toString() => r'kullaniciBilgiProvider';
}

@ProviderFor(ProfilDuzenle)
final profilDuzenleProvider = ProfilDuzenleProvider._();

final class ProfilDuzenleProvider
    extends $NotifierProvider<ProfilDuzenle, AsyncValue<void>> {
  ProfilDuzenleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilDuzenleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilDuzenleHash();

  @$internal
  @override
  ProfilDuzenle create() => ProfilDuzenle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$profilDuzenleHash() => r'917bdf57e283842dbd0e5c6ed982788f380ad7e9';

abstract class _$ProfilDuzenle extends $Notifier<AsyncValue<void>> {
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

@ProviderFor(Engelleme)
final engellemeProvider = EngellemeProvider._();

final class EngellemeProvider
    extends $NotifierProvider<Engelleme, AsyncValue<void>> {
  EngellemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engellemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engellemeHash();

  @$internal
  @override
  Engelleme create() => Engelleme();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$engellemeHash() => r'e471bc895a03b072d0b1fa3ec0fa56648f1c9141';

abstract class _$Engelleme extends $Notifier<AsyncValue<void>> {
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

@ProviderFor(engellenenler)
final engellenenlerProvider = EngellenenlerProvider._();

final class EngellenenlerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  EngellenenlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engellenenlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engellenenlerHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return engellenenler(ref);
  }
}

String _$engellenenlerHash() => r'c75318ff134d7f08cd483e7cc5bd33b22293c3bd';

@ProviderFor(Sikayet)
final sikayetProvider = SikayetProvider._();

final class SikayetProvider
    extends $NotifierProvider<Sikayet, AsyncValue<void>> {
  SikayetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sikayetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sikayetHash();

  @$internal
  @override
  Sikayet create() => Sikayet();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$sikayetHash() => r'3785b707a0666b7295f2b8ae01f9e9f7342b6e9b';

abstract class _$Sikayet extends $Notifier<AsyncValue<void>> {
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

/// Kullanıcının kendi ilanlarını real-time dinler.
/// [keepAlive] sayesinde sayfa kapanınca dispose olmaz,
/// tekrar açılınca Firestore'a yeniden bağlanmaz.
/// uid null olduğunda (çıkış yapıldığında) provider invalidate edilir.

@ProviderFor(ilanlarim)
final ilanlarimProvider = IlanlarimProvider._();

/// Kullanıcının kendi ilanlarını real-time dinler.
/// [keepAlive] sayesinde sayfa kapanınca dispose olmaz,
/// tekrar açılınca Firestore'a yeniden bağlanmaz.
/// uid null olduğunda (çıkış yapıldığında) provider invalidate edilir.

final class IlanlarimProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IlanModel>>,
          List<IlanModel>,
          Stream<List<IlanModel>>
        >
    with $FutureModifier<List<IlanModel>>, $StreamProvider<List<IlanModel>> {
  /// Kullanıcının kendi ilanlarını real-time dinler.
  /// [keepAlive] sayesinde sayfa kapanınca dispose olmaz,
  /// tekrar açılınca Firestore'a yeniden bağlanmaz.
  /// uid null olduğunda (çıkış yapıldığında) provider invalidate edilir.
  IlanlarimProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ilanlarimProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ilanlarimHash();

  @$internal
  @override
  $StreamProviderElement<List<IlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<IlanModel>> create(Ref ref) {
    return ilanlarim(ref);
  }
}

String _$ilanlarimHash() => r'e4590c00e1002eb544b796ca09f105886a89ab59';
