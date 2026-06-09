// lib/features/home/providers/kesfet_vitrin2_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';

part 'kesfet_vitrin2_providers.g.dart';

// ── Model: Güzergah (ilanlar dahil) ─────────────────────────────────────────

class Guzergah {
  final String nereden;
  final String nereye;
  final List<IlanModel> ilanlar;
  int get ilanSayisi => ilanlar.length;
  const Guzergah({required this.nereden, required this.nereye, required this.ilanlar});
}

// ── Model: Şehir ─────────────────────────────────────────────────────────────

class SehirSatiri {
  final String sehir;
  final int ilanSayisi;
  const SehirSatiri({required this.sehir, required this.ilanSayisi});
}

// ── Model: Trend Ürün ────────────────────────────────────────────────────────

class TrendUrun {
  final String ad;
  final List<IlanModel> ilanlar;
  const TrendUrun({required this.ad, required this.ilanlar});
}

// ── 1) Trend ürünler ─────────────────────────────────────────────────────────

@riverpod
List<TrendUrun> kesfetTrendUrunler(Ref ref) {
  final istek = ref.watch(istekIlanlarProvider).filtrelenmis;

  final gruplar = <String, List<IlanModel>>{};
  for (final ilan in istek) {
    if (ilan.urun.trim().length < 3) continue;
    final urun = ilan.urun.trim();
    gruplar.putIfAbsent(urun, () => []).add(ilan);
  }

  final sirali = gruplar.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  return sirali.take(15).map((e) => TrendUrun(ad: e.key, ilanlar: e.value)).toList();
}

// ── 2) Popüler güzergahlar (ilanlarıyla birlikte) ────────────────────────────

@riverpod
List<Guzergah> kesfetPopulerGuzergahlar(Ref ref) {
  final tasiyici = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;

  final gruplar = <String, List<IlanModel>>{};
  final anahtarBilgi = <String, Map<String, String>>{};

  for (final ilan in tasiyici) {
    if (ilan.nereden.isEmpty || ilan.nereye.isEmpty) continue;
    final anahtar =
        '${ilan.nereden.trim().toLowerCase()}→${ilan.nereye.trim().toLowerCase()}';
    gruplar.putIfAbsent(anahtar, () => []).add(ilan);
    anahtarBilgi.putIfAbsent(anahtar, () => {
      'nereden': ilan.nereden.trim(),
      'nereye': ilan.nereye.trim(),
    });
  }

  final sirali = gruplar.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  return sirali.take(10).map((e) {
    final bilgi = anahtarBilgi[e.key]!;
    return Guzergah(
      nereden: bilgi['nereden']!,
      nereye: bilgi['nereye']!,
      ilanlar: e.value,
    );
  }).toList();
}

// ── 3) Bu hafta hangi şehirlerden geliyor ────────────────────────────────────

@riverpod
List<SehirSatiri> kesfetBuHaftaSehirler(Ref ref) {
  final tasiyici = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final bugun = DateTime.now();
  final haftaSonu = bugun.add(const Duration(days: 7));

  final frekans = <String, int>{};
  for (final ilan in tasiyici) {
    if (ilan.nereden.isEmpty || ilan.tarih == null) continue;
    if (ilan.tarih!.isBefore(bugun.subtract(const Duration(days: 1)))) continue;
    if (ilan.tarih!.isAfter(haftaSonu)) continue;
    final sehir = ilan.nereden.trim();
    frekans[sehir] = (frekans[sehir] ?? 0) + 1;
  }

  final sirali = frekans.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sirali.take(10)
      .map((e) => SehirSatiri(sehir: e.key, ilanSayisi: e.value))
      .toList();
}