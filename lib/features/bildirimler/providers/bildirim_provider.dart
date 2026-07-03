import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/bildirim_repository.dart';
import '../domain/bildirim_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

part 'bildirim_provider.g.dart';

/// Kullanıcının tüm bildirimlerini real-time dinler.
/// uid değişince (hesap geçişi) provider otomatik yeniden başlar.
@riverpod
Stream<List<BildirimModel>> bildirimler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(bildirimRepositoryProvider).bildirimlerStream(uid);
}

/// Okunmamış bildirim sayısı — navigation badge için.
/// autoDispose: uid değişince (logout/login) eski stream otomatik kapanır.
@riverpod
Stream<int> okunmamisBildirimSayi(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(0);
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
    } catch (e, s) { AppHataYonetici.logla(e, s, etiket: 'bildirimProvider'); }
  }
}