import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
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

    final snap = await q.get(const GetOptions(source: Source.server));

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
      final gelecekQ = _col
          .where('tip', isEqualTo: IlanTip.tasiyici)
          .where('aktif', isEqualTo: true)
          .where('tarih', isGreaterThanOrEqualTo: bugunTimestamp)
          .orderBy('tarih', descending: false)
          .limit(limit);
      final gecmisQ = _col
          .where('tip', isEqualTo: IlanTip.tasiyici)
          .where('aktif', isEqualTo: true)
          .where('tarih', isLessThan: bugunTimestamp)
          .orderBy('tarih', descending: true)
          .limit(10);

      final gelecek = await gelecekQ.get(const GetOptions(source: Source.server));
      final gecmis  = await gecmisQ.get(const GetOptions(source: Source.server));

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
    final q = _col
        .where('tip', isEqualTo: IlanTip.tasiyici)
        .where('aktif', isEqualTo: true)
        .orderBy('olusturmaTarihi', descending: true)
        .limit(limit);

    final snap = await q.get(const GetOptions(source: Source.server));

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
      // orderField ile cursor alanı eşleşmeli
      sonTarih: ilanlar.isNotEmpty
          ? (orderField == 'tarih'
              ? ilanlar.last.tarih
              : ilanlar.last.olusturmaTarihi)
          : sonTarih,
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

  /// Resmi yüklemeden önce sıkıştırır.
  /// Çıktı: max 1200px, %85 kalite → genellikle 200-500 KB arası
  Future<File> _resimSikistir(File dosya, int index) async {
    final tempDir = await getTemporaryDirectory();
    final hedefYol =
        '${tempDir.path}/ilan_compressed_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
    final sonuc = await FlutterImageCompress.compressAndGetFile(
      dosya.absolute.path,
      hedefYol,
      quality: 85,
      minWidth: 1200,
      minHeight: 1200,
      format: CompressFormat.jpeg,
    );
    return sonuc != null ? File(sonuc.path) : dosya;
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
      // Yüklemeden önce sıkıştır
      final sikistirilmis = await _resimSikistir(resimler[i], i);
      final ref = storage
          .ref()
          .child(StoragePaths.ilanResimleri)
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      final task = ref.putFile(sikistirilmis);
      task.snapshotEvents.listen((snap) {
        onProgress?.call(i, snap.bytesTransferred / snap.totalBytes);
      });
      await task;
      resimUrller.add(await ref.getDownloadURL());
    }
    // Kullanıcının güncel puanını çek
    final kullaniciDoc = await firestore
        .collection(Collections.kullanicilar)
        .doc(user.uid)
        .get();
    final kullaniciPuan = (kullaniciDoc.data()?['ortalamaPuan'] as num?)?.toDouble() ?? 0.0;

    final ilanData = ilan.copyWith(kullaniciPuan: kullaniciPuan).toFirestore();
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
    // Deterministik ID — race condition'ı önler
    // Aynı kullanıcı aynı ilanı iki kez favorilerse ikinci yazma birincinin üzerine yazar
    final favoriId = '${kullaniciId}_${ilan.id}';
    final favoriRef = firestore.collection(Collections.favoriler).doc(favoriId);

    await firestore.runTransaction((txn) async {
      final favoriSnap = await txn.get(favoriRef);
      if (favoriSnap.exists) return; // Zaten favoride

      txn.set(favoriRef, {
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
      txn.update(_col.doc(ilan.id), {
        'favoriSayisi': FieldValue.increment(1),
      });
    });
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

  /// 12 saatlik throttle ile görüntülenme sayısını artırır.
  /// favoriler koleksiyonuyla aynı pattern: üst seviye koleksiyon + deterministik ID.
  Future<bool> goruntulenmeyiKaydet({
    required String kullaniciId,
    required String ilanId,
  }) async {
    final kayitRef = firestore
        .collection(Collections.goruntulenmeler)
        .doc('${kullaniciId}_$ilanId');

    bool sayildi = false;
    await firestore.runTransaction((txn) async {
      final snap = await txn.get(kayitRef);
      final simdi = DateTime.now();

      if (snap.exists) {
        final sonTarih = (snap.data()!['sonTarih'] as Timestamp).toDate();
        if (simdi.difference(sonTarih).inHours < 12) return;
      }

      txn.set(kayitRef, {
        'kullaniciId': kullaniciId,
        'ilanId':      ilanId,
        'sonTarih':    Timestamp.fromDate(simdi),
      });
      txn.update(_col.doc(ilanId), {
        'goruntulenmeSayisi': FieldValue.increment(1),
      });
      sayildi = true;
    });
    return sayildi;
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