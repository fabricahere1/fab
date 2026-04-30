import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    return _kullaniciModelCevir(doc);
  }
 
  Stream<KullaniciModel?> kullaniciStream(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _kullaniciModelCevir(doc);
    });
  }
 
  Stream<Map<String, dynamic>?> kullaniciDataStream(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>?;
    });
  }
 
  Future<void> profilOlustur({
    required String uid,
    required String adSoyad,
    String? email,
  }) async {
    await _col.doc(uid).set({
      'adSoyad':          adSoyad,
      'email': ?email,
      'profilTamamlandi': false,
      'olusturmaTarihi':  FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
 
  Future<void> profilGuncelle({
    required String uid,
    required Map<String, dynamic> data,
  }) => _col.doc(uid).update(data);
 
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
 
  Future<void> fcmTokenKaydet(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) {
        await _col.doc(uid).update({'fcmToken': token});
      }
      messaging.onTokenRefresh.listen((yeniToken) {
        _col.doc(uid).update({'fcmToken': yeniToken});
      });
    } catch (_) {}
  }
 
  Future<void> fcmTokenSil(String uid) async {
    try {
      await _col.doc(uid).update({'fcmToken': FieldValue.delete()});
    } catch (_) {}
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
  // Timestamp → DateTime dönüşümü data katmanında yapılır — domain Firebase'i tanımaz
  KullaniciModel _kullaniciModelCevir(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return KullaniciModel(
      id:                   doc.id,
      adSoyad:              d['adSoyad']              as String? ?? '',
      fotoUrl:              d['fotoUrl']              as String?,
      telefon:              d['telefon']              as String?,
      email:                d['email']                as String?,
      fcmToken:             d['fcmToken']             as String?,
      profilTamamlandi:     d['profilTamamlandi']     as bool?   ?? false,
      ortalamaPuan:         ((d['ortalamaPuan']       as num?)?.toDouble()) ?? 0.0,
      degerlendirmeSayisi:  ((d['degerlendirmeSayisi'] as num?)?.toInt()) ?? 0,
      kullaniciTipi:        d['kullaniciTipi']        as String? ?? '',
      yasadigiUlke:         d['yasadigiUlke']         as String? ?? '',
      bulunduguSehir:       d['bulunduguSehir']       as String? ?? '',
      geldigiSehirler:      List<String>.from(d['geldigiSehirler'] ?? []),
      hakkinda:             d['hakkinda']             as String? ?? '',
      sehir:                d['sehir']                as String? ?? '',
      telefonGizli:         d['telefonGizli']         as bool?   ?? false,
      engellenenler:        List<String>.from(d['engellenenler'] ?? []),
    );
  }

}