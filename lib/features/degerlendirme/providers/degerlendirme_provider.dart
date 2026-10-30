// lib/features/degerlendirme/providers/degerlendirme_provider.dart

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/degerlendirme_repository.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

export '../data/degerlendirme_repository.dart' show BekleyenDegerlendirme;

part 'degerlendirme_provider.g.dart';

// Backend "kendi" bekleyen listeni döndürür (JWT'den) — parametre almıyor.
@riverpod
Future<List<BekleyenDegerlendirme>> bekleyenDegerlendirmelerim(Ref ref) {
  return ref.read(degerlendirmeRepositoryProvider).bekleyenDegerlendirmelerimGetir();
}

// Kullanıcı değerlendirmeleri — liste durumu (backend artık tüm geçmişi
// tek seferde döndürüyor, "daha fazla yükle" kavramı kalmadı).
class DegerlendirmeListeState {
  final List<Map<String, dynamic>> liste;
  final bool yukleniyor;
  final Object? hata;

  const DegerlendirmeListeState({
    this.liste = const [],
    this.yukleniyor = false,
    this.hata,
  });

  DegerlendirmeListeState copyWith({
    List<Map<String, dynamic>>? liste,
    bool? yukleniyor,
    Object? hata,
    bool temizleHata = false,
  }) =>
      DegerlendirmeListeState(
        liste: liste ?? this.liste,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        hata: temizleHata ? null : (hata ?? this.hata),
      );
}

// autoDispose (varsayılan) BİLİNÇLİ: parametre kullaniciId — sınırsız uzay,
// bkz. ilan_provider.dart:498 uyarısı. keepAlive EKLEME.
@riverpod
class KullaniciDegerlendirmeleri extends _$KullaniciDegerlendirmeleri {
  DegerlendirmeRepository get _repo => ref.read(degerlendirmeRepositoryProvider);

  @override
  DegerlendirmeListeState build(String kullaniciId) {
    Future.microtask(_ilkYukle);
    return const DegerlendirmeListeState(yukleniyor: true);
  }

  Future<void> _ilkYukle() async {
    state = state.copyWith(yukleniyor: true, temizleHata: true);
    try {
      final sayfa = await _repo.degerlendirmeSayfasiGetir(kullaniciId);
      if (!ref.mounted) return;
      state = state.copyWith(liste: sayfa.liste, yukleniyor: false);
    } catch (e, stack) {
      AppHataYonetici.logla(e, stack, etiket: 'Degerlendirme.sayfa');
      if (!ref.mounted) return;
      state = state.copyWith(yukleniyor: false, hata: e);
    }
  }

  Future<void> dahaFazlaYukle() async {}

  Future<void> yenile() async {
    state = const DegerlendirmeListeState(yukleniyor: true);
    await _ilkYukle();
  }
}

// Değerlendirme işlemleri notifier
// keepAlive ZORUNLU: gonder() ağ çağrısı bittikten SONRA kendi ref'i
// üzerinden bekleyenDegerlendirmelerimProvider'ı invalidate ediyor —
// autoDispose olsaydı, modal kapanıp bu provider'ı dinleyen kalmayınca
// Riverpod erken temizleyip "Ref ... disposed" hatası fırlatabilirdi
// (bkz. 2026-10-23 Google girişi çökmesiyle aynı kök sebep).
@Riverpod(keepAlive: true)
class DegerlendirmeIslemleri extends _$DegerlendirmeIslemleri {
  DegerlendirmeRepository get _repo => ref.read(degerlendirmeRepositoryProvider);

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> gonder({
    required String ilanId,
    required String degerlendirilenId,
    required double puan,
    required String yorum,
  }) async {
    try {
      await _repo.degerlendirmeGonder(
        ilanId: ilanId,
        degerlendirilenId: degerlendirilenId,
        puan: puan,
        yorum: yorum,
      );
      ref.invalidate(bekleyenDegerlendirmelerimProvider);
      return true;
    } catch (e) {
      debugPrint('[Degerlendirme] gonder hatasi: $e');
      return false;
    }
  }
}
