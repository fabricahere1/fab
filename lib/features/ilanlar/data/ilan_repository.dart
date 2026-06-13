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

class IlanSayfasi {
  final List<IlanModel> ilanlar;
  final DateTime? sonTarih;
  final String? sonId;
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

  Stream<IlanModel?> ilanStream(String ilanId) {
    return _col.doc(ilanId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return IlanModel.fromFirestore(doc);
    });
  }

  Future<IlanSayfasi> istekIlanlariniGetir({
    String? kategori,
    int limit = Pagination.ilanSayfaBoyutu,
    bool forceServer = false,
  }) async {
    Query q = _col
        .where('tip', isEqualTo: IlanTip.istek)
        .where('aktif', isEqualTo: true)
        .orderBy('olusturmaTarihi', descending: true)
        .limit(limit);
    if (kategori != null) q = q.where('kategori', isEqualTo: kategori);

    QuerySnapshot snap;
    if (forceServer) {
      snap = await q.get(const GetOptions(source: Source.server));
    } else {
      try {
        snap = await q.get(const GetOptions(source: Source.cache));
        if (snap.docs.isEmpty) {
          snap = await q.get(const GetOptions(source: Source.server));
        }
      } catch (_) {
        snap = await q.get(const GetOptions(source: Source.server));
      }
    }

    final ilanlar = snap.docs.map(IlanModel.fromFirestore).toList();
    return IlanSayfasi(
      ilanlar: ilanlar,
      sonTarih: ilanlar.isNotEmpty ? ilanlar.last.olusturmaTarihi : null,
      sonId: ilanlar.isNotEmpty ? ilanlar.last.id : null,
      bitti: snap.docs.length < limit,
    );
  }

  Future<IlanSayfasi> istekIlanlariniGetirSunucu({
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
    bool forceServer = false,
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

      QuerySnapshot gelecek;
      QuerySnapshot gecmis;
      if (forceServer) {
        gelecek = await gelecekQ.get(const GetOptions(source: Source.server));
        gecmis  = await gecmisQ.get(const GetOptions(source: Source.server));
      } else {
        try {
          gelecek = await gelecekQ.get(const GetOptions(source: Source.cache));
          gecmis  = await gecmisQ.get(const GetOptions(source: Source.cache));
          if (gelecek.docs.isEmpty && gecmis.docs.isEmpty) {
            gelecek = await gelecekQ.get(const GetOptions(source: Source.server));
            gecmis  = await gecmisQ.get(const GetOptions(source: Source.server));
          }
        } catch (_) {
          gelecek = await gelecekQ.get(const GetOptions(source: Source.server));
          gecmis  = await gecmisQ.get(const GetOptions(source: Source.server));
        }
      }

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

    QuerySnapshot snap;
    if (forceServer) {
      snap = await q.get(const GetOptions(source: Source.server));
    } else {
      try {
        snap = await q.get(const GetOptions(source: Source.cache));
        if (snap.docs.isEmpty) {
          snap = await q.get(const GetOptions(source: Source.server));
        }
      } catch (_) {
        snap = await q.get(const GetOptions(source: Source.server));
      }
    }

    final ilanlar = snap.docs.map(IlanModel.fromFirestore).toList();
    return IlanSayfasi(
      ilanlar: ilanlar,
      sonTarih: ilanlar.isNotEmpty ? ilanlar.last.olusturmaTarihi : null,
      sonId: ilanlar.isNotEmpty ? ilanlar.last.id : null,
      bitti: snap.docs.length < limit,
    );
  }

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

  /// Full resim: max 1080px, %75 kalite → 100-300 KB
  Future<File> _resimSikistir(File dosya, int index) async {
    final tempDir = await getTemporaryDirectory();
    final hedefYol =
        '${tempDir.path}/ilan_compressed_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
    final sonuc = await FlutterImageCompress.compressAndGetFile(
      dosya.absolute.path,
      hedefYol,
      quality: 75,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );
    return sonuc != null ? File(sonuc.path) : dosya;
  }

  /// Thumbnail: max 300px, %65 kalite → 10-25 KB
  Future<File> _thumbnailOlustur(File dosya) async {
    final tempDir = await getTemporaryDirectory();
    final hedefYol =
        '${tempDir.path}/ilan_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final sonuc = await FlutterImageCompress.compressAndGetFile(
      dosya.absolute.path,
      hedefYol,
      quality: 65,
      minWidth: 300,
      minHeight: 300,
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

    final ts = DateTime.now().millisecondsSinceEpoch;
    final List<Reference> yuklenenRefler = [];
    String thumbUrl = '';
    Reference? thumbRef;

    try {
      // ── 1. Tüm resimleri paralel sıkıştır ───────────────────────────────
      final sikistirilmisler = await Future.wait(
        List.generate(resimler.length, (i) => _resimSikistir(resimler[i], i)),
      );

      // ── 2. Tüm resimleri paralel yükle ──────────────────────────────────
      final refs = List.generate(resimler.length, (i) => storage
          .ref()
          .child(StoragePaths.ilanResimleri)
          .child('${user.uid}_${ts}_$i.jpg'));

      // Progress takibi için her resim için ayrı progress tutuyoruz
      final progresses = List<double>.filled(resimler.length, 0.0);

      final uploadFutures = List.generate(resimler.length, (i) async {
        onProgress?.call(i, 0.0);
        final task = refs[i].putFile(sikistirilmisler[i]);
        task.snapshotEvents.listen((snap) {
          progresses[i] = snap.bytesTransferred / snap.totalBytes;
          // Toplam progress ortalamasını bildir
          final toplamProgress =
              progresses.reduce((a, b) => a + b) / progresses.length;
          onProgress?.call(i, toplamProgress);
        });
        await task;
        yuklenenRefler.add(refs[i]);
      });

      // ── 3. Thumbnail paralel başlat (ilk resim için) ─────────────────────
      Future<void>? thumbFuture;
      if (resimler.isNotEmpty) {
        thumbFuture = () async {
          final thumb = await _thumbnailOlustur(resimler[0]);
          thumbRef = storage
              .ref()
              .child(StoragePaths.ilanThumbnailleri)
              .child('${user.uid}_${ts}_thumb.jpg');
          await thumbRef!.putFile(thumb);
          thumbUrl = await thumbRef!.getDownloadURL();
        }();
      }

      // ── 4. Tüm yüklemeleri bekle ─────────────────────────────────────────
      await Future.wait([
        ...uploadFutures,
        ?thumbFuture,
      ]);

      // ── 5. Download URL'leri paralel al ──────────────────────────────────
      final resimUrller = await Future.wait(
        refs.map((ref) => ref.getDownloadURL()),
      );

      // ── 6. Kullanıcı puanını çek ─────────────────────────────────────────
      final kullaniciDoc = await firestore
          .collection(Collections.kullanicilar)
          .doc(user.uid)
          .get();
      final kullaniciPuan =
          (kullaniciDoc.data()?['ortalamaPuan'] as num?)?.toDouble() ?? 0.0;

      // ── 7. Firestore'a kaydet ─────────────────────────────────────────────
      final ilanData =
          ilan.copyWith(kullaniciPuan: kullaniciPuan).toFirestore();
      if (resimUrller.isNotEmpty) {
        ilanData['resimUrl'] = resimUrller.first;
        ilanData['resimUrller'] = resimUrller;
        if (thumbUrl.isNotEmpty) ilanData['resimThumbUrl'] = thumbUrl;
      }

      final ref = await _col.add(ilanData);
      return ref.id;
    } catch (e) {
      // Upload yarıda kestiyse yüklenmiş dosyaları temizle
      for (final ref in yuklenenRefler) {
        await ref.delete().catchError((_) {});
      }
      if (thumbRef != null) {
        await thumbRef!.delete().catchError((_) {});
      }
      rethrow;
    }
  }

  Future<void> ilanGuncelle(String ilanId, Map<String, dynamic> data) =>
      _col.doc(ilanId).update(data);

  /// İlanı (gerekiyorsa yeni resimlerle) günceller.
  /// [mevcutResimler] korunan eski URL'ler, [yeniResimler] eklenen yerel dosyalar.
  /// Sıkıştırıp yükler, `resimUrl`/`resimUrller` alanlarını yeniden kurar.
  /// Resimler değiştiğinde sunucudaki `ilanGuncellemeModerasyon` Vision ile tekrar denetler.
  Future<void> ilanResimliGuncelle({
    required String ilanId,
    required Map<String, dynamic> data,
    List<File> yeniResimler = const [],
    List<String> mevcutResimler = const [],
    void Function(int index, double progress)? onProgress,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Giriş yapılmamış');

    final ts = DateTime.now().millisecondsSinceEpoch;
    final List<String> yeniUrller = [];
    String? yeniThumbUrl;

    if (yeniResimler.isNotEmpty) {
      // Paralel sıkıştır + yükle
      final sikistirilmisler = await Future.wait(
        List.generate(yeniResimler.length, (i) => _resimSikistir(yeniResimler[i], i)),
      );
      final refs = List.generate(
        yeniResimler.length,
        (i) => storage
            .ref()
            .child(StoragePaths.ilanResimleri)
            .child('${user.uid}_${ts}_d$i.jpg'),
      );
      final progresses = List<double>.filled(yeniResimler.length, 0.0);
      await Future.wait(List.generate(yeniResimler.length, (i) async {
        onProgress?.call(i, 0.0);
        final task = refs[i].putFile(sikistirilmisler[i]);
        task.snapshotEvents.listen((snap) {
          progresses[i] = snap.bytesTransferred / snap.totalBytes;
          onProgress?.call(
              i, progresses.reduce((a, b) => a + b) / progresses.length);
        });
        await task;
      }));
      yeniUrller.addAll(await Future.wait(refs.map((r) => r.getDownloadURL())));

      // İlk resim yeni (yerel) bir dosyaysa thumbnail üret
      if (mevcutResimler.isEmpty) {
        final thumb = await _thumbnailOlustur(yeniResimler.first);
        final thumbRef = storage
            .ref()
            .child(StoragePaths.ilanThumbnailleri)
            .child('${user.uid}_${ts}_thumb.jpg');
        await thumbRef.putFile(thumb);
        yeniThumbUrl = await thumbRef.getDownloadURL();
      }
    }

    final tumResimler = [...mevcutResimler, ...yeniUrller];
    if (tumResimler.isNotEmpty) {
      data['resimUrl'] = tumResimler.first;
      data['resimUrller'] = tumResimler;
      if (yeniThumbUrl != null) data['resimThumbUrl'] = yeniThumbUrl;
    }

    await _col.doc(ilanId).update(data);
  }

  Future<void> ilanSil(String ilanId) async {
    // Sadece ilanın kendi dokümanını sil — sahibi için kurallarca her zaman izinli.
    // İlişkili favoriler/goruntulenmeler temizliği sunucudaki `ilanSilindi`
    // (onDelete) Cloud Function'ında yapılır; çünkü diğer kullanıcıların favori
    // kayıtlarını client'tan `where ilanId==` ile sorgulamak güvenlik
    // kurallarınca reddedilir ve tüm silme işlemini patlatır.
    await _col.doc(ilanId).delete();
  }

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
    final favoriId = '${kullaniciId}_${ilan.id}';
    final favoriRef = firestore.collection(Collections.favoriler).doc(favoriId);

    await firestore.runTransaction((txn) async {
      final favoriSnap = await txn.get(favoriRef);
      if (favoriSnap.exists) return;

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
    final favoriId = '${kullaniciId}_$ilanId';
    final favoriRef = firestore.collection(Collections.favoriler).doc(favoriId);
    await firestore.runTransaction((txn) async {
      final snap = await txn.get(favoriRef);
      if (!snap.exists) return;
      txn.delete(favoriRef);
      txn.update(_col.doc(ilanId), {
        'favoriSayisi': FieldValue.increment(-1),
      });
    });
  }

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