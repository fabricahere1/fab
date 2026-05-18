// lib/features/ilanlar/presentation/widgets/swipe_karti.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../../../shared/constants/app_colors.dart';
import '../../../../core/cache/app_cache_manager.dart';
import '../../domain/ilan_model.dart';
import '../../providers/ilan_provider.dart';
import '../../data/ilan_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../ilan_detay_screen.dart';

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

  Offset _konum = Offset.zero;

  late final AnimationController _animCtrl;
  late Animation<Offset> _animKonum;

  bool _animasyonAktif  = false;
  bool _kartFirliyor    = false;
  bool _kartGeriAliyor  = false;
  bool _geriAlAnimasyonu = false; // geri alma sırasında arka kartı gizler

  late final AnimationController _favCtrl;
  late final Animation<double>   _favScale;

  static const _esik           = 100.0;
  static const _hizEsik        = 500.0;
  static const _maxGecmis      = 20;
  static const _onYuklemEsigi  = 3;

  // ── Nullable getterlar ───────────────────────────────────────────────────

  bool get _listeBitti => _idx >= widget.ilanlar.length;

  IlanModel? get _mevcutIlan =>
      _idx < widget.ilanlar.length ? widget.ilanlar[_idx] : null;

  IlanModel? get _sonrakiIlan =>
      _idx + 1 < widget.ilanlar.length ? widget.ilanlar[_idx + 1] : null;

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

    if (_kartGeriAliyor) {
      // Sola fırlatma bitti — arka kart gizliydi, şimdi geri al
      _kartGeriAliyor    = false;
      _geriAlAnimasyonu  = false;
      if (_gecmis.isNotEmpty) {
        setState(() {
          _konum = Offset.zero;
          _idx   = _gecmis.removeLast();
        });
      } else {
        setState(() => _konum = Offset.zero);
      }
    } else if (_kartFirliyor) {
      _kartFirliyor = false;
      final yeniIdx = _idx + 1;

      if (yeniIdx >= widget.ilanlar.length - _onYuklemEsigi) {
        widget.onDahaFazla?.call();
      }

      setState(() {
        _gecmis.add(_idx);
        if (_gecmis.length > _maxGecmis) _gecmis.removeAt(0);
        _idx  = yeniIdx;
        _konum = Offset.zero;
      });
    } else {
      setState(() => _konum = Offset.zero);
    }
  }

  // ── Drag ─────────────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_animasyonAktif) {
      _animCtrl.stop();
      _animasyonAktif    = false;
      _kartFirliyor      = false;
      _kartGeriAliyor    = false;
      _geriAlAnimasyonu  = false;
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _konum += d.delta);
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;
    final dx = _konum.dx;

    if (dx.abs() > _esik || vx.abs() > _hizEsik) {
      final solaGidiyor = dx < 0 || vx < 0;
      if (solaGidiyor) {
        if (_gecmis.isNotEmpty) {
          _firlat(vx, geriAl: true);
        } else {
          _gereDon();
        }
      } else {
        _firlat(vx, geriAl: false);
      }
    } else {
      _gereDon();
    }
  }

  // ── Fırlatma ─────────────────────────────────────────────────────────────

  void _firlat(double vx, {bool geriAl = false}) {
    final w   = MediaQuery.of(context).size.width;
    final yon = (_konum.dx != 0)
        ? _konum.dx.sign
        : (vx != 0 ? vx.sign : 1);
    final hedef = Offset(yon * w * 1.5, _konum.dy + 80 * yon);

    final hizFaktoru = (vx.abs() / 1000).clamp(0.3, 1.0);
    final sure = Duration(milliseconds: (400 - hizFaktoru * 200).round());

    _animasyonAktif   = true;
    _kartFirliyor     = !geriAl;
    _kartGeriAliyor   = geriAl;
    _geriAlAnimasyonu = geriAl; // geri alma sırasında arka kartı gizle

    _animKonum = Tween<Offset>(begin: _konum, end: hedef).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _animCtrl.duration = sure;
    _animCtrl.forward(from: 0);
  }

  // ── Buton fırlatma ───────────────────────────────────────────────────────

  void _firlatYon(double yon) {
    if (_animasyonAktif) return;
    final w = MediaQuery.of(context).size.width;

    _animasyonAktif   = true;
    _kartFirliyor     = true;
    _kartGeriAliyor   = false;
    _geriAlAnimasyonu = false;

    _animKonum = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(yon * w * 1.5, 60),
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));

    _animCtrl.duration = const Duration(milliseconds: 280);
    _animCtrl.forward(from: 0);
  }

  // ── Geri dönüş ───────────────────────────────────────────────────────────

  void _gereDon() {
    _animasyonAktif   = true;
    _kartFirliyor     = false;
    _kartGeriAliyor   = false;
    _geriAlAnimasyonu = false;

    _animKonum = Tween<Offset>(
      begin: _konum,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    ));

    _animCtrl.duration = const Duration(milliseconds: 500);
    _animCtrl.forward(from: 0);
  }

  // ── Butonlar ─────────────────────────────────────────────────────────────

  void _butonSonraki() => _firlatYon(1);

  void _geriButon() {
    if (_gecmis.isEmpty || _animasyonAktif) return;
    setState(() {
      _idx   = _gecmis.removeLast();
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
    if (widget.ilanlar.isEmpty || _listeBitti) {
      return _BosSonucEkrani(onYenile: widget.onDahaFazla);
    }

    final favIdler = ref.watch(favoriliIlanIdlerProvider);
    final mevcut   = _mevcutIlan!;
    final sonraki  = _sonrakiIlan;
    final isFav    = favIdler.contains(mevcut.id);

    // Geri alma sırasında arka kartta önceki ilanı göster
    final arkaIlan = _geriAlAnimasyonu
        ? (_gecmis.isNotEmpty ? widget.ilanlar[_gecmis.last] : null)
        : sonraki;

    final x         = _konum.dx;
    final y         = _konum.dy;
    final rotasyon  = (x / 18) * (math.pi / 180);
    final ilerleme  = (x.abs() / _esik).clamp(0.0, 1.0);
    final arkaScale = 0.92 + 0.08 * ilerleme;

    return Stack(
      children: [

        // ── Kart alanı (fullscreen) ───────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onPanStart:  _onDragStart,
            onPanUpdate: _onDragUpdate,
            onPanEnd:    _onDragEnd,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [

                // Arka kart
                if (arkaIlan != null)
                  Positioned.fill(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                          arkaScale, arkaScale, 1)
                        ..setTranslationRaw(0, 18 * (1 - ilerleme), 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _KartArkaplan(ilan: arkaIlan),
                      ),
                    ),
                  ),

                // Ön kart
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..translateByDouble(x, y * 0.3, 0, 1)
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

        // ── Alt butonlar — resmin üzerinde, gradient arkaplanlı ───────────
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            height: 110,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x00000000),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AltButon(
                  ikon: Icons.history_rounded,
                  renk: const Color(0xFFFFA726),
                  bgRenk: Colors.white.withValues(alpha: 0.15),
                  borderRenk: Colors.white.withValues(alpha: 0.25),
                  label: 'Geri Al',
                  boyut: 52,
                  ikonBoyut: 22,
                  onTap: _gecmis.isEmpty ? null : _geriButon,
                ),

                _FavorileButon(
                  aktif: isFav,
                  onTap: () => _favToggle(mevcut),
                ),

                _AltButon(
                  ikon: Icons.skip_next_rounded,
                  renk: const Color(0xFF90CAF9),
                  bgRenk: Colors.white.withValues(alpha: 0.15),
                  borderRenk: Colors.white.withValues(alpha: 0.25),
                  label: 'İleri',
                  boyut: 52,
                  ikonBoyut: 22,
                  onTap: _butonSonraki,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Boş sonuç ekranı ─────────────────────────────────────────────────────────

class _BosSonucEkrani extends StatelessWidget {
  final VoidCallback? onYenile;
  const _BosSonucEkrani({this.onYenile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Tüm ilanları gördün!',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni ilanlar için yenile',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 24),
          if (onYenile != null)
            GestureDetector(
              onTap: onYenile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Yenile',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) =>
              IlanDetayScreen(ilanId: ilan.id, ilan: ilan),
          transitionsBuilder: (_, anim, _, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _KartArkaplan(ilan: ilan)),

        const Positioned.fill(
          child: DecoratedBox(
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
                '${idx + 1} / $toplam',
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
          left: 0, right: 0, bottom: 110,
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
                            color: Colors.white.withValues(alpha: 0.65)),
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
                      if (ilan.ucret.isNotEmpty)
                        Text(
                          '${ilan.ucret} ₺',
                          style: GoogleFonts.dmSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
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

        // Kalp animasyonu
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
      ),
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

  @override
  Widget build(BuildContext context) {
    final bgRenk   = _renkler[ilan.id.hashCode.abs() % _renkler.length];
    final resimler = ilan.tumResimler;
    final placeholder = Container(color: bgRenk);

    if (resimler.isNotEmpty) {
      return CachedNetworkImage(
        cacheManager: AppCacheManager.instance,
        imageUrl: resimler.first,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
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
                    color: Colors.black.withValues(alpha: 0.2),
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
                    color: Colors.white.withValues(alpha: 0.8))),
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
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: aktif
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935)
                      .withValues(alpha: aktif ? 0.45 : 0.15),
                  blurRadius: aktif ? 20 : 8,
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
                color: Colors.white,
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
              color: Colors.white.withValues(alpha: aktif ? 1.0 : 0.7),
            ),
          ),
        ],
      ),
    );
  }
}