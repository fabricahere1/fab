import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../../core/cache/app_cache_manager.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/constants/app_constants.dart';

class FavorilerScreen extends ConsumerWidget {
  const FavorilerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final favorilerAsync = ref.watch(favorilerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Favorilerim',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? Center(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: Text(
                  'Favorileri görmek için giriş yap',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.red,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.red,
                  ),
                ),
              ),
            )
          : favorilerAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.red, strokeWidth: 2)),
              error: (_, _) => Center(
                child: Text('Bir hata oluştu.',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary)),
              ),
              data: (favoriler) {
                if (favoriler.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border,
                            size: 64, color: AppColors.divider),
                        const SizedBox(height: 16),
                        Text('Henüz favori yok',
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                            'İlan detayında kalp ikonuna basarak\nfavorilere ekleyebilirsin',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textHint)),
                      ],
                    ),
                  );
                }

                return MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: const EdgeInsets.all(8),
                  itemCount: favoriler.length,
                  itemBuilder: (context, index) {
                    final favori = favoriler[index];
                    final ilan = _favoridenIlan(favori);
                    return _FavoriKarti(
                      ilan: ilan,
                      uid: uid,
                    );
                  },
                );
              },
            ),
    );
  }

  IlanModel _favoridenIlan(Map<String, dynamic> favori) {
    return IlanModel(
      id: favori['ilanId'] as String? ?? '',
      tip: favori['tip'] as String? ?? 'istek',
      nereden: favori['nereden'] as String? ?? '',
      nereye: favori['nereye'] as String? ?? '',
      ucret: favori['ucret'] as String? ?? '',
      urun: favori['urun'] as String? ?? '',
      notlar: favori['notlar'] as String? ?? '',
      kategori: favori['kategori'] as String? ?? 'diger',
      kullaniciId: favori['ilanSahibiId'] as String? ?? '',
      kullaniciAd: favori['kullaniciAd'] as String? ?? '',
      resimUrl: favori['resimUrl'] as String? ?? '',
      resimUrller: List<String>.from(favori['resimUrller'] ?? []),
    );
  }
}

// ── Favori Kartı ──────────────────────────────────────────────────────────────

class _FavoriKarti extends ConsumerWidget {
  final IlanModel ilan;
  final String uid;

  const _FavoriKarti({
    required this.ilan,
    required this.uid,
  });

  double _resimYuksekligi() {
    const heights = [160.0, 200.0, 140.0, 180.0, 220.0, 150.0];
    return heights[ilan.id.hashCode.abs() % heights.length];
  }

  Future<void> _favoridenCikar(BuildContext context, WidgetRef ref) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Favorilerden Çıkar',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
            '"${ilan.urun.isNotEmpty ? ilan.urun : 'Bu ilan'}" favorilerden çıkarılsın mı?',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Çıkar',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay != true) return;
    await ref.read(favoriProvider.notifier).cikar(ilan.id);
    if (context.mounted) {
      AppSnackBar.bilgi(context, 'Favorilerden çıkarıldı.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridResim = ilan.gridResim;
    final kategoriAdi_ = kategoriAdi(ilan.kategori);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Resim + favori çıkar butonu ──────────────────────────────
            Stack(
              children: [
                gridResim.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: gridResim,
                        width: double.infinity,
                        height: _resimYuksekligi(),
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        memCacheWidth: 200,
                        placeholder: (_, _) => Container(
                          height: _resimYuksekligi(),
                          color: AppColors.surface,
                        ),
                        errorWidget: (_, _, _) => Container(
                          height: _resimYuksekligi(),
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 32),
                          ),
                        ),
                      )
                    : Container(
                        height: _resimYuksekligi(),
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.textHint, size: 32),
                        ),
                      ),

                // Favoriden çıkar butonu
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _favoridenCikar(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.favorite,
                          color: AppColors.red, size: 16),
                    ),
                  ),
                ),
              ],
            ),

            // ── Detaylar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flight_takeoff_outlined,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${ilan.nereden} → ${ilan.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (ilan.ucret.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${ilan.ucret} ₺',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                  if (kategoriAdi_.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kategoriAdi_,
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}