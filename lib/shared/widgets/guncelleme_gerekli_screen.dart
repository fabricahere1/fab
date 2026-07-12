// lib/shared/widgets/guncelleme_gerekli_screen.dart
//
// Minimum sürüm kapısına takılan cihazlar için çıkışsız kilit ekranı.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

class GuncellemeGerekliScreen extends StatelessWidget {
  final String? guncellemeLinki;

  const GuncellemeGerekliScreen({super.key, this.guncellemeLinki});

  Future<void> _guncelle() async {
    final link = guncellemeLinki;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    size: 44,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Güncelleme gerekli',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Uygulamanın bu sürümü artık desteklenmiyor. Devam etmek için en güncel sürümü yüklemen gerekiyor.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (guncellemeLinki != null && guncellemeLinki!.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _guncelle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Güncelle',
                        style: GoogleFonts.manrope(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
