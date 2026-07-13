// lib/features/degerlendirme/providers/degerlendirme_provider.dart

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../data/degerlendirme_repository.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

part 'degerlendirme_provider.g.dart';

// İşlem durumlarını dinler - sohbet ekranı için
@riverpod
Stream<Map<String, dynamic>> sohbetDurumu(Ref ref, String sohbetId) {
  return ref.read(mesajRepositoryProvider).sohbetDurumuStream(sohbetId);
}

// Bekleyen değerlendirmeleri dinler
@riverpod
Stream<List<Map<String, dynamic>>> bekleyenDegerlendirmeler(
    Ref ref, String kullaniciId) {
  return ref
      .read(degerlendirmeRepositoryProvider)
      .bekleyenDegerlendirmelerStream(kullaniciId);
}

// Kullanıcı değerlendirmeleri — sayfalı liste durumu
class DegerlendirmeListeState {
  final List<Map<String, dynamic>> liste;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final DateTime? sonTarih;
  final Object? hata;

  const DegerlendirmeListeState({
    this.liste = const [],
    this.yukleniyor = false,
    this.dahaFazlaVar = true,
    this.sonTarih,
    this.hata,
  });

  DegerlendirmeListeState copyWith({
    List<Map<String, dynamic>>? liste,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    DateTime? sonTarih,
    Object? hata,
    bool temizleHata = false,
  }) =>
      DegerlendirmeListeState(
        liste: liste ?? this.liste,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        sonTarih: sonTarih ?? this.sonTarih,
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
      state = state.copyWith(
        liste: sayfa.liste,
        sonTarih: sayfa.sonTarih,
        dahaFazlaVar: !sayfa.bitti,
        yukleniyor: false,
      );
    } catch (e, stack) {
      AppHataYonetici.logla(e, stack, etiket: 'Degerlendirme.sayfa');
      if (!ref.mounted) return;
      state = state.copyWith(yukleniyor: false, hata: e);
    }
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor || !state.dahaFazlaVar) return;
    state = state.copyWith(yukleniyor: true);
    try {
      final sayfa = await _repo.degerlendirmeSayfasiGetir(
        kullaniciId,
        sonTarih: state.sonTarih,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        liste: [...state.liste, ...sayfa.liste],
        sonTarih: sayfa.sonTarih,
        dahaFazlaVar: !sayfa.bitti,
        yukleniyor: false,
      );
    } catch (e, stack) {
      AppHataYonetici.logla(e, stack, etiket: 'Degerlendirme.sayfa');
      if (!ref.mounted) return;
      state = state.copyWith(yukleniyor: false, hata: e);
    }
  }

  Future<void> yenile() async {
    state = const DegerlendirmeListeState(yukleniyor: true);
    await _ilkYukle();
  }
}

// Değerlendirme işlemleri notifier
@riverpod
class DegerlendirmeIslemleri extends _$DegerlendirmeIslemleri {
  late final DegerlendirmeRepository _repo;

  @override
  AsyncValue<void> build() {
    _repo = ref.read(degerlendirmeRepositoryProvider);
    return const AsyncData(null);
  }

  Future<bool> gonder({
    required String sohbetId,
    required String degerlendireninId,
    required String hedefKullaniciId,
    required double puan,
    required String yorum,
    String ilanBaslik = '',
  }) async {
    try {
      await _repo.degerlendirmeGonder(
        sohbetId: sohbetId,
        degerlendireninId: degerlendireninId,
        hedefKullaniciId: hedefKullaniciId,
        puan: puan,
        yorum: yorum,
        ilanBaslik: ilanBaslik,
      );
      return true;
    } catch (e) {
      // Zaten değerlendirildiyse bekleyen kaydı temizle — veri tutarsızlığı düzeltme
      if (e.toString().contains('zaten_degerlendirdi')) {
        await _repo.bekleyenDegerlendirmeTamamla(
          sohbetId: sohbetId,
          kullaniciId: degerlendireninId,
        );
        return true;
      }
      debugPrint('[Degerlendirme] gonder hatasi: $e');
      return false;
    }
  }

  Future<void> bekleyenKaydet({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    await _repo.bekleyenDegerlendirmeKaydet(
      sohbetId: sohbetId,
      kullaniciId: kullaniciId,
    );
    await _repo.sohbetDegerlendirmeyiIsaretle(
      sohbetId: sohbetId,
      kullaniciId: kullaniciId,
    );
  }

  Future<void> bekleyenTamamla({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    await _repo.bekleyenDegerlendirmeTamamla(
      sohbetId: sohbetId,
      kullaniciId: kullaniciId,
    );
  }

  Future<bool> zatenYaptimMi({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    return _repo.zatenDegerlendirdimMi(
      sohbetId: sohbetId,
      kullaniciId: kullaniciId,
    );
  }
}