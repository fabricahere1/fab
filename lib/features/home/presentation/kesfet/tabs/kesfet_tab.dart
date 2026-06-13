import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart' show kKategoriAgaci, kategoriAdi;
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/kesfet_computed_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/features/home/presentation/kesfet/widgets/kesfet_widgets.dart';

class KesfetTab extends ConsumerStatefulWidget {
  const KesfetTab({super.key});

  @override
  ConsumerState<KesfetTab> createState() => _KesfetTabState();
}

class _KesfetTabState extends ConsumerState<KesfetTab> {
  String? _seciliKategori;

  @override
  Widget build(BuildContext context) {
    final seciliKategori = _seciliKategori;
    final yukleniyor     = ref.watch(istekIlanlarProvider).yukleniyor;

    // Memoize edilmiş hesaplamalar
    final oneCikan       = ref.watch(oneCikanIlanlarProvider);
    final yakinGelenler  = ref.watch(yakinGelenIlanlarProvider);
    final topGuzergahlar = ref.watch(populerGuzergahlarProvider);

    // Tüm ilanlar — kategori filtresi için
    final istekler    = ref.watch(istekIlanlarProvider).filtrelenmis;
    final tasiyicilar = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;

    final tumIlanlar = [...istekler, ...tasiyicilar]
      ..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
          .compareTo(a.olusturmaTarihi ?? DateTime(0)));

    final filtreliIlanlar = seciliKategori == null
        ? tumIlanlar
        : tumIlanlar
            .where((i) => i.kategori == seciliKategori)
            .toList();

    return CustomScrollView(
      slivers: [
        // ── Kategori story çemberleri ────────────────────────────────────────
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
                  return StoryItem(
                    emoji: '✦',
                    label: 'Tümü',
                    secili: seciliKategori == null,
                    onTap: () => setState(() => _seciliKategori = null),
                  );
                }
                final kat    = kKategoriAgaci[i - 1];
                final secili = seciliKategori == kat.key;
                return StoryItem(
                  emoji: kat.emoji,
                  label: kat.ad,
                  secili: secili,
                  onTap: () => setState(() => _seciliKategori = secili ? null : kat.key),
                );
              },
            ),
          ),
        ),

        // Kategori seçili değilken ekstra bölümler
        if (seciliKategori == null) ...[
          // ── Son baktıklarınız (YENİ) ───────────────────────────────────────
          SliverToBoxAdapter(
            child: const SonGoruntulenenlerBolumu(),
          ),

          // ── Öne çıkanlar ──────────────────────────────────────────────────
          if (oneCikan.isNotEmpty) ...[
            SliverToBoxAdapter(child: bolumBasligi('⭐ Öne çıkanlar')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  itemCount: oneCikan.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: HeroKart(ilan: oneCikan[i]),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // ── Yakında gelenler ───────────────────────────────────────────────
          if (yakinGelenler.isNotEmpty) ...[
            SliverToBoxAdapter(
                child: bolumBasligi('✈ Bir kaç güne oradayım')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _YakinGelenkKarti(ilan: yakinGelenler[index]),
                childCount: yakinGelenler.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // ── Popüler güzergahlar ────────────────────────────────────────────
          if (topGuzergahlar.isNotEmpty) ...[
            SliverToBoxAdapter(
                child: bolumBasligi('🗺 Popüler güzergahlar')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 68,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  itemCount: topGuzergahlar.length,
                  itemBuilder: (context, i) =>
                      _GuzergahKarti(guzergah: topGuzergahlar[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ],

        // ── İlan grid başlığı ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: bolumBasligi(
            seciliKategori == null
                ? '🆕 Tüm ilanlar'
                : kategoriAdi(seciliKategori),
          ),
        ),

        // ── Skeleton ya da gerçek grid ───────────────────────────────────────
        if (yukleniyor)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childCount: 6,
              itemBuilder: (_, _) => const SkeletonKart(),
            ),
          )
        else if (filtreliIlanlar.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Bu kategoride ilan yok',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childCount: filtreliIlanlar.length,
              itemBuilder: (_, i) =>
                  KesfetKarti(ilan: filtreliIlanlar[i]),
            ),
          ),
      ],
    );
  }
}

// ── Yakında gelen ilan kartı ──────────────────────────────────────────────────

class _YakinGelenkKarti extends ConsumerWidget {
  final IlanModel ilan;
  const _YakinGelenkKarti({required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fark = ilan.tarih!.difference(DateTime.now()).inDays;
    final yazi = fark == 0 ? 'Bugün!' : fark == 1 ? 'Yarın' : '$fark gün sonra';

    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id));
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
                  Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ilan.kullaniciAd,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: fark == 0
                    ? AppColors.red.withValues(alpha: 0.1)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                yazi,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      fark == 0 ? AppColors.red : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Güzergah kartı ────────────────────────────────────────────────────────────

class _GuzergahKarti extends StatelessWidget {
  final GuzergahSatiri guzergah;
  const _GuzergahKarti({required this.guzergah});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Text(
                guzergah.nereden,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward,
                    size: 11, color: AppColors.textSecondary),
              ),
              Text(
                guzergah.nereye,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${guzergah.ilanSayisi} ilan',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
