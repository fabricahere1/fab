// lib/features/ilanlar/presentation/gelenler_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import '../../../core/cache/app_cache_manager.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';

// ── Sıralama ──────────────────────────────────────────────────────────────────

enum GelenlerSiralama { enYeni, enEski }

// ── Şehirler ──────────────────────────────────────────────────────────────────

const _kSehirler = [
  'İstanbul',
  'Ankara',
  'İzmir',
  'Bursa',
  'Çanakkale',
  'Eskişehir',
  'Antalya',
];

class GelenlerScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const GelenlerScreen({super.key, this.embedded = false});

  @override
  ConsumerState<GelenlerScreen> createState() => _GelenlerScreenState();
}

class _GelenlerScreenState extends ConsumerState<GelenlerScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController   = ScrollController();
  final _aramaCtrl          = TextEditingController();
  final _kategoriScrollCtrl = ScrollController();

  String              _aramaMetni  = '';
  String?             _seciliAnaKey;
  bool                _aramaGizli  = false;
  GelenlerSiralama    _siralama    = GelenlerSiralama.enYeni;
  String?             _seciliSehir;

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
      ref.read(tasiyiciIlanlarProvider.notifier).dahaFazlaYukle();
    }
  }

  List<IlanModel> _filtrele(List<IlanModel> liste) {
    var sonuc = liste;
    if (_seciliAnaKey != null) {
      final anaKat = app_constants.kKategoriAgaci.firstWhere(
        (k) => k.key == _seciliAnaKey,
        orElse: () => app_constants.AnaKategori(key: '', ad: '', emoji: ''),
      );
      if (anaKat.altlar.isNotEmpty) {
        final gecerliKeyler = {anaKat.key, ...anaKat.altlar.map((a) => a.key)};
        sonuc = sonuc.where((i) => gecerliKeyler.contains(i.kategori)).toList();
      } else {
        sonuc = sonuc.where((i) => i.kategori == _seciliAnaKey).toList();
      }
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

  void _kategoriSec(String anaKey) {
    setState(() {
      _seciliAnaKey = _seciliAnaKey == anaKey ? null : anaKey;
    });
  }

  bool get _filtrAktif => _seciliSehir != null || _siralama != GelenlerSiralama.enYeni;

  void _filtreAc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Sıralama ──
                Text('Sıralama', style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FiltreChip(
                      label: 'En Yeni',
                      secili: _siralama == GelenlerSiralama.enYeni,
                      onTap: () => setModalState(
                          () => _siralama = GelenlerSiralama.enYeni),
                    ),
                    const SizedBox(width: 8),
                    _FiltreChip(
                      label: 'En Eski',
                      secili: _siralama == GelenlerSiralama.enEski,
                      onTap: () => setModalState(
                          () => _siralama = GelenlerSiralama.enEski),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Varış Şehri ──
                Text('Varış Şehri', style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FiltreChip(
                      label: 'Tümü',
                      secili: _seciliSehir == null,
                      onTap: () => setModalState(() => _seciliSehir = null),
                    ),
                    ..._kSehirler.map((sehir) => _FiltreChip(
                      label: sehir,
                      secili: _seciliSehir == sehir,
                      onTap: () => setModalState(() => _seciliSehir = sehir),
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Uygula butonu ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
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
                    child: Text('Uygula', style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      listeWidget = SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == ilanlar.length) {
              return state.dahaFazlaVar
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.red),
                      )),
                    )
                  : const SizedBox(height: 80);
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: RepaintBoundary(
                child: _GelenKarti(ilan: ilanlar[index]),
              ),
            );
          },
          childCount: ilanlar.length + 1,
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
                      width: 44,
                      height: 44,
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
        SizedBox(
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
                  onTap: () => setState(() => _seciliAnaKey = null),
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
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE53935)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text('Tümü',
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
              final kat    = app_constants.kKategoriAgaci[i - 1];
              final secili = _seciliAnaKey == kat.key;
              return GestureDetector(
                onTap: () => _kategoriSec(kat.key),
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
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
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

        // ── Aktif filtre badge ──
        if (_seciliSehir != null)
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
            ]),
          ),

        // ── Neden İSTE barı ──
        const SizedBox(
          height: 28,
          child: _NedenIsteBar(),
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

// ── Neden İSTE barı ───────────────────────────────────────────────────────────

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

// ── Yatay Kart ────────────────────────────────────────────────────────────────

class _GelenKarti extends StatelessWidget {
  final IlanModel ilan;
  const _GelenKarti({required this.ilan});

  Color get _aciliyetRenk {
    if (ilan.tarih == null) return AppColors.textSecondary;
    final fark = ilan.tarih!
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
    if (fark <= 1) return AppColors.red;
    if (fark <= 3) return const Color(0xFFE65100);
    return AppColors.green;
  }

  String? get _gelisYazisi {
    if (ilan.tarih == null) return null;
    final bugun = DateTime.now();
    final fark = ilan.tarih!
        .difference(DateTime(bugun.year, bugun.month, bugun.day))
        .inDays;
    if (fark < 0) return 'Geçti';
    if (fark == 0) return 'Bugün';
    if (fark == 1) return 'Yarın';
    return '$fark gün';
  }

  @override
  Widget build(BuildContext context) {
    final resimler     = ilan.tumResimler;
    final gelisYazisi  = _gelisYazisi;
    final aciliyetRenk = _aciliyetRenk;
    final kategori     = app_constants.kategoriAdi(ilan.kategori);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => IlanDetayScreen(ilanId: ilan.id, ilan: ilan),
        ),
      ),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 88,
                height: 88,
                child: resimler.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resimler.first,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: 176,
                        placeholder: (_, _) => _ResimPlaceholder(ilan: ilan),
                        errorWidget: (_, _, _) => _ResimPlaceholder(ilan: ilan),
                      )
                    : _ResimPlaceholder(ilan: ilan),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ilan.urun,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Row(
                      children: [
                        const Icon(Icons.flight_takeoff_rounded,
                            size: 11, color: Color(0xFF64B5F6)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${ilan.nereden} → ${ilan.nereye}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            kategori.replaceAll(RegExp(r'^[^ ]+ '), ''),
                            style: GoogleFonts.dmSans(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),

                        const Spacer(),

                        if (gelisYazisi != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: aciliyetRenk.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              gelisYazisi,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: aciliyetRenk,
                              ),
                            ),
                          ),

                        const SizedBox(width: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resim Placeholder ─────────────────────────────────────────────────────────

class _ResimPlaceholder extends StatelessWidget {
  final IlanModel ilan;
  const _ResimPlaceholder({required this.ilan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight_takeoff_outlined,
              color: Color(0xFF64B5F6), size: 24),
          const SizedBox(height: 4),
          Text(
            ilan.nereden.length > 6
                ? ilan.nereden.substring(0, 6)
                : ilan.nereden,
            style: GoogleFonts.dmSans(
                fontSize: 9,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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