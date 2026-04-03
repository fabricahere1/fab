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
 
enum SiralamaTipi { enYeni, enEski, ucretArtan, ucretAzalan }
 
extension SiralamaTipiX on SiralamaTipi {
  String get label {
    switch (this) {
      case SiralamaTipi.enYeni: return 'En yeni';
      case SiralamaTipi.enEski: return 'En eski';
      case SiralamaTipi.ucretArtan: return 'Ücret: Düşük → Yüksek';
      case SiralamaTipi.ucretAzalan: return 'Ücret: Yüksek → Düşük';
    }
  }
}
 
class IsteklerScreen extends ConsumerStatefulWidget {
  const IsteklerScreen({super.key});
 
  @override
  ConsumerState<IsteklerScreen> createState() => _IsteklerScreenState();
}
 
// AutomaticKeepAliveClientMixin — sekme değişince state korunur
class _IsteklerScreenState extends ConsumerState<IsteklerScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  SiralamaTipi _siralama = SiralamaTipi.enYeni;
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
 
  List<IlanModel> _filtrele(List<IlanModel> liste) {
    if (_seciliKategori == null) return liste;
    return liste.where((i) => i.kategori == _seciliKategori).toList();
  }
 
  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAlive için zorunlu
    final state = ref.watch(istekIlanlarProvider);
    final ilanlar = _sirala(_filtrele(state.filtrelenmis));
 
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
          preferredSize: const Size.fromHeight(44),
          child: _KategoriBar(
            seciliKategori: _seciliKategori,
            onSecildi: (k) => setState(() => _seciliKategori = k),
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
                    itemCount: ilanlar.length,
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: _IlanKarti(ilan: ilanlar[index]),
                      );
                    },
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
                      Container(height: 12, width: double.infinity, color: Colors.white),
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
 
// ── Kategori Bar ──────────────────────────────────────────
 
class _KategoriBar extends StatelessWidget {
  final String? seciliKategori;
  final ValueChanged<String?> onSecildi;
 
  const _KategoriBar({
    required this.seciliKategori,
    required this.onSecildi,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _KategoriChip(
            label: 'Tümü',
            secili: seciliKategori == null,
            onTap: () => onSecildi(null),
          ),
          ...kKategoriler.entries.map((e) => _KategoriChip(
                label: e.value,
                secili: seciliKategori == e.key,
                onTap: () =>
                    onSecildi(seciliKategori == e.key ? null : e.key),
              )),
        ],
      ),
    );
  }
}
 
class _KategoriChip extends StatelessWidget {
  final String label;
  final bool secili;
  final VoidCallback onTap;
 
  const _KategoriChip({
    required this.label,
    required this.secili,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: secili ? AppColors.red : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: secili ? AppColors.red : AppColors.textSecondary,
            fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
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
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
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
            Hero(
              tag: 'ilan_resim_${ilan.id}',
              child: resimler.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: resimler.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      placeholder: (_, __) => Container(
                        height: _resimYuksekligi(),
                        color: AppColors.surface,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: _resimYuksekligi(),
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.textHint, size: 32),
                        ),
                      ),
                    )
                  : Container(
                      height: _resimYuksekligi(),
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.textHint, size: 32),
                      ),
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
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
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
                style: GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}