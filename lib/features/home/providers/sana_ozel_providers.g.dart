// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sana_ozel_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Şehrine gelecek taşıyıcı ilanları (nereye == user.bulunduguSehir)

@ProviderFor(sehirGelecekIlanlar)
final sehirGelecekIlanlarProvider = SehirGelecekIlanlarProvider._();

/// Şehrine gelecek taşıyıcı ilanları (nereye == user.bulunduguSehir)

final class SehirGelecekIlanlarProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Şehrine gelecek taşıyıcı ilanları (nereye == user.bulunduguSehir)
  SehirGelecekIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sehirGelecekIlanlarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sehirGelecekIlanlarHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return sehirGelecekIlanlar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$sehirGelecekIlanlarHash() =>
    r'736878cbf002fad895f3bfa0d3c18dd126159fa7';

/// Taşıyıcı ilanları kullanıcının ilgi kategorileriyle eşleşenler

@ProviderFor(kategorilereGoreIlanlar)
final kategorilereGoreIlanlarProvider = KategorilereGoreIlanlarProvider._();

/// Taşıyıcı ilanları kullanıcının ilgi kategorileriyle eşleşenler

final class KategorilereGoreIlanlarProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Taşıyıcı ilanları kullanıcının ilgi kategorileriyle eşleşenler
  KategorilereGoreIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kategorilereGoreIlanlarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kategorilereGoreIlanlarHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return kategorilereGoreIlanlar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$kategorilereGoreIlanlarHash() =>
    r'1e67fc5268bf1ad18ad1c714e77a32cc6eadaef4';

/// Taşıyıcı ilanları kullanıcının beden bilgisiyle eşleşenler

@ProviderFor(bedenGoreIlanlar)
final bedenGoreIlanlarProvider = BedenGoreIlanlarProvider._();

/// Taşıyıcı ilanları kullanıcının beden bilgisiyle eşleşenler

final class BedenGoreIlanlarProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Taşıyıcı ilanları kullanıcının beden bilgisiyle eşleşenler
  BedenGoreIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bedenGoreIlanlarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bedenGoreIlanlarHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return bedenGoreIlanlar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$bedenGoreIlanlarHash() => r'26fb25b93cad710d379ec18b909e41a90c7e6abe';

/// Diğer kullanıcıların aynı kategorilerde en çok istediği ürünler

@ProviderFor(populerKategoriIstekleri)
final populerKategoriIstekleriProvider = PopulerKategoriIstekleriProvider._();

/// Diğer kullanıcıların aynı kategorilerde en çok istediği ürünler

final class PopulerKategoriIstekleriProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Diğer kullanıcıların aynı kategorilerde en çok istediği ürünler
  PopulerKategoriIstekleriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'populerKategoriIstekleriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$populerKategoriIstekleriHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return populerKategoriIstekleri(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$populerKategoriIstekleriHash() =>
    r'2c9d70dd2de7b7278f46b40b932d77ea763712bf';

/// Duty Free alışveriş yapabilecek taşıyıcılar

@ProviderFor(dutyFreeYapabilecekIlanlar)
final dutyFreeYapabilecekIlanlarProvider =
    DutyFreeYapabilecekIlanlarProvider._();

/// Duty Free alışveriş yapabilecek taşıyıcılar

final class DutyFreeYapabilecekIlanlarProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Duty Free alışveriş yapabilecek taşıyıcılar
  DutyFreeYapabilecekIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dutyFreeYapabilecekIlanlarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dutyFreeYapabilecekIlanlarHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return dutyFreeYapabilecekIlanlar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$dutyFreeYapabilecekIlanlarHash() =>
    r'78575afbc4ec79b292e5ac9c255ded18ec5d02ba';

/// Taşıyıcının seyahat edeceği şehirden açılan istek ilanları

@ProviderFor(seyahatSehriIlanlar)
final seyahatSehriIlanlarProvider = SeyahatSehriIlanlarProvider._();

/// Taşıyıcının seyahat edeceği şehirden açılan istek ilanları

final class SeyahatSehriIlanlarProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Taşıyıcının seyahat edeceği şehirden açılan istek ilanları
  SeyahatSehriIlanlarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seyahatSehriIlanlarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seyahatSehriIlanlarHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return seyahatSehriIlanlar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$seyahatSehriIlanlarHash() =>
    r'0e3238b2cb790671435d93319a2058f9762692d0';

/// Kargo teslim kabul eden istekçilerin ilanları

@ProviderFor(kargoKabulIstekler)
final kargoKabulIsteklerProvider = KargoKabulIsteklerProvider._();

/// Kargo teslim kabul eden istekçilerin ilanları

final class KargoKabulIsteklerProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Kargo teslim kabul eden istekçilerin ilanları
  KargoKabulIsteklerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kargoKabulIsteklerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kargoKabulIsteklerHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return kargoKabulIstekler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$kargoKabulIsteklerHash() =>
    r'3000fe3e41c5696e1a529a2e4e0657a40d5cd299';

/// Elden teslim kabul eden istekçilerin ilanları

@ProviderFor(eldenKabulIstekler)
final eldenKabulIsteklerProvider = EldenKabulIsteklerProvider._();

/// Elden teslim kabul eden istekçilerin ilanları

final class EldenKabulIsteklerProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// Elden teslim kabul eden istekçilerin ilanları
  EldenKabulIsteklerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eldenKabulIsteklerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eldenKabulIsteklerHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return eldenKabulIstekler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$eldenKabulIsteklerHash() =>
    r'c1b2477239b68258c8797edc5353c9024da7c848';

/// 4 puan ve üzeri değerlendirme alan kullanıcıların istek ilanları

@ProviderFor(onayliIstekler)
final onayliIsteklerProvider = OnayliIsteklerProvider._();

/// 4 puan ve üzeri değerlendirme alan kullanıcıların istek ilanları

final class OnayliIsteklerProvider
    extends
        $FunctionalProvider<List<IlanModel>, List<IlanModel>, List<IlanModel>>
    with $Provider<List<IlanModel>> {
  /// 4 puan ve üzeri değerlendirme alan kullanıcıların istek ilanları
  OnayliIsteklerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onayliIsteklerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onayliIsteklerHash();

  @$internal
  @override
  $ProviderElement<List<IlanModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<IlanModel> create(Ref ref) {
    return onayliIstekler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<IlanModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<IlanModel>>(value),
    );
  }
}

String _$onayliIsteklerHash() => r'1c3d1f5b99528ff724b746e686ccc074d69059de';
