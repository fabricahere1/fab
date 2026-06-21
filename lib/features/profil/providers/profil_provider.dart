import 'dart:io';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../ilanlar/domain/ilan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/kullanici_repository.dart';
import '../domain/kullanici_model.dart';
import '../../auth/providers/auth_provider.dart';

export '../data/kullanici_repository.dart' show kullaniciRepositoryProvider;

part 'profil_provider.g.dart';

@riverpod
Stream<KullaniciModel?> benimKullaniciProfil(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(kullaniciRepositoryProvider).kullaniciStream(uid);
}

@Riverpod(keepAlive: true)
Future<KullaniciModel?> kullaniciBilgi(Ref ref, String uid) {
  return ref.watch(kullaniciRepositoryProvider).kullaniciGetir(uid);
}

@riverpod
class ProfilDuzenle extends _$ProfilDuzenle {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  KullaniciRepository get _repo => ref.read(kullaniciRepositoryProvider);

  Future<bool> profilGuncelle({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.profilGuncelle(uid: uid, data: data);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> profilTamamla({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.profilTamamla(uid: uid, data: data);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<String?> fotoGuncelle({
    required String uid,
    required File foto,
  }) async {
    state = const AsyncLoading();
    try {
      final url = await _repo.profilFotoYukle(uid: uid, foto: foto);
      if (ref.mounted) state = const AsyncData(null);
      return url;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
}

@riverpod
class Engelleme extends _$Engelleme {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  KullaniciRepository get _repo => ref.read(kullaniciRepositoryProvider);

  Future<void> engelle({
    required String benimUid,
    required String hedefUid,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.engelle(benimUid: benimUid, hedefUid: hedefUid);
      if (ref.mounted) state = const AsyncData(null);
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> engelKaldir({
    required String benimUid,
    required String hedefUid,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.engelKaldir(benimUid: benimUid, hedefUid: hedefUid);
      if (ref.mounted) state = const AsyncData(null);
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }
}

@riverpod
Stream<List<String>> engellenenler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(kullaniciRepositoryProvider).engellenenlerStream(uid);
}

@riverpod
class Sikayet extends _$Sikayet {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> sikayetGonder({
    required String sikayetEdenId,
    required String hedefId,
    required String hedefAd,
    required String sebep,
    String ilanId = '',
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(kullaniciRepositoryProvider).sikayetGonder(
        sikayetEdenId: sikayetEdenId,
        hedefId: hedefId,
        hedefAd: hedefAd,
        sebep: sebep,
        ilanId: ilanId,
      );
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

/// Kullanıcının kendi ilanlarını real-time dinler.
/// [keepAlive] sayesinde sayfa kapanınca dispose olmaz,
/// tekrar açılınca Firestore'a yeniden bağlanmaz.
/// uid null olduğunda (çıkış yapıldığında) provider invalidate edilir.
@Riverpod(keepAlive: true)
Stream<List<IlanModel>> ilanlarim(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;

  if (uid == null) {
    Future.microtask(() => ref.invalidateSelf());
    return const Stream.empty();
  }

  return ref.watch(ilanRepositoryProvider).kullaniciIlanlarStream(uid);
}

// ── Takip listesi provider'ları ──────────────────────────────────────────────

@riverpod
Stream<List<String>> takipciIdleri(Ref ref, String kullaniciId) {
  return ref.watch(kullaniciRepositoryProvider).takipciIdleriStream(kullaniciId);
}

@riverpod
Stream<List<String>> takipEdilenIdleri(Ref ref, String kullaniciId) {
  return ref.watch(kullaniciRepositoryProvider).takipEdilenIdleriStream(kullaniciId);
}

/// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.
@riverpod
Stream<Map<String, DateTime>> takipEdilenTarihleri(Ref ref, String kullaniciId) {
  return ref.watch(kullaniciRepositoryProvider).takipEdilenTarihleriStream(kullaniciId);
}

/// 4.0 ve üzeri ortalama puana sahip taşıyıcılar (kendisi hariç).
@riverpod
Future<List<KullaniciModel>> yuksekPuanliTasiyicilar(Ref ref) async {
  final benimUid = ref.watch(currentUserProvider)?.uid;
  final liste = await ref.watch(kullaniciRepositoryProvider).yuksekPuanliTasiyicilariGetir();
  return liste.where((k) => k.id != benimUid).toList();
}

/// 4.0 ve üzeri ortalama puana sahip istekçiler (kendisi hariç).
@riverpod
Future<List<KullaniciModel>> yuksekPuanliIstekciler(Ref ref) async {
  final benimUid = ref.watch(currentUserProvider)?.uid;
  final liste = await ref.watch(kullaniciRepositoryProvider).yuksekPuanliIstekcileriGetir();
  return liste.where((k) => k.id != benimUid).toList();
}

@riverpod
Future<KullaniciModel?> kullaniciBilgisi(Ref ref, String uid) {
  return ref.watch(kullaniciRepositoryProvider).kullaniciGetir(uid);
}

// ── Optimistik takip state ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class OptimistikTakip extends _$OptimistikTakip {
  @override
  Map<String, bool> build() => {}; // takipEdilenId → true:takip / false:bırak

  void takipEt(String id) => state = {...state, id: true};
  void takipiBirak(String id) => state = {...state, id: false};
  void temizle(String id) {
    final yeni = Map<String, bool>.from(state)..remove(id);
    state = yeni;
  }
}

// ── Takip provider'ları ───────────────────────────────────────────────────────

@riverpod
Stream<bool> takipEdiyorMu(Ref ref, String takipEdilenId) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(false);

  final optimistik = ref.watch(optimistikTakipProvider);
  if (optimistik.containsKey(takipEdilenId)) {
    return Stream.value(optimistik[takipEdilenId]!);
  }

  return ref.watch(kullaniciRepositoryProvider).takipEdiyorMu(
    takipciId: uid,
    takipEdilenId: takipEdilenId,
  );
}

@riverpod
class TakipIslemleri extends _$TakipIslemleri {
  late final KullaniciRepository _repo;

  @override
  AsyncValue<void> build() {
    _repo = ref.read(kullaniciRepositoryProvider);
    return const AsyncData(null);
  }

  Future<void> takipEt(String takipEdilenId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    ref.read(optimistikTakipProvider.notifier).takipEt(takipEdilenId);
    try {
      await _repo.takipEt(takipciId: uid, takipEdilenId: takipEdilenId);
    } catch (_) {
      ref.read(optimistikTakipProvider.notifier).temizle(takipEdilenId);
    }
  }

  Future<void> takipiBirak(String takipEdilenId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    ref.read(optimistikTakipProvider.notifier).takipiBirak(takipEdilenId);
    try {
      await _repo.takipiBirak(takipciId: uid, takipEdilenId: takipEdilenId);
    } catch (_) {
      ref.read(optimistikTakipProvider.notifier).temizle(takipEdilenId);
    }
  }
}