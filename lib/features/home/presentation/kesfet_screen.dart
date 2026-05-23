// lib/features/home/presentation/kesfet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/ilanlar/data/ilan_repository.dart';
import 'package:iste_v3/features/auth/providers/auth_provider.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/core/cache/app_cache_manager.dart';

class KesfetScreen extends ConsumerStatefulWidget {
  const KesfetScreen({super.key});

  @override
  ConsumerState<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends ConsumerState<KesfetScreen> {
  final PageController _pageCtrl = PageController();
  String _aktifTab = 'istek'; // 'istek' | 'tasiyici'

  @override
  void initState() {
    super.initState();
    // Tam ekran karanlık — status bar ikonları beyaz olsun
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final istekler    = ref.watch(istekIlanlarProvider).filtrelenmis;
    final tasiyicilar = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
    final ilanlar     = _aktifTab == 'istek' ? istekler : tasiyicilar;

    if (ilanlar.isEmpty) {
      return _BosEkran(
        aktifTab: _aktifTab,
        onTabDegis: (t) => setState(() => _aktifTab = t),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageCtrl,
        scrollDirection: Axis.vertical,
        itemCount: ilanlar.length,
        itemBuilder: (context, index) {
          return _IlanKart(
            ilan:      ilanlar[index],
            aktifTab:  _aktifTab,
            toplamSayi: ilanlar.length,
            simdikiIndex: index,
            onTabDegis: (t) {
              setState(() => _aktifTab = t);
              _pageCtrl.jumpToPage(0);
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Boş ekran
// ─────────────────────────────────────────────────────────────────────────────

class _BosEkran extends StatelessWidget {
  final String aktifTab;
  final ValueChanged<String> onTabDegis;
  const _BosEkran({required this.aktifTab, required this.onTabDegis});

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: statusH),
          _UstBar(
            aktifTab: aktifTab,
            onTabDegis: onTabDegis,
            toplamSayi: 0,
            simdikiIndex: 0,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 14),
                  Text(
                    'Henüz ilan yok',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tek İlan Kartı — tam ekran
// ─────────────────────────────────────────────────────────────────────────────

class _IlanKart extends ConsumerStatefulWidget {
  final IlanModel ilan;
  final String aktifTab;
  final int toplamSayi;
  final int simdikiIndex;
  final ValueChanged<String> onTabDegis;

  const _IlanKart({
    required this.ilan,
    required this.aktifTab,
    required this.toplamSayi,
    required this.simdikiIndex,
    required this.onTabDegis,
  });

  @override
  ConsumerState<_IlanKart> createState() => _IlanKartState();
}

class _IlanKartState extends ConsumerState<_IlanKart>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  bool _localFavori = false;
  bool _islemYapiliyor = false;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut),
    );

    // Favori durumunu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid          = ref.read(currentUserProvider)?.uid;
      final favoriliIdler = ref.read(favoriliIlanIdlerProvider);
      if (uid != null && mounted) {
        setState(() {
          _localFavori = favoriliIdler.contains(widget.ilan.id);
        });
      }
    });
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _favoriToggle() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null || _islemYapiliyor) return;
    if (uid == widget.ilan.kullaniciId) return;

    _islemYapiliyor = true;
    setState(() => _localFavori = !_localFavori);
    _heartCtrl.forward(from: 0);

    try {
      final repo = ref.read(ilanRepositoryProvider);
      if (_localFavori) {
        await repo.favoriyeEkle(kullaniciId: uid, ilan: widget.ilan);
      } else {
        await repo.favoridanCikar(kullaniciId: uid, ilanId: widget.ilan.id);
      }
    } catch (_) {
      if (mounted) setState(() => _localFavori = !_localFavori);
    } finally {
      _islemYapiliyor = false;
    }
  }

  void _ilanDetayGit() {
    ref.read(sonGoruntulenenlerProvider.notifier).kaydet(widget.ilan);
    context.push(AppRoutes.ilanDetayPath(widget.ilan.id), extra: widget.ilan);
  }

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final ilan    = widget.ilan;
    final resimler = ilan.tumResimler;
    final katAdi  = kategoriAdi(ilan.kategori);
    final uid     = ref.watch(currentUserProvider)?.uid;
    final kendi   = uid == ilan.kullaniciId;

    return GestureDetector(
      onTap: _ilanDetayGit,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── Arka plan resim ───────────────────────────────────────────
            resimler.isNotEmpty
                ? CachedNetworkImage(
                    cacheManager: AppCacheManager.instance,
                    imageUrl: resimler.first,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    errorWidget: (_, _, _) => _DegiskenArkaplan(ilan: ilan),
                  )
                : _DegiskenArkaplan(ilan: ilan),

            // ── Koyu gradient overlay ─────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC000000),
                    Color(0xEE000000),
                  ],
                  stops: [0.0, 0.15, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            // ── Üst bar ───────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: _UstBar(
                aktifTab: widget.aktifTab,
                onTabDegis: widget.onTabDegis,
                toplamSayi: widget.toplamSayi,
                simdikiIndex: widget.simdikiIndex,
              ),
            ),

            // ── Sağ aksiyonlar ────────────────────────────────────────────
            if (!kendi)
              Positioned(
                right: 12,
                bottom: 110,
                child: _SagAksiyonlar(
                  localFavori:  _localFavori,
                  heartScale:   _heartScale,
                  onFavori:     _favoriToggle,
                  onDetay:      _ilanDetayGit,
                  favoriSayisi: ilan.favoriSayisi,
                ),
              ),

            // ── Alt içerik ────────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: kendi ? 0 : 70,
              child: _AltIcerik(
                ilan:   ilan,
                katAdi: katAdi,
                onIste: _ilanDetayGit,
                kendi:  kendi,
              ),
            ),

            // ── Swipe hint ────────────────────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 0, right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_up_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 3),
                    Text(
                      'Sonraki ilan',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Üst Bar — logo + tab'lar + progress
// ─────────────────────────────────────────────────────────────────────────────

class _UstBar extends StatelessWidget {
  final String aktifTab;
  final ValueChanged<String> onTabDegis;
  final int toplamSayi;
  final int simdikiIndex;

  const _UstBar({
    required this.aktifTab,
    required this.onTabDegis,
    required this.toplamSayi,
    required this.simdikiIndex,
  });

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(14, statusH + 10, 14, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x88000000), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + tab'lar
          Row(
            children: [
              Text(
                'Keşfet',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              _TabButon(
                label: 'Taşıyıcı',
                aktif: aktifTab == 'tasiyici',
                onTap: () => onTabDegis('tasiyici'),
              ),
              const SizedBox(width: 16),
              _TabButon(
                label: 'İstek',
                aktif: aktifTab == 'istek',
                onTap: () => onTabDegis('istek'),
              ),
            ],
          ),
          // Progress çubukları
          if (toplamSayi > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                toplamSayi.clamp(0, 8),
                (i) => Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: i <= simdikiIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TabButon extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;
  const _TabButon({required this.label, required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
              color: aktif
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          if (aktif) ...[
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sağ Aksiyonlar
// ─────────────────────────────────────────────────────────────────────────────

class _SagAksiyonlar extends StatelessWidget {
  final bool localFavori;
  final Animation<double> heartScale;
  final VoidCallback onFavori;
  final VoidCallback onDetay;
  final int favoriSayisi;

  const _SagAksiyonlar({
    required this.localFavori,
    required this.heartScale,
    required this.onFavori,
    required this.onDetay,
    required this.favoriSayisi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // İste / Favori
        _AksiyonButon(
          icon: ScaleTransition(
            scale: heartScale,
            child: Icon(
              localFavori ? Icons.favorite : Icons.favorite_border,
              color: localFavori ? AppColors.red : Colors.white,
              size: 24,
            ),
          ),
          label: localFavori ? 'Kaydedildi' : 'İste',
          onTap: onFavori,
          renk: localFavori ? AppColors.red : null,
        ),
        const SizedBox(height: 18),

        // Detay
        _AksiyonButon(
          icon: Icon(Icons.info_outline_rounded,
              color: Colors.white, size: 22),
          label: 'Detay',
          onTap: onDetay,
        ),
        const SizedBox(height: 18),

        // Paylaş
        _AksiyonButon(
          icon: Icon(Icons.share_outlined,
              color: Colors.white, size: 22),
          label: 'Paylaş',
          onTap: () {},
        ),
      ],
    );
  }
}

class _AksiyonButon extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color? renk;

  const _AksiyonButon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: renk != null
                  ? renk!.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alt İçerik
// ─────────────────────────────────────────────────────────────────────────────

class _AltIcerik extends StatelessWidget {
  final IlanModel ilan;
  final String katAdi;
  final VoidCallback onIste;
  final bool kendi;

  const _AltIcerik({
    required this.ilan,
    required this.katAdi,
    required this.onIste,
    required this.kendi,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          // Güzergah badge
          if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight_takeoff_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 5),
                  Text(
                    '${ilan.nereden}  →  ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

          // Ürün adı
          Text(
            ilan.urun.isNotEmpty
                ? ilan.urun
                : '${ilan.nereden} → ${ilan.nereye}',
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 6),

          // Kategori + tarih
          Row(
            children: [
              if (katAdi.isNotEmpty)
                _MiniChip(label: katAdi),
              if (ilan.tarih != null) ...[
                const SizedBox(width: 6),
                _MiniChip(
                  label: _tarihYazi(ilan.tarih!),
                  renk: Colors.white.withValues(alpha: 0.12),
                ),
              ],
              if (kendi) ...[
                const SizedBox(width: 6),
                _MiniChip(
                    label: 'Senin ilanın',
                    renk: AppColors.red.withValues(alpha: 0.7)),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // CTA
          if (!kendi)
            GestureDetector(
              onTap: onIste,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.send_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 7),
                    Text(
                      'Hemen İste',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  String _tarihYazi(DateTime tarih) {
    final fark = tarih.difference(DateTime.now()).inDays;
    if (fark == 0) return 'Bugün iniyor';
    if (fark == 1) return 'Yarın iniyor';
    if (fark < 0) return 'Geçmiş';
    return '$fark gün sonra';
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color? renk;
  const _MiniChip({required this.label, this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: renk ?? Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Değişken arka plan — resim yoksa gradient
// ─────────────────────────────────────────────────────────────────────────────

class _DegiskenArkaplan extends StatelessWidget {
  final IlanModel ilan;
  const _DegiskenArkaplan({required this.ilan});

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [const Color(0xFF1a0505), const Color(0xFFE24B4A)],
      [const Color(0xFF0d1b2a), const Color(0xFF1565C0)],
      [const Color(0xFF1a0a1a), const Color(0xFF6A1B9A)],
      [const Color(0xFF0a1a0a), const Color(0xFF2E7D32)],
      [const Color(0xFF1a1000), const Color(0xFFE65100)],
    ];
    final idx = ilan.id.hashCode.abs() % gradients.length;
    final g   = gradients[idx];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [g[0], g[1]],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 72,
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}