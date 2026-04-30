// lib/features/ilanlar/presentation/ilanlar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../providers/grid_tercihi_notifier.dart';
import '../presentation/ilan_form_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';
import 'widgets/filtre_ekrani.dart';
import 'widgets/ilan_karti.dart';

const _kResimYukseklikleri = [120.0, 150.0, 105.0, 135.0, 165.0, 112.0];

enum SiralamaTipi { enYeni, enEski, ucretArtan, ucretAzalan }

extension SiralamaTipiX on SiralamaTipi {
  String get label {
    switch (this) {
      case SiralamaTipi.enYeni:      return 'En yeni';
      case SiralamaTipi.enEski:      return 'En eski';
      case SiralamaTipi.ucretArtan:  return 'Ücret: Düşük → Yüksek';
      case SiralamaTipi.ucretAzalan: return 'Ücret: Yüksek → Düşük';
    }
  }
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

  SiralamaTipi _siralama   = SiralamaTipi.enYeni;
  String?      _seciliAnaKey;
  String?      _seciliAltKey;
  String       _aramaMetni = '';
  bool         _aramaGizli = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.userScrollDirection == ScrollDirection.reverse && !_aramaGizli) {
      setState(() => _aramaGizli = true);
    } else if (pos.userScrollDirection == ScrollDirection.forward && _aramaGizli) {
      setState(() => _aramaGizli = false);
    }
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      if (!ref.read(istekIlanlarProvider).yukleniyor) {
        ref.read(istekIlanlarProvider.notifier).dahaFazlaYukle();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _aramaCtrl.dispose();
    _kategoriScrollCtrl.dispose();
    super.dispose();
  }

  String get _filtreBadgeMetni {
    if (_seciliAnaKey == null) return '';
    final ana = kKategoriAgaci.firstWhere(
      (k) => k.key == _seciliAnaKey,
      orElse: () => AnaKategori(key: '', ad: '', emoji: ''),
    );
    if (_seciliAltKey != null) {
      final alt = ana.altlar.firstWhere(
        (a) => a.key == _seciliAltKey,
        orElse: () => AltKategori(key: '', ad: ''),
      );
      if (alt.key.isNotEmpty) return alt.ad;
    }
    return ana.ad;
  }

  List<IlanModel> _sirala(List<IlanModel> liste) {
    final kopya = List<IlanModel>.from(liste);
    switch (_siralama) {
      case SiralamaTipi.enYeni:
        kopya.sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
            .compareTo(a.olusturmaTarihi ?? DateTime(0)));
      case SiralamaTipi.enEski:
        kopya.sort((a, b) => (a.olusturmaTarihi ?? DateTime(0))
            .compareTo(b.olusturmaTarihi ?? DateTime(0)));
      case SiralamaTipi.ucretArtan:
        kopya.sort((a, b) {
          final aU = double.tryParse(a.ucret) ?? 0;
          final bU = double.tryParse(b.ucret) ?? 0;
          return aU.compareTo(bU);
        });
      case SiralamaTipi.ucretAzalan:
        kopya.sort((a, b) {
          final aU = double.tryParse(a.ucret) ?? 0;
          final bU = double.tryParse(b.ucret) ?? 0;
          return bU.compareTo(aU);
        });
    }
    return kopya;
  }

  List<IlanModel> _filtrele(List<IlanModel> liste) {
    var sonuc = liste;
    if (_seciliAltKey != null) {
      sonuc = sonuc.where((i) => i.kategori == _seciliAltKey).toList();
    } else if (_seciliAnaKey != null) {
      final anaKat = kKategoriAgaci.firstWhere(
        (k) => k.key == _seciliAnaKey,
        orElse: () => AnaKategori(key: '', ad: '', emoji: ''),
      );
      if (anaKat.altlar.isNotEmpty) {
        final gecerliKeyler = {anaKat.key, ...anaKat.altlar.map((a) => a.key)};
        sonuc = sonuc.where((i) => gecerliKeyler.contains(i.kategori)).toList();
      } else {
        sonuc = sonuc.where((i) => i.kategori == _seciliAnaKey).toList();
      }
    }
    if (_aramaMetni.isNotEmpty) {
      final q = _aramaMetni.toLowerCase();
      sonuc = sonuc.where((i) =>
          i.urun.toLowerCase().contains(q) ||
          i.nereden.toLowerCase().contains(q) ||
          i.nereye.toLowerCase().contains(q) ||
          i.notlar.toLowerCase().contains(q)).toList();
    }
    return sonuc;
  }

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
              seciliAnaKey: _seciliAnaKey,
              seciliAltKey: _seciliAltKey,
              onSecildi: (anaKey, altKey) {
                setState(() { _seciliAnaKey = anaKey; _seciliAltKey = altKey; });
                Navigator.of(ctx).pop();
              },
              onTemizle: () {
                setState(() { _seciliAnaKey = null; _seciliAltKey = null; });
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _siralamaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Sırala', style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...SiralamaTipi.values.map((tip) {
                final secili = _siralama == tip;
                return InkWell(
                  onTap: () { setState(() => _siralama = tip); Navigator.pop(ctx); },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      Expanded(child: Text(tip.label, style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: secili ? AppColors.red : AppColors.textPrimary,
                          fontWeight: secili ? FontWeight.w600 : FontWeight.w400))),
                      if (secili) const Icon(Icons.check, color: AppColors.red, size: 20),
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _kategoriSec(String anaKey) {
    setState(() {
      if (_seciliAnaKey == anaKey) { _seciliAnaKey = null; _seciliAltKey = null; }
      else { _seciliAnaKey = anaKey; _seciliAltKey = null; }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state       = ref.watch(istekIlanlarProvider);
    final kolonSayisi = ref.watch(gridTercihiProvider);
    final ilanlar     = _sirala(_filtrele(state.filtrelenmis));
    final filtrAktif  = _seciliAnaKey != null;
    final statusH     = MediaQuery.of(context).padding.top;

    Widget ilanWidget;
    if (state.yukleniyor && ilanlar.isEmpty) {
      ilanWidget = SliverToBoxAdapter(child: ShimmerGrid(kolonSayisi: kolonSayisi));
    } else if (ilanlar.isEmpty) {
      ilanWidget = SliverToBoxAdapter(
        child: filtrAktif || _aramaMetni.isNotEmpty
            ? FiltreBosBekran(onTemizle: () => setState(() {
                _seciliAnaKey = null; _seciliAltKey = null;
                _aramaMetni = ''; _aramaCtrl.clear();
              }))
            : BosEkran(onYenile: () =>
                ref.read(istekIlanlarProvider.notifier).yenile()),
      );
    } else {
      ilanWidget = SliverMasonryGrid.count(
        crossAxisCount: kolonSayisi,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childCount: ilanlar.length,
        itemBuilder: (context, index) => RepaintBoundary(
          child: IlanKarti(
            ilan: ilanlar[index],
            resimYukseklikleri: _kResimYukseklikleri,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [

          // ── Status bar ────────────────────────────────────────────────
          Container(height: statusH, color: Colors.white),

          // ── Arama çubuğu + Neden İSTE (scroll'da tamamen gizlenir) ───
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: _aramaGizli
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arama satırı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFE8E8E8), width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                const Icon(Icons.search_rounded,
                                    size: 15,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: _aramaCtrl,
                                    onChanged: (v) =>
                                        setState(() => _aramaMetni = v),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'Ne getirmemizi istersin?',
                                      hintStyle: GoogleFonts.dmSans(
                                          color: AppColors.textHint,
                                          fontSize: 12),
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
                                    child: const Icon(Icons.close_rounded,
                                        size: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Container(
                                    width: 0.5,
                                    height: 14,
                                    color: const Color(0xFFDDDDDD)),
                                _ToolBtn(
                                  onTap: _siralamaSheet,
                                  aktif: _siralama != SiralamaTipi.enYeni,
                                  child: const Icon(Icons.sort_rounded, size: 15),
                                ),
                                _ToolBtn(
                                  onTap: () => ref
                                      .read(gridTercihiProvider.notifier)
                                      .degistir(kolonSayisi == 2 ? 3 : 2),
                                  aktif: kolonSayisi == 3,
                                  child: Icon(
                                    kolonSayisi == 2
                                        ? Icons.grid_view_rounded
                                        : Icons.view_column_rounded,
                                    size: 15,
                                  ),
                                ),
                                _ToolBtn(
                                  onTap: _filtreAc,
                                  aktif: filtrAktif,
                                  child: const Icon(Icons.tune_rounded, size: 15),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const BildirimCaniWidget(),
                      ],
                    ),
                  ),

                  // Neden İSTE barı — kayan yazı
                  const _NedenIsteBar(),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),

          // ── Kategori barı (her zaman görünür) ─────────────────────────
          Container(
            height: 40,
            color: Colors.white,
            child: ListView.builder(
              controller: _kategoriScrollCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: kKategoriAgaci.length,
              itemBuilder: (context, i) {
                final kat    = kKategoriAgaci[i];
                final secili = _seciliAnaKey == kat.key;
                return GestureDetector(
                  onTap: () => _kategoriSec(kat.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: secili ? AppColors.red : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(kat.ad,
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

          // Aktif filtre badge
          if (filtrAktif)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_filtreBadgeMetni,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() {
                        _seciliAnaKey = null; _seciliAltKey = null;
                      }),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: AppColors.red),
                    ),
                  ]),
                ),
              ]),
            ),

          Container(height: 0.5, color: AppColors.divider),

          // ── İlan listesi ──────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.red,
              onRefresh: () =>
                  ref.read(istekIlanlarProvider.notifier).yenile(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(6),
                    sliver: ilanWidget,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) =>
                const IlanFormScreen(tip: IlanTip.istek))),
        backgroundColor: AppColors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('İlan Ver',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Araç butonu ───────────────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool aktif;
  const _ToolBtn({required this.onTap, required this.child, this.aktif = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: aktif
              ? AppColors.red.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: IconTheme(
          data: IconThemeData(
              color: aktif ? AppColors.red : AppColors.textSecondary,
              size: 15),
          child: child,
        ),
      ),
    );
  }
}

// ── Neden İSTE — kayan yazı ───────────────────────────────────────────────────

class _NedenIsteBar extends StatefulWidget {
  const _NedenIsteBar();

  @override
  State<_NedenIsteBar> createState() => _NedenIsteBarState();
}

class _NedenIsteBarState extends State<_NedenIsteBar>
    with SingleTickerProviderStateMixin {
  late final ScrollController _ctrl;
  late final Ticker _ticker;
  double _offset = 0;
  double _contentWidth = 0;

  static const _hiz = 0.6; // piksel/ms
  static const _maddeler = [
    'Güvenli alışveriş',
    'Onaylı taşıyıcılar',
    'Uygun fiyat',
    'Kolay iade',
    'Hızlı teslimat',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_ctrl.hasClients) return;
    if (_contentWidth == 0) return;

    _offset += _hiz;
    if (_offset >= _contentWidth) {
      _offset = 0;
    }
    _ctrl.jumpTo(_offset);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFC8E6C9),
      height: 28,
      child: LayoutBuilder(builder: (context, constraints) {
        // İçerik genişliğini hesapla — her madde ~120px, ayraç ~16px
        _contentWidth =
            (_maddeler.length * 120.0 + _maddeler.length * 16.0);

        return SingleChildScrollView(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var r = 0; r < 3; r++) ...[
                for (final m in _maddeler) ...[
                  const SizedBox(width: 16),
                  _NedenItem(metin: m),
                  const _NedenAyrac(),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _NedenItem extends StatelessWidget {
  final String metin;
  const _NedenItem({required this.metin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 12, color: Color(0xFF388E3C)),
        const SizedBox(width: 4),
        Text(
          metin,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }
}

class _NedenAyrac extends StatelessWidget {
  const _NedenAyrac();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
          color: Color(0xFF4CAF50), shape: BoxShape.circle),
    );
  }
}
