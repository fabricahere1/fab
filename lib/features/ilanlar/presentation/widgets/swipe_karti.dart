// lib/features/ilanlar/presentation/widgets/swipe_karti.dart
//
// Tinder tarzı swipe — temiz ve çalışan versiyon.
// SpringSimulation sorunları yerine Tween + CurvedAnimation kullanır.
// Kart parmakla kayar, bırakılınca fırlar veya yaylanarak döner.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../core/cache/app_cache_manager.dart';
import '../../domain/ilan_model.dart';
import '../../providers/ilan_provider.dart';
import '../../data/ilan_repository.dart';
import '../../../../router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';

class SwipeGorunumu extends ConsumerStatefulWidget {
  final List<IlanModel> ilanlar;
  final VoidCallback? onDahaFazla;

  const SwipeGorunumu({
    super.key,
    required this.ilanlar,
    this.onDahaFazla,
  });

  @override
  ConsumerState<SwipeGorunumu> createState() => _SwipeGorunumuState();
}

class _SwipeGorunumuState extends ConsumerState<SwipeGorunumu>
    with TickerProviderStateMixin {

  int _idx = 0;
  final List<int> _gecmis = [];

  // Kart pozisyonu — drag esnasında direkt güncellenir
  Offset _konum = Offset.zero;

  // Animasyon controller — fırlatma ve geri dönüş için
  late final AnimationController _animCtrl;
  late Animation<Offset> _animKonum;

  // Animasyon modu
  bool _animasyonAktif = false;
  bool _kartFirliyor   = false;

  // Kalp
  late final AnimationController _favCtrl;
  late final Animation<double>   _favScale;

  static const _esik    = 100.0;
  static const _hizEsik = 500.0;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(vsync: this);
    _animKonum = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animCtrl);

    _animCtrl.addListener(() {
      if (_animasyonAktif) {
        setState(() => _konum = _animKonum.value);
      }
    });

    _animCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && _animasyonAktif) {
        _animasyonBitti();
      }
    });

    _favCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _favScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _favCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _favCtrl.dispose();
    super.dispose();
  }

  void _animasyonBitti() {
    _animasyonAktif = false;
    if (_kartFirliyor) {
      _kartFirliyor = false;
      setState(() {
        _gecmis.add(_idx);
        _idx++;
        _konum = Offset.zero;
      });
      if (_idx >= widget.ilanlar.length - 3) {
        widget.onDahaFazla?.call();
      }
    } else {
      setState(() => _konum = Offset.zero);
    }
  }

  IlanModel get _mevcut => widget.ilanlar[_idx % widget.ilanlar.length];
  IlanModel get _sonraki =>
      widget.ilanlar[(_idx + 1) % widget.ilanlar.length];

  // ── Drag ─────────────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_animasyonAktif) {
      _animCtrl.stop();
      _animasyonAktif = false;
      _kartFirliyor   = false;
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _konum += d.delta);
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;

    if (_konum.dx.abs() > _esik || vx.abs() > _hizEsik) {
      _firlat(vx);
    } else {
      _gereDon();
    }
  }

  // ── Fırlatma ─────────────────────────────────────────────────────────────

  void _firlat(double vx) {
    final w   = MediaQuery.of(context).size.width;
    final yon = (_konum.dx != 0)
        ? _konum.dx.sign
        : (vx != 0 ? vx.sign : 1);
    final hedef = Offset(yon * w * 1.5, _konum.dy + 80 * yon);

    // Hız bazlı süre: hızlı swipe → kısa süre, yavaş → biraz daha uzun
    final hizFaktoru = (vx.abs() / 1000).clamp(0.3, 1.0);
    final sure = Duration(milliseconds: (400 - hizFaktoru * 200).round());

    _animasyonAktif = true;
    _kartFirliyor   = true;

    _animKonum = Tween<Offset>(begin: _konum, end: hedef).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _animCtrl.duration = sure;
    _animCtrl.forward(from: 0);
  }

  // ── Geri dönüş ───────────────────────────────────────────────────────────

  void _gereDon() {
    _animasyonAktif = true;
    _kartFirliyor   = false;

    _animKonum = Tween<Offset>(
      begin: _konum,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        // Elastik yay hissi — biraz titrer ve yerine oturur
        curve: Curves.elasticOut,
      ),
    );

    _animCtrl.duration = const Duration(milliseconds: 500);
    _animCtrl.forward(from: 0);
  }

  // ── Butonlar ─────────────────────────────────────────────────────────────

  void _butonIleri() {
    if (_animasyonAktif) return;
    setState(() => _konum = const Offset(-15, 0));
    _firlat(-1800);
  }

  void _butonSonraki() {
    if (_animasyonAktif) return;
    setState(() => _konum = const Offset(15, 0));
    _firlat(1800);
  }

  void _geri() {
    if (_gecmis.isEmpty || _animasyonAktif) return;
    setState(() {
      _idx = _gecmis.removeLast();
      _konum = Offset.zero;
    });
  }

  // ── Favori ───────────────────────────────────────────────────────────────

  Future<void> _favToggle(IlanModel ilan) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final isFav = ref.read(favoriliIlanIdlerProvider).contains(ilan.id);
    if (isFav) {
      await ref
          .read(ilanRepositoryProvider)
          .favoridanCikar(kullaniciId: uid, ilanId: ilan.id);
    } else {
      await ref
          .read(ilanRepositoryProvider)
          .favoriyeEkle(kullaniciId: uid, ilan: ilan);
      _favCtrl.forward(from: 0).then((_) {
        if (mounted) _favCtrl.reverse();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.ilanlar.isEmpty) {
      return const Center(child: Text('İlan bulunamadı'));
    }

    final favIdler  = ref.watch(favoriliIlanIdlerProvider);
    final mevcut    = _mevcut;
    final sonraki   = _sonraki;
    final isFav     = favIdler.contains(mevcut.id);

    final x         = _konum.dx;
    final y         = _konum.dy;
    // Rotasyon: yukarıdan tutunca az, aşağıdan tutunca fazla dönsün
    final rotasyon  = (x / 18) * (3.14159 / 180);
    final ilerleme  = (x.abs() / _esik).clamp(0.0, 1.0);
    final arkaScale = 0.92 + 0.08 * ilerleme;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanStart:  _onDragStart,
            onPanUpdate: _onDragUpdate,
            onPanEnd:    _onDragEnd,
            child: Stack(
              children: [

                // ── Arka kart ──────────────────────────────────────────
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                        arkaScale, arkaScale, 1)
                      ..setTranslationRaw(0, 18 * (1 - ilerleme), 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _KartArkaplan(ilan: sonraki),
                    ),
                  ),
                ),

                // ── Ön kart ────────────────────────────────────────────
                Positioned.fill(
                  child: Transform(
                    // Alt merkez pivot → daha doğal Tinder hissi
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..translate(x, y * 0.3)
                      ..rotateZ(rotasyon),
                    child: _OnKart(
                      ilan:        mevcut,
                      isFav:       isFav,
                      idx:         _idx,
                      toplam:      widget.ilanlar.length,
                      suruklenmeX: x,
                      favScale:    _favScale,
                      onFav:       () => _favToggle(mevcut),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Alt butonlar ───────────────────────────────────────────────
        Container(
          height: 100,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Geri Al
              _AltButon(
                ikon: Icons.history_rounded,
                renk: const Color(0xFFFFA726),
                bgRenk: const Color(0xFFFFF8E1),
                borderRenk: const Color(0xFFFFE082),
                label: 'Geri Al',
                boyut: 52,
                ikonBoyut: 22,
                onTap: _gecmis.isEmpty ? null : _geri,
              ),

              // Favorile — ortada, büyük
              _FavorileButon(
                aktif: isFav,
                onTap: () => _favToggle(mevcut),
              ),

              // İleri
              _AltButon(
                ikon: Icons.skip_next_rounded,
                renk: const Color(0xFF5C6BC0),
                bgRenk: const Color(0xFFEDE7F6),
                borderRenk: const Color(0xFFB39DDB),
                label: 'İleri',
                boyut: 52,
                ikonBoyut: 22,
                onTap: _butonSonraki,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Ön kart ──────────────────────────────────────────────────────────────────

class _OnKart extends StatelessWidget {
  final IlanModel ilan;
  final bool isFav;
  final int idx;
  final int toplam;
  final double suruklenmeX;
  final Animation<double> favScale;
  final VoidCallback onFav;

  const _OnKart({
    required this.ilan,
    required this.isFav,
    required this.idx,
    required this.toplam,
    required this.suruklenmeX,
    required this.favScale,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    final gecOp   = suruklenmeX < -15
        ? ((-suruklenmeX - 15) / 85).clamp(0.0, 1.0)
        : 0.0;
    final ileriOp = suruklenmeX > 15
        ? ((suruklenmeX - 15) / 85).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        // Arka plan resim
        Positioned.fill(child: _KartArkaplan(ilan: ilan)),

        // Alt gradient
        Positioned.fill(
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC000000),
                  Color(0xF0000000),
                ],
                stops: [0, 0.38, 0.72, 1],
              ),
            ),
          ),
        ),

        // Üst gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const [0, 0.3],
              ),
            ),
          ),
        ),

        // GEÇ
        Positioned(
          top: 55, left: 18,
          child: Opacity(
            opacity: gecOp,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('GEÇ',
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                        letterSpacing: 1)),
              ),
            ),
          ),
        ),

        // İLERİ
        Positioned(
          top: 55, right: 18,
          child: Opacity(
            opacity: ileriOp,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFF69F0AE), width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('İLERİ',
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF69F0AE),
                        letterSpacing: 1)),
              ),
            ),
          ),
        ),

        // Kategori + sayaç
        Positioned(
          top: 12, left: 14, right: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5),
                ),
                child: Text(
                  ilan.kategori.isNotEmpty ? ilan.kategori : 'Diğer',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
              Text(
                '${(idx % toplam) + 1} / $toplam',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),

        // Favori
        Positioned(
          top: 8, right: 14,
          child: GestureDetector(
            onTap: onFav,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: isFav
                    ? AppColors.red.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.5),
              ),
              child: Icon(
                isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: Colors.white, size: 17,
              ),
            ),
          ),
        ),

        // Alt bilgi
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.ilanDetayPath(ilan.id)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ilan.urun.isNotEmpty
                        ? ilan.urun
                        : '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 11, color: Color(0xAAFFFFFF)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${ilan.nereden} → ${ilan.nereye}',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color:
                                Colors.white.withValues(alpha: 0.65)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('taşıma ücreti',
                              style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: Colors.white
                                      .withValues(alpha: 0.5))),
                          Text(
                            ilan.ucret.isNotEmpty
                                ? '${ilan.ucret} ₺'
                                : 'Belirtilmemiş',
                            style: GoogleFonts.dmSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded,
                                color: Color(0xFFFFA726), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              ilan.favoriSayisi > 0
                                  ? '${ilan.favoriSayisi} favori'
                                  : 'Yeni',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Kalp
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: ScaleTransition(
                scale: favScale,
                child: const Text('❤️',
                    style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Kart arka planı ──────────────────────────────────────────────────────────

class _KartArkaplan extends StatelessWidget {
  final IlanModel ilan;
  const _KartArkaplan({required this.ilan});

  static const _renkler = [
    Color(0xFF0D1B2A), Color(0xFF1B5E20), Color(0xFF3E0028),
    Color(0xFF1A0030), Color(0xFF0D2137), Color(0xFF111111),
  ];

  static const _emojiMap = {
    'elektronik': '📱', 'giyim': '👗', 'guzellik': '💄',
    'aksesuar': '👜', 'oyun': '🎮', 'ev': '🏠',
    'spor': '⚽', 'kitap': '📚', 'cocuk': '🧸',
  };

  @override
  Widget build(BuildContext context) {
    final bgRenk   = _renkler[ilan.id.hashCode.abs() % _renkler.length];
    final resimler = ilan.tumResimler;
    final emoji    = _emojiMap.entries
        .firstWhere(
          (e) => ilan.kategori.toLowerCase().contains(e.key),
          orElse: () => const MapEntry('', '📦'),
        )
        .value;

    final placeholder = Container(
      color: bgRenk,
      child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 90))),
    );

    if (resimler.isNotEmpty) {
      return CachedNetworkImage(
        cacheManager: AppCacheManager.instance,
        imageUrl: resimler.first,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }
    return placeholder;
  }
}

// ── Yan buton (Geri Al / İleri) ──────────────────────────────────────────────

class _AltButon extends StatelessWidget {
  final IconData ikon;
  final Color renk;
  final Color bgRenk;
  final Color borderRenk;
  final String label;
  final VoidCallback? onTap;
  final double boyut;
  final double ikonBoyut;

  const _AltButon({
    required this.ikon,
    required this.renk,
    required this.bgRenk,
    required this.borderRenk,
    required this.label,
    required this.boyut,
    required this.ikonBoyut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: boyut,
              height: boyut,
              decoration: BoxDecoration(
                color: bgRenk,
                shape: BoxShape.circle,
                border: Border.all(color: borderRenk, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: renk.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(ikon, color: renk, size: ikonBoyut),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFAAAAAA))),
          ],
        ),
      ),
    );
  }
}

// ── Orta favori butonu ────────────────────────────────────────────────────────

class _FavorileButon extends StatelessWidget {
  final bool aktif;
  final VoidCallback onTap;

  const _FavorileButon({required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: aktif
                  ? const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF6F6F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFEBEE), Color(0xFFFFF0F0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935)
                      .withValues(alpha: aktif ? 0.45 : 0.2),
                  blurRadius: aktif ? 20 : 12,
                  spreadRadius: aktif ? 2 : 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: Icon(
                aktif ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(aktif),
                color: aktif ? Colors.white : const Color(0xFFE53935),
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            aktif ? 'Favorilendi' : 'Favorile',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: aktif ? const Color(0xFFE53935) : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}