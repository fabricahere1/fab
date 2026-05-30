import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/ilan_repository.dart';
import '../domain/ilan_model.dart';
import '../../auth/providers/auth_provider.dart';

export '../data/ilan_repository.dart' show ilanRepositoryProvider;

part 'ilan_provider.g.dart';

class IlanListeState {
  final List<IlanModel> ilanlar;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final DateTime? sonTarih;
  final String siralama;
  final List<String> engellenenler;

  const IlanListeState({
    this.ilanlar = const [],
    this.yukleniyor = false,
    this.dahaFazlaVar = true,
    this.sonTarih,
    this.siralama = 'tarih',
    this.engellenenler = const [],
  });

  IlanListeState copyWith({
    List<IlanModel>? ilanlar,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    DateTime? sonTarih,
    String? siralama,
    List<String>? engellenenler,
  }) =>
      IlanListeState(
        ilanlar: ilanlar ?? this.ilanlar,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        sonTarih: sonTarih ?? this.sonTarih,
        siralama: siralama ?? this.siralama,
        engellenenler: engellenenler ?? this.engellenenler,
      );

  List<IlanModel> get filtrelenmis {
    if (engellenenler.isEmpty) return ilanlar;
    return ilanlar.where((i) => !engellenenler.contains(i.kullaniciId)).toList();
  }
}

@riverpod
class IstekIlanlar extends _$IstekIlanlar {
  bool _ilkYuklemeYapildi = false;

  @override
  IlanListeState build() {
    if (!_ilkYuklemeYapildi) {
      _ilkYuklemeYapildi = true;
      Future.microtask(() => _ilkYukle());
    }
    return const IlanListeState(yukleniyor: true);
  }

  IlanRepository get _repo => ref.read(ilanRepositoryProvider);

  Future<void> _ilkYukle({int deneme = 0}) async {
    state = state.copyWith(yukleniyor: true);
    try {
      final sonuc = await _repo.istekIlanlariniGetir();
      state = state.copyWith(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
      if (sonuc.ilanlar.isNotEmpty) {
        _arkaGuncelleIstekIlanlar();
      }
    } catch (e) {
      debugPrint('İstek ilanları yükleme hatası: $e');
      if (deneme < 2) {
        await Future.delayed(const Duration(seconds: 2));
        _ilkYukle(deneme: deneme + 1);
      } else {
        state = state.copyWith(yukleniyor: false);
      }
    }
  }

  Future<void> _arkaGuncelleIstekIlanlar() async {
    try {
      final sonuc = await _repo.istekIlanlariniGetirSunucu();
      if (!state.yukleniyor) {
        state = state.copyWith(
          ilanlar: sonuc.ilanlar,
          sonTarih: sonuc.sonTarih,
          dahaFazlaVar: !sonuc.bitti,
        );
      }
    } catch (_) {}
  }

  Future<void> yenile() async {
    state = state.copyWith(yukleniyor: true);
    try {
      final sonuc = await _repo.istekIlanlariniGetir();
      state = state.copyWith(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
    } catch (e) {
      debugPrint('İstek ilanları yenileme hatası: $e');
      state = state.copyWith(yukleniyor: false);
    }
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor || !state.dahaFazlaVar || state.sonTarih == null) return;
    state = state.copyWith(yukleniyor: true);
    try {
      final sonuc = await _repo.sonrakiSayfayiGetir(
        tip: 'istek',
        sonTarih: state.sonTarih!,
        siralama: 'olusturma',
      );
      state = state.copyWith(
        ilanlar: [...state.ilanlar, ...sonuc.ilanlar],
        sonTarih: sonuc.sonTarih ?? state.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
    } catch (_) {
      state = state.copyWith(yukleniyor: false);
    }
  }

  void ilanFavoriSayisiGuncelle(String ilanId, int delta) {
    state = state.copyWith(
      ilanlar: state.ilanlar.map((i) {
        if (i.id == ilanId) {
          return i.copyWith(
              favoriSayisi: (i.favoriSayisi + delta).clamp(0, 999999));
        }
        return i;
      }).toList(),
    );
  }

  void ilanGoruntulenmeSayisiArttir(String ilanId) {
    state = state.copyWith(
      ilanlar: state.ilanlar.map((i) {
        if (i.id == ilanId) {
          return i.copyWith(goruntulenmeSayisi: i.goruntulenmeSayisi + 1);
        }
        return i;
      }).toList(),
    );
  }

  void engellenenlerGuncelle(List<String> engellenenler) {
    state = state.copyWith(engellenenler: engellenenler);
  }
}

@riverpod
class TasiyiciIlanlar extends _$TasiyiciIlanlar {
  bool _ilkYuklemeYapildi = false;

  @override
  IlanListeState build() {
    if (!_ilkYuklemeYapildi) {
      _ilkYuklemeYapildi = true;
      Future.microtask(() => _ilkYukle());
    }
    return const IlanListeState(yukleniyor: true);
  }

  IlanRepository get _repo => ref.read(ilanRepositoryProvider);

  Future<void> _ilkYukle({int deneme = 0}) async {
    state = state.copyWith(yukleniyor: true);
    try {
      final sonuc = await _repo.tasiyiciIlanlariniGetir(
        tariheGore: state.siralama == 'tarih',
      );
      state = state.copyWith(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
    } catch (e) {
      debugPrint('Taşıyıcı ilanları yükleme hatası: $e');
      if (deneme < 2) {
        await Future.delayed(const Duration(seconds: 2));
        _ilkYukle(deneme: deneme + 1);
      } else {
        state = state.copyWith(yukleniyor: false);
      }
    }
  }

  Future<void> yenile() async {
    state = IlanListeState(siralama: state.siralama, yukleniyor: true);
    try {
      final sonuc = await _repo.tasiyiciIlanlariniGetir(
        tariheGore: state.siralama == 'tarih',
      );
      state = IlanListeState(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        siralama: state.siralama,
      );
    } catch (_) {
      state = IlanListeState(siralama: state.siralama);
    }
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor || !state.dahaFazlaVar || state.sonTarih == null) return;
    state = state.copyWith(yukleniyor: true);
    try {
      final sonuc = await _repo.sonrakiSayfayiGetir(
        tip: 'tasiyici',
        sonTarih: state.sonTarih!,
        siralama: state.siralama,
      );
      state = state.copyWith(
        ilanlar: [...state.ilanlar, ...sonuc.ilanlar],
        sonTarih: sonuc.sonTarih ?? state.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
    } catch (_) {
      state = state.copyWith(yukleniyor: false);
    }
  }

  Future<void> siralamaGuncelle(String yeniSiralama) async {
    if (state.siralama == yeniSiralama) return;
    state = IlanListeState(siralama: yeniSiralama);
    await _ilkYukle();
  }

  void ilanFavoriSayisiGuncelle(String ilanId, int delta) {
    state = state.copyWith(
      ilanlar: state.ilanlar.map((i) {
        if (i.id == ilanId) {
          return i.copyWith(
              favoriSayisi: (i.favoriSayisi + delta).clamp(0, 999999));
        }
        return i;
      }).toList(),
    );
  }

  void ilanGoruntulenmeSayisiArttir(String ilanId) {
    state = state.copyWith(
      ilanlar: state.ilanlar.map((i) {
        if (i.id == ilanId) {
          return i.copyWith(goruntulenmeSayisi: i.goruntulenmeSayisi + 1);
        }
        return i;
      }).toList(),
    );
  }

  void engellenenlerGuncelle(List<String> engellenenler) {
    state = state.copyWith(engellenenler: engellenenler);
  }
}

// ── Diğer provider'lar ────────────────────────────────────────────────────────

class IlanOlusturState {
  final bool yukleniyor;
  final double yuklemeProgress;
  final int yuklenenResimIndex;
  final String? hata;

  const IlanOlusturState({
    this.yukleniyor = false,
    this.yuklemeProgress = 0.0,
    this.yuklenenResimIndex = 0,
    this.hata,
  });

  IlanOlusturState copyWith({
    bool? yukleniyor,
    double? yuklemeProgress,
    int? yuklenenResimIndex,
    String? hata,
  }) =>
      IlanOlusturState(
        yukleniyor: yukleniyor ?? this.yukleniyor,
        yuklemeProgress: yuklemeProgress ?? this.yuklemeProgress,
        yuklenenResimIndex: yuklenenResimIndex ?? this.yuklenenResimIndex,
        hata: hata,
      );
}

@riverpod
class IlanOlustur extends _$IlanOlustur {
  @override
  IlanOlusturState build() => const IlanOlusturState();

  Future<String?> olustur({
    required IlanModel ilan,
    List<File> resimler = const [],
  }) async {
    state = const IlanOlusturState(yukleniyor: true);
    try {
      final id = await ref.read(ilanRepositoryProvider).ilanOlustur(
        ilan: ilan,
        resimler: resimler,
        onProgress: (index, progress) {
          state = state.copyWith(
            yuklenenResimIndex: index,
            yuklemeProgress: progress,
          );
        },
      );
      state = const IlanOlusturState();
      return id;
    } catch (e) {
      state = IlanOlusturState(hata: e.toString());
      return null;
    }
  }
}

// ── Tekil ilan stream ─────────────────────────────────────────────────────────

@riverpod
Stream<IlanModel?> ilanById(Ref ref, String ilanId) {
  return ref.watch(ilanRepositoryProvider).ilanStream(ilanId);
}

// ── Favori provider'lar ───────────────────────────────────────────────────────

@riverpod
Stream<List<Map<String, dynamic>>> favoriler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(ilanRepositoryProvider).favorilerStream(uid);
}

@riverpod
Stream<bool> ilanFavorideMi(Ref ref, String ilanId) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(false);
  return ref.watch(ilanRepositoryProvider).favorideMi(
    kullaniciId: uid,
    ilanId: ilanId,
  );
}

@riverpod
Stream<List<IlanModel>> kullaniciIlanlarStream(Ref ref, String kullaniciId) {
  return ref.watch(ilanRepositoryProvider).kullaniciIlanlarStream(kullaniciId);
}

@riverpod
Stream<int> ilanFavoriSayisi(Ref ref, String ilanId) {
  return ref.watch(ilanRepositoryProvider).favoriSayisiStream(ilanId);
}

// ── Breadcrumb navigasyon provider'ı ─────────────────────────────────────────

@riverpod
class BreadcrumbIlanTipi extends _$BreadcrumbIlanTipi {
  @override
  String build() => '';

  void set(String tip) => state = tip;
  void temizle() => state = '';
}

@riverpod
class BreadcrumbKategoriFiltresi extends _$BreadcrumbKategoriFiltresi {
  @override
  List<String> build() => [];

  void set(List<String> yol) => state = yol;
  void temizle() => state = [];
}

@riverpod
Set<String> favoriliIlanIdler(Ref ref) {
  final fav = ref.watch(favorilerProvider);
  return fav.when(
    data: (liste) => liste
        .map((f) => f['ilanId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet(),
    loading: () => {},
    error: (_, _) => {},
  );
}

// ── Favori işlemleri ──────────────────────────────────────────────────────────

@riverpod
class FavoriNotifier extends _$FavoriNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  IlanRepository get _repo => ref.read(ilanRepositoryProvider);
  String get _uid => ref.read(currentUserProvider)?.uid ?? '';

  Future<void> ekle(IlanModel ilan) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    await _repo.favoriyeEkle(kullaniciId: uid, ilan: ilan);
    ref.read(istekIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(ilan.id, 1);
    ref.read(tasiyiciIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(ilan.id, 1);
  }

  Future<void> cikar(String ilanId) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    await _repo.favoridanCikar(kullaniciId: uid, ilanId: ilanId);
    ref.read(istekIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(ilanId, -1);
    ref.read(tasiyiciIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(ilanId, -1);
  }
}

// ── Kullanıcının favori ilanları (IlanModel listesi olarak) ──────────────────

final kullaniciFavorileriProvider =
    StreamProvider.autoDispose.family<List<IlanModel>, String>((ref, uid) {
  final repo = ref.watch(ilanRepositoryProvider);
  return repo.favorilerStream(uid).map((liste) => liste
      .map((map) {
        try {
          return IlanModel(
            id:          map['ilanId']      as String? ?? '',
            tip:         map['tip']         as String? ?? '',
            nereden:     map['nereden']     as String? ?? '',
            nereye:      map['nereye']      as String? ?? '',
            urun:        map['urun']        as String? ?? '',
            ucret:       map['ucret']       as String? ?? '',
            kategori:    map['kategori']    as String? ?? 'diger',
            kullaniciId: map['ilanSahibiId'] as String? ?? '',
            kullaniciAd: map['kullaniciAd'] as String? ?? '',
            resimUrl:    map['resimUrl']    as String? ?? '',
          );
        } catch (_) {
          return null;
        }
      })
      .whereType<IlanModel>()
      .toList());
});

// ── İlan işlemleri ────────────────────────────────────────────────────────────

@riverpod
class IlanIslemleri extends _$IlanIslemleri {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  IlanRepository get _repo => ref.read(ilanRepositoryProvider);

  Future<void> pasifYap(String ilanId) async {
    await _repo.ilanPasifYap(ilanId);
  }

  Future<void> sil(String ilanId) async {
    await _repo.ilanSil(ilanId);
  }

  Future<void> goruntulemeKaydet({
    required String kullaniciId,
    required String ilanId,
  }) async {
    await _repo.goruntulenmeyiKaydet(kullaniciId: kullaniciId, ilanId: ilanId);
  }

  Future<void> guncelle(String ilanId, Map<String, dynamic> data) async {
    await _repo.ilanGuncelle(ilanId, data);
  }
}