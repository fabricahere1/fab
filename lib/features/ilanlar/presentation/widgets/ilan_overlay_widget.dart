import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/banner_service.dart';

// Overlay'in iç durumu
enum _Durum { yukleniyor, tebrikler, reddedildi }

class IlanYuklemeOverlay extends StatefulWidget {
  final bool aktif;
  final bool? basarili; // null=CF bekleniyor, true=yayında, false=reddedildi
  final VoidCallback? onTamamlandi;

  const IlanYuklemeOverlay({
    super.key,
    required this.aktif,
    this.basarili,
    this.onTamamlandi,
  });

  @override
  State<IlanYuklemeOverlay> createState() => _IlanYuklemeOverlayState();
}

class _IlanYuklemeOverlayState extends State<IlanYuklemeOverlay>
    with TickerProviderStateMixin {

  // ── Durum ──────────────────────────────────────────────────────────────────
  _Durum _durum = _Durum.yukleniyor;
  bool _basariliGeldi = false; // CF sonucu bar bitmeden geldiyse beklet

  // ── Animasyon controller'ları ──────────────────────────────────────────────
  late final AnimationController _halkaCtr;   // dönen halkalar
  late final AnimationController _barCtr;     // faz 1: 0→%80 (10sn)
  late final Animation<double>   _barAnim;
  late final AnimationController _tamamlaCtr; // faz 2: %80→%100 (600ms)
  late final AnimationController _gecissCtr;  // sonuç ekranı fade-in (350ms)
  late final AnimationController _sallaCtr;   // tebrikler shake (700ms)

  // ── Sahte ilerleme sekansı ─────────────────────────────────────────────────
  // hızlı → bekle → hızlı → bekle → hızlı → bekle → yavaş kapanış
  static final _seq = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.00, end: 0.25).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.25), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.50).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.50), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.50, end: 0.75).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.75), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.00).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
  ]);

  // ── Shake tweeni ───────────────────────────────────────────────────────────
  static final _shakeTween = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end:  7.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin:  7.0, end: -7.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -7.0, end:  5.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin:  5.0, end: -3.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -3.0, end:  0.0), weight: 1),
  ]);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _halkaCtr = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _barCtr     = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _barAnim    = _seq.animate(_barCtr);
    _tamamlaCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _gecissCtr  = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _sallaCtr   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    // Faz 1 bitince: CF geldiyse hemen faz 2'ye geç, gelmediyse beklet bayrağı zaten var
    _barCtr.addStatusListener((s) {
      if (s == AnimationStatus.completed && _basariliGeldi) _baslaFaz2();
    });

    // Faz 2 bitince: sonuç ekranını göster
    _tamamlaCtr.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _gosterSonuc();
    });
  }

  @override
  void didUpdateWidget(IlanYuklemeOverlay old) {
    super.didUpdateWidget(old);

    // Overlay açıldı
    if (widget.aktif && !old.aktif) {
      _durum = _Durum.yukleniyor;
      _basariliGeldi = false;
      _barCtr.forward(from: 0);
      _tamamlaCtr.reset();
      _gecissCtr.reset();
      _sallaCtr.reset();
      BannerService.instance.sustur();
    }

    // CF sonucu yeni geldi
    if (widget.basarili != old.basarili && widget.basarili != null) {
      _basariliGeldi = true;
      // Bar bittiyse hemen faz 2, bitmemişse _barCtr listener halleder
      if (_barCtr.status == AnimationStatus.completed) _baslaFaz2();
    }
  }

  @override
  void dispose() {
    BannerService.instance.aktifEt();
    _halkaCtr.dispose();
    _barCtr.dispose();
    _tamamlaCtr.dispose();
    _gecissCtr.dispose();
    _sallaCtr.dispose();
    super.dispose();
  }

  // ── Animasyon adımları ─────────────────────────────────────────────────────
  void _baslaFaz2() => _tamamlaCtr.forward(from: 0);

  void _gosterSonuc() {
    final basarili = widget.basarili == true;
    setState(() => _durum = basarili ? _Durum.tebrikler : _Durum.reddedildi);
    _gecissCtr.forward(from: 0);

    if (basarili) {
      HapticFeedback.mediumImpact();
      _sallaCtr.forward(from: 0);
    }

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onTamamlandi?.call();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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

            // Yükleme ekranı — sonuç gelene kadar göster
            AnimatedOpacity(
              opacity: _durum == _Durum.yukleniyor ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: _YuklemeIcerik(
                halkaCtr: _halkaCtr,
                barAnim: _barAnim,
                tamamlaCtr: _tamamlaCtr,
                basarili: widget.basarili,
              ),
            ),

            // Tebrikler ekranı
            if (_durum == _Durum.tebrikler)
              FadeTransition(
                opacity: _gecissCtr,
                child: AnimatedBuilder(
                  animation: _sallaCtr,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeTween.evaluate(_sallaCtr), 0),
                    child: child,
                  ),
                  child: const _TebriklerIcerik(),
                ),
              ),

            // Reddedildi ekranı
            if (_durum == _Durum.reddedildi)
              FadeTransition(
                opacity: _gecissCtr,
                child: const _ReddedildiIcerik(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Yükleme içeriği ───────────────────────────────────────────────────────────

class _YuklemeIcerik extends StatelessWidget {
  final AnimationController halkaCtr;
  final Animation<double> barAnim;
  final AnimationController tamamlaCtr;
  final bool? basarili;

  const _YuklemeIcerik({
    required this.halkaCtr,
    required this.barAnim,
    required this.tamamlaCtr,
    required this.basarili,
  });

  // Her AnimatedBuilder rebuild'inde hesaplanır — stale olmaz
  double _barDeger(double barAnimVal, double tamamlaVal) =>
      barAnimVal * 0.8 + tamamlaVal * 0.2;

  String _asamaMetni(double p) {
    if (p < 0.20) return 'İlanınız alınıyor';
    if (p < 0.40) return 'İlanınız alındı';
    if (p < 0.60) return 'İlanınız inceleniyor';
    return 'İlanınız değerlendiriliyor';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dönen halkalar + logo
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Halka(ctrl: halkaCtr, renk: const Color(0xFFE24B4A), boyut: 100, hiz: 1.0, tersine: false),
                _Halka(ctrl: halkaCtr, renk: const Color(0xFFFAC775), boyut: 78,  hiz: 0.7, tersine: true),
                _Halka(ctrl: halkaCtr, renk: const Color(0xFF5DCAA5), boyut: 56,  hiz: 0.5, tersine: false),
                Image.asset('assets/images/logo_beyaz.png', width: 36, height: 36, fit: BoxFit.contain),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Aşama metni + progress bar — tek AnimatedBuilder, her frame'de hesapla
          AnimatedBuilder(
            animation: Listenable.merge([barAnim, tamamlaCtr]),
            builder: (_, _) {
              final p = _barDeger(barAnim.value, tamamlaCtr.value);
              return Column(
                children: [
                  Text(
                    _asamaMetni(p),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: p,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              basarili == false ? const Color(0xFFE24B4A) : Colors.white,
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
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Tebrikler içeriği ─────────────────────────────────────────────────────────

class _TebriklerIcerik extends StatelessWidget {
  const _TebriklerIcerik();

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

// ── Reddedildi içeriği ────────────────────────────────────────────────────────

class _ReddedildiIcerik extends StatelessWidget {
  const _ReddedildiIcerik();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE24B4A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE24B4A).withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 28),
            Text(
              'İlan Yayınlanamadı',
              style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'İlanınız ilan verme kurallarına uygun olmadığı için yayınlanamadı. Lütfen kontrol edip tekrar deneyin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.80)),
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
