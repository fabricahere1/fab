// lib/features/home/presentation/hos_geldin_dialog.dart
//
// Hesabını yeni tamamlayıp ana sayfaya İLK KEZ ulaşan kullanıcıya
// gösterilen, yalnızca görselden oluşan tanıtım overlay'i. Görsel
// (assets/images/hosgeldin_banner.png) mesajı zaten içeriyor — burada
// ekstra başlık/metin YOK, yalnızca kapatma ikonu var.

import 'package:flutter/material.dart';

class HosGeldinDialog extends StatelessWidget {
  const HosGeldinDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.asset(
                'assets/images/hosgeldin_banner.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 20, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
