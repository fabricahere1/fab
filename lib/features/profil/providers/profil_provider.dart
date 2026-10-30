import 'dart:async';
import '../../../shared/utils/app_hata_yonetici.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../ilanlar/domain/ilan_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/kullanici_repository.dart';
import '../domain/kullanici_model.dart';
import '../../auth/providers/auth_provider.dart';

export '../data/kullanici_repository.dart' show kullaniciRepositoryProvider;

part 'profil_provider.g.dart';

const _profilYenilemeAraligi = Duration(seconds: 20);

// Artık Stream DEĞİL (AWS backend'inde canlı akış yok) — periyodik
// yenileme, bildirimler/sohbetler ile aynı desen.
@Riverpod(keepAlive: true)
class BenimKullaniciProfil extends _$BenimKullaniciProfil {
  Timer? _zamanlayici;

  @override
  Future<KullaniciModel?> build() async {
    ref.onDispose(() => _zamanlayici?.cancel());
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return null;

    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(_profilYenilemeAraligi, (_) => yenile());

    return ref.read(kullaniciRepositoryProvider).benimProfilimGetir();
  }

  Future<void> yenile() async {
    if (ref.read(currentUserProvider)?.uid == null) return;
    try {
      final profil = await ref.read(kullaniciRepositoryProvider).benimProfilimGetir();
      if (!ref.mounted) return;
      state = AsyncData(profil);
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'benimKullaniciProfil.yenile');
    }
  }
}

@Riverpod(keepAlive: true)
Future<KullaniciModel?> kullaniciBilgi(Ref ref, String uid) {
  return ref.watch(kullaniciRepositoryProvider).kullaniciGetir(uid);
}

// keepAlive ZORUNLU: profilGuncelle/profilTamamla ağ çağrısı bittikten
// SONRA kendi ref'i üzerinden benimKullaniciProfilProvider'ı invalidate
// ediyor — autoDispose olsaydı erken temizlenip "Ref ... disposed" hatası
// fırlatabilirdi (bkz. 2026-10-23 Google girişi çökmesiyle aynı kök sebep).
@Riverpod(keepAlive: true)
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
      ref.invalidate(benimKullaniciProfilProvider);
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
      ref.invalidate(benimKullaniciProfilProvider);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

// keepAlive ZORUNLU: engelle()/engelKaldir() ağ çağrısı bittikten SONRA
// kendi ref'i üzerinden engellenenlerProvider'ı invalidate ediyor — aynı
// risk sınıfı (bkz. yukarıdaki ProfilDuzenle notu).
@Riverpod(keepAlive: true)
class Engelleme extends _$Engelleme {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  KullaniciRepository get _repo => ref.read(kullaniciRepositoryProvider);

  Future<bool> engelle({
    required String benimUid,
    required String hedefUid,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.engelle(benimUid: benimUid, hedefUid: hedefUid);
      ref.invalidate(engellenenlerProvider);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> engelKaldir({
    required String benimUid,
    required String hedefUid,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.engelKaldir(benimUid: benimUid, hedefUid: hedefUid);
      ref.invalidate(engellenenlerProvider);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

// Artık ayrı bir GET /v3/engellenenlerim çağrısı — backend profil
// yanıtında bu alan yok (bkz. v3_engelleme_routes.go).
@riverpod
Future<List<String>> engellenenler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Future.value(const []);
  return ref.read(kullaniciRepositoryProvider).engellenenlerGetir();
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
    String degerlendirmeId = '',
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(kullaniciRepositoryProvider).sikayetGonder(
        sikayetEdenId: sikayetEdenId,
        hedefId: hedefId,
        hedefAd: hedefAd,
        sebep: sebep,
        ilanId: ilanId,
        degerlendirmeId: degerlendirmeId,
      );
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

/// Kullanıcının kendi ilanlarını getirir.
@Riverpod(keepAlive: true)
Future<List<IlanModel>> ilanlarim(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Future.value(const []);
  return ref.watch(ilanRepositoryProvider).ilanlarimGetir();
}

// ── Takip listesi provider'ları ──────────────────────────────────────────────

@riverpod
Future<List<String>> takipciIdleri(Ref ref, String kullaniciId) {
  return ref.watch(kullaniciRepositoryProvider).takipciIdleriGetir(kullaniciId);
}

@riverpod
Future<List<String>> takipEdilenIdleri(Ref ref, String kullaniciId) {
  return ref.watch(kullaniciRepositoryProvider).takipEdilenIdleriGetir(kullaniciId);
}

/// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.
@riverpod
Future<Map<String, DateTime>> takipEdilenTarihleri(Ref ref, String kullaniciId) {
  return ref.watch(kullaniciRepositoryProvider).takipEdilenTarihleriGetir(kullaniciId);
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

// ── Takipçi sayısı delta (optimistik) ────────────────────────────────────────

@Riverpod(keepAlive: true)
class TakipciDelta extends _$TakipciDelta {
  @override
  Map<String, int> build() => {};

  void arttir(String uid) =>
      state = {...state, uid: (state[uid] ?? 0) + 1};
  void azalt(String uid) =>
      state = {...state, uid: (state[uid] ?? 0) - 1};
  void temizle(String uid) {
    if (!state.containsKey(uid)) return;
    final yeni = Map<String, int>.from(state)..remove(uid);
    state = yeni;
  }
}

// ── Takip provider'ları ───────────────────────────────────────────────────────

// Ham değer — backend'den tek seferlik okuma (Stream yok). optimistikTakipProvider'a
// bağımlı DEĞİL — bkz. takipEdiyorMu() nasıl birleştirdiği.
@riverpod
Future<bool> takipEdiyorMuHam(Ref ref, String takipEdilenId) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Future.value(false);
  return ref.watch(kullaniciRepositoryProvider).takipEdiyorMu(
    takipciId: uid,
    takipEdilenId: takipEdilenId,
  );
}

@riverpod
bool takipEdiyorMu(Ref ref, String takipEdilenId) {
  final optimistik = ref.watch(
    optimistikTakipProvider.select((s) => s[takipEdilenId]),
  );
  final hamAsync = ref.watch(takipEdiyorMuHamProvider(takipEdilenId));
  return optimistik ?? hamAsync.value ?? false;
}

@Riverpod(keepAlive: true)
class TakipIslemleri extends _$TakipIslemleri {
  KullaniciRepository get _repo => ref.read(kullaniciRepositoryProvider);

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> takipEt(String takipEdilenId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return false;
    ref.read(optimistikTakipProvider.notifier).takipEt(takipEdilenId);
    try {
      await _repo.takipEt(takipciId: uid, takipEdilenId: takipEdilenId);
      if (!ref.mounted) return false;
      ref.read(takipciDeltaProvider.notifier).arttir(takipEdilenId);
      return true;
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'takip.et');
      if (!ref.mounted) return false;
      ref.read(optimistikTakipProvider.notifier).temizle(takipEdilenId);
      return false;
    }
  }

  Future<bool> takipiBirak(String takipEdilenId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return false;
    ref.read(optimistikTakipProvider.notifier).takipiBirak(takipEdilenId);
    try {
      await _repo.takipiBirak(takipciId: uid, takipEdilenId: takipEdilenId);
      if (!ref.mounted) return false;
      ref.read(takipciDeltaProvider.notifier).azalt(takipEdilenId);
      return true;
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'takip.birak');
      if (!ref.mounted) return false;
      ref.read(optimistikTakipProvider.notifier).temizle(takipEdilenId);
      return false;
    }
  }
}
