import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../router/app_router.dart' show AppRoutes;
import '../constants/app_colors.dart';

/// Giriş gerektiren bir aksiyonu sarmalar.
/// Kullanıcı giriş yapmamışsa login bottom sheet açar,
/// giriş yapmışsa [onDevam]'ı doğrudan çağırır.
class LoginGerektirenAksiyon extends ConsumerWidget {
  final VoidCallback onDevam;
  final Widget child;

  const LoginGerektirenAksiyon({
    super.key,
    required this.onDevam,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _kontrol(context, ref),
      child: AbsorbPointer(child: child),
    );
  }

  void _kontrol(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      onDevam();
    } else {
      loginBottomSheet(context);
    }
  }
}

/// Standalone çağrı için — herhangi bir yerde kullanılabilir.
/// [returnRoute] verilirse login/profil tamamlama sonrası o rotaya gidilir.
void loginBottomSheet(BuildContext context, {String? returnRoute}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LoginSheet(returnRoute: returnRoute),
  );
}

class _LoginSheet extends StatelessWidget {
  final String? returnRoute;
  const _LoginSheet({this.returnRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 16),
          Lottie.asset(
            ['assets/animations/bukalemun.json', 'assets/animations/timsah.json']
                [Random().nextInt(2)],
            width: 100,
            height: 100,
          ),

          // Başlık
          Text(
            'Devam etmek için giriş yap',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mesaj göndermek, favori eklemek ve ilan vermek için hesabına giriş yapman gerekiyor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Giriş Yap butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final q = returnRoute != null ? '?returnRoute=${Uri.encodeComponent(returnRoute!)}' : '';
                context.go('${AppRoutes.login}$q');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Giriş Yap',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Kayıt Ol butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                final q = returnRoute != null ? '?returnRoute=${Uri.encodeComponent(returnRoute!)}' : '';
                context.go('${AppRoutes.register}$q');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Kayıt Ol',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
