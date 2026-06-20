import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/ilanlar/presentation/ilan_form_screen.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_constants.dart';

class NedenIsteBar extends StatelessWidget {
  const NedenIsteBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _ilanSecPopup(context),
      child: Container(
        height: 36,
        color: const Color(0xFFEEEEEE),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'İlk ilanını ver, ücretsiz öne çıkaralım',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _ilanSecPopup(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (ctx, a1, a2) => const _IlanSecPanel(),
        transitionsBuilder: (ctx, anim, secAnim, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }
}

class _IlanSecPanel extends StatelessWidget {
  const _IlanSecPanel();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {}, // iç tıklamalar kapanmasın
        child: Container(
          width: MediaQuery.of(context).size.width * 0.82,
          height: double.infinity,
          color: Colors.white,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close_rounded,
                            size: 22, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Ne yapmak istersin?',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Uygun seçeneği seç, hemen başla.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _SecenekKarti(
                  ikon: Icons.shopping_bag_outlined,
                  baslik: 'İstek İlanı',
                  aciklama: 'Yurt dışından bir ürün almak istiyorum',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IlanFormScreen(tip: 'istek')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SecenekKarti(
                  ikon: Icons.flight_takeoff_rounded,
                  baslik: 'Gelen İlanı',
                  aciklama: 'Seyahat edip ürün taşıyabilirim',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const IlanFormScreen(tip: IlanTip.tasiyici)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecenekKarti extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const _SecenekKarti({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, size: 22, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      aciklama,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}