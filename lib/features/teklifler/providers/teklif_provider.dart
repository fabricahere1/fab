// lib/features/teklifler/providers/teklif_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/teklif_model.dart';
import '../data/teklif_repository.dart';

part 'teklif_provider.g.dart';

@riverpod
Stream<TeklifModel?> teklifDetay(Ref ref, String teklifId) {
  return ref.watch(teklifRepositoryProvider).teklifDetayStream(teklifId);
}

@riverpod
Stream<({int sayi, double? enYuksek})> ilanTeklifOzet(Ref ref, String ilanId) {
  return ref
      .watch(teklifRepositoryProvider)
      .ilanaTekliflerStream(ilanId)
      .map((teklifler) {
    if (teklifler.isEmpty) return (sayi: 0, enYuksek: null);
    final enYuksek =
        teklifler.map((t) => t.miktar).reduce((a, b) => a > b ? a : b);
    return (sayi: teklifler.length, enYuksek: enYuksek);
  });
}

// ✅ Düzeltildi: ilanId + teklifVerenId ile sorgu — yanlış ilan için badge çıkmaz
@riverpod
Stream<TeklifModel?> ilanKabulTeklifi(Ref ref, String ilanId, String teklifVerenId) {
  return ref
      .watch(teklifRepositoryProvider)
      .ilanKabulTeklifleriStream(ilanId, teklifVerenId);
}

@riverpod
Stream<List<TeklifModel>> ilanTeklifleri(Ref ref, String ilanId) {
  return ref.watch(teklifRepositoryProvider).ilanaTekliflerStream(ilanId);
}

@riverpod
Stream<List<TeklifModel>> benimTekliflerim(Ref ref, String kullaniciId) {
  return ref.watch(teklifRepositoryProvider).benirnTekliflerimStream(kullaniciId);
}

@riverpod
class TeklifNotifier extends _$TeklifNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  TeklifRepository get _repo => ref.read(teklifRepositoryProvider);

  Future<bool> teklifVer({
    required String ilanId,
    required String ilanBaslik,
    required String ilanSahibiId,
    required String ilanSahibiAd,
    required String teklifVerenId,
    required String teklifVerenAd,
    required double miktar,
    required double ilanMiktar,
  }) async {
    if (!ref.mounted) return false;
    state = const AsyncLoading();
    try {
      await _repo.teklifVer(
        ilanId: ilanId,
        ilanBaslik: ilanBaslik,
        ilanSahibiId: ilanSahibiId,
        ilanSahibiAd: ilanSahibiAd,
        teklifVerenId: teklifVerenId,
        teklifVerenAd: teklifVerenAd,
        miktar: miktar,
        ilanMiktar: ilanMiktar,
      );
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> teklifKabul({
    required TeklifModel teklif,
    required String kabulEdenId,
    required String kabulEdenAd,
  }) async {
    if (!ref.mounted) return false;
    state = const AsyncLoading();
    try {
      await _repo.teklifKabul(
        teklif: teklif,
        kabulEdenId: kabulEdenId,
        kabulEdenAd: kabulEdenAd,
      );
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> teklifReddet(TeklifModel teklif) async {
    if (!ref.mounted) return false;
    state = const AsyncLoading();
    try {
      await _repo.teklifReddet(teklif: teklif);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> karsiTeklifVer({
    required TeklifModel teklif,
    required double karsiMiktar,
  }) async {
    if (!ref.mounted) return false;
    state = const AsyncLoading();
    try {
      await _repo.karsiTeklifVer(teklif: teklif, karsiMiktar: karsiMiktar);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}