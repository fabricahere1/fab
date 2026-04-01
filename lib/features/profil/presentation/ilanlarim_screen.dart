import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../ilanlar/data/ilan_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../ilanlar/presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
 
// ── Provider ──────────────────────────────────────────────
 
final ilanlarimProvider =
    StreamProvider.autoDispose<List<IlanModel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(ilanRepositoryProvider).kullaniciIlanlarStream(uid);
});
 
// ── Screen ────────────────────────────────────────────────
 
class IlanlarimScreen extends ConsumerStatefulWidget {
  const IlanlarimScreen({super.key});
 
  @override
  ConsumerState<IlanlarimScreen> createState() => _IlanlarimScreenState();
}
 
class _IlanlarimScreenState extends ConsumerState<IlanlarimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final ilanlarimAsync = ref.watch(ilanlarimProvider);
 
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('İlanlarım',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.red,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.red,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.dmSans(fontSize: 14),
          tabs: const [
            Tab(text: 'İstekler'),
            Tab(text: 'Gelenler'),
          ],
        ),
      ),
      body: ilanlarimAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.red, strokeWidth: 2)),
        error: (_, __) => Center(
          child: Text('Bir hata oluştu.',
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary)),
        ),
        data: (ilanlar) {
          final istekler = ilanlar
              .where((i) => i.tip == IlanTip.istek)
              .toList();
          final gelenler = ilanlar
              .where((i) => i.tip == IlanTip.tasiyici)
              .toList();
 
          return TabBarView(
            controller: _tabController,
            children: [
              _IlanListesi(ilanlar: istekler, tip: IlanTip.istek),
              _IlanListesi(ilanlar: gelenler, tip: IlanTip.tasiyici),
            ],
          );
        },
      ),
    );
  }
}
 
// ── İlan Listesi ──────────────────────────────────────────
 
class _IlanListesi extends ConsumerWidget {
  final List<IlanModel> ilanlar;
  final String tip;
 
  const _IlanListesi({required this.ilanlar, required this.tip});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ilanlar.isEmpty) {
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
            Text(
              tip == IlanTip.istek
                  ? 'İstekler sekmesinden ilan verebilirsin'
                  : 'Gelenler sekmesinden ilan verebilirsin',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
 
    if (tip == IlanTip.istek) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        padding: const EdgeInsets.all(6),
        itemCount: ilanlar.length,
        itemBuilder: (context, index) =>
            _IstekKarti(ilan: ilanlar[index], ref: ref),
      );
    }
 
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ilanlar.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 0),
      itemBuilder: (context, index) =>
          _GelenKarti(ilan: ilanlar[index], ref: ref),
    );
  }
}
 
// ── İstek Kartı ───────────────────────────────────────────
 
class _IstekKarti extends StatelessWidget {
  final IlanModel ilan;
  final WidgetRef ref;
  const _IstekKarti({required this.ilan, required this.ref});
 
  double _resimYuksekligi() {
    final heights = [160.0, 200.0, 140.0, 180.0, 220.0, 150.0];
    return heights[ilan.id.hashCode.abs() % heights.length];
  }
 
  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
 
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
                resimler.isNotEmpty
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
                // Aktif/Pasif badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ilan.aktif
                          ? const Color(0xFF2E7D32)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ilan.aktif ? 'Aktif' : 'Pasif',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
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
                  Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Gelen Kartı ───────────────────────────────────────────
 
class _GelenKarti extends StatelessWidget {
  final IlanModel ilan;
  final WidgetRef ref;
  const _GelenKarti({required this.ilan, required this.ref});
 
  @override
  Widget build(BuildContext context) {
    final tarihYazi = ilan.tarih != null
        ? '${ilan.tarih!.day}.${ilan.tarih!.month}.${ilan.tarih!.year}'
        : '';
 
    return InkWell(
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
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tarihYazi.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(tarihYazi,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ilan.aktif
                        ? const Color(0xFFE8F5E9)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ilan.aktif ? 'Aktif' : 'Pasif',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: ilan.aktif
                          ? const Color(0xFF2E7D32)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (ilan.ucret.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${ilan.ucret} ₺',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}