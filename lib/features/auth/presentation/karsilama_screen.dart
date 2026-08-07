// lib/features/auth/presentation/karsilama_screen.dart
//
// Misafir kullanıcının HER uygulama açılışında (giriş yapana kadar)
// karşılaştığı ekran — "İSTE'ye Katıl / Giriş Yap / Atla". "Atla",
// yalnızca o oturum için geçerli (bkz. karsilamaAtlandiProvider,
// app_router.dart) — kalıcı bir tercih değil, kullanıcı giriş yapana
// kadar bir sonraki açılışta yine gösterilir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../router/app_router.dart' show AppRoutes, karsilamaAtlandiProvider;
import '../../../shared/constants/app_colors.dart';

class KarsilamaScreen extends ConsumerWidget {
  const KarsilamaScreen({super.key});

  void _atla(BuildContext context, WidgetRef ref) {
    ref.read(karsilamaAtlandiProvider.notifier).state = true;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: TextButton(
                onPressed: () => _atla(context, ref),
                child: Text(
                  'Atla',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: Image.asset(
                      'assets/images/karsilama_banner.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const Spacer(flex: 4),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.register),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "İSTE'ye Katıl",
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Zaten Üyeyim / Giriş Yap',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
