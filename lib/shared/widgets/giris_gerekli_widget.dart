import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_colors.dart';

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
          Lottie.asset(
            'assets/animations/bukalemun.json',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(mesaj,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onGirisYap,
            child: Text('Giriş Yap',
                style: GoogleFonts.dmSans(
                    color: Colors.black, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
