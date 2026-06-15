import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/banner_service.dart';

enum _Durum { yukleniyor, tebrikler, reddedildi }

class IlanYuklemeOverlay extends StatefulWidget {
  final bool aktif;
  final bool? basarili;
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

  _Durum _durum = _Durum.yukleniyor;
  bool _basariliGeldi = false;

  late final AnimationController _halkaCtr;
  late final AnimationController _barCtr;
  late final Animation<double>   _barAnim;
  late final AnimationController _tamamlaCtr;
  late final AnimationController _gecissCtr;
  late final AnimationController _sallaCtr;
  late final AnimationController _geriSayimCtr;

  static final _seq = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.00, end: 0.25).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.25), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.50).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.50), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.50, end: 0.75).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(0.75), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.00).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
  ]);

  static final _shakeTween = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end:  7.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin:  7.0, end: -7.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -7.0, end:  5.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin:  5.0, end: -3.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -3.0, end:  0.0), weight: 1),
  ]);

  @override
  void initState() {
    super.initState();

    _halkaCtr        = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _barCtr          = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _barAnim         = _seq.animate(_barCtr);
    _tamamlaCtr      = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _gecissCtr       = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _sallaCtr        = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _geriSayimCtr    = AnimationController(vsync: this, duration: const Duration(seconds: 10));

    _barCtr.addStatusListener((s) {
      if (s == AnimationStatus.completed && _basariliGeldi) _baslaFaz2();
    });

    _tamamlaCtr.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _gosterSonuc();
    });

    _geriSayimCtr.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        widget.onTamamlandi?.call();
      }
    });
  }

  @override
  void didUpdateWidget(IlanYuklemeOverlay old) {
    super.didUpdateWidget(old);

    if (widget.aktif && !old.aktif) {
      _durum = _Durum.yukleniyor;
      _basariliGeldi = false;
      _barCtr.forward(from: 0);
      _tamamlaCtr.reset();
      _gecissCtr.reset();
      _sallaCtr.reset();
      _geriSayimCtr.reset();
      BannerService.instance.sustur();
    }

    if (widget.basarili != old.basarili && widget.basarili != null) {
      _basariliGeldi = true;
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
    _geriSayimCtr.dispose();
    super.dispose();
  }

  void _baslaFaz2() => _tamamlaCtr.forward(from: 0);

  void _gosterSonuc() {
    final basarili = widget.basarili == true;
    setState(() => _durum = basarili ? _Durum.tebrikler : _Durum.reddedildi);
    _gecissCtr.forward(from: 0);
    if (basarili) {
      HapticFeedback.mediumImpact();
      _sallaCtr.forward(from: 0);
    }
    _geriSayimCtr.forward(from: 0);
  }

  void _kapat() {
    _geriSayimCtr.stop();
    widget.onTamamlandi?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.aktif ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !widget.aktif,
        child: Material(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Yükleme ekranı
              AnimatedOpacity(
                opacity: _durum == _Durum.yukleniyor ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _YuklemeIcerik(
                  halkaCtr: _halkaCtr,
                  barAnim: _barAnim,
                  tamamlaCtr: _tamamlaCtr,
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
                    child: _SonucIcerik(
                      basarili: true,
                      geriSayimCtr: _geriSayimCtr,
                      onKapat: _kapat,
                    ),
                  ),
                ),

              // Reddedildi ekranı
              if (_durum == _Durum.reddedildi)
                FadeTransition(
                  opacity: _gecissCtr,
                  child: _SonucIcerik(
                    basarili: false,
                    geriSayimCtr: _geriSayimCtr,
                    onKapat: _kapat,
                  ),
                ),
            ],
          ),
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

  const _YuklemeIcerik({
    required this.halkaCtr,
    required this.barAnim,
    required this.tamamlaCtr,
  });

  double _barDeger(double barVal, double tamamlaVal) =>
      barVal * 0.8 + tamamlaVal * 0.2;

  String _asamaMetni(double p) {
    if (p < 0.20) return 'İlanınız alınıyor';
    if (p < 0.40) return 'İlanınız alındı';
    if (p < 0.60) return 'İlanınız inceleniyor';
    return 'İlanınız değerlendiriliyor';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _Halka(ctrl: halkaCtr, renk: const Color(0xFFE24B4A), boyut: 100, hiz: 1.0, tersine: false),
                  _Halka(ctrl: halkaCtr, renk: const Color(0xFFFAC775), boyut: 78,  hiz: 0.7, tersine: true),
                  _Halka(ctrl: halkaCtr, renk: const Color(0xFF5DCAA5), boyut: 56,  hiz: 0.5, tersine: false),
                  Image.asset('assets/images/logo.png', width: 36, height: 36, fit: BoxFit.contain),
                ],
              ),
            ),
            const SizedBox(height: 32),

            AnimatedBuilder(
              animation: Listenable.merge([barAnim, tamamlaCtr]),
              builder: (_, _) {
                final p = _barDeger(barAnim.value, tamamlaCtr.value);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _asamaMetni(p),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: p,
                        backgroundColor: const Color(0xFFE8E8E8),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5DCAA5)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '%${(p * 100).toInt()}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              'İçerik kontrolü yapıyoruz, neredeyse bitti...',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF999999),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sonuç içeriği (Tebrikler / Reddedildi) ────────────────────────────────────

class _SonucIcerik extends StatelessWidget {
  final bool basarili;
  final AnimationController geriSayimCtr;
  final VoidCallback onKapat;

  const _SonucIcerik({
    required this.basarili,
    required this.geriSayimCtr,
    required this.onKapat,
  });

  @override
  Widget build(BuildContext context) {
    final renk = basarili ? const Color(0xFF5DCAA5) : const Color(0xFFE24B4A);
    final ikon = basarili ? Icons.check_rounded : Icons.close_rounded;
    final baslik = basarili ? 'Tebrikler!' : 'İlan Yayınlanamadı';
    final aciklama = basarili
        ? 'İlanınız artık yayında'
        : 'İlanınız ilan verme kurallarına uygun olmadığı için yayınlanamadı. Lütfen kontrol edip tekrar deneyin.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, color: renk, size: 40),
            ),
            const SizedBox(height: 24),

            // Başlık
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),

            // Açıklama
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Geri sayım bar
            AnimatedBuilder(
              animation: geriSayimCtr,
              builder: (_, _) => ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: 1.0 - geriSayimCtr.value,
                  backgroundColor: const Color(0xFFE8E8E8),
                  valueColor: AlwaysStoppedAnimation<Color>(renk),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kapat butonu
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onKapat,
                style: TextButton.styleFrom(
                  backgroundColor: renk,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Kapat',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
