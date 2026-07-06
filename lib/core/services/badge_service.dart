import '../firebase/app_firestore.dart';
import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Okunmamış bildirim sayısını dinler ve uygulama ikonuna badge yazar.
class BadgeService {
  BadgeService._();
  static final instance = BadgeService._();

  final _firestore = AppFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  StreamSubscription? _authSub;
  StreamSubscription? _bildirimSub;

  void init() {
    _authSub = _auth.authStateChanges().listen(_authDegisti);
  }

  void _authDegisti(User? user) {
    _bildirimSub?.cancel();

    if (user == null) {
      AppBadgePlus.updateBadge(0);
      return;
    }

    _bildirimSub = _firestore
        .collection('bildirimler')
        .where('kullaniciId', isEqualTo: user.uid)
        .where('okundu', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      AppBadgePlus.updateBadge(snap.size);
    });
  }

  void dispose() {
    _authSub?.cancel();
    _bildirimSub?.cancel();
  }
}