// lib/features/home/presentation/kesfet_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/arama/presentation/arama_screen.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/ilanlar/presentation/ilan_form_screen.dart';
import 'package:iste_v3/features/ilanlar/presentation/widgets/ilan_karti.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import '../providers/kesfet_akis_provider.dart';
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
      ref.read(kesfetAkisProvider('istek').notifier).yenile(),
      ref.read(kesfetAkisProvider('tasiyici').notifier).yenile(),
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

    final istekAkis = ref.watch(kesfetAkisProvider('istek'));
    final tasiyiciAkis = ref.watch(kesfetAkisProvider('tasiyici'));

    final birlesikListe = [...istekAkis.ilanlar, ...tasiyiciAkis.ilanlar]
      ..sort((a, b) {
        final ta = a.olusturmaTarihi;
        final tb = b.olusturmaTarihi;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });

    // Bir akış ilk sayfasını henüz yüklememişse (dahaFazlaVar && sonTarih == null)
    // frontier'ı tanımsızdır — grid, iki akış da ilk sayfasını getirene kadar boş kalır.
    // (Boş ilk sayfa bitti=true döndürdüğü için burada takılı kalmaz.)
    final istekHazir = !istekAkis.dahaFazlaVar || istekAkis.sonTarih != null;
    final tasiyiciHazir = !tasiyiciAkis.dahaFazlaVar || tasiyiciAkis.sonTarih != null;

    // Frontier kesimi — iki akış farklı derinliklere sayfalanabilir; kesim olmadan
    // sonraki sayfa listenin ORTASINA eklenir (kullanıcı kaydırırken kartlar yer
    // değiştirir). Görüntü yalnızca her iki akışın da "buraya kadar eksiksizim"
    // dediği en geç tarihe kadar gösterilir, gerisi tamponda bekler.
    final f1 = istekAkis.dahaFazlaVar ? istekAkis.sonTarih : null;
    final f2 = tasiyiciAkis.dahaFazlaVar ? tasiyiciAkis.sonTarih : null;
    final kesim = (f1 != null && f2 != null)
        ? (f1.isAfter(f2) ? f1 : f2)
        : (f1 ?? f2);

    final gorunurListe = (!istekHazir || !tasiyiciHazir)
        ? const <IlanModel>[]
        : (kesim == null
            ? birlesikListe
            : birlesikListe
                .where((i) => i.olusturmaTarihi != null && !i.olusturmaTarihi!.isBefore(kesim))
                .toList());

    final gridYukleniyor = istekAkis.yukleniyor || tasiyiciAkis.yukleniyor;
    final gridDahaFazlaVar = istekAkis.dahaFazlaVar || tasiyiciAkis.dahaFazlaVar;

    return RefreshIndicator(
      onRefresh: () => _yenile(ref),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) {
            if (istekAkis.dahaFazlaVar && !istekAkis.yukleniyor) {
              ref.read(kesfetAkisProvider('istek').notifier).dahaFazlaYukle();
            }
            if (tasiyiciAkis.dahaFazlaVar && !tasiyiciAkis.yukleniyor) {
              ref.read(kesfetAkisProvider('tasiyici').notifier).dahaFazlaYukle();
            }
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Hero banner
            const SliverToBoxAdapter(child: KesfetHeroBanner()),
            // 2. Önerilen ilanlar (2 satır)
            const SliverToBoxAdapter(child: KesfetOnerilenBolum()),
            // 3. Haftanın en çok görüntülenenleri + favorilenenleri
            const SliverToBoxAdapter(child: KesfetGoruntulenenFavorilenenBolum()),
            // 4. En yeni ilanlar (2 satır, etiketsiz)
            const SliverToBoxAdapter(child: KesfetEnYeniBolum()),
            // 5. Bugün eklenen + Yakında gelecek + Duty Free
            const SliverToBoxAdapter(child: KesfetGuncelBolumler()),
            // 6. En eski ilanlar (1 satır)
            const SliverToBoxAdapter(child: KesfetEnEskiBolum1Satir()),
            // 7. Trend ürünler + Popüler güzergahlar + Bu hafta nereden geliyorlar
            const SliverToBoxAdapter(child: KesfetTrendGuzergahSehirGrubu()),
            // 8. En eski ilanlar (2 satır)
            const SliverToBoxAdapter(child: KesfetEnEskiBolum2Satir()),
            // 9. İndirim & outlet mağazaları + Dünya trendleri
            const SliverToBoxAdapter(child: KesfetIndirimDunyaGrubu()),
            // 10. Alışveriş rehberi (İstekçi Rehberi)
            // (KesfetRehberBedenIpucuBannerGrubu'nun yerine, araya kategori
            //  vitrini girebilsin diye burada manuel sıralıyoruz)
            const SliverToBoxAdapter(child: _AlisverisRehberiVeKategoriVitrini()),
            // 12. Beden dönüştürücü + Taşıyıcı ipuçları + İlk ilanını ver banner'ı
            const SliverToBoxAdapter(child: _BedenIpucuVeBanner()),
            // 13. Rastgele keşfet karması (2 satır)
            const SliverToBoxAdapter(child: KesfetRastgeleKarmaBolum()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverPadding(
              padding: const EdgeInsets.all(10),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childCount: gorunurListe.length,
                itemBuilder: (context, i) => RepaintBoundary(
                  key: ValueKey(gorunurListe[i].id),
                  child: IlanKarti(
                    ilan: gorunurListe[i],
                    resimYukseklikleri: kResimYukseklikleri,
                    kolonSayisi: 2,
                  ),
                ),
              ),
            ),
            if (gridDahaFazlaVar || gridYukleniyor)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
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