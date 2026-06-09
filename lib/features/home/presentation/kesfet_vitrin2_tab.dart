// lib/features/home/presentation/kesfet_vitrin2_tab.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/home/providers/kesfet_vitrin2_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/features/home/presentation/kesfet_bolum_detay_screen.dart';
import 'package:iste_v3/router/app_router.dart';

// ── Zemin painter ─────────────────────────────────────────────────────────────

enum _ZeminTipi { mavi, yesil }

class _SiluetZeminPainter extends CustomPainter {
  final _ZeminTipi tip;
  const _SiluetZeminPainter(this.tip);

  static final _p = Paint()
    ..color = Colors.white.withValues(alpha: 0.38)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final List<Color> renkler = tip == _ZeminTipi.mavi
        ? [const Color(0xFF87CEEB), const Color(0xFFE0F4FF)]
        : [const Color(0xFFB2DFDB), const Color(0xFFE8F5E9)];

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: renkler,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    if (tip == _ZeminTipi.mavi) {
      _ucak(canvas, w * 0.12, h * 0.22, 0.9, -0.15);
      _bavul(canvas, w * 0.80, h * 0.18, 0.8);
      _ucak(canvas, w * 0.55, h * 0.75, 0.6, 0.2);
      _bavul(canvas, w * 0.10, h * 0.72, 0.6);
    } else {
      _bavul(canvas, w * 0.10, h * 0.20, 0.85);
      _ucak(canvas, w * 0.75, h * 0.18, 0.9, 0.1);
      _bavul(canvas, w * 0.80, h * 0.72, 0.6);
      _ucak(canvas, w * 0.18, h * 0.75, 0.6, -0.2);
    }
  }

  void _ucak(Canvas canvas, double cx, double cy, double scale, double angle) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    final s = scale * 18.0;
    canvas.drawPath(Path()
      ..moveTo(-s, 0)..lineTo(s * 0.6, -s * 0.18)..lineTo(s, 0)..lineTo(s * 0.6, s * 0.18)..close(), _p);
    canvas.drawPath(Path()
      ..moveTo(-s * 0.1, 0)..lineTo(-s * 0.5, -s * 0.65)..lineTo(s * 0.25, -s * 0.20)..close(), _p);
    canvas.drawPath(Path()
      ..moveTo(-s * 0.1, 0)..lineTo(-s * 0.5, s * 0.65)..lineTo(s * 0.25, s * 0.20)..close(), _p);
    canvas.drawPath(Path()
      ..moveTo(-s * 0.75, 0)..lineTo(-s, -s * 0.36)..lineTo(-s * 0.55, -s * 0.12)..close(), _p);
    canvas.restore();
  }

  void _bavul(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    final s = scale * 13.0;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 1.7),
      const Radius.circular(3),
    ), _p);
    canvas.drawPath(Path()
      ..moveTo(-s * 0.4, -s * 0.85)..lineTo(-s * 0.4, -s * 1.2)
      ..quadraticBezierTo(0, -s * 1.45, s * 0.4, -s * 1.2)..lineTo(s * 0.4, -s * 0.85), _p);
    canvas.drawLine(Offset(0, -s * 0.85), Offset(0, s * 0.85), _p);
    canvas.drawLine(Offset(-s, 0), Offset(s, 0), _p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SiluetZeminPainter old) => old.tip != tip;
}

// ── Ana widget ────────────────────────────────────────────────────────────────

class KesfetVitrin2Tab extends ConsumerWidget {
  const KesfetVitrin2Tab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendUrunler = ref.watch(kesfetTrendUrunlerProvider);
    final guzergahlar  = ref.watch(kesfetPopulerGuzergahlarProvider);
    final sehirler     = ref.watch(kesfetBuHaftaSehirlerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trendUrunler.isNotEmpty) _TrendUrunlerBolum(trendler: trendUrunler),
        if (guzergahlar.isNotEmpty)  _GuzergahlarBolum(guzergahlar: guzergahlar),
        if (sehirler.isNotEmpty)     _SehirlerBolum(sehirler: sehirler),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Bölüm başlığı helper ──────────────────────────────────────────────────────

Widget _bolumBaslik({
  required String baslik,
  required IconData ikon,
  VoidCallback? tumunuGor,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 12, 10),
    child: Row(
      children: [
        Icon(ikon, size: 16, color: AppColors.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
        if (tumunuGor != null)
          GestureDetector(
            onTap: tumunuGor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text('Tümünü Gör',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
            ),
          ),
      ],
    ),
  );
}

// ── 1) Trend Ürünler — liste görünümü + tümünü gör ───────────────────────────

class _TrendUrunlerBolum extends StatelessWidget {
  final List<TrendUrun> trendler;
  const _TrendUrunlerBolum({required this.trendler});

  // İlk 5'i göster, tümünü gör ile hepsi
  static const _onizleme = 5;

  @override
  Widget build(BuildContext context) {
    final liste = trendler.take(_onizleme).toList();
    // Tüm ilanlar (tümünü gör sayfası için)
    final tumIlanlar = trendler.expand((t) => t.ilanlar).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bolumBaslik(
          baslik: 'Trend ürünler',
          ikon: Icons.trending_up_rounded,
          tumunuGor: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => KesfetBolumDetayScreen(
              baslik: 'Trend ürünler',
              ilanlar: tumIlanlar,
              ikon: Icons.trending_up_rounded,
            ),
          )),
        ),

        // Zemin + liste
        Stack(
          children: [
            // Zemin
            Positioned.fill(
              child: CustomPaint(painter: _SiluetZeminPainter(_ZeminTipi.mavi)),
            ),
            // Liste
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: List.generate(liste.length, (i) {
                  final trend = liste[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => KesfetBolumDetayScreen(
                        baslik: trend.ad,
                        ilanlar: trend.ilanlar,
                        ikon: Icons.trending_up_rounded,
                      ),
                    )),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: Row(
                        children: [
                          // Sıra
                          SizedBox(
                            width: 24,
                            child: Text('${i + 1}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: i < 3 ? AppColors.red : AppColors.textHint,
                                )),
                          ),
                          // İkon
                          if (i < 3) ...[
                            Text(['🔥', '⚡', '✨'][i], style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                          ] else ...[
                            const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                          ],
                          // Ürün adı
                          Expanded(
                            child: Text(trend.ad,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          // İlan sayısı
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${trend.ilanlar.length} ilan',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.red)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── 2) Popüler Güzergahlar — D stili (bayrak + avatarlar) ────────────────────

class _GuzergahlarBolum extends StatelessWidget {
  final List<Guzergah> guzergahlar;
  const _GuzergahlarBolum({required this.guzergahlar});

  static const _bayraklar = <String, String>{
    'new york': '🇺🇸', 'los angeles': '🇺🇸', 'chicago': '🇺🇸',
    'miami': '🇺🇸', 'houston': '🇺🇸', 'boston': '🇺🇸',
    'san francisco': '🇺🇸', 'washington': '🇺🇸', 'usa': '🇺🇸',
    'abd': '🇺🇸', 'new jersey': '🇺🇸', 'seattle': '🇺🇸',
    'londra': '🇬🇧', 'london': '🇬🇧', 'manchester': '🇬🇧',
    'uk': '🇬🇧', 'ingiltere': '🇬🇧',
    'paris': '🇫🇷', 'lyon': '🇫🇷', 'fransa': '🇫🇷',
    'berlin': '🇩🇪', 'münih': '🇩🇪', 'frankfurt': '🇩🇪', 'almanya': '🇩🇪',
    'amsterdam': '🇳🇱', 'hollanda': '🇳🇱',
    'dubai': '🇦🇪', 'abu dhabi': '🇦🇪', 'bae': '🇦🇪',
    'tokyo': '🇯🇵', 'osaka': '🇯🇵', 'japonya': '🇯🇵',
    'milano': '🇮🇹', 'roma': '🇮🇹', 'italya': '🇮🇹',
    'madrid': '🇪🇸', 'barcelona': '🇪🇸', 'ispanya': '🇪🇸',
    'stockholm': '🇸🇪', 'isveç': '🇸🇪',
    'zürih': '🇨🇭', 'cenevre': '🇨🇭', 'isviçre': '🇨🇭',
    'toronto': '🇨🇦', 'vancouver': '🇨🇦', 'kanada': '🇨🇦',
    'sidney': '🇦🇺', 'melbourne': '🇦🇺', 'avustralya': '🇦🇺',
    'seul': '🇰🇷', 'güney kore': '🇰🇷',
    'şangay': '🇨🇳', 'pekin': '🇨🇳', 'çin': '🇨🇳',
  };

  String _bayrak(String sehir) {
    final k = sehir.toLowerCase().trim();
    for (final e in _bayraklar.entries) {
      if (k.contains(e.key)) return e.value;
    }
    return '✈️';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bolumBaslik(baslik: 'Popüler güzergahlar', ikon: Icons.route_outlined),
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _SiluetZeminPainter(_ZeminTipi.yesil)),
              ),
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: guzergahlar.length,
                itemBuilder: (_, i) {
                  final g = guzergahlar[i];
                  final bayrakNereden = _bayrak(g.nereden);
                  final bayrakNereye  = _bayrak(g.nereye);
                  // Avatar fotoğrafları — ilk 3 taşıyıcı
                  final avatarlar = g.ilanlar.take(3).toList();

                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => KesfetBolumDetayScreen(
                        baslik: '${g.nereden} → ${g.nereye}',
                        ilanlar: g.ilanlar,
                        ikon: Icons.route_outlined,
                      ),
                    )),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Üst: bayraklar + şehirler ──────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nereden
                                Row(children: [
                                  Text(bayrakNereden, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(g.nereden,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                                // Ok
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    const SizedBox(width: 2),
                                    Container(width: 1, height: 10, color: AppColors.divider),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.arrow_downward_rounded,
                                        size: 11, color: AppColors.textHint),
                                  ]),
                                ),
                                // Nereye
                                Row(children: [
                                  Text(bayrakNereye, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(g.nereye,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // ── Alt: avatar + ilan sayısı ──────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              children: [
                                // Avatarlar üst üste
                                SizedBox(
                                  width: avatarlar.length * 18.0 + 4,
                                  height: 24,
                                  child: Stack(
                                    children: List.generate(avatarlar.length, (ai) {
                                      final fotoUrl = avatarlar[ai].resimUrl;
                                      return Positioned(
                                        left: ai * 18.0,
                                        child: Container(
                                          width: 24, height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                            color: AppColors.surface,
                                          ),
                                          child: ClipOval(
                                            child: fotoUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    cacheManager: AppCacheManager.instance,
                                                    imageUrl: fotoUrl,
                                                    fit: BoxFit.cover,
                                                    fadeInDuration: Duration.zero,
                                                    errorWidget: (_, _, _) => _avatarYok(),
                                                  )
                                                : _avatarYok(),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${g.ilanSayisi} taşıyıcı',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 16, color: AppColors.textHint),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _avatarYok() => Container(
        color: AppColors.surface,
        child: const Icon(Icons.person_outline, size: 12, color: AppColors.textHint),
      );
}

// ── Mini ilan kartı ───────────────────────────────────────────────────────────

class _MiniIlanKarti extends ConsumerWidget {
  final IlanModel ilan;
  const _MiniIlanKarti({required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resim = ilan.gridResim;
    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
      },
      child: Container(
        width: 80,
        height: 136,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          SizedBox(
            height: 104,
            width: double.infinity,
            child: resim.isNotEmpty
                ? CachedNetworkImage(
                    cacheManager: AppCacheManager.instance,
                    imageUrl: resim,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    errorWidget: (_, _, _) => _resimYok(),
                  )
                : _resimYok(),
          ),
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
              child: Text(
                ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _resimYok() => Container(
        color: const Color(0xFFF2F2F2),
        child: const Center(child: Icon(Icons.inventory_2_outlined, size: 22, color: AppColors.textHint)),
      );
}

// ── 3) Bu Hafta Hangi Şehirlerden Geliyor ────────────────────────────────────

class _SehirlerBolum extends StatelessWidget {
  final List<SehirSatiri> sehirler;
  const _SehirlerBolum({required this.sehirler});

  static const _bayraklar = <String, String>{
    'new york': '🇺🇸', 'los angeles': '🇺🇸', 'chicago': '🇺🇸',
    'miami': '🇺🇸', 'houston': '🇺🇸', 'boston': '🇺🇸',
    'san francisco': '🇺🇸', 'washington': '🇺🇸', 'usa': '🇺🇸',
    'abd': '🇺🇸', 'new jersey': '🇺🇸', 'seattle': '🇺🇸',
    'londra': '🇬🇧', 'london': '🇬🇧', 'manchester': '🇬🇧',
    'uk': '🇬🇧', 'ingiltere': '🇬🇧',
    'paris': '🇫🇷', 'lyon': '🇫🇷', 'fransa': '🇫🇷',
    'berlin': '🇩🇪', 'münih': '🇩🇪', 'frankfurt': '🇩🇪', 'almanya': '🇩🇪',
    'amsterdam': '🇳🇱', 'hollanda': '🇳🇱',
    'dubai': '🇦🇪', 'abu dhabi': '🇦🇪', 'bae': '🇦🇪',
    'tokyo': '🇯🇵', 'osaka': '🇯🇵', 'japonya': '🇯🇵',
    'milano': '🇮🇹', 'roma': '🇮🇹', 'italya': '🇮🇹',
    'madrid': '🇪🇸', 'barcelona': '🇪🇸', 'ispanya': '🇪🇸',
    'stockholm': '🇸🇪', 'isveç': '🇸🇪',
    'zürih': '🇨🇭', 'cenevre': '🇨🇭', 'isviçre': '🇨🇭',
    'toronto': '🇨🇦', 'vancouver': '🇨🇦', 'kanada': '🇨🇦',
    'sidney': '🇦🇺', 'melbourne': '🇦🇺', 'avustralya': '🇦🇺',
    'seul': '🇰🇷', 'güney kore': '🇰🇷',
    'şangay': '🇨🇳', 'pekin': '🇨🇳', 'çin': '🇨🇳',
  };

  String _bayrak(String sehir) {
    final k = sehir.toLowerCase().trim();
    for (final e in _bayraklar.entries) {
      if (k.contains(e.key)) return e.value;
    }
    return '✈️';
  }

  @override
  Widget build(BuildContext context) {
    final maxIlan = sehirler.first.ilanSayisi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bolumBaslik(
          baslik: 'Bu hafta hangi şehirlerden geliyor',
          ikon: Icons.location_on_outlined,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(sehirler.length, (i) {
              final s    = sehirler[i];
              final oran = maxIlan > 0 ? s.ilanSayisi / maxIlan : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 22,
                    child: Text('${i + 1}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: i < 3 ? AppColors.red : AppColors.textHint)),
                  ),
                  Text(_bayrak(s.sehir), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.sehir,
                            style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: oran,
                            backgroundColor: AppColors.divider.withValues(alpha: 0.4),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.red.withValues(alpha: 0.4 + oran * 0.6)),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: Text('${s.ilanSayisi} ilan',
                        style: GoogleFonts.dmSans(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                ]),
              );
            }),
          ),
        ),
      ],
    );
  }
}