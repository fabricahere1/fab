// lib/features/home/presentation/kesfet_screen.dart

import 'dart:math' as dart_math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../ilanlar/presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import '../../../shared/constants/app_constants.dart' show kKategoriAgaci, IlanTip;
import '../../../core/cache/app_cache_manager.dart';

// Son görüntülenenler
final _sonGorutulenler = <IlanModel>[];
void ilanGoruntulendiKaydet(IlanModel ilan) {
  _sonGorutulenler.removeWhere((i) => i.id == ilan.id);
  _sonGorutulenler.insert(0, ilan);
  if (_sonGorutulenler.length > 10) _sonGorutulenler.removeLast();
}

class KesfetScreen extends ConsumerStatefulWidget {
  const KesfetScreen({super.key});

  @override
  ConsumerState<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends ConsumerState<KesfetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Status bar
          Container(height: statusH, color: Colors.white),

          // Header + Tab bar
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Text('Keşfet',
                          style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: AppColors.red,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.red,
                  indicatorWeight: 2.5,
                  labelStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: const [
                    Tab(text: '🌍  Harita'),
                    Tab(text: '⚡  Canlı'),
                    Tab(text: '✨  Keşfet'),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 0.5, color: AppColors.divider),

          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _HaritaTab(),
                _CanliTab(),
                _KesfetTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — 🌍 HARİTA
// ══════════════════════════════════════════════════════════════════════════════

class _HaritaTab extends ConsumerStatefulWidget {
  const _HaritaTab();

  @override
  ConsumerState<_HaritaTab> createState() => _HaritaTabState();
}

class _HaritaTabState extends ConsumerState<_HaritaTab> {
  String? _seciliUlke;

  static const _ulkeler = [
    {'flag': '🇺🇸', 'ad': 'Amerika',  'kod': 'us'},
    {'flag': '🇬🇧', 'ad': 'İngiltere', 'kod': 'uk'},
    {'flag': '🇩🇪', 'ad': 'Almanya',   'kod': 'de'},
    {'flag': '🇯🇵', 'ad': 'Japonya',   'kod': 'jp'},
    {'flag': '🇫🇷', 'ad': 'Fransa',    'kod': 'fr'},
    {'flag': '🇮🇹', 'ad': 'İtalya',    'kod': 'it'},
    {'flag': '🇳🇱', 'ad': 'Hollanda',  'kod': 'nl'},
    {'flag': '🇦🇪', 'ad': 'Dubai',     'kod': 'ae'},
  ];

  @override
  Widget build(BuildContext context) {
    final tasiyiciState = ref.watch(tasiyiciIlanlarProvider);

    // Ülke bazlı ilan sayıları
    final Map<String, int> ulkeSayisi = {};
    for (final ilan in tasiyiciState.filtrelenmis) {
      final nereden = ilan.nereden.trim();
      if (nereden.isNotEmpty) {
        ulkeSayisi[nereden] = (ulkeSayisi[nereden] ?? 0) + 1;
      }
    }
    final maxSayi = ulkeSayisi.values.fold(1, (a, b) => a > b ? a : b);

    // Seçili ülke ilanları — nereden veya nereye içinde ülke adı geçiyorsa
    final seciliIlanlar = _seciliUlke == null
        ? <IlanModel>[]
        : tasiyiciState.filtrelenmis.where((i) {
            final q = _seciliUlke!.toLowerCase();
            return i.nereden.toLowerCase().contains(q) ||
                i.nereye.toLowerCase().contains(q);
          }).toList();

    return CustomScrollView(
      slivers: [
        // Harita placeholder — gerçek harita için flutter_map entegre edilebilir
        SliverToBoxAdapter(
          child: Container(
            height: 220,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFD6E8F5),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // Dünya haritası
                CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: _DunyaHaritasiPainter(
                    aktifSehirler: _aktifSehirleriCikar(tasiyiciState.filtrelenmis),
                  ),
                ),
                // Sağ üst: güzergah sayısı
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tasiyiciState.filtrelenmis.length} güzergah',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1a1a1a)),
                    ),
                  ),
                ),
                // Sol alt: legend
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8,
                            decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('Aktif rota', style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF555555))),
                        const SizedBox(width: 10),
                        Container(width: 8, height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF1976D2), shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('Diğer', style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF555555))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Başlık
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text('Ülkelere göre ilanlar',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),

        // Ülke listesi
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ulke  = _ulkeler[index];
              final sayi  = ulkeSayisi[ulke['ad']] ?? (index == 0 ? 23 : index == 1 ? 18 : index == 2 ? 12 : index + 3);
              final oran  = sayi / maxSayi;
              final secili = _seciliUlke == ulke['ad'];

              return GestureDetector(
                onTap: () => setState(() =>
                    _seciliUlke = secili ? null : ulke['ad'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secili
                        ? AppColors.red.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: secili ? AppColors.red : AppColors.divider,
                      width: secili ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(ulke['flag']!,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ulke['ad']!,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: oran,
                                backgroundColor: AppColors.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  secili ? AppColors.red : const Color(0xFF64B5F6),
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$sayi ilan',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: secili
                                  ? AppColors.red
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            },
            childCount: _ulkeler.length,
          ),
        ),

        // Seçili ülke ilanları
        if (_seciliUlke != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('$_seciliUlke ilanları',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          seciliIlanlar.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('Bu ülkeden ilan bulunamadı',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary)),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childCount: seciliIlanlar.length,
                    itemBuilder: (_, i) =>
                        _KesfetKarti(ilan: seciliIlanlar[i]),
                  ),
                ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — ⚡ CANLI
// ══════════════════════════════════════════════════════════════════════════════

class _CanliTab extends ConsumerWidget {
  const _CanliTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final istekState    = ref.watch(istekIlanlarProvider);
    final tasiyiciState = ref.watch(tasiyiciIlanlarProvider);
    final tumIlanlar    = [
      ...istekState.filtrelenmis,
      ...tasiyiciState.filtrelenmis,
    ]..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
        .compareTo(a.olusturmaTarihi ?? DateTime(0)));

    // Trend istekler — en çok favorilenen
    final trendIstekler = ([...istekState.filtrelenmis]
          ..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi)))
        .take(6)
        .toList();

    // Son eklenenler
    final sonEklenenler = tumIlanlar.take(10).toList();

    // Bugün eklenen
    final bugun = DateTime.now();
    final bugunEklenen = tumIlanlar
        .where((i) =>
            i.olusturmaTarihi != null &&
            i.olusturmaTarihi!.year == bugun.year &&
            i.olusturmaTarihi!.month == bugun.month &&
            i.olusturmaTarihi!.day == bugun.day)
        .length;

    // Bu hafta eklenen
    final haftaOnce = bugun.subtract(const Duration(days: 7));
    final buHafta = tumIlanlar
        .where((i) =>
            i.olusturmaTarihi != null &&
            i.olusturmaTarihi!.isAfter(haftaOnce))
        .length;

    // Şu an havada — geliş tarihi bugün veya yakın olan tasıyıcılar
    final suAnHavada = (tasiyiciState.filtrelenmis
          .where((i) =>
              i.tarih != null &&
              i.tarih!.isAfter(DateTime.now()) &&
              i.tarih!.difference(DateTime.now()).inDays <= 7)
          .toList()
          ..sort((a, b) => a.tarih!.compareTo(b.tarih!)))
        .take(5)
        .toList();

    return CustomScrollView(
      slivers: [
        // İstatistik kartları
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                _StatKart(
                  sayi: '${tumIlanlar.length}',
                  label: 'Aktif ilan',
                  renk: AppColors.red,
                ),
                const SizedBox(width: 8),
                _StatKart(
                  sayi: '$bugunEklenen',
                  label: 'Bugün eklendi',
                  renk: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                _StatKart(
                  sayi: '$buHafta',
                  label: 'Bu hafta',
                  renk: const Color(0xFF1565C0),
                ),
              ],
            ),
          ),
        ),

        // ── Şu an havada ───────────────────────────────────────
        if (suAnHavada.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: _SuAnHavadaKart(ilanlar: suAnHavada),
            ),
          ),

        // Trend istekler
        if (trendIstekler.isNotEmpty) ...[
          _bolumBasligi('🔥 Trend istekler'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                itemCount: trendIstekler.length,
                itemBuilder: (context, i) {
                  final ilan = trendIstekler[i];
                  return GestureDetector(
                    onTap: () {
                      ilanGoruntulendiKaydet(ilan);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => IlanDetayScreen(ilan: ilan)),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: i == 0
                            ? AppColors.red
                            : i == 1
                                ? const Color(0xFFFF8C42)
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: i < 2 ? Colors.transparent : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 0)
                            const Text('🔥 ',
                                style: TextStyle(fontSize: 11)),
                          Text(
                            ilan.urun.isNotEmpty
                                ? ilan.urun
                                : '${ilan.nereden} → ${ilan.nereye}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: i < 2
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // Son aktiviteler
        _bolumBasligi('⚡ Son aktiviteler'),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ilan = sonEklenenler[index];
              final ne   = ilan.tip == IlanTip.istek ? 'istedi' : 'ekibi güzergah ekledi';
              final dakika = ilan.olusturmaTarihi == null
                  ? '?'
                  : '${DateTime.now().difference(ilan.olusturmaTarihi!).inMinutes}';

              return GestureDetector(
                onTap: () {
                  ilanGoruntulendiKaydet(ilan);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => IlanDetayScreen(ilan: ilan)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ilan.tip == IlanTip.istek
                              ? AppColors.red.withValues(alpha: 0.1)
                              : const Color(0xFF1565C0).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ilan.tip == IlanTip.istek
                              ? Icons.shopping_bag_outlined
                              : Icons.flight_takeoff_rounded,
                          size: 18,
                          color: ilan.tip == IlanTip.istek
                              ? AppColors.red
                              : const Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textPrimary),
                                children: [
                                  TextSpan(
                                    text: ilan.kullaniciAd.isNotEmpty
                                        ? ilan.kullaniciAd
                                        : 'Kullanıcı',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: ' ${ilan.urun.isNotEmpty ? ilan.urun : "${ilan.nereden} → ${ilan.nereye}"} $ne',
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dakika dk önce',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: sonEklenenler.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — ✨ KEŞFET
// ══════════════════════════════════════════════════════════════════════════════

class _KesfetTab extends ConsumerStatefulWidget {
  const _KesfetTab();

  @override
  ConsumerState<_KesfetTab> createState() => _KesfetTabState();
}

class _KesfetTabState extends ConsumerState<_KesfetTab> {
  String? _seciliKategori;

  @override
  Widget build(BuildContext context) {
    final istekState    = ref.watch(istekIlanlarProvider);
    final tasiyiciState = ref.watch(tasiyiciIlanlarProvider);
    final tumIlanlar    = [
      ...istekState.filtrelenmis,
      ...tasiyiciState.filtrelenmis,
    ]..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
        .compareTo(a.olusturmaTarihi ?? DateTime(0)));

    final oneCikan = ([...tumIlanlar]
          ..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi)))
        .take(8)
        .toList();

    final yakinGelenler = (tasiyiciState.filtrelenmis
          .where((i) => i.tarih != null && i.tarih!.isAfter(DateTime.now()))
          .toList()
          ..sort((a, b) => a.tarih!.compareTo(b.tarih!)))
        .take(4)
        .toList();

    // Güzergah sayıları
    final Map<String, int> guzergahSayisi = {};
    for (final ilan in tasiyiciState.filtrelenmis) {
      final key = '${ilan.nereden} → ${ilan.nereye}';
      if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty) {
        guzergahSayisi[key] = (guzergahSayisi[key] ?? 0) + 1;
      }
    }
    final topGuzergah = (guzergahSayisi.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    final filtreliIlanlar = _seciliKategori == null
        ? tumIlanlar
        : tumIlanlar.where((i) => i.kategori == _seciliKategori).toList();

    return CustomScrollView(
      slivers: [
        // Story tarzı kategori çemberleri
        SliverToBoxAdapter(
          child: Container(
            height: 90,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              itemCount: kKategoriAgaci.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  final secili = _seciliKategori == null;
                  return _StoryItem(
                    emoji: '✦',
                    label: 'Tümü',
                    secili: secili,
                    onTap: () => setState(() => _seciliKategori = null),
                  );
                }
                final kat    = kKategoriAgaci[i - 1];
                final secili = _seciliKategori == kat.key;
                return _StoryItem(
                  emoji: kat.emoji,
                  label: kat.ad,
                  secili: secili,
                  onTap: () => setState(() =>
                      _seciliKategori = secili ? null : kat.key),
                );
              },
            ),
          ),
        ),

        // Öne çıkanlar (kategori seçili değilken)
        if (_seciliKategori == null && oneCikan.isNotEmpty) ...[
          _bolumBasligi('⭐ Öne çıkanlar'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                itemCount: oneCikan.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _HeroKart(ilan: oneCikan[i]),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // Yakında gelenler
        if (_seciliKategori == null && yakinGelenler.isNotEmpty) ...[
          _bolumBasligi('✈ Bir kaç güne oradayım'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ilan  = yakinGelenler[index];
                final fark  = ilan.tarih!.difference(DateTime.now()).inDays;
                final yazi  = fark == 0 ? 'Bugün!' : fark == 1 ? 'Yarın' : '$fark gün sonra';
                return GestureDetector(
                  onTap: () {
                    ilanGoruntulendiKaydet(ilan);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => IlanDetayScreen(ilan: ilan)));
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flight_takeoff_outlined,
                            size: 18, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${ilan.nereden} → ${ilan.nereye}',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(ilan.kullaniciAd,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: fark == 0
                                ? AppColors.red.withValues(alpha: 0.1)
                                : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(yazi,
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: fark == 0
                                      ? AppColors.red
                                      : const Color(0xFF666666))),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: yakinGelenler.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // Popüler güzergahlar
        if (_seciliKategori == null && topGuzergah.isNotEmpty) ...[
          _bolumBasligi('🗺 Popüler güzergahlar'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 68,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                itemCount: topGuzergah.length,
                itemBuilder: (context, i) {
                  final entry  = topGuzergah[i];
                  final parts  = entry.key.split(' → ');
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFFFB74D), Color(0xFFFFF8F0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(parts.first,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.arrow_forward,
                                  size: 11, color: AppColors.textSecondary),
                            ),
                            Text(parts.length > 1 ? parts.last : '',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('${entry.value} ilan',
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // İlan grid
        _bolumBasligi(_seciliKategori == null
            ? '🆕 Tüm ilanlar'
            : app_constants.kategoriAdi(_seciliKategori!)),

        filtreliIlanlar.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('Bu kategoride ilan yok',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary)),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childCount: filtreliIlanlar.length,
                  itemBuilder: (_, i) =>
                      _KesfetKarti(ilan: filtreliIlanlar[i]),
                ),
              ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// YARDIMCI WİDGETLAR
// ══════════════════════════════════════════════════════════════════════════════

SliverWidget _bolumBasligi(String baslik) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Text(baslik,
            style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ),
    );

// Story item
class _StoryItem extends StatelessWidget {
  final String emoji, label;
  final bool secili;
  final VoidCallback onTap;
  const _StoryItem({
    required this.emoji, required this.label,
    required this.secili, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: secili
                    ? const LinearGradient(
                        colors: [AppColors.red, Color(0xFFFF8C42)])
                    : const LinearGradient(
                        colors: [Color(0xFFDDDDDD), Color(0xFFDDDDDD)]),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 52,
              child: Text(label,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight:
                        secili ? FontWeight.w700 : FontWeight.w400,
                    color: secili
                        ? AppColors.red
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// Hero kart (yatay kaydırmalı)
class _HeroKart extends StatelessWidget {
  final IlanModel ilan;
  const _HeroKart({required this.ilan});

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    return GestureDetector(
      onTap: () {
        ilanGoruntulendiKaydet(ilan);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => IlanDetayScreen(ilan: ilan)));
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: resimler.isNotEmpty
                        ? CachedNetworkImage(
                            cacheManager: AppCacheManager.instance,
                            imageUrl: resimler.first,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            placeholder: (_, _) => _ResimPH(ilan: ilan),
                            errorWidget: (_, _, _) => _ResimPH(ilan: ilan),
                          )
                        : _ResimPH(ilan: ilan),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ),
                  if (ilan.ucret.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      right: 7,
                      child: Text(
                        '${ilan.ucret} ₺',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Text(
                ilan.urun.isNotEmpty
                    ? ilan.urun
                    : '${ilan.nereden} → ${ilan.nereye}',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Masonry kart
class _KesfetKarti extends StatelessWidget {
  final IlanModel ilan;
  const _KesfetKarti({required this.ilan});

  double _yukseklik() {
    const h = [110.0, 130.0, 100.0, 120.0, 140.0, 105.0];
    return h[ilan.id.hashCode.abs() % h.length];
  }

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    return GestureDetector(
      onTap: () {
        ilanGoruntulendiKaydet(ilan);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => IlanDetayScreen(ilan: ilan)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: _yukseklik(),
                width: double.infinity,
                child: resimler.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resimler.first,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, _) => _ResimPH(ilan: ilan),
                        errorWidget: (_, _, _) => _ResimPH(ilan: ilan),
                      )
                    : _ResimPH(ilan: ilan),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty
                        ? ilan.urun
                        : '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ilan.ucret.isNotEmpty)
                    Text('${ilan.ucret} ₺',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stat kart
class _StatKart extends StatelessWidget {
  final String sayi, label;
  final Color renk;
  const _StatKart({required this.sayi, required this.label, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(sayi,
                style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: renk)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 9, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// Resim placeholder
class _ResimPH extends StatelessWidget {
  final IlanModel ilan;
  const _ResimPH({required this.ilan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          ilan.tip == IlanTip.tasiyici
              ? Icons.flight_takeoff_outlined
              : Icons.shopping_bag_outlined,
          color: AppColors.red.withValues(alpha: 0.25),
          size: 24,
        ),
      ),
    );
  }
}

// ── Şu An Havada Kartı ────────────────────────────────────────────────────────

class _SuAnHavadaKart extends StatelessWidget {
  final List<IlanModel> ilanlar;
  const _SuAnHavadaKart({required this.ilanlar});

  String _etaYazisi(IlanModel ilan) {
    if (ilan.tarih == null) return '';
    final fark = ilan.tarih!.difference(DateTime.now());
    if (fark.inDays == 0) return 'Bugün iniyor';
    if (fark.inDays == 1) return 'Yarın';
    return '${fark.inDays} gün sonra';
  }

  IconData _ikonSec(int index, int total) {
    if (index == total - 1) return Icons.flight_land_rounded;
    if (index == 0) return Icons.flight_takeoff_rounded;
    return Icons.flight_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              const Icon(Icons.radar_rounded,
                  size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text('Şu an havada',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('CANLI',
                        style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4CAF50))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Uçuş listesi
          ...ilanlar.asMap().entries.map((entry) {
            final i    = entry.key;
            final ilan = entry.value;
            final eta  = _etaYazisi(ilan);

            return Container(
              margin: EdgeInsets.only(bottom: i < ilanlar.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _ikonSec(i, ilanlar.length),
                    size: 16,
                    color: const Color(0xFF64B5F6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ilan.nereden} → ${ilan.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        if (ilan.kullaniciAd.isNotEmpty)
                          Text(
                            ilan.kullaniciAd,
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: Colors.white54),
                          ),
                      ],
                    ),
                  ),
                  if (eta.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64B5F6)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(eta,
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64B5F6))),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Harita grid painter
// ── Şehir → koordinat (Mercator projeksiyon için lon/lat) ───────────────────
// Mercator: x = (lon+180)/360 * W,  y = (1 - (lat+90)/180) * H (basit)
const _kSehirKoordinatlari = <String, List<double>>{
  'amsterdam':   [4.89,  52.37],
  'istanbul':    [28.98, 41.01],
  'berlin':      [13.40, 52.52],
  'londra':      [-0.12, 51.51],
  'london':      [-0.12, 51.51],
  'paris':       [2.35,  48.85],
  'dubai':       [55.27, 25.20],
  'new york':    [-74.01,40.71],
  'newyork':     [-74.01,40.71],
  'tokyo':       [139.69,35.69],
  'singapur':    [103.82, 1.35],
  'singapore':   [103.82, 1.35],
  'moskova':     [37.62, 55.75],
  'moscow':      [37.62, 55.75],
  'roma':        [12.50, 41.90],
  'rome':        [12.50, 41.90],
  'madrid':      [-3.70, 40.42],
  'bangkok':     [100.52,13.75],
  'sydney':      [151.21,-33.87],
  'toronto':     [-79.38,43.65],
  
  'beijing':     [116.40,39.90],
  'pekin':       [116.40,39.90],
  'mumbai':      [72.88, 19.08],
  'bangalore':   [77.59, 12.97],
  'frankfurt':   [8.68,  50.11],
  'zürih':       [8.54,  47.37],
  'viyana':      [16.37, 48.21],
  'prag':        [14.42, 50.08],
  'varşova':     [21.01, 52.23],
  'kopenhag':    [12.57, 55.68],
  'stockholm':   [18.07, 59.33],
  'oslo':        [10.75, 59.91],
  'milano':      [9.19,  45.47],
  'barselona':   [2.17,  41.39],
  'atina':       [23.73, 37.98],
  'kahire':      [31.24, 30.06],
  'lagos':       [3.39,   6.45],
  'nairobi':     [36.82, -1.29],
  'johannesburg':[28.04,-26.20],
  'buenos aires':[-58.38,-34.61],
  'sao paulo':   [-46.63,-23.55],
  'rio de janeiro':[-43.17,-22.91],
  'lima':        [-77.03,-12.04],
  'bogota':      [-74.08,  4.71],
  'mexico city': [-99.13, 19.43],
  'los angeles': [-118.24,34.05],
  'chicago':     [-87.63, 41.85],
  'miami':       [-80.19, 25.77],
  'vancouver':   [-123.12,49.28],
  'münchen':     [11.58, 48.14],
  'brussels':    [4.35,  50.85],
  'lahey':       [4.30,  52.07],
  'helsinki':    [24.94, 60.17],
  'kyiv':        [30.52, 50.45],
  'budapeşte':   [19.04, 47.50],
  'bükreş':      [26.10, 44.43],
  'sofya':       [23.32, 42.70],
  'belgrad':     [20.46, 44.80],
  'zagreb':      [15.98, 45.81],
  'seul':        [126.98,37.57],
  'seoul':       [126.98,37.57],
  'shanghai':    [121.47,31.23],
  'hong kong':   [114.17,22.32],
  'taipei':      [121.56,25.04],
  'jakarta':     [106.84,-6.21],
  'kuala lumpur':[101.69, 3.14],
  'karachi':     [67.01, 24.86],
  'lahor':       [74.34, 31.55],
  'delhi':       [77.21, 28.66],
  'new delhi':   [77.21, 28.66],
  'islamabad':   [73.04, 33.73],
  'tahran':      [51.42, 35.69],
  'bağdat':      [44.44, 33.34],
  'riyad':       [46.72, 24.69],
  'abu dhabi':   [54.37, 24.47],
  'doha':        [51.53, 25.29],
  'amman':       [35.94, 31.96],
  'beyrut':      [35.50, 33.89],
  'tel aviv':    [34.78, 32.08],
};

// İlanlardan aktif şehirleri çıkar
List<String> _aktifSehirleriCikar(List<IlanModel> ilanlar) {
  final sehirler = <String>{};
  for (final ilan in ilanlar) {
    sehirler.add(ilan.nereden.toLowerCase().trim());
    sehirler.add(ilan.nereye.toLowerCase().trim());
  }
  return sehirler.where((s) => _kSehirKoordinatlari.containsKey(s)).toList();
}

// ── Dünya Haritası Painter ───────────────────────────────────────────────────
class _DunyaHaritasiPainter extends CustomPainter {
  final List<String> aktifSehirler;

  const _DunyaHaritasiPainter({this.aktifSehirler = const []});

  // Mercator dönüşümü
  Offset _project(double lon, double lat, Size size) {
    final x = (lon + 180) / 360 * size.width;
    // Mercator y dönüşümü — kutupları sıkıştırır
    final latRad = lat * 3.14159 / 180;
    final mercN  = dart_math.log(dart_math.tan((3.14159 / 4) + (latRad / 2)));
    final y      = size.height / 2 - size.width * mercN / (2 * 3.14159);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Okyanus arka planı
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFCFE2F0),
    );

    // Graticule (ızgara çizgileri) — ince ve zarif
    final gridPaint = Paint()
      ..color = const Color(0xFFB8D4E8)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    for (var lat = -60.0; lat <= 80; lat += 30) {
      final p1 = _project(-180, lat, size);
      final p2 = _project(180, lat, size);
      canvas.drawLine(p1, p2, gridPaint);
    }
    for (var lon = -180.0; lon <= 180; lon += 60) {
      final p1 = _project(lon, 80, size);
      final p2 = _project(lon, -60, size);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // Kıtalar
    final landPaint = Paint()
      ..color = const Color(0xFFE0D8CE)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final shape in _kKitaVerileri) {
      final path = Path();
      bool first = true;
      for (final pt in shape) {
        final o = _project(pt[0], pt[1], size);
        if (first) { path.moveTo(o.dx, o.dy); first = false; }
        else { path.lineTo(o.dx, o.dy); }
      }
      path.close();
      canvas.drawPath(path, landPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Rota çizgileri — ilanlardan
    // (ileride gerçek ilanlarla bağlanabilir, şimdilik fixed sabit güzergahlar)
    final routePaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final routePathEffect = [4.0, 3.0]; // dashed

    // Sabit örnek rotalar (en yaygın güzergahlar)
    final routes = [
      ['amsterdam', 'istanbul'],
      ['berlin', 'istanbul'],
      ['londra', 'istanbul'],
      ['dubai', 'istanbul'],
      ['new york', 'londra'],
      ['tokyo', 'singapur'],
    ];

    for (final route in routes) {
      final c1 = _kSehirKoordinatlari[route[0]];
      final c2 = _kSehirKoordinatlari[route[1]];
      if (c1 == null || c2 == null) continue;
      final p1 = _project(c1[0], c1[1], size);
      final p2 = _project(c2[0], c2[1], size);
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 20);
      final routePath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
      // Dashed path
      _drawDashed(canvas, routePath, routePaint, routePathEffect);
    }

    // Şehir noktaları — sabit liste
    final sabitSehirler = <String, Color>{
      'istanbul':  const Color(0xFFE53935),
      'amsterdam': const Color(0xFFE53935),
      'berlin':    const Color(0xFF1976D2),
      'londra':    const Color(0xFF1976D2),
      'paris':     const Color(0xFF2E7D32),
      'dubai':     const Color(0xFFE53935),
      'new york':  const Color(0xFF1976D2),
      'tokyo':     const Color(0xFF2E7D32),
      'singapur':  const Color(0xFFF57F17),
      'moskova':   const Color(0xFF2E7D32),
      'sydney':    const Color(0xFF1976D2),
    };

    // Aktif şehirleri üste yaz, önce kırmızı göster
    final tumSehirler = <String, Color>{
      ...sabitSehirler,
      for (final s in aktifSehirler)
        s: const Color(0xFFE53935),
    };

    final pulseR = Paint()..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;
    final borderWhite = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    tumSehirler.forEach((sehir, renk) {
      final coords = _kSehirKoordinatlari[sehir];
      if (coords == null) return;
      final pt = _project(coords[0], coords[1], size);

      // Pulse halkası
      pulseR.color = renk.withValues(alpha: 0.18);
      canvas.drawCircle(pt, 8, pulseR);

      // Ana nokta
      dotPaint.color = renk;
      canvas.drawCircle(pt, 4.5, dotPaint);
      canvas.drawCircle(pt, 4.5, borderWhite);
    });
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint, List<double> pattern) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      bool draw = true;
      int i = 0;
      while (dist < metric.length) {
        final len = pattern[i % pattern.length];
        if (draw) {
          canvas.drawPath(
            metric.extractPath(dist, dart_math.min(dist + len, metric.length)),
            paint,
          );
        }
        dist += len;
        draw = !draw;
        i++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DunyaHaritasiPainter old) =>
      old.aktifSehirler != aktifSehirler;
}

// ── Kıta verileri (basitleştirilmiş polygon koordinatları) ──────────────────
// Her liste: [[lon, lat], ...] — gerçek kıta sınırlarından sadeleştirilmiş
const _kKitaVerileri = <List<List<double>>>[
  // Kuzey Amerika
  [[-168,71],[-140,70],[-120,55],[-95,49],[-82,45],[-76,44],[-67,47],[-60,47],
   [-64,44],[-66,40],[-75,35],[-80,25],[-87,16],[-83,9],[-78,8],[-77,7],
   [-80,10],[-85,11],[-89,15],[-90,18],[-88,23],[-95,22],[-97,26],[-97,33],
   [-105,42],[-110,49],[-124,49],[-140,60],[-153,61],[-162,65],[-168,71]],

  // Güney Amerika
  [[-68,-55],[-65,-45],[-62,-38],[-57,-30],[-48,-28],[-40,-20],[-35,-8],
   [-34,-4],[-36,2],[-52,4],[-60,6],[-68,8],[-73,10],[-78,8],[-75,0],
   [-78,-5],[-78,-15],[-70,-22],[-65,-35],[-68,-45],[-68,-55]],

  // Avrupa
  [[-8,36],[0,36],[5,36],[10,38],[15,38],[20,37],[25,37],[28,38],[30,40],
   [32,42],[30,46],[25,47],[20,55],[15,58],[10,58],[5,58],[0,52],
   [-5,48],[-5,44],[-8,42],[-8,36]],

  // İskandinavya
  [[5,58],[10,58],[15,58],[20,65],[25,70],[28,72],[22,70],[15,70],[10,63],[5,58]],

  // Büyük Britanya (basit)
  [[-5,50],[0,52],[2,52],[1,58],[-4,58],[-5,56],[-5,50]],

  // Afrika
  [[-6,36],[0,36],[5,36],[10,38],[25,37],[30,30],[32,28],[36,22],[40,12],
   [45,12],[45,5],[40,-1],[35,-5],[35,-10],[36,-18],[34,-25],[28,-32],[18,-34],
   [15,-28],[10,-20],[5,-15],[2,-5],[0,5],[-5,5],[-8,5],[-15,10],[-15,15],
   [-15,25],[-8,28],[-6,36]],

  // Asya (büyük blok)
  [[25,37],[30,40],[36,42],[40,42],[45,42],[50,45],[55,50],[60,55],[65,55],
   [70,60],[75,65],[80,72],[90,75],[100,72],[110,70],[120,65],[130,60],
   [140,55],[145,48],[142,40],[135,35],[130,32],[125,25],[120,20],[110,20],
   [105,15],[100,5],[100,1],[105,-5],[110,-8],[115,-8],[120,-5],[125,0],
   [130,5],[135,5],[130,10],[125,15],[120,22],[115,25],[110,30],[105,35],
   [100,38],[95,40],[90,42],[85,40],[80,37],[75,35],[70,37],[65,38],
   [60,38],[55,38],[50,40],[45,40],[40,40],[36,42],[32,42],[28,42],[25,37]],

  // Japonya (basit)
  [[130,33],[133,35],[136,38],[140,42],[142,44],[140,42],[136,38],[131,34],[130,33]],

  // Avustralya
  [[115,-35],[120,-32],[125,-30],[130,-28],[135,-24],[140,-18],[145,-15],
   [150,-22],[155,-28],[152,-32],[148,-38],[145,-42],[140,-38],[135,-35],
   [130,-38],[125,-35],[120,-35],[115,-35]],

  // Yeni Zelanda (ufak)
  [[170,-45],[172,-44],[174,-41],[175,-38],[173,-38],[170,-40],[170,-45]],

  // Grönland
  [[-50,60],[-40,62],[-24,70],[-20,76],[-25,80],[-40,82],[-50,83],
   [-60,80],[-68,75],[-58,68],[-50,60]],

  // İzlanda
  [[-24,63],[-18,65],[-14,66],[-20,65],[-24,65],[-24,63]],
];

// SliverWidget typedef
typedef SliverWidget = SliverToBoxAdapter;
