// lib/features/ilanlar/data/ilan_repository.dart
//
// Firestore'un yerini AWS Go backend'i (/v3/ilanlar route'ları) alıyor.
// Gerçek zamanlı Firestore stream'leri YOK ARTIK — Çekmece'deki (ikinciel)
// aynı geçişte kullanıcı onayıyla kabul edilen desen: "yenile" (pull-to-
// refresh / tekrar fetch) modeli. Resim sıkıştırma client'ta kalıyor
// (daha hızlı yükleme), ama yükleme artık doğrudan backend'in multipart
// /v3/ilanlar'ına — Firebase Storage'a değil.

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../domain/ilan_model.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/utils/oneri_skoru.dart';

part 'ilan_repository.g.dart';

class IlanSayfasi {
  final List<IlanModel> ilanlar;
  final int sonrakiOffset;
  final bool bitti;

  const IlanSayfasi({
    required this.ilanlar,
    required this.sonrakiOffset,
    required this.bitti,
  });
}

@riverpod
IlanRepository ilanRepository(Ref ref) {
  return IlanRepository();
}

class IlanRepository {
  Future<List<IlanModel>> _ilanlariGetir({
    required String tip,
    String? kategori,
    String? arama,
    int limit = Pagination.ilanSayfaBoyutu,
    int offset = 0,
  }) async {
    final response = await ApiClient.dio.get('/ilanlar', queryParameters: {
      'tip': tip,
      if (kategori != null) 'kategori': kategori,
      if (arama != null && arama.isNotEmpty) 'arama': arama,
      'limit': limit,
      'offset': offset,
    });
    final liste = (response.data['ilanlar'] as List)
        .map((j) => IlanModel.fromJson(j as Map<String, dynamic>))
        .toList();
    return liste;
  }

  Future<IlanSayfasi> istekIlanlariniGetir({
    String? kategori,
    int limit = Pagination.ilanSayfaBoyutu,
    bool forceServer = false, // artık fark etmiyor, hep sunucudan çekiyoruz
  }) async {
    final ilanlar = await _ilanlariGetir(tip: IlanTip.istek, kategori: kategori, limit: limit);
    return IlanSayfasi(ilanlar: ilanlar, sonrakiOffset: ilanlar.length, bitti: ilanlar.length < limit);
  }

  Future<IlanSayfasi> istekIlanlariniGetirSunucu({
    String? kategori,
    int limit = Pagination.ilanSayfaBoyutu,
  }) => istekIlanlariniGetir(kategori: kategori, limit: limit);

  Future<IlanSayfasi> tasiyiciIlanlariniGetir({
    int limit = Pagination.ilanSayfaBoyutu,
    bool forceServer = false,
  }) async {
    final ilanlar = await _ilanlariGetir(tip: IlanTip.tasiyici, limit: limit);
    return IlanSayfasi(ilanlar: ilanlar, sonrakiOffset: ilanlar.length, bitti: ilanlar.length < limit);
  }

  Future<IlanSayfasi> sonrakiSayfayiGetir({
    required String tip,
    required int offset,
    String? kategori,
    int limit = Pagination.ilanSayfaBoyutu,
  }) async {
    final ilanlar = await _ilanlariGetir(tip: tip, kategori: kategori, limit: limit, offset: offset);
    return IlanSayfasi(
      ilanlar: ilanlar,
      sonrakiOffset: offset + ilanlar.length,
      bitti: ilanlar.length < limit,
    );
  }

  Future<List<IlanModel>> son24SaatIlanlariniGetir({int limit = 15}) async {
    final tumu = await _ilanlariGetir(tip: IlanTip.istek, limit: 50);
    final simdi = DateTime.now();
    return tumu
        .where((i) => i.olusturmaTarihi != null && simdi.difference(i.olusturmaTarihi!).inHours < 24)
        .take(limit)
        .toList();
  }

  Future<List<IlanModel>> haftaninEnleriGetir({int limit = 15}) async {
    final tumu = await _ilanlariGetir(tip: IlanTip.istek, limit: 50);
    final simdi = DateTime.now();
    final sonYedi = tumu
        .where((i) => i.olusturmaTarihi != null && simdi.difference(i.olusturmaTarihi!).inDays < 7)
        .toList();
    final skorlar = {for (final i in sonYedi) i.id: oneriSkoru(i)};
    final sirali = [...sonYedi]..sort((a, b) => skorlar[b.id]!.compareTo(skorlar[a.id]!));
    return sirali.take(limit).toList();
  }

  /// Kendi ilanlarım (onay bekleyen/reddedilen dahil).
  Future<List<IlanModel>> ilanlarimGetir() async {
    final response = await ApiClient.dio.get('/ilanlarim');
    return (response.data['ilanlar'] as List)
        .map((j) => IlanModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<IlanModel>> kullaniciIlanlariGetir(String kullaniciId) async {
    // Backend'de "başka bir kullanıcının ilanları" için ayrı bir endpoint
    // yok — herkese açık listeden client tarafında filtreliyoruz. Küçük
    // ölçekte (v3) kabul edilebilir, büyürse backend'e
    // GET /ilanlar?kullaniciId= eklenir.
    final istek = await _ilanlariGetir(tip: IlanTip.istek, limit: 100);
    final tasiyici = await _ilanlariGetir(tip: IlanTip.tasiyici, limit: 100);
    return [...istek, ...tasiyici].where((i) => i.kullaniciId == kullaniciId).toList();
  }

  /// Full resim: max 1080px, %75 kalite → 100-300 KB (yükleme hızı için).
  Future<File> _resimSikistir(File dosya, int index) async {
    final tempDir = await getTemporaryDirectory();
    final hedefYol =
        '${tempDir.path}/ilan_compressed_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
    final sonuc = await FlutterImageCompress.compressAndGetFile(
      dosya.absolute.path,
      hedefYol,
      quality: 75,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );
    if (sonuc == null) return dosya;
    final sikistirilmis = File(sonuc.path);
    unawaited(Future.delayed(const Duration(minutes: 5), () async {
      if (await sikistirilmis.exists()) {
        await sikistirilmis.delete().catchError((_) => sikistirilmis as FileSystemEntity);
      }
    }));
    return sikistirilmis;
  }

  /// İlan oluşturur — backend tüm fotoğraf işleme/moderasyon/thumbnail
  /// üretimini KENDİSİ yapıyor (bkz. v3_ilan_routes.go), client sadece
  /// sıkıştırıp multipart olarak gönderiyor.
  Future<String> ilanOlustur({
    required IlanModel ilan,
    List<File> resimler = const [],
    void Function(int index, double progress)? onProgress,
  }) async {
    final sikistirilmisler = await Future.wait(
      List.generate(resimler.length, (i) => _resimSikistir(resimler[i], i)),
    );

    final formData = FormData.fromMap({
      'tip': ilan.tip,
      'nereden': ilan.nereden,
      'nereye': ilan.nereye,
      'ucret': ilan.ucret,
      'urun': ilan.urun,
      'notlar': ilan.notlar,
      'urunLinki': ilan.urunLinki,
      'kategori': ilan.kategori,
      'anaKategori': ilan.anaKategori,
      'kategoriYolu': ilan.kategoriYolu.join(','),
      'tasimaTercihi': ilan.tasimaTercihi,
      'cinsiyet': ilan.cinsiyet,
      'beden': ilan.beden,
      // toUtc() şart: lokal DateTime.toIso8601String() 'Z'/offset içermez,
      // backend (Go time.RFC3339) böylesini parse edemez.
      if (ilan.tarih != null) 'tarih': ilan.tarih!.toUtc().toIso8601String(),
      if (ilan.sahipIstekTeslimatTercihi != null)
        'sahipIstekTeslimatTercihi': ilan.sahipIstekTeslimatTercihi,
      'sahipDutyFree': ilan.sahipDutyFree.toString(),
      'sadeceGeliyorum': ilan.sadeceGeliyorum.toString(),
      'resimler': [
        for (final dosya in sikistirilmisler)
          await MultipartFile.fromFile(dosya.path, filename: dosya.uri.pathSegments.last),
      ],
    });

    final response = await ApiClient.dio.post(
      '/ilanlar',
      data: formData,
      onSendProgress: (gonderilen, toplam) {
        if (toplam > 0) onProgress?.call(0, gonderilen / toplam);
      },
    );
    return (response.data as Map<String, dynamic>)['id'] as String;
  }

  /// Çekmece'deki "AI ile Doldur" ile aynı Gemini altyapısını kullanan
  /// v3'e özgü sade karşılığı — sadece "Notlar" alanı için bir öneri
  /// döner (v3'ün ilan modelinde başlık/kategori/marka yok). Başarısız
  /// olursa null döner, çağıran taraf elle doldurmaya devam eder.
  Future<String?> aiNotOnerisiGetir(File resim) async {
    try {
      final formData = FormData.fromMap({
        'resim': await MultipartFile.fromFile(resim.path, filename: resim.uri.pathSegments.last),
      });
      final response = await ApiClient.dio.post('/ilanlar/ai-oneri', data: formData);
      return (response.data as Map<String, dynamic>)['notlar'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<IlanModel?> ilanGetir(String ilanId) async {
    try {
      final response = await ApiClient.dio.get('/ilanlar/$ilanId');
      return IlanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// [yeniResimler] verilirse multipart olarak gönderilir — backend bunları
  /// mevcut resim_urller listesine EKLER (2026-10-28'de eklendi: resimsiz
  /// girilmiş bir ilana düzenlemeden resim eklenemiyordu, bkz. v3_ilan_routes.go
  /// PUT /ilanlar/:id). Resim yoksa eskisi gibi düz JSON gönderilir.
  Future<void> ilanGuncelle(
    String ilanId,
    Map<String, dynamic> data, {
    List<File> yeniResimler = const [],
  }) async {
    if (yeniResimler.isEmpty) {
      await ApiClient.dio.put('/ilanlar/$ilanId', data: {
        if (data.containsKey('ucret')) 'ucret': data['ucret'],
        if (data.containsKey('urun')) 'urun': data['urun'],
        if (data.containsKey('notlar')) 'notlar': data['notlar'],
        if (data.containsKey('tasimaTercihi')) 'tasimaTercihi': data['tasimaTercihi'],
      });
      return;
    }

    final sikistirilmisler = await Future.wait(
      List.generate(yeniResimler.length, (i) => _resimSikistir(yeniResimler[i], i)),
    );
    final formData = FormData.fromMap({
      if (data.containsKey('ucret')) 'ucret': data['ucret'],
      if (data.containsKey('urun')) 'urun': data['urun'],
      if (data.containsKey('notlar')) 'notlar': data['notlar'],
      if (data.containsKey('tasimaTercihi')) 'tasimaTercihi': data['tasimaTercihi'],
      'resimler': [
        for (final dosya in sikistirilmisler)
          await MultipartFile.fromFile(dosya.path, filename: dosya.uri.pathSegments.last),
      ],
    });
    await ApiClient.dio.put('/ilanlar/$ilanId', data: formData);
  }

  Future<void> ilanSil(String ilanId) async {
    await ApiClient.dio.delete('/ilanlar/$ilanId');
  }

  Future<List<IlanModel>> favorileriGetir() async {
    final response = await ApiClient.dio.get('/favorilerim');
    return (response.data['ilanlar'] as List)
        .map((j) => IlanModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> favoriyeEkle(String ilanId) => ApiClient.dio.post('/ilanlar/$ilanId/favori');
  Future<void> favoridenCikar(String ilanId) => ApiClient.dio.delete('/ilanlar/$ilanId/favori');
}
