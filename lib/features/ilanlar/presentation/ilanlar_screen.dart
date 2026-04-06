import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../domain/ilan_model.dart';
import '../data/ilan_repository.dart';
import '../providers/ilan_provider.dart';
import '../presentation/ilan_form_screen.dart';
import '../presentation/ilan_detay_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';
import '../../../core/cache/app_cache_manager.dart';

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

class IsteklerScreen extends ConsumerStatefulWidget {
  const IsteklerScreen({super.key});

  @override
  ConsumerState<IsteklerScreen> createState() => _IsteklerScreenState();
}

class _IsteklerScreenState extends ConsumerState<IsteklerScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _aramaCtrl = TextEditingController();
  SiralamaTipi _siralama = SiralamaTipi.enYeni;
  String? _seciliAnaKey;
  String? _seciliAltKey;
  String _aramaMetni = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _aramaCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(istekIlanlarProvider.notifier).dahaFazlaYukle();
    }
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
        final gecerliKeyler = {
          anaKat.key,
          ...anaKat.altlar.map((a) => a.key)
        };
        sonuc =
            sonuc.where((i) => gecerliKeyler.contains(i.kategori)).toList();
      } else {
        sonuc =
            sonuc.where((i) => i.kategori == _seciliAnaKey).toList();
      }
    }
    if (_aramaMetni.isNotEmpty) {
      final q = _aramaMetni.toLowerCase();
      sonuc = sonuc
          .where((i) =>
              i.urun.toLowerCase().contains(q) ||
              i.nereden.toLowerCase().contains(q) ||
              i.nereye.toLowerCase().contains(q) ||
              i.notlar.toLowerCase().contains(q))
          .toList();
    }
    return sonuc;
  }

  void _filtreAc() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filtre kapat',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: Material(
            color: Colors.transparent,
            child: _FiltreEkrani(
              seciliAnaKey: _seciliAnaKey,
              seciliAltKey: _seciliAltKey,
              onSecildi: (anaKey, altKey) {
                setState(() {
                  _seciliAnaKey = anaKey;
                  _seciliAltKey = altKey;
                });
                Navigator.of(ctx).pop();
              },
              onTemizle: () {
                setState(() {
                  _seciliAnaKey = null;
                  _seciliAltKey = null;
                });
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(istekIlanlarProvider);
    final ilanlar = _sirala(_filtrele(state.filtrelenmis));
    final filtrAktif = _seciliAnaKey != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('İstekler',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
        actions: [
          const BildirimCaniWidget(),
          TextButton.icon(
            onPressed: _siralamaSheet,
            icon: const Icon(Icons.sort,
                color: AppColors.textPrimary, size: 18),
            label: Text(
              _siralama.label.split(':').first,
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(filtrAktif ? 88 : 52),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _aramaCtrl,
                            onChanged: (v) =>
                                setState(() => _aramaMetni = v),
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'İlanlarda ara...',
                              hintStyle: GoogleFonts.dmSans(
                                  color: AppColors.textHint,
                                  fontSize: 13),
                              prefixIcon: const Icon(Icons.search,
                                  color: AppColors.textSecondary,
                                  size: 18),
                              suffixIcon: _aramaMetni.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 14,
                                          color:
                                              AppColors.textSecondary),
                                      onPressed: () {
                                        _aramaCtrl.clear();
                                        setState(
                                            () => _aramaMetni = '');
                                      },
                                      padding: EdgeInsets.zero,
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _filtreAc,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 22,
                                color: filtrAktif
                                    ? AppColors.red
                                    : AppColors.textSecondary,
                              ),
                              if (filtrAktif)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (filtrAktif)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _filtreBadgeMetni,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _seciliAnaKey = null;
                                  _seciliAltKey = null;
                                }),
                                child: const Icon(Icons.close,
                                    size: 13, color: AppColors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: state.yukleniyor && ilanlar.isEmpty
          ? const _ShimmerGrid()
          : ilanlar.isEmpty
              ? _BosEkran(
                  onYenile: () =>
                      ref.read(istekIlanlarProvider.notifier).yenile())
              : RefreshIndicator(
                  color: AppColors.red,
                  onRefresh: () =>
                      ref.read(istekIlanlarProvider.notifier).yenile(),
                  child: MasonryGridView.count(
                    controller: _scrollController,
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    padding: const EdgeInsets.all(6),
                    cacheExtent: 500,
                    itemCount: ilanlar.length,
                    itemBuilder: (context, index) => RepaintBoundary(
                      child: _IlanKarti(ilan: ilanlar[index]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const IlanFormScreen(tip: IlanTip.istek),
          ),
        ),
        backgroundColor: AppColors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('İlan Ver',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _siralamaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Sırala',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...SiralamaTipi.values.map((tip) {
                final secili = _siralama == tip;
                return InkWell(
                  onTap: () {
                    setState(() => _siralama = tip);
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(tip.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                color: secili
                                    ? AppColors.red
                                    : AppColors.textPrimary,
                                fontWeight: secili
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              )),
                        ),
                        if (secili)
                          const Icon(Icons.check,
                              color: AppColors.red, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filtre Ekranı ─────────────────────────────────────────

class _FiltreEkrani extends StatefulWidget {
  final String? seciliAnaKey;
  final String? seciliAltKey;
  final void Function(String? anaKey, String? altKey) onSecildi;
  final VoidCallback onTemizle;

  const _FiltreEkrani({
    required this.seciliAnaKey,
    required this.seciliAltKey,
    required this.onSecildi,
    required this.onTemizle,
  });

  @override
  State<_FiltreEkrani> createState() => _FiltreEkraniState();
}

class _FiltreEkraniState extends State<_FiltreEkrani> {
  String? _acikAnaKey;

  @override
  void initState() {
    super.initState();
    _acikAnaKey = widget.seciliAnaKey;
  }

  IconData _kategoriIkon(String key) {
    switch (key) {
      case 'giyim':     return Icons.checkroom_outlined;
      case 'elektronik': return Icons.smartphone_outlined;
      case 'guzellik':  return Icons.favorite_border;
      case 'ev':        return Icons.home_outlined;
      case 'spor':      return Icons.sports_soccer_outlined;
      case 'kultur':    return Icons.menu_book_outlined;
      case 'gida':      return Icons.coffee_outlined;
      default:          return Icons.grid_view_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text('Kategori',
                      style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (widget.seciliAnaKey != null)
                    GestureDetector(
                      onTap: widget.onTemizle,
                      child: Text('Temizle',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        size: 22,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                itemCount: kKategoriAgaci.length,
                itemBuilder: (ctx, i) {
                  final ana = kKategoriAgaci[i];
                  final acik = _acikAnaKey == ana.key;
                  final secili = widget.seciliAnaKey == ana.key;
                  final altSecili = ana.altlar
                      .any((a) => a.key == widget.seciliAltKey);
                  final vurgulu = secili || altSecili;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          if (ana.altlar.isEmpty) {
                            widget.onSecildi(ana.key, null);
                          } else {
                            setState(() => _acikAnaKey =
                                acik ? null : ana.key);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: (secili && !altSecili)
                                ? AppColors.red
                                    .withValues(alpha: 0.05)
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider
                                    .withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _kategoriIkon(ana.key),
                                size: 22,
                                color: vurgulu
                                    ? AppColors.red
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  ana.ad,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: vurgulu
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: vurgulu
                                        ? AppColors.red
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (ana.altlar.isNotEmpty)
                                AnimatedRotation(
                                  turns: acik ? 0.25 : 0,
                                  duration: const Duration(
                                      milliseconds: 200),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: acik
                                        ? AppColors.red
                                        : AppColors.textSecondary,
                                  ),
                                )
                              else
                                const Icon(Icons.chevron_right,
                                    size: 20,
                                    color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      if (acik && ana.altlar.isNotEmpty)
                        Container(
                          color: AppColors.surface,
                          child: Column(
                            children: [
                              _AltKategoriSatiri(
                                ad: 'Tümü',
                                secili:
                                    widget.seciliAnaKey == ana.key &&
                                        widget.seciliAltKey == null,
                                onTap: () =>
                                    widget.onSecildi(ana.key, null),
                              ),
                              ...ana.altlar.map((alt) =>
                                  _AltKategoriSatiri(
                                    ad: alt.ad,
                                    secili: widget.seciliAltKey ==
                                        alt.key,
                                    onTap: () => widget.onSecildi(
                                        ana.key, alt.key),
                                  )),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AltKategoriSatiri extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;

  const _AltKategoriSatiri({
    required this.ad,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(
            left: 58, right: 20, top: 13, bottom: 13),
        decoration: BoxDecoration(
          color: secili
              ? AppColors.red.withValues(alpha: 0.05)
              : Colors.transparent,
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
                  fontWeight:
                      secili ? FontWeight.w600 : FontWeight.w400,
                  color: secili
                      ? AppColors.red
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (secili)
              const Icon(Icons.check,
                  size: 16, color: AppColors.red),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Grid ──────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        padding: const EdgeInsets.all(6),
        itemCount: 6,
        itemBuilder: (context, index) {
          final heights = [160.0, 200.0, 140.0, 180.0, 220.0, 150.0];
          final h = heights[index % heights.length];
          return Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: h, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 12,
                          width: double.infinity,
                          color: Colors.white),
                      const SizedBox(height: 6),
                      Container(
                          height: 10, width: 80, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(
                          height: 12, width: 60, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── İlan Kartı ────────────────────────────────────────────

class _IlanKarti extends ConsumerWidget {
  final IlanModel ilan;
  const _IlanKarti({required this.ilan, super.key});

  double _resimYuksekligi() {
    final heights = [160.0, 200.0, 140.0, 180.0, 220.0, 150.0];
    return heights[ilan.id.hashCode.abs() % heights.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resimler = ilan.tumResimler;
    final kategoriAdiStr = kategoriAdi(ilan.kategori);
    final uid = ref.watch(currentUserProvider)?.uid;
    final gosterFavori = uid != null && uid != ilan.kullaniciId;
    final favoriliIdler = ref.watch(favoriliIlanIdlerProvider);
    final favorideMi =
        gosterFavori && favoriliIdler.contains(ilan.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: _resimYuksekligi(),
                  width: double.infinity,
                  child: resimler.isNotEmpty
                      ? CachedNetworkImage(
                          cacheManager: AppCacheManager.instance,
                          imageUrl: resimler.first,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          memCacheWidth: 400,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(Icons.image_outlined,
                                  color: AppColors.textHint,
                                  size: 32),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 32),
                          ),
                        ),
                ),
                if (gosterFavori)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        if (favorideMi) {
                          await ref
                              .read(ilanRepositoryProvider)
                              .favoridanCikar(
                                kullaniciId: uid,
                                ilanId: ilan.id,
                              );
                        } else {
                          await ref
                              .read(ilanRepositoryProvider)
                              .favoriyeEkle(
                                kullaniciId: uid,
                                ilan: ilan,
                              );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favorideMi
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: favorideMi
                              ? AppColors.red
                              : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${ilan.nereden} → ${ilan.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ilan.ucret.isNotEmpty
                              ? '${ilan.ucret} ₺'
                              : 'Belirtilmemiş',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: ilan.ucret.isNotEmpty
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: ilan.ucret.isNotEmpty
                                ? AppColors.red
                                : AppColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (kategoriAdiStr.isNotEmpty)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            color: AppColors.chipBg,
                            child: Text(
                              kategoriAdiStr,
                              style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Boş ekran ─────────────────────────────────────────────

class _BosEkran extends StatelessWidget {
  final VoidCallback onYenile;
  const _BosEkran({required this.onYenile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Henüz ilan yok',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('İlk ilanı sen ver!',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onYenile,
            child: Text('Yenile',
                style:
                    GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}