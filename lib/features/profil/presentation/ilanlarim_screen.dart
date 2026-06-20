// lib/features/profil/presentation/ilanlarim_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/cache/app_cache_manager.dart';
import '../../../router/app_router.dart';

// 88x88 sabit kare resim alanı
const double _kResimBoyutu = 88.0;

class IlanlarimScreen extends ConsumerStatefulWidget {
  const IlanlarimScreen({super.key});

  @override
  ConsumerState<IlanlarimScreen> createState() => _IlanlarimScreenState();
}

class _IlanlarimScreenState extends ConsumerState<IlanlarimScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
        title: Text(
          'İlanlarım',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.red,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.red,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.manrope(fontSize: 14),
          tabs: const [
            Tab(text: 'İstek İlanlarım'),
            Tab(text: 'Taşıyıcı İlanlarım'),
          ],
        ),
      ),
      body: ilanlarimAsync.when(
        skipLoadingOnReload: true,
        skipError: true,
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.red,
            strokeWidth: 2,
          ),
        ),
        error: (_, _) => Center(
          child: Text(
            'Bir hata oluştu.',
            style: GoogleFonts.manrope(color: AppColors.textSecondary),
          ),
        ),
        data: (ilanlar) {
          final istekler =
              ilanlar.where((i) => i.tip == IlanTip.istek).toList();
          final tasiyicilar =
              ilanlar.where((i) => i.tip == IlanTip.tasiyici).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _IlanListesi(ilanlar: istekler, tip: IlanTip.istek),
              _IlanListesi(ilanlar: tasiyicilar, tip: IlanTip.tasiyici),
            ],
          );
        },
      ),
    );
  }
}

// ── Liste ─────────────────────────────────────────────────────────────────────

class _IlanListesi extends StatelessWidget {
  final List<IlanModel> ilanlar;
  final String tip;

  const _IlanListesi({required this.ilanlar, required this.tip});

  @override
  Widget build(BuildContext context) {
    if (ilanlar.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              tip == IlanTip.istek
                  ? 'Henüz istek ilanın yok'
                  : 'Henüz taşıyıcı ilanın yok',
              style: GoogleFonts.manrope(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (tip == IlanTip.istek) {
      return ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: ilanlar.length,
        separatorBuilder: (_, _) => const SizedBox(height: 5),
        itemBuilder: (context, index) => _IstekKarti(ilan: ilanlar[index]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: ilanlar.length,
      separatorBuilder: (_, _) => const SizedBox(height: 5),
      itemBuilder: (context, index) => _GelenKarti(ilan: ilanlar[index]),
    );
  }
}

// ── İstek Kartı — yatay liste, sol 88x88 resim + sağ metin ───────────────────

class _IstekKarti extends StatelessWidget {
  final IlanModel ilan;

  const _IstekKarti({required this.ilan});

  void _detayaGit(BuildContext context) {
    context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
  }

  @override
  Widget build(BuildContext context) {
    final gridResim = ilan.gridResim;
    final varResim = gridResim.isNotEmpty;

    return GestureDetector(
      onTap: () => _detayaGit(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sol: 88x88 sabit kare resim, ortalanmış ───────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: _kResimBoyutu,
                height: _kResimBoyutu,
                child: Center(
                  child: varResim
                      ? CachedNetworkImage(
                          cacheManager: AppCacheManager.instance,
                          imageUrl: gridResim,
                          fit: BoxFit.cover,
                          width: _kResimBoyutu,
                          height: _kResimBoyutu,
                          fadeInDuration: Duration.zero,
                          memCacheWidth: 200,
                          placeholder: (_, _) =>
                              Container(color: AppColors.surface),
                          errorWidget: (_, _, _) => _ResimYok(),
                        )
                      : _ResimYok(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Sağ: ürün adı, güzergah, ücret, badge ─────────────
            Expanded(
              child: SizedBox(
                height: _kResimBoyutu,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _AktifBadge(aktif: ilan.aktif),
                      ],
                    ),
                    Text(
                      '${ilan.nereden} → ${ilan.nereye}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ilan.ucret.isNotEmpty)
                      Text(
                        '${ilan.ucret} ₺',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red,
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

// ── Taşıyıcı Kartı (değişmedi) ───────────────────────────────────────────────

class _GelenKarti extends StatelessWidget {
  final IlanModel ilan;

  const _GelenKarti({required this.ilan});

  void _detayaGit(BuildContext context) {
    context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
  }

  @override
  Widget build(BuildContext context) {
    final gridResim = ilan.gridResim;
    final varResim = gridResim.isNotEmpty;
    final tarih = ilan.tarih;
    final tarihYazi = tarih != null
        ? '${tarih.day}.${tarih.month}.${tarih.year}'
        : '';

    return GestureDetector(
      onTap: () => _detayaGit(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: _kResimBoyutu,
                height: _kResimBoyutu,
                child: Center(
                  child: varResim
                      ? CachedNetworkImage(
                          cacheManager: AppCacheManager.instance,
                          imageUrl: gridResim,
                          fit: BoxFit.cover,
                          width: _kResimBoyutu,
                          height: _kResimBoyutu,
                          fadeInDuration: Duration.zero,
                          memCacheWidth: 200,
                          placeholder: (_, _) =>
                              Container(color: AppColors.surface),
                          errorWidget: (_, _, _) => _ResimYok(),
                        )
                      : _ResimYok(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: _kResimBoyutu,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${ilan.nereden} → ${ilan.nereye}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _AktifBadge(aktif: ilan.aktif, stil: _AktifBadgeStil.light),
                      ],
                    ),
                    if (tarihYazi.isNotEmpty)
                      Text(
                        tarihYazi,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (ilan.ucret.isNotEmpty)
                      Text(
                        '${ilan.ucret} ₺',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red,
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

// ── Ortak yardımcı widget'lar ─────────────────────────────────────────────────

class _ResimYok extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textHint, size: 28),
      ),
    );
  }
}

enum _AktifBadgeStil { solid, light }

class _AktifBadge extends StatelessWidget {
  final bool aktif;
  final _AktifBadgeStil stil;

  const _AktifBadge({
    required this.aktif,
    this.stil = _AktifBadgeStil.solid,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = stil == _AktifBadgeStil.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: aktif
            ? (isLight ? const Color(0xFFE8F5E9) : const Color(0xFF2E7D32))
            : (isLight ? AppColors.surface : Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        aktif ? 'Aktif' : 'Pasif',
        style: GoogleFonts.manrope(
          fontSize: isLight ? 11 : 10,
          color: aktif
              ? (isLight ? const Color(0xFF2E7D32) : Colors.white)
              : (isLight ? AppColors.textSecondary : Colors.white),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}