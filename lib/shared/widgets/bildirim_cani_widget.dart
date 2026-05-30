import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../features/bildirimler/presentation/bildirimler_screen.dart';
import '../../features/bildirimler/providers/bildirim_provider.dart';
import '../constants/app_colors.dart';

class BildirimCaniWidget extends ConsumerWidget {
  final Color? renk;
  const BildirimCaniWidget({super.key, this.renk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final okunmamisBildirim =
        ref.watch(okunmamisBildirimSayiProvider).value ?? 0;
    final ikonRenk = renk ?? Colors.black;

    final ikon = Icon(
      Symbols.notifications,
      color: ikonRenk,
      size: 24,
      weight: 300,
      opticalSize: 24,
      fill: 0,
    );

    return IconButton(
      onPressed: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const BildirimlerScreen(),
          transitionsBuilder: (_, anim, _, child) => SlideTransition(
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
          ? ikon
          : Badge(
              label: Text(
                okunmamisBildirim > 99 ? '99+' : '$okunmamisBildirim',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.red,
              child: ikon,
            ),
    );
  }
}