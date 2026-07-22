import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';

void main() {
  group('IlanModel.fromFirestore', () {
    test('1) tüm alanları dolu bir doküman → doğru değerler okunur', () async {
      final firestore = FakeFirebaseFirestore();
      final tarih = DateTime(2026, 3, 1, 10, 0);
      final olusturmaTarihi = DateTime(2026, 3, 2, 11, 30);

      await firestore.collection('ilanlar').doc('ilan1').set({
        'tip': 'tasiyici',
        'nereden': 'Berlin',
        'nereye': 'İstanbul',
        'ucret': '200',
        'urun': 'Kitap',
        'notlar': 'Kırılacak eşya',
        'kategori': 'elektronik',
        'kullaniciId': 'uid1',
        'kullaniciAd': 'Ahmet',
        'aktif': true,
        'durum': IlanDurum.yayinda,
        'redSebebi': '',
        'tarih': Timestamp.fromDate(tarih),
        'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
        'resimUrl': 'https://x/1.jpg',
        'resimThumbUrl': 'https://x/1_thumb.jpg',
        'resimUrller': ['https://x/1.jpg', 'https://x/2.jpg'],
        'urunLinki': 'https://shop/1',
        'favoriSayisi': 7,
        'goruntulenmeSayisi': 42,
        'tasimaTercihi': 'kargo',
        'kullaniciPuan': 4.5,
        'anaKategori': 'elektronik',
        'kategoriYolu': ['elektronik', 'telefon'],
        'cinsiyet': 'kadin',
        'beden': 'M',
        'sahipIstekTeslimatTercihi': 'elden',
        'sahipDutyFree': true,
        'sadeceGeliyorum': true,
      });

      final snap = await firestore.collection('ilanlar').doc('ilan1').get();
      final ilan = IlanModel.fromFirestore(snap);

      expect(ilan.id, 'ilan1');
      expect(ilan.tip, 'tasiyici');
      expect(ilan.nereden, 'Berlin');
      expect(ilan.nereye, 'İstanbul');
      expect(ilan.ucret, '200');
      expect(ilan.urun, 'Kitap');
      expect(ilan.notlar, 'Kırılacak eşya');
      expect(ilan.kategori, 'elektronik');
      expect(ilan.kullaniciId, 'uid1');
      expect(ilan.kullaniciAd, 'Ahmet');
      expect(ilan.aktif, isTrue);
      expect(ilan.durum, IlanDurum.yayinda);
      expect(ilan.tarih, tarih);
      expect(ilan.olusturmaTarihi, olusturmaTarihi);
      expect(ilan.resimUrl, 'https://x/1.jpg');
      expect(ilan.resimThumbUrl, 'https://x/1_thumb.jpg');
      expect(ilan.resimUrller, ['https://x/1.jpg', 'https://x/2.jpg']);
      expect(ilan.urunLinki, 'https://shop/1');
      expect(ilan.favoriSayisi, 7);
      expect(ilan.goruntulenmeSayisi, 42);
      expect(ilan.tasimaTercihi, 'kargo');
      expect(ilan.kullaniciPuan, 4.5);
      expect(ilan.anaKategori, 'elektronik');
      expect(ilan.kategoriYolu, ['elektronik', 'telefon']);
      expect(ilan.cinsiyet, 'kadin');
      expect(ilan.beden, 'M');
      expect(ilan.sahipIstekTeslimatTercihi, 'elden');
      expect(ilan.sahipDutyFree, isTrue);
      expect(ilan.sadeceGeliyorum, isTrue);
    });

    test(
        '2) opsiyonel alanlar (List\'ler, nullable\'lar) TAMAMEN eksik bir '
        'doküman → çökmeden doğru varsayılanlara düşer', () async {
      final firestore = FakeFirebaseFirestore();

      // Yalnızca zorunlu (required) alanlar — geri kalan HİÇ yazılmadı.
      await firestore.collection('ilanlar').doc('ilan2').set({
        'tip': 'istek',
        'nereden': 'Münih',
        'nereye': 'Ankara',
        'kullaniciId': 'uid2',
      });

      final snap = await firestore.collection('ilanlar').doc('ilan2').get();

      // Çökmemeli.
      final ilan = IlanModel.fromFirestore(snap);

      expect(ilan.id, 'ilan2');
      expect(ilan.tip, 'istek');
      // @Default değerleri:
      expect(ilan.ucret, '');
      expect(ilan.urun, '');
      expect(ilan.kategori, 'diger');
      expect(ilan.kullaniciAd, 'Kullanıcı');
      expect(ilan.aktif, isFalse);
      expect(ilan.durum, IlanDurum.onayBekliyor);
      expect(ilan.redSebebi, '');
      // Timestamp alanları eksikse null:
      expect(ilan.tarih, isNull);
      expect(ilan.olusturmaTarihi, isNull);
      // List alanları eksikse BOŞ liste (null değil):
      expect(ilan.resimUrller, isEmpty);
      expect(ilan.kategoriYolu, isEmpty);
      // Nullable string eksikse null:
      expect(ilan.sahipIstekTeslimatTercihi, isNull);
      expect(ilan.sahipDutyFree, isFalse);
      expect(ilan.sadeceGeliyorum, isFalse);
      expect(ilan.favoriSayisi, 0);
      expect(ilan.goruntulenmeSayisi, 0);
      expect(ilan.kullaniciPuan, 0.0);
      expect(ilan.tasimaTercihi, 'hepsi');
    });
  });

  group('IlanModel round-trip (toJson/fromJson)', () {
    // NOT: toFirestore() extension'ı (ilan_model.dart) BİLEREK asimetrik —
    // 'aktif' ve 'durum' alanlarını modelin gerçek değerinden BAĞIMSIZ
    // olarak hep false/onayBekliyor'a sabitliyor (yeni ilan hep moderasyon
    // bekler doğsun diye), 'redSebebi'/'favoriSayisi'/'goruntulenmeSayisi'yi
    // hiç yazmıyor, ve 'olusturmaTarihi' için modelin kendi değeri yerine
    // FieldValue.serverTimestamp() sentinel'i kullanıyor. Yani
    // toFirestore() → fromFirestore() bir round-trip DEĞİL, tek yönlü bir
    // "create payload" üretici — bu yüzden round-trip eşitliğini
    // toJson()/fromJson() (freezed/json_serializable'ın ürettiği, gerçekten
    // simetrik serileştiriciler) ile test ediyoruz.
    test('gerçek bir IlanModel → toJson → fromJson → orijinalle eşit '
        '(Freezed == operatörü)', () {
      const orijinal = IlanModel(
        id: 'ilan3',
        tip: 'tasiyici',
        nereden: 'Paris',
        nereye: 'İzmir',
        kullaniciId: 'uid3',
        ucret: '150',
        urun: 'Parfüm',
        kategori: 'kadin_giyim',
        aktif: true,
        durum: IlanDurum.yayinda,
        resimUrller: ['a.jpg', 'b.jpg'],
        kategoriYolu: ['kadin_giyim', 'ust'],
        favoriSayisi: 3,
        kullaniciPuan: 4.8,
        sahipIstekTeslimatTercihi: 'kargo',
        sahipDutyFree: true,
      );

      final json = orijinal.toJson();
      final geriDonusen = IlanModel.fromJson(json);

      expect(geriDonusen, equals(orijinal));
    });
  });
}
