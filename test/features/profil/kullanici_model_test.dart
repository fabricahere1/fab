import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/features/profil/domain/kullanici_model.dart';

void main() {
  group('KullaniciModel.fromFirestore', () {
    test('1) tüm alanları dolu bir doküman → doğru değerler okunur',
        () async {
      final firestore = FakeFirebaseFirestore();

      await firestore.collection('kullanicilar').doc('uid1').set({
        'adSoyad': 'Ayşe Yılmaz',
        'fotoUrl': 'https://x/foto.jpg',
        'telefon': '05551112233',
        'email': 'ayse@example.com',
        'profilTamamlandi': true,
        'ortalamaPuan': 4.7,
        'degerlendirmeSayisi': 12,
        'kullaniciTipi': 'her_ikisi',
        'yasadigiUlke': 'Almanya',
        'bulunduguSehir': 'İstanbul',
        'geldigiSehirler': ['İstanbul', 'Ankara'],
        'hakkinda': 'Merhaba',
        'telefonGizli': true,
        'engellenenler': ['uidX'],
        'ilgiKategorileri': ['kadin_giyim'],
        'dutyFreeIlgileniyor': true,
        'istekTeslimatTercihi': 'elden',
        'kadinUstBeden': ['M', 'L'],
        'takipciSayisi': 15,
        'takipSayisi': 8,
        'guvenSkoru': 72,
        'rozetler': ['dogrulandi', 'guvenilir'],
      });

      final snap = await firestore.collection('kullanicilar').doc('uid1').get();
      final k = KullaniciModel.fromFirestore(snap);

      expect(k.id, 'uid1');
      expect(k.adSoyad, 'Ayşe Yılmaz');
      expect(k.fotoUrl, 'https://x/foto.jpg');
      expect(k.telefon, '05551112233');
      expect(k.email, 'ayse@example.com');
      expect(k.profilTamamlandi, isTrue);
      expect(k.ortalamaPuan, 4.7);
      expect(k.degerlendirmeSayisi, 12);
      expect(k.kullaniciTipi, 'her_ikisi');
      expect(k.yasadigiUlke, 'Almanya');
      expect(k.bulunduguSehir, 'İstanbul');
      expect(k.geldigiSehirler, ['İstanbul', 'Ankara']);
      expect(k.hakkinda, 'Merhaba');
      expect(k.telefonGizli, isTrue);
      expect(k.engellenenler, ['uidX']);
      expect(k.ilgiKategorileri, ['kadin_giyim']);
      expect(k.dutyFreeIlgileniyor, isTrue);
      expect(k.istekTeslimatTercihi, 'elden');
      expect(k.kadinUstBeden, ['M', 'L']);
      expect(k.takipciSayisi, 15);
      expect(k.takipSayisi, 8);
      expect(k.guvenSkoru, 72);
      expect(k.rozetler, ['dogrulandi', 'guvenilir']);
    });

    test(
        '4) guvenSkoru alanı dokümanda HİÇ yoksa (dünkü backfill öncesi '
        'eski kullanıcı senaryosu) → çökmeden 0\'a düşer', () async {
      final firestore = FakeFirebaseFirestore();

      // guvenSkoru hiç yazılmamış — backfill öncesi eski doküman simülasyonu.
      await firestore.collection('kullanicilar').doc('uid2').set({
        'adSoyad': 'Eski Kullanıcı',
      });

      final snap = await firestore.collection('kullanicilar').doc('uid2').get();

      final k = KullaniciModel.fromFirestore(snap);

      expect(k.guvenSkoru, 0);
    });

    test(
        '5) ortalamaPuan ve takipciSayisi dokümanda HİÇ yoksa → çökmeden '
        '@Default değerlerine (0.0 / 0) düşer', () async {
      final firestore = FakeFirebaseFirestore();

      await firestore.collection('kullanicilar').doc('uid3').set({
        'adSoyad': 'Yeni Kullanıcı',
      });

      final snap = await firestore.collection('kullanicilar').doc('uid3').get();
      final k = KullaniciModel.fromFirestore(snap);

      expect(k.ortalamaPuan, 0.0);
      expect(k.degerlendirmeSayisi, 0);
      expect(k.takipciSayisi, 0);
      expect(k.takipSayisi, 0);
      // Diğer opsiyonel/list alanlar da çökmeden varsayılana düşmeli:
      expect(k.fotoUrl, isNull);
      expect(k.telefon, isNull);
      expect(k.geldigiSehirler, isEmpty);
      expect(k.engellenenler, isEmpty);
      expect(k.rozetler, isEmpty);
      expect(k.profilTamamlandi, isFalse);
    });
  });

  group('KullaniciModel round-trip (toFirestore/fromFirestore)', () {
    // NOT: IlanModel'in aksine, KullaniciModel.toFirestore() BİLİNÇLİ bir
    // zorlama/override İÇERMİYOR — yalnızca bazı alanları koşullu olarak
    // (ör. `if (takipciSayisi > 0) ...`) atlıyor, ama fromFirestore()
    // eksik alan için ZATEN aynı varsayılana (0/boş liste) düşüyor. Bu
    // yüzden burada, IlanModel'den farklı olarak, gerçek toFirestore() →
    // fromFirestore() round-trip'i anlamlı ve eşitlik bekleniyor.
    test('gerçek bir KullaniciModel → toFirestore → fromFirestore → '
        'orijinalle eşit', () async {
      const orijinal = KullaniciModel(
        id: 'uid4',
        adSoyad: 'Test Kullanıcı',
        fotoUrl: 'https://x/f.jpg',
        profilTamamlandi: true,
        ortalamaPuan: 3.9,
        degerlendirmeSayisi: 5,
        kullaniciTipi: 'istek',
        bulunduguSehir: 'İzmir',
        hakkinda: 'Test',
        takipciSayisi: 4,
        takipSayisi: 2,
        guvenSkoru: 55,
        rozetler: ['yeni_uye'],
      );

      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('kullanicilar')
          .doc(orijinal.id)
          .set(orijinal.toFirestore());

      final snap =
          await firestore.collection('kullanicilar').doc(orijinal.id).get();
      final geriDonusen = KullaniciModel.fromFirestore(snap);

      expect(geriDonusen, equals(orijinal));
    });
  });
}
