// lib/features/home/presentation/kesfet_vitrin2_tab.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'kesfet_bolum_baslik.dart';

import 'package:iste_v3/features/home/presentation/alisveris_rehberi_bolum.dart';
import 'package:iste_v3/features/home/presentation/beden_donusturucu_bolum.dart';
import 'package:iste_v3/features/home/presentation/dunya_trendleri_bolum.dart';
import 'package:iste_v3/features/home/presentation/tasiyici_ipuclari_bolum.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/home/providers/kesfet_vitrin2_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/features/home/presentation/kesfet_bolum_detay_screen.dart';
import 'package:iste_v3/features/ilanlar/presentation/gelenler_screen.dart';
import 'package:iste_v3/router/app_router.dart';

// ── Güzergah kartı bulutlu gökyüzü painter ───────────────────────────────────

class _GuzergahKartPainter extends CustomPainter {
  final int index;
  const _GuzergahKartPainter(this.index);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFE0F4FF)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final boya = Paint()..style = PaintingStyle.fill;

    void bulut(double cx, double cy, double opacity, List<List<double>> elipsler) {
      boya.color = Colors.white.withValues(alpha: opacity);
      for (final e in elipsler) {
        canvas.drawOval(Rect.fromCenter(center: Offset(cx + e[0], cy + e[1]), width: e[2], height: e[3]), boya);
      }
    }

    switch (index % 4) {
      case 0:
        // Sağ üst büyük + sol alt küçük
        bulut(w * 0.70, h * 0.18, 0.45, [[0,0,55,22],[-28,6,36,16],[26,5,32,15],[0,-7,28,13]]);
        bulut(w * 0.20, h * 0.72, 0.30, [[0,0,36,14],[-18,4,24,10],[18,3,22,10]]);
        bulut(w * 0.50, h * 0.38, 0.20, [[0,0,28,10],[-12,3,18,8],[12,3,16,7]]);
        break;
      case 1:
        // Sol üst büyük + sağ orta
        bulut(w * 0.22, h * 0.15, 0.45, [[0,0,50,20],[-24,6,32,14],[22,5,30,13],[0,-6,24,11]]);
        bulut(w * 0.80, h * 0.50, 0.30, [[0,0,38,15],[-18,4,24,10],[18,3,22,10]]);
        bulut(w * 0.45, h * 0.80, 0.20, [[0,0,30,11],[-14,3,18,8],[14,3,16,7]]);
        break;
      case 2:
        // Orta üst büyük + köşelerde küçük
        bulut(w * 0.50, h * 0.16, 0.45, [[0,0,58,23],[-30,7,38,17],[28,6,34,15],[0,-8,30,13]]);
        bulut(w * 0.10, h * 0.55, 0.28, [[0,0,32,12],[-14,3,20,9],[14,3,18,8]]);
        bulut(w * 0.82, h * 0.75, 0.20, [[0,0,28,10],[-12,3,16,7],[12,3,14,7]]);
        break;
      case 3:
        // Sağ üst küçük + sol orta büyük + alt
        bulut(w * 0.75, h * 0.12, 0.38, [[0,0,40,16],[-20,5,26,11],[18,4,24,10]]);
        bulut(w * 0.18, h * 0.42, 0.45, [[0,0,52,20],[-26,6,34,14],[24,5,30,13],[0,-7,26,11]]);
        bulut(w * 0.60, h * 0.78, 0.22, [[0,0,34,12],[-15,3,20,8],[15,3,18,8]]);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GuzergahKartPainter old) => old.index != index;
}

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
    canvas.drawPath(Path()..moveTo(-s, 0)..lineTo(s * 0.6, -s * 0.18)..lineTo(s, 0)..lineTo(s * 0.6, s * 0.18)..close(), _p);
    canvas.drawPath(Path()..moveTo(-s * 0.1, 0)..lineTo(-s * 0.5, -s * 0.65)..lineTo(s * 0.25, -s * 0.20)..close(), _p);
    canvas.drawPath(Path()..moveTo(-s * 0.1, 0)..lineTo(-s * 0.5, s * 0.65)..lineTo(s * 0.25, s * 0.20)..close(), _p);
    canvas.drawPath(Path()..moveTo(-s * 0.75, 0)..lineTo(-s, -s * 0.36)..lineTo(-s * 0.55, -s * 0.12)..close(), _p);
    canvas.restore();
  }

  void _bavul(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    final s = scale * 13.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 1.7), const Radius.circular(3)), _p);
    canvas.drawPath(Path()..moveTo(-s * 0.4, -s * 0.85)..lineTo(-s * 0.4, -s * 1.2)..quadraticBezierTo(0, -s * 1.45, s * 0.4, -s * 1.2)..lineTo(s * 0.4, -s * 0.85), _p);
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KesfetTrendGuzergahSehirGrubu(),
        KesfetIndirimDunyaGrubu(),
        KesfetRehberBedenIpucuBannerGrubu(),
        SizedBox(height: 24),
      ],
    );
  }
}

/// Grup A: Trend ürünler → Popüler güzergahlar → Bu hafta nerelerden
/// geliyorlar.
class KesfetTrendGuzergahSehirGrubu extends ConsumerWidget {
  const KesfetTrendGuzergahSehirGrubu({super.key});

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
      ],
    );
  }
}

/// Grup B: İndirim & outlet mağazaları → Dünya trendleri.
class KesfetIndirimDunyaGrubu extends StatelessWidget {
  const KesfetIndirimDunyaGrubu({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IndirimMagazalariBolum(),
        DunyaTrendleriBolum(),
      ],
    );
  }
}

/// Grup C: Alışveriş rehberi (İstekçi Rehberi) → Beden dönüştürücü →
/// Taşıyıcı ipuçları → İlk ilanını ver banner'ı.
class KesfetRehberBedenIpucuBannerGrubu extends StatelessWidget {
  const KesfetRehberBedenIpucuBannerGrubu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlisverisRehberiBolum(),
        const BedenDonusturuculBolum(),
        const TasiyiciIpuclariBolum(),
        IlkIlanBannerPublic(),
      ],
    );
  }
}

// ── Bölüm başlığı helper ──────────────────────────────────────────────────────

Widget _bolumBaslik({required String baslik, required IconData ikon, VoidCallback? tumunuGor}) {
  return KesfetBolumBaslik(baslik: baslik, ikon: ikon, onTumunuGor: tumunuGor);
}

// ── 1) Trend Ürünler ─────────────────────────────────────────────────────────

class _TrendUrunlerBolum extends StatelessWidget {
  final List<TrendUrun> trendler;
  const _TrendUrunlerBolum({required this.trendler});

  @override
  Widget build(BuildContext context) {
    final tumIlanlar = trendler.expand((t) => t.ilanlar).toList();
    return Consumer(
      builder: (context, ref, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bolumBaslik(
            baslik: 'Trend ürünler',
            ikon: Icons.trending_up_rounded,
            tumunuGor: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => KesfetBolumDetayScreen(baslik: 'Trend ürünler', ilanlar: tumIlanlar, ikon: Icons.trending_up_rounded),
            )),
          ),
          SizedBox(
            height: 136,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              itemCount: tumIlanlar.length,
              itemBuilder: (_, index) {
                final ilan = tumIlanlar[index];
                final resim = ilan.gridResim;
                return GestureDetector(
                  onTap: () { ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan); context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan); },
                  child: Container(
                    width: 88, height: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider, width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: resim.isNotEmpty
                          ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: resim, fit: BoxFit.cover, fadeInDuration: Duration.zero)
                          : Container(color: AppColors.surfaceAlt, child: const Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 26)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── 2) Popüler Güzergahlar ───────────────────────────────────────────────────

class _GuzergahlarBolum extends StatelessWidget {
  final List<Guzergah> guzergahlar;
  const _GuzergahlarBolum({required this.guzergahlar});

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
              Positioned.fill(child: CustomPaint(painter: _SiluetZeminPainter(_ZeminTipi.yesil))),
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: guzergahlar.length,
                itemBuilder: (_, i) {
                  final g = guzergahlar[i];
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
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Bulutlu gökyüzü arka plan
                            CustomPaint(painter: _GuzergahKartPainter(i)),
                            // İçerik
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        const _UcakIkonu(),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(g.nereden,
                                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ]),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(children: [
                                          const SizedBox(width: 2),
                                          Container(width: 1, height: 10, color: AppColors.divider),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.arrow_downward_rounded, size: 11, color: AppColors.textHint),
                                        ]),
                                      ),
                                      Row(children: [
                                        const _UcakIkonu(),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(g.nereye,
                                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: Row(
                                    children: [
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
                                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5), color: AppColors.surface),
                                                child: ClipOval(
                                                  child: fotoUrl.isNotEmpty
                                                      ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: fotoUrl, fit: BoxFit.cover, fadeInDuration: Duration.zero, errorWidget: (_, _, _) => _avatarYok())
                                                      : _avatarYok(),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text('${g.ilanSayisi} taşıyıcı',
                                          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
                                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textHint),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  static Widget _avatarYok() => Container(color: AppColors.surface, child: const Icon(Icons.person_outline, size: 12, color: AppColors.textHint));
}

// ── Beyaz SVG uçak ikonu ──────────────────────────────────────────────────────

class _UcakIkonu extends StatelessWidget {
  const _UcakIkonu();

  @override
  Widget build(BuildContext context) {
    const double size = 20;
    const Color renk = Color(0xFF5B8DB8);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _UcakPainter(renk)),
    );
  }
}

class _UcakPainter extends CustomPainter {
  final Color renk;
  const _UcakPainter(this.renk);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final boya = Paint()
      ..color = renk
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.5);

    final s = w * 0.42;
    // Gövde
    canvas.drawPath(Path()
      ..moveTo(-s, 0)
      ..lineTo(s * 0.6, -s * 0.18)
      ..lineTo(s, 0)
      ..lineTo(s * 0.6, s * 0.18)
      ..close(), boya);
    // Üst kanat
    canvas.drawPath(Path()
      ..moveTo(-s * 0.05, 0)
      ..lineTo(-s * 0.45, -s * 0.85)
      ..lineTo(s * 0.28, -s * 0.22)
      ..close(), boya);
    // Alt kanat
    canvas.drawPath(Path()
      ..moveTo(-s * 0.05, 0)
      ..lineTo(-s * 0.45, s * 0.85)
      ..lineTo(s * 0.28, s * 0.22)
      ..close(), boya);
    // Kuyruk
    canvas.drawPath(Path()
      ..moveTo(-s * 0.72, 0)
      ..lineTo(-s, -s * 0.42)
      ..lineTo(-s * 0.52, -s * 0.14)
      ..close(), boya);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UcakPainter old) => old.renk != renk;
}

// ── 3) Bu Hafta Nerelerden Geliyorlar ────────────────────────────────────────

class _SehirlerBolum extends StatefulWidget {
  final List<SehirSatiri> sehirler;
  const _SehirlerBolum({required this.sehirler});

  @override
  State<_SehirlerBolum> createState() => _SehirlerBolumState();
}

class _SehirlerBolumState extends State<_SehirlerBolum>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    // Biraz gecikmeyle başlat — ekrana gelince tetiklenmiş gibi hissettirir
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _bayraklar = <String, String>{
    'new york': '🇺🇸', 'los angeles': '🇺🇸', 'chicago': '🇺🇸', 'miami': '🇺🇸',
    'houston': '🇺🇸', 'boston': '🇺🇸', 'san francisco': '🇺🇸', 'washington': '🇺🇸',
    'usa': '🇺🇸', 'abd': '🇺🇸', 'new jersey': '🇺🇸', 'seattle': '🇺🇸', 'amerika': '🇺🇸',
    'londra': '🇬🇧', 'london': '🇬🇧', 'manchester': '🇬🇧', 'ingiltere': '🇬🇧', 'birmingham': '🇬🇧',
    'paris': '🇫🇷', 'lyon': '🇫🇷', 'fransa': '🇫🇷', 'marsilya': '🇫🇷',
    'berlin': '🇩🇪', 'münih': '🇩🇪', 'frankfurt': '🇩🇪', 'almanya': '🇩🇪', 'hamburg': '🇩🇪',
    'amsterdam': '🇳🇱', 'hollanda': '🇳🇱', 'rotterdam': '🇳🇱',
    'dubai': '🇦🇪', 'abu dhabi': '🇦🇪', 'bae': '🇦🇪', 'sharjah': '🇦🇪',
    'tokyo': '🇯🇵', 'osaka': '🇯🇵', 'japonya': '🇯🇵',
    'milano': '🇮🇹', 'roma': '🇮🇹', 'italya': '🇮🇹', 'venedik': '🇮🇹',
    'madrid': '🇪🇸', 'barcelona': '🇪🇸', 'ispanya': '🇪🇸',
    'stockholm': '🇸🇪', 'isveç': '🇸🇪', 'göteborg': '🇸🇪',
    'zürih': '🇨🇭', 'cenevre': '🇨🇭', 'isviçre': '🇨🇭',
    'toronto': '🇨🇦', 'vancouver': '🇨🇦', 'kanada': '🇨🇦', 'montreal': '🇨🇦',
    'sidney': '🇦🇺', 'melbourne': '🇦🇺', 'avustralya': '🇦🇺',
    'seul': '🇰🇷', 'güney kore': '🇰🇷',
    'şangay': '🇨🇳', 'pekin': '🇨🇳', 'çin': '🇨🇳',
    'ukrayna': '🇺🇦', 'kiev': '🇺🇦', 'kyiv': '🇺🇦',
    'atina': '🇬🇷', 'yunanistan': '🇬🇷', 'selanik': '🇬🇷',
    'moskova': '🇷🇺', 'rusya': '🇷🇺', 'sankt petersburg': '🇷🇺',
    'varşova': '🇵🇱', 'polonya': '🇵🇱',
    'prag': '🇨🇿', 'çek': '🇨🇿',
    'budapeşte': '🇭🇺', 'macaristan': '🇭🇺',
    'bükreş': '🇷🇴', 'romanya': '🇷🇴',
    'sofya': '🇧🇬', 'bulgaristan': '🇧🇬',
    'belgrad': '🇷🇸', 'sırbistan': '🇷🇸',
    'mumbai': '🇮🇳', 'delhi': '🇮🇳', 'hindistan': '🇮🇳', 'bangalore': '🇮🇳',
    'bangkok': '🇹🇭', 'tayland': '🇹🇭',
    'singapur': '🇸🇬',
    'hong kong': '🇭🇰',
    'riyad': '🇸🇦', 'cidde': '🇸🇦', 'suudi arabistan': '🇸🇦',
    'kuveyt': '🇰🇼',
    'doha': '🇶🇦', 'katar': '🇶🇦',
  };

  // Tam kelime eşleşmesi — "uk" içeren her şeyin İngiltere bayrağı almaması için
  String? _bayrak(String sehir) {
    final k = sehir.toLowerCase().trim();
    // Önce tam eşleşme dene
    if (_bayraklar.containsKey(k)) return _bayraklar[k];
    // Sonra "içeriyor mu" kontrolü — ama kısa anahtarlar (3 harf ve altı) için tam eşleşme şartı
    for (final e in _bayraklar.entries) {
      if (e.key.length <= 3) {
        if (k == e.key) return e.value;
      } else {
        if (k.contains(e.key)) return e.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final maxIlan = widget.sehirler.first.ilanSayisi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bolumBaslik(baslik: 'Bu hafta nerelerden geliyorlar', ikon: Icons.location_on_outlined),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => Column(
              children: List.generate(widget.sehirler.length, (i) {
                final s = widget.sehirler[i];
                final oran = maxIlan > 0 ? s.ilanSayisi / maxIlan : 0.0;
                final bayrak = _bayrak(s.sehir);
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GelenlerScreen(
                        initialNereden: s.sehir,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
                    ),
                    child: Row(children: [
                      SizedBox(width: 22, child: Text('${i + 1}',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700,
                              color: i < 3 ? AppColors.red : AppColors.textHint))),
                      bayrak != null
                          ? Text(bayrak, style: const TextStyle(fontSize: 18))
                          : const Icon(Icons.public_outlined, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.sehir,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,  // w600 → w400
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: oran * _anim.value,  // 0'dan animasyonlu dolar
                              backgroundColor: AppColors.divider.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.red.withValues(alpha: 0.3 + oran * 0.5),
                              ),
                              minHeight: 2,  // 3 → 2
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider, width: 0.5),
                        ),
                        child: Text('İlanlar',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 4) İndirim & Outlet Mağazaları ───────────────────────────────────────────

class _IndirimMagazalariBolum extends StatefulWidget {
  const _IndirimMagazalariBolum();

  @override
  State<_IndirimMagazalariBolum> createState() => _IndirimMagazalariBolumState();
}

class _IndirimMagazalariBolumState extends State<_IndirimMagazalariBolum> {
  String _seciliUlke = 'tumu';

  static const _magazalar = [
    _Magaza('Amazon Outlet',    '🇺🇸', 'Amerika',  'us', 0xFFFFF3E0, 0xFFE65100, 'https://www.amazon.com/Outlet'),
    _Magaza('Nordstrom Rack',   '🇺🇸', 'Amerika',  'us', 0xFFEDE7F6, 0xFF4527A0, 'https://www.nordstromrack.com'),
    _Magaza('TJ Maxx',          '🇺🇸', 'Amerika',  'us', 0xFFE3F2FD, 0xFF0D47A1, 'https://www.tjmaxx.tjx.com'),
    _Magaza('Macy\'s Sale',     '🇺🇸', 'Amerika',  'us', 0xFFFCE4EC, 0xFF880E4F, 'https://www.macys.com/shop/sale'),
    _Magaza('ASOS Sale',        '🇬🇧', 'İngiltere', 'gb', 0xFFE8F5E9, 0xFF1B5E20, 'https://www.asos.com/sale'),
    _Magaza('Next Clearance',   '🇬🇧', 'İngiltere', 'gb', 0xFFF3E5F5, 0xFF4A148C, 'https://www.next.co.uk/shop/clearance'),
    _Magaza('M&S Outlet',       '🇬🇧', 'İngiltere', 'gb', 0xFFE0F2F1, 0xFF004D40, 'https://www.marksandspencer.com/c/sale'),
    _Magaza('Zalando Outlet',   '🇩🇪', 'Almanya',  'de', 0xFFFFF8E1, 0xFFF57F17, 'https://en.zalando.de/outlet/'),
    _Magaza('About You Sale',   '🇩🇪', 'Almanya',  'de', 0xFFE8EAF6, 0xFF1A237E, 'https://www.aboutyou.de/sale'),
    _Magaza('La Redoute',       '🇫🇷', 'Fransa',   'fr', 0xFFFCEAE8, 0xFFB71C1C, 'https://www.laredoute.fr/pplp/cat-promotion.aspx'),
    _Magaza('Cdiscount',        '🇫🇷', 'Fransa',   'fr', 0xFFE8F4FD, 0xFF0D47A1, 'https://www.cdiscount.com/promo'),
    _Magaza('YOOX',             '🇮🇹', 'İtalya',   'it', 0xFFF9FBE7, 0xFF33691E, 'https://www.yoox.com/us/women/sale/shoponline'),
    _Magaza('The Outnet',       '🇮🇹', 'İtalya',   'it', 0xFFFFF3E0, 0xFFBF360C, 'https://www.theoutnet.com'),
    _Magaza('Bol.com',          '🇳🇱', 'Hollanda', 'nl', 0xFFE3F2FD, 0xFF01579B, 'https://www.bol.com/nl/l/sale'),
    _Magaza('El Corte Inglés',  '🇪🇸', 'İspanya',  'es', 0xFFFFEBEE, 0xFFC62828, 'https://www.elcorteingles.es/ofertas'),
    _Magaza('Zara Sale',        '🇪🇸', 'İspanya',  'es', 0xFFF3E5F5, 0xFF6A1B9A, 'https://www.zara.com/es/en/woman-special-prices-l1314.html'),
    _Magaza('H&M Sale',         '🇸🇪', 'İsveç',    'se', 0xFFE8F5E9, 0xFF1B5E20, 'https://www2.hm.com/en_gb/sale.html'),
    _Magaza('AliExpress',       '🇨🇳', 'Çin',      'cn', 0xFFFFF3E0, 0xFFE65100, 'https://www.aliexpress.com/sale/sale-items.html'),
    _Magaza('JD.com',           '🇨🇳', 'Çin',      'cn', 0xFFE3F2FD, 0xFF0D47A1, 'https://www.jd.com'),
    _Magaza('Vip.com',          '🇨🇳', 'Çin',      'cn', 0xFFFCE4EC, 0xFF880E4F, 'https://www.vip.com'),
    _Magaza('Amazon Japan',     '🇯🇵', 'Japonya',  'jp', 0xFFFFF8E1, 0xFFF57F17, 'https://www.amazon.co.jp'),
    _Magaza('Rakuten Sale',     '🇯🇵', 'Japonya',  'jp', 0xFFFFEBEE, 0xFFC62828, 'https://www.rakuten.co.jp'),
    _Magaza('Gmarket Global',   '🇰🇷', 'G. Kore',  'kr', 0xFFE8F5E9, 0xFF1B5E20, 'https://global.gmarket.co.kr'),
    _Magaza('YesStyle',         '🇰🇷', 'G. Kore',  'kr', 0xFFF3E5F5, 0xFF6A1B9A, 'https://www.yesstyle.com/en/sale.html'),
  ];

  static const _ulkeler = [
    ('tumu', 'Tümü'),
    ('us',   '🇺🇸 Amerika'),
    ('gb',   '🇬🇧 İngiltere'),
    ('de',   '🇩🇪 Almanya'),
    ('fr',   '🇫🇷 Fransa'),
    ('it',   '🇮🇹 İtalya'),
    ('nl',   '🇳🇱 Hollanda'),
    ('es',   '🇪🇸 İspanya'),
    ('se',   '🇸🇪 İsveç'),
    ('cn',   '🇨🇳 Çin'),
    ('jp',   '🇯🇵 Japonya'),
    ('kr',   '🇰🇷 G. Kore'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtreli = _seciliUlke == 'tumu'
        ? _magazalar
        : _magazalar.where((m) => m.ulkeKod == _seciliUlke).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bolumBaslik(baslik: 'İndirim & outlet mağazaları', ikon: Icons.local_offer_outlined),

        // Ülke filtreleri
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _ulkeler.length,
            itemBuilder: (_, i) {
              final (kod, isim) = _ulkeler[i];
              final aktif = _seciliUlke == kod;
              return GestureDetector(
                onTap: () => setState(() => _seciliUlke = kod),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: aktif ? AppColors.red : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: aktif ? AppColors.red : AppColors.divider,
                      width: aktif ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(isim,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                          color: aktif ? Colors.white : AppColors.textPrimary)),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Mağaza kartları
        SizedBox(
          height: 158,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            itemCount: filtreli.length,
            itemBuilder: (_, i) => _MagazaKarti(magaza: filtreli[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Magaza {
  final String isim;
  final String bayrak;
  final String ulkeAdi;
  final String ulkeKod;
  final int arkaplanRenk;
  final int yaziRenk;
  final String url;
  const _Magaza(this.isim, this.bayrak, this.ulkeAdi, this.ulkeKod, this.arkaplanRenk, this.yaziRenk, this.url);
}

class _MagazaKarti extends StatelessWidget {
  final _Magaza magaza;
  const _MagazaKarti({required this.magaza});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(magaza.url), mode: LaunchMode.externalApplication),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renkli üst alan
            Container(
              height: 68,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(magaza.arkaplanRenk),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              alignment: Alignment.center,
              child: Text(magaza.isim,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(magaza.yaziRenk))),
            ),
            // Alt bilgi
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${magaza.bayrak} ${magaza.ulkeAdi}',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.red, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text('İndirimleri Gör',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
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

// ── İlk İlan Banner ───────────────────────────────────────────────────────────

class IlkIlanBannerPublic extends StatelessWidget {
  const IlkIlanBannerPublic({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/images/ilk_ilan.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}