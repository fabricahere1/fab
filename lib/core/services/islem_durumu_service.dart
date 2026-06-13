import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'banner_service.dart';
import '../../features/mesajlar/domain/islem_durumu.dart';
import '../../shared/constants/app_constants.dart';

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
        .collection(Collections.sohbetler)
        .where('kullanicilar', arrayContains: user.uid)
        .snapshots()
        .listen((snap) {
      // Cancel listeners for sohbets no longer in the query
      final mevcutIds = snap.docs.map((d) => d.id).toSet();
      final kaldirilan = _islemListeners.keys.toSet().difference(mevcutIds);
      for (final id in kaldirilan) {
        _islemListeners.remove(id)?.cancel();
        _oncekiDurumlar.remove(id);
      }

      for (final doc in snap.docs) {
        final sohbetId = doc.id;
        if (_islemListeners.containsKey(sohbetId)) continue;

        bool ilkSnapshot = true;

        final sub = _firestore
            .collection(Collections.sohbetler)
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
                  _anlasildibildirimiGonder(
                    benimUid: user.uid,
                    karsiUid: karsiUid,
                    ilanBaslik: ilanBaslik,
                    sohbetId: sohbetId,
                  );
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
                _durumBildirimiGonder(
                  benimUid: user.uid,
                  karsiUid: karsiUid,
                  ilanBaslik: ilanBaslik,
                  sohbetId: sohbetId,
                  durum: durum,
                );
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

  Future<void> _anlasildibildirimiGonder({
    required String benimUid,
    required String karsiUid,
    required String ilanBaslik,
    required String sohbetId,
  }) async {
    try {
      final benimDoc = await _firestore
          .collection(Collections.kullanicilar)
          .doc(benimUid)
          .get();
      if (!benimDoc.exists) return;
      final benimAd = (benimDoc.data()?['adSoyad'] as String?) ?? 'Karşı taraf';
      final icerik = '"$ilanBaslik" ilanı için anlaşma önerdi!';

      BannerService.instance.goster(baslik: benimAd, icerik: icerik, tip: 'islem');

      await _firestore.collection(Collections.bildirimler).add({
        'kullaniciId': karsiUid,
        'tip':         'anlasildi',
        'baslik':      benimAd,
        'icerik':      icerik,
        'okundu':      false,
        'tarih':       FieldValue.serverTimestamp(),
        'hedefId':     sohbetId,
        'gondereId':   benimUid,
        'gondereAd':   benimAd,
      });
    } catch (_) {}
  }

  Future<void> _durumBildirimiGonder({
    required String benimUid,
    required String karsiUid,
    required String ilanBaslik,
    required String sohbetId,
    required IslemDurumu durum,
  }) async {
    try {
      final karsiDoc = await _firestore
          .collection(Collections.kullanicilar)
          .doc(karsiUid)
          .get();
      if (!karsiDoc.exists) return;
      final karsiAd = (karsiDoc.data()?['adSoyad'] as String?) ?? 'Karşı taraf';
      final icerik = '"$ilanBaslik" ilanınızı ${durum.gecmisDonusu}';

      BannerService.instance.goster(baslik: karsiAd, icerik: icerik, tip: 'islem');

      if (_bildirimYazilacakDurumlar.contains(durum)) {
        await _firestore.collection(Collections.bildirimler).add({
          'kullaniciId': benimUid,
          'tip':         durum == IslemDurumu.anlasildi ? 'anlasildi' : 'sistem',
          'baslik':      karsiAd,
          'icerik':      icerik,
          'okundu':      false,
          'tarih':       FieldValue.serverTimestamp(),
          'hedefId':     sohbetId,
          'gondereId':   karsiUid,
          'gondereAd':   karsiAd,
        });
      }
    } catch (_) {}
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