import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'banner_service.dart';
import '../../shared/utils/app_hata_yonetici.dart';
import '../../shared/constants/app_constants.dart';

/// Tüm FCM sorumluluğu bu sınıftadır.
/// - İzin isteme
/// - Token alma, Firestore'a yazma, yenilenince güncelleme
/// - Çıkışta token silme (authStateChanges null olunca)
/// - Foreground mesaj → BannerService
///
/// Kullanım (main.dart):
///   await FcmService.instance.init(onBildirimAc: _bildirimdenAc);
///
/// auth_repository.dart FCM'den tamamen habersizdir.
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  /// [onBildirimAc] — bildirime tıklanınca çağrılır (router erişimi için
  /// main.dart'tan inject edilir).
  Future<void> init({
    required void Function(RemoteMessage) onBildirimAc,
    required void Function(RemoteMessage) onIlkAcilis,
  }) async {
    // 1. İzin iste (iOS + Android 13+)
    final izin = await _messaging.requestPermission();
    if (kDebugMode) {
      debugPrint('FCM izin durumu: ${izin.authorizationStatus}');
    }
    // Kullanıcı reddettiyse bildirimler çalışmayacak — sessizce devam et,
    // ama Crashlytics'e logla ki production'da kaç kullanıcı reddettiğini görelim.
    if (izin.authorizationStatus == AuthorizationStatus.denied) {
      AppHataYonetici.logla(
        Exception('FCM izni reddedildi'),
        null,
        etiket: 'fcm.izin_reddedildi',
      );
    }

    // 2. Kullanıcı giriş/çıkış yaptıkça token kaydet / sil
    _authSub = _auth.authStateChanges().listen(_authDegisti);

    // 3. Token yenilenince Firestore'u güncelle
    _tokenSub = _messaging.onTokenRefresh.listen((yeniToken) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) _tokenKaydet(uid, yeniToken);
    });

    // 4. Foreground — in-app banner
    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      _foregroundMesajIsle(message, onBildirimAc);
    });

    // 5. Arka planda bildirime tıklandı
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(onBildirimAc);

    // 6. Uygulama kapalıyken bildirime tıklanıp açıldı — HomeScreen'de işlenir
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onIlkAcilis(initialMessage);
    }
  }

  /// Auth değişince çağrılır.
  /// - user != null → token al ve kaydet
  /// - user == null → token sil (çıkış yapıldı)
  Future<void> _authDegisti(User? user) async {
    if (user == null) {
      // AuthRepository.cikisYap() çağrısından önce token zaten silinir,
      // ama güvence olarak burada da deneriz.
      await _tokenSil();
      return;
    }
    final token = await _messaging.getToken();
    if (token != null) await _tokenKaydet(user.uid, token);
  }

  /// Token'ı Firestore'a yazar.
  /// set(merge:true) → döküman yoksa bile çalışır, sadece fcmToken alanını yazar.
  Future<void> _tokenKaydet(String uid, String token) async {
    try {
      await _firestore
          .collection(Collections.kullanicilar)
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      debugPrint('[FCM] Token kaydedildi: $token');
    } catch (e) {
      debugPrint('[FCM] Token kaydedilemedi: $e');
    }
  }

  /// Firestore'dan fcmToken alanını siler.
  /// Sadece kullanıcı oturumu açıkken çağrılır.
  Future<void> _tokenSil() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection(Collections.kullanicilar)
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()});
      debugPrint('[FCM] Token silindi');
    } catch (e) {
      debugPrint('[FCM] Token silinemedi: $e');
    }
  }

  /// Foreground mesajı → BannerService ile in-app bildirim gösterir.
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

  /// Uygulama kapanırken çağrılır (gerekirse).
  void dispose() {
    _authSub?.cancel();
    _tokenSub?.cancel();
    _messageSub?.cancel();
    _openedAppSub?.cancel();
  }
}