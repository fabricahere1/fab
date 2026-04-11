// lib/features/teklifler/data/teklif_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/teklif_model.dart';
import '../../bildirimler/data/bildirim_repository.dart';
import '../../bildirimler/domain/bildirim_model.dart';
import '../../../shared/constants/app_constants.dart';

part 'teklif_repository.g.dart';

@riverpod
TeklifRepository teklifRepository(Ref ref) {
  return TeklifRepository(
    firestore: FirebaseFirestore.instance,
    bildirimRepo: ref.read(bildirimRepositoryProvider),
  );
}

class TeklifRepository {
  final FirebaseFirestore firestore;
  final BildirimRepository bildirimRepo;

  TeklifRepository({required this.firestore, required this.bildirimRepo});

  CollectionReference get _col => firestore.collection(Collections.teklifler);

  Future<void> teklifVer({
    required String ilanId,
    required String ilanBaslik,
    required String ilanSahibiId,
    required String ilanSahibiAd,
    required String teklifVerenId,
    required String teklifVerenAd,
    required double miktar,
    required double ilanMiktar,
  }) async {
    final mevcutSnap = await _col
        .where('ilanId', isEqualTo: ilanId)
        .where('teklifVerenId', isEqualTo: teklifVerenId)
        .where('durum', isEqualTo: TeklifDurum.bekliyor.firestoreKey)
        .get();

    String teklifId;
    if (mevcutSnap.docs.isNotEmpty) {
      teklifId = mevcutSnap.docs.first.id;
      await _col.doc(teklifId).update({
        'miktar': miktar,
        'guncellemeTarihi': FieldValue.serverTimestamp(),
      });
    } else {
      final docRef = await _col.add({
        'ilanId': ilanId,
        'ilanBaslik': ilanBaslik,
        'ilanSahibiId': ilanSahibiId,
        'ilanSahibiAd': ilanSahibiAd,
        'teklifVerenId': teklifVerenId,
        'teklifVerenAd': teklifVerenAd,
        'miktar': miktar,
        'ilanMiktar': ilanMiktar,
        'durum': TeklifDurum.bekliyor.firestoreKey,
        'karsiTeklifMiktar': null,
        'olusturmaTarihi': FieldValue.serverTimestamp(),
        'guncellemeTarihi': FieldValue.serverTimestamp(),
      });
      teklifId = docRef.id;
    }

    await bildirimRepo.bildirimOlustur(
      kullaniciId: ilanSahibiId,
      tip: BildirimTip.teklif,
      baslik: teklifVerenAd,
      icerik: '"$ilanBaslik" ilanına ${miktar.toStringAsFixed(0)} ₺ teklif verdi',
      hedefId: teklifId,
      gondereId: teklifVerenId,
      gondereAd: teklifVerenAd,
    );
  }

  Future<void> teklifKabul({
    required TeklifModel teklif,
    required String kabulEdenId,
    required String kabulEdenAd,
  }) async {
    await _col.doc(teklif.id).update({
      'durum': TeklifDurum.kabul.firestoreKey,
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    final bildirimHedefi = kabulEdenId == teklif.ilanSahibiId
        ? teklif.teklifVerenId
        : teklif.ilanSahibiId;

    await bildirimRepo.bildirimOlustur(
      kullaniciId: bildirimHedefi,
      tip: BildirimTip.teklif,
      baslik: kabulEdenAd,
      icerik: '🤝 "${teklif.ilanBaslik}" için anlaşma sağlandı!',
      hedefId: teklif.id,
      gondereId: kabulEdenId,
      gondereAd: kabulEdenAd,
    );

    final digerler = await _col
        .where('ilanId', isEqualTo: teklif.ilanId)
        .where('durum', isEqualTo: TeklifDurum.bekliyor.firestoreKey)
        .get();

    final batch = firestore.batch();
    for (final doc in digerler.docs) {
      if (doc.id != teklif.id) {
        batch.update(doc.reference, {
          'durum': TeklifDurum.reddedildi.firestoreKey,
          'guncellemeTarihi': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> teklifReddet({required TeklifModel teklif}) async {
    await _col.doc(teklif.id).update({
      'durum': TeklifDurum.reddedildi.firestoreKey,
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    await bildirimRepo.bildirimOlustur(
      kullaniciId: teklif.teklifVerenId,
      tip: BildirimTip.teklif,
      baslik: teklif.ilanSahibiAd,
      icerik: '"${teklif.ilanBaslik}" için teklifiniz reddedildi.',
      hedefId: teklif.id,
      gondereId: teklif.ilanSahibiId,
      gondereAd: teklif.ilanSahibiAd,
    );
  }

  Future<void> karsiTeklifVer({
    required TeklifModel teklif,
    required double karsiMiktar,
  }) async {
    await _col.doc(teklif.id).update({
      'durum': TeklifDurum.karsiTeklif.firestoreKey,
      'karsiTeklifMiktar': karsiMiktar,
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    await bildirimRepo.bildirimOlustur(
      kullaniciId: teklif.teklifVerenId,
      tip: BildirimTip.teklif,
      baslik: teklif.ilanSahibiAd,
      icerik: '"${teklif.ilanBaslik}" için karşı teklif: ${karsiMiktar.toStringAsFixed(0)} ₺',
      hedefId: teklif.id,
      gondereId: teklif.ilanSahibiId,
      gondereAd: teklif.ilanSahibiAd,
    );
  }

  Stream<TeklifModel?> teklifDetayStream(String teklifId) {
    return _col.doc(teklifId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TeklifModel.fromFirestore(doc);
    });
  }

  Stream<List<TeklifModel>> ilanaTekliflerStream(String ilanId) {
    return _col
        .where('ilanId', isEqualTo: ilanId)
        .where('durum', isEqualTo: TeklifDurum.bekliyor.firestoreKey)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TeklifModel.fromFirestore).toList());
  }

  // ✅ Düzeltildi: hem ilanId hem teklifVerenId kontrolü
  Stream<TeklifModel?> ilanKabulTeklifleriStream(String ilanId, String teklifVerenId) {
    return _col
        .where('ilanId', isEqualTo: ilanId)
        .where('teklifVerenId', isEqualTo: teklifVerenId)
        .where('durum', isEqualTo: TeklifDurum.kabul.firestoreKey)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : TeklifModel.fromFirestore(s.docs.first));
  }

  Stream<_TeklifOzet> ilanTeklifOzetStream(String ilanId) {
    return _col
        .where('ilanId', isEqualTo: ilanId)
        .where('durum', isEqualTo: TeklifDurum.bekliyor.firestoreKey)
        .snapshots()
        .map((s) {
      final teklifler = s.docs.map(TeklifModel.fromFirestore).toList();
      if (teklifler.isEmpty) return const _TeklifOzet(sayi: 0, enYuksek: null);
      final enYuksek = teklifler.map((t) => t.miktar).reduce((a, b) => a > b ? a : b);
      return _TeklifOzet(sayi: teklifler.length, enYuksek: enYuksek);
    });
  }

  Stream<List<TeklifModel>> benirnTekliflerimStream(String kullaniciId) {
    return _col
        .where('teklifVerenId', isEqualTo: kullaniciId)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TeklifModel.fromFirestore).toList());
  }
}

class _TeklifOzet {
  final int sayi;
  final double? enYuksek;
  const _TeklifOzet({required this.sayi, required this.enYuksek});
}