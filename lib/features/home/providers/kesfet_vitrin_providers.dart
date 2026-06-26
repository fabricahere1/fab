// lib/features/home/providers/kesfet_vitrin_providers.dart
//
// "Keşfet" sekmesinin (herkese aynı, kişiselleştirilmemiş) vitrin bölümlerini
// besleyen computed provider'lar. Tüm veriler mevcut istek/taşıyıcı ilan
// listelerinden türetilir; ekstra Firestore sorgusu yapılmaz.

import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';

part 'kesfet_vitrin_providers.g.dart';

// ── Yardımcılar ───────────────────────────────────────────────────────────────

/// İstek + taşıyıcı, engellenenler filtrelenmiş tüm aktif ilanlar.
List<IlanModel> _tumIlanlar(Ref ref) {
  final istek    = ref.watch(istekIlanlarProvider).filtrelenmis;
  final tasiyici = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  return [...istek, ...tasiyici];
}

DateTime _gunBaslangici(DateTime d) => DateTime(d.year, d.month, d.day);

int _yilinGunu(DateTime d) => d.difference(DateTime(d.year)).inDays;

// ── 1) Haftanın en çok görüntülenen ilanları ─────────────────────────────────
//
// Görüntülenme sayısı ilan kartındaki animasyonlu sayaçla aynı kaynaktan
// (`goruntulenmeSayisi`) beslenir. İstek/taşıyıcı karışık, en yüksekten sıralı.

@riverpod
List<IlanModel> kesfetEnCokGoruntulenen(Ref ref) {
  final liste = _tumIlanlar(ref)
      .where((i) => i.goruntulenmeSayisi > 0)
      .toList()
    ..sort((a, b) => b.goruntulenmeSayisi.compareTo(a.goruntulenmeSayisi));
  return liste.take(10).toList();
}

// ── 2) Haftanın en çok favorilenen ilanları ──────────────────────────────────
//
// Favori sayısı ilan kartındaki animasyonlu favori sayacıyla aynı kaynaktan
// (`favoriSayisi`) beslenir. İstek/taşıyıcı karışık, en yüksekten sıralı.

@riverpod
List<IlanModel> kesfetEnCokFavorilenen(Ref ref) {
  final liste = _tumIlanlar(ref)
      .where((i) => i.favoriSayisi > 0)
      .toList()
    ..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi));
  return liste.take(10).toList();
}

// ── 3) Bugün eklenen ilanlar ──────────────────────────────────────────────────
//
// Son 24 saatte eklenen, istek/taşıyıcı karışık ilanlar. Oluşturma sırasını
// bozacak şekilde rastgele karıştırılır; tohum gün bazlı olduğundan sıra gün
// içinde sabit kalır (yeniden build'lerde kartlar zıplamaz), ertesi gün değişir.

@riverpod
List<IlanModel> kesfetBugunEklenen(Ref ref) {
  final esik  = DateTime.now().subtract(const Duration(hours: 24));
  final liste = _tumIlanlar(ref)
      .where((i) =>
          i.olusturmaTarihi != null && i.olusturmaTarihi!.isAfter(esik))
      .toList();

  final simdi = DateTime.now();
  final tohum = simdi.year * 1000 + _yilinGunu(simdi);
  liste.shuffle(Random(tohum));

  return liste.take(15).toList();
}

// ── 4) Yakın zamanda Türkiye'ye gelecekler ────────────────────────────────────
//
// Taşıyıcı (gelen) ilanlarından seyahat tarihi bugünden itibaren 0–7 gün
// aralığında olanlar. En yakın tarih en başta.

@riverpod
List<IlanModel> kesfetYakinGelecekler(Ref ref) {
  final tasiyici = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final bugun    = _gunBaslangici(DateTime.now());

  final liste = tasiyici.where((i) {
    if (i.tarih == null) return false;
    final fark = _gunBaslangici(i.tarih!).difference(bugun).inDays;
    return fark >= 0 && fark <= 7;
  }).toList()
    ..sort((a, b) => a.tarih!.compareTo(b.tarih!));

  return liste;
}

// ── 5) Bugün yola çıkacaklar – Duty Free fırsatları ───────────────────────────
//
// Taşıyıcı (gelen) ilanlarından seyahat tarihi şu andan itibaren 24 saat
// içinde olan VE ilan sahibi kayıt sırasında "Duty Free alışverişi ile
// ilgileniyor musun?" sorusuna evet demiş (`sahipDutyFree`) olanlar.

@riverpod
List<IlanModel> kesfetDutyFree(Ref ref) {
  final tasiyici = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final simdi    = DateTime.now();
  final sinir    = simdi.add(const Duration(hours: 24));

  final liste = tasiyici.where((i) =>
      i.sahipDutyFree &&
      i.tarih != null &&
      i.tarih!.isAfter(simdi) &&
      i.tarih!.isBefore(sinir)).toList()
    ..sort((a, b) => a.tarih!.compareTo(b.tarih!));

  return liste;
}

// ── 6) Hero Banner — son 7 günde eklenen + en çok görüntülenen ───────────────
//
// Son 7 günde eklenen ilanlardan görüntülenme sayısına göre sıralanmış ilk 15.
// Bu hafta yeni + popüler kombinasyonu.

@riverpod
List<IlanModel> kesfetHeroBanner(Ref ref) {
  final esik = DateTime.now().subtract(const Duration(days: 7));
  final liste = _tumIlanlar(ref)
      .where((i) => i.olusturmaTarihi != null && i.olusturmaTarihi!.isAfter(esik))
      .toList()
    ..sort((a, b) => b.goruntulenmeSayisi.compareTo(a.goruntulenmeSayisi));

  // Eğer son 7 günde yeterli ilan yoksa genel en çok görüntülenenlerle tamamla
  if (liste.length >= 10) return liste.take(15).toList();

  final seen = <String>{...liste.map((i) => i.id)};
  final ek = _tumIlanlar(ref)
      .where((i) => seen.add(i.id))
      .toList()
    ..sort((a, b) => b.goruntulenmeSayisi.compareTo(a.goruntulenmeSayisi));

  return [...liste, ...ek].take(15).toList();
}

// ── 7) Önerilen ilanlar — favori/görüntülenme/güven/tazelik/resim ağırlıklı ──
//
// Cloud Functions'taki onerilenPuanHesapla ile aynı formül, client-side
// (model'e ekstra alan eklemeden) hesaplanır: favori×3 + görüntülenme×1 +
// kullanıcıPuan×5 + tazelik(24s=10/3g=6/7g=3/30g=1) + resim sayısı puanı.
// 30 ilan döner; ekrana 2 satır (15+15) olarak bölünür.

double _onerilenPuanHesapla(IlanModel i) {
  final simdi  = DateTime.now();
  final gunFark = i.olusturmaTarihi == null
      ? 999.0
      : simdi.difference(i.olusturmaTarihi!).inHours / 24.0;
  double tazelik = 0;
  if (gunFark < 1) {
    tazelik = 10;
  } else if (gunFark < 3) {
    tazelik = 6;
  } else if (gunFark < 7) {
    tazelik = 3;
  } else if (gunFark < 30) {
    tazelik = 1;
  }
  final resimSayisi = i.resimUrller.length;
  double resimPuan = 0;
  if (resimSayisi >= 5) {
    resimPuan = 5;
  } else if (resimSayisi >= 3) {
    resimPuan = 3;
  } else if (resimSayisi >= 1) {
    resimPuan = 1;
  }
  return i.favoriSayisi * 3 +
      i.goruntulenmeSayisi * 1 +
      i.kullaniciPuan * 5 +
      tazelik +
      resimPuan;
}

@riverpod
List<IlanModel> kesfetOnerilenIlanlar(Ref ref) {
  final liste = _tumIlanlar(ref).toList()
    ..sort((a, b) => _onerilenPuanHesapla(b).compareTo(_onerilenPuanHesapla(a)));
  return liste.take(30).toList();
}

// ── 8) En yeni ilanlar ────────────────────────────────────────────────────────
//
// Oluşturma tarihine göre en yeniden eskiye. 30 ilan döner; ekranda bölüm
// başlığı "en yeni" ya da "önerilen" ifadesini kullanmayacak şekilde sunulur.

@riverpod
List<IlanModel> kesfetEnYeniIlanlar(Ref ref) {
  final liste = _tumIlanlar(ref)
      .where((i) => i.olusturmaTarihi != null)
      .toList()
    ..sort((a, b) => b.olusturmaTarihi!.compareTo(a.olusturmaTarihi!));
  return liste.take(30).toList();
}

// ── 9) En eski ilanlar ────────────────────────────────────────────────────────
//
// Oluşturma tarihine göre en eskiden yeniye. Sayfada iki ayrı yerde
// kullanılıyor (1 satır + 2 satır) — ilk 15'i birinci yer, sonraki 30'u
// ikinci yer kullanır, böylece aynı ilanlar tekrar etmez.

@riverpod
List<IlanModel> kesfetEnEskiIlanlar(Ref ref) {
  final liste = _tumIlanlar(ref)
      .where((i) => i.olusturmaTarihi != null)
      .toList()
    ..sort((a, b) => a.olusturmaTarihi!.compareTo(b.olusturmaTarihi!));
  return liste.take(45).toList();
}

// ── 10) Rastgele keşfet karması ───────────────────────────────────────────────
//
// Tamamen karışık kategori örnekleri. Tohum gün bazlı (kesfetBugunEklenen ile
// aynı yaklaşım) — gün içinde sabit, ertesi gün değişir.

@riverpod
List<IlanModel> kesfetRastgeleKarma(Ref ref) {
  final liste = _tumIlanlar(ref).toList();
  final simdi = DateTime.now();
  final tohum = simdi.year * 1000 + _yilinGunu(simdi) + 7; // farklı tohum, bugunEklenen ile aynı sıralamayı vermesin
  liste.shuffle(Random(tohum));
  return liste.take(30).toList();
}