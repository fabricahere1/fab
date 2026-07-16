import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/features/mesajlar/domain/mesaj_model.dart';

SohbetModel _sohbet({
  Map<String, int> okunmamis = const {},
  Map<String, dynamic> gizli = const {},
  DateTime? sonMesajZamani,
}) {
  return SohbetModel(
    id: 'sohbet1',
    kullanicilar: const ['uidA', 'uidB'],
    ilanId: 'ilan1',
    okunmamis: okunmamis,
    gizli: gizli,
    sonMesajZamani: sonMesajZamani,
  );
}

void main() {
  group('okunmamisSayisi', () {
    test('nested map\'te değer varsa doğru döner', () {
      final sohbet = _sohbet(okunmamis: {'uidA': 3, 'uidB': 7});

      expect(sohbet.okunmamisSayisi('uidA'), 3);
      expect(sohbet.okunmamisSayisi('uidB'), 7);
    });

    test('map\'te uid yoksa 0 döner', () {
      final sohbet = _sohbet(okunmamis: {'uidA': 3});

      expect(sohbet.okunmamisSayisi('uidB'), 0);
    });

    test('okunmamis map\'i tamamen boşsa 0 döner', () {
      final sohbet = _sohbet();

      expect(sohbet.okunmamisSayisi('uidA'), 0);
    });
  });

  group('gizliMi', () {
    test('gizli map\'te uid için hiç girdi yoksa false döner', () {
      final sohbet = _sohbet(gizli: const {});

      expect(sohbet.gizliMi('uidA'), isFalse);
    });

    test('gizli değeri bool true ise true döner', () {
      final sohbet = _sohbet(gizli: const {'uidA': true});

      expect(sohbet.gizliMi('uidA'), isTrue);
    });

    test('gizli değeri bool false ise false döner', () {
      final sohbet = _sohbet(gizli: const {'uidA': false});

      expect(sohbet.gizliMi('uidA'), isFalse);
    });

    test(
        'gizli değeri Timestamp ve sonMesajZamani gizleme anından SONRA ise '
        '(yeni mesaj geldi) false döner — sohbet tekrar görünür olmalı', () {
      final gizlemeAni = DateTime(2026, 1, 1, 12, 0, 0);
      final yeniMesajZamani = DateTime(2026, 1, 1, 12, 5, 0);
      final sohbet = _sohbet(
        gizli: {'uidA': Timestamp.fromDate(gizlemeAni)},
        sonMesajZamani: yeniMesajZamani,
      );

      expect(sohbet.gizliMi('uidA'), isFalse);
    });

    test(
        'gizli değeri Timestamp ve sonMesajZamani gizleme anından ÖNCE/AYNI ise '
        'true döner — sohbet hâlâ gizli kalmalı', () {
      final gizlemeAni = DateTime(2026, 1, 1, 12, 0, 0);
      final eskiMesajZamani = DateTime(2026, 1, 1, 11, 0, 0);
      final sohbet = _sohbet(
        gizli: {'uidA': Timestamp.fromDate(gizlemeAni)},
        sonMesajZamani: eskiMesajZamani,
      );

      expect(sohbet.gizliMi('uidA'), isTrue);
    });

    test(
        'gizli değeri Timestamp ama sonMesajZamani null ise false döner '
        '(karşılaştırma yapılamıyor)', () {
      final gizlemeAni = DateTime(2026, 1, 1, 12, 0, 0);
      final sohbet = _sohbet(
        gizli: {'uidA': Timestamp.fromDate(gizlemeAni)},
        sonMesajZamani: null,
      );

      expect(sohbet.gizliMi('uidA'), isFalse);
    });

    test('gizli map\'inde başka bir kullanıcının değeri bu uid\'yi etkilemez',
        () {
      final sohbet = _sohbet(gizli: const {'uidB': true});

      expect(sohbet.gizliMi('uidA'), isFalse);
    });
  });
}
