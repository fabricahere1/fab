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
      .take(5)
      .toList();
}

// ── Şu an havada (bu hafta içinde) ───────────────────────────────────────────

@riverpod
List<IlanModel> suAnHavadaIlanlar(Ref ref) {
  final liste   = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final simdi   = DateTime.now();
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
  final istekler    = ref.watch(istekIlanlarProvider).filtrelenmis;
  final tasiyicilar = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final liste       = [...istekler, ...tasiyicilar];
  final sayac       = <String, int>{};
  for (final ilan in liste) {
    if (ilan.nereden.isEmpty || ilan.nereye.isEmpty) continue;
    final anahtar = '${ilan.nereden}||${ilan.nereye}';
    sayac[anahtar] = (sayac[anahtar] ?? 0) + 1;
  }
  final sirali = (sayac.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .take(6);
  return sirali.map((e) {
    final p = e.key.split('||');
    return GuzergahSatiri(
      nereden:    p[0],
      nereye:     p.length > 1 ? p[1] : '',
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
      .take(20)
      .toList();
}

// ── Son 1 saatte eklenenler (Flash ilanlar) ───────────────────────────────────

@riverpod
List<IlanModel> flashIlanlar(Ref ref) {
  final liste   = ref.watch(sonAktivitelerProvider);
  final birSaat = DateTime.now().subtract(const Duration(hours: 1));
  return liste
      .where((i) =>
          i.olusturmaTarihi != null &&
          i.olusturmaTarihi!.isAfter(birSaat))
      .take(10)
      .toList();
}

// ── Son anlaşmalar (islemDurumu ANLASILDI olanlar) ────────────────────────────

@riverpod
List<IlanModel> sonAnlasmalar(Ref ref) {
  // Firestore'dan anlaşılan sohbetleri çeken ayrı bir provider
  // olana kadar boş liste döndürür — ileride doldurulur.
  return [];
}

// ── İstatistikler ─────────────────────────────────────────────────────────────

class KesfetIstatistik {
  final int toplamAktif;
  final int bugunEklenen;
  final int suAnYolda;
  const KesfetIstatistik({
    required this.toplamAktif,
    required this.bugunEklenen,
    required this.suAnYolda,
  });
}

@riverpod
KesfetIstatistik kesfetIstatistik(Ref ref) {
  final tumIlanlar = ref.watch(sonAktivitelerProvider);
  final havada     = ref.watch(suAnHavadaIlanlarProvider);
  final simdi      = DateTime.now();
  final bugun      = DateTime(simdi.year, simdi.month, simdi.day);
  return KesfetIstatistik(
    toplamAktif:  tumIlanlar.length,
    bugunEklenen: tumIlanlar
        .where((i) =>
            i.olusturmaTarihi != null &&
            !i.olusturmaTarihi!.isBefore(bugun))
        .length,
    suAnYolda: havada.length,
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

// ── Trend kategoriler ─────────────────────────────────────────────────────────

class TrendKategori {
  final String key;
  final String ad;
  final String emoji;
  final int ilanSayisi;
  final double degisimYuzdesi;

  const TrendKategori({
    required this.key,
    required this.ad,
    required this.emoji,
    required this.ilanSayisi,
    required this.degisimYuzdesi,
  });
}

const _kEmojiler = <String, String>{
  'elektronik': '📱', 'giyim': '👗', 'kozmetik': '💄',
  'ev':         '🏠', 'oyun':  '🎮', 'kitap':    '📚',
  'spor':       '⚽', 'bebek': '👶', 'gida':     '🍎',
  'diger':      '📦',
};

const _kAdlar = <String, String>{
  'elektronik': 'Elektronik', 'giyim': 'Giyim',    'kozmetik': 'Kozmetik',
  'ev':         'Ev & Yaşam', 'oyun':  'Oyun',      'kitap':    'Kitap',
  'spor':       'Spor',       'bebek': 'Bebek',     'gida':     'Gıda',
  'diger':      'Diğer',
};

@riverpod
List<TrendKategori> trendKategoriler(Ref ref) {
  final istekler    = ref.watch(istekIlanlarProvider).filtrelenmis;
  final tasiyicilar = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
  final tumIlanlar  = [...istekler, ...tasiyicilar];

  final simdi        = DateTime.now();
  final haftaOnce    = simdi.subtract(const Duration(days: 7));
  final ikiHaftaOnce = simdi.subtract(const Duration(days: 14));

  final buHaftaSayac    = <String, int>{};
  final gecenHaftaSayac = <String, int>{};

  for (final i in tumIlanlar) {
    final kat = i.anaKategori.isNotEmpty ? i.anaKategori : i.kategori;
    if (kat.isEmpty) continue;
    if (i.olusturmaTarihi != null && i.olusturmaTarihi!.isAfter(haftaOnce)) {
      buHaftaSayac[kat] = (buHaftaSayac[kat] ?? 0) + 1;
    } else if (i.olusturmaTarihi != null &&
        i.olusturmaTarihi!.isAfter(ikiHaftaOnce)) {
      gecenHaftaSayac[kat] = (gecenHaftaSayac[kat] ?? 0) + 1;
    }
  }

  // Veri yoksa tüm ilanlardan hesapla
  final kaynak = buHaftaSayac.isNotEmpty
      ? buHaftaSayac
      : () {
          final m = <String, int>{};
          for (final i in tumIlanlar) {
            final k = i.anaKategori.isNotEmpty ? i.anaKategori : i.kategori;
            if (k.isNotEmpty) m[k] = (m[k] ?? 0) + 1;
          }
          return m;
        }();

  return (kaynak.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .take(4)
      .map((e) {
        final onceki = gecenHaftaSayac[e.key] ?? 0;
        final degisim = onceki == 0
            ? 0.0
            : ((e.value - onceki) / onceki) * 100;
        return TrendKategori(
          key:             e.key,
          ad:              _kAdlar[e.key] ?? e.key,
          emoji:           _kEmojiler[e.key] ?? '📦',
          ilanSayisi:      e.value,
          degisimYuzdesi:  degisim,
        );
      })
      .toList();
}

// ── En çok istenen ürün (spotlight) ──────────────────────────────────────────

class SpotlightIlan {
  final IlanModel ilan;
  final int istemeSayisi;
  const SpotlightIlan({required this.ilan, required this.istemeSayisi});
}

@riverpod
SpotlightIlan? spotlightIlan(Ref ref) {
  final liste = ref.watch(istekIlanlarProvider).filtrelenmis;
  if (liste.isEmpty) return null;
  final sirali = [...liste]
    ..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi));
  final en = sirali.first;

  // Aynı ürün adına sahip kaç istek var
  final istemeSayisi = liste
      .where((i) => i.urun.toLowerCase() == en.urun.toLowerCase())
      .length;

  return SpotlightIlan(ilan: en, istemeSayisi: istemeSayisi);
}