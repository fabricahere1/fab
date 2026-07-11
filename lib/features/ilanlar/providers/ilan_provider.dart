import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/ilan_repository.dart';
import '../domain/ilan_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

export '../data/ilan_repository.dart' show ilanRepositoryProvider;

part 'ilan_provider.g.dart';

class IlanListeState {
  final List<IlanModel> ilanlar;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final DateTime? sonTarih;
  final String siralama;
  final List<String> engellenenler;
  final String? hata;

  const IlanListeState({
    this.ilanlar = const [],
    this.yukleniyor = false,
    this.dahaFazlaVar = true,
    this.sonTarih,
    this.siralama = 'tarih',
    this.engellenenler = const [],
    this.hata,
  });

  IlanListeState copyWith({
    List<IlanModel>? ilanlar,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    DateTime? sonTarih,
    String? siralama,
    List<String>? engellenenler,
    String? hata,
    bool temizleHata = false,
  }) =>
      IlanListeState(
        ilanlar: ilanlar ?? this.ilanlar,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        sonTarih: sonTarih ?? this.sonTarih,
        siralama: siralama ?? this.siralama,
        engellenenler: engellenenler ?? this.engellenenler,
        hata: temizleHata ? null : (hata ?? this.hata),
      );

  List<IlanModel> get filtrelenmis {
    if (engellenenler.isEmpty) return ilanlar;
    return ilanlar.where((i) => !engellenenler.contains(i.kullaniciId)).toList();
  }
}

@Riverpod(keepAlive: true)
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
      if (deneme < 2) {
        await Future.delayed(const Duration(seconds: 2));
        _ilkYukle(deneme: deneme + 1);
      } else {
        AppHataYonetici.logla(e, StackTrace.current, etiket: 'istekIlanlar.ilkYukle');
        state = state.copyWith(yukleniyor: false, hata: 'İlanlar yüklenemedi. Tekrar dene.');
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
        ref.read(sayacDeltaProvider.notifier)
            .temizleToplu(sonuc.ilanlar.map((i) => i.id));
      }
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'istekIlanlar.arkaGuncelle');
    }
  }

  Future<void> yenile() async {
    state = state.copyWith(yukleniyor: true);
    try {
      final sonuc = await _repo.istekIlanlariniGetir(forceServer: true)
          .timeout(const Duration(seconds: 15));
      state = state.copyWith(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
      ref.read(sayacDeltaProvider.notifier)
          .temizleToplu(sonuc.ilanlar.map((i) => i.id));
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'istekIlanlar.yenile');
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
      final mevcutIdler = state.ilanlar.map((m) => m.id).toSet();
      final yeniIlanlar = sonuc.ilanlar.where((i) => !mevcutIdler.contains(i.id)).toList();
      state = state.copyWith(
        ilanlar: [...state.ilanlar, ...yeniIlanlar],
        sonTarih: sonuc.sonTarih ?? state.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
      ref.read(sayacDeltaProvider.notifier)
          .temizleToplu(yeniIlanlar.map((i) => i.id));
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'istekIlanlar.dahaFazlaYukle');
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

  void ilanEkle(IlanModel ilan) {
    if (state.ilanlar.any((i) => i.id == ilan.id)) return;
    state = state.copyWith(ilanlar: [ilan, ...state.ilanlar]);
  }

  void ilanKaldir(String ilanId) {
    state = state.copyWith(
      ilanlar: state.ilanlar.where((i) => i.id != ilanId).toList(),
    );
  }

  void engellenenlerGuncelle(List<String> engellenenler) {
    state = state.copyWith(engellenenler: engellenenler);
  }
}

@Riverpod(keepAlive: true)
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
      final sonuc = await _repo.tasiyiciIlanlariniGetir();
      state = state.copyWith(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
    } catch (e) {
      if (deneme < 2) {
        await Future.delayed(const Duration(seconds: 2));
        _ilkYukle(deneme: deneme + 1);
      } else {
        AppHataYonetici.logla(e, StackTrace.current, etiket: 'tasiyiciIlanlar.ilkYukle');
        state = state.copyWith(yukleniyor: false, hata: 'İlanlar yüklenemedi. Tekrar dene.');
      }
    }
  }

  Future<void> yenile() async {
    state = IlanListeState(siralama: state.siralama, yukleniyor: true);
    try {
      final sonuc = await _repo.tasiyiciIlanlariniGetir(forceServer: true)
          .timeout(const Duration(seconds: 15));
      state = IlanListeState(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        siralama: state.siralama,
      );
      ref.read(sayacDeltaProvider.notifier)
          .temizleToplu(sonuc.ilanlar.map((i) => i.id));
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'tasiyiciIlanlar.yenile');
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
      final mevcutIdler = state.ilanlar.map((m) => m.id).toSet();
      final yeniIlanlar = sonuc.ilanlar.where((i) => !mevcutIdler.contains(i.id)).toList();
      state = state.copyWith(
        ilanlar: [...state.ilanlar, ...yeniIlanlar],
        sonTarih: sonuc.sonTarih ?? state.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
      ref.read(sayacDeltaProvider.notifier)
          .temizleToplu(yeniIlanlar.map((i) => i.id));
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'tasiyiciIlanlar.dahaFazlaYukle');
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

  void ilanEkle(IlanModel ilan) {
    if (state.ilanlar.any((i) => i.id == ilan.id)) return;
    state = state.copyWith(ilanlar: [ilan, ...state.ilanlar]);
  }

  void ilanKaldir(String ilanId) {
    state = state.copyWith(
      ilanlar: state.ilanlar.where((i) => i.id != ilanId).toList(),
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

@Riverpod(keepAlive: true)
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

  /// Moderasyon sonucunu bekler. [ilanId] için Firestore'u dinler;
  /// "yayinda" veya "reddedildi" durumuna ulaşınca tamamlanır.
  /// [zaman asimi] içinde sonuç gelmezse null döner.
  /// Moderasyon sonucunu bekler: true=yayında, false=reddedildi, null=timeout
  Future<bool?> durumBekle(
    String ilanId, {
    Duration timeout = const Duration(seconds: 40),
  }) {
    final completer = Completer<bool?>();
    final firestore = ref.read(ilanRepositoryProvider).firestore;
    StreamSubscription? sub;
    Timer? timer;

    timer = Timer(timeout, () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(null);
    });

    sub = firestore.collection('ilanlar').doc(ilanId).snapshots().listen(
      (snap) {
        final durum = snap.data()?['durum'] as String?;
        // 'onayBekliyor' = moderasyon henüz sonuçlanmadı, bekle.
        // Hem create (ilk snapshot zaten onayBekliyor olur) hem edit (guncelle()
        // durum'u onayBekliyor'a çekiyor) akışında doğru çalışır.
        if (durum == 'onayBekliyor') return;
        if (durum == 'yayinda' || durum == 'reddedildi') {
          timer?.cancel();
          sub?.cancel();
          if (!completer.isCompleted) completer.complete(durum == 'yayinda');
        }
      },
      onError: (_) {
        timer?.cancel();
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    return completer.future;
  }

  /// İlanı (gerekiyorsa yeni resimlerle) günceller. Yükleme overlay'i görünsün
  /// diye [IlanOlusturState]'i sürer. Kayıttan sonra sunucudaki
  /// `ilanGuncellemeModerasyon` (onUpdate) içeriği yeniden modere edip uygunsa
  /// yayınlar, uygunsuzsa yayından kaldırır.
  Future<bool> guncelle(
    String ilanId,
    Map<String, dynamic> data, {
    List<File> yeniResimler = const [],
    List<String> mevcutResimler = const [],
  }) async {
    state = const IlanOlusturState(yukleniyor: true, yuklemeProgress: 0.1);
    try {
      await ref.read(ilanRepositoryProvider).ilanResimliGuncelle(
        ilanId: ilanId,
        data: {
          ...data,
          'durum': 'onayBekliyor',
          'redSebebi': '',
        },
        yeniResimler: yeniResimler,
        mevcutResimler: mevcutResimler,
        onProgress: (index, progress) {
          state = state.copyWith(
            yuklenenResimIndex: index,
            yuklemeProgress: progress,
          );
        },
      );
      state = const IlanOlusturState(yukleniyor: true, yuklemeProgress: 1.0);
      await Future.delayed(const Duration(milliseconds: 800));
      state = const IlanOlusturState();
      return true;
    } catch (e) {
      state = IlanOlusturState(hata: e.toString());
      return false;
    }
  }
}

// ── Tekil ilan stream ─────────────────────────────────────────────────────────

@riverpod
Stream<IlanModel?> ilanById(Ref ref, String ilanId) {
  return ref.watch(ilanRepositoryProvider).ilanStream(ilanId);
}

// ── Son 24 saat ilanları ─────────────────────────────────────────────────────

@riverpod
Future<List<IlanModel>> son24SaatIlanlar(Ref ref) {
  return ref.watch(ilanRepositoryProvider).son24SaatIlanlariniGetir();
}

// ── Haftanın en'leri ─────────────────────────────────────────────────────────

@riverpod
Future<List<IlanModel>> haftaninEnleri(Ref ref) {
  return ref.watch(ilanRepositoryProvider).haftaninEnleriGetir();
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

// keepAlive kasıtlı olarak kaldırıldı — family provider'da keepAlive, her farklı
// kullaniciId için ayrı bir stream instance'ı sonsuza kadar hafızada biriktirir.
// autoDispose (varsayılan) ile, provider widget tree'den kalkınca stream kapanır.
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

// ── Sayaç delta extension — tüm kartlarda tek satırla kullanılır ─────────────

extension CanliSayacX on WidgetRef {
  int canliFavoriSayisi(IlanModel ilan) {
    final delta = watch(sayacDeltaProvider.select((s) => s.favori[ilan.id] ?? 0));
    return (ilan.favoriSayisi + delta).clamp(0, 999999);
  }

  int canliGoruntulenmeSayisi(IlanModel ilan) {
    final delta = watch(sayacDeltaProvider.select((s) => s.goruntulenme[ilan.id] ?? 0));
    return (ilan.goruntulenmeSayisi + delta).clamp(0, 999999);
  }
}

// ── Sayaç delta provider ─────────────────────────────────────────────────────

class SayacDeltaState {
  final Map<String, int> favori;
  final Map<String, int> goruntulenme;
  const SayacDeltaState({this.favori = const {}, this.goruntulenme = const {}});
}

@Riverpod(keepAlive: true)
class SayacDelta extends _$SayacDelta {
  @override
  SayacDeltaState build() => const SayacDeltaState();

  void favoriArttir(String id) => state = SayacDeltaState(
        favori: {...state.favori, id: (state.favori[id] ?? 0) + 1},
        goruntulenme: state.goruntulenme,
      );

  void favoriAzalt(String id) => state = SayacDeltaState(
        favori: {...state.favori, id: (state.favori[id] ?? 0) - 1},
        goruntulenme: state.goruntulenme,
      );

  void goruntulenmeArttir(String id) => state = SayacDeltaState(
        favori: state.favori,
        goruntulenme: {
          ...state.goruntulenme,
          id: (state.goruntulenme[id] ?? 0) + 1,
        },
      );

  void temizleToplu(Iterable<String> ilanIdler) {
    final idSet = ilanIdler.toSet();
    final f = Map<String, int>.from(state.favori)
      ..removeWhere((id, _) => idSet.contains(id));
    final g = Map<String, int>.from(state.goruntulenme)
      ..removeWhere((id, _) => idSet.contains(id));
    if (f.length != state.favori.length ||
        g.length != state.goruntulenme.length) {
      state = SayacDeltaState(favori: f, goruntulenme: g);
    }
  }
}

// ── Optimistik favori state ───────────────────────────────────────────────────

@riverpod
class OptimistikFavori extends _$OptimistikFavori {
  @override
  Map<String, bool> build() => {};

  void ekle(String ilanId) => state = {...state, ilanId: true};
  void cikar(String ilanId) => state = {...state, ilanId: false};
  void temizle(String ilanId) {
    final yeni = Map<String, bool>.from(state)..remove(ilanId);
    state = yeni;
  }
}

@riverpod
Set<String> favoriliIlanIdler(Ref ref) {
  final fav       = ref.watch(favorilerProvider);
  final optimistik = ref.watch(optimistikFavoriProvider);

  final base = fav.when(
    data: (liste) => liste
        .map((f) => f['ilanId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet(),
    loading: () => <String>{},
    error: (_, _) => <String>{},
  );

  final sonuc = Set<String>.from(base);
  optimistik.forEach((id, eklendi) {
    if (eklendi) { sonuc.add(id); } else { sonuc.remove(id); }
  });
  return sonuc;
}

// ── Favori işlemleri ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class FavoriNotifier extends _$FavoriNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  IlanRepository get _repo => ref.read(ilanRepositoryProvider);
  String get _uid => ref.read(currentUserProvider)?.uid ?? '';

  Future<void> ekle(IlanModel ilan) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    if (ilan.kullaniciId == uid) return; // kendi ilanını favorileyemezsin
    ref.read(optimistikFavoriProvider.notifier).ekle(ilan.id);
    try {
      await _repo.favoriyeEkle(kullaniciId: uid, ilan: ilan);
      // keepAlive eklendiyse bu kontrol artık tetiklenmemeli, ama provider
      // ileride yanlışlıkla autoDispose'a çevrilirse çökme yerine sessizce
      // çıkmayı garanti eden bir güvenlik ağı olarak kalsın.
      // Başarılı yazma sonrası optimistik kaydı temizle — gerçek Firestore
      // stream'i artık güncel olduğu için devreye girebilsin.
      if (!ref.mounted) return;
      ref.read(sayacDeltaProvider.notifier).favoriArttir(ilan.id);
      ref.read(optimistikFavoriProvider.notifier).temizle(ilan.id);
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'favoriNotifier.ekle');
      if (!ref.mounted) return;
      ref.read(optimistikFavoriProvider.notifier).temizle(ilan.id);
    }
  }

  Future<void> cikar(String ilanId) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    ref.read(optimistikFavoriProvider.notifier).cikar(ilanId);
    try {
      await _repo.favoridanCikar(kullaniciId: uid, ilanId: ilanId);
      if (!ref.mounted) return;
      ref.read(sayacDeltaProvider.notifier).favoriAzalt(ilanId);
      ref.read(optimistikFavoriProvider.notifier).temizle(ilanId);
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'favoriNotifier.cikar');
      if (!ref.mounted) return;
      ref.read(optimistikFavoriProvider.notifier).temizle(ilanId);
    }
  }
}

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
    if (!ref.mounted) return;
    ref.read(istekIlanlarProvider.notifier).ilanKaldir(ilanId);
    ref.read(tasiyiciIlanlarProvider.notifier).ilanKaldir(ilanId);
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

// ── Nav bar görünürlük provider'ı ────────────────────────────────────────────
// ilanlar_screen scroll direction'ını buraya yazıyor
// home_screen buradan okuyor

@Riverpod(keepAlive: true)
class NavBarGizli extends _$NavBarGizli {
  @override
  bool build() => false;

  void gizle() { if (!state) state = true; }
  void goster() { if (state) state = false; }
}