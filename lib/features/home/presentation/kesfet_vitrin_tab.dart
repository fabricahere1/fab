// lib/features/home/presentation/kesfet_vitrin_tab.dart
//
// "Keşfet" sekmesi içeriği — herkese aynı görünen, kişiselleştirilmemiş vitrin.
// Bölümler dokümandaki sırayla:
//   1) Haftanın en çok görüntülenen ilanları
//   2) Haftanın en çok favorilenen ilanları
//   3) Bugün eklenen ilanlar
//   4) Yakın zamanda Türkiye'ye gelecekler
//   5) Bugün yola çıkacaklar – Duty Free fırsatları

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

// Kartlardaki rozetin türü — her bölüm farklı bir metriği öne çıkarır.
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

    final yukleniyor = ref.watch(istekIlanlarProvider).yukleniyor ||
        ref.watch(tasiyiciIlanlarProvider).yukleniyor;

    final bolumler = <_BolumData>[
      _BolumData(
        'HAFTANIN EN ÇOK GÖRÜNTÜLENEN İLANLARI',
        Icons.visibility_outlined,
        goruntulenen,
        _RozetTipi.goruntulenme,
      ),
      _BolumData(
        'HAFTANIN EN ÇOK FAVORİLENEN İLANLARI',
        Icons.favorite_outline_rounded,
        favorilenen,
        _RozetTipi.favori,
      ),
      _BolumData(
        'BUGÜN EKLENEN İLANLAR',
        Icons.fiber_new_outlined,
        bugunEklenen,
        _RozetTipi.yeni,
      ),
      _BolumData(
        'YAKIN ZAMANDA TÜRKİYE\'YE GELECEKLER',
        Icons.flight_land_outlined,
        yakinGelecek,
        _RozetTipi.eta,
      ),
      _BolumData(
        'BUGÜN YOLA ÇIKACAKLAR · DUTY FREE FIRSATLARI',
        Icons.local_mall_outlined,
        dutyFree,
        _RozetTipi.dutyFree,
      ),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    if (bolumler.isEmpty) {
      return RefreshIndicator(
        color: AppColors.red,
        onRefresh: () => _yenile(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: yukleniyor
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.red, strokeWidth: 2))
                  : const _BosEkran(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _yenile(ref),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: bolumler.length,
        itemBuilder: (context, i) => _Bolum(data: bolumler[i]),
      ),
    );
  }
}

// ── Bölüm modeli & widget'ı ───────────────────────────────────────────────────

class _BolumData {
  final String baslik;
  final IconData ikon;
  final List<IlanModel> ilanlar;
  final _RozetTipi rozetTipi;
  const _BolumData(this.baslik, this.ikon, this.ilanlar, this.rozetTipi);
}

class _Bolum extends StatelessWidget {
  final _BolumData data;
  const _Bolum({required this.data});

  @override
  Widget build(BuildContext context) {
    final dutyFree = data.rozetTipi == _RozetTipi.dutyFree;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Icon(data.ikon,
                  size: 16,
                  color: dutyFree ? const Color(0xFFB8860B) : AppColors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.baslik,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 285,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: data.ilanlar.length,
            itemBuilder: (context, i) =>
                _KesfetKart(ilan: data.ilanlar[i], rozetTipi: data.rozetTipi),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── İlan kartı ────────────────────────────────────────────────────────────────

class _KesfetKart extends ConsumerWidget {
  final IlanModel ilan;
  final _RozetTipi rozetTipi;
  const _KesfetKart({required this.ilan, required this.rozetTipi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resim  = ilan.gridResim;
    final katAdi = kategoriAdi(ilan.kategori);

    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF888888), width: 0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim + rozet — tam boyut (kırpmadan), arkada nötr gri zemin
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                height: 185,
                width: double.infinity,
                color: const Color(0xFFF2F2F2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    resim.isNotEmpty
                        ? CachedNetworkImage(
                            cacheManager: AppCacheManager.instance,
                            imageUrl: resim,
                            fit: BoxFit.contain,
                            fadeInDuration: Duration.zero,
                            errorWidget: (_, _, _) =>
                                _RenkliArkaplan(ilan: ilan),
                          )
                        : _RenkliArkaplan(ilan: ilan),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _Rozet(ilan: ilan, tipi: rozetTipi),
                    ),
                  ],
                ),
              ),
            ),

            // Bilgi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ilan.urun.isNotEmpty)
                      Text(
                        ilan.urun,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.flight_takeoff_rounded,
                              size: 10, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${ilan.nereden} → ${ilan.nereye}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (katAdi.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          katAdi,
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rozet ─────────────────────────────────────────────────────────────────────

class _Rozet extends StatelessWidget {
  final IlanModel ilan;
  final _RozetTipi tipi;
  const _Rozet({required this.ilan, required this.tipi});

  @override
  Widget build(BuildContext context) {
    switch (tipi) {
      case _RozetTipi.goruntulenme:
        return _pill(
          ikon: Icons.visibility_rounded,
          metin: _sayiFormat(ilan.goruntulenmeSayisi),
          renk: const Color(0xCC1A1A1A),
        );
      case _RozetTipi.favori:
        return _pill(
          ikon: Icons.favorite_rounded,
          metin: _sayiFormat(ilan.favoriSayisi),
          renk: AppColors.red.withValues(alpha: 0.92),
        );
      case _RozetTipi.yeni:
        return _pill(metin: 'YENİ', renk: AppColors.red.withValues(alpha: 0.92));
      case _RozetTipi.eta:
        return _pill(
          ikon: Icons.schedule_rounded,
          metin: _etaMetin(ilan.tarih),
          renk: _etaRenk(ilan.tarih),
        );
      case _RozetTipi.dutyFree:
        return _pill(
          ikon: Icons.local_mall_rounded,
          metin: 'DUTY FREE',
          renk: const Color(0xE6B8860B),
        );
    }
  }

  Widget _pill({IconData? ikon, required String metin, required Color renk}) {
    if (metin.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 10, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            metin,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Renkli arkaplan (resimsiz ilanlar için) ──────────────────────────────────

class _RenkliArkaplan extends StatelessWidget {
  final IlanModel ilan;
  const _RenkliArkaplan({required this.ilan});

  static const _renkler = [
    Color(0xFFFFF3F3),
    Color(0xFFF3F7FF),
    Color(0xFFF3FFF7),
    Color(0xFFFFF9F3),
    Color(0xFFF9F3FF),
  ];

  @override
  Widget build(BuildContext context) {
    final renk = _renkler[ilan.id.hashCode.abs() % _renkler.length];
    return Container(
      color: renk,
      child: Center(
        child: Icon(Icons.inventory_2_outlined,
            size: 32, color: AppColors.textHint.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ── Boş ekran ─────────────────────────────────────────────────────────────────

class _BosEkran extends StatelessWidget {
  const _BosEkran();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_outlined,
                size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Keşfedilecek içerik birazdan burada.\nİlanlar yüklendikçe en popüler ve en yeni\nilanlar bu sekmede listelenecek.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Yardımcılar ───────────────────────────────────────────────────────────────

String _sayiFormat(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _etaMetin(DateTime? tarih) {
  if (tarih == null) return '';
  final fark = DateTime(tarih.year, tarih.month, tarih.day)
      .difference(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day))
      .inDays;
  if (fark <= 0) return 'BUGÜN';
  if (fark == 1) return 'YARIN';
  return '$fark GÜN';
}

Color _etaRenk(DateTime? tarih) {
  if (tarih == null) return const Color(0xCC1A1A1A);
  final fark = DateTime(tarih.year, tarih.month, tarih.day)
      .difference(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day))
      .inDays;
  if (fark <= 0) return AppColors.red.withValues(alpha: 0.92);
  if (fark <= 2) return const Color(0xE6E65100);
  return const Color(0xCC1565C0);
}
