import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/shared/constants/app_constants.dart' show IlanTip;
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';

// ── Bölüm başlığı ────────────────────────────────────────────────────────────

Widget bolumBasligi(String baslik) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Text(
        baslik,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );

Widget bolumBasligiSliver(String baslik) => SliverToBoxAdapter(
      child: bolumBasligi(baslik),
    );

// ── Resim placeholder ─────────────────────────────────────────────────────────

class ResimPlaceholder extends StatelessWidget {
  final IlanModel ilan;
  const ResimPlaceholder({super.key, required this.ilan});

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

// ── Skeleton yükleme kartı ────────────────────────────────────────────────────

class SkeletonKart extends StatefulWidget {
  final double yukseklik;
  const SkeletonKart({super.key, this.yukseklik = 140});

  @override
  State<SkeletonKart> createState() => _SkeletonKartState();
}

class _SkeletonKartState extends State<SkeletonKart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: widget.yukseklik,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: widget.yukseklik * 0.65,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 60,
                      color: AppColors.divider,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Story (kategori) item ─────────────────────────────────────────────────────

class StoryItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool secili;
  final VoidCallback onTap;

  const StoryItem({
    super.key,
    required this.emoji,
    required this.label,
    required this.secili,
    required this.onTap,
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
                        colors: [AppColors.red, Color(0xFFFF8C42)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFDDDDDD), Color(0xFFDDDDDD)],
                      ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 52,
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: secili ? FontWeight.w700 : FontWeight.w400,
                  color: secili ? AppColors.red : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero kart (yatay kaydırmalı öne çıkanlar) ────────────────────────────────

class HeroKart extends ConsumerWidget {
  final IlanModel ilan;
  const HeroKart({super.key, required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resimler = ilan.tumResimler;
    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id));
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
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
                            placeholder: (_, _) =>
                                ResimPlaceholder(ilan: ilan),
                            errorWidget: (_, _, _) =>
                                ResimPlaceholder(ilan: ilan),
                          )
                        : ResimPlaceholder(ilan: ilan),
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
                          color: Colors.white,
                        ),
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
                  color: AppColors.textPrimary,
                ),
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

// ── Masonry ilan kartı ────────────────────────────────────────────────────────

class KesfetKarti extends ConsumerWidget {
  final IlanModel ilan;
  const KesfetKarti({super.key, required this.ilan});

  double _yukseklik() {
    const h = [110.0, 130.0, 100.0, 120.0, 140.0, 105.0];
    return h[ilan.id.hashCode.abs() % h.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resimler = ilan.tumResimler;
    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id));
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: _yukseklik(),
                width: double.infinity,
                child: resimler.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resimler.first,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, _) => ResimPlaceholder(ilan: ilan),
                        errorWidget: (_, _, _) => ResimPlaceholder(ilan: ilan),
                      )
                    : ResimPlaceholder(ilan: ilan),
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
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ilan.ucret.isNotEmpty)
                    Text(
                      '${ilan.ucret} ₺',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.red,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── İstatistik kartı ──────────────────────────────────────────────────────────

class StatKart extends StatelessWidget {
  final String sayi;
  final String label;
  final Color renk;
  const StatKart({
    super.key,
    required this.sayi,
    required this.label,
    required this.renk,
  });

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
            Text(
              sayi,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: renk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Şu an havada kartı ────────────────────────────────────────────────────────

class SuAnHavadaKart extends StatelessWidget {
  final List<IlanModel> ilanlar;
  const SuAnHavadaKart({super.key, required this.ilanlar});

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
          Row(
            children: [
              const Icon(Icons.radar_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Şu an havada',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    Text(
                      'CANLI',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ilanlar.asMap().entries.map((entry) {
            final i    = entry.key;
            final ilan = entry.value;
            final eta  = _etaYazisi(ilan);
            return Container(
              margin: EdgeInsets.only(
                  bottom: i < ilanlar.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            color: Colors.white,
                          ),
                        ),
                        if (ilan.kullaniciAd.isNotEmpty)
                          Text(
                            ilan.kullaniciAd,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (eta.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF64B5F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        eta,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64B5F6),
                        ),
                      ),
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

// ── Son görüntülenenler yatay listesi ─────────────────────────────────────────

class SonGoruntulenenlerBolumu extends ConsumerWidget {
  const SonGoruntulenenlerBolumu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(sonGoruntulenenlerProvider);
    if (liste.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bolumBasligi('🕐 Son baktıklarınız'),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            itemCount: liste.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: HeroKart(ilan: liste[i]),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
