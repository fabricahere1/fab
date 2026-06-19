// lib/features/ilanlar/presentation/ilanlar_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../providers/grid_tercihi_notifier.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/cache/app_cache_manager.dart';
import 'package:iste_v3/features/arama/presentation/arama_screen.dart';
import 'package:iste_v3/features/arama/data/arama_service.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';
import '../../../shared/widgets/neden_iste_bar.dart';
import 'widgets/filtre_ekrani.dart';
import 'widgets/ilan_karti.dart';
import 'widgets/swipe_karti.dart';
import 'dart:async';
import 'package:iste_v3/features/ilanlar/presentation/favoriler_screen.dart';
import 'ilan_detay_screen.dart';



// ── Algolia filtre state ───────────────────────────────────────────────────────

class _AlgoliaState {
  final List<IlanModel> ilanlar;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final int mevcutSayfa;
  final Map<String, int> kategoriFacets;

  const _AlgoliaState({
    this.ilanlar        = const [],
    this.yukleniyor     = false,
    this.dahaFazlaVar   = true,
    this.mevcutSayfa    = 0,
    this.kategoriFacets = const {},
  });

  _AlgoliaState copyWith({
    List<IlanModel>? ilanlar,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    int? mevcutSayfa,
    Map<String, int>? kategoriFacets,
  }) => _AlgoliaState(
    ilanlar:        ilanlar        ?? this.ilanlar,
    yukleniyor:     yukleniyor     ?? this.yukleniyor,
    dahaFazlaVar:   dahaFazlaVar   ?? this.dahaFazlaVar,
    mevcutSayfa:    mevcutSayfa    ?? this.mevcutSayfa,
    kategoriFacets: kategoriFacets ?? this.kategoriFacets,
  );
}

// Algolia sonucunu IlanModel'e donustur
IlanModel _hittenIlan(Map<String, dynamic> hit) {
  final resimUrller = (hit['resimUrller'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList() ?? [];
  final kategoriYolu = (hit['kategoriYolu'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList() ?? [];
  final tarihMs = hit['olusturmaTarihi'] as int?;
  return IlanModel(
    id:              hit['objectID']     as String? ?? '',
    tip:             hit['tip']          as String? ?? '',
    nereden:         hit['nereden']      as String? ?? '',
    nereye:          hit['nereye']       as String? ?? '',
    urun:            hit['urun']         as String? ?? '',
    kategori:        hit['kategori']     as String? ?? 'diger',
    anaKategori:     hit['anaKategori']  as String? ?? '',
    kategoriYolu:    kategoriYolu,
    resimUrl:        hit['resimUrl']     as String? ?? '',
    resimUrller:     resimUrller,
    aktif:           hit['aktif']        as bool?   ?? true,
    durum:           hit['durum']        as String? ?? 'yayinda',
    kullaniciId:     hit['kullaniciId']  as String? ?? '',
    kullaniciAd:     hit['kullaniciAd']  as String? ?? '',
    olusturmaTarihi: tarihMs != null
        ? DateTime.fromMillisecondsSinceEpoch(tarihMs)
        : null,
  );
}

class IsteklerIcEkran extends ConsumerStatefulWidget {
  const IsteklerIcEkran({super.key});

  @override
  ConsumerState<IsteklerIcEkran> createState() => _IsteklerIcEkranState();
}

class _IsteklerIcEkranState extends ConsumerState<IsteklerIcEkran>
    with AutomaticKeepAliveClientMixin {
  final _scrollController   = ScrollController();
  final _aramaCtrl          = TextEditingController();
  final _kategoriScrollCtrl = ScrollController();

  SiralamaTipi _siralama             = SiralamaTipi.enYeni;
  List<String> _seciliKategoriYolu   = [];
  List<String> _seciliAltKeyler      = [];
  List<String> _seciliIstekSehirleri = [];
  String       _seciliUlkeSehir      = '';
  bool         _aramaGizli           = false;
  Timer?       _filtreTimer;

  _AlgoliaState _algoliaState = const _AlgoliaState();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _algoliaYukle(sifirla: true);
  }

  double _sonScrollPixel = 0;
  static const double _gosterThreshold = 80;

  void _onScroll() {
    final pos = _scrollController.position;
    final simdi = pos.pixels;

    // En tepedeyken her zaman header'ı göster
    if (simdi <= 0) {
      if (_aramaGizli) setState(() => _aramaGizli = false);
      ref.read(navBarGizliProvider.notifier).goster();
      _sonScrollPixel = 0;
      return;
    }

    if (pos.userScrollDirection == ScrollDirection.reverse) {
      _sonScrollPixel = simdi;
      if (!_aramaGizli) setState(() => _aramaGizli = true);
      ref.read(navBarGizliProvider.notifier).gizle();
    } else if (pos.userScrollDirection == ScrollDirection.forward) {
      if (simdi < _sonScrollPixel - _gosterThreshold) {
        _sonScrollPixel = simdi;
        if (_aramaGizli) setState(() => _aramaGizli = false);
        ref.read(navBarGizliProvider.notifier).goster();
      }
    }

    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _dahaFazlaYukle();
    }
  }

  @override
  void dispose() {
    _filtreTimer?.cancel();
    _scrollController.dispose();
    _aramaCtrl.dispose();
    _kategoriScrollCtrl.dispose();
    super.dispose();
  }

  // ── Algolia yukle ─────────────────────────────────────────────────────────

  Future<void> _algoliaYukle({bool sifirla = false}) async {
    if (_algoliaState.yukleniyor) return;
    if (!sifirla && !_algoliaState.dahaFazlaVar) return;

    final sayfa = sifirla ? 0 : _algoliaState.mevcutSayfa + 1;

    if (sifirla) {
      setState(() {
        _aramaGizli = false;
        _sonScrollPixel = 0;
      });
      ref.read(navBarGizliProvider.notifier).goster();
      // Scroll'u en başa al
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
    setState(() {
      _algoliaState = _algoliaState.copyWith(
        yukleniyor: true,
        ilanlar: sifirla ? [] : _algoliaState.ilanlar,
      );
    });

    try {
      final sonuc = await algoliaFiltrele(
        kategoriYolu:    _seciliKategoriYolu,
        seciliAltKeyler: _seciliAltKeyler,
        sehirler:        _seciliIstekSehirleri,
        ulkeSehir:       _seciliUlkeSehir,
        siralama:     _siralama.algoliaKey,
        ilanTipi:     'istek',
        sayfa:        sayfa,
        hitsPerPage:  24,
      );

      var yeniIlanlar = sonuc.ilanlar.map(_hittenIlan).toList();

      // enEski icin client-side siralama
      if (_siralama == SiralamaTipi.enEski) {
        yeniIlanlar.sort((a, b) =>
            (a.olusturmaTarihi ?? DateTime(0))
                .compareTo(b.olusturmaTarihi ?? DateTime(0)));
      }
      // enCokFavorilenen icin siralama
      if (_siralama == SiralamaTipi.enCokFavorilenen) {
        yeniIlanlar.sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi));
      }
      // onerilen icin siralama
      if (_siralama == SiralamaTipi.onerilen) {
        yeniIlanlar.sort((a, b) {
          final aOnayliMi = a.kullaniciPuan >= 4.0;
          final bOnayliMi = b.kullaniciPuan >= 4.0;
          if (aOnayliMi && !bOnayliMi) return -1;
          if (!aOnayliMi && bOnayliMi) return 1;
          return b.kullaniciPuan.compareTo(a.kullaniciPuan);
        });
      }

      final mevcutIdler = _algoliaState.ilanlar.map((i) => i.id).toSet();
      final benzersizYeni = yeniIlanlar
          .where((i) => !mevcutIdler.contains(i.id))
          .toList();

      setState(() {
        _algoliaState = _AlgoliaState(
          ilanlar:        [..._algoliaState.ilanlar, ...benzersizYeni],
          yukleniyor:     false,
          dahaFazlaVar:   sayfa < sonuc.toplamSayfa - 1,
          mevcutSayfa:    sayfa,
          kategoriFacets: sifirla ? sonuc.kategoriFacets : _algoliaState.kategoriFacets,
        );
      });
    } catch (_) {
      setState(() {
        _algoliaState = _algoliaState.copyWith(yukleniyor: false);
      });
    }
  }

  void _dahaFazlaYukle() {
    if (!_algoliaState.yukleniyor && _algoliaState.dahaFazlaVar) {
      _algoliaYukle();
    }
  }

  void _filtreUygula(VoidCallback degistir) {
    _filtreTimer?.cancel();
    setState(() => degistir());
    _algoliaYukle(sifirla: true);
  }

  bool get _filtrAktif =>
      _seciliKategoriYolu.isNotEmpty ||
      _seciliAltKeyler.isNotEmpty ||
      _seciliIstekSehirleri.isNotEmpty ||
      _seciliUlkeSehir.isNotEmpty;



  String? get _seciliAnaKey =>
      _seciliKategoriYolu.isNotEmpty ? _seciliKategoriYolu.first : null;

  void _filtreAc() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, ___, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0), end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: Material(
            color: Colors.transparent,
            child: FiltreEkrani(
              seciliKategoriYolu:   _seciliKategoriYolu,
              seciliAltKeyler:      _seciliAltKeyler,
              seciliSiralama:       _siralama,
              seciliIstekSehirleri: _seciliIstekSehirleri,
              kategoriFacets:       _algoliaState.kategoriFacets,
              onUygula: (secim) {
                _filtreUygula(() {
                  _seciliKategoriYolu   = secim.kategoriYolu;
                  _seciliAltKeyler      = secim.seciliAltKeyler;
                  _siralama             = secim.siralama;
                  _seciliIstekSehirleri = secim.istekSehirleri;
                  _seciliUlkeSehir      = secim.ulkeSehir.isNotEmpty
                      ? secim.ulkeSehir[0].toUpperCase() + secim.ulkeSehir.substring(1)
                      : '';
                });
              },
              onTemizle: () {
                _filtreUygula(() {
                  _seciliKategoriYolu   = [];
                  _seciliAltKeyler      = [];
                  _siralama             = SiralamaTipi.enYeni;
                  _seciliIstekSehirleri = [];
                  _seciliUlkeSehir      = '';
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _anaKategoriSec(String anaKey) {
    _filtreUygula(() {
      if (_seciliAnaKey == anaKey) {
        _seciliKategoriYolu = [];
        _seciliAltKeyler    = [];
      } else {
        _seciliKategoriYolu = [anaKey];
        _seciliAltKeyler    = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen<List<String>>(breadcrumbKategoriFiltresiProvider, (prev, next) {
      if (next.isNotEmpty) {
        _filtreUygula(() => _seciliKategoriYolu = List<String>.from(next));
        ref.read(breadcrumbKategoriFiltresiProvider.notifier).temizle();
      }
    });

    final mod     = ref.watch(gridTercihiProvider);
    final ilanlar = _algoliaState.ilanlar;
    final statusH = MediaQuery.of(context).padding.top;
    final isSwipe = mod == GoruntulemeModeli.swipe;
    final scrW    = MediaQuery.of(context).size.width;
    final uc3Extent = (scrW - 36) / 3 + 105;

    Widget ilanWidget;
    if (isSwipe) {
      ilanWidget = SwipeGorunumu(
        ilanlar: ilanlar,
        onDahaFazla: _dahaFazlaYukle,
      );
    } else if (_algoliaState.yukleniyor && ilanlar.isEmpty) {
      ilanWidget = SliverToBoxAdapter(
          child: ShimmerGrid(kolonSayisi: mod.kolonSayisi));
    } else if (ilanlar.isEmpty) {
      ilanWidget = SliverFillRemaining(
        hasScrollBody: false,
        child: _filtrAktif
            ? FiltreBosBekran(onTemizle: () {
                _filtreUygula(() {
                  _seciliKategoriYolu   = [];
                  _seciliAltKeyler      = [];
                  _seciliIstekSehirleri = [];
                  _seciliUlkeSehir      = '';
                });
              })
            : IlanBosEkran(onYenile: () => _algoliaYukle(sifirla: true)),
      );
    } else {
      if (mod.kolonSayisi == 3) {
        ilanWidget = SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: uc3Extent,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => RepaintBoundary(
              key: ValueKey(ilanlar[index].id),
              child: IlanKarti(
                ilan: ilanlar[index],
                resimYukseklikleri: kResimYukseklikleri,
                kolonSayisi: mod.kolonSayisi,
              ),
            ),
            childCount: ilanlar.length,
          ),
        );
      } else {
        ilanWidget = SliverMasonryGrid.count(
          crossAxisCount: mod.kolonSayisi,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childCount: ilanlar.length,
          itemBuilder: (context, index) => RepaintBoundary(
            key: ValueKey(ilanlar[index].id),
            child: IlanKarti(
              ilan: ilanlar[index],
              resimYukseklikleri: kResimYukseklikleri,
              kolonSayisi: mod.kolonSayisi,
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Column(
            children: [
              Container(height: statusH, color: Colors.white),

              _IsteklerHeader(
                aramaCtrl: _aramaCtrl,
                aramaMetni: '',
                aramaGizli: _aramaGizli && !isSwipe,
                filtrAktif: _filtrAktif,
                seciliAnaKey: _seciliAnaKey,
                seciliUlkeSehir: _seciliUlkeSehir,
                onUlkeSehirTemizle: () => _filtreUygula(() {
                  _seciliUlkeSehir = '';
                }),
                onAramaChanged: (_) {},
                onAramaSifirla: () {},
                onFiltreAc: _filtreAc,
                onKategoriSec: _anaKategoriSec,
                onFiltreSifirla: () => _filtreUygula(() {
                  _seciliKategoriYolu   = [];
                  _seciliAltKeyler      = [];
                  _seciliIstekSehirleri = [];
                  _seciliUlkeSehir      = '';
                }),

                kategoriScrollCtrl: _kategoriScrollCtrl,
              ),

              Container(height: 0.5, color: AppColors.divider),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.red,
                  onRefresh: () => _algoliaYukle(sifirla: true),
                  child: isSwipe
                      ? ilanWidget
                      : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/images/banner_ilk_ilan.png',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),
                            const SliverToBoxAdapter(
                              child: _Son24SaatBolumu(),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.all(10),
                              sliver: ilanWidget,
                            ),
                            // Yukleniyor gostergesi
                            if (_algoliaState.yukleniyor && ilanlar.isNotEmpty)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),

          Positioned(
            right: 0, top: 0, bottom: 0,
            child: Center(
              child: _DikeTabBar(
                mod: mod,
                isSwipe: isSwipe,
                onModSec: (m) =>
                    ref.read(gridTercihiProvider.notifier).modSec(m),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dikey mod tab bar ─────────────────────────────────────────────────────────

class _DikeTabBar extends StatelessWidget {
  final GoruntulemeModeli mod;
  final bool isSwipe;
  final ValueChanged<GoruntulemeModeli> onModSec;

  const _DikeTabBar({
    required this.mod,
    required this.isSwipe,
    required this.onModSec,
  });

  @override
  Widget build(BuildContext context) {
    final modlar = [
      (GoruntulemeModeli.iki,   Icons.grid_view_rounded),
      (GoruntulemeModeli.uc,    Icons.view_module_rounded),
      (GoruntulemeModeli.swipe, Icons.swipe_left_alt_rounded),
    ];

    final bgRenk = isSwipe
        ? const Color(0x73000000)
        : const Color(0xFFEEEEEE);

    final borderRenk = isSwipe
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFDDDDDD);

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
      child: Container(
        width: 36,
        decoration: BoxDecoration(
          color: bgRenk,
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: modlar.map((entry) {
            final (m, ikon) = entry;
            final aktif  = mod == m;
            final isLast = m == GoruntulemeModeli.swipe;

            final ikonRenk = aktif
                ? Colors.white
                : isSwipe
                    ? Colors.white.withValues(alpha: 0.55)
                    : const Color(0xFF888888);
            final itemBg = aktif
                ? AppColors.red.withValues(alpha: isSwipe ? 0.8 : 1.0)
                : Colors.transparent;

            return GestureDetector(
              onTap: () => onModSec(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36, height: 40,
                decoration: BoxDecoration(
                  color: itemBg,
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: borderRenk, width: 0.5)),
                ),
                child: Icon(ikon, size: 16, color: ikonRenk),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _IsteklerHeader extends StatelessWidget {
  final TextEditingController aramaCtrl;
  final String aramaMetni;
  final bool aramaGizli;
  final bool filtrAktif;
  final String? seciliAnaKey;
  final String seciliUlkeSehir;
  final VoidCallback onUlkeSehirTemizle;
  final ScrollController kategoriScrollCtrl;
  final ValueChanged<String> onAramaChanged;
  final VoidCallback onAramaSifirla;
  final VoidCallback onFiltreAc;
  final ValueChanged<String> onKategoriSec;
  final VoidCallback onFiltreSifirla;

  const _IsteklerHeader({
    required this.aramaCtrl,
    required this.aramaMetni,
    required this.aramaGizli,
    required this.filtrAktif,
    required this.seciliAnaKey,
    required this.seciliUlkeSehir,
    required this.onUlkeSehirTemizle,
    required this.kategoriScrollCtrl,
    required this.onAramaChanged,
    required this.onAramaSifirla,
    required this.onFiltreAc,
    required this.onKategoriSec,
    required this.onFiltreSifirla,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              heightFactor: aramaGizli ? 0.0 : 1.0,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 4),
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: 38),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const FavorilerScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Symbols.favorite,
                          color: AppColors.textPrimary,
                          size: 22,
                          weight: 400,
                          fill: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const BildirimCaniWidget(),
                  ],
                ),
              ),
            ),
          ),

          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              heightFactor: aramaGizli ? 0.0 : 1.0,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) => const AramaScreen(),
                            transitionsBuilder: (_, anim, _, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 200),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.all(0.5),
                          child: Container(
                            height: 43,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(21.5),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Icon(Icons.search_rounded,
                                    size: 18,
                                    color: Color(0xFFCCCCCC)),
                                const SizedBox(width: 8),
                                Text(
                                  'Ne gelsin istersin ?',
                                  style: GoogleFonts.dmSans(
                                      color: const Color(0xFFCCCCCC),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onFiltreAc,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: filtrAktif
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.tune_rounded,
                                color: Colors.white, size: 19),
                            if (filtrAktif)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  width: 7, height: 7,
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(
            height: 36,
            child: ListView.builder(
              controller: kategoriScrollCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 48, 4),
              itemCount: kKategoriAgaci.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  final secili = seciliAnaKey == null && seciliUlkeSehir.isEmpty;
                  return GestureDetector(
                    onTap: () { if (!secili) onFiltreSifirla(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: secili
                            ? const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: secili ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFDDDDDD), width: 1),
                        boxShadow: secili
                            ? [BoxShadow(
                                color: const Color(0xFFE53935)
                                    .withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text('Tumü',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secili
                                ? Colors.white
                                : AppColors.textSecondary,
                          )),
                    ),
                  );
                }
                final kat    = kKategoriAgaci[i - 1];
                final secili = seciliAnaKey == kat.key;
                return GestureDetector(
                  onTap: () => onKategoriSec(kat.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: secili
                          ? const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: secili ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: secili
                            ? Colors.transparent
                            : const Color(0xFFEEEEEE),
                        width: 1,
                      ),
                      boxShadow: secili
                          ? [BoxShadow(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _kategoriIkon(kat.key),
                          size: 15,
                          color: secili ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(kat.ad,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: secili
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Türkiye dışı seçim badge
          if (seciliUlkeSehir.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.public_outlined,
                          size: 12, color: Color(0xFF1565C0)),
                      const SizedBox(width: 4),
                      Text(
                        seciliUlkeSehir,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF1565C0),
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onUlkeSehirTemizle,
                        child: Text(
                          'Temizle',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF1565C0)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          const NedenIsteBar(),
        ],
      ),
    );
  }
}

// ── Son 24 Saat Bolumu ────────────────────────────────────────────────────────

class _Son24SaatBolumu extends ConsumerWidget {
  const _Son24SaatBolumu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(haftaninEnleriProvider);

    return async.when(
      loading: () => _Son24SaatSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (ilanlar) {
        if (ilanlar.isEmpty) return const SizedBox.shrink();

        const cardW = 140.0;
        const cardH = 200.0;

        return Stack(
          children: [
            Positioned.fill(
              bottom: 10, // 10px kısa
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(top: -8, right: 20,
              child: Icon(Icons.flight_takeoff_rounded, size: 80, color: const Color(0xFFFF9800).withValues(alpha: 0.45))),
            Positioned(top: 25, right: 115,
              child: Icon(Icons.shopping_bag_outlined, size: 52, color: const Color(0xFFFF9800).withValues(alpha: 0.40))),
            Positioned(bottom: 8, right: 55,
              child: Icon(Icons.local_shipping_outlined, size: 58, color: const Color(0xFFFF9800).withValues(alpha: 0.38))),
            Positioned(top: 10, left: 25,
              child: Icon(Icons.location_on_outlined, size: 44, color: const Color(0xFFFF9800).withValues(alpha: 0.40))),
            Positioned(bottom: 6, left: 75,
              child: Icon(Icons.star_outline_rounded, size: 40, color: const Color(0xFFFF9800).withValues(alpha: 0.42))),
            Positioned(top: 45, left: 145,
              child: Icon(Icons.card_travel_outlined, size: 36, color: const Color(0xFFFF9800).withValues(alpha: 0.38))),
            Positioned(top: 5, right: 195,
              child: Icon(Icons.redeem_outlined, size: 34, color: const Color(0xFFFF9800).withValues(alpha: 0.35))),
            Positioned(bottom: 12, right: 190,
              child: Icon(Icons.airplane_ticket_outlined, size: 38, color: const Color(0xFFFF9800).withValues(alpha: 0.37))),
            Positioned(top: 60, right: 20,
              child: Icon(Icons.card_giftcard_outlined, size: 30, color: const Color(0xFFFF9800).withValues(alpha: 0.33))),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Haftanın Öne Çıkanları",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => const _HaftaninEnleriEkrani(),
                            ),
                          ),
                          child: Text(
                            'Tümünü Gör →',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: cardH,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: ilanlar.length,
                      itemBuilder: (context, i) {
                        final ilan = ilanlar[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => IlanDetayScreen(ilanId: ilan.id),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: cardW,
                                height: cardH,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: SizedBox(
                                        width: cardW,
                                        height: 115,
                                        child: ilan.gridResim.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: ilan.gridResim,
                                                cacheManager: AppCacheManager.instance,
                                                width: cardW,
                                                height: 115,
                                                fit: BoxFit.cover,
                                                errorWidget: (ctx, url, err) =>
                                                    _PlaceholderImage(w: cardW, h: 115),
                                              )
                                            : _PlaceholderImage(w: cardW, h: 115),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                                        child: Text(
                                          ilan.urun.isNotEmpty ? ilan.urun : ilan.nereden,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                                      child: Text(
                                        '${ilan.nereden} -> ${ilan.nereye}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2400),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF2400)
                                            .withValues(alpha: 0.45),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'YENI',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Son24SaatSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(top: 18, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (ctx, i) => Container(
                width: 130,
                height: 170,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final double w;
  final double h;
  const _PlaceholderImage({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      color: const Color(0xFFEEEEEE),
      child: const Icon(Icons.image_outlined,
          size: 28, color: Color(0xFFCCCCCC)),
    );
  }
}

// ── Haftanın En'leri Tam Ekran ────────────────────────────────────────────────

class _HaftaninEnleriEkrani extends ConsumerWidget {
  const _HaftaninEnleriEkrani();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(haftaninEnleriProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          "Haftanın En İyileri",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.red)),
        error: (_, _) => const Center(child: Text('Yüklenemedi')),
        data: (ilanlar) => MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          padding: const EdgeInsets.all(10),
          itemCount: ilanlar.length,
          itemBuilder: (context, i) => IlanKarti(
            ilan: ilanlar[i],
            resimYukseklikleri: kResimYukseklikleri,
          ),
        ),
      ),
    );
  }
}

// Kategori ikon mapping — Material Symbols w100
IconData _kategoriIkon(String key) {
  switch (key) {
    case 'kadin':       return Symbols.face_3;
    case 'erkek':       return Symbols.face;
    case 'cocuk':       return Symbols.face_retouching_natural;
    case 'ev':          return Symbols.cottage;
    case 'elektronik':  return Symbols.headphones;
    case 'supplement':  return Symbols.vaccines;
    default:            return Symbols.package_2;
  }
}