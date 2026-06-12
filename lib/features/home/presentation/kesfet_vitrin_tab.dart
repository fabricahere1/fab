// lib/features/home/presentation/kesfet_vitrin_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/home/providers/kesfet_vitrin_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'kesfet_bolum_detay_screen.dart';

enum _RozetTipi { goruntulenme, favori, yeni, eta, dutyFree }

class KesfetVitrinTab extends ConsumerWidget {
  const KesfetVitrinTab({super.key});

  Future<void> _yenile(WidgetRef ref) async {
    await Future.wait([
      ref.read(istekIlanlarProvider.notifier).yenile(),
      ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goruntulenen = ref.watch(kesfetEnCokGoruntulenenProvider);
    final favorilenen  = ref.watch(kesfetEnCokFavorilenenProvider);
    final bugunEklenen = ref.watch(kesfetBugunEklenenProvider);
    final yakinGelecek = ref.watch(kesfetYakinGeleceklerProvider);
    final dutyFree     = ref.watch(kesfetDutyFreeProvider);
    final yukleniyor   = ref.watch(istekIlanlarProvider).yukleniyor || ref.watch(tasiyiciIlanlarProvider).yukleniyor;

    final bolumler = <_BolumData>[
      _BolumData('Haftanın en çok görüntülenen ilanları', Icons.visibility_outlined, goruntulenen, _RozetTipi.goruntulenme, CicekTipi.papatya),
      _BolumData('Haftanın en çok favorilenen ilanları', Icons.favorite_outline_rounded, favorilenen, _RozetTipi.favori, CicekTipi.gul),
      _BolumData('Bugün eklenen ilanlar', Icons.fiber_new_outlined, bugunEklenen, _RozetTipi.yeni, CicekTipi.lavanta),
      _BolumData('Yakın zamanda Türkiye\'ye gelecekler', Icons.flight_land_outlined, yakinGelecek, _RozetTipi.eta, CicekTipi.aycicegi),
      _BolumData('Bugün yola çıkacaklar · Duty Free fırsatları', Icons.local_mall_outlined, dutyFree, _RozetTipi.dutyFree, CicekTipi.papatya),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    if (bolumler.isEmpty) {
      return yukleniyor
          ? const Center(child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2))
          : const _BosEkran();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _HeroBanner(),
        ...bolumler.map((b) => _Bolum(data: b)),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Kalp deseni painter ───────────────────────────────────────────────────────

class KalpZeminPainter extends CustomPainter {
  const KalpZeminPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFFFF0F5));

    const alpha = 0.50;
    final boya = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha)..style = PaintingStyle.fill;
    const s = 10.0, aralikX = 58.0, aralikY = 32.0;

    final tp = TextPainter(
      text: TextSpan(text: 'İste', style: TextStyle(color: const Color(0xFFFFFFFF).withValues(alpha: alpha), fontSize: 10, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();

    for (double y = 0; y < size.height + aralikY; y += aralikY) {
      final xOffset = ((y / aralikY).round() % 2 == 0) ? 0.0 : aralikX / 2;
      for (double x = xOffset; x < size.width + aralikX; x += aralikX) {
        canvas.drawPath(Path()
          ..moveTo(x, y + s * 0.3)..cubicTo(x, y, x - s, y, x - s, y + s * 0.6)
          ..cubicTo(x - s, y + s * 1.2, x, y + s * 1.6, x, y + s * 1.6)
          ..cubicTo(x, y + s * 1.6, x + s, y + s * 1.2, x + s, y + s * 0.6)
          ..cubicTo(x + s, y, x, y, x, y + s * 0.3)..close(), boya);
        tp.paint(canvas, Offset(x + s + 4, y + (s * 1.6 - tp.height) / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bölüm ────────────────────────────────────────────────────────────────────

enum CicekTipi { papatya, gul, lavanta, aycicegi }

class _BolumData {
  final String baslik;
  final IconData ikon;
  final List<IlanModel> ilanlar;
  final _RozetTipi rozetTipi;
  final CicekTipi cicekTipi;
  const _BolumData(this.baslik, this.ikon, this.ilanlar, this.rozetTipi, this.cicekTipi);
}

class _Bolum extends StatelessWidget {
  final _BolumData data;
  const _Bolum({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KesfetBolumDetayScreen(
                      baslik: data.baslik,
                      ilanlar: data.ilanlar,
                      ikon: data.ikon,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Text('Tümünü Gör', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Icon(data.ikon, size: 16, color: AppColors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(data.baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ),
            ]),
          ],
        ),
      ),
      SizedBox(
        height: 270,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: KartZeminPainter(data.cicekTipi))),
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: data.ilanlar.length,
            itemBuilder: (_, i) => _KesfetKart(ilan: data.ilanlar[i], rozetTipi: data.rozetTipi, cicekTipi: data.cicekTipi),
          ),
        ]),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

class CicekBaslikPainter extends CustomPainter {
  final CicekTipi tip;
  const CicekBaslikPainter(this.tip);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final Color zemin;
    switch (tip) {
      case CicekTipi.papatya:  zemin = const Color(0xFFFFF3E0); break;
      case CicekTipi.gul:      zemin = const Color(0xFFFCE4EC); break;
      case CicekTipi.lavanta:  zemin = const Color(0xFFEDE7F6); break;
      case CicekTipi.aycicegi: zemin = const Color(0xFFFFFDE7); break;
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = zemin);
  }

  @override
  bool shouldRepaint(covariant CicekBaslikPainter old) => old.tip != tip;
}

class _KesfetKart extends ConsumerWidget {
  final IlanModel ilan;
  final _RozetTipi rozetTipi;
  final CicekTipi cicekTipi;
  const _KesfetKart({required this.ilan, required this.rozetTipi, required this.cicekTipi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resim  = ilan.gridResim;
    final katAdi = kategoriAdi(ilan.kategori);
    return GestureDetector(
      onTap: () { ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan); context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan); },
      child: Container(
        width: 155, margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF888888), width: 0.3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Container(height: 150, width: double.infinity, color: const Color(0xFFF2F2F2),
              child: Stack(fit: StackFit.expand, children: [
                resim.isNotEmpty ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: resim, fit: BoxFit.cover, fadeInDuration: Duration.zero, errorWidget: (_, _, _) => _RenkliArkaplan(cicekTipi: cicekTipi)) : _RenkliArkaplan(cicekTipi: cicekTipi),
                Positioned(top: 6, left: 6, child: _Rozet(ilan: ilan, tipi: rozetTipi)),
              ]))),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (ilan.urun.isNotEmpty) Text(ilan.urun, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty)
                Row(children: [const Icon(Icons.flight_takeoff_rounded, size: 10, color: AppColors.textSecondary), const SizedBox(width: 3),
                  Expanded(child: Text('${ilan.nereden} → ${ilan.nereye}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis))]),
              if (katAdi.isNotEmpty) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                  child: Text(katAdi, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.red))),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.visibility_outlined, size: 10, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text('${ilan.goruntulenmeSayisi}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
                const SizedBox(width: 6),
                const Icon(Icons.favorite_border, size: 10, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text('${ilan.favoriSayisi}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
              ]),
            ]))),
        ]),
      ),
    );
  }
}

class _Rozet extends StatelessWidget {
  final IlanModel ilan; final _RozetTipi tipi;
  const _Rozet({required this.ilan, required this.tipi});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    switch (tipi) {
      case _RozetTipi.goruntulenme: return _pill(ikon: Icons.visibility_rounded, metin: _sayiFormat(ilan.goruntulenmeSayisi), renk: const Color(0xCC1A1A1A));
      case _RozetTipi.favori:       return _pill(ikon: Icons.favorite_rounded, metin: _sayiFormat(ilan.favoriSayisi), renk: AppColors.red.withValues(alpha: 0.92));
      case _RozetTipi.yeni:         return _pill(metin: 'YENİ', renk: AppColors.red.withValues(alpha: 0.92));
      case _RozetTipi.eta:          return _pill(ikon: Icons.schedule_rounded, metin: _etaMetin(ilan.tarih, now), renk: _etaRenk(ilan.tarih, now));
      case _RozetTipi.dutyFree:     return _pill(ikon: Icons.local_mall_rounded, metin: 'DUTY FREE', renk: const Color(0xE6B8860B));
    }
  }

  Widget _pill({IconData? ikon, required String metin, required Color renk}) {
    if (metin.isEmpty) return const SizedBox.shrink();
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (ikon != null) ...[Icon(ikon, size: 10, color: Colors.white), const SizedBox(width: 3)],
        Text(metin, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
      ]));
  }
}

class _RenkliArkaplan extends StatelessWidget {
  final CicekTipi cicekTipi;
  const _RenkliArkaplan({required this.cicekTipi});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: KartZeminPainter(cicekTipi),
      child: Center(child: Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.textHint.withValues(alpha: 0.4))),
    );
  }
}

class KartZeminPainter extends CustomPainter {
  final CicekTipi tip;
  const KartZeminPainter(this.tip);

  static final _p = Paint()
    ..color = Colors.white.withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final List<Color> renkler;
    switch (tip) {
      case CicekTipi.papatya:  renkler = [const Color(0xFF87CEEB), const Color(0xFFE0F4FF)]; break;
      case CicekTipi.gul:      renkler = [const Color(0xFFFFB6C1), const Color(0xFFFFF0E0)]; break;
      case CicekTipi.lavanta:  renkler = [const Color(0xFFFFF176), const Color(0xFFFFFDE7)]; break;
      case CicekTipi.aycicegi: renkler = [const Color(0xFFB2DFDB), const Color(0xFFE8F5E9)]; break;
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: renkler)
          .createShader(Rect.fromLTWH(0, 0, w, h)));

    switch (tip) {
      case CicekTipi.papatya:
        _ucak(canvas, w * 0.12, h * 0.18, 1.0, 0.0);
        _demetCicek(canvas, w * 0.78, h * 0.12, 1.0);
        _bavul(canvas, w * 0.08, h * 0.60, 0.75);
        _sepet(canvas, w * 0.72, h * 0.55, 0.85);
        _ucak(canvas, w * 0.45, h * 0.82, 0.65, -0.3);
        _tekCicek(canvas, w * 0.88, h * 0.78, 0.7);
        break;
      case CicekTipi.gul:
        _demetCicek(canvas, w * 0.15, h * 0.14, 1.0);
        _bavul(canvas, w * 0.78, h * 0.12, 0.9);
        _ucak(canvas, w * 0.48, h * 0.45, 0.85, 0.15);
        _sepet(canvas, w * 0.10, h * 0.68, 0.8);
        _tekCicek(canvas, w * 0.82, h * 0.65, 0.75);
        _bavul(canvas, w * 0.50, h * 0.82, 0.6);
        break;
      case CicekTipi.lavanta:
        _sepet(canvas, w * 0.08, h * 0.12, 0.9);
        _ucak(canvas, w * 0.70, h * 0.10, 0.95, -0.2);
        _demetCicek(canvas, w * 0.18, h * 0.52, 0.85);
        _bavul(canvas, w * 0.78, h * 0.48, 0.8);
        _tekCicek(canvas, w * 0.50, h * 0.78, 0.7);
        _ucak(canvas, w * 0.82, h * 0.82, 0.6, 0.25);
        break;
      case CicekTipi.aycicegi:
        _bavul(canvas, w * 0.10, h * 0.12, 1.0);
        _ucak(canvas, w * 0.68, h * 0.08, 1.0, 0.1);
        _demetCicek(canvas, w * 0.45, h * 0.40, 0.9);
        _tekCicek(canvas, w * 0.12, h * 0.70, 0.75);
        _sepet(canvas, w * 0.75, h * 0.65, 0.85);
        _ucak(canvas, w * 0.88, h * 0.88, 0.55, -0.15);
        break;
    }
  }

  void _ucak(Canvas canvas, double cx, double cy, double scale, double angle) {
    canvas.save(); canvas.translate(cx, cy); canvas.rotate(angle);
    final s = scale * 22.0; final p = _p;
    canvas.drawPath(Path()..moveTo(-s, 0)..lineTo(s * 0.6, -s * 0.18)..lineTo(s, 0)..lineTo(s * 0.6, s * 0.18)..close(), p);
    canvas.drawPath(Path()..moveTo(-s * 0.1, 0)..lineTo(-s * 0.5, -s * 0.7)..lineTo(s * 0.25, -s * 0.22)..close(), p);
    canvas.drawPath(Path()..moveTo(-s * 0.1, 0)..lineTo(-s * 0.5, s * 0.7)..lineTo(s * 0.25, s * 0.22)..close(), p);
    canvas.drawPath(Path()..moveTo(-s * 0.75, 0)..lineTo(-s, -s * 0.38)..lineTo(-s * 0.55, -s * 0.12)..close(), p);
    canvas.restore();
  }

  void _bavul(Canvas canvas, double cx, double cy, double scale) {
    canvas.save(); canvas.translate(cx, cy);
    final s = scale * 16.0; final p = _p;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 1.7), const Radius.circular(4)), p);
    canvas.drawPath(Path()..moveTo(-s * 0.4, -s * 0.85)..lineTo(-s * 0.4, -s * 1.25)..quadraticBezierTo(0, -s * 1.55, s * 0.4, -s * 1.25)..lineTo(s * 0.4, -s * 0.85), p);
    canvas.drawLine(Offset(0, -s * 0.85), Offset(0, s * 0.85), p);
    canvas.drawLine(Offset(-s, 0), Offset(s, 0), p);
    canvas.drawCircle(Offset(-s * 0.55, s * 0.85), s * 0.18, p);
    canvas.drawCircle(Offset(s * 0.55, s * 0.85), s * 0.18, p);
    canvas.restore();
  }

  void _sepet(Canvas canvas, double cx, double cy, double scale) {
    canvas.save(); canvas.translate(cx, cy);
    final s = scale * 18.0; final p = _p;
    canvas.drawPath(Path()..moveTo(-s, -s * 0.2)..lineTo(-s * 0.75, s * 0.9)..lineTo(s * 0.75, s * 0.9)..lineTo(s, -s * 0.2)..close(), p);
    canvas.drawPath(Path()..moveTo(-s * 0.55, -s * 0.2)..quadraticBezierTo(0, -s * 1.2, s * 0.55, -s * 0.2), p);
    canvas.drawLine(Offset(-s * 0.9, s * 0.28), Offset(s * 0.9, s * 0.28), p);
    canvas.drawLine(Offset(-s * 0.84, s * 0.6), Offset(s * 0.84, s * 0.6), p);
    canvas.drawLine(Offset(-s * 0.3, -s * 0.2), Offset(-s * 0.35, s * 0.9), p);
    canvas.drawLine(Offset(s * 0.3, -s * 0.2), Offset(s * 0.35, s * 0.9), p);
    canvas.restore();
  }

  void _demetCicek(Canvas canvas, double cx, double cy, double scale) {
    canvas.save(); canvas.translate(cx, cy);
    final s = scale * 14.0; final p = _p;
    final saplar = [[0.0, s*3.5, 0.0, -s*0.5],[-s*0.7,s*3.5,-s*0.9,-s*0.3],[s*0.7,s*3.5,s*0.9,-s*0.3],[-s*1.4,s*3.5,-s*1.6,s*0.2],[s*1.4,s*3.5,s*1.6,s*0.2]];
    for (final sap in saplar) { canvas.drawLine(Offset(sap[0], sap[1]), Offset(sap[2], sap[3]), p); }
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -s*0.5-s*0.7), width: s, height: s*1.4), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s*0.9, -s*0.3-s*0.6), width: s*0.85, height: s*1.2), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(s*0.9, -s*0.3-s*0.6), width: s*0.85, height: s*1.2), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s*1.6, s*0.2-s*0.5), width: s*0.7, height: s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(s*1.6, s*0.2-s*0.5), width: s*0.7, height: s), p);
    canvas.drawPath(Path()..moveTo(-s*0.5, s*3.2)..quadraticBezierTo(0, s*2.6, s*0.5, s*3.2), p);
    canvas.restore();
  }

  void _tekCicek(Canvas canvas, double cx, double cy, double scale) {
    canvas.save(); canvas.translate(cx, cy);
    final s = scale * 12.0; final p = _p;
    canvas.drawLine(Offset(0, s*0.5), Offset(0, s*2.5), p);
    canvas.drawPath(Path()..moveTo(0, s*1.5)..quadraticBezierTo(s*0.8, s*1.0, s*0.6, s*0.5)..quadraticBezierTo(s*0.2, s*1.2, 0, s*1.5), p);
    for (int i = 0; i < 5; i++) {
      canvas.save(); canvas.rotate(i * 3.14159 * 2 / 5);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -s*0.85), width: s*0.55, height: s*1.1), p);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, s*0.28, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KartZeminPainter old) => old.tip != tip;
}

// ── Hero Banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends ConsumerWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroIlanlar = ref.watch(kesfetHeroBannerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/hero_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.60),
                      Colors.black.withValues(alpha: 0.20),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text('Bu hafta öne çıkanlar',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KesfetBolumDetayScreen(
                                baslik: 'Bu hafta öne çıkanlar',
                                ilanlar: heroIlanlar,
                                ikon: Icons.local_fire_department_outlined,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                            ),
                            child: Text('Tümünü Gör',
                                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: heroIlanlar.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                            itemCount: heroIlanlar.length,
                            itemBuilder: (_, index) {
                              final ilan  = heroIlanlar[index];
                              final resim = ilan.gridResim;
                              return GestureDetector(
                                onTap: () {
                                  ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
                                  context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
                                },
                                child: Container(
                                  width: 88,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: resim.isNotEmpty
                                        ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: resim, fit: BoxFit.cover, fadeInDuration: Duration.zero)
                                        : Container(color: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 26)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Boş ekran ─────────────────────────────────────────────────────────────────

class _BosEkran extends StatelessWidget {
  const _BosEkran();
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.explore_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
      const SizedBox(height: 16),
      Text('Keşfedilecek içerik birazdan burada.\nİlanlar yüklendikçe en popüler ve en yeni\nilanlar bu sekmede listelenecek.',
          textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
    ])));
}

String _sayiFormat(int n) { if (n >= 1000000) return '${(n/1000000).toStringAsFixed(1)}M'; if (n >= 1000) return '${(n/1000).toStringAsFixed(1)}K'; return '$n'; }
String _etaMetin(DateTime? t, DateTime now) { if (t == null) return ''; final f = DateTime(t.year, t.month, t.day).difference(DateTime(now.year, now.month, now.day)).inDays; if (f <= 0) return 'BUGÜN'; if (f == 1) return 'YARIN'; return '$f GÜN'; }
Color _etaRenk(DateTime? t, DateTime now) { if (t == null) return const Color(0xCC1A1A1A); final f = DateTime(t.year, t.month, t.day).difference(DateTime(now.year, now.month, now.day)).inDays; if (f <= 0) return AppColors.red.withValues(alpha: 0.92); if (f <= 2) return const Color(0xE6E65100); return const Color(0xCC1565C0); }