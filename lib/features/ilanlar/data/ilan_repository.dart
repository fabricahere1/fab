import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/ilan_model.dart';
import '../../../shared/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

part 'ilan_repository.g.dart';

class IlanSayfasi {
  final List<IlanModel> ilanlar;
  final DocumentSnapshot? sonDoc;
  final bool bitti;

  const IlanSayfasi({
    required this.ilanlar,
    required this.sonDoc,
    required this.bitti,
  });
}

@riverpod
IlanRepository ilanRepository(Ref ref) {
  return IlanRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
    auth: FirebaseAuth.instance,
  );
}

class IlanRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirebaseAuth auth;

  IlanRepository({
    required this.firestore,
    required this.storage,
    required this.auth,
  });

  CollectionReference get _col => firestore.collection(Collections.ilanlar);

  Future<IlanSayfasi> istekIlanlariniGetir({
    String? kategori,
    int limit = Pagination.ilanSayfaBoyutu,
  }) async {
    Query q = _col
        .where('tip', isEqualTo: IlanTip.istek)
        .where('aktif', isEqualTo: true)
        .orderBy('olusturmaTarihi', descending: true)
        .limit(limit);
    if (kategori != null) q = q.where('kategori', isEqualTo: kategori);
    final snap = await q.get();
    return IlanSayfasi(
      ilanlar: snap.docs.map(IlanModel.fromFirestore).toList(),
      sonDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      bitti: snap.docs.length < limit,
    );
  }

  Future<IlanSayfasi> tasiyiciIlanlariniGetir({
    bool tariheSore = true,
    int limit = Pagination.ilanSayfaBoyutu,
  }) async {
    if (tariheSore) {
      final bugun = Timestamp.fromDate(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );
      final gelecek = await _col
          .where('tip', isEqualTo: IlanTip.tasiyici)
          .where('aktif', isEqualTo: true)
          .where('tarih', isGreaterThanOrEqualTo: bugun)
          .orderBy('tarih', descending: false)
          .limit(limit)
          .get();
      final gecmis = await _col
          .where('tip', isEqualTo: IlanTip.tasiyici)
          .where('aktif', isEqualTo: true)
          .where('tarih', isLessThan: bugun)
          .orderBy('tarih', descending: true)
          .limit(10)
          .get();
      return IlanSayfasi(
        ilanlar: [
          ...gelecek.docs.map(IlanModel.fromFirestore),
          ...gecmis.docs.map(IlanModel.fromFirestore),
        ],
        sonDoc: gelecek.docs.isNotEmpty ? gelecek.docs.last : null,
        bitti: gelecek.docs.length < limit,
      );
    }
    final snap = await _col
        .where('tip', isEqualTo: IlanTip.tasiyici)
        .where('aktif', isEqualTo: true)
        .orderBy('olusturmaTarihi', descending: true)
        .limit(limit)
        .get();
    return IlanSayfasi(
      ilanlar: snap.docs.map(IlanModel.fromFirestore).toList(),
      sonDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      bitti: snap.docs.length < limit,
    );
  }

  Future<IlanSayfasi> sonrakiSayfayiGetir({
    required String tip,
    required DocumentSnapshot sonDoc,
    required String siralama,
    int limit = Pagination.ilanSayfaBoyutu,
  }) async {
    final orderField = (tip == IlanTip.tasiyici && siralama == 'tarih')
        ? 'tarih'
        : 'olusturmaTarihi';
    final snap = await _col
        .where('tip', isEqualTo: tip)
        .where('aktif', isEqualTo: true)
        .orderBy(orderField, descending: orderField == 'olusturmaTarihi')
        .startAfterDocument(sonDoc)
        .limit(limit)
        .get();
    return IlanSayfasi(
      ilanlar: snap.docs.map(IlanModel.fromFirestore).toList(),
      sonDoc: snap.docs.isNotEmpty ? snap.docs.last : sonDoc,
      bitti: snap.docs.length < limit,
    );
  }

  Stream<List<IlanModel>> kullaniciIlanlarStream(String kullaniciId) {
    return _col
        .where('kullaniciId', isEqualTo: kullaniciId)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IlanModel.fromFirestore).toList());
  }

  Future<String> ilanOlustur({
    required IlanModel ilan,
    List<File> resimler = const [],
    void Function(int index, double progress)? onProgress,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Giriş yapılmamış');
    final List<String> resimUrller = [];
    for (int i = 0; i < resimler.length; i++) {
      onProgress?.call(i, 0.0);
      final ref = storage
          .ref()
          .child(StoragePaths.ilanResimleri)
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      final task = ref.putFile(resimler[i]);
      task.snapshotEvents.listen((snap) {
        onProgress?.call(i, snap.bytesTransferred / snap.totalBytes);
      });
      await task;
      resimUrller.add(await ref.getDownloadURL());
    }
    final ilanData = ilan.toFirestore();
    if (resimUrller.isNotEmpty) {
      ilanData['resimUrl'] = resimUrller.first;
      ilanData['resimUrller'] = resimUrller;
    }
    final ref = await _col.add(ilanData);
    return ref.id;
  }

  Future<void> ilanGuncelle(String ilanId, Map<String, dynamic> data) =>
      _col.doc(ilanId).update(data);

  Future<void> ilanSil(String ilanId) => _col.doc(ilanId).delete();

  Future<void> ilanPasifYap(String ilanId) =>
      _col.doc(ilanId).update({'aktif': false});

  // ✅ Detay sayfası için real-time favori sayacı
  Stream<int> favoriSayisiStream(String ilanId) {
    return _col.doc(ilanId).snapshots().map((doc) =>
        ((doc.data() as Map<String, dynamic>?)?['favoriSayisi'] as num?)
            ?.toInt() ??
        0);
  }

  Stream<bool> favorideMi({
    required String kullaniciId,
    required String ilanId,
  }) {
    return firestore
        .collection(Collections.favoriler)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('ilanId', isEqualTo: ilanId)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }

  Future<void> favoriyeEkle({
    required String kullaniciId,
    required IlanModel ilan,
  }) async {
    final batch = firestore.batch();

    final favoriRef = firestore.collection(Collections.favoriler).doc();
    batch.set(favoriRef, {
      'kullaniciId': kullaniciId,
      'ilanId':      ilan.id,
      'tip':         ilan.tip,
      'kullaniciAd': ilan.kullaniciAd,
      'nereden':     ilan.nereden,
      'nereye':      ilan.nereye,
      'urun':        ilan.urun,
      'ucret':       ilan.ucret,
      'kategori':    ilan.kategori,
      if (ilan.resimUrl.isNotEmpty) 'resimUrl': ilan.resimUrl,
      'eklemeTarihi': FieldValue.serverTimestamp(),
    });

    final ilanRef = _col.doc(ilan.id);
    batch.update(ilanRef, {
      'favoriSayisi': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> favoridanCikar({
    required String kullaniciId,
    required String ilanId,
  }) async {
    final snap = await firestore
        .collection(Collections.favoriler)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('ilanId', isEqualTo: ilanId)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_col.doc(ilanId), {
      'favoriSayisi': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> favorilerStream(String kullaniciId) {
    return firestore
        .collection(Collections.favoriler)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .orderBy('eklemeTarihi', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}