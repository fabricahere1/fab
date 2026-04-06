import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/bildirimler/presentation/bildirimler_screen.dart';
import '../../features/bildirimler/providers/bildirim_provider.dart';
import '../constants/app_colors.dart';

class BildirimCaniWidget extends ConsumerWidget {
  const BildirimCaniWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final okunmamisBildirim =
        ref.watch(okunmamisBildirimSayiProvider).value ?? 0;

    return IconButton(
      onPressed: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const BildirimlerScreen(),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      icon: okunmamisBildirim == 0
          ? const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary)
          : Badge(
              label: Text(
                okunmamisBildirim > 99 ? '99+' : '$okunmamisBildirim',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.red,
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.textPrimary),
            ),
    );
  }
}