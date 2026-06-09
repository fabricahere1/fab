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
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.red, strokeWidth: 2))
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
      // Başlık + Tümünü Göster butonu
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tümünü Gör butonu — sağ üstte
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'Tümünü Gör',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // İkon + Başlık — tek satır
            Row(
              children: [
                Icon(data.ikon, size: 16, color: AppColors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Kartların scroll alanı — çiçekli zemin
      SizedBox(
        height: 270,
        child: Stack(children: [
          // Çiçekli zemin
          Positioned.fill(
            child: CustomPaint(painter: KartZeminPainter(data.cicekTipi)),
          ),
          // Kartlar
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

    // Zemin rengi
    final Color zemin;
    switch (tip) {
      case CicekTipi.papatya:  zemin = const Color(0xFFFFF3E0); break;
      case CicekTipi.gul:      zemin = const Color(0xFFFCE4EC); break;
      case CicekTipi.lavanta:  zemin = const Color(0xFFEDE7F6); break;
      case CicekTipi.aycicegi: zemin = const Color(0xFFFFFDE7); break;
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = zemin);

    switch (tip) {
      case CicekTipi.papatya:  _papatyaCiz(canvas, w, h); break;
      case CicekTipi.gul:      _gulCiz(canvas, w, h); break;
      case CicekTipi.lavanta:  _lavantaCiz(canvas, w, h); break;
      case CicekTipi.aycicegi: _aycicegiCiz(canvas, w, h); break;
    }
  }

  void _tacYaprak(Canvas canvas, Paint p, Offset merkez, double uzunluk, double genislik, int adet) {
    for (int i = 0; i < adet; i++) {
      canvas.save();
      canvas.translate(merkez.dx, merkez.dy);
      canvas.rotate(i * 2 * 3.14159 / adet);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -uzunluk), width: genislik * 2, height: uzunluk * 2), p);
      canvas.restore();
    }
  }

  void _papatyaCiz(Canvas canvas, double w, double h) {
    final yaprak = Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.75)..style = PaintingStyle.fill;
    final merkez = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.9)..style = PaintingStyle.fill;
    final yaprakRenk = Paint()..color = const Color(0xFFC8E6C9).withValues(alpha: 0.55)..style = PaintingStyle.fill;
    // büyük papatya sağ
    _tacYaprak(canvas, yaprak, Offset(w - 38, h * 0.45), 18, 7, 8);
    canvas.drawCircle(Offset(w - 38, h * 0.45), 9, merkez);
    // küçük papatya sol
    _tacYaprak(canvas, yaprak, Offset(40, h * 0.4), 11, 4, 8);
    canvas.drawCircle(Offset(40, h * 0.4), 6, merkez);
    // yapraklar
    canvas.save(); canvas.translate(w - 18, h - 8); canvas.rotate(-0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 28, height: 10), yaprakRenk); canvas.restore();
  }

  void _gulCiz(Canvas canvas, double w, double h) {
    final dis = Paint()..color = const Color(0xFFF48FB1).withValues(alpha: 0.7)..style = PaintingStyle.fill;
    final ic  = Paint()..color = const Color(0xFFF06292).withValues(alpha: 0.65)..style = PaintingStyle.fill;
    final ort = Paint()..color = const Color(0xFFE91E63).withValues(alpha: 0.75)..style = PaintingStyle.fill;
    final yp  = Paint()..color = const Color(0xFFA5D6A7).withValues(alpha: 0.5)..style = PaintingStyle.fill;
    // büyük gül sağ
    _tacYaprak(canvas, dis, Offset(w - 36, h * 0.42), 16, 9, 5);
    _tacYaprak(canvas, ic,  Offset(w - 36, h * 0.42), 11, 6, 5);
    canvas.drawCircle(Offset(w - 36, h * 0.42), 7, ort);
    // küçük gül sol
    _tacYaprak(canvas, dis, Offset(36, h * 0.38), 10, 6, 5);
    canvas.drawCircle(Offset(36, h * 0.38), 5, ort);
    // yaprak
    canvas.save(); canvas.translate(w - 14, h - 5); canvas.rotate(-0.4);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 24, height: 8), yp); canvas.restore();
  }

  void _lavantaCiz(Canvas canvas, double w, double h) {
    final renkler = [
      const Color(0xFFCE93D8),
      const Color(0xFFBA68C8),
      const Color(0xFFAB47BC),
      const Color(0xFF9C27B0),
    ];
    final sap = Paint()..color = const Color(0xFFCE93D8).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final yp  = Paint()..color = const Color(0xFFC8E6C9).withValues(alpha: 0.5)..style = PaintingStyle.fill;

    void dal(double x, double yBaslangic, double yBitis, double scale) {
      canvas.drawLine(Offset(x, yBaslangic), Offset(x, yBitis), sap);
      final adimlar = [0.0, 0.3, 0.55, 0.75, 0.9];
      for (int i = 0; i < adimlar.length; i++) {
        final y = yBitis + (yBaslangic - yBitis) * adimlar[i];
        final renk = Paint()..color = renkler[i < renkler.length ? i : renkler.length - 1].withValues(alpha: 0.55)..style = PaintingStyle.fill;
        if (i == 0) {
          canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 6 * scale), width: 7 * scale, height: 12 * scale), renk);
        } else {
          canvas.drawOval(Rect.fromCenter(center: Offset(x - 5 * scale, y), width: 7 * scale, height: 11 * scale), renk);
          canvas.drawOval(Rect.fromCenter(center: Offset(x + 5 * scale, y), width: 7 * scale, height: 11 * scale), renk);
        }
      }
    }
    dal(w - 40, h, 10, 1.0);
    dal(w - 20, h, 20, 0.8);
    dal(30, h, 15, 0.85);
    // yaprak
    canvas.save(); canvas.translate(w - 55, h - 5); canvas.rotate(-0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 22, height: 8), yp); canvas.restore();
    canvas.save(); canvas.translate(w - 30, h - 8); canvas.rotate(0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 7), yp); canvas.restore();
  }

  void _aycicegiCiz(Canvas canvas, double w, double h) {
    final tac  = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.75)..style = PaintingStyle.fill;
    final dis  = Paint()..color = const Color(0xFF795548).withValues(alpha: 0.82)..style = PaintingStyle.fill;
    final ic   = Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.7)..style = PaintingStyle.fill;
    final sap  = Paint()..color = const Color(0xFF66BB6A).withValues(alpha: 0.45)..style = PaintingStyle.stroke..strokeWidth = 2;
    final yp   = Paint()..color = const Color(0xFFA5D6A7).withValues(alpha: 0.5)..style = PaintingStyle.fill;
    // büyük
    _tacYaprak(canvas, tac, Offset(w - 36, h * 0.4), 20, 7, 12);
    canvas.drawCircle(Offset(w - 36, h * 0.4), 12, dis);
    canvas.drawCircle(Offset(w - 36, h * 0.4), 8, ic);
    canvas.drawLine(Offset(w - 36, h * 0.4 + 12), Offset(w - 36, h + 4), sap);
    // küçük
    _tacYaprak(canvas, tac, Offset(34, h * 0.35), 13, 5, 12);
    canvas.drawCircle(Offset(34, h * 0.35), 7, dis);
    canvas.drawCircle(Offset(34, h * 0.35), 5, ic);
    canvas.drawLine(Offset(34, h * 0.35 + 7), Offset(34, h + 4), sap);
    // yaprak büyük
    canvas.save(); canvas.translate(w - 52, h * 0.7); canvas.rotate(-0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 26, height: 9), yp); canvas.restore();
    canvas.save(); canvas.translate(w - 20, h * 0.75); canvas.rotate(0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 22, height: 8), yp); canvas.restore();
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
      child: Center(
        child: Icon(Icons.inventory_2_outlined, size: 32,
            color: AppColors.textHint.withValues(alpha: 0.4)),
      ),
    );
  }
}

class KartZeminPainter extends CustomPainter {
  final CicekTipi tip;
  const KartZeminPainter(this.tip);

  // ── Beyaz stroke boya — tüm siluetler bu boya ile çizilir ──────────────────
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

    // ── Zemin rengi (gradient) ───────────────────────────────────────────────
    final List<Color> renkler;
    switch (tip) {
      case CicekTipi.papatya:  renkler = [const Color(0xFF87CEEB), const Color(0xFFE0F4FF)]; break;
      case CicekTipi.gul:      renkler = [const Color(0xFFFFB6C1), const Color(0xFFFFF0E0)]; break;
      case CicekTipi.lavanta:  renkler = [const Color(0xFFFFF176), const Color(0xFFFFFDE7)]; break;
      case CicekTipi.aycicegi: renkler = [const Color(0xFFB2DFDB), const Color(0xFFE8F5E9)]; break;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: renkler,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ── Siluet dizilimi — her tip için farklı yerleşim ───────────────────────
    switch (tip) {
      case CicekTipi.papatya:
        // sol üst: uçak büyük
        _ucak(canvas, w * 0.12, h * 0.18, 1.0, 0.0);
        // sağ üst: çiçek demeti
        _demetCicek(canvas, w * 0.78, h * 0.12, 1.0);
        // orta sol: bavul küçük
        _bavul(canvas, w * 0.08, h * 0.60, 0.75);
        // orta sağ: sepet
        _sepet(canvas, w * 0.72, h * 0.55, 0.85);
        // alt orta: uçak küçük eğik
        _ucak(canvas, w * 0.45, h * 0.82, 0.65, -0.3);
        // sağ alt: tek çiçek
        _tekCicek(canvas, w * 0.88, h * 0.78, 0.7);
        break;

      case CicekTipi.gul:
        // sol üst: çiçek demeti büyük
        _demetCicek(canvas, w * 0.15, h * 0.14, 1.0);
        // sağ üst: bavul
        _bavul(canvas, w * 0.78, h * 0.12, 0.9);
        // orta: uçak
        _ucak(canvas, w * 0.48, h * 0.45, 0.85, 0.15);
        // sol alt: sepet
        _sepet(canvas, w * 0.10, h * 0.68, 0.8);
        // sağ alt: tek çiçek
        _tekCicek(canvas, w * 0.82, h * 0.65, 0.75);
        // alt orta: bavul mini
        _bavul(canvas, w * 0.50, h * 0.82, 0.6);
        break;

      case CicekTipi.lavanta:
        // sol üst: sepet
        _sepet(canvas, w * 0.08, h * 0.12, 0.9);
        // sağ üst: uçak
        _ucak(canvas, w * 0.70, h * 0.10, 0.95, -0.2);
        // orta sol: çiçek demeti
        _demetCicek(canvas, w * 0.18, h * 0.52, 0.85);
        // orta sağ: bavul
        _bavul(canvas, w * 0.78, h * 0.48, 0.8);
        // alt: tek çiçek + uçak mini
        _tekCicek(canvas, w * 0.50, h * 0.78, 0.7);
        _ucak(canvas, w * 0.82, h * 0.82, 0.6, 0.25);
        break;

      case CicekTipi.aycicegi:
        // sol üst: bavul büyük
        _bavul(canvas, w * 0.10, h * 0.12, 1.0);
        // sağ üst: uçak
        _ucak(canvas, w * 0.68, h * 0.08, 1.0, 0.1);
        // orta: demet çiçek
        _demetCicek(canvas, w * 0.45, h * 0.40, 0.9);
        // sol alt: tek çiçek
        _tekCicek(canvas, w * 0.12, h * 0.70, 0.75);
        // sağ alt: sepet
        _sepet(canvas, w * 0.75, h * 0.65, 0.85);
        // alt sağ: uçak mini
        _ucak(canvas, w * 0.88, h * 0.88, 0.55, -0.15);
        break;
    }
  }

  // ── Uçak silueti ────────────────────────────────────────────────────────────
  // cx,cy: merkez, scale: boyut çarpanı, angle: radyan cinsinden dönüş
  void _ucak(Canvas canvas, double cx, double cy, double scale, double angle) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    final s = scale * 22.0;
    final p = _p;
    // gövde
    final govde = Path()
      ..moveTo(-s, 0)
      ..lineTo(s * 0.6, -s * 0.18)
      ..lineTo(s, 0)
      ..lineTo(s * 0.6, s * 0.18)
      ..close();
    canvas.drawPath(govde, p);
    // sol kanat
    final kanat = Path()
      ..moveTo(-s * 0.1, 0)
      ..lineTo(-s * 0.5, -s * 0.7)
      ..lineTo(s * 0.25, -s * 0.22)
      ..close();
    canvas.drawPath(kanat, p);
    // sağ kanat
    final kanat2 = Path()
      ..moveTo(-s * 0.1, 0)
      ..lineTo(-s * 0.5, s * 0.7)
      ..lineTo(s * 0.25, s * 0.22)
      ..close();
    canvas.drawPath(kanat2, p);
    // kuyruk
    final kuyruk = Path()
      ..moveTo(-s * 0.75, 0)
      ..lineTo(-s, -s * 0.38)
      ..lineTo(-s * 0.55, -s * 0.12)
      ..close();
    canvas.drawPath(kuyruk, p);
    canvas.restore();
  }

  // ── Bavul silueti ────────────────────────────────────────────────────────────
  void _bavul(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    final s = scale * 16.0;
    final p = _p;
    // gövde
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 1.7),
        const Radius.circular(4),
      ),
      p,
    );
    // sap
    final sap = Path()
      ..moveTo(-s * 0.4, -s * 0.85)
      ..lineTo(-s * 0.4, -s * 1.25)
      ..quadraticBezierTo(0, -s * 1.55, s * 0.4, -s * 1.25)
      ..lineTo(s * 0.4, -s * 0.85);
    canvas.drawPath(sap, p);
    // orta çizgi (dikey)
    canvas.drawLine(Offset(0, -s * 0.85), Offset(0, s * 0.85), p);
    // orta çizgi (yatay)
    canvas.drawLine(Offset(-s, 0), Offset(s, 0), p);
    // tekerlekler
    canvas.drawCircle(Offset(-s * 0.55, s * 0.85), s * 0.18, p);
    canvas.drawCircle(Offset( s * 0.55, s * 0.85), s * 0.18, p);
    canvas.restore();
  }

  // ── Alışveriş sepeti silueti ─────────────────────────────────────────────────
  void _sepet(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    final s = scale * 18.0;
    final p = _p;
    // sepet gövdesi (yamuk)
    final govde = Path()
      ..moveTo(-s, -s * 0.2)
      ..lineTo(-s * 0.75, s * 0.9)
      ..lineTo( s * 0.75, s * 0.9)
      ..lineTo( s, -s * 0.2)
      ..close();
    canvas.drawPath(govde, p);
    // sap (yay)
    final sapPath = Path()
      ..moveTo(-s * 0.55, -s * 0.2)
      ..quadraticBezierTo(0, -s * 1.2, s * 0.55, -s * 0.2);
    canvas.drawPath(sapPath, p);
    // yatay çizgiler
    canvas.drawLine(Offset(-s * 0.9, s * 0.28), Offset( s * 0.9, s * 0.28), p);
    canvas.drawLine(Offset(-s * 0.84, s * 0.6), Offset( s * 0.84, s * 0.6), p);
    // dikey çizgiler
    canvas.drawLine(Offset(-s * 0.3, -s * 0.2), Offset(-s * 0.35, s * 0.9), p);
    canvas.drawLine(Offset( s * 0.3, -s * 0.2), Offset( s * 0.35, s * 0.9), p);
    canvas.restore();
  }

  // ── Çiçek demeti silueti ─────────────────────────────────────────────────────
  void _demetCicek(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    final s = scale * 14.0;
    final p = _p;
    // saplar
    final saplar = [
      [0.0, s * 3.5, 0.0, -s * 0.5],
      [-s * 0.7, s * 3.5, -s * 0.9, -s * 0.3],
      [ s * 0.7, s * 3.5,  s * 0.9, -s * 0.3],
      [-s * 1.4, s * 3.5, -s * 1.6,  s * 0.2],
      [ s * 1.4, s * 3.5,  s * 1.6,  s * 0.2],
    ];
    for (final sap in saplar) {
      canvas.drawLine(Offset(sap[0], sap[1]), Offset(sap[2], sap[3]), p);
    }
    // çiçek başları — oval
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.5 - s * 0.7), width: s, height: s * 1.4), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.9, -s * 0.3 - s * 0.6), width: s * 0.85, height: s * 1.2), p);
    canvas.drawOval(Rect.fromCenter(center: Offset( s * 0.9, -s * 0.3 - s * 0.6), width: s * 0.85, height: s * 1.2), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 1.6, s * 0.2 - s * 0.5), width: s * 0.7, height: s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset( s * 1.6, s * 0.2 - s * 0.5), width: s * 0.7, height: s), p);
    // bağ (kurdelesi)
    final kurde = Path()
      ..moveTo(-s * 0.5, s * 3.2)
      ..quadraticBezierTo(0, s * 2.6, s * 0.5, s * 3.2);
    canvas.drawPath(kurde, p);
    canvas.restore();
  }

  // ── Tek çiçek silueti ────────────────────────────────────────────────────────
  void _tekCicek(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    final s = scale * 12.0;
    final p = _p;
    // sap
    canvas.drawLine(Offset(0, s * 0.5), Offset(0, s * 2.5), p);
    // yaprak
    final yaprak = Path()
      ..moveTo(0, s * 1.5)
      ..quadraticBezierTo(s * 0.8, s * 1.0, s * 0.6, s * 0.5)
      ..quadraticBezierTo(s * 0.2, s * 1.2, 0, s * 1.5);
    canvas.drawPath(yaprak, p);
    // taç yapraklar (4 yön)
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(0, 0);
      canvas.rotate(i * 3.14159 * 2 / 5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, -s * 0.85), width: s * 0.55, height: s * 1.1),
        p,
      );
      canvas.restore();
    }
    // merkez
    canvas.drawCircle(Offset.zero, s * 0.28, p);
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
    final goruntulenen = ref.watch(kesfetEnCokGoruntulenenProvider);
    final favorilenen  = ref.watch(kesfetEnCokFavorilenenProvider);

    // En çok görüntülenen + en çok favorilenen, tekrarları kaldır
    final seen = <String>{};
    final heroIlanlar = [
      ...goruntulenen,
      ...favorilenen,
    ].where((i) => seen.add(i.id)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka plan resmi
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
              // Koyu overlay — yazı okunsun
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
              // İçerik
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Üst: başlık + tümünü gör ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bu hafta öne çıkanlar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.urbanist(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                'En çok görüntülenen & favorilenen ilanlar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tümünü Gör butonu
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
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Tümünü Gör',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Alt: kaydırılabilir ilan kartları ──
                  if (heroIlanlar.isNotEmpty)
                    SizedBox(
                      height: 136,
                      child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: resim.isNotEmpty
                                        ? CachedNetworkImage(
                                            cacheManager: AppCacheManager.instance,
                                            imageUrl: resim,
                                            fit: BoxFit.cover,
                                            fadeInDuration: Duration.zero,
                                          )
                                        : Container(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            child: const Icon(
                                              Icons.inventory_2_outlined,
                                              color: Colors.white,
                                              size: 26,
                                            ),
                                          ),
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