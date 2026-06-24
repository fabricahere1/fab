// lib/features/ilanlar/presentation/gelenler_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import 'package:iste_v3/features/arama/presentation/arama_screen.dart';
import 'package:iste_v3/features/arama/data/arama_service.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';
import '../../../shared/widgets/neden_iste_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:iste_v3/features/ilanlar/presentation/favoriler_screen.dart';
import 'widgets/ilan_karti.dart';
import 'widgets/gelenler_filtre_ekrani.dart';





// ── Algolia state ─────────────────────────────────────────────────────────────

class _GAlgoliaState {
  final List<IlanModel> ilanlar;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final int mevcutSayfa;
  final Map<String, int> kategoriFacets;

  const _GAlgoliaState({
    this.ilanlar        = const [],
    this.yukleniyor     = false,
    this.dahaFazlaVar   = true,
    this.mevcutSayfa    = 0,
    this.kategoriFacets = const {},
  });

  _GAlgoliaState copyWith({
    List<IlanModel>? ilanlar,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    int? mevcutSayfa,
    Map<String, int>? kategoriFacets,
  }) => _GAlgoliaState(
    ilanlar:        ilanlar        ?? this.ilanlar,
    yukleniyor:     yukleniyor     ?? this.yukleniyor,
    dahaFazlaVar:   dahaFazlaVar   ?? this.dahaFazlaVar,
    mevcutSayfa:    mevcutSayfa    ?? this.mevcutSayfa,
    kategoriFacets: kategoriFacets ?? this.kategoriFacets,
  );
}

IlanModel _gHittenIlan(Map<String, dynamic> hit) {
  final resimUrller = (hit['resimUrller'] as List<dynamic>?)
      ?.map((e) => e as String).toList() ?? [];
  final kategoriYolu = (hit['kategoriYolu'] as List<dynamic>?)
      ?.map((e) => e as String).toList() ?? [];
  final tarihMs = hit['olusturmaTarihi'] as int?;
  return IlanModel(
    id:              hit['objectID']    as String? ?? '',
    tip:             hit['tip']         as String? ?? '',
    nereden:         hit['nereden']     as String? ?? '',
    nereye:          hit['nereye']      as String? ?? '',
    urun:            hit['urun']        as String? ?? '',
    kategori:        hit['kategori']    as String? ?? 'diger',
    anaKategori:     hit['anaKategori'] as String? ?? '',
    kategoriYolu:    kategoriYolu,
    resimUrl:        hit['resimUrl']    as String? ?? '',
    resimUrller:     resimUrller,
    aktif:           hit['aktif']       as bool?   ?? true,
    durum:           hit['durum']       as String? ?? 'yayinda',
    kullaniciId:     hit['kullaniciId'] as String? ?? '',
    kullaniciAd:     hit['kullaniciAd'] as String? ?? '',
    olusturmaTarihi: tarihMs != null
        ? DateTime.fromMillisecondsSinceEpoch(tarihMs)
        : null,
  );
}

class GelenlerScreen extends ConsumerStatefulWidget {
  final bool embedded;
  final List<String> initialKategoriYolu;
  final String initialNereden;

  const GelenlerScreen({
    super.key,
    this.embedded = false,
    this.initialKategoriYolu = const [],
    this.initialNereden = '',
  });

  @override
  ConsumerState<GelenlerScreen> createState() => _GelenlerScreenState();
}

class _GelenlerScreenState extends ConsumerState<GelenlerScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController   = ScrollController();
  final _kategoriScrollCtrl = ScrollController();

  List<String>        _seciliKategoriYolu = [];
  List<String>        _seciliAltKeyler    = [];
  bool                _aramaGizli        = false;
  app_constants.SiralamaTipi    _siralama          = app_constants.SiralamaTipi.enYeni;
  List<String>        _seciliSehirler    = [];
  String              _nerdenUlkeSehir   = '';  // nereden filtresi (şehirden geliyor)
  _GAlgoliaState      _algoliaState      = const _GAlgoliaState();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialKategoriYolu.isNotEmpty) {
      _seciliKategoriYolu = List<String>.from(widget.initialKategoriYolu);
    }
    if (widget.initialNereden.isNotEmpty) {
      _nerdenUlkeSehir = widget.initialNereden;
    }
    _algoliaYukle(sifirla: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _kategoriScrollCtrl.dispose();
    super.dispose();
  }

  // ── Algolia ────────────────────────────────────────────────────────────────

  Future<void> _algoliaYukle({bool sifirla = false}) async {
    if (_algoliaState.yukleniyor) return;
    if (!sifirla && !_algoliaState.dahaFazlaVar) return;

    final sayfa = sifirla ? 0 : _algoliaState.mevcutSayfa + 1;

    if (sifirla) {
      setState(() { _aramaGizli = false; });
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
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
        sehirler:        _seciliSehirler,
        ulkeSehir:       _seciliUlkeSehir,
        nerdenUlkeSehir: _nerdenUlkeSehir,
        siralama:        _siralama.algoliaKey,
        ilanTipi:        'tasiyici',
        sayfa:           sayfa,
        hitsPerPage:     24,
      );

      final yeniIlanlar = sonuc.ilanlar.map(_gHittenIlan).toList();
      final mevcutIdler = _algoliaState.ilanlar.map((i) => i.id).toSet();
      final benzersiz   = yeniIlanlar.where((i) => !mevcutIdler.contains(i.id)).toList();

      setState(() {
        _algoliaState = _GAlgoliaState(
          ilanlar:        [..._algoliaState.ilanlar, ...benzersiz],
          yukleniyor:     false,
          dahaFazlaVar:   sayfa < sonuc.toplamSayfa - 1,
          mevcutSayfa:    sayfa,
          kategoriFacets: (sifirla && _seciliKategoriYolu.isEmpty && _seciliAltKeyler.isEmpty)
              ? sonuc.kategoriFacets
              : _algoliaState.kategoriFacets,
        );
      });
    } catch (_) {
      setState(() => _algoliaState = _algoliaState.copyWith(yukleniyor: false));
    }
  }

  void _filtreUygula(VoidCallback degistir) {
    setState(() => degistir());
    _algoliaYukle(sifirla: true);
  }

  double _sonScrollPixel = 0;
  static const double _gosterThreshold = 80;

  void _onScroll() {
    final pos = _scrollController.position;
    final simdi = pos.pixels;

    if (simdi <= 0) {
      if (_aramaGizli) setState(() => _aramaGizli = false);
      ref.read(navBarGizliProvider.notifier).goster();
      _sonScrollPixel = 0;
      return;
    }

    if (pos.userScrollDirection == ScrollDirection.reverse) {
      if (!_aramaGizli) setState(() => _aramaGizli = true);
      _sonScrollPixel = simdi;
      ref.read(navBarGizliProvider.notifier).gizle();
    } else if (pos.userScrollDirection == ScrollDirection.forward) {
      if (simdi < _sonScrollPixel - _gosterThreshold) {
        _sonScrollPixel = simdi;
        if (_aramaGizli) setState(() => _aramaGizli = false);
        ref.read(navBarGizliProvider.notifier).goster();
      }
    }

    if (pos.pixels >= pos.maxScrollExtent - 200) {
      if (!_algoliaState.yukleniyor && _algoliaState.dahaFazlaVar) {
        _algoliaYukle();
      }
    }
  }

  bool get _filtrAktif => _seciliSehirler.isNotEmpty || _seciliKategoriYolu.isNotEmpty || _seciliAltKeyler.isNotEmpty || _siralama != app_constants.SiralamaTipi.enYeni || _seciliUlkeSehir.isNotEmpty;

  String _seciliUlkeSehir = '';

  String? get _seciliAnaKey =>
      _seciliKategoriYolu.isNotEmpty ? _seciliKategoriYolu.first : null;


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



  void _filtreAc() {
    gelenlerFiltreAc(
      context: context,
      seciliKategoriYolu: _seciliKategoriYolu,
      seciliAltKeyler: _seciliAltKeyler,
      seciliSiralama: _siralama,
      seciliSehirler: _seciliSehirler,
      seciliUlkeSehir: _seciliUlkeSehir,
      kategoriFacets: _algoliaState.kategoriFacets,
      onUygula: (secim) {
        _filtreUygula(() {
          _seciliKategoriYolu = secim.kategoriYolu;
          _seciliAltKeyler    = secim.altKeyler;
          _siralama           = secim.siralama;
          _seciliSehirler     = secim.sehirler;
          _seciliUlkeSehir    = secim.ulkeSehir;
        });
      },
      onTemizle: () {
        _filtreUygula(() {
          _seciliKategoriYolu = [];
          _seciliAltKeyler    = [];
          _siralama           = app_constants.SiralamaTipi.enYeni;
          _seciliSehirler     = [];
          _seciliUlkeSehir    = '';
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ilanlar = _algoliaState.ilanlar;
    final statusH = MediaQuery.of(context).padding.top;

    Widget listeWidget;
    if (_algoliaState.yukleniyor && ilanlar.isEmpty) {
      listeWidget = const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
        )),
      );
    } else if (ilanlar.isEmpty) {
      listeWidget = SliverToBoxAdapter(
        child: _BosEkran(
          onYenile: () => _algoliaYukle(sifirla: true),
        ),
      );
    } else {
      listeWidget = SliverPadding(
        padding: const EdgeInsets.all(10),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childCount: ilanlar.length,
          itemBuilder: (context, index) => RepaintBoundary(
            key: ValueKey(ilanlar[index].id),
            child: IlanKarti(
              ilan: ilanlar[index],
              resimYukseklikleri: kResimYukseklikleri,
              kolonSayisi: 2,
            ),
          ),
        ),
      );
    }

    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: statusH, color: Colors.white),

        // ── Satır 1: Logo + bildirim ──
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            heightFactor: _aramaGizli ? 0.0 : 1.0,
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
                        size: 20,
                        weight: 200,
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

        // ── Satır 2: Arama + Filtre ──
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            heightFactor: _aramaGizli ? 0.0 : 1.0,
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
                          transitionDuration: const Duration(milliseconds: 200),
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
                                  size: 18, color: Color(0xFFCCCCCC)),
                              const SizedBox(width: 8),
                              Text(
                                'Güzergah veya ürün ara...',
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
                    onTap: _filtreAc,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _filtrAktif
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
                          if (_filtrAktif)
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

        // ── Satır 3: Kategori chip'leri ──
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            heightFactor: _aramaGizli ? 0.0 : 1.0,
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                controller: _kategoriScrollCtrl,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                itemCount: app_constants.kKategoriAgaci.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final secili = _seciliAnaKey == null;
                    return GestureDetector(
                      onTap: () => _filtreUygula(() {
                        _seciliKategoriYolu = [];
                        _seciliAltKeyler    = [];
                        _seciliSehirler     = [];
                        _seciliUlkeSehir    = '';
                      }),
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
                                  color: const Color(0xFFE53935).withValues(alpha: 0.3),
                                  blurRadius: 8, offset: const Offset(0, 2),
                                )]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text('Tümü',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: secili ? Colors.white : AppColors.textSecondary,
                            )),
                      ),
                    );
                  }
                  final kat    = app_constants.kKategoriAgaci[i - 1];
                  final secili = _seciliAnaKey == kat.key;
                  return GestureDetector(
                    onTap: () => _anaKategoriSec(kat.key),
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
                                color: const Color(0xFFE53935).withValues(alpha: 0.3),
                                blurRadius: 8, offset: const Offset(0, 2),
                              )]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            gelenlerKategoriIkon(kat.key),
                            size: 15,
                            color: secili ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(kat.ad,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secili ? Colors.white : AppColors.textPrimary,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Aktif filtre badge'leri ──
        if (_seciliKategoriYolu.isNotEmpty || _seciliAltKeyler.isNotEmpty ||
            _seciliSehirler.isNotEmpty || _seciliUlkeSehir.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_seciliKategoriYolu.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text(
                          _seciliAltKeyler.isNotEmpty
                              ? '${_seciliAltKeyler.length} alt kategori'
                              : app_constants.kategoriYoluMetni(_seciliKategoriYolu),
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.red,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _filtreUygula(() {
                          _seciliKategoriYolu = [];
                          _seciliAltKeyler    = [];
                        }),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: AppColors.red),
                      ),
                    ]),
                  ),
                if (_seciliSehirler.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text(
                          _seciliSehirler.join(', '),
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.red,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _filtreUygula(() => _seciliSehirler = []),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: AppColors.red),
                      ),
                    ]),
                  ),
                if (_seciliUlkeSehir.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.public_outlined,
                          size: 12, color: Color(0xFF1565C0)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _seciliUlkeSehir,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _filtreUygula(() => _seciliUlkeSehir = ''),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: Color(0xFF1565C0)),
                      ),
                    ]),
                  ),
              ],
            ),
          ),

        // ── Neden İSTE barı ──
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            heightFactor: _aramaGizli ? 0.0 : 1.0,
            alignment: Alignment.topCenter,
            child: const NedenIsteBar(),
          ),
        ),

        Container(height: 0.5, color: AppColors.divider),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          header,
          Expanded(
            child: RefreshIndicator(
              color: AppColors.red,
              onRefresh: () => _algoliaYukle(sifirla: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 10),
                    sliver: listeWidget,
                  ),
                  if (_algoliaState.yukleniyor && ilanlar.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.red),
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
    );
  }
}

// ── Boş Ekran ─────────────────────────────────────────────────────────────────

class _BosEkran extends StatelessWidget {
  final VoidCallback onYenile;
  const _BosEkran({required this.onYenile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight_land_outlined,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Henüz gelen ilanı yok',
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Yurt dışından bir şey getireceksen hemen ilan ver',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onYenile,
            child: Text('Yenile',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Gelenler Detay Ekranı ─────────────────────────────────────────────────────

class GelenlerDetayScreen extends ConsumerStatefulWidget {
  final List<String> kategoriYolu;
  final String? tip;
  const GelenlerDetayScreen({super.key, required this.kategoriYolu, this.tip});

  @override
  ConsumerState<GelenlerDetayScreen> createState() => _GelenlerDetayScreenState();
}

class _GelenlerDetayScreenState extends ConsumerState<GelenlerDetayScreen> {
  final _scrollController = ScrollController();
  List<String> _seciliKategoriYolu = [];

  @override
  void initState() {
    super.initState();
    _seciliKategoriYolu = List<String>.from(widget.kategoriYolu);
  }

  List<IlanModel> _filtrele(List<IlanModel> liste) {
    if (_seciliKategoriYolu.isEmpty) return liste;
    final sonKey = _seciliKategoriYolu.last;
    final gecerliKeyler = app_constants.tumAltKeyler(sonKey);
    return liste.where((i) =>
        gecerliKeyler.contains(i.kategori) ||
        i.kategoriYolu.any((k) => gecerliKeyler.contains(k))).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.tip == 'istek'
        ? ref.watch(istekIlanlarProvider)
        : ref.watch(tasiyiciIlanlarProvider);
    final ilanlar = _filtrele(state.filtrelenmis)
      ..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
          .compareTo(a.olusturmaTarihi ?? DateTime(0)));

    final baslik = _seciliKategoriYolu.isNotEmpty
        ? app_constants.kategoriYoluMetni(_seciliKategoriYolu)
        : 'Gelenler';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          baslik,
          style: GoogleFonts.dmSans(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: state.yukleniyor && ilanlar.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.red, strokeWidth: 2))
          : ilanlar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flight_land_outlined,
                          size: 64, color: AppColors.divider),
                      const SizedBox(height: 16),
                      Text('Bu kategoride ilan yok',
                          style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
                  itemCount: ilanlar.length,
                  itemBuilder: (context, index) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: IlanKarti(
                          ilan: ilanlar[index],
                          resimYukseklikleri: kResimYukseklikleri,
                          kolonSayisi: 2,
                        ),
                      ),
                ),
    );
  }
}