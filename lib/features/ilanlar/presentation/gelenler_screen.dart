// lib/features/ilanlar/presentation/gelenler_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../shared/widgets/turkiye_disi_arama_ekrani.dart';





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

// ── Sıralama ──────────────────────────────────────────────────────────────────

enum GelenlerSiralama { enYeni, enEski, enCokFavorilenen, onerilen }

extension GelenlerSiralamaX on GelenlerSiralama {
  String get label {
    switch (this) {
      case GelenlerSiralama.enYeni:           return 'En yeni';
      case GelenlerSiralama.enEski:           return 'En eski';
      case GelenlerSiralama.enCokFavorilenen: return 'Favori';
      case GelenlerSiralama.onerilen:         return 'Önerilen';
    }
  }
  String get algoliaKey {
    switch (this) {
      case GelenlerSiralama.enYeni:           return 'enYeni';
      case GelenlerSiralama.enEski:           return 'enEski';
      case GelenlerSiralama.enCokFavorilenen: return 'enCokFavorilenen';
      case GelenlerSiralama.onerilen:         return 'onerilen';
    }
  }
}

// ── Şehirler ──────────────────────────────────────────────────────────────────

const _kSehirler = [
  'İstanbul', 'Ankara', 'İzmir', 'Bursa',
  'Çanakkale', 'Eskişehir', 'Antalya',
];

class GelenlerScreen extends ConsumerStatefulWidget {
  final bool embedded;
  final List<String> initialKategoriYolu;
  const GelenlerScreen({super.key, this.embedded = false, this.initialKategoriYolu = const []});

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
  GelenlerSiralama    _siralama          = GelenlerSiralama.enYeni;
  List<String>        _seciliSehirler    = [];
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
        nerdenUlkeSehir: _seciliUlkeSehir,
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

  bool get _filtrAktif => _seciliSehirler.isNotEmpty || _seciliKategoriYolu.isNotEmpty || _seciliAltKeyler.isNotEmpty || _siralama != GelenlerSiralama.enYeni || _seciliUlkeSehir.isNotEmpty;

  String _seciliUlkeSehir = '';

  String? get _seciliAnaKey =>
      _seciliKategoriYolu.isNotEmpty ? _seciliKategoriYolu.first : null;

  List<IlanModel> _filtrele(List<IlanModel> liste) {
    var sonuc = liste;

    if (_seciliKategoriYolu.isNotEmpty) {
      final sonKey = _seciliKategoriYolu.last;
      final gecerliKeyler = app_constants.tumAltKeyler(sonKey);
      sonuc = sonuc.where((i) =>
          gecerliKeyler.contains(i.kategori) ||
          i.kategoriYolu.any((k) => gecerliKeyler.contains(k))).toList();
    }

    if (_seciliSehirler.isNotEmpty) {
      sonuc = sonuc.where((i) =>
        _seciliSehirler.any((s) => i.nereye.toLowerCase().contains(s.toLowerCase()))
      ).toList();
    }


    return sonuc;
  }

  List<IlanModel> _sirala(List<IlanModel> liste) {
    final kopya = List<IlanModel>.from(liste);
    switch (_siralama) {
      case GelenlerSiralama.enYeni:
        kopya.sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
            .compareTo(a.olusturmaTarihi ?? DateTime(0)));
      case GelenlerSiralama.enEski:
        kopya.sort((a, b) => (a.olusturmaTarihi ?? DateTime(0))
            .compareTo(b.olusturmaTarihi ?? DateTime(0)));
      case GelenlerSiralama.enCokFavorilenen:
        kopya.sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi));
      case GelenlerSiralama.onerilen:
        break;
    }
    return kopya;
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



  void _filtreAc() {
    final ilanSayilari = _algoliaState.kategoriFacets;
    var modalKategoriYolu = List<String>.from(_seciliKategoriYolu);
    var modalAltKeyler    = List<String>.from(_seciliAltKeyler);
    var modalSiralama     = _siralama;
    var modalSehirler     = List<String>.from(_seciliSehirler);
    var modalUlkeSehir    = _seciliUlkeSehir;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Sabit başlık ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text('Kategoriler',
                            style: GoogleFonts.dmSans(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const Spacer(),
                        if (modalKategoriYolu.isNotEmpty || modalAltKeyler.isNotEmpty ||
                            modalSehirler.isNotEmpty || modalSiralama != GelenlerSiralama.enYeni)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _filtreUygula(() {
                                _seciliKategoriYolu = [];
                                _seciliAltKeyler    = [];
                                _siralama           = GelenlerSiralama.enYeni;
                                _seciliSehirler     = [];
                                _seciliUlkeSehir    = '';
                              });
                            },
                            child: Text('Temizle',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13, color: AppColors.red,
                                    fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Scrollable içerik ────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ana kategori listesi
                        ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          children: app_constants.kKategoriAgaci.map((node) {
                            final secili = modalKategoriYolu.isNotEmpty &&
                                modalKategoriYolu.first == node.key;
                            final altSecimVar = secili && modalAltKeyler.isNotEmpty;
                            return _FiltreKategoriSatiri(
                              ad: node.ad,
                              ikon: _gelenlerKategoriIkon(node.key),
                              secili: secili,
                              derinlikOku: !node.yaprakMi,
                              ilanSayisi: ilanSayilari[node.key] ?? 0,
                              altBilgi: altSecimVar
                                  ? '${modalAltKeyler.length} alt kategori seçili'
                                  : null,
                              onTap: () {
                                if (node.yaprakMi) {
                                  setModalState(() {
                                    modalKategoriYolu = [node.key];
                                    modalAltKeyler    = [];
                                  });
                                } else {
                                  showGeneralDialog<List<String>>(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: '',
                                    barrierColor: Colors.black54,
                                    transitionDuration: const Duration(milliseconds: 250),
                                    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    transitionBuilder: (_, anim, __, ___) {
                                      final slide = Tween<Offset>(
                                        begin: const Offset(1, 0), end: Offset.zero,
                                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                                      return SlideTransition(
                                        position: slide,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: _AltKategoriSayfasi(
                                            anaNode: node,
                                            mevcutSecim: modalKategoriYolu.isNotEmpty &&
                                                modalKategoriYolu.first == node.key
                                                ? modalAltKeyler
                                                : [],
                                          ),
                                        ),
                                      );
                                    },
                                  ).then((altSecim) {
                                    if (altSecim != null) {
                                      setModalState(() {
                                        modalKategoriYolu = [node.key];
                                        modalAltKeyler    = altSecim;
                                      });
                                    }
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),

                        const Divider(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Sıralama',
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                          child: _GSiralamaSegmented(
                            secili: modalSiralama,
                            onSecim: (tip) => setModalState(() => modalSiralama = tip),
                          ),
                        ),

                        const Divider(height: 24),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              Text('Varış Şehri',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const Spacer(),
                              if (modalSehirler.isNotEmpty)
                                GestureDetector(
                                  onTap: () => setModalState(() => modalSehirler = []),
                                  child: Text('Temizle',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13, color: AppColors.red,
                                          fontWeight: FontWeight.w500)),
                                ),
                              if (modalSehirler.isNotEmpty) const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  final sonuc = await Navigator.push<String>(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      barrierColor: Colors.black54,
                                      pageBuilder: (_, __, ___) => TurkiyeDisiAramaEkrani(
                                        mevcutSecim: modalUlkeSehir,
                                        alan: 'nereden',
                                      ),
                                      transitionsBuilder: (_, anim, __, child) =>
                                          FadeTransition(opacity: anim, child: child),
                                    ),
                                  );
                                  if (sonuc != null) {
                                    setModalState(() => modalUlkeSehir =
                                        sonuc == '__temizle__' ? '' : sonuc);
                                  }
                                },
                                child: Text(
                                  modalUlkeSehir.isNotEmpty
                                      ? modalUlkeSehir
                                      : 'Türkiye dışı',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: const Color(0xFF1565C0),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                          child: GestureDetector(
                            onTap: () async {
                              List<String> temp = List.from(modalSehirler);
                              await showDialog<void>(
                                context: context,
                                builder: (dlgCtx) => StatefulBuilder(
                                  builder: (dlgCtx, setDlg) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    title: Text('Varış Şehri',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 16, fontWeight: FontWeight.w700)),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 340,
                                      child: ListView(
                                        children: [
                                          CheckboxListTile(
                                            dense: true,
                                            title: Text('Tümü',
                                                style: GoogleFonts.dmSans(fontSize: 14)),
                                            value: temp.isEmpty,
                                            activeColor: AppColors.red,
                                            onChanged: (v) {
                                              if (v == true) setDlg(() => temp.clear());
                                            },
                                          ),
                                          ...app_constants.kTurkiyeSehirleri.map((s) =>
                                            CheckboxListTile(
                                              dense: true,
                                              title: Text(s,
                                                  style: GoogleFonts.dmSans(fontSize: 14)),
                                              value: temp.contains(s),
                                              activeColor: AppColors.red,
                                              onChanged: (v) {
                                                setDlg(() => v == true
                                                    ? temp.add(s)
                                                    : temp.remove(s));
                                              },
                                            )),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dlgCtx),
                                        child: Text('İptal',
                                            style: GoogleFonts.dmSans(
                                                color: AppColors.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setModalState(() => modalSehirler = List.from(temp));
                                          Navigator.pop(dlgCtx);
                                        },
                                        child: Text('Tamam',
                                            style: GoogleFonts.dmSans(
                                                color: AppColors.red,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: modalSehirler.isEmpty
                                    ? AppColors.surface
                                    : AppColors.red.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: modalSehirler.isEmpty
                                      ? AppColors.divider
                                      : AppColors.red.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 18,
                                      color: modalSehirler.isEmpty
                                          ? AppColors.textSecondary
                                          : AppColors.red),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      modalSehirler.isEmpty
                                          ? 'Tüm şehirler'
                                          : modalSehirler.join(', '),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        color: modalSehirler.isEmpty
                                            ? AppColors.textHint
                                            : AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: modalSehirler.isEmpty
                                          ? AppColors.textSecondary
                                          : AppColors.red),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _filtreUygula(() {
                                  _seciliKategoriYolu = modalKategoriYolu;
                                  _seciliAltKeyler    = modalAltKeyler;
                                  _siralama           = modalSiralama;
                                  _seciliSehirler     = modalSehirler;
                                  _seciliUlkeSehir    = modalUlkeSehir;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Uygula',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
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
                      onTap: () => setState(() => _seciliKategoriYolu = []),
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
                            _gelenlerKategoriIkon(kat.key),
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
            child: const SizedBox(height: 28, child: NedenIsteBar()),
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

// ── Filtre Chip ───────────────────────────────────────────────────────────────

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool secili;
  final VoidCallback onTap;

  const _FiltreChip({
    required this.label,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: secili ? AppColors.red : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: secili ? AppColors.red : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: secili ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Filtre Kategori Satırı ────────────────────────────────────────────────────

class _FiltreKategoriSatiri extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;
  final bool derinlikOku;
  final bool vurgulu;
  final int? ilanSayisi;
  final String? altBilgi;
  final IconData? ikon;

  const _FiltreKategoriSatiri({
    required this.ad,
    required this.secili,
    required this.onTap,
    this.derinlikOku = false,
    this.vurgulu = false,
    this.ilanSayisi,
    this.altBilgi,
    this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: secili ? AppColors.red.withValues(alpha: 0.05) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (ikon != null) ...[
              Icon(ikon, size: 18,
                  color: secili ? AppColors.red : AppColors.textSecondary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        ad,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: (secili || vurgulu) ? FontWeight.w600 : FontWeight.w400,
                          color: secili ? AppColors.red : AppColors.textPrimary,
                        ),
                      ),
                      if (ilanSayisi != null && ilanSayisi! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '($ilanSayisi)',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (altBilgi != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      altBilgi!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: AppColors.red)
            else if (derinlikOku)
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
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

// ── Alt Kategori Tam Sayfa ────────────────────────────────────────────────────

class _AltKategoriSayfasi extends StatefulWidget {
  final app_constants.KategoriNode anaNode;
  final List<String> mevcutSecim;

  const _AltKategoriSayfasi({
    required this.anaNode,
    required this.mevcutSecim,
  });

  @override
  State<_AltKategoriSayfasi> createState() => _AltKategoriSayfasiState();
}

class _AltKategoriSayfasiState extends State<_AltKategoriSayfasi> {
  late List<String> _gezinmeYolu;
  late List<String> _seciliKeyler;

  @override
  void initState() {
    super.initState();
    _gezinmeYolu  = [widget.anaNode.key];
    _seciliKeyler = List<String>.from(widget.mevcutSecim);
  }

  List<app_constants.KategoriNode> _mevcutNodes() {
    List<app_constants.KategoriNode> liste = app_constants.kKategoriAgaci;
    for (final key in _gezinmeYolu) {
      final node = liste.firstWhere(
        (n) => n.key == key,
        orElse: () => app_constants.KategoriNode(key: '', ad: ''),
      );
      if (node.key.isEmpty || node.altlar.isEmpty) break;
      liste = node.altlar;
    }
    return liste;
  }

  String _baslik() =>
      app_constants.kategoriNodeBul(_gezinmeYolu.last)?.ad ?? '';

  void _geriGit() {
    if (_gezinmeYolu.length > 1) {
      setState(() => _gezinmeYolu = _gezinmeYolu.sublist(0, _gezinmeYolu.length - 1));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _mevcutNodes();

    return PopScope(
      canPop: _gezinmeYolu.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _geriGit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                size: 18, color: AppColors.textPrimary),
            onPressed: _geriGit,
          ),
          title: Text(
            _baslik(),
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          actions: [
            if (_seciliKeyler.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _seciliKeyler.clear()),
                child: Text('Temizle',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.red,
                        fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: ListView(
                  children: [
                    _FiltreKategoriSatiri(
                      ad: 'Tüm "${_baslik()}" Ürünleri',
                      secili: _seciliKeyler.isEmpty,
                      vurgulu: true,
                      onTap: () => Navigator.pop(context, <String>[]),
                    ),
                    ...nodes.map((node) => _FiltreKategoriSatiri(
                      ad: node.ad,
                      secili: _seciliKeyler.contains(node.key),
                      derinlikOku: !node.yaprakMi,
                      onTap: () {
                        if (node.yaprakMi) {
                          setState(() {
                            if (_seciliKeyler.contains(node.key)) {
                              _seciliKeyler.remove(node.key);
                            } else {
                              _seciliKeyler.add(node.key);
                            }
                          });
                        } else {
                          setState(() => _gezinmeYolu = [..._gezinmeYolu, node.key]);
                        }
                      },
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _seciliKeyler),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _seciliKeyler.isEmpty
                    ? 'Tümünü Göster'
                    : '${_seciliKeyler.length} kategori seçildi',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gelenler Sıralama Segmented ───────────────────────────────────────────────

class _GSiralamaSegmented extends StatelessWidget {
  final GelenlerSiralama secili;
  final ValueChanged<GelenlerSiralama> onSecim;

  const _GSiralamaSegmented({
    required this.secili,
    required this.onSecim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: GelenlerSiralama.values.map((tip) {
          final seciliMi = secili == tip;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSecim(tip),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: seciliMi ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: seciliMi
                      ? Border.all(color: const Color(0xFFE0E0E0), width: 0.5)
                      : null,
                ),
                child: Text(
                  tip.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: seciliMi ? FontWeight.w600 : FontWeight.w400,
                    color: seciliMi ? AppColors.red : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

IconData _gelenlerKategoriIkon(String key) {
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