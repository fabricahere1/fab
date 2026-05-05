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
}