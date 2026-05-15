import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'banner_service.dart';
import '../../features/mesajlar/domain/islem_durumu.dart';

/// Sohbet işlem durumlarını dinler, in-app banner gösterir
/// ve bildirimler collection'a yazar.
class IslemDurumuService {
  IslemDurumuService._();
  static final instance = IslemDurumuService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  final Map<String, StreamSubscription> _islemListeners = {};
  final Map<String, Map<String, dynamic>> _oncekiDurumlar = {};
  StreamSubscription? _sohbetlerSub;
  StreamSubscription? _authSub;

  // iletisimBasladi hariç bildirim yazılacak durumlar
  static const _bildirimYazilacakDurumlar = {
    IslemDurumu.anlasildi,
    IslemDurumu.siparisVerildi,
    IslemDurumu.urunAlindi,
    IslemDurumu.yolaCikti,
    IslemDurumu.teslimEdildi,
    IslemDurumu.teslimAlindi,
  };

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

        bool ilkSnapshot = true;

        final sub = _firestore
            .collection('sohbetler')
            .doc(sohbetId)
            .snapshots()
            .listen((sohbetDoc) {
          if (!sohbetDoc.exists) return;
          final d = sohbetDoc.data() as Map<String, dynamic>;
          final islemDurumlari = Map<String, dynamic>.from(
              d['islemDurumlari'] as Map? ?? {});

          // İlk snapshot'ı baseline olarak kaydet, bildirim gösterme
          if (ilkSnapshot) {
            ilkSnapshot = false;
            _oncekiDurumlar[sohbetId] =
                Map<String, dynamic>.from(islemDurumlari);
            return;
          }

          final onceki = _oncekiDurumlar[sohbetId] ?? {};

          for (final durum in IslemDurumu.values) {
            // anlasildi özel case — her kullanıcının kendi onayını takip et
            if (durum == IslemDurumu.anlasildi) {
              final benimKey = 'anlasildi_${user.uid}';
              final yeniOnay = islemDurumlari[benimKey] == true;
              final eskiOnay = onceki[benimKey] == true;

              if (yeniOnay && !eskiOnay) {
                // Ben yeni onayladım → karşı tarafa bildirim gönder
                final kullanicilar = List<String>.from(d['kullanicilar'] ?? []);
                final karsiUid = kullanicilar.firstWhere(
                  (id) => id != user.uid,
                  orElse: () => '',
                );

                if (karsiUid.isNotEmpty) {
                  final ilanBaslik = d['ilanBaslik'] as String? ?? 'İlan';

                  _firestore
                      .collection('kullanicilar')
                      .doc(user.uid)
                      .get()
                      .then((benimDoc) {
                    if (!benimDoc.exists) return;
                    final benimAd =
                        (benimDoc.data()?['adSoyad'] as String?) ?? 'Karşı taraf';
                    final icerik = '"$ilanBaslik" ilanı için anlaşma önerdi!';

                    BannerService.instance.goster(
                      baslik: benimAd,
                      icerik: icerik,
                      tip: 'islem',
                    );

                    _firestore.collection('bildirimler').add({
                      'kullaniciId': karsiUid,
                      'tip':         'anlasildi',
                      'baslik':      benimAd,
                      'icerik':      icerik,
                      'okundu':      false,
                      'tarih':       FieldValue.serverTimestamp(),
                      'hedefId':     sohbetId,
                      'gondereId':   user.uid,
                      'gondereAd':   benimAd,
                    });
                  });
                }
              }
              continue;
            }

            // Diğer durumlar
            final key = durum.firestoreKey;
            final bool yeniDeger = islemDurumlari[key] == true;
            final bool eskiDeger = onceki[key] == true;

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

                  final icerik =
                      '"$ilanBaslik" ilanınızı ${durum.gecmisDonusu}';

                  // Banner göster
                  BannerService.instance.goster(
                    baslik: karsiAd,
                    icerik: icerik,
                    tip: 'islem',
                  );

                  // Bildirim collection'a yaz (iletisimBasladi hariç)
                  if (_bildirimYazilacakDurumlar.contains(durum)) {
                    final bildirimTip = durum == IslemDurumu.anlasildi
                        ? 'anlasildi'
                        : 'sistem';
                    _firestore.collection('bildirimler').add({
                      'kullaniciId': user.uid,
                      'tip':         bildirimTip,
                      'baslik':      karsiAd,
                      'icerik':      icerik,
                      'okundu':      false,
                      'tarih':       FieldValue.serverTimestamp(),
                      'hedefId':     sohbetId,
                      'gondereId':   karsiUid,
                      'gondereAd':   karsiAd,
                    });
                  }
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