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

// Filtre seçim rengi — orta ton yeşil
const Color _kFiltreSec = Color(0xFF3DAA7D);

// Top-level referans
final List<AnaKategori> _kategoriler = kKategoriAgaci;

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

  // Seçili kategori key'i — ana veya alt kategori olabilir
  String? _seciliKategori;

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

  /// Filtreleme mantığı:
  /// - Seçili key bir ANA kategori ise → o ana + tüm alt kategorileri kapsar
  /// - Seçili key bir ALT kategori ise → sadece o alt kategori
  List<IlanModel> _filtrele(List<IlanModel> liste) {
    if (_seciliKategori == null) return liste;

    // Ana kategori mi?
    final anaKat = _kategoriler.firstWhere(
      (k) => k.key == _seciliKategori,
      orElse: () => AnaKategori(key: '', ad: '', emoji: ''),
    );

    if (anaKat.key.isNotEmpty) {
      if (anaKat.altlar.isEmpty) {
        // Alt kategorisi olmayan ana kategori (Diğer gibi)
        return liste.where((i) => i.kategori == anaKat.key).toList();
      }
      // Alt kategorileri olan ana kategori → ana + tüm altlarını kapsar
      final gecerliKeyler = {
        anaKat.key,
        ...anaKat.altlar.map((a) => a.key),
      };
      return liste.where((i) => gecerliKeyler.contains(i.kategori)).toList();
    }

    // Alt kategori — sadece o key
    return liste.where((i) => i.kategori == _seciliKategori).toList();
  }

  /// Seçili kategorinin gösterim adını döndürür
  String get _seciliKategoriAdi {
    if (_seciliKategori == null) return '';
    return kategoriAdi(_seciliKategori);
  }

  void _filtreAc() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filtre kapat',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        return SlideTransition(
          position: slide,
          // Tam ekran — Scaffold ile sarıyoruz ki SafeArea çalışsın
          child: Material(
            color: Colors.transparent,
            child: _FiltreEkrani(
              seciliKategori: _seciliKategori,
              onSecildi: (secilen) {
                setState(() => _seciliKategori = secilen);
                ref
                    .read(istekIlanlarProvider.notifier)
                    .filtreKategoriGuncelle(secilen);
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
    final filtrAktif = _seciliKategori != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'İstekler',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
        actions: [
          TextButton.icon(
            onPressed: _siralamaSheet,
            icon: const Icon(Icons.sort,
                color: AppColors.textPrimary, size: 18),
            label: Text(
              _siralama.label.split(':').first,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _AramaFiltreSatiri(
            aramaCtrl: _aramaCtrl,
            filtrAktif: filtrAktif,
            onAramaChanged: (val) {
              ref.read(istekIlanlarProvider.notifier).filtreAramaGuncelle(val);
              setState(() {});
            },
            onAramaSil: () {
              _aramaCtrl.clear();
              ref.read(istekIlanlarProvider.notifier).filtreAramaGuncelle('');
              setState(() {});
            },
            onFiltreTap: _filtreAc,
          ),
        ),
      ),
      body: Column(
        children: [
          // Seçili kategori bandı
          if (filtrAktif)
            _SeciliKategoriBant(
              kategoriAdiStr: _seciliKategoriAdi,
              onTemizle: () {
                setState(() => _seciliKategori = null);
                ref
                    .read(istekIlanlarProvider.notifier)
                    .filtreKategoriGuncelle(null);
              },
            ),
          Expanded(
            child: state.yukleniyor && ilanlar.isEmpty
                ? const _ShimmerGrid()
                : ilanlar.isEmpty
                    ? _BosEkran(
                        onYenile: () =>
                            ref.read(istekIlanlarProvider.notifier).yenile(),
                      )
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
                          itemCount: ilanlar.length,
                          itemBuilder: (context, index) =>
                              _IlanKarti(ilanId: ilanlar[index].id),
                        ),
                      ),
          ),
        ],
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
        label: Text(
          'İlan Ver',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
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

// ── Arama + Filtre Satırı ─────────────────────────────────────────────────────

class _AramaFiltreSatiri extends StatelessWidget {
  final TextEditingController aramaCtrl;
  final bool filtrAktif;
  final ValueChanged<String> onAramaChanged;
  final VoidCallback onAramaSil;
  final VoidCallback onFiltreTap;

  const _AramaFiltreSatiri({
    required this.aramaCtrl,
    required this.filtrAktif,
    required this.onAramaChanged,
    required this.onAramaSil,
    required this.onFiltreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: aramaCtrl,
                onChanged: onAramaChanged,
                style: GoogleFonts.dmSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'İlanlarda ara...',
                  hintStyle: GoogleFonts.dmSans(
                      color: AppColors.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 18),
                  suffixIcon: aramaCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 14, color: AppColors.textSecondary),
                          onPressed: onAramaSil,
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Sadece ikon
          GestureDetector(
            onTap: onFiltreTap,
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
                        ? _kFiltreSec
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
                          color: _kFiltreSec,
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
    );
  }
}

// ── Filtre Ekranı — TAM EKRAN ─────────────────────────────────────────────────

class _FiltreEkrani extends StatefulWidget {
  final String? seciliKategori;
  final ValueChanged<String?> onSecildi;

  const _FiltreEkrani({
    required this.seciliKategori,
    required this.onSecildi,
  });

  @override
  State<_FiltreEkrani> createState() => _FiltreEkraniState();
}

class _FiltreEkraniState extends State<_FiltreEkrani> {
  late int _aktifAnaIndex;

  @override
  void initState() {
    super.initState();
    _aktifAnaIndex = _anaIndexBul(widget.seciliKategori);
  }

  int _anaIndexBul(String? key) {
    if (key == null) return 0;
    for (int i = 0; i < _kategoriler.length; i++) {
      if (_kategoriler[i].key == key) return i;
      for (final alt in _kategoriler[i].altlar) {
        if (alt.key == key) return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Kategori Seç',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (widget.seciliKategori != null)
                    GestureDetector(
                      onTap: () => widget.onSecildi(null),
                      child: Text(
                        'Temizle',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: _kFiltreSec,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
            // İki kolon
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol: Ana kategoriler — ekranın %36'sı
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.36,
                    child: Container(
                      color: const Color(0xFFF5F5F5),
                      child: ListView.builder(
                        itemCount: _kategoriler.length,
                        itemBuilder: (ctx, i) {
                          final ana = _kategoriler[i];
                          final aktif = i == _aktifAnaIndex;
                          // Bu ana kategorinin altında seçili bir key var mı?
                          final secili =
                              widget.seciliKategori == ana.key ||
                                  ana.altlar.any(
                                      (a) => a.key == widget.seciliKategori);
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _aktifAnaIndex = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: aktif
                                    ? Colors.white
                                    : Colors.transparent,
                                border: aktif
                                    ? const Border(
                                        left: BorderSide(
                                            color: _kFiltreSec, width: 3),
                                      )
                                    : null,
                              ),
                              child: Text(
                                ana.ad,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: secili
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: secili
                                      ? _kFiltreSec
                                      : aktif
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Sağ: Alt kategoriler
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 4, bottom: 32),
                      children: [
                        // "Tümü" → o ana kategoriyi seçer
                        _AltKategoriSatiri(
                          ad: 'Tümü',
                          secili: widget.seciliKategori ==
                              _kategoriler[_aktifAnaIndex].key,
                          onTap: () => widget.onSecildi(
                              _kategoriler[_aktifAnaIndex].key),
                        ),
                        ..._kategoriler[_aktifAnaIndex]
                            .altlar
                            .map((alt) => _AltKategoriSatiri(
                                  ad: alt.ad,
                                  secili:
                                      widget.seciliKategori == alt.key,
                                  onTap: () => widget.onSecildi(alt.key),
                                )),
                      ],
                    ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ad,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight:
                      secili ? FontWeight.w600 : FontWeight.w400,
                  color: secili ? _kFiltreSec : AppColors.textPrimary,
                ),
              ),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: _kFiltreSec),
          ],
        ),
      ),
    );
  }
}

// ── Seçili Kategori Bandı ─────────────────────────────────────────────────────

class _SeciliKategoriBant extends StatelessWidget {
  final String kategoriAdiStr;
  final VoidCallback onTemizle;

  const _SeciliKategoriBant({
    required this.kategoriAdiStr,
    required this.onTemizle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kFiltreSec.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kategoriAdiStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: _kFiltreSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onTemizle,
                  child: const Icon(Icons.close,
                      size: 13, color: _kFiltreSec),
                ),
              ],
            ),
          ),
        ],
      ),
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
          return Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Container(color: Colors.white),
                ),
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
                      Container(height: 10, width: 80, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 60, color: Colors.white),
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

// ── İlan Kartı ────────────────────────────────────────────────────────────────
// StatefulWidget — kart içinde fotoğraf kaydırma state'i tutar

class _IlanKarti extends ConsumerStatefulWidget {
  final String ilanId;
  const _IlanKarti({required this.ilanId});

  @override
  ConsumerState<_IlanKarti> createState() => _IlanKartiState();
}

class _IlanKartiState extends ConsumerState<_IlanKarti> {
  int _aktifResim = 0;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ilan = ref.watch(istekIlanlarProvider).ilanlar.firstWhere(
          (i) => i.id == widget.ilanId,
          orElse: () => IlanModel(
              id: widget.ilanId, tip: '', nereden: '', nereye: '', kullaniciId: ''),
        );
    final resimler = ilan.tumResimler;
    final kategoriAdiStr = kategoriAdi(ilan.kategori);
    final uid = ref.watch(currentUserProvider)?.uid;
    final gosterFavori = uid != null && uid != ilan.kullaniciId;

    final favoriAsync = gosterFavori
        ? ref.watch(ilanFavorideMiProvider(ilan.id))
        : const AsyncData(false);
    final favorideMi = favoriAsync.value ?? false;

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
                parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
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
            // ── Resim bölümü: AspectRatio 4:5 + PageView + noktalar ──
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                children: [
                  // Resim yok
                  if (resimler.isEmpty)
                    Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.textHint, size: 32),
                      ),
                    )
                  // Tek resim — Hero animasyonu için ayrı
                  else if (resimler.length == 1)
                    Hero(
                      tag: 'ilan_resim_${ilan.id}',
                      child: CachedNetworkImage(
                        imageUrl: resimler.first,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surface),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.textHint, size: 32),
                          ),
                        ),
                      ),
                    )
                  // Birden fazla resim — kaydırmalı PageView
                  else
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: resimler.length,
                      onPageChanged: (i) =>
                          setState(() => _aktifResim = i),
                      itemBuilder: (_, i) => i == 0
                          ? Hero(
                              tag: 'ilan_resim_${ilan.id}',
                              child: CachedNetworkImage(
                                imageUrl: resimler[i],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                placeholder: (_, __) => Container(
                                    color: AppColors.surface),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: Icon(Icons.image_outlined,
                                        color: AppColors.textHint,
                                        size: 32),
                                  ),
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: resimler[i],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
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
                            ),
                    ),

                  // Nokta göstergesi — birden fazla resim varsa
                  if (resimler.length > 1)
                    Positioned(
                      bottom: 6,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          resimler.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2),
                            width: _aktifResim == i ? 14 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _aktifResim == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2.5),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (gosterFavori)
                        GestureDetector(
                          onTap: () async {
                            if (favorideMi) {
                              await ref
                                  .read(ilanRepositoryProvider)
                                  .favoridanCikar(
                                    kullaniciId: uid,
                                    ilanId: ilan.id,
                                  );
                              ref
                                  .read(istekIlanlarProvider.notifier)
                                  .ilanFavoriSayisiGuncelle(ilan.id, -1);
                            } else {
                              await ref
                                  .read(ilanRepositoryProvider)
                                  .favoriyeEkle(
                                    kullaniciId: uid,
                                    ilan: ilan,
                                  );
                              ref
                                  .read(istekIlanlarProvider.notifier)
                                  .ilanFavoriSayisiGuncelle(ilan.id, 1);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ilan.favoriSayisi > 0)
                                Text(
                                  '${ilan.favoriSayisi}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.red
                                      .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  favorideMi
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: AppColors.red,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textSecondary),
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
                            fontSize: 13,
                            fontWeight: ilan.ucret.isNotEmpty
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: ilan.ucret.isNotEmpty
                                ? AppColors.red
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (kategoriAdiStr.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          color: AppColors.chipBg,
                          child: Text(
                            kategoriAdiStr,
                            style: GoogleFonts.dmSans(
                                fontSize: 9,
                                color: AppColors.textSecondary),
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

// ── Boş Ekran ─────────────────────────────────────────────────────────────────

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
