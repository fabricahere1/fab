// lib/features/degerlendirme/data/degerlendirme_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/constants/app_constants.dart';

part 'degerlendirme_repository.g.dart';

@riverpod
DegerlendirmeRepository degerlendirmeRepository(Ref ref) {
  return DegerlendirmeRepository(firestore: FirebaseFirestore.instance);
}

class DegerlendirmeRepository {
  final FirebaseFirestore _db;

  DegerlendirmeRepository({required FirebaseFirestore firestore})
      : _db = firestore;

  int _tariheGoreSirala(dynamic tA, dynamic tB) {
    if (tA == null && tB == null) return 0;
    if (tA == null) return 1;
    if (tB == null) return -1;
    try {
      final dtA = (tA as Timestamp).toDate();
      final dtB = (tB as Timestamp).toDate();
      return dtB.compareTo(dtA);
    } catch (_) {
      return 0;
    }
  }

  Future<void> degerlendirmeGonder({
    required String sohbetId,
    required String degerlendireninId,
    required String hedefKullaniciId,
    required double puan,
    required String yorum,
    String ilanBaslik = '',
  }) async {
    final bekleyenRef = _db
        .collection(Collections.kullanicilar)
        .doc(degerlendireninId)
        .collection('bekleyenDegerlendirmeler')
        .doc(sohbetId);

    await _db.runTransaction((tx) async {
      final sohbetRef  = _db.collection(Collections.sohbetler).doc(sohbetId);
      final userRef    = _db.collection(Collections.kullanicilar).doc(hedefKullaniciId);
      final degRef     = _db.collection(Collections.degerlendirmeler).doc();
      final bekleyenSnap = await tx.get(bekleyenRef);

      final sohbetSnap = await tx.get(sohbetRef);
      final snap       = await tx.get(userRef);

      // Mükerrer değerlendirmeyi önle — transaction içinde atomik kontrol
      if (sohbetSnap.exists) {
        final d = sohbetSnap.data() as Map<String, dynamic>;
        if (d['degerlendirmeYapildi_$degerlendireninId'] == true) {
          throw Exception('zaten_degerlendirdi');
        }
      }

      tx.set(degRef, {
        'sohbetId':          sohbetId,
        'degerlendireninId': degerlendireninId,
        'hedefKullaniciId':  hedefKullaniciId,
        'puan':              puan,
        'yorum':             yorum,
        'ilanBaslik':        ilanBaslik,
        'tarih':             FieldValue.serverTimestamp(),
      });

      // set+merge kullan — doküman yoksa da güvenli çalışır
      tx.set(sohbetRef, {
        'degerlendirmeYapildi_$degerlendireninId': true,
      }, SetOptions(merge: true));

      // Bekleyen değerlendirme kaydı varsa transaction içinde tamamlandı işaretle
      if (bekleyenSnap.exists) {
        tx.update(bekleyenRef, {'tamamlandi': true});
      }

      if (snap.exists) {
        final d = snap.data() as Map<String, dynamic>;
        final mevcutPuan = (d['ortalamaPuan']        as num?)?.toDouble() ?? 0.0;
        final mevcutSayi = (d['degerlendirmeSayisi'] as num?)?.toInt()    ?? 0;
        final yeniSayi   = mevcutSayi + 1;
        final yeniPuan   = ((mevcutPuan * mevcutSayi) + puan) / yeniSayi;
        tx.update(userRef, {
          'ortalamaPuan':        yeniPuan,
          'degerlendirmeSayisi': yeniSayi,
        });
      }
    });
  }

  Future<void> sohbetDegerlendirmeyiIsaretle({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    await _db.collection(Collections.sohbetler).doc(sohbetId).update({
      'degerlendirmeYapildi_$kullaniciId': true,
    });
  }

  Future<bool> zatenDegerlendirdimMi({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    final snap = await _db.collection(Collections.sohbetler).doc(sohbetId).get();
    if (!snap.exists) return false;
    final d = snap.data() as Map<String, dynamic>;
    return d['degerlendirmeYapildi_$kullaniciId'] == true;
  }

  Future<void> bekleyenDegerlendirmeKaydet({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    await _db
        .collection(Collections.kullanicilar)
        .doc(kullaniciId)
        .collection('bekleyenDegerlendirmeler')
        .doc(sohbetId)
        .set({
      'sohbetId':   sohbetId,
      'tarih':      FieldValue.serverTimestamp(),
      'tamamlandi': false,
    }, SetOptions(merge: true));
  }

  // orderBy kaldırıldı — composite index gerektirmesin, client-side sıralanıyor
  Stream<List<Map<String, dynamic>>> kullaniciDegerlendirmeleriStream(
      String hedefKullaniciId) {
    return _db
        .collection(Collections.degerlendirmeler)
        .where('hedefKullaniciId', isEqualTo: hedefKullaniciId)
        .snapshots()
        .map((snap) {
      final liste = snap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      liste.sort((a, b) => _tariheGoreSirala(a['tarih'], b['tarih']));
      return liste;
    });
  }

  // orderBy kaldırıldı — composite index gerektirmesin, client-side sıralanıyor
  Stream<List<Map<String, dynamic>>> bekleyenDegerlendirmelerStream(
      String kullaniciId) {
    return _db
        .collection(Collections.kullanicilar)
        .doc(kullaniciId)
        .collection('bekleyenDegerlendirmeler')
        .where('tamamlandi', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final liste = snap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      liste.sort((a, b) => _tariheGoreSirala(a['tarih'], b['tarih']));
      return liste;
    });
  }

  /// Bekleyen değerlendirme kaydını tamamlandı olarak işaretler.
  /// Kayıt yoksa (sohbet ekranından direkt yapıldıysa) sessizce döner.
  Future<void> bekleyenDegerlendirmeTamamla({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    final ref = _db
        .collection(Collections.kullanicilar)
        .doc(kullaniciId)
        .collection('bekleyenDegerlendirmeler')
        .doc(sohbetId);
    final snap = await ref.get();
    if (!snap.exists) return;
    await ref.update({'tamamlandi': true});
  }
}