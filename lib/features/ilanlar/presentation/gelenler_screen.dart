// lib/features/ilanlar/presentation/gelenler_screen.dart

import 'package:flutter/cupertino.dart';
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
import '../../../shared/widgets/bildirim_cani_widget.dart';
import '../../../shared/widgets/neden_iste_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:iste_v3/features/ilanlar/presentation/favoriler_screen.dart';
import 'widgets/ilan_karti.dart';




// ── Sıralama ──────────────────────────────────────────────────────────────────

enum GelenlerSiralama { enYeni, enEski }

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
  final _aramaCtrl          = TextEditingController();
  final _kategoriScrollCtrl = ScrollController();

  String              _aramaMetni        = '';
  List<String>        _seciliKategoriYolu = [];
  bool                _aramaGizli        = false;
  GelenlerSiralama    _siralama          = GelenlerSiralama.enYeni;
  String?             _seciliSehir;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialKategoriYolu.isNotEmpty) {
      _seciliKategoriYolu = List<String>.from(widget.initialKategoriYolu);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _aramaCtrl.dispose();
    _kategoriScrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.userScrollDirection == ScrollDirection.reverse && !_aramaGizli) {
      setState(() => _aramaGizli = true);
    } else if (pos.userScrollDirection == ScrollDirection.forward && _aramaGizli) {
      setState(() => _aramaGizli = false);
    }
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      if (!ref.read(tasiyiciIlanlarProvider).yukleniyor) {
        ref.read(tasiyiciIlanlarProvider.notifier).dahaFazlaYukle();
      }
    }
  }

  bool get _filtrAktif => _seciliSehir != null || _seciliKategoriYolu.isNotEmpty || _siralama != GelenlerSiralama.enYeni;

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

    if (_seciliSehir != null) {
      final sehir = _seciliSehir!.toLowerCase();
      sonuc = sonuc.where((i) => i.nereye.toLowerCase().contains(sehir)).toList();
    }

    if (_aramaMetni.isNotEmpty) {
      final q = _aramaMetni.toLowerCase();
      sonuc = sonuc.where((i) =>
          i.urun.toLowerCase().contains(q) ||
          i.nereden.toLowerCase().contains(q) ||
          i.nereye.toLowerCase().contains(q)).toList();
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
    }
    return kopya;
  }

  void _anaKategoriSec(String anaKey) {
    setState(() {
      if (_seciliAnaKey == anaKey) {
        _seciliKategoriYolu = [];
      } else {
        _seciliKategoriYolu = [anaKey];
      }
    });
  }

  void _filtreAc() {
    var modalKategoriYolu = List<String>.from(_seciliKategoriYolu);
    var modalSiralama     = _siralama;
    var modalSehir        = _seciliSehir;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          List<String> gezinmeYolu = List<String>.from(modalKategoriYolu);
          if (gezinmeYolu.isNotEmpty) gezinmeYolu = gezinmeYolu.sublist(0, gezinmeYolu.length - 1);

          return StatefulBuilder(
            builder: (ctx, setInnerState) {

              List<app_constants.KategoriNode> mevcutNodes() {
                if (gezinmeYolu.isEmpty) return app_constants.kKategoriAgaci;
                List<app_constants.KategoriNode> liste = app_constants.kKategoriAgaci;
                for (final key in gezinmeYolu) {
                  final node = liste.firstWhere(
                    (n) => n.key == key,
                    orElse: () => app_constants.KategoriNode(key: '', ad: ''),
                  );
                  if (node.key.isEmpty || node.altlar.isEmpty) break;
                  liste = node.altlar;
                }
                return liste;
              }

              String seviyeBasligi() {
                if (gezinmeYolu.isEmpty) return 'Kategori';
                final node = app_constants.kategoriNodeBul(gezinmeYolu.last);
                return node?.ad ?? 'Kategori';
              }

              String breadcrumb() {
                if (gezinmeYolu.isEmpty) return '';
                return gezinmeYolu.map((key) {
                  final node = app_constants.kategoriNodeBul(key);
                  return node?.ad ?? key;
                }).join(' › ');
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            if (gezinmeYolu.isNotEmpty)
                              GestureDetector(
                                onTap: () => setInnerState(() =>
                                    gezinmeYolu = gezinmeYolu.sublist(0, gezinmeYolu.length - 1)),
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.arrow_back_ios_rounded,
                                      size: 16, color: AppColors.textPrimary),
                                ),
                              ),
                            Text(
                              gezinmeYolu.isEmpty ? 'Kategori' : seviyeBasligi(),
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            if (modalKategoriYolu.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    modalKategoriYolu = [];
                                    gezinmeYolu = [];
                                  });
                                },
                                child: Text('Temizle',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12, color: AppColors.red,
                                        fontWeight: FontWeight.w500)),
                              ),
                          ],
                        ),
                      ),

                      if (breadcrumb().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Text(
                            breadcrumb(),
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),

                      const SizedBox(height: 10),

                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            if (gezinmeYolu.isNotEmpty)
                              _FiltreKategoriSatiri(
                                ad: 'Tüm "${seviyeBasligi()}" Ürünleri',
                                secili: modalKategoriYolu.isNotEmpty &&
                                    modalKategoriYolu.last == gezinmeYolu.last,
                                vurgulu: true,
                                onTap: () {
                                  setModalState(() => modalKategoriYolu = List<String>.from(gezinmeYolu));
                                },
                              ),
                            ...mevcutNodes().map((node) => _FiltreKategoriSatiri(
                              ad: node.emoji.isNotEmpty
                                  ? '${node.emoji}  ${node.ad}'
                                  : node.ad,
                              secili: modalKategoriYolu.contains(node.key),
                              derinlikOku: !node.yaprakMi,
                              onTap: () {
                                if (node.yaprakMi) {
                                  setModalState(() => modalKategoriYolu = [...gezinmeYolu, node.key]);
                                } else {
                                  setInnerState(() => gezinmeYolu = [...gezinmeYolu, node.key]);
                                }
                              },
                            )),
                          ],
                        ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _FiltreChip(
                              label: 'En Yeni',
                              secili: modalSiralama == GelenlerSiralama.enYeni,
                              onTap: () => setModalState(
                                  () => modalSiralama = GelenlerSiralama.enYeni),
                            ),
                            const SizedBox(width: 8),
                            _FiltreChip(
                              label: 'En Eski',
                              secili: modalSiralama == GelenlerSiralama.enEski,
                              onTap: () => setModalState(
                                  () => modalSiralama = GelenlerSiralama.enEski),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Varış Şehri',
                            style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FiltreChip(
                              label: 'Tümü',
                              secili: modalSehir == null,
                              onTap: () => setModalState(() => modalSehir = null),
                            ),
                            ..._kSehirler.map((sehir) => _FiltreChip(
                              label: sehir,
                              secili: modalSehir == sehir,
                              onTap: () => setModalState(() => modalSehir = sehir),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _seciliKategoriYolu = modalKategoriYolu;
                                _siralama           = modalSiralama;
                                _seciliSehir        = modalSehir;
                              });
                              Navigator.pop(ctx);
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
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state   = ref.watch(tasiyiciIlanlarProvider);
    final ilanlar = _sirala(_filtrele(state.filtrelenmis));
    final statusH = MediaQuery.of(context).padding.top;

    Widget listeWidget;
    if (state.yukleniyor && ilanlar.isEmpty) {
      listeWidget = const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
        )),
      );
    } else if (ilanlar.isEmpty) {
      listeWidget = SliverToBoxAdapter(
        child: _BosEkran(
          onYenile: () => ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
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
                          Icon(Icons.search_rounded,
                              size: 18,
                              color: _aramaMetni.isNotEmpty
                                  ? AppColors.red
                                  : const Color(0xFFCCCCCC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _aramaCtrl,
                              onChanged: (v) =>
                                  setState(() => _aramaMetni = v),
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (_, _, _) =>
                                        const AramaScreen(),
                                    transitionsBuilder:
                                        (_, anim, _, child) =>
                                            FadeTransition(
                                                opacity: anim,
                                                child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 200),
                                  ),
                                );
                              },
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Güzergah veya ürün ara...',
                                hintStyle: GoogleFonts.dmSans(
                                    color: const Color(0xFFCCCCCC),
                                    fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_aramaMetni.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () {
                                _aramaCtrl.clear();
                                setState(() => _aramaMetni = '');
                              },
                              child: Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCCCCCC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
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
                      child: Text('${kat.emoji} ${kat.ad}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secili ? Colors.white : AppColors.textPrimary,
                          )),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Aktif filtre badge'leri ──
        if (_seciliKategoriYolu.isNotEmpty || _seciliSehir != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                if (_seciliKategoriYolu.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text(
                          app_constants.kategoriYoluMetni(_seciliKategoriYolu),
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
                        onTap: () => setState(() => _seciliKategoriYolu = []),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: AppColors.red),
                      ),
                    ]),
                  ),
                if (_seciliSehir != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_seciliSehir!,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.red,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _seciliSehir = null),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: AppColors.red),
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
      body: RefreshIndicator(
        color: AppColors.red,
        onRefresh: () => ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: header),
            SliverPadding(
              padding: const EdgeInsets.only(top: 10),
              sliver: listeWidget,
            ),
          ],
        ),
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

  const _FiltreKategoriSatiri({
    required this.ad,
    required this.secili,
    required this.onTap,
    this.derinlikOku = false,
    this.vurgulu = false,
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
            Expanded(
              child: Text(
                ad,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: (secili || vurgulu) ? FontWeight.w600 : FontWeight.w400,
                  color: secili ? AppColors.red : AppColors.textPrimary,
                ),
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