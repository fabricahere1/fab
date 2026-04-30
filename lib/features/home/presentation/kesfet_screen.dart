// lib/features/home/presentation/kesfet_screen.dart

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
    final tumIlanlar    = [
      ...ref.watch(istekIlanlarProvider).filtrelenmis,
      ...tasiyiciState.filtrelenmis,
    ];

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
            height: 180,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: Stack(
              children: [
                // Grid çizgileri
                CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _HaritaGridPainter(),
                ),
                // Pin'ler
                const _HaritaPin(left: 0.18, top: 0.30, renk: Color(0xFFE53935)),
                const _HaritaPin(left: 0.42, top: 0.22, renk: Color(0xFFFF8C42)),
                const _HaritaPin(left: 0.68, top: 0.38, renk: Color(0xFF4CAF50)),
                const _HaritaPin(left: 0.55, top: 0.55, renk: Color(0xFFE53935)),
                const _HaritaPin(left: 0.30, top: 0.65, renk: Color(0xFFFF8C42)),
                const _HaritaPin(left: 0.78, top: 0.25, renk: Color(0xFF4CAF50)),
                // Overlay bilgi
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flight_takeoff_rounded,
                            size: 12, color: AppColors.red),
                        const SizedBox(width: 5),
                        Text(
                          '${tasiyiciState.filtrelenmis.length} aktif güzergah',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
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
          _BolumBasligi('🔥 Trend istekler'),
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
        _BolumBasligi('⚡ Son aktiviteler'),
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
          _BolumBasligi('⭐ Öne çıkanlar'),
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
          _BolumBasligi('✈ Bir kaç güne oradayım'),
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
          _BolumBasligi('🗺 Popüler güzergahlar'),
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
        _BolumBasligi(_seciliKategori == null
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

SliverWidget _BolumBasligi(String baslik) => SliverToBoxAdapter(
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
class _HaritaGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.12)
      ..strokeWidth = 0.5;

    // Yatay çizgiler
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Dikey çizgiler
    for (var i = 0; i <= 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Meridyen eğrisi
    final curvePaint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.1, 0)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.3, size.width * 0.9, 0);
    canvas.drawPath(path, curvePaint);
    final path2 = Path()
      ..moveTo(size.width * 0.05, size.height)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.7, size.width * 0.95, size.height);
    canvas.drawPath(path2, curvePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// Harita pin
class _HaritaPin extends StatelessWidget {
  final double left, top;
  final Color renk;
  const _HaritaPin({required this.left, required this.top, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment(left * 2 - 1, top * 2 - 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: renk,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: renk.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(6, 4),
              painter: _PinTailPainter(renk),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color renk;
  const _PinTailPainter(this.renk);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = renk;
    final path  = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// SliverWidget typedef
typedef SliverWidget = SliverToBoxAdapter;
