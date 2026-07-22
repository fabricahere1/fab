import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/shared/utils/oneri_skoru.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';

IlanModel _ilan({
  double kullaniciPuan = 0,
  int favoriSayisi = 0,
  int goruntulenmeSayisi = 0,
  int resimSayisi = 0,
  DateTime? olusturmaTarihi,
}) {
  return IlanModel(
    id: 'x',
    tip: 'istek',
    nereden: 'A',
    nereye: 'B',
    kullaniciId: 'u',
    kullaniciPuan: kullaniciPuan,
    favoriSayisi: favoriSayisi,
    goruntulenmeSayisi: goruntulenmeSayisi,
    resimUrller: List.generate(resimSayisi, (i) => 'r$i'),
    olusturmaTarihi: olusturmaTarihi,
  );
}

void main() {
  group('oneriSkoru — tam formül regresyon testi (tazelik zaman-bağımlı '
      'olduğu için tolerans payı ile)', () {
    test('olusturmaTarihi tam "şimdi" ise tazelik=1.0 (yasGun=0)', () {
      final ilan = _ilan(
        kullaniciPuan: 5,
        olusturmaTarihi: DateTime.now(),
      );
      // duzeltilmis = (5*3+4*5)/(3+5) = 35/8 = 4.375 → 0.5*(4.375/5) = 0.4375
      // ilgi = 0 (favori/goruntulenme/resim hepsi 0)
      // beklenen = 0.4375 + 0.3*1.0 + 0.2*0 = 0.7375
      expect(oneriSkoru(ilan), closeTo(0.7375, 0.0001));
    });

    test('olusturmaTarihi 7 gün önce ise tazelik≈0.5 (14 günde sıfıra '
        'iner, yarı yolda yarı değer)', () {
      final ilan = _ilan(
        kullaniciPuan: 5,
        olusturmaTarihi: DateTime.now().subtract(const Duration(days: 7)),
      );
      // tazelik = 1 - 7/14 = 0.5 (±1 günlük saat-dilimi driftine karşı tolerans)
      // beklenen ≈ 0.4375 + 0.3*0.5 + 0 = 0.5875
      expect(oneriSkoru(ilan), closeTo(0.5875, 0.02));
    });

    test('olusturmaTarihi 14+ gün önceyse tazelik 0\'a clamp\'lenir '
        '(negatife düşmez)', () {
      final ilan = _ilan(
        kullaniciPuan: 5,
        olusturmaTarihi: DateTime.now().subtract(const Duration(days: 40)),
      );
      // beklenen ≈ 0.4375 + 0.3*0 + 0 = 0.4375
      expect(oneriSkoru(ilan), closeTo(0.4375, 0.02));
    });

    test('olusturmaTarihi null ise DateTime.now() varsayılır → tazelik=1.0 '
        '(çökme riski yok)', () {
      final ilan = _ilan(kullaniciPuan: 0);
      expect(() => oneriSkoru(ilan), returnsNormally);
      // duzeltilmis=(0+20)/8=2.5 → 0.5*(2.5/5)=0.25; ilgi=0; tazelik=1.0
      expect(oneriSkoru(ilan), closeTo(0.55, 0.0001));
    });

    test('sonuç her zaman [0, 1] aralığında kalır (uç değerlerde bile)', () {
      final maksimum = _ilan(
        kullaniciPuan: 5,
        favoriSayisi: 10000,
        goruntulenmeSayisi: 10000,
        resimSayisi: 50,
        olusturmaTarihi: DateTime.now(),
      );
      final minimum = _ilan(
        kullaniciPuan: 0,
        olusturmaTarihi: DateTime.now().subtract(const Duration(days: 100)),
      );
      expect(oneriSkoru(maksimum), lessThanOrEqualTo(1.0));
      expect(oneriSkoru(minimum), greaterThanOrEqualTo(0.0));
    });
  });

  group('oneriSkoru — alt bileşen (duzeltilmis + ilgi) golden değerleri — '
      'TS parity referansı', () {
    // NOT (parity sınırı — BİLİNÇLİ FARK, bug DEĞİL): oneri_skoru.dart'ın
    // kendi doc-comment'i (satır 12-14) ve functions/src/index.ts'teki
    // onerilenPuanHesapla() karşılaştırıldığında, iki formül TAM olarak
    // aynı değeri üretmiyor:
    //   - Dart: 0.5*(duzeltilmis/5) + 0.3*tazelik + 0.2*ilgi   → [0,1] float
    //   - TS:   round((0.5*(duzeltilmis/5) + 0.2*ilgi) * 20)   → 0-14 tamsayı
    // tazelik yalnızca Dart'ta var (sunucuda Algolia'nın olusturmaTarihi
    // ikincil kriteri karşılıyor); TS'nin çıktısı ayrıca ×20 kovalanmış.
    // Bu yüzden BURADA yalnızca ortak/paylaşılması gereken kısmı
    // (duzeltilmis Bayesian düzeltmesi + ilgi bileşeni) karşılaştırıyoruz —
    // tazelik'i devre dışı bırakmak için olusturmaTarihi=DateTime.now()
    // veriyoruz (tazelik TAM 1.0 olur, sabit ve bilinen bir değer), sonra
    // dartFull'dan 0.3'ü (0.3*tazelik) çıkarıp "dartCore"u izole ediyoruz.
    // dartCore, TS'nin ×20'den ÖNCEKİ çekirdek ifadesiyle birebir aynı
    // matematiksel yapıya sahip. Bu golden değerler, GERÇEK oneriSkoru()
    // fonksiyonu çalıştırılarak üretildi (elle hesaplanmadı).
    //
    // functions/test/oneriSkoru.test.ts, AYNI 10 girdiyi gerçek TS
    // onerilenPuanHesapla() fonksiyonuna verip buradaki goldenBucket
    // değerleriyle karşılaştırıyor.
    const goldenler = [
      // (kullaniciPuan, favoriSayisi, goruntulenmeSayisi, resimSayisi, dartCore, goldenBucket)
      (0.0, 0, 0, 0, 0.25000000000000006, 5),
      (5.0, 0, 0, 0, 0.43750000000000006, 9),
      (3.0, 10, 100, 3, 0.4911858644559704, 10),
      (4.5, 49, 499, 5, 0.6187499999999999, 12),
      (2.0, 1, 1, 1, 0.35783881538615475, 7),
      (5.0, 100, 1000, 10, 0.6375, 13),
      (1.0, 5, 50, 2, 0.38609536125620053, 8),
      (3.5, 0, 500, 0, 0.43124999999999997, 9),
      (4.0, 25, 0, 4, 0.5239410238692572, 10),
      (0.5, 2, 2, 1, 0.31728851595083335, 6),
    ];

    for (final (puan, favori, goruntulenme, resim, beklenenCore, beklenenBucket)
        in goldenler) {
      test('puan=$puan favori=$favori goruntulenme=$goruntulenme resim=$resim '
          '→ dartCore≈$beklenenCore, goldenBucket=$beklenenBucket', () {
        final ilan = _ilan(
          kullaniciPuan: puan,
          favoriSayisi: favori,
          goruntulenmeSayisi: goruntulenme,
          resimSayisi: resim,
          olusturmaTarihi: DateTime.now(), // tazelik'i 1.0'a sabitler
        );
        final dartFull = oneriSkoru(ilan);
        final dartCore = dartFull - 0.3;

        expect(dartCore, closeTo(beklenenCore, 1e-9));
        expect((dartCore * 20).round(), beklenenBucket);
      });
    }
  });
}
