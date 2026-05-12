// lib/features/degerlendirme/data/degerlendirme_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'degerlendirme_repository.g.dart';

@riverpod
DegerlendirmeRepository degerlendirmeRepository(Ref ref) {
  return DegerlendirmeRepository();
}

class DegerlendirmeRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> degerlendirmeGonder({
    required String sohbetId,
    required String degerlendireninId,
    required String hedefKullaniciId,
    required double puan,
    required String yorum,
    String ilanBaslik = '',
  }) async {
    await _db.runTransaction((tx) async {
      final userRef = _db.collection('kullanicilar').doc(hedefKullaniciId);
      final degRef  = _db.collection('degerlendirmeler').doc();
      final snap    = await tx.get(userRef);

      tx.set(degRef, {
        'sohbetId':          sohbetId,
        'degerlendireninId': degerlendireninId,
        'hedefKullaniciId':  hedefKullaniciId,
        'puan':              puan,
        'yorum':             yorum,
        'ilanBaslik':        ilanBaslik,
        'tarih':             FieldValue.serverTimestamp(),
      });

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
    await _db.collection('sohbetler').doc(sohbetId).update({
      'degerlendirmeYapildi_$kullaniciId': true,
    });
  }

  Future<bool> zatenDegerlendirdimMi({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    final snap = await _db.collection('sohbetler').doc(sohbetId).get();
    if (!snap.exists) return false;
    final d = snap.data() as Map<String, dynamic>;
    return d['degerlendirmeYapildi_$kullaniciId'] == true;
  }

  Future<void> bekleyenDegerlendirmeKaydet({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    await _db
        .collection('kullanicilar')
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
        .collection('degerlendirmeler')
        .where('hedefKullaniciId', isEqualTo: hedefKullaniciId)
        .snapshots()
        .map((snap) {
      final liste = snap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      liste.sort((a, b) {
        final tA = a['tarih'];
        final tB = b['tarih'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        try {
          final dtA = (tA as dynamic).toDate() as DateTime;
          final dtB = (tB as dynamic).toDate() as DateTime;
          return dtB.compareTo(dtA);
        } catch (_) {
          return 0;
        }
      });
      return liste;
    });
  }

  // orderBy kaldırıldı — composite index gerektirmesin, client-side sıralanıyor
  Stream<List<Map<String, dynamic>>> bekleyenDegerlendirmelerStream(
      String kullaniciId) {
    return _db
        .collection('kullanicilar')
        .doc(kullaniciId)
        .collection('bekleyenDegerlendirmeler')
        .where('tamamlandi', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final liste = snap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      // Client-side tarihe göre sırala
      liste.sort((a, b) {
        final tA = a['tarih'];
        final tB = b['tarih'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        try {
          final dtA = (tA as dynamic).toDate() as DateTime;
          final dtB = (tB as dynamic).toDate() as DateTime;
          return dtB.compareTo(dtA);
        } catch (_) {
          return 0;
        }
      });
      return liste;
    });
  }

  Future<void> bekleyenDegerlendirmeTamamla({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    await _db
        .collection('kullanicilar')
        .doc(kullaniciId)
        .collection('bekleyenDegerlendirmeler')
        .doc(sohbetId)
        .update({'tamamlandi': true});
  }
}