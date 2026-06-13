// lib/features/ilanlar/presentation/widgets/ilan_yukleme_overlay.dart
// ignore_for_file: unused_element
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IlanYuklemeOverlay extends StatefulWidget {
  final bool aktif;
  final double progress; // eski API — iç zamanlayıcı kullanılıyor
  final bool? basarili;  // null=yükleniyor, true=onaylandı, false=reddedildi
  final VoidCallback? onTamamlandi;

  const IlanYuklemeOverlay({
    super.key,
    required this.aktif,
    this.progress = 0,
    this.basarili,
    this.onTamamlandi,
  });

  @override
  State<IlanYuklemeOverlay> createState() => _IlanYuklemeOverlayState();
}

class _IlanYuklemeOverlayState extends State<IlanYuklemeOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _halkaCtr;
  late final AnimationController _progressCtr;
  late final Animation<double> _progressAnim;
  bool _tamamlandiCagrildi = false;

  // Toplam 10 saniye:
  //  0→25% hızlı (1s) | bekle (1.5s) | 25→50% hızlı (1s) | bekle (1.5s)
  // 50→75% hızlı (1s) | bekle (1.5s) | 75→100% normal (3.5s)
  static final _seq = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.00, end: 0.25).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.25), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.50).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 0.50, end: 0.50), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.50, end: 0.75).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.75), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.00).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
  ]);

  @override
  void initState() {
    super.initState();
    _halkaCtr = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _progressCtr = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _progressAnim = _seq.animate(_progressCtr);

    _progressCtr.addStatusListener((status) {
      if (status == AnimationStatus.completed) _kontrolEt();
    });
  }

  @override
  void didUpdateWidget(IlanYuklemeOverlay old) {
    super.didUpdateWidget(old);

    if (widget.aktif && !old.aktif) {
      _tamamlandiCagrildi = false;
      _progressCtr.forward(from: 0);
    }
    if (!widget.aktif && old.aktif) {
      _progressCtr.reset();
      _tamamlandiCagrildi = false;
    }
    if (widget.basarili != old.basarili && widget.basarili != null) {
      _kontrolEt();
    }
  }

  void _kontrolEt() {
    if (_tamamlandiCagrildi) return;
    if (widget.basarili != null && _progressCtr.value >= 1.0) {
      _tamamlandiCagrildi = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onTamamlandi?.call();
      });
    }
  }

  @override
  void dispose() {
    _halkaCtr.dispose();
    _progressCtr.dispose();
    super.dispose();
  }

  String get _asamaMetni {
    final p = _progressAnim.value;
    if (p < 0.25) return 'İlanınız alınıyor';
    if (p < 0.50) return 'İlanınız alındı';
    if (p < 0.75) return 'İlanınız inceleniyor';
    if (widget.basarili == null) return 'İlanınız değerlendiriliyor';
    if (widget.basarili!) return 'İlanınız yayına hazırlanıyor';
    return 'İlanınız ilan verme kurallarına\nuygun değildir';
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
                        _Halka(ctrl: _halkaCtr, renk: const Color(0xFFE24B4A), boyut: 100, hiz: 1.0, tersine: false),
                        _Halka(ctrl: _halkaCtr, renk: const Color(0xFFFAC775), boyut: 78,  hiz: 0.7, tersine: true),
                        _Halka(ctrl: _halkaCtr, renk: const Color(0xFF5DCAA5), boyut: 56,  hiz: 0.5, tersine: false),
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

                  // Aşama yazısı
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, _) => Text(
                      _asamaMetni,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sahte yükleme barı
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, _) {
                      final p = _progressAnim.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: p,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.basarili == false && p >= 0.75
                                      ? const Color(0xFFE24B4A)
                                      : Colors.white,
                                ),
                                minHeight: 7,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '%${(p * 100).toInt()}',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
      builder: (_, _) {
        final tur = tersine ? -ctrl.value * hiz : ctrl.value * hiz;
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
