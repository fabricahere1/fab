import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/mesaj_model.dart';
import '../../../shared/constants/app_constants.dart';

part 'mesaj_repository.g.dart';

String sohbetIdUret(String uid1, String uid2, String ilanId) {
  final ids = [uid1, uid2]..sort();
  return '${ids[0]}_${ids[1]}_$ilanId';
}

@riverpod
MesajRepository mesajRepository(Ref ref) {
  return MesajRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
}

class MesajRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  MesajRepository({required this.firestore, required this.storage});

  CollectionReference get _sohbetler =>
      firestore.collection(Collections.sohbetler);

  CollectionReference _mesajlar(String sohbetId) =>
      _sohbetler.doc(sohbetId).collection(Collections.mesajlar);

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<String> resimYukle({
    required File dosya,
    required String gondereId,
  }) async {
    final ref = storage
        .ref()
        .child(StoragePaths.mesajResimleri)
        .child('${gondereId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(dosya);
    return await ref.getDownloadURL();
  }

  Future<void> mesajGonder({
    required String sohbetId,
    required String gondereId,
    required String karsiId,
    required String ilanId,
    required String ilanBaslik,
    required String metin,
    String ilanResimUrl = '',
    String tip = 'mesaj',
    String? resimUrl,
    String ilanSahibiId = '',
    String ilanTip = 'istek',
  }) async {
    final sohbetRef = _sohbetler.doc(sohbetId);
    final mesajRef  = _mesajlar(sohbetId).doc();
    final batch     = firestore.batch();

    batch.set(sohbetRef, {
      'kullanicilar':         [gondereId, karsiId],
      'ilanId':               ilanId,
      'ilanBaslik':           ilanBaslik,
      'ilanResimUrl':         ilanResimUrl,
      'sonMesaj':             tip == 'resim' ? '📷 Fotoğraf' : metin,
      'sonMesajZamani':       FieldValue.serverTimestamp(),
      'sonGondereId':         gondereId,
      'ilanSahibiId':         ilanSahibiId,
      'ilanTip':              ilanTip,
      'degerlendirmeYapildi': false,
      'islemDurumlari':       {'iletisimBasladi': true},
      'olusturmaTarihi':      FieldValue.serverTimestamp(),
      'okunmamis':            {karsiId: FieldValue.increment(1)},
    }, SetOptions(merge: true));

    batch.set(mesajRef, {
      'metin':     metin,
      'gondereId': gondereId,
      'tip':       tip,
      'zaman':     FieldValue.serverTimestamp(),
      'okundu':    false,
      if (resimUrl != null) 'resimUrl': resimUrl,
    });

    await batch.commit();
  }

  Stream<List<SohbetModel>> sohbetlerStream(String kullaniciId) {
    return _sohbetler
        .where('kullanicilar', arrayContains: kullaniciId)
        .orderBy('sonMesajZamani', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SohbetModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<MesajModel>> mesajlarStream({
    required String sohbetId,
    int limit = Pagination.mesajSayfaBoyutu,
  }) {
    return _mesajlar(sohbetId)
        .orderBy('zaman', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MesajModel.fromFirestore(doc))
            .where((m) => m.zaman != null)
            .toList());
  }

  Future<List<MesajModel>> eskiMesajlariGetir({
    required String sohbetId,
    required DateTime sonZaman,
    int limit = Pagination.mesajSayfaBoyutu,
  }) async {
    final snap = await _mesajlar(sohbetId)
        .orderBy('zaman', descending: true)
        .startAfter([Timestamp.fromDate(sonZaman)])
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => MesajModel.fromFirestore(doc))
        .where((m) => m.zaman != null)
        .toList();
  }

  Future<void> okunduIsaretle({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    try {
      await _sohbetler.doc(sohbetId).update({
        'okunmamis.$kullaniciId': 0,
      });
      final mesajlar = await _mesajlar(sohbetId)
          .where('okundu', isEqualTo: false)
          .get();
      if (mesajlar.docs.isEmpty) return;
      final batch = firestore.batch();
      for (final doc in mesajlar.docs) {
        final data = doc.data() as Map<String, dynamic>;
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

  Future<void> islemDurumuGuncelle({
    required String sohbetId,
    required String durum,
  }) async {
    await _sohbetler.doc(sohbetId).update({
      'islemDurumlari.$durum': true,
    });
  }

  Future<void> teslimTamamla({required String sohbetId}) async {
    await _sohbetler.doc(sohbetId).update({
      'islemDurumlari.teslimAlindi': true,
    });
    await _sohbetler.doc(sohbetId).update({
      'degerlendirmeBekliyor': true,
    });
  }

  // ── Anlaşıldı — iki taraflı onay ─────────────────────────
  Future<void> anlasildiIsaretle({
    required String sohbetId,
    required String benimUid,
  }) async {
    await _sohbetler.doc(sohbetId).update({
      'islemDurumlari.anlasildi_$benimUid': true,
    });
  }

  Future<void> mesajBildirimiGonder({
    required String aliciId,
    required String gondereId,
    required String gondereAd,
    required String ilanBaslik,
    required String sohbetId,
    required String metin,
  }) async {
    try {
      await _functions.httpsCallable('mesajBildirimiGonder').call({
        'aliciId':    aliciId,
        'gondereAd':  gondereAd,
        'ilanBaslik': ilanBaslik,
        'sohbetId':   sohbetId,
        'metin':      metin,
      });
    } catch (_) {}
  }

  // ── Sohbet dökümanı stream'leri ──────────────────────────

  Stream<Map<String, dynamic>> sohbetDurumuStream(String sohbetId) {
    return _sohbetler.doc(sohbetId).snapshots().map((doc) {
      if (!doc.exists) return <String, dynamic>{};
      return Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>? ?? {});
    });
  }

  Stream<Map<String, dynamic>> islemDurumuStream(String sohbetId) {
    return _sohbetler.doc(sohbetId).snapshots().map((doc) {
      if (!doc.exists) return <String, dynamic>{};
      final d = doc.data() as Map<String, dynamic>;
      return Map<String, dynamic>.from(d['islemDurumlari'] ?? {});
    });
  }

  Stream<String> ilanSahibiIdStream(String sohbetId) {
    return _sohbetler.doc(sohbetId).snapshots().map((doc) {
      if (!doc.exists) return '';
      final d = doc.data() as Map<String, dynamic>;
      return d['ilanSahibiId'] as String? ?? '';
    });
  }

  Stream<String> ilanTipStream(String sohbetId) {
    return _sohbetler.doc(sohbetId).snapshots().map((doc) {
      if (!doc.exists) return 'istek';
      final d = doc.data() as Map<String, dynamic>;
      return d['ilanTip'] as String? ?? 'istek';
    });
  }

  Stream<List<String>> sohbetKullanicilarStream(String sohbetId) {
    return _sohbetler.doc(sohbetId).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final d = doc.data() as Map<String, dynamic>;
      return List<String>.from(d['kullanicilar'] ?? []);
    });
  }
}