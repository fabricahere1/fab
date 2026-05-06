import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'banner_service.dart';
import '../../features/mesajlar/domain/islem_durumu.dart';

/// Sohbet işlem durumlarını dinler ve in-app banner gösterir.
/// main.dart'ın bu mantıktan haberi olmamalı.
class IslemDurumuService {
  IslemDurumuService._();
  static final instance = IslemDurumuService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  final Map<String, StreamSubscription> _islemListeners = {};
  final Map<String, Map<String, dynamic>> _oncekiDurumlar = {};
  StreamSubscription? _sohbetlerSub;
  StreamSubscription? _authSub;

  void init() {
    _authSub = _auth.authStateChanges().listen(_authDegisti);
  }

  void _authDegisti(User? user) {
    _sohbetlerSub?.cancel();
    for (final sub in _islemListeners.values) {
      sub.cancel();
    }
    _islemListeners.clear();
    _oncekiDurumlar.clear();

    if (user == null) return;

    _sohbetlerSub = _firestore
        .collection('sohbetler')
        .where('kullanicilar', arrayContains: user.uid)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final sohbetId = doc.id;
        if (_islemListeners.containsKey(sohbetId)) continue;

        final sub = _firestore
            .collection('sohbetler')
            .doc(sohbetId)
            .snapshots()
            .listen((sohbetDoc) {
          if (!sohbetDoc.exists) return;
          final d = sohbetDoc.data() as Map<String, dynamic>;
          final islemDurumlari = Map<String, dynamic>.from(
              d['islemDurumlari'] as Map? ?? {});
          final onceki = _oncekiDurumlar[sohbetId] ?? {};

          for (final durum in IslemDurumu.values) {
            final key = durum.firestoreKey;
            final yeniDeger = islemDurumlari[key] == true;
            final eskiDeger = onceki[key] == true;

            if (yeniDeger && !eskiDeger) {
              final kullanicilar =
                  List<String>.from(d['kullanicilar'] ?? []);
              final karsiUid = kullanicilar.firstWhere(
                (id) => id != user.uid,
                orElse: () => '',
              );

              if (karsiUid.isNotEmpty) {
                final ilanBaslik = d['ilanBaslik'] as String? ?? 'İlan';

                _firestore
                    .collection('kullanicilar')
                    .doc(karsiUid)
                    .get()
                    .then((karsiDoc) {
                  if (!karsiDoc.exists) return;
                  final karsiAd =
                      (karsiDoc.data()?['adSoyad'] as String?) ??
                          'Karşı taraf';

                  BannerService.instance.goster(
                    baslik: karsiAd,
                    icerik: '"$ilanBaslik" ilanınızı '
                        '${durum.gecmisDonusu}',
                    tip: 'islem',
                  );
                });
              }
            }
          }

          _oncekiDurumlar[sohbetId] =
              Map<String, dynamic>.from(islemDurumlari);
        });

        _islemListeners[sohbetId] = sub;
      }
    });
  }

  void dispose() {
    _authSub?.cancel();
    _sohbetlerSub?.cancel();
    for (final sub in _islemListeners.values) {
      sub.cancel();
    }
    _islemListeners.clear();
    _oncekiDurumlar.clear();
  }
}