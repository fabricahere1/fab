import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../domain/kullanici_model.dart';

part 'kullanici_repository.g.dart';

@riverpod
KullaniciRepository kullaniciRepository(Ref ref) {
  return KullaniciRepository();
}

class KullaniciRepository {
  Future<KullaniciModel?> kullaniciGetir(String uid) async {
    try {
      final response = await ApiClient.dio.get('/kullanicilar/$uid');
      return KullaniciModel.fromApi(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<KullaniciModel?> benimProfilimGetir() async {
    final response = await ApiClient.dio.get('/profilim');
    return KullaniciModel.fromApi(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> kullaniciDataGetir(String uid) async {
    final model = await kullaniciGetir(uid);
    if (model == null) return null;
    return {'adSoyad': model.adSoyad, 'displayName': model.adSoyad, 'fotoUrl': model.fotoUrl};
  }

  Future<void> profilGuncelle({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await ApiClient.dio.patch('/profilim', data: data);
  }

  Future<void> profilTamamla({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await ApiClient.dio.patch('/profilim', data: data);
  }

  /// bildirimTercihleri map'ini döndürür; doküman/alan yoksa null.
  Future<Map<String, bool>?> bildirimTercihleriGetir(String uid) async {
    final profil = await benimProfilimGetir();
    if (profil == null || profil.bildirimTercihleri.isEmpty) return null;
    return profil.bildirimTercihleri;
  }

  Future<void> bildirimTercihGuncelle(String uid, String anahtar, bool deger) {
    return ApiClient.dio.patch('/profilim/bildirim-tercihi', data: {
      'anahtar': anahtar,
      'deger': deger,
    });
  }

  Future<void> engelle({required String benimUid, required String hedefUid}) {
    return ApiClient.dio.post('/kullanicilar/$hedefUid/engelle');
  }

  Future<void> engelKaldir({required String benimUid, required String hedefUid}) {
    return ApiClient.dio.delete('/kullanicilar/$hedefUid/engelle');
  }

  Future<List<String>> engellenenlerGetir() async {
    final response = await ApiClient.dio.get('/engellenenlerim');
    return List<String>.from(response.data as List);
  }

  Future<void> sikayetGonder({
    required String sikayetEdenId,
    required String hedefId,
    required String hedefAd,
    required String sebep,
    String ilanId = '',
    String degerlendirmeId = '',
  }) {
    return ApiClient.dio.post('/sikayetler', data: {
      'hedefId': degerlendirmeId.isNotEmpty ? degerlendirmeId : (ilanId.isNotEmpty ? ilanId : hedefId),
      'hedefTipi': degerlendirmeId.isNotEmpty ? 'degerlendirme' : (ilanId.isNotEmpty ? 'ilan' : 'kullanici'),
      'sebep': sebep,
    });
  }

  // ── Takip sistemi ──────────────────────────────────────────────────────────

  Future<void> takipEt({required String takipciId, required String takipEdilenId}) {
    return ApiClient.dio.post('/kullanicilar/$takipEdilenId/takip');
  }

  Future<void> takipiBirak({required String takipciId, required String takipEdilenId}) {
    return ApiClient.dio.delete('/kullanicilar/$takipEdilenId/takip');
  }

  Future<bool> takipEdiyorMu({required String takipciId, required String takipEdilenId}) async {
    final response = await ApiClient.dio.get('/kullanicilar/$takipEdilenId/takip-durumu');
    return response.data['takipEdiyor'] as bool? ?? false;
  }

  Future<List<String>> takipciIdleriGetir(String kullaniciId) async {
    final response = await ApiClient.dio.get('/kullanicilar/$kullaniciId/takipciler');
    return List<String>.from(response.data as List);
  }

  Future<List<String>> takipEdilenIdleriGetir(String kullaniciId) async {
    final response = await ApiClient.dio.get('/kullanicilar/$kullaniciId/takip-edilenler');
    return List<String>.from(response.data as List);
  }

  /// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.
  Future<Map<String, DateTime>> takipEdilenTarihleriGetir(String kullaniciId) async {
    final response = await ApiClient.dio.get('/kullanicilar/$kullaniciId/takip-edilenler-tarihli');
    return {
      for (final j in (response.data as List))
        (j as Map<String, dynamic>)['id'] as String:
            DateTime.tryParse(j['tarih'] as String? ?? '') ?? DateTime.now(),
    };
  }

  Future<List<KullaniciModel>> _yuksekPuanliGetir(String tip) async {
    final response = await ApiClient.dio.get('/kullanicilar/yuksek-puanli', queryParameters: {'tip': tip});
    return (response.data['kullanicilar'] as List)
        .map((j) => KullaniciModel.fromApi(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<KullaniciModel>> yuksekPuanliTasiyicilariGetir({
    double minPuan = 4.0,
    int limit = 20,
  }) => _yuksekPuanliGetir('tasiyici');

  Future<List<KullaniciModel>> yuksekPuanliIstekcileriGetir({
    double minPuan = 4.0,
    int limit = 20,
  }) => _yuksekPuanliGetir('istek');
}
