import 'dart:math' as math;
import '../../features/ilanlar/domain/ilan_model.dart';

/// Bu formülün client'taki TEK kopyası budur — başka dosyada yerel kopya YASAK.
/// Adil öneri skoru — [0, 1] aralığında (float, ince sıralama için).
///
/// Bileşenler:
///   0.5 × güven-düzeltilmiş satıcı puanı  (Bayesian, prior: 5 oy × 4.0)
///   0.3 × tazelik                           (14 günde sıfıra iner)
///   0.2 × ilgi                              (favori + görüntülenme + resim, log ölçekli)
///
/// Sunucu eşleniği (functions/src/index.ts onerilenPuanHesapla):
/// tazelik YOK (Algolia tarih kriteri karşılar), dönüş kovalanır (×20 tamsayı).
/// Buradaki fark BİLİNÇLİ; ilgi bileşeni ise birebir aynı olmalı.
///
/// kullaniciDegerlendirmeSayisi modelde olmadığından n=3 (orta güven) varsayılır.
/// Tam çözüm: ilan oluştururken satıcının o anki değerlendirme sayısını denormalize et.
double oneriSkoru(IlanModel ilan) {
  const int n = 3; // pragma: değerlendirme sayısı bilinmiyor
  final duzeltilmis = (ilan.kullaniciPuan * n + 4.0 * 5) / (n + 5);

  final yasGun = DateTime.now()
      .difference(ilan.olusturmaTarihi ?? DateTime.now())
      .inDays;
  final tazelik = (1 - yasGun / 14).clamp(0.0, 1.0);

  final favoriPay =
      (math.log(ilan.favoriSayisi + 1) / math.log(50)).clamp(0.0, 1.0);
  final goruntulenmePay =
      (math.log(ilan.goruntulenmeSayisi + 1) / math.log(500)).clamp(0.0, 1.0);
  final resimPay = (ilan.tumResimler.length / 5).clamp(0.0, 1.0);
  // Resim = formüldeki tek "emek" sinyali; manipülasyona en kapalı bileşen.
  final ilgi = 0.6 * favoriPay + 0.25 * goruntulenmePay + 0.15 * resimPay;

  return 0.5 * (duzeltilmis / 5) + 0.3 * tazelik + 0.2 * ilgi;
}

/// [ilanlar]'ı öneri skoruna göre azalan sırada sıralar (yerinde).
void oneriSkoruylasirala(List<IlanModel> ilanlar) {
  final skorlar = {for (final i in ilanlar) i.id: oneriSkoru(i)};
  ilanlar.sort((a, b) => skorlar[b.id]!.compareTo(skorlar[a.id]!));
}
