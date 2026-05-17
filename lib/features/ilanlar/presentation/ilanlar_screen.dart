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
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';
import 'widgets/filtre_ekrani.dart';
import 'widgets/ilan_karti.dart';
import 'widgets/swipe_karti.dart';

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
    if (pos.pixels >= pos.maxScrollExtent - 120) {
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
    final state      = ref.watch(istekIlanlarProvider);
    final mod        = ref.watch(gridTercihiProvider);
    final ilanlar    = _sirala(_filtrele(state.filtrelenmis));
    final filtrAktif = _seciliAnaKey != null;
    final statusH    = MediaQuery.of(context).padding.top;
    final isSwipe    = mod == GoruntulemeModeli.swipe;

    Widget ilanWidget;
    if (isSwipe) {
      ilanWidget = SwipeGorunumu(
        ilanlar: ilanlar,
        onDahaFazla: () {
          if (!ref.read(istekIlanlarProvider).yukleniyor) {
            ref.read(istekIlanlarProvider.notifier).dahaFazlaYukle();
          }
        },
      );
    } else if (state.yukleniyor && ilanlar.isEmpty) {
      ilanWidget = SliverToBoxAdapter(
          child: ShimmerGrid(kolonSayisi: mod.kolonSayisi));
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
        crossAxisCount: mod.kolonSayisi,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childCount: ilanlar.length,
        itemBuilder: (context, index) => RepaintBoundary(
          key: ValueKey(ilanlar[index].id),
          child: IlanKarti(
            ilan: ilanlar[index],
            resimYukseklikleri: _kResimYukseklikleri,
            kolonSayisi: mod.kolonSayisi,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Ana içerik ─────────────────────────────────────────────────
          Column(
            children: [
              Container(height: statusH, color: Colors.white),

              _IsteklerHeader(
                aramaCtrl: _aramaCtrl,
                aramaMetni: _aramaMetni,
                aramaGizli: _aramaGizli && !isSwipe,
                filtrAktif: filtrAktif,
                filtreBadgeMetni: _filtreBadgeMetni,
                siralama: _siralama,
                seciliAnaKey: _seciliAnaKey,
                onAramaChanged: (v) => setState(() => _aramaMetni = v),
                onAramaSifirla: () {
                  _aramaCtrl.clear();
                  setState(() => _aramaMetni = '');
                },
                onFiltreAc: _filtreAc,
                onSiralamaAc: _siralamaSheet,
                onKategoriSec: _kategoriSec,
                onFiltreSifirla: () => setState(() {
                  _seciliAnaKey = null;
                  _seciliAltKey = null;
                }),
                kategoriScrollCtrl: _kategoriScrollCtrl,
              ),

              Container(height: 0.5, color: AppColors.divider),

              Expanded(
                child: isSwipe
                    ? ilanWidget
                    : RefreshIndicator(
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

          // ── Dikey mod tab — sağda tam orta ────────────────────────────
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
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
      (GoruntulemeModeli.iki,    Icons.grid_view_rounded),
      (GoruntulemeModeli.uc,     Icons.view_module_rounded),
      (GoruntulemeModeli.swipe,  Icons.swipe_left_alt_rounded),
    ];

    // Swipe modunda resmin üzerinde — yarı şeffaf siyah
    // Grid modunda beyaz arka plan üzerinde — açık gri
    final bgRenk = isSwipe
        ? const Color(0x73000000)   // rgba(0,0,0,0.45)
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
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: modlar.map((entry) {
            final (m, ikon) = entry;
            final aktif = mod == m;
            final isLast = m == GoruntulemeModeli.swipe;

            Color ikonRenk;
            Color itemBg;
            if (aktif) {
              ikonRenk = Colors.white;
              itemBg = AppColors.red.withValues(alpha: isSwipe ? 0.8 : 1.0);
            } else {
              ikonRenk = isSwipe
                  ? Colors.white.withValues(alpha: 0.55)
                  : const Color(0xFF888888);
              itemBg = Colors.transparent;
            }

            return GestureDetector(
              onTap: () => onModSec(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 40,
                decoration: BoxDecoration(
                  color: itemBg,
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: borderRenk,
                            width: 0.5,
                          ),
                        ),
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

  static const _hiz = 0.6;
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
    final reduceMotion = SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    _ticker = createTicker(_onTick);
    if (!reduceMotion) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!_ctrl.hasClients) return;
    if (_contentWidth == 0) return;
    _offset += _hiz;
    if (_offset >= _contentWidth) _offset = 0;
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
                  _NedenAyrac(),
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
        Text(metin,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20))),
      ],
    );
  }
}

class _NedenAyrac extends StatelessWidget {
  const _NedenAyrac();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3, height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
          color: Color(0xFF4CAF50), shape: BoxShape.circle),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _IsteklerHeader extends StatelessWidget {
  final TextEditingController aramaCtrl;
  final String aramaMetni;
  final bool aramaGizli;
  final bool filtrAktif;
  final String filtreBadgeMetni;
  final SiralamaTipi siralama;
  final String? seciliAnaKey;
  final ScrollController kategoriScrollCtrl;

  final ValueChanged<String> onAramaChanged;
  final VoidCallback onAramaSifirla;
  final VoidCallback onFiltreAc;
  final VoidCallback onSiralamaAc;
  final ValueChanged<String> onKategoriSec;
  final VoidCallback onFiltreSifirla;

  const _IsteklerHeader({
    required this.aramaCtrl,
    required this.aramaMetni,
    required this.aramaGizli,
    required this.filtrAktif,
    required this.filtreBadgeMetni,
    required this.siralama,
    required this.seciliAnaKey,
    required this.kategoriScrollCtrl,
    required this.onAramaChanged,
    required this.onAramaSifirla,
    required this.onFiltreAc,
    required this.onSiralamaAc,
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

          // Satır 1: Logo + bildirim
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
                  const BildirimCaniWidget(),
                ],
              ),
            ),
          ),
          ),

          // Satır 2: Arama + Filtre
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
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: const Color(0xFFEEEEEE), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(Icons.search_rounded,
                              size: 18,
                              color: aramaMetni.isNotEmpty
                                  ? AppColors.red
                                  : const Color(0xFFCCCCCC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: aramaCtrl,
                              onChanged: onAramaChanged,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Ne getirmemizi istersin?',
                                hintStyle: GoogleFonts.dmSans(
                                    color: const Color(0xFFCCCCCC),
                                    fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (aramaMetni.isNotEmpty) ...[
                            GestureDetector(
                              onTap: onAramaSifirla,
                              child: Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCCCCC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                          GestureDetector(
                            onTap: onSiralamaAc,
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: siralama != SiralamaTipi.enYeni
                                    ? AppColors.red.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.sort_rounded,
                                  size: 17,
                                  color: siralama != SiralamaTipi.enYeni
                                      ? AppColors.red
                                      : const Color(0xFFCCCCCC)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onFiltreAc,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
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

          // Satır 3: Kategori chip'leri
          SizedBox(
            height: 36,
            child: ListView.builder(
              controller: kategoriScrollCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 48, 4), // sağda tab için boşluk
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
                        color: secili ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: secili ? Colors.transparent : const Color(0xFFEEEEEE),
                          width: 1,
                        ),
                        boxShadow: secili ? [BoxShadow(
                          color: const Color(0xFFE53935).withValues(alpha: 0.3),
                          blurRadius: 8, offset: const Offset(0, 2),
                        )] : null,
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
                final kat = kKategoriAgaci[i - 1];
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
                        color: secili ? Colors.transparent : const Color(0xFFEEEEEE),
                        width: 1,
                      ),
                      boxShadow: secili ? [BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )] : null,
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

          // Satır 4: Aktif filtre badge
          if (filtrAktif)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(filtreBadgeMetni,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onFiltreSifirla,
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: AppColors.red),
                    ),
                  ]),
                ),
              ]),
            ),

          // Satır 5: Neden İSTE barı
          const SizedBox(
            height: 28,
            child: _NedenIsteBar(),
          ),
        ],
      ),
    );
  }
}