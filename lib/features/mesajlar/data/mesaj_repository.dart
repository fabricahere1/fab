import '../../../core/firebase/app_firestore.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/mesaj_model.dart';
import '../domain/islem_durumu.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

part 'mesaj_repository.g.dart';

String sohbetIdUret(String uid1, String uid2, String ilanId) {
  final ids = [uid1, uid2]..sort();
  return '${ids[0]}_${ids[1]}_$ilanId';
}

@riverpod
MesajRepository mesajRepository(Ref ref) {
  return MesajRepository(
    firestore: AppFirestore.instance,
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

  /// İlk temasta (henüz hiç mesaj gönderilmemişken) sohbet dokümanının
  /// 'kullanicilar' alanı olmadan var olmaması, mesajlar dinleyicisinin
  /// güvenlik kuralı kontrolünde (sohbetKatilimcisiMi) hataya düşmesine
  /// sebep oluyordu. Bu metod, dinleyici başlamadan önce çağrılarak
  /// dokümanın en azından bu alanla var olmasını garanti eder — mevcut
  /// veriyi bozmadan (merge: true).
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

  Future<Map<String, dynamic>?> sohbetGetir(String sohbetId) async {
    final snap = await _sohbetler.doc(sohbetId).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>;
  }

  Future<String> mesajGonder({
    required String sohbetId,
    required String gondereId,
    required String karsiId,
    required String ilanId,
    required String ilanBaslik,
    required String metin,
    String gondereAd = '',
    String karsiAd = '',
    String ilanResimUrl = '',
    String tip = 'mesaj',
    String? resimUrl,
    String ilanSahibiId = '',
    String ilanTip = 'istek',
  }) async {
    final sohbetRef = _sohbetler.doc(sohbetId);
    final mesajRef  = _mesajlar(sohbetId).doc();
    final batch     = firestore.batch();

    // Tek bir set() — eskiden aynı dökümana (sohbetRef) iki ayrı set()
    // çağrısı yapılıyordu (ana veri + okunmamis sayacı). İlk temasta
    // (sohbet dökümanı henüz yokken) ikinci yazma, Firestore kuralının
    // "create" olarak değerlendirdiği ama 'kullanicilar' alanı içermeyen
    // bir istek oluşturuyordu — kural bu alana erişmeye çalışırken
    // permission-denied veriyordu. Tek yazmaya birleştirince bu risk
    // tamamen ortadan kalkıyor; 'okunmamis.$karsiId' nokta notasyonu,
    // sadece o alt-alanı güncelliyor, diğer kullanıcının sayacına dokunmuyor.
    batch.set(sohbetRef, {
      'kullanicilar':         [gondereId, karsiId],
      'sonMesaj':             tip == 'resim' ? '📷 Fotoğraf' : metin,
      'sonMesajZamani':       FieldValue.serverTimestamp(),
      'sonGondereId':         gondereId,
      'ilanTip':              ilanTip,
      'degerlendirmeYapildi': false,
      'islemDurumlari':       {'iletisimBasladi': true},
      'olusturmaTarihi':      FieldValue.serverTimestamp(),
      'okunmamis.$karsiId':   FieldValue.increment(1),
      if (gondereAd.isNotEmpty)   'kullaniciAdlari.$gondereId': gondereAd,
      if (karsiAd.isNotEmpty)     'kullaniciAdlari.$karsiId':   karsiAd,
      // İlan meta: boş geçilirse mevcut değeri ezme
      if (ilanId.isNotEmpty)       'ilanId':       ilanId,
      if (ilanBaslik.isNotEmpty)   'ilanBaslik':   ilanBaslik,
      if (ilanResimUrl.isNotEmpty) 'ilanResimUrl': ilanResimUrl,
      if (ilanSahibiId.isNotEmpty) 'ilanSahibiId': ilanSahibiId,
    }, SetOptions(merge: true));


    batch.set(mesajRef, {
      'metin':     metin,
      'gondereId': gondereId,
      'tip':       tip,
      'zaman':     FieldValue.serverTimestamp(),
      'okundu':    false,
      'resimUrl': resimUrl,
    });

    await batch.commit();
    return mesajRef.id;
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

      // Firestore batch limiti 500 — gruplara böl
      final hedefler = mesajlar.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['gondereId'] != kullaniciId;
      }).toList();

      const grupBoyutu = 490;
      for (int i = 0; i < hedefler.length; i += grupBoyutu) {
        final grup = hedefler.sublist(
          i, (i + grupBoyutu).clamp(0, hedefler.length));
        final batch = firestore.batch();
        for (final doc in grup) {
          batch.update(doc.reference, {'okundu': true});
        }
        await batch.commit();
      }
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'mesajRepository.okunduIsaretle');
    }
  }

  Future<void> mesajSil({
    required String sohbetId,
    required String mesajId,
    required String metin,
  }) async {
    final sohbetRef = _sohbetler.doc(sohbetId);
    final sohbetSnap = await sohbetRef.get();
    final sohbetData = sohbetSnap.data() as Map<String, dynamic>?;

    await _mesajlar(sohbetId).doc(mesajId).delete();

    // Silinen mesaj son mesajsa güncelle — metin yerine sonMesajId ile kontrol
    final sonMesaj = sohbetData?['sonMesaj'] as String?;
    if (sohbetSnap.exists && sonMesaj == metin) {
      final onceki = await _mesajlar(sohbetId)
          .orderBy('zaman', descending: true)
          .limit(1)
          .get();
      final yeniSonMesaj = onceki.docs.isNotEmpty
          ? (onceki.docs.first.data() as Map<String, dynamic>)['metin'] ?? ''
          : '';
      final yeniGondereId = onceki.docs.isNotEmpty
          ? (onceki.docs.first.data() as Map<String, dynamic>)['gondereId'] ?? ''
          : '';
      await sohbetRef.update({
        'sonMesaj': yeniSonMesaj,
        'sonGondereId': yeniGondereId,
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

  CollectionReference get _kullanicilar =>
      firestore.collection(Collections.kullanicilar);

  CollectionReference get _bildirimler =>
      firestore.collection(Collections.bildirimler);

  /// Sohbetin karşı taraf uid'ini, ilan başlığını ve benim adımı tek
  /// okumada toplar — bildirim yazarken ihtiyaç duyulan bağlamı sağlar.
  /// Mesaj bildirimleri gibi, "anında yaz" deseniyle çalışır; sonradan
  /// dinleyip fark etmeye (IslemDurumuService'in eski yaklaşımı) güvenmez
  /// — o yaklaşım, uygulama yeni açıldığında oluşan bir yarış durumu
  /// (race condition) yüzünden bildirimleri kaçırıyordu.
  Future<({String karsiUid, String ilanBaslik, String benimAd, Map<String, dynamic> mevcutDurumlar})>
      _bildirimBaglamiOku(String sohbetId, String benimUid) async {
    final sohbetSnap = await _sohbetler.doc(sohbetId).get();
    final sohbetData = sohbetSnap.data() as Map<String, dynamic>? ?? {};
    final kullanicilar = List<String>.from(sohbetData['kullanicilar'] ?? []);
    final karsiUid = kullanicilar.firstWhere((id) => id != benimUid, orElse: () => '');
    final ilanBaslik = sohbetData['ilanBaslik'] as String? ?? 'İlan';
    final mevcutDurumlar = Map<String, dynamic>.from(sohbetData['islemDurumlari'] as Map? ?? {});

    final benimDoc = await _kullanicilar.doc(benimUid).get();
    final benimAd = (benimDoc.data() as Map<String, dynamic>?)?['adSoyad'] as String? ?? 'Kullanıcı';

    return (karsiUid: karsiUid, ilanBaslik: ilanBaslik, benimAd: benimAd, mevcutDurumlar: mevcutDurumlar);
  }

  Future<void> _islemBildirimiYaz({
    required String kullaniciId,
    required String gondereId,
    required String gondereAd,
    required String icerik,
    required String tip,
    required String hedefId,
  }) async {
    if (kullaniciId.isEmpty) return;
    try {
      await _bildirimler.add({
        'kullaniciId': kullaniciId,
        'tip':         tip,
        'baslik':      gondereAd,
        'icerik':      icerik,
        'okundu':      false,
        'tarih':       FieldValue.serverTimestamp(),
        'hedefId':     hedefId,
        'gondereId':   gondereId,
        'gondereAd':   gondereAd,
      });
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'mesajRepository.islemBildirimiYaz');
    }
  }

  /// [yapanUid] — bu işlemi gerçekten yapan kişinin uid'i, durum boolean'ı
  /// ile AYNI atomik update() çağrısında yazılır.
  Future<void> islemDurumuGuncelle({
    required String sohbetId,
    required String durum,
    required String yapanUid,
  }) async {
    final baglam = await _bildirimBaglamiOku(sohbetId, yapanUid);

    await _sohbetler.doc(sohbetId).update({
      'islemDurumlari.$durum': true,
      'islemDurumlari.${durum}_yapanUid': yapanUid,
    });

    final durumEnum = IslemDurumu.values.firstWhere(
      (d) => d.firestoreKey == durum,
      orElse: () => IslemDurumu.iletisimBasladi,
    );
    if (durumEnum == IslemDurumu.iletisimBasladi) return; // bu duruma bildirim yazılmaz

    await _islemBildirimiYaz(
      kullaniciId: baglam.karsiUid,
      gondereId: yapanUid,
      gondereAd: baglam.benimAd,
      icerik: '"${baglam.ilanBaslik}" ilanını ${durumEnum.gecmisDonusu}',
      tip: 'sistem',
      hedefId: sohbetId,
    );
  }

  Future<void> teslimTamamla({
    required String sohbetId,
    required String yapanUid,
  }) async {
    await islemDurumuGuncelle(
      sohbetId: sohbetId,
      durum: 'teslimAlindi',
      yapanUid: yapanUid,
    );
    await _sohbetler.doc(sohbetId).update({
      'degerlendirmeBekliyor': true,
    });
  }

  // ── Anlaşıldı — iki taraflı onay ─────────────────────────
  //
  // İlk kişi tıkladığında "önerdi", ikinci kişi (karşı taraf ZATEN
  // onaylamışken) tıkladığında "kabul etti" mesajı gider — yapanUid yazma
  // anından ÖNCE mevcut durumu okuyup karşı tarafın onayının olup
  // olmadığına bakarak ayrım yapılır.
  Future<void> anlasildiIsaretle({
    required String sohbetId,
    required String benimUid,
  }) async {
    await _sohbetler.doc(sohbetId).update({
      'islemDurumlari.anlasildi_$benimUid': true,
    });

    // bildirimler yazma + push Cloud Function tarafından yapılıyor
  }

  Future<void> mesajBildirimiGonder({
    required String aliciId,
    required String gondereId,
    required String gondereAd,
    required String ilanBaslik,
    required String sohbetId,
    required String metin,
    String ilanId = '',
    String ilanSahibiId = '',
    String ilanResimUrl = '',
    String mesajId = '',
    String mesajZaman = '',
  }) async {
    try {
      await _functions.httpsCallable('mesajBildirimiGonder').call({
        'aliciId':      aliciId,
        'gondereAd':    gondereAd,
        'ilanBaslik':   ilanBaslik,
        'sohbetId':     sohbetId,
        'metin':        metin,
        'ilanId':       ilanId,
        'ilanSahibiId': ilanSahibiId,
        'ilanResimUrl': ilanResimUrl,
        'mesajId':      mesajId,
        'mesajZaman':   mesajZaman,
      });
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'mesajRepository.mesajBildirimiGonder');
    }
  }

  // ── Sohbet dökümanı stream'leri ──────────────────────────

  Stream<Map<String, dynamic>> sohbetDurumuStream(String sohbetId) {
    return _sohbetler.doc(sohbetId).snapshots().map((doc) {
      if (!doc.exists) return <String, dynamic>{};
      return Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>? ?? {});
    });
  }
}