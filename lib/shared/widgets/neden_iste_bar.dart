import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/ilanlar/presentation/ilan_form_screen.dart';
import '../../router/app_router.dart' show AppRoutes;
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_constants.dart';
import 'login_gerektiren_aksiyon.dart' show loginBottomSheet;

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
            const Icon(Icons.bolt_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hemen ücretsiz ilan ver',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4A4A),
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Color(0xFFA8A8A8)),
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

class _IlanSecPanel extends ConsumerWidget {
  const _IlanSecPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.read(currentUserProvider)?.uid;
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {}, // iç tıklamalar kapanmasın
        child: Material(
          color: Colors.white,
          child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.82,
          height: double.infinity,
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
                            size: 19, color: Color(0xFFA8A8A8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Ne yapmak istersin?',
                    style: GoogleFonts.dmSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Uygun seçeneği seç, hemen başla.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: const Color(0xFF9A9A9A),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _SecenekKarti(
                  ikon: Icons.shopping_bag_outlined,
                  ikonBg: const Color(0xFFFAECE7),
                  ikonRenk: const Color(0xFFD85A30),
                  baslik: 'İstek İlanı',
                  aciklama: 'Yurt dışından bir ürün almak istiyorum',
                  onTap: () {
                    Navigator.pop(context);
                    if (uid == null) {
                      loginBottomSheet(context, returnRoute: AppRoutes.ilanOlusturIstek);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IlanFormScreen(tip: IlanTip.istek)),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _SecenekKarti(
                  ikon: Icons.flight_takeoff_rounded,
                  ikonBg: const Color(0xFFE6F1FB),
                  ikonRenk: const Color(0xFF185FA5),
                  baslik: 'Gelen İlanı',
                  aciklama: 'Seyahat edip ürün taşıyabilirim',
                  onTap: () {
                    Navigator.pop(context);
                    if (uid == null) {
                      loginBottomSheet(context, returnRoute: AppRoutes.ilanOlusturTasiyici);
                      return;
                    }
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
      ),
    );
  }
}

class _SecenekKarti extends StatelessWidget {
  final IconData ikon;
  final Color ikonBg;
  final Color ikonRenk;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const _SecenekKarti({
    required this.ikon,
    required this.ikonBg,
    required this.ikonRenk,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ikonBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(ikon, size: 22, color: ikonRenk),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      aciklama,
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: const Color(0xFF9A9A9A),
                        height: 1.4,
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
