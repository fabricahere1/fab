import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/ilan_model.dart';
import '../../../shared/constants/app_constants.dart';

part 'ilan_repository.g.dart';

// Pagination cursor — DocumentSnapshot yerine DateTime kullanılır
// Böylece data katmanı dışına Firestore tipi sızmaz
class IlanSayfasi {
  final List<IlanModel> ilanlar;
  final DateTime? sonTarih;   // startAfter cursor
  final String? sonId;        // tiebreaker
  final bool bitti;

  const IlanSayfasi({
    required this.ilanlar,
    required this.bitti,
    this.sonTarih,
    this.sonId,
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

  // ── Tekil ilan ────────────────────────────────────────────────────────────

  /// Bildirimden açılırken veya deep link ile sadece ilanId bilindiğinde kullanılır.
  Stream<IlanModel?> ilanStream(String ilanId) {
    return _col.doc(ilanId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return IlanModel.fromFirestore(doc);
    });
  }

  // ── Liste ─────────────────────────────────────────────────────────────────

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
    final ilanlar = snap.docs.map(IlanModel.fromFirestore).toList();
    return IlanSayfasi(
      ilanlar: ilanlar,
      sonTarih: ilanlar.isNotEmpty ? ilanlar.last.olusturmaTarihi : null,
      sonId: ilanlar.isNotEmpty ? ilanlar.last.id : null,
      bitti: snap.docs.length < limit,
    );
  }

  Future<IlanSayfasi> tasiyiciIlanlariniGetir({
    bool tariheGore = true,
    int limit = Pagination.ilanSayfaBoyutu,
  }) async {
    if (tariheGore) {
      final bugun = DateTime.now();
      final bugunTimestamp = Timestamp.fromDate(
        DateTime(bugun.year, bugun.month, bugun.day),
      );
      final gelecek = await _col
          .where('tip', isEqualTo: IlanTip.tasiyici)
          .where('aktif', isEqualTo: true)
          .where('tarih', isGreaterThanOrEqualTo: bugunTimestamp)
          .orderBy('tarih', descending: false)
          .limit(limit)
          .get();
      final gecmis = await _col
          .where('tip', isEqualTo: IlanTip.tasiyici)
          .where('aktif', isEqualTo: true)
          .where('tarih', isLessThan: bugunTimestamp)
          .orderBy('tarih', descending: true)
          .limit(10)
          .get();
      final ilanlar = [
        ...gelecek.docs.map(IlanModel.fromFirestore),
        ...gecmis.docs.map(IlanModel.fromFirestore),
      ];
      return IlanSayfasi(
        ilanlar: ilanlar,
        sonTarih: ilanlar.isNotEmpty ? ilanlar.last.tarih : null,
        sonId: ilanlar.isNotEmpty ? ilanlar.last.id : null,
        bitti: gelecek.docs.length < limit,
      );
    }
    final snap = await _col
        .where('tip', isEqualTo: IlanTip.tasiyici)
        .where('aktif', isEqualTo: true)
        .orderBy('olusturmaTarihi', descending: true)
        .limit(limit)
        .get();
    final ilanlar = snap.docs.map(IlanModel.fromFirestore).toList();
    return IlanSayfasi(
      ilanlar: ilanlar,
      sonTarih: ilanlar.isNotEmpty ? ilanlar.last.olusturmaTarihi : null,
      sonId: ilanlar.isNotEmpty ? ilanlar.last.id : null,
      bitti: snap.docs.length < limit,
    );
  }

  // DocumentSnapshot yerine DateTime cursor kullanır
  Future<IlanSayfasi> sonrakiSayfayiGetir({
    required String tip,
    required DateTime sonTarih,
    required String siralama,
    int limit = Pagination.ilanSayfaBoyutu,
  }) async {
    final orderField = (tip == IlanTip.tasiyici && siralama == 'tarih')
        ? 'tarih'
        : 'olusturmaTarihi';
    final cursor = Timestamp.fromDate(sonTarih);
    final snap = await _col
        .where('tip', isEqualTo: tip)
        .where('aktif', isEqualTo: true)
        .orderBy(orderField, descending: orderField == 'olusturmaTarihi')
        .startAfter([cursor])
        .limit(limit)
        .get();
    final ilanlar = snap.docs.map(IlanModel.fromFirestore).toList();
    return IlanSayfasi(
      ilanlar: ilanlar,
      sonTarih: ilanlar.isNotEmpty ? ilanlar.last.olusturmaTarihi : sonTarih,
      sonId: ilanlar.isNotEmpty ? ilanlar.last.id : null,
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
    final mevcutSnap = await firestore
        .collection(Collections.favoriler)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('ilanId', isEqualTo: ilan.id)
        .get();
    if (mevcutSnap.docs.isNotEmpty) return;

    final batch = firestore.batch();
    final favoriRef = firestore.collection(Collections.favoriler).doc();
    batch.set(favoriRef, {
      'kullaniciId':  kullaniciId,
      'ilanId':       ilan.id,
      'tip':          ilan.tip,
      'kullaniciAd':  ilan.kullaniciAd,
      'nereden':      ilan.nereden,
      'nereye':       ilan.nereye,
      'urun':         ilan.urun,
      'ucret':        ilan.ucret,
      'kategori':     ilan.kategori,
      if (ilan.resimUrl.isNotEmpty) 'resimUrl': ilan.resimUrl,
      'eklemeTarihi': FieldValue.serverTimestamp(),
    });
    batch.update(_col.doc(ilan.id), {
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
