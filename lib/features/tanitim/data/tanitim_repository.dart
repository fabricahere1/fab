// lib/features/tanitim/data/tanitim_repository.dart
//
// Tanıtım (onboarding) ekranının gösterilip gösterilmeyeceği — Çekmece'deki
// ilan_tesvik_repository ile aynı desen: kullanici_id'ye bağlı, backend'de
// tutulur (bkz. v3_tanitim.go).

import '../../../core/api/api_client.dart';

class TanitimRepository {
  Future<bool> gosterilmeliMi() async {
    final response = await ApiClient.dio.get('/tanitim/durum');
    return response.data['goster'] as bool? ?? false;
  }

  Future<void> goruldu() async {
    await ApiClient.dio.post('/tanitim/goruldu');
  }
}
