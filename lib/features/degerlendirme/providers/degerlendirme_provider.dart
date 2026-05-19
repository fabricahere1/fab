// lib/features/degerlendirme/providers/degerlendirme_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../mesajlar/data/mesaj_repository.dart';
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