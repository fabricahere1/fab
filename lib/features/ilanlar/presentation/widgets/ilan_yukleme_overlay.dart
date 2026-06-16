// lib/features/ilanlar/presentation/widgets/ilan_yukleme_overlay.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IlanYuklemeOverlay extends StatefulWidget {
  final double progress;
  final bool aktif;
  final String? ilanId;
  final VoidCallback? onBitti;

  const IlanYuklemeOverlay({
    super.key,
    required this.progress,
    required this.aktif,
    this.ilanId,
    this.onBitti,
  });

  @override
  State<IlanYuklemeOverlay> createState() => _IlanYuklemeOverlayState();
}

enum _Asama {
  alinan,
  alindi,
  inceleniyor,
  hazirlaniyor,
  bitti,
}

class _IlanYuklemeOverlayState extends State<IlanYuklemeOverlay>
    with SingleTickerProviderStateMixin {

  late final AnimationController _halkaCtrl;

  double _barDeger = 0.0;
  _Asama _asama    = _Asama.alinan;
  bool?  _sonuc;

  StreamSubscription<DocumentSnapshot>? _firestoreSub;
  Timer? _t1, _t2, _t3, _tBitti;

  bool get _gorunur => widget.aktif || widget.ilanId != null;

  @override
  void initState() {
    super.initState();
    _halkaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didUpdateWidget(IlanYuklemeOverlay old) {
    super.didUpdateWidget(old);

    if (widget.ilanId != null && old.ilanId == null) {
      _firestoreDinle(widget.ilanId!);
    }

    if (widget.aktif && !old.aktif) {
      _sifirla();
      _animasyonuBaslat();
    }
  }

  void _sifirla() {
    _t1?.cancel(); _t2?.cancel(); _t3?.cancel(); _tBitti?.cancel();
    _firestoreSub?.cancel();
    _firestoreSub = null;
    setState(() {
      _barDeger = 0.0;
      _asama    = _Asama.alinan;
      _sonuc    = null;
    });
  }

  // 0.0s: %0  baslar
  // 0.0s: %0  -> %25 (800ms hizli)
  // 0.8s: %25 dur (1500ms bekle)
  // 2.3s: %25 -> %50 (800ms hizli)
  // 3.1s: %50 dur (1500ms bekle)
  // 4.6s: %50 -> %75 (800ms hizli)
  // 5.4s: %75 dur -- Firestore bekle
  // Firestore gelince: %75 -> %100 (800ms)

  void _animasyonuBaslat() {
    _setBar(0.25, ms: 800, asama: _Asama.alinan);

    _t1 = Timer(const Duration(milliseconds: 2300), () {
      if (!mounted) return;
      _setBar(0.50, ms: 800, asama: _Asama.alindi);
    });

    _t2 = Timer(const Duration(milliseconds: 4600), () {
      if (!mounted) return;
      _setBar(0.75, ms: 800, asama: _Asama.inceleniyor);
    });
  }

  void _setBar(double hedef, {required int ms, required _Asama asama}) {
    if (!mounted) return;
    final baslangic = _barDeger;
    final toplam    = ms ~/ 16;
    int adim        = 0;
    Timer.periodic(const Duration(milliseconds: 16), (t) {
      adim++;
      if (!mounted || adim > toplam) { t.cancel(); return; }
      final ease = 1 - math.pow(1 - adim / toplam, 3).toDouble();
      setState(() {
        _barDeger = baslangic + (hedef - baslangic) * ease;
        if (adim == toplam) {
          _barDeger = hedef;
          _asama    = asama;
        }
      });
    });
  }

  void _firestoreDinle(String ilanId) {
    _firestoreSub = FirebaseFirestore.instance
        .collection('ilanlar')
        .doc(ilanId)
        .snapshots()
        .listen((snap) {
      if (!mounted || !snap.exists) return;
      final durum = snap.data()?['durum'] as String?;
      if (durum == 'yayinda') {
        _sonucGeldi(uygun: true);
      } else if (durum == 'reddedildi') {
        _sonucGeldi(uygun: false);
      }
    });
  }

  void _sonucGeldi({required bool uygun}) {
    _firestoreSub?.cancel();
    _firestoreSub = null;

    final beklemeSure = _barDeger < 0.74
        ? Duration(milliseconds: (((0.75 - _barDeger) / 0.75) * 2000).toInt() + 600)
        : Duration.zero;

    _t3 = Timer(beklemeSure, () {
      if (!mounted) return;
      setState(() => _asama = _Asama.hazirlaniyor);
      _setBar(1.0, ms: 800, asama: _Asama.bitti);

      _tBitti = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _sonuc = uygun);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          widget.onBitti?.call();
        });
      });
    });
  }

  @override
  void dispose() {
    _halkaCtrl.dispose();
    _t1?.cancel(); _t2?.cancel(); _t3?.cancel(); _tBitti?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }

  String get _asamaMetni {
    switch (_asama) {
      case _Asama.alinan:
        return '\u0130lan\u0131n\u0131z al\u0131n\u0131yor...';
      case _Asama.alindi:
        return '\u0130lan\u0131n\u0131z al\u0131nd\u0131';
      case _Asama.inceleniyor:
        return '\u0130lan\u0131n\u0131z inceleniyor...';
      case _Asama.hazirlaniyor:
        return '\u0130lan\u0131n\u0131z yay\u0131na haz\u0131rlan\u0131yor';
      case _Asama.bitti:
        if (_sonuc == false) {
          return '\u0130lan\u0131n\u0131z ilan verme kurallar\u0131na uygun de\u011fildir';
        }
        return '\u0130lan\u0131n\u0131z yay\u0131na haz\u0131rlan\u0131yor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _gorunur ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_gorunur,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black.withValues(alpha: 0.55)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _Halka(ctrl: _halkaCtrl, renk: const Color(0xFFE24B4A),
                            boyut: 100, hiz: 1.0, tersine: false),
                        _Halka(ctrl: _halkaCtrl, renk: const Color(0xFFFAC775),
                            boyut: 78,  hiz: 0.7, tersine: true),
                        _Halka(ctrl: _halkaCtrl, renk: const Color(0xFF5DCAA5),
                            boyut: 56,  hiz: 0.5, tersine: false),
                        Image.asset(
                          'assets/images/logo_beyaz.png',
                          width: 36, height: 36, fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      _asamaMetni,
                      key: ValueKey(_asamaMetni),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: LinearProgressIndicator(
                        value: _barDeger,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 2,
                      ),
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
      builder: (_, child) {
        final tur = tersine ? -ctrl.value * hiz : ctrl.value * hiz;
        return Transform.rotate(
          angle: tur * 2 * math.pi,
          child: SizedBox(
            width: boyut, height: boyut,
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
      ..color       = renk
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap   = StrokeCap.round;

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