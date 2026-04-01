import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/kullanici_repository.dart';
import '../domain/kullanici_model.dart';
import '../../auth/providers/auth_provider.dart';
 
part 'profil_provider.g.dart';
 
@riverpod
Stream<KullaniciModel?> benimKullaniciProfil(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(kullaniciRepositoryProvider).kullaniciStream(uid);
}
 
@riverpod
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
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
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
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
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
      state = const AsyncData(null);
      return url;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
}
 
@riverpod
class Engelleme extends _$Engelleme {
  @override
  AsyncValue<void> build() => const AsyncData(null);
 
  KullaniciRepository get _repo => ref.read(kullaniciRepositoryProvider);
 
  Future<void> engelle({required String benimUid, required String hedefUid}) async {
    state = const AsyncLoading();
    try {
      await _repo.engelle(benimUid: benimUid, hedefUid: hedefUid);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
 
  Future<void> engelKaldir({required String benimUid, required String hedefUid}) async {
    state = const AsyncLoading();
    try {
      await _repo.engelKaldir(benimUid: benimUid, hedefUid: hedefUid);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
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
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}