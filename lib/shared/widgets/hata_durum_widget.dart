import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class HataDurumWidget extends StatelessWidget {
  final String mesaj;
  final VoidCallback? onTekrarDene;

  const HataDurumWidget({
    super.key,
    required this.mesaj,
    this.onTekrarDene,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 56, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              mesaj,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            if (onTekrarDene != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onTekrarDene,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.red,
                  textStyle: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
