// lib/features/home/presentation/kesfet_vitrin_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kesfet_bolum_baslik.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/home/providers/kesfet_vitrin_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'kesfet_bolum_detay_screen.dart';
import 'package:iste_v3/features/ilanlar/presentation/widgets/ilan_karti.dart' show ShimmerGrid;

enum RozetTipi { goruntulenme, favori, yeni, eta, dutyFree, yok }

/// Grup 1: Haftanın en çok görüntülenenleri + favorilenenleri.
class KesfetGoruntulenenFavorilenenBolum extends ConsumerWidget {
  const KesfetGoruntulenenFavorilenenBolum({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goruntulenen = ref.watch(kesfetEnCokGoruntulenenProvider);
    final favorilenen  = ref.watch(kesfetEnCokFavorilenenProvider);

    final bolumler = <_BolumData>[
      _BolumData('Haftanın en çok görüntülenen ilanları', Icons.visibility_outlined, goruntulenen, RozetTipi.goruntulenme, CicekTipi.papatya),
      _BolumData('Haftanın en çok favorilenen ilanları', Icons.favorite_outline_rounded, favorilenen, RozetTipi.favori, CicekTipi.gul),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    return Column(mainAxisSize: MainAxisSize.min, children: bolumler.map((b) => _Bolum(data: b)).toList());
  }
}

/// Grup 2: Bugün eklenen + Yakında Türkiye'ye gelecekler + Duty Free.
class KesfetGuncelBolumler extends ConsumerWidget {
  const KesfetGuncelBolumler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bugunEklenen = ref.watch(kesfetBugunEklenenProvider);
    final yakinGelecek = ref.watch(kesfetYakinGeleceklerProvider);
    final dutyFree     = ref.watch(kesfetDutyFreeProvider);

    final bolumler = <_BolumData>[
      _BolumData('Bugün eklenen ilanlar', Icons.fiber_new_outlined, bugunEklenen, RozetTipi.yeni, CicekTipi.lavanta),
      _BolumData('Yakın zamanda Türkiye\'ye gelecekler', Icons.flight_land_outlined, yakinGelecek, RozetTipi.eta, CicekTipi.aycicegi),
      _BolumData('Bugün yola çıkacaklar · Duty Free fırsatları', Icons.local_mall_outlined, dutyFree, RozetTipi.dutyFree, CicekTipi.papatya),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    return Column(mainAxisSize: MainAxisSize.min, children: bolumler.map((b) => _Bolum(data: b)).toList());
  }
}

/// Tüm Vitrin1 bölümleri hâlâ boşsa true döner — kesfet_screen.dart bununla
/// boş-ekranı (KesfetBosEkran) gösterip göstermeyeceğine karar verir.
bool kesfetVitrin1TamamenBosMu(WidgetRef ref) {
  final goruntulenen = ref.watch(kesfetEnCokGoruntulenenProvider);
  final favorilenen  = ref.watch(kesfetEnCokFavorilenenProvider);
  final bugunEklenen = ref.watch(kesfetBugunEklenenProvider);
  final yakinGelecek = ref.watch(kesfetYakinGeleceklerProvider);
  final dutyFree     = ref.watch(kesfetDutyFreeProvider);
  return goruntulenen.isEmpty && favorilenen.isEmpty && bugunEklenen.isEmpty &&
      yakinGelecek.isEmpty && dutyFree.isEmpty;
}

class KesfetVitrinTab extends ConsumerWidget {
  const KesfetVitrinTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yukleniyor = ref.watch(istekIlanlarProvider).yukleniyor || ref.watch(tasiyiciIlanlarProvider).yukleniyor;
    final bosMu = kesfetVitrin1TamamenBosMu(ref);

    if (bosMu) {
      return yukleniyor
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: ShimmerGrid(kolonSayisi: 2),
            )
          : const KesfetBosEkran();
    }

    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KesfetHeroBanner(),
        KesfetGoruntulenenFavorilenenBolum(),
        KesfetGuncelBolumler(),
        SizedBox(height: 8),
      ],
    );
  }
}

/// "Önerilen ilanlar" — kesfetOnerilenIlanlarProvider'dan gelen 30 ilanı
/// 2 satıra (15+15) böler.
class KesfetOnerilenBolum extends ConsumerWidget {
  const KesfetOnerilenBolum({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(kesfetOnerilenIlanlarProvider);
    if (liste.isEmpty) return const SizedBox.shrink();
    final satir1 = liste.take(15).toList();
    final satir2 = liste.skip(15).take(15).toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _Bolum(data: _BolumData('Senin için seçtiklerimiz', Icons.auto_awesome_outlined, satir1, RozetTipi.yok, CicekTipi.gul)),
      if (satir2.isNotEmpty)
        _Bolum(data: _BolumData('Bunlar da ilgini çekebilir', Icons.local_florist_outlined, satir2, RozetTipi.yok, CicekTipi.lavanta)),
    ]);
  }
}

/// "En yeni ilanlar" — başlık kasıtlı olarak "en yeni"/"önerilen" demiyor,
/// 2 satıra (15+15) bölünür.
class KesfetEnYeniBolum extends ConsumerWidget {
  const KesfetEnYeniBolum({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(kesfetEnYeniIlanlarProvider);
    if (liste.isEmpty) return const SizedBox.shrink();
    final satir1 = liste.take(15).toList();
    final satir2 = liste.skip(15).take(15).toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _Bolum(data: _BolumData('Vitrine az önce çıkanlar', Icons.storefront_outlined, satir1, RozetTipi.yok, CicekTipi.aycicegi)),
      if (satir2.isNotEmpty)
        _Bolum(data: _BolumData('Gözden kaçırma', Icons.remove_red_eye_outlined, satir2, RozetTipi.yok, CicekTipi.papatya)),
    ]);
  }
}

/// "En eski ilanlar" — 1 satırlık kullanım (Duty Free ile Trend ürünler
/// arasında). kesfetEnEskiIlanlarProvider'ın İLK 15 ilanını kullanır.
class KesfetEnEskiBolum1Satir extends ConsumerWidget {
  const KesfetEnEskiBolum1Satir({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(kesfetEnEskiIlanlarProvider).take(15).toList();
    if (liste.isEmpty) return const SizedBox.shrink();
    return _Bolum(data: _BolumData('Daha fazlası', Icons.hourglass_empty_rounded, liste, RozetTipi.yok, CicekTipi.gul));
  }
}

/// "En eski ilanlar" — 2 satırlık kullanım (Bu hafta nereden geliyorlar ile
/// İndirim outlet arasında). kesfetEnEskiIlanlarProvider'ın 15-45 arası
/// ilanlarını kullanır — ilk 15'i yukarıdaki tek satırlık bölüm aldığı için
/// burada tekrar etmez.
class KesfetEnEskiBolum2Satir extends ConsumerWidget {
  const KesfetEnEskiBolum2Satir({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tum = ref.watch(kesfetEnEskiIlanlarProvider);
    final satir1 = tum.skip(15).take(15).toList();
    final satir2 = tum.skip(30).take(15).toList();
    if (satir1.isEmpty && satir2.isEmpty) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (satir1.isNotEmpty)
        _Bolum(data: _BolumData('Bunlara baktın mı', Icons.search_outlined, satir1, RozetTipi.yok, CicekTipi.aycicegi)),
      if (satir2.isNotEmpty)
        _Bolum(data: _BolumData('Bunları da getirebilirsin', Icons.refresh_rounded, satir2, RozetTipi.yok, CicekTipi.papatya)),
    ]);
  }
}

/// "Rastgele keşfet karması" — 2 satır, İlk İlanını Ver banner'ından sonra.
class KesfetRastgeleKarmaBolum extends ConsumerWidget {
  const KesfetRastgeleKarmaBolum({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(kesfetRastgeleKarmaProvider);
    if (liste.isEmpty) return const SizedBox.shrink();
    final satir1 = liste.take(15).toList();
    final satir2 = liste.skip(15).take(15).toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _Bolum(data: _BolumData('İSTE\'den special ilanlar', Icons.shuffle_rounded, satir1, RozetTipi.yok, CicekTipi.lavanta)),
      if (satir2.isNotEmpty)
        _Bolum(data: _BolumData('Keşfetmeye devam et', Icons.explore_outlined, satir2, RozetTipi.yok, CicekTipi.gul)),
    ]);
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
  final RozetTipi rozetTipi;
  final CicekTipi cicekTipi;
  const _BolumData(this.baslik, this.ikon, this.ilanlar, this.rozetTipi, this.cicekTipi);
}

class _Bolum extends StatelessWidget {
  final _BolumData data;
  const _Bolum({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      KesfetBolumBaslik(
        baslik: data.baslik,
        ikon: data.ikon,
        onTumunuGor: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KesfetBolumDetayScreen(
              baslik: data.baslik,
              ilanlar: data.ilanlar,
              ikon: data.ikon,
            ),
          ),
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

class _KesfetKart extends ConsumerWidget {
  final IlanModel ilan;
  final RozetTipi rozetTipi;
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
                resim.isNotEmpty ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: resim, fit: BoxFit.cover, memCacheWidth: 310, memCacheHeight: 300, fadeInDuration: Duration.zero, placeholder: (_, _) => Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!, child: Container(color: Colors.white)), errorWidget: (_, _, _) => _RenkliArkaplan(cicekTipi: cicekTipi)) : _RenkliArkaplan(cicekTipi: cicekTipi),
                if (rozetTipi != RozetTipi.yok)
                  Positioned(top: 6, left: 6, child: _Rozet(ilan: ilan, tipi: rozetTipi, favoriSayisi: ref.canliFavoriSayisi(ilan), goruntulenmeSayisi: ref.canliGoruntulenmeSayisi(ilan))),
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
                Text('${ref.canliGoruntulenmeSayisi(ilan)}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
                const SizedBox(width: 6),
                const Icon(Icons.favorite_border, size: 10, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text('${ref.canliFavoriSayisi(ilan)}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
              ]),
            ]))),
        ]),
      ),
    );
  }
}

class _Rozet extends StatelessWidget {
  final IlanModel ilan;
  final RozetTipi tipi;
  final int favoriSayisi;
  final int goruntulenmeSayisi;
  const _Rozet({required this.ilan, required this.tipi, required this.favoriSayisi, required this.goruntulenmeSayisi});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    switch (tipi) {
      case RozetTipi.goruntulenme: return _pill(ikon: Icons.visibility_rounded, metin: _sayiFormat(goruntulenmeSayisi), renk: const Color(0xCC1A1A1A));
      case RozetTipi.favori:       return _pill(ikon: Icons.favorite_rounded, metin: _sayiFormat(favoriSayisi), renk: AppColors.red.withValues(alpha: 0.92));
      case RozetTipi.yeni:         return _pill(metin: 'YENİ', renk: AppColors.red.withValues(alpha: 0.92));
      case RozetTipi.eta:          return _pill(ikon: Icons.schedule_rounded, metin: _etaMetin(ilan.tarih, now), renk: _etaRenk(ilan.tarih, now));
      case RozetTipi.dutyFree:     return _pill(ikon: Icons.local_mall_rounded, metin: 'DUTY FREE', renk: const Color(0xE6B8860B));
      case RozetTipi.yok:          return const SizedBox.shrink();
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

class KesfetHeroBanner extends ConsumerWidget {
  const KesfetHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroIlanlar = ref.watch(kesfetHeroBannerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: const Color(0xFF7C3AED), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: SizedBox(
          height: 236,
          child: Stack(
            children: [
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
                              style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
                          child: Text('Tümü →',
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 12, 6),
                    child: Text('Öne çıkanlar',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
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
                                  width: 120,
                                  height: 160,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFC9A24B), width: 1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        resim.isNotEmpty
                                            ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: resim, fit: BoxFit.cover, memCacheWidth: 240, memCacheHeight: 320, fadeInDuration: Duration.zero, placeholder: (_, _) => Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!, child: Container(color: Colors.white)))
                                            : Container(color: AppColors.surface, child: Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 26)),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                                              stops: const [0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 8, right: 8, bottom: 8,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                              ),
                                              Text(
                                                ilan.tip == IlanTip.istek
                                                    ? '→ ${ilan.nereye}'
                                                    : '${ilan.nereden} → ${ilan.nereye}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.dmSans(fontSize: 9, color: Colors.white.withValues(alpha: 0.85)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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

class KesfetBosEkran extends StatelessWidget {
  const KesfetBosEkran({super.key});
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