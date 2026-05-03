// lib/features/ilanlar/presentation/widgets/ilan_banner.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IlanBanner extends StatefulWidget {
  final double yukseklik;
  const IlanBanner({super.key, required this.yukseklik});

  @override
  State<IlanBanner> createState() => _IlanBannerState();
}

class _IlanBannerState extends State<IlanBanner>
    with TickerProviderStateMixin {

  static const _slaytlar = [
    (
      satirlar: ['İster Yurtdışından', "Türkiye'ye"],
      resim: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
    ),
    (
      satirlar: ["İster Türkiye'den", 'Yurtdışına'],
      resim: 'https://images.unsplash.com/photo-1548574505-5e239809ee19?w=800&q=80',
    ),
    (
      satirlar: ['Sen Nerede', 'Olursan Ol'],
      resim: 'https://images.unsplash.com/photo-1569154941061-e231b4aa8092?w=800&q=80',
    ),
    (
      satirlar: ['Nerden', 'İstersen İste'],
      resim: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
    ),
    (
      satirlar: ['Yeterki', 'Sen İste'],
      resim: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
    ),
  ];

  int  _aktif          = 0;
  bool _gecisVar       = false;
  bool _otomatikAktif  = true;

  final List<AnimationController> _harfCtrls  = [];
  final List<AnimationController> _sallaCtrls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _girisBaslat());
    _otomatikGecis();
  }

  void _temizle() {
    for (final c in _harfCtrls)  { c.stop(); c.dispose(); }
    for (final c in _sallaCtrls) { c.stop(); c.dispose(); }
    _harfCtrls.clear();
    _sallaCtrls.clear();
  }

  void _girisBaslat() {
    if (!mounted) return;
    _temizle();

    final satirlar = _slaytlar[_aktif].satirlar;
    final List<(int, int)> esleme = [];
    for (int si = 0; si < satirlar.length; si++) {
      int hi = 0;
      for (final ch in satirlar[si].characters) {
        if (ch != ' ') { esleme.add((si, hi)); hi++; }
      }
    }

    for (int i = 0; i < esleme.length; i++) {
      final (_, hi) = esleme[i];
      final delayMs = (hi * 28 + (i * 13) % 100).toInt();
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      );
      _harfCtrls.add(ctrl);
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) ctrl.forward();
      });
    }

    final sonMs = esleme.isNotEmpty
        ? (esleme.last.$2 * 28 + esleme.length * 13) + 560
        : 560;
    Future.delayed(Duration(milliseconds: sonMs), () {
      if (!mounted) return;
      for (int i = 0; i < _harfCtrls.length; i++) {
        final sc = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 2000 + (i * 41 % 500)),
        )..repeat(reverse: true);
        _sallaCtrls.add(sc);
      }
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  Future<void> _cikisBaslat() async {
    for (int i = _harfCtrls.length - 1; i >= 0; i--) {
      _harfCtrls[i].reverse();
      await Future.delayed(const Duration(milliseconds: 18));
    }
    await Future.delayed(const Duration(milliseconds: 240));
  }

  Future<void> _gecis(int hedef) async {
    if (_gecisVar || !mounted) return;
    _gecisVar      = true;
    _otomatikAktif = false;
    await _cikisBaslat();
    if (!mounted) return;
    setState(() => _aktif = hedef);
    _girisBaslat();
    _gecisVar      = false;
    _otomatikAktif = true;
    _otomatikGecis();
  }

  void _otomatikGecis() {
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (!mounted || !_otomatikAktif) return;
      _gecis((_aktif + 1) % _slaytlar.length);
    });
  }

  @override
  void dispose() {
    _temizle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slayt = _slaytlar[_aktif];

    return SizedBox(
      height: widget.yukseklik,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.network(
              slayt.resim,
              key: ValueKey(slayt.resim),
              fit: BoxFit.cover,
              width: double.infinity,
              height: widget.yukseklik,
              errorBuilder: (_, _, _) =>
                  Container(color: const Color(0xFFE53935)),
              loadingBuilder: (_, child, prog) => prog == null
                  ? child
                  : Container(color: const Color(0xFF8B0000)),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x88000000), Color(0xBB000000)],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildSatirlar(),
              ),
            ),
          ),
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slaytlar.length, (i) {
                final secili = i == _aktif;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  secili ? 20 : 5,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                        alpha: secili ? 0.95 : 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSatirlar() {
    final satirlar = _slaytlar[_aktif].satirlar;
    final widgets  = <Widget>[];
    int ctrlIdx    = 0;

    for (int si = 0; si < satirlar.length; si++) {
      final satirWidgets = <Widget>[];

      for (final ch in satirlar[si].characters) {
        if (ch == ' ') {
          satirWidgets.add(const SizedBox(width: 6));
          continue;
        }
        if (ctrlIdx >= _harfCtrls.length) { ctrlIdx++; continue; }

        final harfCtrl  = _harfCtrls[ctrlIdx];
        final sallaCtrl = ctrlIdx < _sallaCtrls.length
            ? _sallaCtrls[ctrlIdx]
            : null;

        final seed   = (si * 31 + ctrlIdx * 17).toDouble();
        final txBase = ((seed * 7.3) % 60) - 30;
        final tyBase = ((seed * 3.7) % 50) + 20;
        ctrlIdx++;

        final girisAnim = CurvedAnimation(
          parent: harfCtrl,
          curve: Curves.elasticOut,
        );

        satirWidgets.add(
          AnimatedBuilder(
            animation: Listenable.merge([
              harfCtrl,
              ?sallaCtrl,
            ]),
            builder: (_, _) {
              final t          = girisAnim.value;
              final tx         = txBase * (1 - t);
              final ty         = tyBase * (1 - t);
              final scale      = 0.3 + t * 0.7;
              final angle      = ((seed % 40) - 20) / 180 * 3.14 * (1 - t);
              final sallaAngle = (sallaCtrl != null && harfCtrl.isCompleted)
                  ? (sallaCtrl.value - 0.5) * 0.04
                  : 0.0;

              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(tx, ty, 0, 1)
                    ..rotateZ(angle + sallaAngle)
                    ..scaleByDouble(scale, scale, 1, 1),
                  child: Text(
                    ch,
                    style: GoogleFonts.dmSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                      shadows: const [
                        Shadow(
                          color: Color(0x88000000),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }

      widgets.add(Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: satirWidgets,
      ));
      if (si < satirlar.length - 1) widgets.add(const SizedBox(height: 3));
    }
    return widgets;
  }
}
