// lib/features/ilanlar/presentation/widgets/ilan_yukleme_overlay.dart
// ignore_for_file: unused_element
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/banner_service.dart';
import 'package:google_fonts/google_fonts.dart';

class IlanYuklemeOverlay extends StatefulWidget {
  final bool aktif;
  final double progress; // eski API — kullanılmıyor
  final bool? basarili;  // null=bekleniyor, true=onaylandı, false=reddedildi
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

  // Faz 1: 10 saniyede 0→1 (bar değeri 0→%80 olarak yorumlanır)
  late final AnimationController _phase1Ctr;
  late final Animation<double> _phase1Anim;

  // Faz 2: basarili gelince %80→%100 hızla tamamla
  late final AnimationController _phase2Ctr;

  bool _tebriklerAktif = false;
  bool _tamamlandiCagrildi = false;

  double get _barValue => _phase1Anim.value * 0.8 + _phase2Ctr.value * 0.2;

  String get _asamaMetni {
    final p = _barValue;
    if (p < 0.20) return 'İlanınız alınıyor';
    if (p < 0.40) return 'İlanınız alındı';
    if (p < 0.60) return 'İlanınız inceleniyor';
    if (p < 0.80) return 'İlanınız değerlendiriliyor';
    if (widget.basarili == null) return 'İlanınız değerlendiriliyor';
    if (widget.basarili!) return 'İlanınız yayına hazırlanıyor';
    return 'İlanınız ilan verme kurallarına\nuygun değildir';
  }

  // Faz 1 sahte ilerleme ritmi: hızlı → bekle → hızlı → bekle → hızlı → bekle → yavaş
  static final _seq = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.00, end: 0.25).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.25), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.50).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.50), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.50, end: 0.75).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.75), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.00).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
  ]);

  @override
  void initState() {
    super.initState();

    _halkaCtr = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _phase1Ctr = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _phase1Anim = _seq.animate(_phase1Ctr);

    _phase2Ctr = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _phase1Ctr.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (widget.basarili != null) _baslaFaz2();
    });

    _phase2Ctr.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (_tamamlandiCagrildi) return;
      if (widget.basarili == true) {
        setState(() => _tebriklerAktif = true);
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            _tamamlandiCagrildi = true;
            widget.onTamamlandi?.call();
          }
        });
      } else {
        _tamamlandiCagrildi = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) widget.onTamamlandi?.call();
        });
      }
    });
  }

  @override
  void didUpdateWidget(IlanYuklemeOverlay old) {
    super.didUpdateWidget(old);

    if (widget.aktif && !old.aktif) {
      _tamamlandiCagrildi = false;
      _tebriklerAktif = false;
      _phase1Ctr.forward(from: 0);
      _phase2Ctr.reset();
      BannerService.instance.sustur();
    }
    if (!widget.aktif && old.aktif) {
      _phase1Ctr.reset();
      _phase2Ctr.reset();
      _tamamlandiCagrildi = false;
      _tebriklerAktif = false;
    }

    if (widget.basarili != old.basarili && widget.basarili != null) {
      if (_phase1Ctr.status == AnimationStatus.completed) {
        _baslaFaz2();
      }
    }
  }

  void _baslaFaz2() {
    if (_tamamlandiCagrildi) return;
    _phase2Ctr.forward(from: 0);
  }

  @override
  void dispose() {
    BannerService.instance.aktifEt();
    _halkaCtr.dispose();
    _phase1Ctr.dispose();
    _phase2Ctr.dispose();
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
            Container(color: Colors.black.withValues(alpha: 0.55)),

            // Yükleme içeriği — her zaman build'de, tebrikler aktifken gizle
            AnimatedOpacity(
              opacity: _tebriklerAktif ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _Halka(ctrl: _halkaCtr, renk: const Color(0xFFE24B4A), boyut: 100, hiz: 1.0, tersine: false),
                          _Halka(ctrl: _halkaCtr, renk: const Color(0xFFFAC775), boyut: 78,  hiz: 0.7, tersine: true),
                          _Halka(ctrl: _halkaCtr, renk: const Color(0xFF5DCAA5), boyut: 56,  hiz: 0.5, tersine: false),
                          Image.asset('assets/images/logo_beyaz.png', width: 36, height: 36, fit: BoxFit.contain),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: Listenable.merge([_phase1Anim, _phase2Ctr]),
                      builder: (_, _) => Text(
                        _asamaMetni,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: Listenable.merge([_phase1Anim, _phase2Ctr]),
                      builder: (_, _) {
                        final p = _barValue;
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
                                style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Tebrikler katmanı — üstte, aktif olunca fade in
            AnimatedOpacity(
              opacity: _tebriklerAktif ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5DCAA5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5DCAA5).withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Tebrikler! 🎉',
                        style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'İlanınız artık yayında',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
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
