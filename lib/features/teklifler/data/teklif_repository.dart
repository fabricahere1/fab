// lib/features/teklifler/data/teklif_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/teklif_model.dart';
import '../../bildirimler/data/bildirim_repository.dart';
import '../../bildirimler/domain/bildirim_model.dart';
import '../../mesajlar/data/mesaj_repository.dart';
import '../../../shared/constants/app_constants.dart';

part 'teklif_repository.g.dart';

@riverpod
TeklifRepository teklifRepository(Ref ref) {
  return TeklifRepository(
    firestore: FirebaseFirestore.instance,
    bildirimRepo: ref.read(bildirimRepositoryProvider),
    mesajRepo: ref.read(mesajRepositoryProvider),
  );
}

class TeklifRepository {
  final FirebaseFirestore firestore;
  final BildirimRepository bildirimRepo;
  final MesajRepository mesajRepo;

  TeklifRepository({
    required this.firestore,
    required this.bildirimRepo,
    required this.mesajRepo,
  });

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

    // Kabul anında sohbete otomatik sistem mesajı at — chat boş açılmasın
    final sohbetId = sohbetIdUret(
      teklif.ilanSahibiId,
      teklif.teklifVerenId,
      teklif.ilanId,
    );
    await mesajRepo.mesajGonder(
      sohbetId:    sohbetId,
      gondereId:   kabulEdenId,
      karsiId:     bildirimHedefi,
      ilanId:      teklif.ilanId,
      ilanBaslik:  teklif.ilanBaslik,
      ilanResimUrl: '',
      metin:       '🤝 Anlaşma sağlandı! ${teklif.miktar.toStringAsFixed(0)} ₺ üzerinden uzlaştınız.',
      tip:         'sistem',
    );

    // Bekliyor ve karşıTeklif durumundaki diğer tüm teklifleri reddet
    final bekleyenler = await _col
        .where('ilanId', isEqualTo: teklif.ilanId)
        .where('durum', isEqualTo: TeklifDurum.bekliyor.firestoreKey)
        .get();
    final karsiTeklifler = await _col
        .where('ilanId', isEqualTo: teklif.ilanId)
        .where('durum', isEqualTo: TeklifDurum.karsiTeklif.firestoreKey)
        .get();

    final batch = firestore.batch();
    for (final doc in [...bekleyenler.docs, ...karsiTeklifler.docs]) {
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
      return _teklifModelCevir(doc);
    });
  }

  Stream<List<TeklifModel>> ilanaTekliflerStream(String ilanId) {
    return _col
        .where('ilanId', isEqualTo: ilanId)
        .where('durum', isEqualTo: TeklifDurum.bekliyor.firestoreKey)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => _teklifModelCevir(doc)).toList());
  }

  // ✅ Düzeltildi: hem ilanId hem teklifVerenId kontrolü
  Stream<TeklifModel?> ilanKabulTeklifleriStream(String ilanId, String teklifVerenId) {
    return _col
        .where('ilanId', isEqualTo: ilanId)
        .where('teklifVerenId', isEqualTo: teklifVerenId)
        .where('durum', isEqualTo: TeklifDurum.kabul.firestoreKey)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : _teklifModelCevir(s.docs.first));
  }

  Stream<TeklifOzet> ilanTeklifOzetStream(String ilanId) {
    return _col
        .where('ilanId', isEqualTo: ilanId)
        .where('durum', isEqualTo: TeklifDurum.bekliyor.firestoreKey)
        .snapshots()
        .map((s) {
      final teklifler = s.docs.map((doc) => _teklifModelCevir(doc)).toList();
      if (teklifler.isEmpty) return const TeklifOzet(sayi: 0, enYuksek: null);
      final enYuksek = teklifler.map((t) => t.miktar).reduce((a, b) => a > b ? a : b);
      return TeklifOzet(sayi: teklifler.length, enYuksek: enYuksek);
    });
  }

  Stream<List<TeklifModel>> benimTekliflerimStream(String kullaniciId) {
    return _col
        .where('teklifVerenId', isEqualTo: kullaniciId)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => _teklifModelCevir(doc)).toList());
  }

  Stream<List<TeklifModel>> ilanSahibiTeklifleriStream(String kullaniciId) {
    return _col
        .where('ilanSahibiId', isEqualTo: kullaniciId)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => _teklifModelCevir(doc)).toList());
  }

  // ── Teslim metodları ─────────────────────────────────────────────────────────
  Future<void> eldenTeslimBeyan({required String teklifId}) async {
    await _col.doc(teklifId).update({
      'getirenTeslimBeyan': 'teslim_etti',
      'teslimatTipi':       'elden',
      'getirenTeslimTarihi': FieldValue.serverTimestamp(),
    });
  }

  Future<void> henuzDegilBeyan({required String teklifId}) async {
    await _col.doc(teklifId).update({
      'getirenTeslimBeyan': 'henuz_degil',
    });
  }

  // ── Kargo teslim ─────────────────────────────────────────────────────────────
  Future<void> kargoVerildiBeyan({
    required String teklifId,
    required String kargoSirketi,
    required String kargoTakipNo,
  }) async {
    await _col.doc(teklifId).update({
      'getirenTeslimBeyan': 'teslim_etti',
      'teslimatTipi':       'kargo',
      'kargoSirketi':        kargoSirketi,
      'kargoTakipNo':        kargoTakipNo,
      'getirenTeslimTarihi': FieldValue.serverTimestamp(),
    });
  }

  // ── İsteyen onay ─────────────────────────────────────────────────────────────
  Future<void> isteyenTeslimAldi({required String teklifId}) async {
    final simdi = DateTime.now();
    await _col.doc(teklifId).update({
      'isteyenTeslimOnay': 'aldi',
      'teslimDurumu':      'teslim_edildi',
      'teslimOnayTarihi':  FieldValue.serverTimestamp(),
      // Değerlendirme hemen açılır, 24 saat içinde yapılmalı
      'degerlendirmeAcilmaTarihi': Timestamp.fromDate(simdi),
      'degerlendirmeSonTarihi':    Timestamp.fromDate(
        simdi.add(const Duration(hours: 24)),
      ),
    });
  }

  Future<void> isteyenTeslimAlmadi({required String teklifId}) async {
    await _col.doc(teklifId).update({
      'isteyenTeslimOnay': 'almadi',
    });
  }

  // ── Değerlendirme ─────────────────────────────────────────────────────────────
  Future<void> isteyenDegerlendirdi({required String teklifId}) async {
    await _col.doc(teklifId).update({
      'isteyenDegerlendirdiMi': true,
    });
  }

  Future<void> getirenDegerlendirdi({required String teklifId}) async {
    await _col.doc(teklifId).update({
      'getirenDegerlendirdiMi': true,
    });
  }

  // ── Değerlendirme — puan kaydet ───────────────────────────────────────────────
  Future<void> puanEkle({
    required String hedefUid,
    required double puan,
  }) async {
    // Firestore transaction ile ortalama puan güncelle
    final kullaniciRef = firestore.collection('kullanicilar').doc(hedefUid);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(kullaniciRef);
      final eskiPuan   = (snap.data()?['ortalamaPuan']      as num?)?.toDouble() ?? 0.0;
      final eskiSayi   = (snap.data()?['degerlendirmeSayisi'] as num?)?.toInt()   ?? 0;
      final yeniSayi   = eskiSayi + 1;
      final yeniOrtalama = ((eskiPuan * eskiSayi) + puan) / yeniSayi;
      tx.update(kullaniciRef, {
        'ortalamaPuan':        yeniOrtalama,
        'degerlendirmeSayisi': yeniSayi,
      });
    });
  }

  Future<void> isteyenDegerlendirdiKaydet({
    required String teklifId,
    required String getirenUid,
    required double puan,
  }) async {
    await _col.doc(teklifId).update({'isteyenDegerlendirdiMi': true});
    await puanEkle(hedefUid: getirenUid, puan: puan);
  }

  Future<void> getirenDegerlendirdiKaydet({
    required String teklifId,
    required String isteyenUid,
    required double puan,
  }) async {
    await _col.doc(teklifId).update({'getirenDegerlendirdiMi': true});
    await puanEkle(hedefUid: isteyenUid, puan: puan);
  }

  // Timestamp → DateTime dönüşümü data katmanında yapılır — domain Firebase'i tanımaz
  TeklifModel _teklifModelCevir(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeklifModel(
      id:               doc.id,
      ilanId:           d['ilanId']            as String? ?? '',
      ilanBaslik:       d['ilanBaslik']         as String? ?? '',
      ilanSahibiId:     d['ilanSahibiId']       as String? ?? '',
      ilanSahibiAd:     d['ilanSahibiAd']       as String? ?? '',
      teklifVerenId:    d['teklifVerenId']      as String? ?? '',
      teklifVerenAd:    d['teklifVerenAd']      as String? ?? '',
      miktar:           (d['miktar']            as num?)?.toDouble() ?? 0,
      ilanMiktar:       (d['ilanMiktar']        as num?)?.toDouble() ?? 0,
      durum:            TeklifDurumX.fromString(d['durum'] as String? ?? ''),
      karsiTeklifMiktar:(d['karsiTeklifMiktar'] as num?)?.toDouble(),
      olusturmaTarihi:  (d['olusturmaTarihi']   as Timestamp?)?.toDate(),
      guncellemeTarihi: (d['guncellemeTarihi']  as Timestamp?)?.toDate(),
      olusumTipi:       d['olusumTipi']         as String? ?? OlusumTipi.teklif,
      teslimDurumu:        d['teslimDurumu']        as String? ?? 'beklemede',
      teslimatTipi:        d['teslimatTipi']         as String? ?? 'beklemede',
      getirenTeslimBeyan:  d['getirenTeslimBeyan']   as String? ?? 'yok',
      isteyenTeslimOnay:   d['isteyenTeslimOnay']    as String? ?? 'yok',
      kargoSirketi:        d['kargoSirketi']          as String? ?? '',
      kargoTakipNo:        d['kargoTakipNo']          as String? ?? '',
      teslimOnayTarihi:   (d['teslimOnayTarihi']     as Timestamp?)?.toDate(),
      isteyenDegerlendirdiMi: d['isteyenDegerlendirdiMi'] as bool? ?? false,
      getirenDegerlendirdiMi: d['getirenDegerlendirdiMi'] as bool? ?? false,
      degerlendirmeAcilmaTarihi:
          (d['degerlendirmeAcilmaTarihi'] as Timestamp?)?.toDate(),
    );
  }
}


class TeklifOzet {
  final int sayi;
  final double? enYuksek;
  const TeklifOzet({required this.sayi, required this.enYuksek});
}