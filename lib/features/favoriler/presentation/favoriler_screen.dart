import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../ilanlar/data/ilan_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../router/app_router.dart';
 
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
              child: Text('Favorileri görmek için giriş yap',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, color: AppColors.textSecondary)),
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
                            'İlanları favorilere eklemek için\nilan detayındaki ••• menüsünü kullan',
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
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  padding: const EdgeInsets.all(6),
                  itemCount: favoriler.length,
                  itemBuilder: (context, index) {
                    final favori = favoriler[index];
                    final ilan = _favoridenIlan(favori);
                    return _FavoriKarti(
                      ilan: ilan,
                      favoriId: favori['id'] as String? ?? '',
                      uid: uid,
                      ref: ref,
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
      kullaniciId: favori['kullaniciId'] as String? ?? '',
      kullaniciAd: favori['kullaniciAd'] as String? ?? '',
      resimUrl: favori['resimUrl'] as String? ?? '',
      resimUrller: List<String>.from(favori['resimUrller'] ?? []),
    );
  }
}
 
// ── Favori Kartı ──────────────────────────────────────────
 
class _FavoriKarti extends StatelessWidget {
  final IlanModel ilan;
  final String favoriId;
  final String uid;
  final WidgetRef ref;
 
  const _FavoriKarti({
    required this.ilan,
    required this.favoriId,
    required this.uid,
    required this.ref,
  });
 
  double _resimYuksekligi() {
    final heights = [160.0, 200.0, 140.0, 180.0, 220.0, 150.0];
    return heights[ilan.id.hashCode.abs() % heights.length];
  }
 
  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    final kategoriAdi_ = kategoriAdi(ilan.kategori);
 
    return GestureDetector(
      onTap: () => context.push(AppRoutes.ilanDetayPath(ilan.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim + Favori çıkar butonu
            Stack(
              children: [
                resimler.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resimler.first,
                        width: double.infinity,
                        height: _resimYuksekligi(),
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
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
                    onTap: () async {
                      await ref
                          .read(ilanRepositoryProvider)
                          .favoridanCikar(
                            kullaniciId: uid,
                            ilanId: ilan.id,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Favorilerden çıkarıldı.',
                                style: GoogleFonts.dmSans()),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          color: AppColors.red, size: 16),
                    ),
                  ),
                ),
              ],
            ),
 
            // Detaylar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
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
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ilan.ucret.isNotEmpty
                              ? '${ilan.ucret} ₺'
                              : 'Belirtilmemiş',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: ilan.ucret.isNotEmpty
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: ilan.ucret.isNotEmpty
                                ? AppColors.red
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (kategoriAdi_.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          color: AppColors.chipBg,
                          child: Text(
                            kategoriAdi_,
                            style: GoogleFonts.dmSans(
                                fontSize: 9,
                                color: AppColors.textSecondary),
                          ),
                        ),
                    ],
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