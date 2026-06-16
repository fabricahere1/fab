// lib/features/ilanlar/presentation/ilanlar_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
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

enum SiralamaTipi { enYeni, enEski, enCokFavorilenen, onayliIstekci }

extension SiralamaTipiX on SiralamaTipi {
  String get label {
    switch (this) {
      case SiralamaTipi.enYeni:           return 'En yeni';
      case SiralamaTipi.enEski:           return 'En eski';
      case SiralamaTipi.enCokFavorilenen: return 'En cok favorilenen';
      case SiralamaTipi.onayliIstekci:    return 'Onayli istekci';
    }
  }

  String get algoliaKey {
    switch (this) {
      case SiralamaTipi.enYeni:           return 'enYeni';
      case SiralamaTipi.enEski:           return 'enEski';
      case SiralamaTipi.enCokFavorilenen: return 'enCokFavorilenen';
      case SiralamaTipi.onayliIstekci:    return 'enYeni';
    }
  }
}

// ── Algolia filtre state ───────────────────────────────────────────────────────

class _AlgoliaState {
  final List<IlanModel> ilanlar;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final int mevcutSayfa;

  const _AlgoliaState({
    this.ilanlar      = const [],
    this.yukleniyor   = false,
    this.dahaFazlaVar = true,
    this.mevcutSayfa  = 0,
  });

  _AlgoliaState copyWith({
    List<IlanModel>? ilanlar,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    int? mevcutSayfa,
  }) => _AlgoliaState(
    ilanlar:      ilanlar      ?? this.ilanlar,
    yukleniyor:   yukleniyor   ?? this.yukleniyor,
    dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
    mevcutSayfa:  mevcutSayfa  ?? this.mevcutSayfa,
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
      // onayliIstekci icin siralama
      if (_siralama == SiralamaTipi.onayliIstekci) {
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
          ilanlar:      [..._algoliaState.ilanlar, ...benzersizYeni],
          yukleniyor:   false,
          dahaFazlaVar: sayfa < sonuc.toplamSayfa - 1,
          mevcutSayfa:  sayfa,
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
      _seciliIstekSehirleri.isNotEmpty;



  String? get _seciliAnaKey =>
      _seciliKategoriYolu.isNotEmpty ? _seciliKategoriYolu.first : null;

  void _filtreAc() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
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
              onUygula: (secim) {
                _filtreUygula(() {
                  _seciliKategoriYolu   = secim.kategoriYolu;
                  _seciliAltKeyler      = secim.seciliAltKeyler;
                  _siralama             = secim.siralama;
                  _seciliIstekSehirleri = secim.istekSehirleri;
                });
              },
              onTemizle: () {
                _filtreUygula(() {
                  _seciliKategoriYolu   = [];
                  _seciliAltKeyler      = [];
                  _siralama             = SiralamaTipi.enYeni;
                  _seciliIstekSehirleri = [];
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
      ilanWidget = SliverToBoxAdapter(
        child: _filtrAktif
            ? FiltreBosBekran(onTemizle: () => _filtreUygula(() {
                _seciliKategoriYolu   = [];
                _seciliIstekSehirleri = [];
              }))
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
                onAramaChanged: (_) {},
                onAramaSifirla: () {},
                onFiltreAc: _filtreAc,
                onKategoriSec: _anaKategoriSec,
                onFiltreSifirla: () => _filtreUygula(() {
                  _seciliKategoriYolu = [];
                  _seciliAltKeyler    = [];
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
                    Image.asset('assets/images/logo.png', height: 48),
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
                          Icons.favorite_border,
                          color: AppColors.textPrimary,
                          size: 22,
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
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: const Color(0xFFEEEEEE), width: 1),
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
                  final secili = seciliAnaKey == null;
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
                    child: Text('${kat.emoji} ${kat.ad}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secili
                              ? Colors.white
                              : AppColors.textPrimary,
                        )),
                  ),
                );
              },
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
    final async = ref.watch(son24SaatIlanlarProvider);

    return async.when(
      loading: () => _Son24SaatSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (ilanlar) {
        if (ilanlar.isEmpty) return const SizedBox.shrink();

        const cardW = 130.0;
        const cardH = 170.0;

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFFBBDEFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(top: 10, bottom: 18),
              child: const SizedBox(height: 210, width: double.infinity),
            ),
            Positioned(top: -8, right: 20,
              child: Icon(Icons.flight_takeoff_rounded, size: 72, color: const Color(0xFFFF9800).withValues(alpha: 0.18))),
            Positioned(top: 30, right: 110,
              child: Icon(Icons.shopping_bag_outlined, size: 44, color: const Color(0xFFFF9800).withValues(alpha: 0.15))),
            Positioned(bottom: 10, right: 60,
              child: Icon(Icons.local_shipping_outlined, size: 52, color: const Color(0xFFFF9800).withValues(alpha: 0.14))),
            Positioned(top: 15, left: 30,
              child: Icon(Icons.location_on_outlined, size: 38, color: const Color(0xFFFF9800).withValues(alpha: 0.13))),
            Positioned(bottom: 8, left: 80,
              child: Icon(Icons.star_outline_rounded, size: 34, color: const Color(0xFFFF9800).withValues(alpha: 0.16))),
            Positioned(top: 50, left: 150,
              child: Icon(Icons.card_travel_outlined, size: 30, color: const Color(0xFFFF9800).withValues(alpha: 0.12))),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Son 24 saatte eklendi',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
                                    SizedBox(
                                      width: cardW,
                                      height: 100,
                                      child: ilan.gridResim.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: ilan.gridResim,
                                              cacheManager: AppCacheManager.instance,
                                              width: cardW,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorWidget: (ctx, url, err) =>
                                                  _PlaceholderImage(w: cardW, h: 100),
                                            )
                                          : _PlaceholderImage(w: cardW, h: 100),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                                        child: Text(
                                          ilan.urun.isNotEmpty ? ilan.urun : ilan.nereden,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
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
          colors: [Color(0xFF90CAF9), Color(0xFFBBDEFB)],
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