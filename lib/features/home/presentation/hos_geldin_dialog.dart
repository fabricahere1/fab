// lib/features/home/presentation/hos_geldin_dialog.dart
//
// Hesabını yeni tamamlayıp ana sayfaya İLK KEZ ulaşan kullanıcıya
// gösterilen, yalnızca görselden oluşan tanıtım overlay'i. Görsel
// (assets/images/hosgeldin_banner.png) mesajı zaten içeriyor — burada
// ekstra başlık/metin YOK, yalnızca kapatma ikonu var.

import 'package:flutter/material.dart';

class HosGeldinDialog extends StatefulWidget {
  const HosGeldinDialog({super.key});

  @override
  State<HosGeldinDialog> createState() => _HosGeldinDialogState();
}

class _HosGeldinDialogState extends State<HosGeldinDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        ),
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
      ),
    );
  }
}
