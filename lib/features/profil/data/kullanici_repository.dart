import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/kullanici_model.dart';
import '../../../shared/constants/app_constants.dart';
 
part 'kullanici_repository.g.dart';
 
@riverpod
KullaniciRepository kullaniciRepository(Ref ref) {
  return KullaniciRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
    auth: FirebaseAuth.instance,
  );
}
 
class KullaniciRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirebaseAuth auth;
 
  KullaniciRepository({
    required this.firestore,
    required this.storage,
    required this.auth,
  });
 
  CollectionReference get _col =>
      firestore.collection(Collections.kullanicilar);
 
  Future<KullaniciModel?> kullaniciGetir(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return KullaniciModel.fromFirestore(doc);
  }
 
  Stream<KullaniciModel?> kullaniciStream(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return KullaniciModel.fromFirestore(doc);
    });
  }
 
  Stream<Map<String, dynamic>?> kullaniciDataStream(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>?;
    });
  }

  Future<Map<String, dynamic>?> kullaniciDataGetir(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }
 
  Future<void> profilOlustur({
    required String uid,
    required String adSoyad,
    required String email,
  }) async {
    await _col.doc(uid).set({
      'adSoyad':          adSoyad,
      'email': email,
      'profilTamamlandi': false,
      'olusturmaTarihi':  FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
 
  Future<void> profilGuncelle({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _col.doc(uid).update(data);
    if (data.containsKey('ortalamaPuan')) {
      final puan = (data['ortalamaPuan'] as num?)?.toDouble() ?? 0.0;
      final ilanSnap = await firestore
          .collection(Collections.ilanlar)
          .where('kullaniciId', isEqualTo: uid)
          .where('aktif', isEqualTo: true)
          .get();
      final batch = firestore.batch();
      for (final doc in ilanSnap.docs) {
        batch.update(doc.reference, {'kullaniciPuan': puan});
      }
      await batch.commit();
    }
  }
 
  Future<void> profilTamamla({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _col.doc(uid).set(
      {...data, 'profilTamamlandi': true, 'guncellemeTarihi': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
 
  Future<String> profilFotoYukle({
    required String uid,
    required File foto,
  }) async {
    final ref = storage
        .ref()
        .child(StoragePaths.profilFotolari)
        .child('$uid.jpg');
    await ref.putFile(foto);
    final url = await ref.getDownloadURL();
    await _col.doc(uid).update({'fotoUrl': url});
    await auth.currentUser?.updatePhotoURL(url);
    return url;
  }
 
 
 
  Future<void> engelle({required String benimUid, required String hedefUid}) =>
      _col.doc(benimUid).update({
        'engellenenler': FieldValue.arrayUnion([hedefUid]),
      });
 
  Future<void> engelKaldir({required String benimUid, required String hedefUid}) =>
      _col.doc(benimUid).update({
        'engellenenler': FieldValue.arrayRemove([hedefUid]),
      });
 
  Stream<List<String>> engellenenlerStream(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      return List<String>.from(
        (doc.data() as Map<String, dynamic>)['engellenenler'] ?? [],
      );
    });
  }
 
  Future<void> sikayetGonder({
    required String sikayetEdenId,
    required String hedefId,
    required String hedefAd,
    required String sebep,
    String ilanId = '',
  }) async {
    await firestore.collection(Collections.sikayetler).add({
      'sikayetEdenId': sikayetEdenId,
      'hedefId':       hedefId,
      'hedefAd':       hedefAd,
      'sebep':         sebep,
      'ilanId':        ilanId,
      'tarih':         FieldValue.serverTimestamp(),
    });
  }

  // ── Takip sistemi ──────────────────────────────────────────────────────────

  Future<void> takipEt({required String takipciId, required String takipEdilenId}) async {
    final takipId = '${takipciId}_$takipEdilenId';
    final takipRef = firestore.collection('takipler').doc(takipId);
    await firestore.runTransaction((txn) async {
      final snap = await txn.get(takipRef);
      if (snap.exists) return;
      txn.set(takipRef, {
        'takipciId':     takipciId,
        'takipEdilenId': takipEdilenId,
        'tarih':         FieldValue.serverTimestamp(),
      });
      txn.update(_col.doc(takipEdilenId), {'takipciSayisi': FieldValue.increment(1)});
      txn.update(_col.doc(takipciId), {'takipSayisi': FieldValue.increment(1)});
    });
  }

  Future<void> takipiBirak({required String takipciId, required String takipEdilenId}) async {
    final takipId = '${takipciId}_$takipEdilenId';
    final takipRef = firestore.collection('takipler').doc(takipId);
    await firestore.runTransaction((txn) async {
      final snap = await txn.get(takipRef);
      if (!snap.exists) return;
      txn.delete(takipRef);
      txn.update(_col.doc(takipEdilenId), {'takipciSayisi': FieldValue.increment(-1)});
      txn.update(_col.doc(takipciId), {'takipSayisi': FieldValue.increment(-1)});
    });
  }

  Stream<bool> takipEdiyorMu({required String takipciId, required String takipEdilenId}) {
    return firestore
        .collection('takipler')
        .doc('${takipciId}_$takipEdilenId')
        .snapshots()
        .map((snap) => snap.exists);
  }

  Stream<List<String>> takipciIdleriStream(String kullaniciId) {
    return firestore
        .collection('takipler')
        .where('takipEdilenId', isEqualTo: kullaniciId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()['takipciId'] as String).toList());
  }

  Stream<List<String>> takipEdilenIdleriStream(String kullaniciId) {
    return firestore
        .collection('takipler')
        .where('takipciId', isEqualTo: kullaniciId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()['takipEdilenId'] as String).toList());
  }

  /// Takip edilen kullanıcıların id → takip başlangıç tarihi haritası.
  /// "Takip ettiğin taşıyıcıların YENİ ilanları" gibi, takipten sonra açılan
  /// ilanları filtrelemek için zaman bilgisine ihtiyaç duyan akışlar kullanır.
  Stream<Map<String, DateTime>> takipEdilenTarihleriStream(String kullaniciId) {
    return firestore
        .collection('takipler')
        .where('takipciId', isEqualTo: kullaniciId)
        .snapshots()
        .map((snap) => {
              for (final d in snap.docs)
                d.data()['takipEdilenId'] as String:
                    (d.data()['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
  }

  /// Ortalama puanı [minPuan] ve üzeri olan taşıyıcılar, puana göre sıralı.
  Future<List<KullaniciModel>> yuksekPuanliTasiyicilariGetir({
    double minPuan = 4.0,
    int limit = 20,
  }) async {
    final snap = await _col
        .where('ortalamaPuan', isGreaterThanOrEqualTo: minPuan)
        .orderBy('ortalamaPuan', descending: true)
        .limit(limit * 3) // istekçi tipi olanları eledikten sonra yetsin diye fazla çek
        .get();
    return snap.docs
        .map(KullaniciModel.fromFirestore)
        .where((k) => k.tasiyiciMi)
        .take(limit)
        .toList();
  }

  /// Ortalama puanı [minPuan] ve üzeri olan istekçiler, puana göre sıralı.
  Future<List<KullaniciModel>> yuksekPuanliIstekcileriGetir({
    double minPuan = 4.0,
    int limit = 20,
  }) async {
    final snap = await _col
        .where('ortalamaPuan', isGreaterThanOrEqualTo: minPuan)
        .orderBy('ortalamaPuan', descending: true)
        .limit(limit * 3) // taşıyıcı tipi olanları eledikten sonra yetsin diye fazla çek
        .get();
    return snap.docs
        .map(KullaniciModel.fromFirestore)
        .where((k) => k.istekMi)
        .take(limit)
        .toList();
  }
}