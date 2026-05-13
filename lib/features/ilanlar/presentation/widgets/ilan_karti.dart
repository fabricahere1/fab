// lib/features/ilanlar/presentation/widgets/ilan_karti.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/ilan_model.dart';
import '../../providers/ilan_provider.dart';
import '../../data/ilan_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/cache/app_cache_manager.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/utils/app_layout.dart';
import '../ilan_detay_screen.dart';
import '../../../../shared/constants/app_constants.dart';

// ── Grid Kartı ────────────────────────────────────────────────────────────────

class IlanKarti extends ConsumerWidget {
  final IlanModel ilan;
  final List<double> resimYukseklikleri;

  const IlanKarti({
    super.key,
    required this.ilan,
    required this.resimYukseklikleri,
  });

  double _resimYuksekligi() {
    return resimYukseklikleri[ilan.id.hashCode.abs() % resimYukseklikleri.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guncelIlan = ref.watch(
      istekIlanlarProvider.select((s) {
        try {
          return s.filtrelenmis.firstWhere((i) => i.id == ilan.id);
        } catch (_) {
          return ilan;
        }
      }),
    );

    final resimler       = guncelIlan.tumResimler;
    final kategoriAdiStr = kategoriAdi(guncelIlan.kategori);
    final uid            = ref.watch(currentUserProvider)?.uid;
    final gosterFavori   = uid != null && uid != guncelIlan.kullaniciId;
    final favoriliIdler  = ref.watch(favoriliIlanIdlerProvider);
    final favorideMi     = gosterFavori && favoriliIdler.contains(guncelIlan.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => IlanDetayScreen(ilanId: guncelIlan.id, ilan: guncelIlan),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: _resimYuksekligi(),
                  width: double.infinity,
                  child: resimler.isNotEmpty
                      ? CachedNetworkImage(
                          cacheManager: AppCacheManager.instance,
                          imageUrl: resimler.first,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          memCacheWidth: 400,
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(Icons.image_outlined,
                                  color: AppColors.textHint, size: 28),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 28),
                          ),
                        ),
                ),
                if (gosterFavori)
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        if (uid == null) return;
                        if (favorideMi) {
                          await ref.read(ilanRepositoryProvider)
                              .favoridanCikar(kullaniciId: uid, ilanId: guncelIlan.id);
                        } else {
                          await ref.read(ilanRepositoryProvider)
                              .favoriyeEkle(kullaniciId: uid, ilan: guncelIlan);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favorideMi ? Icons.favorite : Icons.favorite_border,
                          color: favorideMi ? AppColors.red : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guncelIlan.urun.isNotEmpty ? guncelIlan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                        fontSize: AppLayout.fs(context, 12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${guncelIlan.nereden} → ${guncelIlan.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: AppLayout.fs(context, 10),
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (kategoriAdiStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        kategoriAdiStr,
                        style: GoogleFonts.dmSans(
                            fontSize: AppLayout.fs(context, 9),
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

// ── Liste Kartı ───────────────────────────────────────────────────────────────

class IlanListeKarti extends ConsumerWidget {
  final IlanModel ilan;
  const IlanListeKarti({super.key, required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resimler      = ilan.tumResimler;
    final uid           = ref.watch(currentUserProvider)?.uid;
    final gosterFavori  = uid != null && uid != ilan.kullaniciId;
    final favoriliIdler = ref.watch(favoriliIlanIdlerProvider);
    final favorideMi    = gosterFavori && favoriliIdler.contains(ilan.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => IlanDetayScreen(ilanId: ilan.id, ilan: ilan),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 72, height: 72,
                child: resimler.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resimler.first,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: 200,
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 24),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.textHint, size: 24),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                      fontSize: AppLayout.fs(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${ilan.nereden} → ${ilan.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: AppLayout.fs(context, 11),
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (ilan.notlar.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ilan.notlar,
                      style: GoogleFonts.dmSans(
                          fontSize: AppLayout.fs(context, 11),
                          color: AppColors.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (gosterFavori)
              GestureDetector(
                onTap: () async {
                  if (uid == null) return;
                  if (favorideMi) {
                    await ref.read(ilanRepositoryProvider)
                        .favoridanCikar(kullaniciId: uid, ilanId: ilan.id);
                  } else {
                    await ref.read(ilanRepositoryProvider)
                        .favoriyeEkle(kullaniciId: uid, ilan: ilan);
                  }
                },
                child: Icon(
                  favorideMi ? Icons.favorite : Icons.favorite_border,
                  color: favorideMi ? AppColors.red : AppColors.textHint,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Grid ──────────────────────────────────────────────────────────────

class ShimmerGrid extends StatelessWidget {
  final int kolonSayisi;
  const ShimmerGrid({super.key, this.kolonSayisi = 2});

  static const _yukseklikler = [120.0, 150.0, 105.0, 135.0, 165.0, 112.0];

  @override
  Widget build(BuildContext context) {
    if (kolonSayisi == 1) return const ShimmerListe();
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: MasonryGridView.count(
        crossAxisCount: kolonSayisi,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          final h = _yukseklikler[index % _yukseklikler.length];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: h, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 11, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 5),
                      Container(height: 9, width: 80, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Shimmer Liste ─────────────────────────────────────────────────────────────

class ShimmerListe extends StatelessWidget {
  const ShimmerListe({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Column(
        children: List.generate(6, (_) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 1),
          child: Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 13, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 140, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 13, width: 80, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}