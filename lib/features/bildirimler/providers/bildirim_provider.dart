import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/bildirim_repository.dart';
import '../domain/bildirim_model.dart';
import '../../auth/providers/auth_provider.dart';

part 'bildirim_provider.g.dart';

/// Kullanıcının tüm bildirimlerini real-time dinler.
/// [keepAlive] ile tab değişimlerinde dispose olmaz, Firestore bağlantısı korunur.
/// uid null olduğunda (çıkış yapıldığında) provider temizlenir.
@Riverpod(keepAlive: true)
Stream<List<BildirimModel>> bildirimler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;

  if (uid == null) {
    Future.microtask(() => ref.invalidateSelf());
    return const Stream.empty();
  }

  return ref.watch(bildirimRepositoryProvider).bildirimlerStream(uid);
}

/// Okunmamış bildirim sayısı — navigation badge için.
/// [keepAlive] ile uygulama boyunca aktif kalır.
@Riverpod(keepAlive: true)
Stream<int> okunmamisBildirimSayi(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;

  if (uid == null) {
    Future.microtask(() => ref.invalidateSelf());
    return Stream.value(0);
  }

  return ref.watch(bildirimRepositoryProvider).okunmamisSayiStream(uid);
}

/// Bildirim işlemleri — okuma, silme, gönderme.
@riverpod
class BildirimNotifier extends _$BildirimNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  BildirimRepository get _repo => ref.read(bildirimRepositoryProvider);

  Future<void> okunduIsaretle(String bildirimId) async {
    try {
      await _repo.okunduIsaretle(bildirimId);
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> tumunuOkunduIsaretle() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    try {
      await _repo.tumunuOkunduIsaretle(uid);
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> bildirimSil(String bildirimId) async {
    try {
      await _repo.bildirimSil(bildirimId);
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> mesajBildirimiGonder({
    required String aliciId,
    required String gondereId,
    required String gondereAd,
    required String ilanBaslik,
    required String sohbetId,
  }) async {
    try {
      await _repo.mesajBildirimiGonder(
        aliciId: aliciId,
        gondereId: gondereId,
        gondereAd: gondereAd,
        ilanBaslik: ilanBaslik,
        sohbetId: sohbetId,
      );
    } catch (_) {}
  }
}