import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/constants/app_constants.dart';
 
part 'mesaj_repository.g.dart';
 
String sohbetIdUret(String uid1, String uid2, String ilanId) {
  final ids = [uid1, uid2]..sort();
  return '${ids[0]}_${ids[1]}_$ilanId';
}
 
@riverpod
MesajRepository mesajRepository(Ref ref) {
  return MesajRepository(firestore: FirebaseFirestore.instance);
}
 
class MesajRepository {
  final FirebaseFirestore firestore;
 
  MesajRepository({required this.firestore});
 
  CollectionReference get _sohbetler =>
      firestore.collection(Collections.sohbetler);
 
  CollectionReference _mesajlar(String sohbetId) =>
      _sohbetler.doc(sohbetId).collection(Collections.mesajlar);
 
  Future<void> mesajGonder({
    required String sohbetId,
    required String gondereId,
    required String gondereAd,
    required String karsiId,
    required String karsiAd,
    required String ilanId,
    required String ilanBaslik,
    required String metin,
    String ilanResimUrl = '',
    String tip = 'mesaj',
  }) async {
    final sohbetRef = _sohbetler.doc(sohbetId);
    final mesajRef = _mesajlar(sohbetId).doc();
    final batch = firestore.batch();
 
    batch.set(sohbetRef, {
      'kullanicilar':         [gondereId, karsiId],
      'kullaniciAdlari':      {gondereId: gondereAd, karsiId: karsiAd},
      'ilanId':               ilanId,
      'ilanBaslik':           ilanBaslik,
      'ilanResimUrl':         ilanResimUrl,
      'sonMesaj':             metin,
      'sonMesajZamani':       FieldValue.serverTimestamp(),
      'sonGondereId':         gondereId,
      'degerlendirmeYapildi': false,
      'olusturmaTarihi':      FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
 
    batch.set(mesajRef, {
      'metin':     metin,
      'gondereId': gondereId,
      'gondereAd': gondereAd,
      'tip':       tip,
      'zaman':     FieldValue.serverTimestamp(),
      'okundu':    false,
    });
 
    await batch.commit();
 
    // ✅ okunmamis sayacını ayrı update ile artır
    await sohbetRef.update({
      'okunmamis.$karsiId': FieldValue.increment(1),
    });
  }
 
  Stream<QuerySnapshot> mesajlarStream({
    required String sohbetId,
    int limit = Pagination.mesajSayfaBoyutu,
  }) {
    return _mesajlar(sohbetId)
        .orderBy('zaman', descending: true)
        .limit(limit)
        .snapshots();
  }
 
  Future<QuerySnapshot> eskiMesajlariGetir({
    required String sohbetId,
    required DocumentSnapshot sonDoc,
    int limit = Pagination.mesajSayfaBoyutu,
  }) {
    return _mesajlar(sohbetId)
        .orderBy('zaman', descending: true)
        .startAfterDocument(sonDoc)
        .limit(limit)
        .get();
  }
 
  Future<void> okunduIsaretle({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    try {
      // Okunmamis sayacını sıfırla
      await _sohbetler.doc(sohbetId).update({
        'okunmamis.$kullaniciId': 0,
      });
 
      // ✅ isNotEqualTo kaldırıldı — Firestore'da isNotEqualTo + isEqualTo birlikte çalışmıyor
      final mesajlar = await _mesajlar(sohbetId)
          .where('okundu', isEqualTo: false)
          .get();
 
      if (mesajlar.docs.isEmpty) return;
 
      final batch = firestore.batch();
      for (final doc in mesajlar.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Kendi gönderdiğimiz mesajları atlat
        if (data['gondereId'] == kullaniciId) continue;
        batch.update(doc.reference, {'okundu': true});
      }
      await batch.commit();
    } catch (_) {}
  }
 
  Future<void> mesajSil({
    required String sohbetId,
    required String mesajId,
    required String metin,
  }) async {
    final sohbetRef = _sohbetler.doc(sohbetId);
    await _mesajlar(sohbetId).doc(mesajId).delete();
    final sohbetSnap = await sohbetRef.get();
    if (sohbetSnap.exists &&
        (sohbetSnap.data() as Map<String, dynamic>?)?['sonMesaj'] == metin) {
      final onceki = await _mesajlar(sohbetId)
          .orderBy('zaman', descending: true)
          .limit(1)
          .get();
      await sohbetRef.update({
        'sonMesaj': onceki.docs.isNotEmpty
            ? (onceki.docs.first.data() as Map<String, dynamic>)['metin'] ?? ''
            : '',
      });
    }
  }
 
  Stream<List<Map<String, dynamic>>> sohbetlerStream(String kullaniciId) {
    return _sohbetler
        .where('kullanicilar', arrayContains: kullaniciId)
        .orderBy('sonMesajZamani', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }
 
  Future<void> sohbetiGizle({
    required String sohbetId,
    required String kullaniciId,
  }) =>
      _sohbetler.doc(sohbetId).update({
        'gizli.$kullaniciId': FieldValue.serverTimestamp(),
      });
 
  Future<void> sohbetiSabitle({
    required String sohbetId,
    required String kullaniciId,
    required bool sabitlenmis,
  }) =>
      _sohbetler.doc(sohbetId).update({
        'sabitlenmis.$kullaniciId': !sabitlenmis,
      });
 
  Stream<int> toplamOkunmamisStream(String kullaniciId) {
    return _sohbetler
        .where('kullanicilar', arrayContains: kullaniciId)
        .snapshots()
        .map((snap) {
      int toplam = 0;
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final gizli = (d['gizli'] as Map<String, dynamic>?) ?? {};
        final gizliDeger = gizli[kullaniciId];
        if (gizliDeger != null) {
          if (gizliDeger is bool && gizliDeger == true) continue;
          if (gizliDeger is Timestamp) {
            final sonMesajZamani = d['sonMesajZamani'] as Timestamp?;
            if (sonMesajZamani == null) continue;
            if (!sonMesajZamani.toDate().isAfter(gizliDeger.toDate())) continue;
          }
        }
        final okunmamis = (d['okunmamis'] as Map<String, dynamic>?) ?? {};
        toplam += ((okunmamis[kullaniciId] as num?)?.toInt() ?? 0);
      }
      return toplam;
    });
  }
}