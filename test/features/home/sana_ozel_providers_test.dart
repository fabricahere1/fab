import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/features/home/providers/sana_ozel_providers.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/profil/domain/kullanici_model.dart';

IlanModel _ilan({
  required String cinsiyet,
  required String beden,
  String anaKategori = '',
}) {
  return IlanModel(
    id: 'ilan1',
    tip: 'tasiyici',
    nereden: 'İstanbul',
    nereye: 'Berlin',
    kullaniciId: 'sahipUid',
    anaKategori: anaKategori,
    cinsiyet: cinsiyet,
    beden: beden,
  );
}

KullaniciModel _profil({
  List<String> kadinUstBeden = const [],
  List<String> erkekUstBeden = const [],
  List<String> cocukAyakkabi = const [],
  List<String> erkekAyakkabi = const [],
}) {
  return KullaniciModel(
    id: 'benUid',
    kadinUstBeden: kadinUstBeden,
    erkekUstBeden: erkekUstBeden,
    cocukAyakkabi: cocukAyakkabi,
    erkekAyakkabi: erkekAyakkabi,
  );
}

void main() {
  group('bedenEslesiyor', () {
    test('1) Kadın ilanı + kadinUstBeden eşleşmesi → true', () {
      final ilan = _ilan(cinsiyet: 'Kadın', beden: 'M');
      final profil = _profil(kadinUstBeden: ['M']);
      expect(bedenEslesiyor(ilan, profil), isTrue);
    });

    test(
        '2) Kadın ilanı + yalnızca erkekUstBeden eşleşmesi → false '
        '(düzeltmeden önceki bug: Türkçe ı/i uyuşmazlığı yüzünden '
        "default dalına düşüp yanlışlıkla true dönerdi)", () {
      final ilan = _ilan(cinsiyet: 'Kadın', beden: 'M');
      final profil = _profil(erkekUstBeden: ['M']);
      expect(bedenEslesiyor(ilan, profil), isFalse);
    });

    test('3) Çocuk ilanı + cocukAyakkabi eşleşmesi → true', () {
      final ilan =
          _ilan(cinsiyet: 'Erkek', beden: '28', anaKategori: 'cocuk');
      final profil = _profil(cocukAyakkabi: ['28']);
      expect(bedenEslesiyor(ilan, profil), isTrue);
    });

    test(
        '4) Çocuk ilanı + yalnızca erkekAyakkabi eşleşmesi (cocukAyakkabi '
        'boş) → false (düzeltmeden önceki BUG 2: çocuk ürünü yetişkin '
        "erkek listesiyle karşılaştırılıyordu)", () {
      final ilan =
          _ilan(cinsiyet: 'Erkek', beden: '28', anaKategori: 'cocuk');
      final profil = _profil(erkekAyakkabi: ['28']);
      expect(bedenEslesiyor(ilan, profil), isFalse);
    });

    test('5) Unisex ilan + kadinUstBeden eşleşmesi → true (default dalı)',
        () {
      final ilan = _ilan(cinsiyet: 'Unisex', beden: 'M');
      final profil = _profil(kadinUstBeden: ['M']);
      expect(bedenEslesiyor(ilan, profil), isTrue);
    });
  });
}
