// İSTE — tanıtım (onboarding) ekranı · Model 1
//
// 3 sahne: Rota → Bavul → Pasaport. Her şey CustomPainter ile kodla çizilir;
// ikon fontu / görsel dosyası yok (release build'deki ikon tree-shaking
// sorunundan etkilenmez). Sadece Icons.add kullanılır (MaterialIcons, const).
//
// Kullanım:
//   IsteTanitimEkrani(
//     onTamamlandi: (hemenIlanVer) async { ... },
//   )
//   hemenIlanVer == true  → kullanıcı "Hemen ilan ver"e bastı
//   hemenIlanVer == false → kullanıcı son sayfada "Geç"e bastı
//
// "Animasyonları kaldır" erişilebilirlik ayarı açıksa sahneler son halleriyle
// gösterilir ve otomatik geçiş yapılmaz.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─────────────────────────────────────────────────────────────
// Renkler (Model 1)
// ─────────────────────────────────────────────────────────────
const _kirmizi = Color(0xFFE53935);
const _kirmiziBtn = Color(0xFFD32F2F);
const _kirmiziKoyu = Color(0xFFC62828);
const _kirmiziAcik = Color(0xFFFFB3AD);
const _sap = Color(0xFF8E1F1C);
const _lacivert = Color(0xFF1D3E8A);
const _krem = Color(0xFFFBF7F3);
const _murekkep = Color(0xFF1F1A2E);
const _soluk = Color(0xFF6E6577);
const _kara = Color(0xFFF0E4D7);
const _turkiye = Color(0xFFFFE1DE);
const _kapak = Color(0xFF7A1F2B);
const _altin = Color(0xFFE7C766);
const _fermuar = Color(0xFFFFD978);
const _yesil = Color(0xFF1E7B4F);
const _mor = Color(0xFF6B3FA0);
const _sayfaZemin = Color(0xFFFFFDF8);

// Eğriler
const _yumusak = Cubic(0.16, 1, 0.3, 1);
const _damgaEgri = Cubic(0.3, 0.7, 0.4, 1);
const _kapanis = Cubic(0.6, 0, 0.4, 1);
const _cevir = Cubic(0.4, 0, 0.2, 1);

/// Her sahnenin animasyonunun bittiği saniye. Otomatik geçiş = bitiş + 1.3 sn.
const _sahneBitis = [5.5, 5.3, 4.4];
const _bekleme = 1.3;

// ─────────────────────────────────────────────────────────────
// Yardımcılar
// ─────────────────────────────────────────────────────────────
double _lerp(double a, double b, double p) => a + (b - a) * p;

double _seg(double t, double s, double d) => ((t - s) / d).clamp(0.0, 1.0);

double _io(double x) {
  if (x < .5) return 4 * x * x * x;
  final y = -2 * x + 2;
  return 1 - y * y * y / 2;
}

Color _a(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

/// 0.4 → 1.08 → 1 büyüme (0.48 sn). Başlamadıysa 0.
double _pop(double t, double s) {
  final x = t - s;
  if (x <= 0) return 0;
  if (x >= .48) return 1;
  final p = x / .48;
  if (p < .6) return _lerp(.4, 1.08, _yumusak.transform(p / .6));
  return _lerp(1.08, 1, _io((p - .6) / .4));
}

class _Damga {
  const _Damga(this.olcek, this.aci, this.opak);
  final double olcek;
  final double aci; // radyan
  final double opak;
}

/// Mühür vuruşu: 2.4 → 0.94 → 1 ölçek, (r-12°) → r dönüş, 0.46 sn.
_Damga _damga(double t, double s, double rDerece) {
  final p = _seg(t, s, .46);
  final olcek = p < .7
      ? _lerp(2.4, .94, _damgaEgri.transform(p / .7))
      : _lerp(.94, 1, (p - .7) / .3);
  final derece = rDerece - 12 * (1 - _damgaEgri.transform(p));
  return _Damga(olcek, derece * math.pi / 180, _seg(t, s, .15));
}

void _opak(Canvas c, double a, VoidCallback ciz) {
  if (a <= 0) return;
  if (a >= 1) {
    ciz();
    return;
  }
  c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, a));
  ciz();
  c.restore();
}

void _golge(Canvas c, Offset m, double r, {double dy = 3, double a = .14}) {
  c.drawCircle(
    m + Offset(0, dy),
    r,
    Paint()
      ..color = _a(_murekkep, a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
}

Size _yazi(
  Canvas c,
  String s,
  Offset m, {
  double boyut = 10,
  Color renk = _murekkep,
  FontWeight kalinlik = FontWeight.w600,
  double aralik = 0,
  bool italik = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontSize: boyut,
        color: renk,
        fontWeight: kalinlik,
        letterSpacing: aralik,
        fontStyle: italik ? FontStyle.italic : FontStyle.normal,
        height: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  tp.paint(c, m - Offset(tp.width / 2, tp.height / 2));
  return tp.size;
}

/// Konuşma balonu. [uc] kuyruğun ucu; balon bunun üstünde durur.
void _balon(
  Canvas c,
  Offset uc,
  String metin,
  double olcek,
  double opak, {
  Color zemin = Colors.white,
  Color yazi = _murekkep,
}) {
  if (opak <= 0 || olcek <= 0) return;
  final tp = TextPainter(
    text: TextSpan(
      text: metin,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: yazi),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = tp.width + 20;
  final h = tp.height + 12;
  final sol = (uc.dx - w / 2).clamp(4.0, math.max(4.0, 278.0 - w)).toDouble();
  final ust = uc.dy - 7 - h;
  _opak(c, opak, () {
    c.save();
    c.translate(uc.dx, uc.dy);
    c.scale(olcek);
    c.translate(-uc.dx, -uc.dy);
    final r = RRect.fromLTRBR(sol, ust, sol + w, ust + h, const Radius.circular(11));
    final kuyruk = Path()
      ..moveTo(uc.dx - 6, ust + h - 1)
      ..lineTo(uc.dx, uc.dy)
      ..lineTo(uc.dx + 6, ust + h - 1)
      ..close();
    final sekil = Path()
      ..addRRect(r)
      ..addPath(kuyruk, Offset.zero);
    c.drawPath(
      sekil.shift(const Offset(0, 3)),
      Paint()
        ..color = _a(_murekkep, .12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawPath(sekil, Paint()..color = zemin);
    tp.paint(c, Offset(sol + 10, ust + 6));
    c.restore();
  });
}

Offset _qpt(Offset a, Offset k, Offset b, double q) =>
    a * ((1 - q) * (1 - q)) + k * (2 * (1 - q) * q) + b * (q * q);

/// Uçak silueti, +x yönüne bakar, yaklaşık 2 birim uzunluğunda.
Path _ucakYolu() {
  const n = [
    Offset(1, 0),
    Offset(.55, .12),
    Offset(.1, .12),
    Offset(-.35, .75),
    Offset(-.55, .75),
    Offset(-.3, .12),
    Offset(-.75, .12),
    Offset(-.95, .38),
    Offset(-1.08, .38),
    Offset(-.95, 0),
  ];
  final p = Path()..moveTo(n[0].dx, n[0].dy);
  for (var i = 1; i < n.length; i++) {
    p.lineTo(n[i].dx, n[i].dy);
  }
  for (var i = n.length - 2; i >= 1; i--) {
    p.lineTo(n[i].dx, -n[i].dy);
  }
  return p..close();
}

final Path _ucakSekli = _ucakYolu();

/// Damla şeklinde pin; [uc] alt sivri nokta.
Path _pinYolu(Offset uc, double r) {
  final m = uc.translate(0, -r * 1.7);
  return Path()
    ..moveTo(uc.dx, uc.dy)
    ..quadraticBezierTo(m.dx - r * 1.05, m.dy + r * .9, m.dx - r, m.dy)
    ..arcTo(Rect.fromCircle(center: m, radius: r), math.pi, math.pi, false)
    ..quadraticBezierTo(m.dx + r * 1.05, m.dy + r * .9, uc.dx, uc.dy)
    ..close();
}

/// Noktalardan yumuşak kapalı şekil (Catmull-Rom).
Path _blob(List<Offset> n) {
  final p = Path()..moveTo(n[0].dx, n[0].dy);
  final l = n.length;
  for (var i = 0; i < l; i++) {
    final p0 = n[(i - 1 + l) % l];
    final p1 = n[i];
    final p2 = n[(i + 1) % l];
    final p3 = n[(i + 2) % l];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return p..close();
}

final Path _avrupa = _blob(const [
  Offset(14, 70), Offset(60, 52), Offset(120, 48), Offset(190, 62),
  Offset(205, 100), Offset(170, 140), Offset(120, 150), Offset(80, 135),
  Offset(40, 140), Offset(20, 110),
]);
final Path _turkiyeYolu = _blob(const [
  Offset(112, 160), Offset(150, 150), Offset(196, 156), Offset(214, 172),
  Offset(190, 190), Offset(140, 192), Offset(116, 180),
]);
final Path _arabistan = _blob(const [
  Offset(190, 205), Offset(240, 200), Offset(272, 230), Offset(262, 290),
  Offset(220, 305), Offset(196, 262),
]);
final Path _afrika = _blob(const [
  Offset(10, 205), Offset(80, 198), Offset(170, 215), Offset(180, 260),
  Offset(140, 330), Offset(60, 330), Offset(20, 280),
]);

/// Eşya çizimi. [s] ≈ yarı genişlik (px).
void _esya(Canvas c, String tur, Offset m, double s) {
  if (s <= 0) return;
  c.save();
  c.translate(m.dx, m.dy);
  c.scale(s / 14);
  final cizgi = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = _a(_murekkep, .3);
  if (tur == 'ayakkabi') {
    final ust = Path()
      ..moveTo(-13, 4)
      ..lineTo(-12, -5)
      ..quadraticBezierTo(-6, -8, -3, -6)
      ..lineTo(3, -1)
      ..quadraticBezierTo(11, 0, 14, 4)
      ..close();
    c.drawPath(ust, Paint()..color = _kirmizi);
    final taban = RRect.fromLTRBR(-14, 3.5, 14, 9, const Radius.circular(3));
    c.drawRRect(taban, Paint()..color = Colors.white);
    c.drawRRect(taban, cizgi);
    final bag = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-5, -4), const Offset(-2, -5.5), bag);
    c.drawLine(const Offset(-3, -2), const Offset(0, -3.5), bag);
    c.drawLine(const Offset(-1, 0), const Offset(2, -1.5), bag);
    c.drawCircle(const Offset(-10, -1), 1.6, Paint()..color = _kirmiziKoyu);
  } else if (tur == 'parfum') {
    c.drawRRect(
      RRect.fromLTRBR(-2.5, -9, 2.5, -4, const Radius.circular(1)),
      Paint()..color = _a(_murekkep, .25),
    );
    c.drawRRect(
      RRect.fromLTRBR(-5, -14, 5, -8, const Radius.circular(2)),
      Paint()..color = _altin,
    );
    final govde = RRect.fromLTRBR(-10, -5, 10, 13, const Radius.circular(5));
    c.drawRRect(govde, Paint()..color = const Color(0xFFF7C6CF));
    c.drawRRect(
      RRect.fromLTRBR(-10, 3, 10, 13, const Radius.circular(5)),
      Paint()..color = const Color(0xFFEE9AAE),
    );
    c.drawRRect(govde, cizgi);
    c.drawLine(
      const Offset(-6, -2),
      const Offset(-6, 7),
      Paint()
        ..color = _a(Colors.white, .8)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  } else if (tur == 'kahve') {
    final torba = Path()
      ..moveTo(-10, -10)
      ..lineTo(10, -10)
      ..lineTo(12, 13)
      ..lineTo(-12, 13)
      ..close();
    c.drawPath(torba, Paint()..color = const Color(0xFF7B4A2D));
    c.drawRect(const Rect.fromLTRB(-10, -13, 10, -9), Paint()..color = const Color(0xFF5E3820));
    c.drawCircle(const Offset(0, 2), 6, Paint()..color = const Color(0xFFF5E6D3));
    c.save();
    c.translate(0, 2);
    c.rotate(.5);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 5, height: 7.5),
        Paint()..color = const Color(0xFF5E3820));
    c.drawLine(const Offset(0, -3), const Offset(0, 3),
        Paint()
          ..color = const Color(0xFFF5E6D3)
          ..strokeWidth = .9);
    c.restore();
  } else if (tur == 'kulaklik') {
    c.drawArc(
      const Rect.fromLTRB(-11, -12, 11, 10),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = _lacivert,
    );
    final kulak = Paint()..color = _lacivert;
    c.drawRRect(RRect.fromLTRBR(-14, -1, -6, 12, const Radius.circular(3)), kulak);
    c.drawRRect(RRect.fromLTRBR(6, -1, 14, 12, const Radius.circular(3)), kulak);
    final ped = Paint()..color = _a(Colors.white, .35);
    c.drawRRect(RRect.fromLTRBR(-8.5, 1, -6, 10, const Radius.circular(1)), ped);
    c.drawRRect(RRect.fromLTRBR(6, 1, 8.5, 10, const Radius.circular(1)), ped);
  } else if (tur == 'telefon') {
    c.drawRRect(RRect.fromLTRBR(-8, -14, 8, 14, const Radius.circular(3.5)),
        Paint()..color = _murekkep);
    c.drawRRect(
      RRect.fromLTRBR(-6.5, -11, 6.5, 10, const Radius.circular(1.5)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FB3FF), Color(0xFFC6A8FF)],
        ).createShader(const Rect.fromLTRB(-6.5, -11, 6.5, 10)),
    );
    c.drawCircle(const Offset(0, 12), 1, Paint()..color = _a(Colors.white, .5));
  }
  c.restore();
}

/// Küçük bayrak; [r] bayrağın dikdörtgeni.
void _bayrak(Canvas c, String kod, Rect r) {
  c.save();
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(1.5));
  c.drawRRect(rr.inflate(1.2), Paint()..color = Colors.white);
  c.clipRRect(rr);
  final w = r.width;
  final h = r.height;
  if (kod == 'uk') {
    c.drawRect(r, Paint()..color = const Color(0xFF012169));
    final beyaz = Paint()
      ..color = Colors.white
      ..strokeWidth = h * .3;
    final kirmizi = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = h * .12;
    c.drawLine(r.topLeft, r.bottomRight, beyaz);
    c.drawLine(r.bottomLeft, r.topRight, beyaz);
    c.drawLine(r.topLeft, r.bottomRight, kirmizi);
    c.drawLine(r.bottomLeft, r.topRight, kirmizi);
    c.drawRect(Rect.fromCenter(center: r.center, width: w, height: h * .36), Paint()..color = Colors.white);
    c.drawRect(Rect.fromCenter(center: r.center, width: h * .36, height: h), Paint()..color = Colors.white);
    c.drawRect(Rect.fromCenter(center: r.center, width: w, height: h * .2), Paint()..color = const Color(0xFFC8102E));
    c.drawRect(Rect.fromCenter(center: r.center, width: h * .2, height: h), Paint()..color = const Color(0xFFC8102E));
  } else if (kod == 'fr') {
    const renkler = [Color(0xFF0055A4), Colors.white, Color(0xFFEF4135)];
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(r.left + w * i / 3, r.top, w / 3 + .5, h), Paint()..color = renkler[i]);
    }
  } else if (kod == 'de') {
    const renkler = [Color(0xFF111111), Color(0xFFDD0000), Color(0xFFFFCE00)];
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(r.left, r.top + h * i / 3, w, h / 3 + .5), Paint()..color = renkler[i]);
    }
  } else if (kod == 'ae') {
    const renkler = [Color(0xFF00732F), Colors.white, Color(0xFF111111)];
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(r.left, r.top + h * i / 3, w, h / 3 + .5), Paint()..color = renkler[i]);
    }
    c.drawRect(Rect.fromLTWH(r.left, r.top, w * .27, h), Paint()..color = const Color(0xFFFF0000));
  }
  c.restore();
}

// ─────────────────────────────────────────────────────────────
// Sahne 1 — Rota (282 x 340)
// ─────────────────────────────────────────────────────────────
class _RotaPainter extends CustomPainter {
  _RotaPainter(this.t);
  final double t;

  static const ist = Offset(150, 170);
  static const lon = Offset(50, 96);
  static const ber = Offset(112, 86);
  static const dxb = Offset(232, 240);

  Offset _k(Offset a, double kalkis) =>
      Offset((a.dx + ist.dx) / 2, (a.dy + ist.dy) / 2 - kalkis);

  @override
  void paint(Canvas c, Size size) {
    final h = _yumusak.transform(_seg(t, 0, .6));
    _opak(c, h, () {
      c.save();
      final o = _lerp(.96, 1, h);
      c.translate(141, 170);
      c.scale(o);
      c.translate(-141, -170);
      _harita(c);
      c.restore();
    });

    _sehir(c, lon, 'Londra', 1.35, nabiz: true);
    _sehir(c, ber, 'Berlin', 3.6);
    _sehir(c, dxb, 'Dubai', 3.6);

    _rota(c, lon, 70, 2.15, .55);
    _rota(c, ber, 45, 3.85, .48);
    _rota(c, dxb, 60, 3.85, .48);

    _pin(c);

    _ucak(c, lon, 70, 2.7, 1.1);
    _ucak(c, ber, 45, 4.35, .9);
    _ucak(c, dxb, 60, 4.5, .9);

    _teslim(c, 'ayakkabi', -30, 3.8);
    _teslim(c, 'kahve', 0, 5.25);
    _teslim(c, 'parfum', 30, 5.4);

    _yolcu(c);

    final gizle1 = _seg(t, 2.15, .25);
    _balon(
      c,
      Offset(ist.dx, ist.dy - 34),
      "Londra'dan sneaker istiyorum",
      _pop(t, .75) * _lerp(1, .85, gizle1),
      _seg(t, .75, .2) * (1 - gizle1),
    );
    final gizle2 = _seg(t, 2.7, .25);
    _balon(
      c,
      Offset(lon.dx, lon.dy - 46),
      'Ben getiririm!',
      _pop(t, 1.75) * _lerp(1, .85, gizle2),
      _seg(t, 1.75, .2) * (1 - gizle2),
      zemin: _lacivert,
      yazi: Colors.white,
    );
  }

  void _harita(Canvas c) {
    final kart = RRect.fromLTRBR(4, 8, 278, 332, const Radius.circular(20));
    c.drawRRect(kart, Paint()..color = const Color(0xFFFFFDFA));
    c.save();
    c.clipRRect(kart);
    final nokta = Paint()..color = _a(_murekkep, .05);
    for (double x = 18; x < 278; x += 18) {
      for (double y = 22; y < 332; y += 18) {
        c.drawCircle(Offset(x, y), .8, nokta);
      }
    }
    final kara = Paint()..color = _kara;
    c.drawPath(_avrupa, kara);
    c.drawPath(_afrika, kara);
    c.drawPath(_arabistan, kara);
    c.drawPath(_turkiyeYolu, Paint()..color = _turkiye);
    c.restore();
    c.drawRRect(
      kart,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kara,
    );
  }

  void _sehir(Canvas c, Offset m, String ad, double bas, {bool nabiz = false}) {
    final o = _pop(t, bas);
    if (o <= 0) return;
    if (nabiz) {
      final f = ((t - bas) % 1.4) / 1.4;
      c.drawCircle(m, 4 + 14 * f, Paint()..color = _a(_lacivert, .35 * (1 - f)));
    }
    c.drawCircle(m, 4.6 * o, Paint()..color = Colors.white);
    c.drawCircle(m, 3.2 * o, Paint()..color = _lacivert);
    _opak(c, _seg(t, bas + .1, .3), () {
      _yazi(c, ad, m + const Offset(0, 11),
          boyut: 8.5, renk: _soluk, kalinlik: FontWeight.w700);
    });
  }

  void _rota(Canvas c, Offset a, double kalkis, double bas, double sure) {
    final p = _seg(t, bas, sure);
    if (p <= 0) return;
    final ilerleme = _io(p);
    final k = _k(a, kalkis);
    final kalem = Paint()
      ..color = _a(_lacivert, .55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final akis = t > bas + sure ? (t - bas - sure) * 14 : 0.0;
    const n = 80;
    var uzunluk = 0.0;
    var onceki = a;
    for (var i = 1; i <= n; i++) {
      final nokta = _qpt(a, k, ist, i / n * ilerleme);
      final d = (nokta - onceki).distance;
      if ((uzunluk - akis) % 9 < 3) c.drawLine(onceki, nokta, kalem);
      uzunluk += d;
      onceki = nokta;
    }
  }

  void _pin(Canvas c) {
    final d = _seg(t, .3, .55);
    if (d <= 0) return;
    final y = -60 * (1 - _yumusak.transform(d));
    var ez = 0.0;
    for (final v in const [.62, 3.8, 5.25, 5.4]) {
      final x = _seg(t, v, .3);
      if (x > 0 && x < 1) ez += math.sin(math.pi * x) * .16;
    }
    c.drawOval(
      Rect.fromCenter(center: ist + const Offset(0, 1), width: 16 * (.5 + .5 * d), height: 5),
      Paint()..color = _a(_murekkep, .15 * d),
    );
    c.save();
    c.translate(ist.dx, ist.dy + y);
    c.scale(1 + ez, 1 - ez);
    c.drawPath(_pinYolu(Offset.zero, 11), Paint()..color = _kirmizi);
    c.drawCircle(const Offset(0, -18.7), 4.2, Paint()..color = Colors.white);
    c.restore();
    _opak(c, _seg(t, .7, .3), () {
      _yazi(c, 'İstanbul', ist + const Offset(0, 12),
          boyut: 9, renk: _kirmiziKoyu, kalinlik: FontWeight.w800);
    });
  }

  void _ucak(Canvas c, Offset a, double kalkis, double bas, double sure) {
    final p = _seg(t, bas, sure);
    if (p <= 0 || p >= 1) return;
    final q = _io(p);
    final k = _k(a, kalkis);
    final konum = _qpt(a, k, ist, q);
    final teget = (k - a) * (2 * (1 - q)) + (ist - k) * (2 * q);
    final aci = math.atan2(teget.dy, teget.dx);
    final olcek = 1 + .3 * math.sin(math.pi * q);
    final op = _seg(p, 0, .08) * (1 - _seg(p, .9, .1));
    _opak(c, op, () {
      c.save();
      c.translate(konum.dx + 4, konum.dy + 10 * olcek);
      c.rotate(aci);
      c.scale(8 * olcek, 8 * olcek * .6);
      c.drawPath(_ucakSekli, Paint()..color = _a(_murekkep, .12));
      c.restore();
      c.save();
      c.translate(konum.dx, konum.dy);
      c.rotate(aci);
      c.scale(9 * olcek);
      c.drawPath(_ucakSekli, Paint()..color = _lacivert);
      c.restore();
    });
  }

  void _teslim(Canvas c, String tur, double dx, double bas) {
    final o = _pop(t, bas);
    if (o <= 0) return;
    final m = ist + Offset(dx, -52);
    _golge(c, m, 15 * o);
    c.drawCircle(m, 15 * o, Paint()..color = Colors.white);
    _esya(c, tur, m, 10.5 * o);
  }

  void _yolcu(Canvas c) {
    final o = _pop(t, 1.5);
    if (o <= 0) return;
    final m = lon + const Offset(0, -30);
    c.save();
    c.translate(m.dx, m.dy);
    c.scale(o);
    _golge(c, Offset.zero, 14);
    c.drawCircle(Offset.zero, 15, Paint()..color = Colors.white);
    c.drawCircle(Offset.zero, 13, Paint()..color = _lacivert);
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 13)));
    final beyaz = Paint()..color = Colors.white;
    c.drawCircle(const Offset(0, -3.5), 4.6, beyaz);
    c.drawOval(Rect.fromCenter(center: const Offset(0, 10), width: 18, height: 13), beyaz);
    c.restore();
    c.restore();
  }

  @override
  bool shouldRepaint(_RotaPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────
// Sahne 2 — Bavul (282 x 340)
// ─────────────────────────────────────────────────────────────
class _BavulPainter extends CustomPainter {
  _BavulPainter(this.t);
  final double t;

  static const cx = 141.0;
  static const _esyalar = ['kulaklik', 'parfum', 'ayakkabi', 'telefon'];
  static const _bayraklar = ['uk', 'fr', 'de', 'ae'];
  static const _etiketler = ['LONDON', 'PARIS', 'DUBAI'];
  static const _etiketRenk = [_lacivert, _mor, _yesil];
  static const _etiketYer = [Offset(100, 222), Offset(168, 252), Offset(178, 204)];
  static const _etiketAci = [-8.0, 7.0, -5.0];

  @override
  void paint(Canvas c, Size size) {
    final giris = _yumusak.transform(_seg(t, 0, .5));
    final kapali = t >= 2.67;

    // Zıplama / sallanma
    final h = _seg(t, 4.1, .8);
    var dy = 0.0;
    var don = 0.0;
    if (h > 0 && h < 1) {
      dy = -math.sin(2 * math.pi * h).abs() * 10 * (1 - h * .4);
      don = .045 * math.sin(4 * math.pi * h);
    }

    c.drawOval(
      Rect.fromCenter(center: const Offset(cx, 292), width: 170 - dy.abs() * 3, height: 12),
      Paint()
        ..color = _a(_murekkep, .1 * giris)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    _opak(c, giris, () {
      c.save();
      c.translate(cx, 282 + (1 - giris) * 20);
      c.rotate(don);
      c.translate(-cx, -282 + dy);

      if (!kapali) {
        // Açık kapak (iç astar görünür), kapanırken boyu kısalır
        final k = _kapanis.transform(_seg(t, 2.35, .34));
        final kapakH = 62 * (1 - k);
        if (kapakH > .5) {
          final kapak = RRect.fromLTRBR(66, 158 - kapakH, 216, 160, const Radius.circular(14));
          c.drawRRect(kapak, Paint()..color = _kirmiziKoyu);
          c.drawRRect(kapak.deflate(6), Paint()..color = _a(_kirmiziAcik, .55));
          final cep = RRect.fromLTRBR(84, 158 - kapakH + 12, 198, 158 - kapakH * .45, const Radius.circular(6));
          if (kapakH > 30) {
            c.drawRRect(
              cep,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = _a(_kirmiziKoyu, .5),
            );
          }
        }
        // Bavulun içi
        c.drawRRect(
          RRect.fromLTRBR(70, 152, 212, 180, const Radius.circular(10)),
          Paint()..color = const Color(0xFF7E1A18),
        );
      }

      // Uçan eşyalar (gövdenin arkasında kalır → içine düşüyor gibi)
      for (var i = 0; i < 4; i++) {
        final p = _seg(t, .5 + i * .34, .78);
        if (p <= 0 || p >= 1) continue;
        final bas = i.isEven ? Offset(-30, 60.0 + i * 18) : Offset(312, 50.0 + i * 18);
        final hedef = Offset(cx - 48 + i * 32, 170);
        final k = Offset((bas.dx + hedef.dx) / 2, (bas.dy + hedef.dy) / 2 - 60);
        final q = _io(p);
        final m = _qpt(bas, k, hedef, q);
        final aci = (1 - q) * (i.isEven ? -1 : 1) * math.pi * 1.1;
        final olcek = p > .75 ? _lerp(1, .5, (p - .75) / .25) : 1.0;
        _opak(c, 1 - _seg(p, .85, .15), () {
          c.save();
          c.translate(m.dx, m.dy);
          c.rotate(aci);
          c.scale(olcek);
          _golge(c, Offset.zero, 17);
          c.drawCircle(Offset.zero, 17, Paint()..color = Colors.white);
          _esya(c, _esyalar[i], Offset.zero, 11);
          _bayrak(c, _bayraklar[i], const Rect.fromLTWH(5, -20, 14, 9));
          c.restore();
        });
      }

      // Sap (kapanınca)
      if (kapali) {
        _opak(c, _seg(t, 2.67, .2), () {
          c.drawRRect(
            RRect.fromLTRBR(116, 138, 166, 168, const Radius.circular(9)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = _sap,
          );
        });
      }

      // Gövde
      final govde = RRect.fromLTRBR(66, kapali ? 156.0 : 170.0, 216, 282, const Radius.circular(16));
      c.drawRRect(govde, Paint()..color = _kirmizi);
      c.drawRRect(
        RRect.fromLTRBR(66, kapali ? 156.0 : 170.0, 216, kapali ? 166.0 : 178.0, const Radius.circular(16)),
        Paint()..color = _a(Colors.white, .12),
      );
      final kaburga = Paint()
        ..color = _a(_kirmiziAcik, .35)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (final x in const [96.0, 141.0, 186.0]) {
        c.drawLine(Offset(x, kapali ? 184.0 : 186.0), Offset(x, 272), kaburga);
      }
      final teker = Paint()..color = _murekkep;
      c.drawCircle(const Offset(86, 286), 6, teker);
      c.drawCircle(const Offset(196, 286), 6, teker);

      if (kapali) {
        // Dikiş + fermuar
        c.drawLine(
          const Offset(72, 176),
          const Offset(210, 176),
          Paint()
            ..color = _kirmiziKoyu
            ..strokeWidth = 2,
        );
        final z = _io(_seg(t, 2.75, .42));
        if (z > 0) {
          final x = 72 + 138 * z;
          c.drawLine(
            const Offset(72, 176),
            Offset(x, 176),
            Paint()
              ..color = _fermuar
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round,
          );
          final cekec = RRect.fromLTRBR(x - 3, 174, x + 3, 186, const Radius.circular(2));
          c.drawRRect(cekec, Paint()..color = _fermuar);
          c.drawRRect(
            cekec,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .8
              ..color = _sap,
          );
        }

        // Şehir etiketleri
        for (var i = 0; i < 3; i++) {
          final d = _damga(t, 3.2 + i * .26, _etiketAci[i]);
          if (d.opak <= 0) continue;
          _opak(c, d.opak, () {
            c.save();
            final m = _etiketYer[i];
            c.translate(m.dx, m.dy);
            c.rotate(d.aci);
            c.scale(d.olcek);
            final r = RRect.fromLTRBR(-29, -11, 29, 11, const Radius.circular(6));
            c.drawRRect(r.shift(const Offset(0, 1.5)), Paint()..color = _a(_murekkep, .15));
            c.drawRRect(r, Paint()..color = _etiketRenk[i]);
            c.drawRRect(
              r.deflate(2.5),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = .8
                ..color = _a(Colors.white, .8),
            );
            _yazi(c, _etiketler[i], Offset.zero,
                boyut: 9, renk: Colors.white, kalinlik: FontWeight.w900, aralik: 1);
            c.restore();
          });
        }
      }
      c.restore();
    });

    _balon(
      c,
      Offset(cx, 132 + dy),
      'Dönüşte getiriyorum ✓',
      _pop(t, 4.9),
      _seg(t, 4.9, .2),
      zemin: _lacivert,
      yazi: Colors.white,
    );
  }

  @override
  bool shouldRepaint(_BavulPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────
// Sahne 3 — Pasaport (282 x 340)
// ─────────────────────────────────────────────────────────────
class _PasaportPainter extends CustomPainter {
  _PasaportPainter(this.t);
  final double t;

  static const px = 56.0;
  static const py = 58.0;
  static const pw = 170.0;
  static const ph = 210.0;

  static const _sehirler = ['LONDRA', 'DUBAI', 'BERLİN'];
  static const _renkler = [_lacivert, _yesil, _mor];
  static const _yerler = [Offset(px + 52, py + 62), Offset(px + 120, py + 108), Offset(px + 60, py + 160)];
  static const _acilar = [-10.0, 8.0, -5.0];
  static const _urunler = ['sneaker', 'parfüm', 'kahve'];

  @override
  void paint(Canvas c, Size size) {
    final giris = _yumusak.transform(_seg(t, 0, .6));
    final j = _seg(t, 3.85 + .32, .4);
    final sarsinti = (j > 0 && j < 1) ? math.sin(j * math.pi * 3) * (1 - j) * 4 : 0.0;

    _opak(c, giris, () {
      c.save();
      c.translate(0, (1 - giris) * 24 + sarsinti);

      final dis = RRect.fromLTRBR(px - 6, py - 4, px + pw + 6, py + ph + 4, const Radius.circular(12));
      c.drawRRect(
        dis.shift(const Offset(0, 6)),
        Paint()
          ..color = _a(_murekkep, .18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      c.drawRRect(dis, Paint()..color = _kapak);

      final sayfa = RRect.fromLTRBR(px, py, px + pw, py + ph, const Radius.circular(8));
      _bosSayfa(c, sayfa);

      // Sayfa 1: damgalar
      _opak(c, 1 - _seg(t, 3.2, .2), () {
        _yazi(c, 'VİZELER · VISAS', const Offset(px + pw / 2, py + 16),
            boyut: 7, renk: _a(_kapak, .5), kalinlik: FontWeight.w800, aralik: 1.5);
        for (var i = 0; i < 3; i++) {
          final bas = 1.3 + i * .56;
          final d = _damga(t, bas, _acilar[i]);
          if (d.opak <= 0) continue;
          _opak(c, d.opak * .92, () {
            c.save();
            c.translate(_yerler[i].dx, _yerler[i].dy);
            c.rotate(d.aci);
            c.scale(d.olcek);
            _muhur(c, i);
            c.restore();
          });
          _opak(c, _seg(t, bas + .46, .3), () {
            _yazi(c, _urunler[i], _yerler[i] + const Offset(0, 33),
                boyut: 10, renk: _murekkep, kalinlik: FontWeight.w600, italik: true);
          });
        }
      });

      // Sayfa 2: soldan çevrilerek gelir
      final p2 = _cevir.transform(_seg(t, 3.38, .45));
      if (p2 > 0) {
        c.save();
        c.translate(px, 0);
        c.scale(p2, 1);
        c.translate(-px, 0);
        _bosSayfa(c, sayfa);
        c.drawRRect(sayfa, Paint()..color = _a(_murekkep, .08 * (1 - p2)));
        c.restore();
      }

      // Büyük ÜCRETSİZ mührü
      final d = _damga(t, 3.85, -8);
      if (d.opak > 0) {
        _opak(c, d.opak * .93, () {
          c.save();
          c.translate(px + pw / 2, py + ph / 2);
          c.rotate(d.aci);
          c.scale(d.olcek);
          final r = RRect.fromLTRBR(-62, -30, 62, 30, const Radius.circular(8));
          c.drawRRect(
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = _kirmiziKoyu,
          );
          c.drawRRect(
            r.deflate(4.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _kirmiziKoyu,
          );
          _yazi(c, 'ÜCRETSİZ', const Offset(0, -5),
              boyut: 21, renk: _kirmiziKoyu, kalinlik: FontWeight.w900, aralik: 1);
          _yazi(c, 'TÜM İSTEKLER', const Offset(0, 15),
              boyut: 8.5, renk: _kirmiziKoyu, kalinlik: FontWeight.w800, aralik: 1.5);
          c.restore();
        });
      }

      // Ön kapak: soldaki sırttan açılır
      final ac = _cevir.transform(_seg(t, .65, .52));
      final sx = 1 - ac;
      if (sx > 0) {
        c.save();
        c.translate(px - 6, 0);
        c.scale(sx, 1);
        c.translate(-(px - 6), 0);
        c.drawRRect(dis, Paint()..color = _kapak);
        final orta = const Offset(px + pw / 2, py + ph / 2 - 18);
        final altinKalem = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _altin;
        c.drawCircle(orta, 24, altinKalem);
        c.drawCircle(orta, 15, altinKalem..strokeWidth = 1.2);
        c.drawCircle(orta, 4, Paint()..color = _altin);
        _yazi(c, 'PASAPORT', orta + const Offset(0, 46),
            boyut: 12, renk: _altin, kalinlik: FontWeight.w800, aralik: 2.5);
        _yazi(c, 'İSTE', orta + const Offset(0, 64),
            boyut: 8, renk: _a(_altin, .8), kalinlik: FontWeight.w700, aralik: 2);
        c.drawRRect(dis, Paint()..color = _a(Colors.black, ac * .35));
        c.restore();
      }

      c.restore();
    });
  }

  void _bosSayfa(Canvas c, RRect sayfa) {
    c.drawRRect(sayfa, Paint()..color = _sayfaZemin);
    c.save();
    c.clipRRect(sayfa);
    final dalga = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = _a(_kapak, .06);
    for (var i = 0; i < 12; i++) {
      final y = py + 14 + i * 17.0;
      final yol = Path()..moveTo(px, y);
      for (var x = 0.0; x <= pw; x += 8) {
        yol.lineTo(px + x, y + math.sin(x / 14 + i) * 2.2);
      }
      c.drawPath(yol, dalga);
    }
    c.restore();
  }

  void _muhur(Canvas c, int i) {
    final renk = _renkler[i];
    final kalin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = renk;
    final ince = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = renk;
    if (i == 0) {
      c.drawCircle(Offset.zero, 26, kalin);
      c.drawCircle(Offset.zero, 21, ince);
    } else if (i == 1) {
      final r = RRect.fromLTRBR(-34, -18, 34, 18, const Radius.circular(4));
      c.drawRRect(r, kalin);
      c.drawRRect(r.deflate(3), ince);
    } else {
      final r = Rect.fromCenter(center: Offset.zero, width: 68, height: 40);
      c.drawOval(r, kalin);
      c.drawOval(r.deflate(3.5), ince);
    }
    _yazi(c, _sehirler[i], const Offset(0, -3),
        boyut: 9.5, renk: renk, kalinlik: FontWeight.w900, aralik: .8);
    _yazi(c, 'GİRİŞ · 2026', const Offset(0, 8),
        boyut: 5.5, renk: renk, kalinlik: FontWeight.w700, aralik: .8);
  }

  @override
  bool shouldRepaint(_PasaportPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────
// Ekran
// ─────────────────────────────────────────────────────────────
class IsteTanitimEkrani extends StatefulWidget {
  const IsteTanitimEkrani({super.key, required this.onTamamlandi});

  /// true → "Hemen ilan ver", false → son sayfada "Geç".
  final void Function(bool hemenIlanVer) onTamamlandi;

  @override
  State<IsteTanitimEkrani> createState() => _IsteTanitimEkraniState();
}

class _IsteTanitimEkraniState extends State<IsteTanitimEkrani>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _simdi = Duration.zero;
  Duration _baslangic = Duration.zero;
  double _t = 0;
  int _sayfa = 0;
  int _yon = 1;
  bool _azHareket = false;
  bool _bitti = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tik)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _azHareket = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tik(Duration e) {
    _simdi = e;
    if (_azHareket) return;
    final t = (e - _baslangic).inMicroseconds / 1e6;
    setState(() => _t = t);
    if (_sayfa < 2 && t > _sahneBitis[_sayfa] + _bekleme) {
      _git(_sayfa + 1, 1);
    }
  }

  void _git(int i, int yon) {
    if (i == _sayfa || i < 0 || i > 2) return;
    setState(() {
      _sayfa = i;
      _yon = yon;
      _baslangic = _simdi;
      _t = 0;
    });
  }

  void _bitir(bool hemenIlanVer) {
    if (_bitti) return;
    _bitti = true;
    widget.onTamamlandi(hemenIlanVer);
  }

  double get _sahneT => _azHareket ? 99.0 : _t;

  @override
  Widget build(BuildContext context) {
    final t = _sahneT;
    final ilerleme = _sayfa < 2
        ? (t / (_sahneBitis[_sayfa] + _bekleme)).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: _krem,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 10, 0),
              child: Row(
                children: [
                  const Text(
                    'İSTE',
                    style: TextStyle(
                      color: _kirmiziBtn,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _sayfa < 2 ? _git(2, 1) : _bitir(false),
                    style: TextButton.styleFrom(foregroundColor: _soluk),
                    child: const Text(
                      'Geç',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v < -200) _git(_sayfa + 1, 1);
                  if (v > 200) _git(_sayfa - 1, -1);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (gelen, gidenler) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...gidenler, if (gelen != null) gelen],
                  ),
                  transitionBuilder: (child, anim) {
                    final gelenMi = child.key == ValueKey(_sayfa);
                    return FadeTransition(
                      opacity: anim,
                      child: AnimatedBuilder(
                        animation: anim,
                        builder: (context, ch) => Transform.translate(
                          offset: Offset((1 - anim.value) * (gelenMi ? _yon : -_yon) * 40, 0),
                          child: ch,
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_sayfa),
                    child: _sayfaIcerik(t),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
              child: _sayfa < 2
                  ? Row(
                      children: [
                        _noktalar(ilerleme),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _git(_sayfa + 1, 1),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _murekkep,
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                            shape: const StadiumBorder(),
                            side: const BorderSide(color: Color(0xFFEDE3DA)),
                          ),
                          child: const Text(
                            'İleri',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _noktalar(ilerleme),
                        const SizedBox(height: 8),
                        Transform.scale(
                          scale: t > _sahneBitis[2]
                              ? 1 + .03 * (.5 - .5 * math.cos((t - _sahneBitis[2]) * 2 * math.pi / 1.6))
                              : 1.0,
                          child: ElevatedButton.icon(
                            onPressed: () => _bitir(true),
                            icon: const Icon(Icons.add, size: 22),
                            label: const Text('Hemen ilan ver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kirmiziBtn,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
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

  Widget _sahne(CustomPainter painter) => ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 282,
            height: 340,
            child: CustomPaint(painter: painter),
          ),
        ),
      );

  Widget _belir(double t, double bas, Widget child) {
    final x = _yumusak.transform(_seg(t, bas, .5));
    return Opacity(
      opacity: x,
      child: Transform.translate(offset: Offset(0, (1 - x) * 10), child: child),
    );
  }

  static const _baslikStil = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    color: _murekkep,
    height: 1.22,
  );
  static const _altStil = TextStyle(fontSize: 14.5, color: _soluk, height: 1.4);

  Widget _sayfaIcerik(double t) {
    final CustomPainter painter;
    final List<Widget> yazilar;
    if (_sayfa == 0) {
      painter = _RotaPainter(t);
      yazilar = [
        _belir(t, .2, const Text('İstediğini yaz,\nyurt dışından gelen getirsin',
            textAlign: TextAlign.center, style: _baslikStil)),
        const SizedBox(height: 10),
        _belir(t, .45, const Text(
            "Londra'dan sneaker mı, Dubai'den parfüm mü?\nOradan gelen biri mutlaka vardır.",
            textAlign: TextAlign.center, style: _altStil)),
      ];
    } else if (_sayfa == 1) {
      painter = _BavulPainter(t);
      yazilar = [
        _belir(t, .2, const Text('Yolculuk mu var?\nBavulundaki boş yer birisinin isteği olabilir',
            textAlign: TextAlign.center, style: _baslikStil)),
        const SizedBox(height: 10),
        _belir(t, .45, const Text('Gittiğin şehirden istenenleri gör,\ndönüşte getir.',
            textAlign: TextAlign.center, style: _altStil)),
      ];
    } else {
      painter = _PasaportPainter(t);
      final isaret = _io(_seg(t, 1.0, .6));
      yazilar = [
        _belir(t, .2, Column(
          children: [
            const Text('Sen iste,',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _murekkep, height: 1.15)),
            Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 4,
                  height: 13,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: isaret,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _a(_kirmiziAcik, .55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const Text('gelen getirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _kirmiziBtn, height: 1.15)),
              ],
            ),
          ],
        )),
      ];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          Expanded(child: _sahne(painter)),
          const SizedBox(height: 6),
          ...yazilar,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _noktalar(double ilerleme) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _git(i, i > _sayfa ? 1 : -1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: i == _sayfa ? 28 : 8,
                  height: 8,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: i == _sayfa
                        ? const Color(0xFFF6D3CF)
                        : i < _sayfa
                            ? _kirmiziBtn
                            : const Color(0xFFE6DCD3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: i == _sayfa
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: ilerleme,
                            heightFactor: 1,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_kirmizi, _kirmiziBtn]),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
        ],
      );
}
