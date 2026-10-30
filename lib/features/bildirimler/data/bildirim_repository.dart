// lib/features/bildirimler/data/bildirim_repository.dart
//
// Firestore'un yerini AWS Go backend'i (/v3/bildirimler*) alıyor. Gerçek
// zamanlı stream YOK — Çekmece'deki ve v3'ün ilan/auth katmanlarındaki
// aynı karar: periyodik yenileme (bildirim_provider.dart'ta polling).
//
// ÖNEMLİ: mesaj bildirimi artık BURADAN (client'tan) gönderilmiyor —
// backend, /v3/sohbetler/:id/mesajlar çağrısında bunu KENDİSİ otomatik
// yapıyor (bkz. v3_bildirim_gonder.go). mesajBildirimiGonder metodu bu
// yüzden kaldırıldı; mesajlar özelliği AWS'ye taşınınca (henüz
// taşınmadı, bkz. backlog) bu otomatik davranış devreye girecek.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../domain/bildirim_model.dart';

part 'bildirim_repository.g.dart';

@riverpod
BildirimRepository bildirimRepository(Ref ref) {
  return BildirimRepository();
}

class BildirimRepository {
  Future<List<BildirimModel>> bildirimleriGetir() async {
    final response = await ApiClient.dio.get('/bildirimlerim');
    return (response.data['bildirimler'] as List)
        .map((j) => BildirimModel.fromApi(j as Map<String, dynamic>))
        .toList();
  }

  Future<int> okunmamisSayiGetir() async {
    final response = await ApiClient.dio.get('/bildirimler/okunmamis-sayisi');
    return (response.data['sayi'] as num?)?.toInt() ?? 0;
  }

  Future<void> okunduIsaretle(String bildirimId) async {
    await ApiClient.dio.patch('/bildirimler/$bildirimId/okundu');
  }

  Future<void> tumunuOkunduIsaretle() async {
    await ApiClient.dio.patch('/bildirimler/tumunu-okundu');
  }

  Future<void> bildirimSil(String bildirimId) async {
    await ApiClient.dio.delete('/bildirimler/$bildirimId');
  }
}
