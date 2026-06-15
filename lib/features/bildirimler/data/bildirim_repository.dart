import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/bildirim_model.dart';
import '../../../shared/constants/app_constants.dart';
 
part 'bildirim_repository.g.dart';
 
@riverpod
BildirimRepository bildirimRepository(Ref ref) {
  return BildirimRepository(firestore: FirebaseFirestore.instance);
}
 
class BildirimRepository {
  final FirebaseFirestore firestore;
 
  BildirimRepository({required this.firestore});
 
  CollectionReference get _col => firestore.collection(Collections.bildirimler);
 
  // Kullanıcının bildirimlerini stream olarak dinle
  Stream<List<BildirimModel>> bildirimlerStream(String kullaniciId) {
    return _col
        .where('kullaniciId', isEqualTo: kullaniciId)
        .orderBy('tarih', descending: true)
        .limit(50)
        .snapshots(includeMetadataChanges: false)
        .map((snap) => snap.docs
            .map((doc) => BildirimModel.fromFirestore(doc))
            .toList());
  }
 
  // Okunmamış bildirim sayısı
  Stream<int> okunmamisSayiStream(String kullaniciId) {
    return _col
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('okundu', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
 
  // Bildirim oluştur
  Future<void> bildirimOlustur({
    required String kullaniciId,
    required BildirimTip tip,
    required String baslik,
    required String icerik,
    String hedefId = '',
    String gondereId = '',
    String gondereAd = '',
  }) async {
    await _col.add({
      'kullaniciId': kullaniciId,
      'tip': tip.name,
      'baslik': baslik,
      'icerik': icerik,
      'okundu': false,
      'tarih': FieldValue.serverTimestamp(),
      'hedefId': hedefId,
      'gondereId': gondereId,
      'gondereAd': gondereAd,
    });
  }
 
  // Bildirimi okundu işaretle
  Future<void> okunduIsaretle(String bildirimId) async {
    await _col.doc(bildirimId).update({'okundu': true});
  }
 
  // Tüm bildirimleri okundu işaretle
  Future<void> tumunuOkunduIsaretle(String kullaniciId) async {
    final snap = await _col
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('okundu', isEqualTo: false)
        .get();
 
    final batch = firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'okundu': true});
    }
    await batch.commit();
  }
 
  // Bildirimi sil
  Future<void> bildirimSil(String bildirimId) async {
    await _col.doc(bildirimId).delete();
  }
 
  // Mesaj bildirimi gönder (mesaj gönderilince çağrılır)
  Future<void> mesajBildirimiGonder({
    required String aliciId,
    required String gondereId,
    required String gondereAd,
    required String ilanBaslik,
    required String sohbetId,
  }) async {
    await bildirimOlustur(
      kullaniciId: aliciId,
      tip: BildirimTip.mesaj,
      baslik: gondereAd,
      icerik: '$ilanBaslik hakkında mesaj gönderdi',
      hedefId: sohbetId,
      gondereId: gondereId,
      gondereAd: gondereAd,
    );
  }
}