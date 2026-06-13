// lib/features/home/providers/kesfet_computed_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';

part 'kesfet_computed_providers.g.dart';

// ── Öne çıkanlar ─────────────────────────────────────────────────────────────

@riverpod
List<IlanModel> oneCikanIlanlar(Ref ref) {
  final liste = ref.watch(istekIlanlarProvider).filtrelenmis;
  return ([...liste]
        ..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi)))
      .take(8)
      .toList();
}

// ── Yakında gelenler ──────────────────────────────────────────────────────────

@riverpod
List<IlanModel> yakinGelenIlanlar(Ref ref) {
  final liste = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final simdi = DateTime.now();
  return (liste
        .where((i) => i.tarih != null && i.tarih!.isAfter(simdi))
        .toList()
        ..sort((a, b) => a.tarih!.compareTo(b.tarih!)))
      .take(4)
      .toList();
}

// ── Şu an havada ─────────────────────────────────────────────────────────────

@riverpod
List<IlanModel> suAnHavadaIlanlar(Ref ref) {
  final liste  = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final simdi  = DateTime.now();
  final yediGun = simdi.add(const Duration(days: 7));
  return (liste
        .where((i) =>
            i.tarih != null &&
            i.tarih!.isAfter(simdi) &&
            i.tarih!.isBefore(yediGun))
        .toList()
        ..sort((a, b) => a.tarih!.compareTo(b.tarih!)))
      .take(5)
      .toList();
}

// ── Popüler güzergahlar ───────────────────────────────────────────────────────

class GuzergahSatiri {
  final String nereden;
  final String nereye;
  final int ilanSayisi;
  const GuzergahSatiri({
    required this.nereden,
    required this.nereye,
    required this.ilanSayisi,
  });
  String get etiket => '$nereden → $nereye';
}

@riverpod
List<GuzergahSatiri> populerGuzergahlar(Ref ref) {
  final liste = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final sayac = <String, int>{};
  for (final ilan in liste) {
    if (ilan.nereden.isEmpty || ilan.nereye.isEmpty) continue;
    final anahtar = '${ilan.nereden}||${ilan.nereye}';
    sayac[anahtar] = (sayac[anahtar] ?? 0) + 1;
  }
  final sirali = (sayac.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .take(5);
  return sirali.map((e) {
    final parcalar = e.key.split('||');
    return GuzergahSatiri(
      nereden:    parcalar[0],
      nereye:     parcalar.length > 1 ? parcalar[1] : '',
      ilanSayisi: e.value,
    );
  }).toList();
}

// ── Trend istekler ────────────────────────────────────────────────────────────

@riverpod
List<IlanModel> trendIstekler(Ref ref) {
  final liste = ref.watch(istekIlanlarProvider).filtrelenmis;
  return ([...liste]
        ..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi)))
      .take(6)
      .toList();
}

// ── Son aktiviteler ───────────────────────────────────────────────────────────

@riverpod
List<IlanModel> sonAktiviteler(Ref ref) {
  final istekler    = ref.watch(istekIlanlarProvider).filtrelenmis;
  final tasiyicilar = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  return ([...istekler, ...tasiyicilar]
        ..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
            .compareTo(a.olusturmaTarihi ?? DateTime(0))))
      .take(10)
      .toList();
}

// ── İstatistikler ─────────────────────────────────────────────────────────────

class KesfetIstatistik {
  final int toplamAktif;
  final int bugunEklenen;
  final int buHaftaEklenen;
  const KesfetIstatistik({
    required this.toplamAktif,
    required this.bugunEklenen,
    required this.buHaftaEklenen,
  });
}

@riverpod
KesfetIstatistik kesfetIstatistik(Ref ref) {
  final tumIlanlar = ref.watch(sonAktivitelerProvider);
  final simdi      = DateTime.now();
  final bugun      = DateTime(simdi.year, simdi.month, simdi.day);
  final haftaOnce  = simdi.subtract(const Duration(days: 7));
  return KesfetIstatistik(
    toplamAktif: tumIlanlar.length,
    bugunEklenen: tumIlanlar
        .where((i) =>
            i.olusturmaTarihi != null &&
            !i.olusturmaTarihi!.isBefore(bugun))
        .length,
    buHaftaEklenen: tumIlanlar
        .where((i) =>
            i.olusturmaTarihi != null &&
            i.olusturmaTarihi!.isAfter(haftaOnce))
        .length,
  );
}

// ── Ülke bazlı ilan sayıları ──────────────────────────────────────────────────

@riverpod
Map<String, int> ulkeIlanSayilari(Ref ref) {
  final liste = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final sayac = <String, int>{};
  for (final ilan in liste) {
    final nereden = ilan.nereden.trim();
    if (nereden.isNotEmpty) {
      sayac[nereden] = (sayac[nereden] ?? 0) + 1;
    }
  }
  return sayac;
}
