// lib/features/ilanlar/presentation/gelenler_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../presentation/gelenler_form_screen.dart';
import '../presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import '../../../core/cache/app_cache_manager.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';

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

  String  _aramaMetni    = '';
  String? _seciliAnaKey;
  bool    _aramaGizli    = false;

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
      setState(() => _aramaGizli = false);  // hemen göster, en üst bekleme
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
    if (_aramaMetni.isNotEmpty) {
      final q = _aramaMetni.toLowerCase();
      sonuc = sonuc.where((i) =>
          i.urun.toLowerCase().contains(q) ||
          i.nereden.toLowerCase().contains(q) ||
          i.nereye.toLowerCase().contains(q)).toList();
    }
    return sonuc;
  }

  void _kategoriSec(String anaKey) {
    setState(() {
      _seciliAnaKey = _seciliAnaKey == anaKey ? null : anaKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state   = ref.watch(tasiyiciIlanlarProvider);
    final ilanlar = _filtrele(state.filtrelenmis);
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
        // Status bar
        Container(height: statusH, color: Colors.white),

        // Arama çubuğu (scroll'da gizlenir)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
          crossFadeState: _aramaGizli
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
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
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _aramaCtrl,
                            onChanged: (v) =>
                                setState(() => _aramaMetni = v),
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Güzergah veya ürün ara...',
                              hintStyle: GoogleFonts.dmSans(
                                  color: AppColors.textHint, fontSize: 12),
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
                                size: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const BildirimCaniWidget(),
              ],
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),

        // Kategori barı (her zaman görünür)
        Container(
          height: 40,
          color: Colors.white,
          child: ListView.builder(
            controller: _kategoriScrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: app_constants.kKategoriAgaci.length,
            itemBuilder: (context, i) {
              final kat    = app_constants.kKategoriAgaci[i];
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

        Container(height: 0.5, color: AppColors.divider),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GelenlerFormScreen()),
        ),
        backgroundColor: AppColors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('İlan Ver',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Yatay Kart — sol çizgi + resim + detaylar ────────────────────────────────

class _GelenKarti extends StatelessWidget {
  final IlanModel ilan;
  const _GelenKarti({required this.ilan});

  // Aciliyet rengi
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
        PageRouteBuilder(
          pageBuilder: (_, _, _) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (_, anim, _, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0), end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
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
            // ── Resim ─────────────────────────────────────────
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
                        memCacheWidth: 176,
                        placeholder: (_, _) => _ResimPlaceholder(ilan: ilan),
                        errorWidget: (_, _, _) =>
                            _ResimPlaceholder(ilan: ilan),
                      )
                    : _ResimPlaceholder(ilan: ilan),
              ),
            ),

            // ── İçerik ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ürün adı
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

                    // Güzergah
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

                    // Alt satır: kategori + tarih + fiyat
                    Row(
                      children: [
                        // Kategori chip
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

                        // Tarih badge
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

                        // Fiyat
                        Text(
                          '${ilan.ucret} ₺',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                          ),
                        ),
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
