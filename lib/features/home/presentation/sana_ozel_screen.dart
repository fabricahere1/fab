// lib/features/home/presentation/sana_ozel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/profil/providers/profil_provider.dart';
import 'package:iste_v3/features/profil/domain/kullanici_model.dart';
import 'package:iste_v3/features/home/providers/sana_ozel_providers.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/home/presentation/kesfet_vitrin_tab.dart'
    show CicekBaslikPainter, CicekTipi, KartZeminPainter;
import 'package:iste_v3/features/home/presentation/kesfet_bolum_detay_screen.dart';

class SanaOzelScreen extends ConsumerWidget {
  const SanaOzelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(benimKullaniciProfilProvider);
    return profilAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (profil) {
        if (profil == null) return const SizedBox.shrink();
        return profil.tasiyiciMi
            ? const _TasiyiciSanaOzel(key: ValueKey('tasiyici'))
            : const _IstekSanaOzel(key: ValueKey('istek'));
      },
    );
  }
}

// ── İSTEK ────────────────────────────────────────────────────────────────────

class _IstekSanaOzel extends ConsumerWidget {
  const _IstekSanaOzel({super.key});

  Future<void> _yenile(WidgetRef ref) => Future.wait([
    ref.read(istekIlanlarProvider.notifier).yenile(),
    ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tumu = [
      _BolumData('Senin şehrine gelecek ilanlar', ref.watch(sehirGelecekIlanlarProvider), Icons.flight_land_outlined, CicekTipi.papatya),
      _BolumData('Senin kategorilerin', ref.watch(kategorilereGoreIlanlarProvider), Icons.interests_outlined, CicekTipi.gul),
      _BolumData('Senin bedenine göre ilanlar', ref.watch(bedenGoreIlanlarProvider), Icons.checkroom_outlined, CicekTipi.lavanta),
      _BolumData('İlgilendiğin kategorilerden en çok istenenler', ref.watch(populerKategoriIstekleriProvider), Icons.trending_up_rounded, CicekTipi.aycicegi),
      _BolumData('Duty Free alışverişi yapabilecek olanlar', ref.watch(dutyFreeYapabilecekIlanlarProvider), Icons.shopping_bag_outlined, CicekTipi.papatya),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    return RefreshIndicator(
          color: AppColors.red,
          onRefresh: () => _yenile(ref),
          child: tumu.isEmpty
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.7,
                      child: const _BosEkran(mesaj: 'Henüz sana özel içerik yok.\nProfilini tamamladıktan sonra burada kişiselleştirilmiş ilanlar görünecek.')),
                ])
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  itemCount: tumu.length,
                  itemBuilder: (_, i) => _Bolum(data: tumu[i]),
                ),
        );
  }
}

// ── TAŞIYICI ─────────────────────────────────────────────────────────────────

class _TasiyiciSanaOzel extends ConsumerWidget {
  const _TasiyiciSanaOzel({super.key});

  Future<void> _yenile(WidgetRef ref) => Future.wait([
    ref.read(istekIlanlarProvider.notifier).yenile(),
    ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tumu = [
      _BolumData('Seyahat edeceğin şehirden açılan ilanlar', ref.watch(seyahatSehriIlanlarProvider), Icons.location_on_outlined, CicekTipi.aycicegi),
      _BolumData('Kargo teslim kabul eden istekçiler', ref.watch(kargoKabulIsteklerProvider), Icons.local_shipping_outlined, CicekTipi.lavanta),
      _BolumData('Elden teslim kabul eden istekçiler', ref.watch(eldenKabulIsteklerProvider), Icons.handshake_outlined, CicekTipi.gul),
      _BolumData('Onaylı istekçilerin istekleri', ref.watch(onayliIsteklerProvider), Icons.verified_outlined, CicekTipi.papatya),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    return RefreshIndicator(
          color: AppColors.red,
          onRefresh: () => _yenile(ref),
          child: tumu.isEmpty
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.7,
                      child: const _BosEkran(mesaj: 'Henüz sana özel içerik yok.\nSeyahat bilgilerini güncelledikten sonra burada eşleşen istekler görünecek.')),
                ])
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  itemCount: tumu.length,
                  itemBuilder: (_, i) => _Bolum(data: tumu[i]),
                ),
        );
  }
}

// ── Bölüm ─────────────────────────────────────────────────────────────────────

class _BolumData {
  final String baslik;
  final List<IlanModel> ilanlar;
  final IconData ikon;
  final CicekTipi cicekTipi;
  const _BolumData(this.baslik, this.ilanlar, this.ikon, this.cicekTipi);
}

class _Bolum extends StatelessWidget {
  final _BolumData data;
  const _Bolum({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık + Tümünü Göster butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    child: Text('Tümünü Gör',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Icon(data.ikon, size: 15, color: AppColors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(data.baslik,
                      style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.1)),
                ),
              ]),
            ],
          ),
        ),
        // Kartların scroll alanı — çiçekli zemin
        SizedBox(
          height: 270,
          child: Stack(children: [
            Positioned.fill(
              child: CustomPaint(painter: KartZeminPainter(data.cicekTipi)),
            ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: data.ilanlar.length,
              itemBuilder: (_, i) => _SanaOzelKart(ilan: data.ilanlar[i], cicekTipi: data.cicekTipi),
            ),
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SanaOzelKart extends ConsumerWidget {
  final IlanModel ilan;
  final CicekTipi cicekTipi;
  const _SanaOzelKart({required this.ilan, required this.cicekTipi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resim  = ilan.gridResim;
    final katAdi = kategoriAdi(ilan.kategori);
    return GestureDetector(
      onTap: () { ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan); context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan); },
      child: Container(
        width: 155,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF888888), width: 0.3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Container(height: 150, width: double.infinity, color: const Color(0xFFF2F2F2),
              child: resim.isNotEmpty
                  ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: resim, fit: BoxFit.cover, fadeInDuration: Duration.zero, errorWidget: (_, _, _) => _RenkliArkaplan(cicekTipi: cicekTipi))
                  : _RenkliArkaplan(cicekTipi: cicekTipi)),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (ilan.urun.isNotEmpty) Text(ilan.urun, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty)
                Row(children: [const Icon(Icons.flight_takeoff_rounded, size: 10, color: AppColors.textSecondary), const SizedBox(width: 3),
                  Expanded(child: Text('${ilan.nereden} → ${ilan.nereye}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis))]),
              if (katAdi.isNotEmpty)
                Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ]),
          )),
        ]),
      ),
    );
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

class _BosEkran extends StatelessWidget {
  final String mesaj;
  const _BosEkran({required this.mesaj});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_search_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(mesaj, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      ])));
  }
}