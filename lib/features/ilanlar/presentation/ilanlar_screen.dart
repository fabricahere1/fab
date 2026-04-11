// lib/features/ilanlar/presentation/ilanlar_screen.dart

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
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';
import '../../../core/cache/app_cache_manager.dart';

// Not: SliverMasonryGrid, flutter_staggered_grid_view paketinin
// SliverMasonryGrid.count constructor'ından gelir — aynı paket.
// Önceki yükseklikler: [160, 200, 140, 180, 220, 150]
// %75'e küçültülmüş (~4cm→3cm hissi):
const _kResimYukseklikleri = [120.0, 150.0, 105.0, 135.0, 165.0, 112.0];

// Kategori barı yüksekliği
const double _kKategoriBarYuksekligi = 46.0;

// Banner yüksekliği
const double _kBannerYuksekligi = 120.0;

// ── Sıralama ──────────────────────────────────────────────────────────────────

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

// ── Ana ekran ─────────────────────────────────────────────────────────────────

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

  SiralamaTipi _siralama    = SiralamaTipi.enYeni;
  String?      _seciliAnaKey;
  String?      _seciliAltKey;
  String       _aramaMetni  = '';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      final state = ref.read(istekIlanlarProvider);
      if (!state.yukleniyor) {
        ref.read(istekIlanlarProvider.notifier).dahaFazlaYukle();
      }
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
        final gecerliKeyler = {anaKat.key, ...anaKat.altlar.map((a) => a.key)};
        sonuc = sonuc.where((i) => gecerliKeyler.contains(i.kategori)).toList();
      } else {
        sonuc = sonuc.where((i) => i.kategori == _seciliAnaKey).toList();
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
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
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

  // ── Kategori barından seçim ─────────────────────────────────────────────────
  void _kategoriSec(String anaKey) {
    setState(() {
      if (_seciliAnaKey == anaKey) {
        // Aynıya tekrar tıklayınca filtre kalkar
        _seciliAnaKey = null;
        _seciliAltKey = null;
      } else {
        _seciliAnaKey = anaKey;
        _seciliAltKey = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state      = ref.watch(istekIlanlarProvider);
    final ilanlar    = _sirala(_filtrele(state.filtrelenmis));
    final filtrAktif = _seciliAnaKey != null;

    // AppBar bottom: arama + (badge) + kategori barı
    final bottomH = 52.0
        + (filtrAktif ? 32.0 : 0.0)
        + _kKategoriBarYuksekligi;

    // İlan içeriği
    Widget ilanWidget;
    if (state.yukleniyor && ilanlar.isEmpty) {
      ilanWidget = const SliverToBoxAdapter(child: _ShimmerGrid());
    } else if (ilanlar.isEmpty) {
      ilanWidget = SliverToBoxAdapter(
        child: filtrAktif || _aramaMetni.isNotEmpty
            ? _FiltreBosBekran(
                onTemizle: () => setState(() {
                  _seciliAnaKey = null;
                  _seciliAltKey = null;
                  _aramaMetni   = '';
                  _aramaCtrl.clear();
                }),
              )
            : _BosEkran(
                onYenile: () =>
                    ref.read(istekIlanlarProvider.notifier).yenile()),
      );
    } else {
      ilanWidget = SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childCount: ilanlar.length,
        itemBuilder: (context, index) => RepaintBoundary(
          child: _IlanKarti(ilan: ilanlar[index]),
        ),
      );
    }

    // AppBar yok — HomeScreen üstleniyor.
    // Scaffold yerine Column + Expanded döndürüyoruz.
    return Scaffold(
      backgroundColor: AppColors.surface,
      // ── Pinned arama + kategori barı ─────────────────────────
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(bottomH),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arama çubuğu + filtre ikonu
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _AramaCubugu(
                        controller: _aramaCtrl,
                        aramaMetni: _aramaMetni,
                        onChanged: (v) => setState(() => _aramaMetni = v),
                        onTemizle: () {
                          _aramaCtrl.clear();
                          setState(() => _aramaMetni = '');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sıralama butonu
                    GestureDetector(
                      onTap: _siralamaSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.sort,
                            color: AppColors.textSecondary, size: 22),
                      ),
                    ),
                    _FiltreButon(aktif: filtrAktif, onTap: _filtreAc),
                  ],
                ),
              ),

              // Aktif filtre badge
              if (filtrAktif)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 14, right: 14, bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _FiltreBadge(
                      metin: _filtreBadgeMetni,
                      onKaldir: () => setState(() {
                        _seciliAnaKey = null;
                        _seciliAltKey = null;
                      }),
                    ),
                  ),
                ),

              // Kategori barı
              _KategoriBar(
                scrollController: _kategoriScrollCtrl,
                seciliKey: _seciliAnaKey,
                onSec: _kategoriSec,
              ),
            ],
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────
      body: RefreshIndicator(
        color: AppColors.red,
        onRefresh: () =>
            ref.read(istekIlanlarProvider.notifier).yenile(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _SlaytBanner()),
            SliverPadding(
              padding: const EdgeInsets.all(6),
              sliver: ilanWidget,
            ),
          ],
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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

// ── Arama Çubuğu ─────────────────────────────────────────────────────────────
// Gri outline yok; hafif gri fill + gölge ile derinlik verildi.

class _AramaCubugu extends StatelessWidget {
  final TextEditingController controller;
  final String aramaMetni;
  final ValueChanged<String> onChanged;
  final VoidCallback onTemizle;

  const _AramaCubugu({
    required this.controller,
    required this.aramaMetni,
    required this.onChanged,
    required this.onTemizle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.dmSans(
            fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'İlanlarda ara...',
          hintStyle: GoogleFonts.dmSans(
              color: AppColors.textHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.textSecondary, size: 18),
          suffixIcon: aramaMetni.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      size: 14, color: AppColors.textSecondary),
                  onPressed: onTemizle,
                  padding: EdgeInsets.zero,
                )
              : null,
          // Tüm border'ları kaldır
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        ),
      ),
    );
  }
}

// ── Filtre Butonu — 2×2 ızgara ikonu ─────────────────────────────────────────

class _FiltreButon extends StatelessWidget {
  final bool aktif;
  final VoidCallback onTap;

  const _FiltreButon({required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 2×2 ızgara — CustomPaint ile çiziyoruz (4 küçük kare)
            CustomPaint(
              size: const Size(20, 20),
              painter: _IzgaraPainter(
                renk: aktif ? AppColors.red : AppColors.textSecondary,
              ),
            ),
            // Aktifse küçük kırmızı nokta
            if (aktif)
              Positioned(
                top: 6,
                right: 6,
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
    );
  }
}

class _IzgaraPainter extends CustomPainter {
  final Color renk;
  const _IzgaraPainter({required this.renk});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = renk
      ..style = PaintingStyle.fill;

    const gap = 3.0;     // kareler arası boşluk
    final kareW = (size.width - gap) / 2;
    final kareH = (size.height - gap) / 2;

    // Sol üst
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, kareW, kareH),
        const Radius.circular(2),
      ),
      paint,
    );
    // Sağ üst
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(kareW + gap, 0, kareW, kareH),
        const Radius.circular(2),
      ),
      paint,
    );
    // Sol alt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, kareH + gap, kareW, kareH),
        const Radius.circular(2),
      ),
      paint,
    );
    // Sağ alt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(kareW + gap, kareH + gap, kareW, kareH),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_IzgaraPainter old) => old.renk != renk;
}

// ── Filtre Badge ──────────────────────────────────────────────────────────────

class _FiltreBadge extends StatelessWidget {
  final String metin;
  final VoidCallback onKaldir;

  const _FiltreBadge({required this.metin, required this.onKaldir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metin,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onKaldir,
            child: const Icon(Icons.close, size: 13, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}

// ── Kategori Barı — yatay kaydırmalı ─────────────────────────────────────────

class _KategoriBar extends StatelessWidget {
  final ScrollController scrollController;
  final String? seciliKey;
  final ValueChanged<String> onSec;

  const _KategoriBar({
    required this.scrollController,
    required this.seciliKey,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kKategoriBarYuksekligi,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: kKategoriAgaci.length,
        itemBuilder: (context, i) {
          final kat    = kKategoriAgaci[i];
          final secili = seciliKey == kat.key;

          return GestureDetector(
            onTap: () => onSec(kat.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: secili ? AppColors.red : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                kat.ad,
                style: GoogleFonts.dmSans(
                  fontSize: 13,                          // önceki: 12 → 13
                  fontWeight: FontWeight.w600,           // her zaman w600 (koyu)
                  color: secili
                      ? Colors.white
                      : const Color(0xFF222222),         // neredeyse siyah
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Slayt Banner ─────────────────────────────────────────────────────────────
// Her slayta farklı network arka plan resmi + koyu overlay + patlama animasyonu.
// Sıkışma efekti kaldırıldı.

class _SlaytBanner extends StatefulWidget {
  const _SlaytBanner();

  @override
  State<_SlaytBanner> createState() => _SlaytBannerState();
}

class _SlaytBannerState extends State<_SlaytBanner>
    with TickerProviderStateMixin {

  // ── Slayt verileri ────────────────────────────────────────────────────────
  static const _slaytlar = [
    (
      satirlar: ['İster Yurtdışından', "Türkiye'ye"],
      resim: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
      // Uçaktan pencere manzarası
    ),
    (
      satirlar: ["İster Türkiye'den", 'Yurtdışına'],
      resim: 'https://images.unsplash.com/photo-1548574505-5e239809ee19?w=800&q=80',
      // Havalimanı koridoru
    ),
    (
      satirlar: ['Sen Nerede', 'Olursan Ol'],
      resim: 'https://images.unsplash.com/photo-1569154941061-e231b4aa8092?w=800&q=80',
      // Gökyüzünde uçak
    ),
    (
      satirlar: ['Nerden', 'İstersen İste'],
      resim: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
      // Bagaj bandı / terminal
    ),
    (
      satirlar: ['Yeterki', 'Sen İste'],
      resim: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
      // Tekrar uçak penceresi
    ),
  ];

  int  _aktif       = 0;
  bool _gecisVar    = false;
  bool _otomatikAktif = true;

  final List<AnimationController> _harfCtrls  = [];
  final List<AnimationController> _sallaCtrls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _girisBaslat());
    _otomatikGecis();
  }

  // ── Animasyon ─────────────────────────────────────────────────────────────
  void _temizle() {
    for (final c in _harfCtrls)  { c.stop(); c.dispose(); }
    for (final c in _sallaCtrls) { c.stop(); c.dispose(); }
    _harfCtrls.clear();
    _sallaCtrls.clear();
  }

  void _girisBaslat() {
    if (!mounted) return;
    _temizle();

    final satirlar = _slaytlar[_aktif].satirlar;
    final List<(int si, int hi)> esleme = [];
    for (int si = 0; si < satirlar.length; si++) {
      int hi = 0;
      for (final ch in satirlar[si].characters) {
        if (ch != ' ') { esleme.add((si, hi)); hi++; }
      }
    }

    for (int i = 0; i < esleme.length; i++) {
      final (_, hi) = esleme[i];
      final delayMs = (hi * 28 + (i * 13) % 100).toInt();
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      );
      _harfCtrls.add(ctrl);
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) ctrl.forward();
      });
    }

    // Sallama
    final sonMs = esleme.isNotEmpty
        ? (esleme.last.$2 * 28 + esleme.length * 13) + 560
        : 560;
    Future.delayed(Duration(milliseconds: sonMs), () {
      if (!mounted) return;
      for (int i = 0; i < _harfCtrls.length; i++) {
        final sc = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 2000 + (i * 41 % 500)),
        )..repeat(reverse: true);
        _sallaCtrls.add(sc);
      }
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  Future<void> _cikisBaslat() async {
    for (int i = _harfCtrls.length - 1; i >= 0; i--) {
      _harfCtrls[i].reverse();
      await Future.delayed(const Duration(milliseconds: 18));
    }
    await Future.delayed(const Duration(milliseconds: 240));
  }

  Future<void> _gecis(int hedef) async {
    if (_gecisVar || !mounted) return;
    _gecisVar = true;
    _otomatikAktif = false;
    await _cikisBaslat();
    if (!mounted) return;
    setState(() => _aktif = hedef);
    _girisBaslat();
    _gecisVar = false;
    _otomatikAktif = true;
    _otomatikGecis();
  }

  void _otomatikGecis() {
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (!mounted || !_otomatikAktif) return;
      _gecis((_aktif + 1) % _slaytlar.length);
    });
  }

  @override
  void dispose() {
    _temizle();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final slayt = _slaytlar[_aktif];

    return SizedBox(
      height: _kBannerYuksekligi,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Arka plan resmi ─────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.network(
              slayt.resim,
              key: ValueKey(slayt.resim),
              fit: BoxFit.cover,
              width: double.infinity,
              height: _kBannerYuksekligi,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFE53935)),
              loadingBuilder: (_, child, prog) => prog == null
                  ? child
                  : Container(color: const Color(0xFF8B0000)),
            ),
          ),

          // ── Koyu overlay — yazılar net okunur ───────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x88000000), // üst %53
                  Color(0xBB000000), // alt %73
                ],
              ),
            ),
          ),

          // ── Yazılar ─────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildSatirlar(),
              ),
            ),
          ),

          // ── Nokta göstergesi ────────────────────────────────────
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slaytlar.length, (i) {
                final secili = i == _aktif;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  secili ? 20 : 5,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: secili ? 0.95 : 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Patlama animasyonlu satırlar ──────────────────────────────────────────
  List<Widget> _buildSatirlar() {
    final satirlar = _slaytlar[_aktif].satirlar;
    final widgets  = <Widget>[];
    int ctrlIdx    = 0;

    for (int si = 0; si < satirlar.length; si++) {
      final satirWidgets = <Widget>[];

      for (final ch in satirlar[si].characters) {
        if (ch == ' ') {
          satirWidgets.add(const SizedBox(width: 6));
          continue;
        }
        if (ctrlIdx >= _harfCtrls.length) { ctrlIdx++; continue; }

        final harfCtrl  = _harfCtrls[ctrlIdx];
        final sallaCtrl = ctrlIdx < _sallaCtrls.length
            ? _sallaCtrls[ctrlIdx]
            : null;

        // Deterministik rastgele yön (patlama)
        final seed   = (si * 31 + ctrlIdx * 17).toDouble();
        final txBase = ((seed * 7.3) % 60) - 30;
        final tyBase = ((seed * 3.7) % 50) + 20;
        ctrlIdx++;

        final girisAnim = CurvedAnimation(
          parent: harfCtrl,
          curve: Curves.elasticOut,
        );

        satirWidgets.add(
          AnimatedBuilder(
            animation: Listenable.merge([
              harfCtrl,
              if (sallaCtrl != null) sallaCtrl,
            ]),
            builder: (_, __) {
              final t          = girisAnim.value;
              final tx         = txBase * (1 - t);
              final ty         = tyBase * (1 - t);
              final scale      = 0.3 + t * 0.7;
              final angle      = ((seed % 40) - 20) / 180 * 3.14 * (1 - t);
              final sallaAngle = (sallaCtrl != null && harfCtrl.isCompleted)
                  ? (sallaCtrl.value - 0.5) * 0.04
                  : 0.0;

              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(tx, ty)
                    ..rotateZ(angle + sallaAngle)
                    ..scale(scale),
                  child: Text(
                    ch,
                    style: GoogleFonts.dmSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                      shadows: const [
                        Shadow(
                          color: Color(0x88000000),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }

      widgets.add(Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: satirWidgets,
      ));
      if (si < satirlar.length - 1) widgets.add(const SizedBox(height: 3));
    }
    return widgets;
  }
}

// ── İlan Kartı ────────────────────────────────────────────────────────────────

class _IlanKarti extends ConsumerWidget {
  final IlanModel ilan;
  const _IlanKarti({required this.ilan});

  double _resimYuksekligi() {
    return _kResimYukseklikleri[ilan.id.hashCode.abs() % _kResimYukseklikleri.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resimler       = ilan.tumResimler;
    final kategoriAdiStr = kategoriAdi(ilan.kategori);
    final uid            = ref.watch(currentUserProvider)?.uid;
    final gosterFavori   = uid != null && uid != ilan.kullaniciId;
    final favoriliIdler  = ref.watch(favoriliIlanIdlerProvider);
    final favorideMi     = gosterFavori && favoriliIdler.contains(ilan.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (_, anim, _, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Resim ────────────────────────────────────────────
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
                          placeholder: (_, _) =>
                              Container(color: AppColors.surface),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(Icons.image_outlined,
                                  color: AppColors.textHint, size: 28),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 28),
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
                                  kullaniciId: uid, ilanId: ilan.id);
                        } else {
                          await ref
                              .read(ilanRepositoryProvider)
                              .favoriyeEkle(
                                  kullaniciId: uid, ilan: ilan);
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
                          color: favorideMi ? AppColors.red : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Alt bilgi ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürün adı
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Nereden → Nereye
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: AppColors.textSecondary),
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
                  const SizedBox(height: 5),

                  // Ücret + kategori chip
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
                            decoration: BoxDecoration(
                              color: AppColors.chipBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
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
                  const SizedBox(height: 5),

                  // ── Değerlendirme satırı ─────────────────────────
                  _DegerlendirmeSatiri(ilan: ilan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Değerlendirme Satırı ──────────────────────────────────────────────────────
// Firestore'dan her kart için ayrı sorgu yapmak yerine ilan sahibinin
// ortalama puanını provider üzerinden okuyoruz.
// Eğer puan henüz yoksa widget render edilmez — extra Firestore okuması yok.

class _DegerlendirmeSatiri extends ConsumerWidget {
  final IlanModel ilan;
  const _DegerlendirmeSatiri({required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(kullaniciBilgiProvider(ilan.kullaniciId));

    return profilAsync.maybeWhen(
      data: (profil) {
        final sayi = profil?.degerlendirmeSayisi ?? 0;
        final puan = profil?.ortalamaPuan ?? 0.0;
        if (sayi == 0) return const SizedBox.shrink();

        return Row(
          children: [
            const Icon(Icons.star_rounded,
                size: 12, color: Color(0xFFFFA726)),
            const SizedBox(width: 2),
            Text(
              puan.toStringAsFixed(1),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '($sayi)',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── Shimmer Grid ──────────────────────────────────────────────────────────────

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
          final h = _kResimYukseklikleri[index % _kResimYukseklikleri.length];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
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
                          height: 11,
                          width: double.infinity,
                          color: Colors.white),
                      const SizedBox(height: 5),
                      Container(height: 9, width: 80, color: Colors.white),
                      const SizedBox(height: 5),
                      Container(height: 11, width: 60, color: Colors.white),
                      const SizedBox(height: 5),
                      Container(height: 10, width: 50, color: Colors.white),
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

// ── Filtre Ekranı ─────────────────────────────────────────────────────────────

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
      case 'giyim':      return Icons.checkroom_outlined;
      case 'elektronik': return Icons.smartphone_outlined;
      case 'guzellik':   return Icons.favorite_border;
      case 'ev':         return Icons.home_outlined;
      case 'spor':       return Icons.sports_soccer_outlined;
      case 'kultur':     return Icons.menu_book_outlined;
      case 'gida':       return Icons.coffee_outlined;
      default:           return Icons.grid_view_outlined;
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
                          fontSize: 16, fontWeight: FontWeight.w700)),
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
                        size: 22, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                itemCount: kKategoriAgaci.length,
                itemBuilder: (ctx, i) {
                  final ana      = kKategoriAgaci[i];
                  final acik     = _acikAnaKey == ana.key;
                  final secili   = widget.seciliAnaKey == ana.key;
                  final altSecili = ana.altlar
                      .any((a) => a.key == widget.seciliAltKey);
                  final vurgulu  = secili || altSecili;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          if (ana.altlar.isEmpty) {
                            widget.onSecildi(ana.key, null);
                          } else {
                            setState(() =>
                                _acikAnaKey = acik ? null : ana.key);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: (secili && !altSecili)
                                ? AppColors.red.withValues(alpha: 0.05)
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
                              Icon(_kategoriIkon(ana.key),
                                  size: 22,
                                  color: vurgulu
                                      ? AppColors.red
                                      : Colors.black87),
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
                                  duration:
                                      const Duration(milliseconds: 200),
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
                                secili: widget.seciliAnaKey == ana.key &&
                                    widget.seciliAltKey == null,
                                onTap: () =>
                                    widget.onSecildi(ana.key, null),
                              ),
                              ...ana.altlar.map((alt) =>
                                  _AltKategoriSatiri(
                                    ad: alt.ad,
                                    secili:
                                        widget.seciliAltKey == alt.key,
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
                  color: secili ? AppColors.red : AppColors.textPrimary,
                ),
              ),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: AppColors.red),
          ],
        ),
      ),
    );
  }
}

// ── Filtre sonucu boş ─────────────────────────────────────────────────────────

class _FiltreBosBekran extends StatelessWidget {
  final VoidCallback onTemizle;
  const _FiltreBosBekran({required this.onTemizle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_outlined,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Sonuç bulunamadı',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Filtre veya aramayı temizlemeyi deneyin',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onTemizle,
            child: Text('Filtreyi Temizle',
                style: GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Boş ekran ─────────────────────────────────────────────────────────────────

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
                style: GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}