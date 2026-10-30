import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'banner_service.dart';
import '../../shared/utils/app_hata_yonetici.dart';

/// Tüm FCM sorumluluğu bu sınıftadır.
/// - İzin isteme
/// - Token alma, backend'e (PATCH /v3/profilim) yazma, yenilenince güncelleme
/// - Çıkışta token silme
/// - Foreground mesaj → BannerService
///
/// ÖNEMLİ FARK (Firebase→AWS geçişi): token kaydı artık Firebase
/// authStateChanges()'e DEĞİL, kendi JWT oturumumuza bağlı — Google/e-posta
/// girişi Firebase Auth'u hiç tetiklemiyor, bu yüzden "giriş oldu" sinyalini
/// auth_repository.dart (girişten hemen sonra girisSonrasiTokenKaydet()
/// çağırarak) veriyor; burası kendi başına auth durumunu dinlemiyor.
///
/// Kullanım (main.dart):
///   await FcmService.instance.init(onBildirimAc: _bildirimdenAc);
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  String _maskele(String s) => s.length <= 6 ? s : '...${s.substring(s.length - 6)}';

  Future<void> init({
    required void Function(RemoteMessage) onBildirimAc,
    required void Function(RemoteMessage) onIlkAcilis,
  }) async {
    final izin = await _messaging.requestPermission();
    if (kDebugMode) {
      debugPrint('FCM izin durumu: ${izin.authorizationStatus}');
    }
    if (izin.authorizationStatus == AuthorizationStatus.denied) {
      AppHataYonetici.logla(
        Exception('FCM izni reddedildi'),
        null,
        etiket: 'fcm.izin_reddedildi',
      );
    }

    // Zaten giriş yapılmışsa (uygulama yeniden açıldı) token'ı tazele.
    final mevcutToken = await ApiClient.tokenOku();
    if (mevcutToken != null) {
      await girisSonrasiTokenKaydet();
    }

    _tokenSub = _messaging.onTokenRefresh.listen((yeniToken) async {
      if (await ApiClient.tokenOku() != null) {
        await _tokenKaydet(yeniToken);
      }
    });

    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      _foregroundMesajIsle(message, onBildirimAc);
    });

    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(onBildirimAc);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onIlkAcilis(initialMessage);
    }
  }

  /// Giriş başarılı olduktan hemen sonra (auth_repository.dart'tan)
  /// çağrılır — fire-and-forget, ağ hatası girişi engellemez.
  Future<void> girisSonrasiTokenKaydet() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _tokenKaydet(token);
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'FCM.girisSonrasiTokenKaydet');
    }
  }

  Future<void> _tokenKaydet(String token) async {
    try {
      await ApiClient.dio.patch('/profilim', data: {'fcmToken': token});
      debugPrint('[FCM] Token kaydedildi: ${_maskele(token)}');
    } catch (e, s) {
      debugPrint('[FCM] Token kaydedilemedi: $e');
      AppHataYonetici.logla(e, s, etiket: 'FCM.tokenKaydet');
    }
  }

  /// Çıkış öncesi çağrılır: backend'deki fcmToken'ı temizler ve cihaz
  /// token'ını iptal eder. Ağ hatası çıkışı engellemez.
  Future<void> oturumKapanisTemizligi() async {
    try {
      await ApiClient.dio.patch('/profilim', data: {'fcmToken': ''});
      await _messaging.deleteToken();
      debugPrint('[FCM] Çıkış temizliği tamamlandı');
    } on DioException catch (_) {
      // Token zaten geçersizse (401) ya da ağ hatasıysa sessizce geç —
      // çıkışı engellememeli.
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'cikis.fcmTemizlik');
    }
  }

  void _foregroundMesajIsle(
    RemoteMessage message,
    void Function(RemoteMessage) onBildirimAc,
  ) {
    final notification = message.notification;
    final baslik = notification?.title ?? 'Bildirim';
    final icerik = notification?.body  ?? '';
    final tip    = message.data['tip'] as String? ?? 'bilgi';

    BannerService.instance.goster(
      baslik: baslik,
      icerik: icerik,
      tip: switch (tip) {
        'mesaj'         => 'mesaj',
        'degerlendirme' => 'degerlendirme',
        'islem'         => 'islem',
        _               => 'bilgi',
      },
      onTap: () => onBildirimAc(message),
    );
  }

  void dispose() {
    _tokenSub?.cancel();
    _messageSub?.cancel();
    _openedAppSub?.cancel();
  }
}
