import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
 
/// Veri olmadığında gösterilen boş ekran.
class BosEkran extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  final String altMesaj;
  final Color renk;
 
  const BosEkran({
    super.key,
    required this.icon,
    required this.mesaj,
    this.altMesaj = '',
    this.renk = AppColors.primary,
  });
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: renk.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(mesaj,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 15)),
          if (altMesaj.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(altMesaj,
                style: GoogleFonts.dmSans(
                    color: AppColors.textHint, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
 
/// Giriş gerektiren sayfalar için CTA widget'ı.
class GirisGerekli extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  final VoidCallback onGirisYap;
 
  const GirisGerekli({
    super.key,
    required this.icon,
    required this.mesaj,
    required this.onGirisYap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(mesaj,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onGirisYap,
            child: Text('Giriş Yap',
                style: GoogleFonts.dmSans(
                    color: AppColors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
 
/// Küçük etiket chip'i (kategori, tip vb. için).
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color bgColor;
  final Color textColor;
 
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.bgColor = AppColors.chipBg,
    this.textColor = AppColors.textSecondary,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
