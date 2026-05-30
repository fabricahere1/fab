// lib/features/degerlendirme/providers/degerlendirme_provider.dart

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../data/degerlendirme_repository.dart';

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

// Kullanıcı değerlendirmelerini dinler
@riverpod
Stream<List<Map<String, dynamic>>> kullaniciDegerlendirmeleri(
    Ref ref, String kullaniciId) {
  return ref
      .watch(degerlendirmeRepositoryProvider)
      .kullaniciDegerlendirmeleriStream(kullaniciId);
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