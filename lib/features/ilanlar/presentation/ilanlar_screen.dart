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
import 'dart:math';
import 'package:iste_v3/features/favoriler/presentation/favoriler_screen.dart';
import 'ilan_detay_screen.dart';
import '../../../shared/utils/app_hata_yonetici.dart';
import '../../../shared/utils/oneri_skoru.dart';
import '../../../shared/widgets/hata_durum_widget.dart';
import '../../tanitim/data/tanitim_repository.dart';
import '../../tanitim/presentation/iste_tanitim_ekrani.dart';
import '../../ilanlar/presentation/ilan_form_screen.dart';



// ── Algolia filtre state ───────────────────────────────────────────────────────

class _AlgoliaState {
  final List<IlanModel> ilanlar;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final int mevcutSayfa;
  final Map<String, int> kategoriFacets;
  final String? hata;

  const _AlgoliaState({
    this.ilanlar        = const [],
    this.yukleniyor     = false,
    this.dahaFazlaVar   = true,
    this.mevcutSayfa    = 0,
    this.kategoriFacets = const {},
    this.hata,
  });

  _AlgoliaState copyWith({
    List<IlanModel>? ilanlar,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    int? mevcutSayfa,
    Map<String, int>? kategoriFacets,
    String? hata,
    bool temizleHata = false,
  }) => _AlgoliaState(
    ilanlar:        ilanlar        ?? this.ilanlar,
    yukleniyor:     yukleniyor     ?? this.yukleniyor,
    dahaFazlaVar:   dahaFazlaVar   ?? this.dahaFazlaVar,
    mevcutSayfa:    mevcutSayfa    ?? this.mevcutSayfa,
    kategoriFacets: kategoriFacets ?? this.kategoriFacets,
    hata:           temizleHata ? null : (hata ?? this.hata),
  );
}

// Algolia sonucunu IlanModel'e donustur
// Artık Algolia'nın özel alan adları yerine ham v3Ilan JSON'ı geliyor
// (bkz. arama_service.dart) — IlanModel.fromJson bunu zaten her yerde
// (GET /ilanlar, GET /ilanlarim) ayrıştırdığı şekilde ayrıştırıyor.
IlanModel _hittenIlan(Map<String, dynamic> hit) => IlanModel.fromJson(hit);

class IsteklerIcEkran extends ConsumerStatefulWidget {
  final GlobalKey? filtreKey;
  final GlobalKey? gorunumKey;
  final VoidCallback? onHosGeldinKapandi;

  const IsteklerIcEkran({
    super.key,
    this.filtreKey,
    this.gorunumKey,
    this.onHosGeldinKapandi,
  });

  @override
  ConsumerState<IsteklerIcEkran> createState() => _IsteklerIcEkranState();
}

class _IsteklerIcEkranState extends ConsumerState<IsteklerIcEkran>
    with AutomaticKeepAliveClientMixin {
  final _scrollController   = ScrollController();
  final _aramaCtrl          = TextEditingController();
  final _kategoriScrollCtrl = ScrollController();

  SiralamaTipi _siralama             = SiralamaTipi.onerilen;
  List<String> _seciliKategoriYolu   = [];
  List<String> _seciliAltKeyler      = [];
  List<String> _seciliIstekSehirleri = [];
  String       _seciliUlkeSehir      = '';
  bool         _aramaGizli           = false;
  Timer?       _filtreTimer;

  _AlgoliaState _algoliaState = const _AlgoliaState();

  static const _ilkIlanBannerGorselleri = [
    'assets/images/banner_ilk_ilan.png',
    'assets/images/banner_ilk_ilan_aa.png',
    'assets/images/banner_ilk_ilan_bb.png',
  ];
  late final String _ilkIlanBannerGorseli =
      _ilkIlanBannerGorselleri[Random().nextInt(_ilkIlanBannerGorselleri.length)];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _algoliaYukle(sifirla: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hosGeldinKontrolEt());
  }

  Future<void> _hosGeldinKontrolEt() async {
    if (!mounted) return;
    final hemenIlanVer = await _tanitimKontrolEt();
    // "Hemen ilan ver" ile ilan formuna gidiliyorsa coach mark'ı şimdi
    // tetikleme — ikisi aynı anda yarışıp tur diyaloğu yeni açılan ilan
    // formunun altında kalıp kayboluyordu. Tur, 'tur_gosterildi' bayrağı
    // hâlâ false olduğu için bir sonraki ana sayfa ziyaretinde gösterilir.
    if (hemenIlanVer == true) return;
    if (!mounted) return;
    widget.onHosGeldinKapandi?.call();
  }

  /// Tanıtım (onboarding) ekranı — Çekmece'deki ilan_tesvik gibi,
  /// kullanici_id'ye bağlı olarak backend'de bir kerelik gösterilir.
  /// Coach mark'tan ÖNCE çalışır.
  Future<bool?> _tanitimKontrolEt() async {
    bool goster;
    try {
      goster = await TanitimRepository().gosterilmeliMi();
    } catch (_) {
      // Ağ hatasında akışı bozma — tanıtımı sessizce atla, bir sonraki
      // açılışta tekrar denenir (backend'de bayrak hâlâ false).
      return null;
    }
    if (!goster || !mounted) return null;

    final hemenIlanVer = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IsteTanitimEkrani(
          onTamamlandi: (hemenIlanVer) => Navigator.of(context).pop(hemenIlanVer),
        ),
      ),
    );
    unawaited(TanitimRepository().goruldu());
    if (hemenIlanVer == true && mounted) {
      Navigator.push(context, CupertinoPageRoute(
        builder: (_) => IlanFormScreen(tip: IlanTip.istek),
      ));
    }
    return hemenIlanVer;
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

      // enCokFavorilenen: Algolia'nın ilanlar_favori replikası
      // (arama_service.dart) zaten kendi customRanking'iyle favoriSayisi'ye
      // göre sıralı dönüyor — client-taraflı yeniden sıralama gereksizdi ve
      // yalnızca o anki 24'lük sayfa içinde yapıldığı için sayfalar arası
      // global sıralamayı bozuyordu (gelenler_screen.dart'ta zaten yoktu).
      // onerilen icin siralama
      if (_siralama == SiralamaTipi.onerilen) {
        oneriSkoruylasirala(yeniIlanlar);
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
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'ilanlarScreen.algoliaYukle');
      setState(() {
        _algoliaState = _algoliaState.copyWith(
          yukleniyor: false,
          hata: _algoliaState.ilanlar.isEmpty ? 'İlanlar yüklenemedi.' : null,
        );
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
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
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
                  _siralama             = SiralamaTipi.onerilen;
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
    } else if (_algoliaState.hata != null && ilanlar.isEmpty) {
      ilanWidget = SliverFillRemaining(
        hasScrollBody: false,
        child: HataDurumWidget(
          mesaj: _algoliaState.hata!,
          onTekrarDene: () => _algoliaYukle(sifirla: true),
        ),
      );
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
                filtreKey: widget.filtreKey,
                mod: mod,
                gorunumKey: widget.gorunumKey,
                onModSec: (m) =>
                    ref.read(gridTercihiProvider.notifier).modSec(m),
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
                                    _ilkIlanBannerGorseli,
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
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: const AspectRatio(
                                    aspectRatio: 6,
                                    child: _IlkIlanBannerCarousel(),
                                  ),
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
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
        ],
      ),
    );
  }
}

// ── Dikey mod tab bar ─────────────────────────────────────────────────────────

// Çekmece'deki _GorunumIkonButonu ile aynı desen: popup açmaz, her
// dokunuşta 2'li → 3'lü → swipe → (baştan) döngüsel geçiş yapar. Eskiden
// ekranın sağ kenarına yapışık sabit bir dikey çubuktu (_DikeTabBar),
// kullanıcı isteğiyle arama satırındaki filtre ikonunun eski yerine
// taşındı.
class _GorunumIkonButonu extends StatelessWidget {
  final GoruntulemeModeli mod;
  final ValueChanged<GoruntulemeModeli> onModSec;
  final GlobalKey? gorunumKey;

  const _GorunumIkonButonu({
    required this.mod,
    required this.onModSec,
    this.gorunumKey,
  });

  static const _ikonlar = {
    GoruntulemeModeli.iki:   Icons.grid_view_rounded,
    GoruntulemeModeli.uc:    Icons.view_module_rounded,
    GoruntulemeModeli.swipe: Icons.swipe_left_alt_rounded,
  };

  void _sonrakineGec() {
    final degerler = GoruntulemeModeli.values;
    final sonrakiIndex = (mod.index + 1) % degerler.length;
    onModSec(degerler[sonrakiIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: gorunumKey,
      onTap: _sonrakineGec,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(_ikonlar[mod], color: Colors.white, size: 18),
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
  final GlobalKey? filtreKey;
  final GoruntulemeModeli mod;
  final ValueChanged<GoruntulemeModeli> onModSec;
  final GlobalKey? gorunumKey;

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
    required this.mod,
    required this.onModSec,
    this.gorunumKey,
    required this.onFiltreAc,
    required this.onKategoriSec,
    required this.onFiltreSifirla,
    this.filtreKey,
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
                          Icons.favorite_outline,
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
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (_, _, _) => const AramaScreen(),
                                      transitionsBuilder: (_, anim, _, child) =>
                                          FadeTransition(opacity: anim, child: child),
                                      transitionDuration:
                                          const Duration(milliseconds: 200),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
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
                              // Filtre ikonu — eskiden arama kutusunun
                              // DIŞINDA, ayrı 44px'lik bir kutuydu; artık
                              // arama çubuğunun içine, sağa, küçültülmüş
                              // (18px radius) olarak taşındı.
                              GestureDetector(
                                key: filtreKey,
                                onTap: onFiltreAc,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: filtrAktif
                                          ? const Color(0xFF1A1A1A)
                                          : const Color(0xFF2C2C2C),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(Icons.tune_rounded,
                                            color: Colors.white, size: 16),
                                        if (filtrAktif)
                                          Positioned(
                                            top: 6, right: 6,
                                            child: Container(
                                              width: 6, height: 6,
                                              decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GorunumIkonButonu(
                      mod: mod,
                      onModSec: onModSec,
                      gorunumKey: gorunumKey,
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
                        color: secili ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFEEEEEE), width: 1),
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
                      child: Text('Tümü',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
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
                      gradient: null,
                      color: secili ? kategoriRengi(kat.key) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: secili
                            ? Colors.transparent
                            : const Color(0xFFEEEEEE),
                        width: 1,
                      ),
                      boxShadow: secili
                          ? [BoxShadow(
                              color: kategoriRengi(kat.key)
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
                        kat.ikonYolu != null
                            ? Image.asset(kat.ikonYolu!, width: 22, height: 22)
                            : Icon(
                                kategoriIkon(kat.key),
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

// ── İlk İlan Banner Carousel ──────────────────────────────────────────────────

class _IlkIlanBannerCarousel extends StatefulWidget {
  const _IlkIlanBannerCarousel();

  @override
  State<_IlkIlanBannerCarousel> createState() =>
      _IlkIlanBannerCarouselState();
}

class _IlkIlanBannerCarouselState extends State<_IlkIlanBannerCarousel> {
  static const _gorseller = [
    'assets/images/banner_ilk_ilan_cc.png',
    'assets/images/banner_ilk_ilan_dd.png',
    'assets/images/banner_ilk_ilan_ee.png',
  ];

  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageCtrl,
      itemCount: _gorseller.length,
      itemBuilder: (context, i) => Image.asset(
        _gorseller[i],
        width: double.infinity,
        fit: BoxFit.cover,
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
      error: (e, s) { AppHataYonetici.logla(e, s, etiket: 'ilanlarScreen.haftaninEnleri'); return const SizedBox.shrink(); },
      data: (ilanlar) {
        if (ilanlar.isEmpty) return const SizedBox.shrink();

        const cardH = 190.0;
        const cardW = 110.0;

        return Stack(
          children: [
            Positioned.fill(
              bottom: 10, // 10px kısa
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD6ECFF), Color(0xFFFFD9E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Haftanın Öne Çıkanları",
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Tümünü Gör',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ilan.gridResim.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: ilan.gridResim,
                                              cacheManager: AppCacheManager.instance,
                                              fit: BoxFit.cover,
                                              memCacheWidth: (cardW * 2).round(),
                                              memCacheHeight: (cardH * 2).round(),
                                              errorWidget: (ctx, url, err) =>
                                                  _PlaceholderImage(w: cardW, h: cardH),
                                            )
                                          : _PlaceholderImage(w: cardW, h: cardH),
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
                                        child: Text(
                                          ilan.tip == IlanTip.istek
                                              ? '→ ${ilan.nereye}'
                                              : '${ilan.nereden} → ${ilan.nereye}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 9,
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD500),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Öne çıkan',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                              if (ilan.yeniMi)
                              Positioned(
                                top: 6,
                                right: 6,
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
// Standart Material Icons kullanılıyor — Material Symbols (değişken font)
// bazı daha az yaygın simgeleri (dry_cleaning, stroller gibi) her cihazda
// doğru render etmiyordu ("ana kategori simgelerinden bazıları yok" bug
// raporu), standart ikon fontu uygulamanın her yerinde zaten güvenilir
// çalışıyor.
IconData kategoriIkon(String key) {
  switch (key) {
    case 'kadin':       return Icons.checkroom;
    case 'erkek':       return Icons.dry_cleaning;
    case 'cocuk':       return Icons.stroller;
    case 'ev':          return Icons.cottage;
    case 'elektronik':  return Icons.headphones;
    case 'supplement':  return Icons.vaccines;
    default:            return Icons.inventory_2;
  }
}