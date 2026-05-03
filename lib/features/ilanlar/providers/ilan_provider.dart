import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/ilan_repository.dart';
import '../domain/ilan_model.dart';
import '../../auth/providers/auth_provider.dart';

part 'ilan_provider.g.dart';

// DocumentSnapshot YOK — cursor olarak DateTime kullanılır
class IlanListeState {
  final List<IlanModel> ilanlar;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final DateTime? sonTarih;
  final String siralama;
  final String? filtreKategori;
  final String filtreNereye;
  final String filtreArama;
  final List<String> engellenenler;

  const IlanListeState({
    this.ilanlar = const [],
    this.yukleniyor = false,
    this.dahaFazlaVar = true,
    this.sonTarih,
    this.siralama = 'tarih',
    this.filtreKategori,
    this.filtreNereye = '',
    this.filtreArama = '',
    this.engellenenler = const [],
  });

  IlanListeState copyWith({
    List<IlanModel>? ilanlar,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    DateTime? sonTarih,
    String? siralama,
    String? filtreKategori,
    bool clearFiltreKategori = false,
    String? filtreNereye,
    String? filtreArama,
    List<String>? engellenenler,
  }) =>
      IlanListeState(
        ilanlar: ilanlar ?? this.ilanlar,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        sonTarih: sonTarih ?? this.sonTarih,
        siralama: siralama ?? this.siralama,
        filtreKategori: clearFiltreKategori
            ? null
            : (filtreKategori ?? this.filtreKategori),
        filtreNereye: filtreNereye ?? this.filtreNereye,
        filtreArama: filtreArama ?? this.filtreArama,
        engellenenler: engellenenler ?? this.engellenenler,
      );

  List<IlanModel> get filtrelenmis {
    var liste = ilanlar;
    if (engellenenler.isNotEmpty) {
      liste = liste.where((i) => !engellenenler.contains(i.kullaniciId)).toList();
    }
    if (filtreKategori != null) {
      liste = liste.where((i) => i.kategori == filtreKategori).toList();
    }
    if (filtreNereye.isNotEmpty) {
      final q = filtreNereye.toLowerCase();
      liste = liste.where((i) => i.nereye.toLowerCase().contains(q)).toList();
    }
    if (filtreArama.isNotEmpty) {
      final q = filtreArama.toLowerCase();
      liste = liste.where((i) =>
        i.urun.toLowerCase().contains(q) ||
        i.nereden.toLowerCase().contains(q) ||
        i.nereye.toLowerCase().contains(q) ||
        i.notlar.toLowerCase().contains(q) ||
        i.kullaniciAd.toLowerCase().contains(q)
      ).toList();
    }
    return liste;
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

  Future<void> _ilkYukle() async {
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
      debugPrint('İstek ilanları yükleme hatası: $e');
      state = state.copyWith(yukleniyor: false);
    }
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

  void filtreKategoriGuncelle(String? kategori) {
    state = state.copyWith(
      filtreKategori: kategori,
      clearFiltreKategori: kategori == null,
    );
  }

  void filtreNereyeGuncelle(String nereye) =>
      state = state.copyWith(filtreNereye: nereye);

  void filtreAramaGuncelle(String arama) =>
      state = state.copyWith(filtreArama: arama);

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

  void filtreleriTemizle() {
    state = state.copyWith(filtreNereye: '', clearFiltreKategori: true);
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

  Future<void> _ilkYukle() async {
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
      state = state.copyWith(yukleniyor: false);
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

  void filtreNereyeGuncelle(String nereye) =>
      state = state.copyWith(filtreNereye: nereye);

  void filtreAramaGuncelle(String arama) =>
      state = state.copyWith(filtreArama: arama);

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

// ── Tekil ilan stream — bildirimden açılırken kullanılır ──────────────────────

/// Sadece ilanId ile Firestore'dan güncel ilan verisini izler.
/// IlanDetayScreen bu provider'ı kullanır.
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
