// lib/features/home/presentation/kesfet_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/arama/presentation/arama_screen.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/ilanlar/presentation/ilan_form_screen.dart';
import 'sana_ozel_screen.dart';
import 'kesfet_vitrin_tab.dart';
import 'kesfet_vitrin2_tab.dart';
import 'kategori_vitrini_bolum.dart';
import 'alisveris_rehberi_bolum.dart';
import 'beden_donusturucu_bolum.dart';
import 'tasiyici_ipuclari_bolum.dart';

class KesfetScreen extends ConsumerStatefulWidget {
  const KesfetScreen({super.key});

  @override
  ConsumerState<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends ConsumerState<KesfetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  double _sonPixel = 0;
  static const _threshold = 80.0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) return;
      _sonPixel = 0;
      ref.read(navBarGizliProvider.notifier).goster();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification n) {
    if (n.metrics.axis == Axis.horizontal) return false;
    if (n is! ScrollUpdateNotification) return false;
    if (n.scrollDelta == null) return false;

    final simdi = n.metrics.pixels;
    final gizli = ref.read(navBarGizliProvider);

    if (n.scrollDelta! > 0) {
      _sonPixel = simdi;
      if (!gizli) ref.read(navBarGizliProvider.notifier).gizle();
    } else if (n.scrollDelta! < 0) {
      if (simdi < _sonPixel - _threshold) {
        _sonPixel = simdi;
        if (gizli) ref.read(navBarGizliProvider.notifier).goster();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusH  = MediaQuery.of(context).padding.top;
    // navBarGizliProvider'ı dinle — nav bar gizliyse üst bar da gizlenir
    final ustGizli = ref.watch(navBarGizliProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Status bar — her zaman sabit
          Container(height: statusH, color: Colors.white),

          // Arama + Tab bar — nav bar ile senkron
          Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    heightFactor: ustGizli ? 0.0 : 1.0,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) => const AramaScreen(),
                            transitionsBuilder: (_, anim, _, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 200),
                          ),
                        ),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(Icons.search_rounded, size: 18, color: Color(0xFFCCCCCC)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Ne arıyorsun ?',
                                    style: GoogleFonts.dmSans(color: const Color(0xFFCCCCCC), fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabCtrl,
                  labelStyle: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w500),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.red,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [Tab(text: 'Keşfet'), Tab(text: 'Sana Özel')],
                ),
              ],
            ),
          ),

          // ── Promosyon bandı — arama/tab ile içerik arasında ──────────────
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => IlanFormScreen(tip: IlanTip.istek),
              ),
            ),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEDE7F6), Color(0xFFF3EEFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  const Icon(Icons.campaign_outlined,
                      size: 16, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'İste\'de ilan vermek ücretsiz, hemen tıkla',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Color(0xFF7C3AED)),
                ],
              ),
            ),
          ),

          // İçerik
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onNotification,
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _KesfetTumEkran(),
                  SanaOzelScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Keşfet tam ekranı — vitrin1 + vitrin2 alt alta ───────────────────────────

class _KesfetTumEkran extends ConsumerWidget {
  const _KesfetTumEkran();

  Future<void> _yenile(WidgetRef ref) async {
    await Future.wait([
      ref.read(istekIlanlarProvider.notifier).yenile(),
      ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosMu = kesfetVitrin1TamamenBosMu(ref);
    final yukleniyor = ref.watch(istekIlanlarProvider).yukleniyor || ref.watch(tasiyiciIlanlarProvider).yukleniyor;

    if (bosMu) {
      return RefreshIndicator(
        color: AppColors.red,
        onRefresh: () => _yenile(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: yukleniyor
              ? const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2)),
                )
              : const KesfetBosEkran(),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _yenile(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: const [
            // 1. Hero banner
            KesfetHeroBanner(),
            // 2. Önerilen ilanlar (2 satır)
            KesfetOnerilenBolum(),
            // 3. Haftanın en çok görüntülenenleri + favorilenenleri
            KesfetGoruntulenenFavorilenenBolum(),
            // 4. En yeni ilanlar (2 satır, etiketsiz)
            KesfetEnYeniBolum(),
            // 5. Bugün eklenen + Yakında gelecek + Duty Free
            KesfetGuncelBolumler(),
            // 6. En eski ilanlar (1 satır)
            KesfetEnEskiBolum1Satir(),
            // 7. Trend ürünler + Popüler güzergahlar + Bu hafta nereden geliyorlar
            KesfetTrendGuzergahSehirGrubu(),
            // 8. En eski ilanlar (2 satır)
            KesfetEnEskiBolum2Satir(),
            // 9. İndirim & outlet mağazaları + Dünya trendleri
            KesfetIndirimDunyaGrubu(),
            // 10. Alışveriş rehberi (İstekçi Rehberi)
            // (KesfetRehberBedenIpucuBannerGrubu'nun yerine, araya kategori
            //  vitrini girebilsin diye burada manuel sıralıyoruz)
            _AlisverisRehberiVeKategoriVitrini(),
            // 12. Beden dönüştürücü + Taşıyıcı ipuçları + İlk ilanını ver banner'ı
            _BedenIpucuVeBanner(),
            // 13. Rastgele keşfet karması (2 satır)
            KesfetRastgeleKarmaBolum(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Alışveriş rehberi (İstekçi Rehberi) + onun hemen altına kategori vitrini.
class _AlisverisRehberiVeKategoriVitrini extends StatelessWidget {
  const _AlisverisRehberiVeKategoriVitrini();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlisverisRehberiBolum(),
        KategoriVitriniBolum(),
      ],
    );
  }
}

/// Beden dönüştürücü + Taşıyıcı ipuçları + İlk ilanını ver banner'ı.
class _BedenIpucuVeBanner extends StatelessWidget {
  const _BedenIpucuVeBanner();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BedenDonusturuculBolum(),
        TasiyiciIpuclariBolum(),
        IlkIlanBannerPublic(),
      ],
    );
  }
}