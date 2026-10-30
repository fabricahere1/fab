import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/features/auth/providers/auth_provider.dart';
import 'package:iste_v3/features/mesajlar/domain/mesaj_model.dart';
import 'package:iste_v3/features/mesajlar/presentation/mesajlar_screen.dart';
import 'package:iste_v3/features/mesajlar/providers/mesaj_provider.dart';
import 'package:iste_v3/features/profil/providers/profil_provider.dart';

// _SohbetKarti private bir sınıf (mesajlar_screen.dart içinde) — bu
// dosyadan doğrudan import/instantiate edilemez. Bu yüzden gerçek widget'ı
// MesajlarScreen üzerinden, provider override'larıyla render ediyoruz —
// tıpkı üretimdeki gibi.

const _benimUid = 'uidA';
const _karsiUid = 'uidB';

SohbetModel _sohbet({
  Map<String, dynamic> islemDurumlari = const {},
  Map<String, int> okunmamis = const {},
}) {
  return SohbetModel(
    id: 'sohbet1',
    kullanicilar: const [_benimUid, _karsiUid],
    ilanId: 'ilan1',
    ilanBaslik: 'Test İlan',
    kullaniciAdlari: const {_karsiUid: 'Karşı Kullanıcı'},
    sonMesaj: 'merhaba',
    islemDurumlari: islemDurumlari,
    okunmamis: okunmamis,
  );
}

class _FakeSohbetler extends Sohbetler {
  final SohbetModel _sohbet;
  _FakeSohbetler(this._sohbet);

  @override
  Future<List<SohbetModel>> build() async => [_sohbet];
}

Future<void> _render(WidgetTester tester, SohbetModel sohbet) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(AktifKullanici(uid: _benimUid)),
        sohbetlerProvider.overrideWith(() => _FakeSohbetler(sohbet)),
        engellenenlerProvider.overrideWith((ref) async => <String>[]),
      ],
      child: const MaterialApp(home: MesajlarScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      '1) karsiOnayi=true, benimOnayim=false → "Anlaşma önerildi" etiketi '
      'GÖRÜNMELİ', (tester) async {
    final sohbet = _sohbet(islemDurumlari: const {
      'anlasildi_$_karsiUid': true,
    });

    await _render(tester, sohbet);

    expect(find.text('Anlaşma önerildi'), findsOneWidget);
  });

  testWidgets(
      '2) karsiOnayi=true, benimOnayim=true (ikisi de onayladı) → etiket '
      'GÖRÜNMEMELİ', (tester) async {
    final sohbet = _sohbet(islemDurumlari: const {
      'anlasildi_$_benimUid': true,
      'anlasildi_$_karsiUid': true,
    });

    await _render(tester, sohbet);

    expect(find.text('Anlaşma önerildi'), findsNothing);
  });

  testWidgets('3) karsiOnayi=false → etiket GÖRÜNMEMELİ', (tester) async {
    final sohbet = _sohbet(islemDurumlari: const {});

    await _render(tester, sohbet);

    expect(find.text('Anlaşma önerildi'), findsNothing);
  });

  group('4) yeşil etiket ile kırmızı okunmamış rozeti birbirinden BAĞIMSIZ', () {
    testWidgets('anlasmaOnerildi=true VE okunmamış mesaj var → İKİSİ DE '
        'aynı anda görünür, birbirini engellemez', (tester) async {
      final sohbet = _sohbet(
        islemDurumlari: const {'anlasildi_$_karsiUid': true},
        okunmamis: const {_benimUid: 3},
      );

      await _render(tester, sohbet);

      expect(find.text('Anlaşma önerildi'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // kırmızı rozet sayacı
    });

    testWidgets('anlasmaOnerildi=false AMA okunmamış mesaj var → yalnızca '
        'kırmızı rozet görünür, yeşil etiket görünmez', (tester) async {
      final sohbet = _sohbet(
        islemDurumlari: const {},
        okunmamis: const {_benimUid: 5},
      );

      await _render(tester, sohbet);

      expect(find.text('Anlaşma önerildi'), findsNothing);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('anlasmaOnerildi=true AMA okunmamış mesaj YOK → yalnızca '
        'yeşil etiket görünür, kırmızı rozet görünmez', (tester) async {
      final sohbet = _sohbet(
        islemDurumlari: const {'anlasildi_$_karsiUid': true},
        okunmamis: const {},
      );

      await _render(tester, sohbet);

      expect(find.text('Anlaşma önerildi'), findsOneWidget);
      // Kırmızı rozet yalnızca okunmamisSayi > 0 iken render ediliyor —
      // burada hiç yok, bu yüzden hiçbir sayaç Text'i aramıyoruz, yalnızca
      // rozetin var olduğu Positioned+Container yapısının yokluğunu
      // dolaylı olarak (herhangi bir rakam bulunmamasıyla) doğruluyoruz.
      expect(find.textContaining(RegExp(r'^[0-9]+\+?$')), findsNothing);
    });
  });
}
