import '../firebase/app_firestore.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'banner_service.dart';
import '../../shared/constants/app_constants.dart';

/// "anlasildi" ve "sistem" (işlem durumu) tipindeki bildirimleri dinler,
/// karşı tarafın ekranında CANLI banner gösterir.
///
/// Mesaj bildirimleri (tip: 'mesaj') buraya dahil edilmedi — onlar zaten
/// FCM foreground mesaj işleme akışında ayrı bir banner gösterimine sahip
/// olabilir, burada da göstermek çift banner riski taşırdı.
///
/// IslemDurumuService'in eski "sohbet dökümanını dinle, durumu fark et"
/// yaklaşımının yerine geçer — bu servis, doğrudan `bildirimler`
/// koleksiyonunu (kullaniciId == benimUid) dinler. Bildirim artık ilgili
/// repository fonksiyonu tarafından İŞLEM ANINDA, garantili şekilde
/// yazıldığı için (mesaj bildirimleriyle aynı, kanıtlanmış desen), bu
/// dinleyicinin tek işi "yeni bir bildirim koleksiyona eklendiğinde onu
/// banner olarak göster" — durum karşılaştırması/race condition riski yok.
class BildirimBannerService {
  BildirimBannerService._();
  static final instance = BildirimBannerService._();

  final _firestore = AppFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  StreamSubscription? _authSub;
  StreamSubscription? _bildirimSub;
  bool _ilkSnapshot = true;

  static const _bannerGosterilecekTipler = {'anlasildi', 'sistem'};

  void init() {
    _authSub = _auth.authStateChanges().listen(_authDegisti);
  }

  void _authDegisti(User? user) {
    _bildirimSub?.cancel();
    _ilkSnapshot = true;

    if (user == null) return;

    _bildirimSub = _firestore
        .collection(Collections.bildirimler)
        .where('kullaniciId', isEqualTo: user.uid)
        .orderBy('tarih', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      // İlk snapshot — uygulama açılırken zaten var olan eski bildirimler.
      // Bunlar için banner gösterme, sadece baseline olarak kabul et.
      if (_ilkSnapshot) {
        _ilkSnapshot = false;
        return;
      }

      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        final tip = data['tip'] as String? ?? '';
        if (!_bannerGosterilecekTipler.contains(tip)) continue;

        final baslik = data['baslik'] as String? ?? '';
        final icerik = data['icerik'] as String? ?? '';
        if (icerik.isEmpty) continue;

        BannerService.instance.goster(baslik: baslik, icerik: icerik, tip: 'islem');
      }
    }, onError: (e, s) {
      // Eksik Firestore index'i ya da geçici bağlantı sorunu — banner
      // gösterilemese de uygulama hiçbir koşulda çökmemeli.
      debugPrint('[BildirimBannerService] dinleme hatası: $e');
    });
  }

  void dispose() {
    _authSub?.cancel();
    _bildirimSub?.cancel();
  }
}