// lib/features/home/presentation/kesfet_bolum_detay_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';

class KesfetBolumDetayScreen extends ConsumerWidget {
  final String baslik;
  final List<IlanModel> ilanlar;
  final IconData ikon;

  const KesfetBolumDetayScreen({
    super.key,
    required this.baslik,
    required this.ilanlar,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(ikon, size: 16, color: AppColors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                baslik,
                style: GoogleFonts.raleway(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: ilanlar.isEmpty
          ? Center(
              child: Text(
                'Henüz ilan yok.',
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          : MasonryGridView.count(
              padding: const EdgeInsets.all(10),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemCount: ilanlar.length,
              itemBuilder: (context, i) => _DetayKart(ilan: ilanlar[i]),
            ),
    );
  }
}

class _DetayKart extends ConsumerWidget {
  final IlanModel ilan;
  const _DetayKart({required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resim   = ilan.gridResim;
    final katAdi  = kategoriAdi(ilan.kategori);
    final resimYukseklik = 140.0 + (ilan.id.hashCode.abs() % 6) * 16.0;

    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF888888), width: 0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Resim
              Container(
                height: resimYukseklik,
                width: double.infinity,
                color: const Color(0xFFF2F2F2),
                child: resim.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resim,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        errorWidget: (_, _, _) => const Center(
                          child: Icon(Icons.image_outlined, color: AppColors.textHint, size: 28),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 28),
                      ),
              ),
              // Bilgi
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ilan.urun.isNotEmpty)
                      Text(
                        ilan.urun,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.flight_takeoff_rounded, size: 10, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${ilan.nereden} → ${ilan.nereye}',
                            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    if (katAdi.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          katAdi,
                          style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.red),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.visibility_outlined, size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text('${ilan.goruntulenmeSayisi}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      const Icon(Icons.favorite_border, size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text('${ilan.favoriSayisi}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
                    ]),
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