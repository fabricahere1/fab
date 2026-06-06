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
        final tasiyiciMi = profil.tasiyiciMi;
        return tasiyiciMi
            ? _TasiyiciSanaOzel(key: const ValueKey('tasiyici'))
            : _IstekSanaOzel(key: const ValueKey('istek'));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// İSTEK kullanıcısı görünümü
// ─────────────────────────────────────────────────────────────────────────────

class _IstekSanaOzel extends ConsumerWidget {
  const _IstekSanaOzel({super.key});

  Future<void> _yenile(WidgetRef ref) async {
    await Future.wait([
      ref.read(istekIlanlarProvider.notifier).yenile(),
      ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sehirIlanlar      = ref.watch(sehirGelecekIlanlarProvider);
    final kategoriIlanlar   = ref.watch(kategorilereGoreIlanlarProvider);
    final bedenIlanlar      = ref.watch(bedenGoreIlanlarProvider);
    final populerIstekler   = ref.watch(populerKategoriIstekleriProvider);
    final dutyFreeIlanlar   = ref.watch(dutyFreeYapabilecekIlanlarProvider);

    final tumu = [
      _BolumData('SENİN ŞEHRİNE GELECEK İLANLAR', sehirIlanlar, Icons.flight_land_outlined),
      _BolumData('SENİN KATEGORİLERİN', kategoriIlanlar, Icons.interests_outlined),
      _BolumData('SENİN BEDENİNE GÖRE OLAN İLANLAR', bedenIlanlar, Icons.checkroom_outlined),
      _BolumData('İLGİLENDİĞİN KATEGORİLERDEN EN ÇOK İSTENENLER', populerIstekler, Icons.trending_up_rounded),
      _BolumData('DUTY FREE ALIŞVERİŞİ YAPABİLECEK OLANLAR', dutyFreeIlanlar, Icons.shopping_bag_outlined),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    if (tumu.isEmpty) {
      return RefreshIndicator(
        color: AppColors.red,
        onRefresh: () => _yenile(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _BosEkran(
                mesaj: 'Henüz sana özel içerik yok.\nProfilini tamamladıktan sonra burada kişiselleştirilmiş ilanlar görünecek.',
              ),
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
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: tumu.length,
        itemBuilder: (context, i) => _Bolum(data: tumu[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAŞIYICI kullanıcısı görünümü
// ─────────────────────────────────────────────────────────────────────────────

class _TasiyiciSanaOzel extends ConsumerWidget {
  const _TasiyiciSanaOzel({super.key});

  Future<void> _yenile(WidgetRef ref) =>
      ref.read(istekIlanlarProvider.notifier).yenile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seyahatIlanlar = ref.watch(seyahatSehriIlanlarProvider);
    final kargoIlanlar   = ref.watch(kargoKabulIsteklerProvider);
    final eldenIlanlar   = ref.watch(eldenKabulIsteklerProvider);
    final onayliIlanlar  = ref.watch(onayliIsteklerProvider);

    final tumu = [
      _BolumData('SEYAHAT EDECEĞİN ŞEHİRDEN AÇILAN İLANLAR', seyahatIlanlar, Icons.location_on_outlined),
      _BolumData('KARGO TESLİM KABUL EDEN İSTEKÇİLER', kargoIlanlar, Icons.local_shipping_outlined),
      _BolumData('ELDEN TESLİM KABUL EDEN İSTEKÇİLER', eldenIlanlar, Icons.handshake_outlined),
      _BolumData('ONAYLI İSTEKÇİLERİN İSTEKLERİ', onayliIlanlar, Icons.verified_outlined),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    if (tumu.isEmpty) {
      return RefreshIndicator(
        color: AppColors.red,
        onRefresh: () => _yenile(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _BosEkran(
                mesaj: 'Henüz sana özel içerik yok.\nSeyahat bilgilerini güncelledikten sonra burada eşleşen istekler görünecek.',
              ),
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
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: tumu.length,
        itemBuilder: (context, i) => _Bolum(data: tumu[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bölüm widget
// ─────────────────────────────────────────────────────────────────────────────

class _BolumData {
  final String baslik;
  final List<IlanModel> ilanlar;
  final IconData ikon;
  const _BolumData(this.baslik, this.ilanlar, this.ikon);
}

class _Bolum extends StatelessWidget {
  final _BolumData data;
  const _Bolum({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Icon(data.ikon, size: 16, color: AppColors.red),
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
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: data.ilanlar.length,
            itemBuilder: (context, i) => _SanaOzelKart(ilan: data.ilanlar[i]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sana Özel ilan kartı — yatay scroll için kompakt tasarım
// ─────────────────────────────────────────────────────────────────────────────

class _SanaOzelKart extends ConsumerWidget {
  final IlanModel ilan;
  const _SanaOzelKart({required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resim   = ilan.gridResim;
    final katAdi  = kategoriAdi(ilan.kategori);

    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
      },
      child: Container(
        width: 148,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.8),
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
            // Resim
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: resim.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resim,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        errorWidget: (_, _, _) => _RenkliArkaplan(ilan: ilan),
                      )
                    : _RenkliArkaplan(ilan: ilan),
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
                    // Güzergah
                    if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff_rounded,
                              size: 10,
                              color: AppColors.textSecondary),
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
            size: 32,
            color: AppColors.textHint.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Boş ekran
// ─────────────────────────────────────────────────────────────────────────────

class _BosEkran extends StatelessWidget {
  final String mesaj;
  const _BosEkran({required this.mesaj});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined,
                size: 56,
                color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              mesaj,
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
