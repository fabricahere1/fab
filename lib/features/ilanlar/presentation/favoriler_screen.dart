// lib/features/ilanlar/presentation/favoriler_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/cache/app_cache_manager.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import 'ilan_detay_screen.dart';

class FavorilerScreen extends ConsumerWidget {
  const FavorilerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _appBar(context),
        body: Center(
          child: Text(
            'Favorileri görmek için giriş yapmalısın.',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final favorilerAsync = ref.watch(kullaniciFavorileriProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _appBar(context),
      body: favorilerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
        ),
        error: (_, _) => Center(
          child: Text('Bir hata oluştu',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (ilanlar) {
          if (ilanlar.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 64, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz favorin yok',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beğendiğin ilanları favorile,\nburadan kolayca ulaş.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 260,
            ),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final ilan = ilanlar[index];
              return RepaintBoundary(
                key: ValueKey(ilan.id),
                child: _FavoriKarti(ilan: ilan, uid: uid),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Favorilerim',
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Kart ──────────────────────────────────────────────────────────────────────

class _FavoriKarti extends ConsumerStatefulWidget {
  final IlanModel ilan;
  final String uid;

  const _FavoriKarti({required this.ilan, required this.uid});

  @override
  ConsumerState<_FavoriKarti> createState() => _FavoriKartiState();
}

class _FavoriKartiState extends ConsumerState<_FavoriKarti>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _islem = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 1.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _favoridanCikar() async {
    if (_islem) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Favorilerden Çıkar',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
            '"${widget.ilan.urun.isNotEmpty ? widget.ilan.urun : 'Bu ilan'}" favorilerden çıkarılsın mı?',
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
    _islem = true;
    _ctrl.forward().then((_) => _ctrl.reverse());
    try {
      await ref.read(favoriProvider.notifier).cikar(widget.ilan.id);
    } finally {
      _islem = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resimler = widget.ilan.tumResimler;
    final kategori = app_constants.kategoriAdi(widget.ilan.kategori);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => IlanDetayScreen(
            ilanId: widget.ilan.id,
            ilan: widget.ilan,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF888888), width: 0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf + favori butonu
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: const Color(0xFFF2F2F2),
                  child: resimler.isNotEmpty
                      ? CachedNetworkImage(
                          cacheManager: AppCacheManager.instance,
                          imageUrl: resimler.first,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (_, _) =>
                              const SizedBox.shrink(),
                          errorWidget: (_, _, _) => const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 28),
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
                // Favoriden çıkar butonu
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: _favoridanCikar,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Bilgi alanı
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ilan.urun.isNotEmpty ? widget.ilan.urun : 'İlan',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
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
                            '${widget.ilan.nereden} → ${widget.ilan.nereye}',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (kategori.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.chipBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kategori,
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}