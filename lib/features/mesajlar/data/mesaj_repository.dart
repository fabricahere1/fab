// lib/features/mesajlar/data/mesaj_repository.dart
//
// Firestore'un yerini AWS Go backend'i (/v3/sohbetler*) alıyor. İşlem
// durumu state machine'inin TÜM iş mantığı (hangi anahtar, hangi sırada,
// hangi metinle) client'ta (islem_durumu.dart) kalıyor — backend sadece
// opak bir anahtar=true deposu + bildirim göndericisi.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../domain/mesaj_model.dart';

part 'mesaj_repository.g.dart';

@riverpod
MesajRepository mesajRepository(Ref ref) {
  return MesajRepository();
}

class MesajRepository {
  Future<SohbetModel> sohbetBaslat({required String ilanId}) async {
    final response = await ApiClient.dio.post('/ilanlar/$ilanId/sohbet-baslat');
    return SohbetModel.fromApi(response.data as Map<String, dynamic>);
  }

  Future<SohbetModel?> sohbetGetir(String sohbetId) async {
    try {
      final response = await ApiClient.dio.get('/sohbetler/$sohbetId');
      return SohbetModel.fromApi(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) return null;
      rethrow;
    }
  }

  Future<List<SohbetModel>> sohbetleriGetir() async {
    final response = await ApiClient.dio.get('/sohbetlerim');
    return (response.data['sohbetler'] as List)
        .map((j) => SohbetModel.fromApi(j as Map<String, dynamic>))
        .toList();
  }

  Future<MesajModel> mesajGonder({
    required String sohbetId,
    String metin = '',
    File? resim,
  }) async {
    dynamic data;
    if (resim != null) {
      data = FormData.fromMap({
        'metin': metin,
        'resim': await MultipartFile.fromFile(resim.path, filename: resim.uri.pathSegments.last),
      });
    } else {
      data = {'metin': metin};
    }
    final response = await ApiClient.dio.post('/sohbetler/$sohbetId/mesajlar', data: data);
    return MesajModel.fromApi(response.data as Map<String, dynamic>);
  }

  Future<List<MesajModel>> mesajlariGetir(String sohbetId) async {
    final response = await ApiClient.dio.get('/sohbetler/$sohbetId/mesajlar');
    return (response.data['mesajlar'] as List)
        .map((j) => MesajModel.fromApi(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> mesajSil({required String sohbetId, required String mesajId}) {
    return ApiClient.dio.delete('/sohbetler/$sohbetId/mesajlar/$mesajId');
  }

  Future<void> okunduIsaretle(String sohbetId) {
    return ApiClient.dio.patch('/sohbetler/$sohbetId/okundu');
  }

  Future<void> sohbetiGizle(String sohbetId) {
    return ApiClient.dio.patch('/sohbetler/$sohbetId/gizle');
  }

  Future<bool> sohbetiSabitle(String sohbetId) async {
    final response = await ApiClient.dio.patch('/sohbetler/$sohbetId/sabitle');
    return response.data['sabitlenmis'] as bool? ?? false;
  }

  /// [anahtar] — IslemDurumu.firestoreKey ya da "anlasildi_&lt;uid&gt;" gibi
  /// bileşik bir anahtar. [bildirimIcerigi] verilirse karşı tarafa
  /// bildirim gider (IslemDurumu.gecmisDonusu'ndan client tarafından
  /// üretiliyor — backend sadece aynen iletiyor).
  Future<void> islemDurumuGuncelle({
    required String sohbetId,
    required String anahtar,
    String? bildirimIcerigi,
  }) {
    return ApiClient.dio.patch('/sohbetler/$sohbetId/islem-durumu', data: {
      'anahtar': anahtar,
      if (bildirimIcerigi != null) 'bildirimIcerigi': bildirimIcerigi,
    });
  }

  Future<void> anlasildiIsaretle({required String sohbetId, required String benimUid}) {
    return islemDurumuGuncelle(sohbetId: sohbetId, anahtar: anlasildiAlani(benimUid));
  }

  Future<void> teslimTamamla({required String sohbetId}) {
    return ApiClient.dio.post('/sohbetler/$sohbetId/teslim-tamamla');
  }
}
