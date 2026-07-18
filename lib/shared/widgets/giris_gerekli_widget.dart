import 'dart:math';

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

  static const List<String> _animasyonlar = [
    'assets/animations/bukalemun.json',
    'assets/animations/timsah.json',
  ];

  @override
  Widget build(BuildContext context) {
    final secilenAnimasyon =
        _animasyonlar[Random().nextInt(_animasyonlar.length)];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            secilenAnimasyon,
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
