import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/kesfet_computed_providers.dart';
import 'package:iste_v3/features/home/presentation/kesfet/widgets/kesfet_widgets.dart';

// Bilinen şehir koordinatları — harita marker'ları için
const _sehirKoordinatlari = <String, LatLng>{
  'istanbul':   LatLng(41.0082, 28.9784),
  'ankara':     LatLng(39.9334, 32.8597),
  'izmir':      LatLng(38.4189, 27.1287),
  'new york':   LatLng(40.7128, -74.0060),
  'london':     LatLng(51.5074, -0.1278),
  'berlin':     LatLng(52.5200, 13.4050),
  'paris':      LatLng(48.8566, 2.3522),
  'tokyo':      LatLng(35.6762, 139.6503),
  'dubai':      LatLng(25.2048, 55.2708),
  'amsterdam':  LatLng(52.3676, 4.9041),
  'rome':       LatLng(41.9028, 12.4964),
  'barcelona':  LatLng(41.3851, 2.1734),
  'frankfurt':  LatLng(50.1109, 8.6821),
  'madrid':     LatLng(40.4168, -3.7038),
  'vienna':     LatLng(48.2082, 16.3738),
  'zurich':     LatLng(47.3769, 8.5417),
  'brussels':   LatLng(50.8503, 4.3517),
  'stockholm':  LatLng(59.3293, 18.0686),
  'athens':     LatLng(37.9838, 23.7275),
  'moscow':     LatLng(55.7558, 37.6173),
};

LatLng? _koordinatBul(String sehir) {
  final anahtar = sehir.toLowerCase().trim();
  for (final entry in _sehirKoordinatlari.entries) {
    if (anahtar.contains(entry.key)) return entry.value;
  }
  return null;
}

class HaritaTab extends ConsumerStatefulWidget {
  const HaritaTab({super.key});

  @override
  ConsumerState<HaritaTab> createState() => _HaritaTabState();
}

class _HaritaTabState extends ConsumerState<HaritaTab> {
  String? _seciliUlke;
  final _mapCtrl = MapController();

  static const _ulkeler = [
    {'flag': '🇺🇸', 'ad': 'Amerika'},
    {'flag': '🇬🇧', 'ad': 'İngiltere'},
    {'flag': '🇩🇪', 'ad': 'Almanya'},
    {'flag': '🇯🇵', 'ad': 'Japonya'},
    {'flag': '🇫🇷', 'ad': 'Fransa'},
    {'flag': '🇮🇹', 'ad': 'İtalya'},
    {'flag': '🇳🇱', 'ad': 'Hollanda'},
    {'flag': '🇦🇪', 'ad': 'Dubai'},
  ];

  @override
  Widget build(BuildContext context) {
    final tasiyiciState  = ref.watch(tasiyiciIlanlarProvider);
    final ulkeSayilari   = ref.watch(ulkeIlanSayilariProvider);
    final ilanlar        = tasiyiciState.filtrelenmis;
    final maxSayi        = ulkeSayilari.values.fold(1, (a, b) => a > b ? a : b);

    // Haritada gösterilecek marker'lar
    final markers = <Marker>[];
    for (final ilan in ilanlar) {
      final coord = _koordinatBul(ilan.nereden);
      if (coord == null) continue;
      markers.add(
        Marker(
          point: coord,
          width: 32,
          height: 32,
          child: GestureDetector(
            onTap: () => _ilanBottomSheet(context, ilan),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    // Polyline'lar — güzergah çizgileri
    final polylines = <Polyline>[];
    for (final ilan in ilanlar.take(20)) {
      final baslangic = _koordinatBul(ilan.nereden);
      final bitis     = _koordinatBul(ilan.nereye);
      if (baslangic == null || bitis == null) continue;
      polylines.add(
        Polyline(
          points: [baslangic, bitis],
          color: AppColors.red.withValues(alpha: 0.3),
          strokeWidth: 1.5,
          // strokePattern: StrokePattern.dotted(),
        ),
      );
    }

    final seciliIlanlar = _seciliUlke == null
        ? <IlanModel>[]
        : ilanlar.where((i) {
            final q = _seciliUlke!.toLowerCase();
            return i.nereden.toLowerCase().contains(q) ||
                i.nereye.toLowerCase().contains(q);
          }).toList();

    return CustomScrollView(
      slivers: [
        // ── Gerçek harita ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 220,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: const MapOptions(
                    initialCenter: LatLng(41.0, 29.0),
                    initialZoom: 2.5,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.iste.app',
                    ),
                    if (polylines.isNotEmpty)
                      PolylineLayer(polylines: polylines),
                    if (markers.isNotEmpty)
                      MarkerLayer(markers: markers),
                  ],
                ),
                // Aktif güzergah badge
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flight_takeoff_rounded,
                            size: 12, color: AppColors.red),
                        const SizedBox(width: 5),
                        Text(
                          '${ilanlar.length} aktif güzergah',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Ülkelere göre ilanlar ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text('Ülkelere göre ilanlar',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ulke   = _ulkeler[index];
              // Gerçek Firestore verisi — hardcoded sayı yok
              final sayi   = ulkeSayilari[ulke['ad']] ?? 0;
              final oran   = maxSayi > 0 ? sayi / maxSayi : 0.0;
              final secili = _seciliUlke == ulke['ad'];

              return GestureDetector(
                onTap: () {
                  setState(() =>
                      _seciliUlke = secili ? null : ulke['ad'] as String);
                  // Seçili ülkenin koordinatına git
                  if (!secili) {
                    final coord =
                        _koordinatBul(ulke['ad']!.toLowerCase());
                    if (coord != null) {
                      _mapCtrl.move(coord, 4.0);
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secili
                        ? AppColors.red.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: secili ? AppColors.red : AppColors.divider,
                      width: secili ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(ulke['flag']!,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ulke['ad']!,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: oran,
                                backgroundColor: AppColors.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  secili
                                      ? AppColors.red
                                      : const Color(0xFF64B5F6),
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        sayi > 0 ? '$sayi ilan' : 'yakında',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secili
                                ? AppColors.red
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: _ulkeler.length,
          ),
        ),

        // ── Seçili ülke ilanları ─────────────────────────────────────────────
        if (_seciliUlke != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('$_seciliUlke ilanları',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          if (tasiyiciState.yukleniyor)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (_, _) => const SkeletonKart(),
                ),
              ),
            )
          else if (seciliIlanlar.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('Bu ülkeden ilan bulunamadı',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childCount: seciliIlanlar.length,
                itemBuilder: (_, i) =>
                    KesfetKarti(ilan: seciliIlanlar[i]),
              ),
            ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _ilanBottomSheet(BuildContext context, IlanModel ilan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded,
                    color: AppColors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ilan.kullaniciAd,
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 13)),
            if (ilan.tarih != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tarih: ${ilan.tarih!.day}.${ilan.tarih!.month}.${ilan.tarih!.year}',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('İlanı Gör',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}