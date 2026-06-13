// lib/features/ilanlar/presentation/widgets/ilan_yukleme_overlay.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IlanYuklemeOverlay extends StatefulWidget {
  final double progress;
  final bool aktif;

  const IlanYuklemeOverlay({
    super.key,
    required this.progress,
    required this.aktif,
  });

  @override
  State<IlanYuklemeOverlay> createState() => _IlanYuklemeOverlayState();
}

class _IlanYuklemeOverlayState extends State<IlanYuklemeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.aktif ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !widget.aktif,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Koyu arka plan
            Container(color: Colors.black.withValues(alpha: 0.55)),

            // Merkez içerik
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo + halkalar
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Halka 1 — kırmızı
                        _Halka(
                          ctrl: _ctrl,
                          renk: const Color(0xFFE24B4A),
                          boyut: 100,
                          hiz: 1.0,
                          tersine: false,
                        ),
                        // Halka 2 — sarı
                        _Halka(
                          ctrl: _ctrl,
                          renk: const Color(0xFFFAC775),
                          boyut: 78,
                          hiz: 0.7,
                          tersine: true,
                        ),
                        // Halka 3 — yeşil
                        _Halka(
                          ctrl: _ctrl,
                          renk: const Color(0xFF5DCAA5),
                          boyut: 56,
                          hiz: 0.5,
                          tersine: false,
                        ),
                        // Logo
                        Image.asset(
                          'assets/images/logo_beyaz.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Yükleniyor yazısı
                  Text(
                    widget.progress >= 1.0
                        ? 'İlanınız başarıyla bize ulaştı 🎉'
                        : 'İlan yükleniyor...',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.progress >= 1.0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'İlanınız inceleniyor, bu işlem\nbir kaç dakika sürebilir.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Progress bar
                  SizedBox(
                    width: 180,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: widget.progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '%${(widget.progress * 100).toInt()}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dönen halka ───────────────────────────────────────────────────────────────

class _Halka extends StatelessWidget {
  final AnimationController ctrl;
  final Color renk;
  final double boyut;
  final double hiz;
  final bool tersine;

  const _Halka({
    required this.ctrl,
    required this.renk,
    required this.boyut,
    required this.hiz,
    required this.tersine,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final tur = tersine
            ? -ctrl.value * hiz
            : ctrl.value * hiz;
        return Transform.rotate(
          angle: tur * 2 * math.pi,
          child: SizedBox(
            width: boyut,
            height: boyut,
            child: CustomPaint(painter: _HalkaPainter(renk)),
          ),
        );
      },
    );
  }
}

class _HalkaPainter extends CustomPainter {
  final Color renk;
  const _HalkaPainter(this.renk);

  @override
  void paint(Canvas canvas, Size size) {
    final boya = Paint()
      ..color = renk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      math.pi * 1.2,
      false,
      boya,
    );
  }

  @override
  bool shouldRepaint(covariant _HalkaPainter old) => old.renk != renk;
}