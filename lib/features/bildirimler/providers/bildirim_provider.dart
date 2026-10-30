// lib/features/bildirimler/providers/bildirim_provider.dart
//
// Firestore stream'lerinin yerini AWS backend'ine periyodik polling
// alıyor — gerçek zamanlı değil ama 20sn'de bir tazeleniyor (bildirim
// gelen kutusu için kabul edilebilir bir gecikme, sohbet gibi anlık
// olması gerekmiyor).

import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/bildirim_repository.dart';
import '../domain/bildirim_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

part 'bildirim_provider.g.dart';

const _bildirimYenilemeAraligi = Duration(seconds: 20);

@Riverpod(keepAlive: true)
class Bildirimler extends _$Bildirimler {
  Timer? _zamanlayici;

  @override
  Future<List<BildirimModel>> build() async {
    ref.onDispose(() => _zamanlayici?.cancel());
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return [];

    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(_bildirimYenilemeAraligi, (_) => yenile());

    return ref.read(bildirimRepositoryProvider).bildirimleriGetir();
  }

  Future<void> yenile() async {
    if (ref.read(currentUserProvider)?.uid == null) return;
    try {
      final liste = await ref.read(bildirimRepositoryProvider).bildirimleriGetir();
      if (!ref.mounted) return;
      state = AsyncData(liste);
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'bildirimler.yenile');
    }
  }
}

@Riverpod(keepAlive: true)
class OkunmamisBildirimSayi extends _$OkunmamisBildirimSayi {
  Timer? _zamanlayici;

  @override
  Future<int> build() async {
    ref.onDispose(() => _zamanlayici?.cancel());
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return 0;

    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(_bildirimYenilemeAraligi, (_) => yenile());

    return ref.read(bildirimRepositoryProvider).okunmamisSayiGetir();
  }

  Future<void> yenile() async {
    if (ref.read(currentUserProvider)?.uid == null) return;
    try {
      final sayi = await ref.read(bildirimRepositoryProvider).okunmamisSayiGetir();
      if (!ref.mounted) return;
      state = AsyncData(sayi);
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'okunmamisBildirimSayi.yenile');
    }
  }
}

/// Bildirim işlemleri — okuma, silme.
@riverpod
class BildirimNotifier extends _$BildirimNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  BildirimRepository get _repo => ref.read(bildirimRepositoryProvider);

  Future<void> okunduIsaretle(String bildirimId) async {
    try {
      await _repo.okunduIsaretle(bildirimId);
      if (!ref.mounted) return;
      ref.read(bildirimlerProvider.notifier).yenile();
      ref.read(okunmamisBildirimSayiProvider.notifier).yenile();
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> tumunuOkunduIsaretle() async {
    try {
      await _repo.tumunuOkunduIsaretle();
      if (!ref.mounted) return;
      ref.read(bildirimlerProvider.notifier).yenile();
      ref.read(okunmamisBildirimSayiProvider.notifier).yenile();
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> bildirimSil(String bildirimId) async {
    try {
      await _repo.bildirimSil(bildirimId);
      if (!ref.mounted) return;
      ref.read(bildirimlerProvider.notifier).yenile();
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }
}
