// lib/features/ilanlar/presentation/widgets/ilan_karti.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/ilan_model.dart';
import '../../providers/ilan_provider.dart';
import '../../data/ilan_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/cache/app_cache_manager.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/utils/app_layout.dart';
import '../ilan_detay_screen.dart';
import '../../../../shared/constants/app_constants.dart';

const kResimYukseklikleri = [176.0, 208.0, 160.0, 192.0, 224.0, 168.0];

// ── Grid Kartı ────────────────────────────────────────────────────────────────

class IlanKarti extends ConsumerWidget {
  final IlanModel ilan;
  final List<double> resimYukseklikleri;
  final int kolonSayisi;

  const IlanKarti({
    super.key,
    required this.ilan,
    required this.resimYukseklikleri,
    this.kolonSayisi = 2,
  });

  double _resimYuksekligi(BuildContext context) {
    if (kolonSayisi == 3) {
      final kartGenisligi = (MediaQuery.of(context).size.width - 24 - 12) / 3;
      return kartGenisligi * 1.0;
    }
    return resimYukseklikleri[ilan.id.hashCode.abs() % resimYukseklikleri.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IlanModel guncelIlan;
    if (ilan.tip == IlanTip.tasiyici) {
      guncelIlan = ref.watch(tasiyiciIlanlarProvider.select((s) {
        try {
          return s.filtrelenmis.firstWhere((i) => i.id == ilan.id);
        } catch (_) {
          return ilan;
        }
      }));
    } else {
      guncelIlan = ref.watch(istekIlanlarProvider.select((s) {
        try {
          return s.filtrelenmis.firstWhere((i) => i.id == ilan.id);
        } catch (_) {
          return ilan;
        }
      }));
    }

    final resimler       = guncelIlan.tumResimler;
    final kategoriAdiStr = kategoriAdi(guncelIlan.kategori);
    final uid            = ref.watch(currentUserProvider)?.uid;
    final gosterFavori   = uid != null && uid != guncelIlan.kullaniciId;
    final favoriliIdler  = ref.watch(favoriliIlanIdlerProvider);
    final favorideMi     = gosterFavori && favoriliIdler.contains(guncelIlan.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => IlanDetayScreen(ilanId: guncelIlan.id, ilan: guncelIlan),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF888888), width: 0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: _resimYuksekligi(context),
                  width: double.infinity,
                  child: resimler.isNotEmpty
                      ? _IlanResimSlider(
                          resimler: resimler,
                          yukseklik: _resimYuksekligi(context),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 28),
                          ),
                        ),
                ),
                // ── Optimistic favori butonu ──────────────────────────────
                if (gosterFavori)
                  Positioned(
                    top: 6, right: 6,
                    child: _FavoriButon(
                      ilan: guncelIlan,
                      uid: uid,
                      baslangicDurumu: favorideMi,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: kolonSayisi == 3
                  ? const EdgeInsets.all(5)
                  : const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guncelIlan.urun.isNotEmpty ? guncelIlan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                        fontSize: AppLayout.fs(context, 12),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${guncelIlan.nereden} → ${guncelIlan.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: AppLayout.fs(context, 10),
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (kategoriAdiStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kategoriAdiStr,
                        style: GoogleFonts.dmSans(
                            fontSize: AppLayout.fs(context, 9),
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 5),
                  _SayacWidget(
                    goruntulenmeSayisi: guncelIlan.goruntulenmeSayisi,
                    favoriSayisi: guncelIlan.favoriSayisi,
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

// ── İlan Resim Slider (swipeable, tam boyut) ──────────────────────────────────

class _IlanResimSlider extends StatefulWidget {
  final List<String> resimler;
  final double yukseklik;

  const _IlanResimSlider({required this.resimler, required this.yukseklik});

  @override
  State<_IlanResimSlider> createState() => _IlanResimSliderState();
}

class _IlanResimSliderState extends State<_IlanResimSlider> {
  final _pageCtrl = PageController();
  int _aktif = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final px = MediaQuery.devicePixelRatioOf(context);
    final w  = (MediaQuery.sizeOf(context).width / 2 * px).toInt();

    return Stack(
      children: [
        // Fotoğraf PageView — karta dokunmayı absorbe etmesin
        PageView.builder(
          controller: _pageCtrl,
          physics: widget.resimler.length > 1
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: widget.resimler.length,
          onPageChanged: (i) => setState(() => _aktif = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            cacheManager: AppCacheManager.instance,
            imageUrl: widget.resimler[i],
            fit: BoxFit.cover,
            memCacheWidth: w,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: Container(color: Colors.white),
            ),
            errorWidget: (_, _, _) => Container(
              color: AppColors.surface,
              child: const Center(
                child: Icon(Icons.image_outlined,
                    color: AppColors.textHint, size: 28),
              ),
            ),
          ),
        ),

        // Nokta indikatörü — sadece birden fazla fotoğraf varsa
        if (widget.resimler.length > 1)
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.resimler.length, (i) {
                final aktif = i == _aktif;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: aktif ? 12 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: aktif
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ── Optimistic Favori Butonu ──────────────────────────────────────────────────
//
// Tıklanınca UI'ı ANINDA günceller (optimistic), arkada Firestore'a yazar.
// Firestore stream gelince zaten doğru değer yansır — kullanıcı farkı görmez.

class _FavoriButon extends ConsumerStatefulWidget {
  final IlanModel ilan;
  final String uid;
  final bool baslangicDurumu;

  const _FavoriButon({
    required this.ilan,
    required this.uid,
    required this.baslangicDurumu,
  });

  @override
  ConsumerState<_FavoriButon> createState() => _FavoriButonState();
}

class _FavoriButonState extends ConsumerState<_FavoriButon>
    with SingleTickerProviderStateMixin {
  late bool _localFavori;
  bool _islem = false; // çift tıklamayı önle
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _localFavori = widget.baslangicDurumu;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  // Firestore stream'den gelen gerçek durum değişirse senkronize et
  @override
  void didUpdateWidget(_FavoriButon old) {
    super.didUpdateWidget(old);
    // Sadece islem yokken senkronize et — islem varken kullanıcının
    // tıkladığı değeri koruyoruz
    if (!_islem && old.baslangicDurumu != widget.baslangicDurumu) {
      _localFavori = widget.baslangicDurumu;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _toglle() async {
    if (_islem) return;
    _islem = true;

    // 1. UI'ı anında güncelle
    setState(() => _localFavori = !_localFavori);

    // 2. Scale animasyonu
    _ctrl.forward().then((_) => _ctrl.reverse());

    // 3. Arkada Firestore'a yaz ve provider state'i güncelle
    try {
      final repo = ref.read(ilanRepositoryProvider);
      if (_localFavori) {
        await repo.favoriyeEkle(kullaniciId: widget.uid, ilan: widget.ilan);
        ref.read(istekIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(widget.ilan.id, 1);
        ref.read(tasiyiciIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(widget.ilan.id, 1);
      } else {
        await repo.favoridanCikar(kullaniciId: widget.uid, ilanId: widget.ilan.id);
        ref.read(istekIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(widget.ilan.id, -1);
        ref.read(tasiyiciIlanlarProvider.notifier).ilanFavoriSayisiGuncelle(widget.ilan.id, -1);
      }
    } catch (_) {
      // Hata olursa geri al
      if (mounted) setState(() => _localFavori = !_localFavori);
    } finally {
      _islem = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toglle,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Icon(
            _localFavori ? Icons.favorite : Icons.favorite_border,
            color: _localFavori ? AppColors.red : Colors.white.withValues(alpha: 0.9),
            size: 16,
          ),
        ),
      ),
    );
  }
}

// ── Shimmer Grid ──────────────────────────────────────────────────────────────

class ShimmerGrid extends StatelessWidget {
  final int kolonSayisi;
  const ShimmerGrid({super.key, this.kolonSayisi = 2});

  @override
  Widget build(BuildContext context) {
    if (kolonSayisi == 1) return const ShimmerListe();
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: MasonryGridView.count(
        crossAxisCount: kolonSayisi,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          final h = kResimYukseklikleri[index % kResimYukseklikleri.length];
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
                      Container(height: 11, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 5),
                      Container(height: 9, width: 80, color: Colors.white),
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

// ── Animasyonlu Görüntülenme / Favori Sayacı ─────────────────────────────────

class _SayacWidget extends StatefulWidget {
  final int goruntulenmeSayisi;
  final int favoriSayisi;

  const _SayacWidget({
    required this.goruntulenmeSayisi,
    required this.favoriSayisi,
  });

  @override
  State<_SayacWidget> createState() => _SayacWidgetState();
}

class _SayacWidgetState extends State<_SayacWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideOut;
  late Animation<Offset> _slideIn;
  bool _gosterGoruntulenme = true;
  static const _interval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(_interval, _toggle);
  }

  void _toggle() {
    if (!mounted) return;
    _ctrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _gosterGoruntulenme = !_gosterGoruntulenme);
      _ctrl.reset();
      Future.delayed(_interval, _toggle);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sayiStr = _gosterGoruntulenme
        ? '${widget.goruntulenmeSayisi}'
        : '${widget.favoriSayisi}';
    final ikon = _gosterGoruntulenme
        ? Icons.remove_red_eye_outlined
        : Icons.favorite_border;

    return ClipRect(
      child: SizedBox(
        height: 16,
        child: Stack(
          children: [
            // Çıkan
            SlideTransition(
              position: _slideOut,
              child: _SayacSatir(
                ikon: ikon,
                sayi: sayiStr,
              ),
            ),
            // Giren
            SlideTransition(
              position: _slideIn,
              child: _SayacSatir(
                ikon: _gosterGoruntulenme
                    ? Icons.favorite_border
                    : Icons.remove_red_eye_outlined,
                sayi: _gosterGoruntulenme
                    ? '${widget.favoriSayisi}'
                    : '${widget.goruntulenmeSayisi}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SayacSatir extends StatelessWidget {
  final IconData ikon;
  final String sayi;
  const _SayacSatir({required this.ikon, required this.sayi});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 10, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          sayi,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Shimmer Liste ─────────────────────────────────────────────────────────────

class ShimmerListe extends StatelessWidget {
  const ShimmerListe({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Column(
        children: List.generate(6, (_) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 1),
          child: Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 13, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 140, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 13, width: 80, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}