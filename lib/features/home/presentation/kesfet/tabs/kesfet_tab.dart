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

    final oneCikan       = ref.watch(oneCikanIlanlarProvider);
    final yakinGelenler  = ref.watch(yakinGelenIlanlarProvider);
    final topGuzergahlar = ref.watch(populerGuzergahlarProvider);

    final istekler    = ref.watch(istekIlanlarProvider).filtrelenmis;
    final tasiyicilar = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;

    final tumIlanlar = [...istekler, ...tasiyicilar]
      ..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
          .compareTo(a.olusturmaTarihi ?? DateTime(0)));

    final filtreliIlanlar = seciliKategori == null
        ? tumIlanlar
        : tumIlanlar.where((i) => i.kategori == seciliKategori).toList();

    return CustomScrollView(
      slivers: [

        // ── Kategori story çemberleri ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 88,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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

        // ── Ayırıcı ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: const Color(0xFFF0F0F0),
          ),
        ),

        // Kategori seçili değilken ekstra bölümler
        if (seciliKategori == null) ...[

          // ── Son baktıklarınız ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: const SonGoruntulenenlerBolumu(),
          ),

          // ── Öne çıkanlar ────────────────────────────────────────────────
          if (oneCikan.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                child: bolumBasligi('Öne çıkanlar'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  itemCount: oneCikan.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: HeroKart(ilan: oneCikan[i]),
                  ),
                ),
              ),
            ),
          ],

          // ── Yakında gelenler ─────────────────────────────────────────────
          if (yakinGelenler.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: bolumBasligi('Yakında gelenler'),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _YakinGelenKarti(ilan: yakinGelenler[index]),
                childCount: yakinGelenler.length,
              ),
            ),
          ],

          // ── Popüler güzergahlar ──────────────────────────────────────────
          if (topGuzergahlar.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: bolumBasligi('Popüler güzergahlar'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  itemCount: topGuzergahlar.length,
                  itemBuilder: (context, i) =>
                      _GuzergahKarti(guzergah: topGuzergahlar[i]),
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],

        // ── İlan grid başlığı ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: bolumBasligi(
            seciliKategori == null ? 'Tüm ilanlar' : kategoriAdi(seciliKategori),
          ),
        ),

        // ── Skeleton ya da gerçek grid ───────────────────────────────────────
        if (yukleniyor)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childCount: 6,
              itemBuilder: (_, _) => const SkeletonKart(),
            ),
          )
        else if (filtreliIlanlar.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'Bu kategoride ilan yok',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childCount: filtreliIlanlar.length,
              itemBuilder: (_, i) => KesfetKarti(ilan: filtreliIlanlar[i]),
            ),
          ),
      ],
    );
  }
}

// ── Yakında gelen ilan kartı ──────────────────────────────────────────────────

class _YakinGelenKarti extends ConsumerWidget {
  final IlanModel ilan;
  const _YakinGelenKarti({required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fark = ilan.tarih!.difference(DateTime.now()).inDays;
    final yazi = fark == 0 ? 'Bugün' : fark == 1 ? 'Yarın' : '$fark gün sonra';

    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.flight_takeoff_outlined,
                size: 18, color: Color(0xFFBDBDBD)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ilan.kullaniciAd,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFFBDBDBD),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: fark == 0
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                yazi,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fark == 0 ? AppColors.red : const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Güzergah kartı (pill) ─────────────────────────────────────────────────────

class _GuzergahKarti extends StatelessWidget {
  final GuzergahSatiri guzergah;
  const _GuzergahKarti({required this.guzergah});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            guzergah.nereden,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded,
                size: 11, color: Color(0xFFBDBDBD)),
          ),
          Text(
            guzergah.nereye,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${guzergah.ilanSayisi}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }
}