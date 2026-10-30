// lib/features/degerlendirme/data/degerlendirme_repository.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';

part 'degerlendirme_repository.g.dart';

@riverpod
DegerlendirmeRepository degerlendirmeRepository(Ref ref) {
  return DegerlendirmeRepository();
}

class BekleyenDegerlendirme {
  final String id;
  final String ilanId;
  final String degerlendirilenId;

  const BekleyenDegerlendirme({
    required this.id,
    required this.ilanId,
    required this.degerlendirilenId,
  });

  factory BekleyenDegerlendirme.fromApi(Map<String, dynamic> json) {
    return BekleyenDegerlendirme(
      id: json['id'] as String? ?? '',
      ilanId: json['ilanId'] as String? ?? '',
      degerlendirilenId: json['degerlendirilenId'] as String? ?? '',
    );
  }
}

class DegerlendirmeSayfasi {
  final List<Map<String, dynamic>> liste;
  final bool bitti;
  const DegerlendirmeSayfasi({required this.liste, required this.bitti});
}

class DegerlendirmeRepository {
  /// Backend yalnızca v3_bekleyen_degerlendirmeler'de kaydı olan (yani
  /// gerçekten o ilan üzerinden işlem yapmış) çiftlerin değerlendirmesini
  /// kabul ediyor — başarılı çağrı aynı zamanda bekleyen kaydı siler.
  Future<String> degerlendirmeGonder({
    required String ilanId,
    required String degerlendirilenId,
    required double puan,
    required String yorum,
  }) async {
    final response = await ApiClient.dio.post('/degerlendirmeler', data: {
      'ilanId': ilanId,
      'degerlendirilenId': degerlendirilenId,
      'puan': puan.round(),
      'yorum': yorum,
    });
    return response.data['id'] as String? ?? '';
  }

  Future<List<BekleyenDegerlendirme>> bekleyenDegerlendirmelerimGetir() async {
    final response = await ApiClient.dio.get('/bekleyen-degerlendirmelerim');
    return (response.data['bekleyenler'] as List)
        .map((j) => BekleyenDegerlendirme.fromApi(j as Map<String, dynamic>))
        .toList();
  }

  /// Sayfalama artık yok — backend tüm geçmişi tek seferde döndürüyor.
  Future<DegerlendirmeSayfasi> degerlendirmeSayfasiGetir(String hedefKullaniciId) async {
    final response = await ApiClient.dio.get('/kullanicilar/$hedefKullaniciId/degerlendirmeler');
    final liste = (response.data['degerlendirmeler'] as List).cast<Map<String, dynamic>>();
    return DegerlendirmeSayfasi(liste: liste, bitti: true);
  }
}
