// lib/features/profil/presentation/ilanlarim_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/cache/app_cache_manager.dart';
import '../../../router/app_router.dart';

// Ana akıştaki yükseklikler: [160, 200, 140, 180, 220, 150] → ortalama ~175
// Bunun yarısı → sabit 88px
const double _kResimYuksekligi = 88.0;

// Sticker çerçeve kalınlığı ve köşe yarıçapı
const double _kStickerBorder = 3.0;
const double _kStickerRadius = 12.0;

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
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
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
          labelStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14),
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
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
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
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (tip == IlanTip.istek) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: const EdgeInsets.all(10),
        itemCount: ilanlar.length,
        itemBuilder: (context, index) => _IstekKarti(ilan: ilanlar[index]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ilanlar.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _GelenKarti(ilan: ilanlar[index]),
    );
  }
}

// ── İstek Kartı — yarı boyut resim + sticker çerçeve ─────────────────────────

class _IstekKarti extends StatelessWidget {
  final IlanModel ilan;

  const _IstekKarti({required this.ilan});

  void _detayaGit(BuildContext context) {
    context.push(AppRoutes.ilanDetayPath(ilan.id));
  }

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    final varResim = resimler.isNotEmpty;

    return GestureDetector(
      onTap: () => _detayaGit(context),
      child: Container(
        // ── Sticker dış gölge ──────────────────────────────────
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kStickerRadius),
          boxShadow: [
            // Yumuşak ana gölge
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            // Sert alt gölge — sticker baskı hissi
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 0,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Resim alanı ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_kStickerRadius),
              ),
              child: Stack(
                children: [
                  // Resim
                  SizedBox(
                    height: _kResimYuksekligi,
                    width: double.infinity,
                    child: varResim
                        ? CachedNetworkImage(
                            cacheManager: AppCacheManager.instance,
                            imageUrl: resimler.first,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            memCacheWidth: 300,
                            placeholder: (_, _) =>
                                Container(color: AppColors.surface),
                            errorWidget: (_, _, _) => _ResimYok(),
                          )
                        : _ResimYok(),
                  ),

                  // ── Sticker beyaz iç çerçeve (üst + yan kenarlar) ──
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.white, width: _kStickerBorder),
                          left: BorderSide(
                              color: Colors.white, width: _kStickerBorder),
                          right: BorderSide(
                              color: Colors.white, width: _kStickerBorder),
                        ),
                      ),
                    ),
                  ),

                  // Aktif / Pasif badge
                  Positioned(
                    top: _kStickerBorder + 4,
                    left: _kStickerBorder + 4,
                    child: _AktifBadge(aktif: ilan.aktif),
                  ),
                ],
              ),
            ),

            // ── Alt metin alanı (sticker alt şerit) ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
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

// ── Taşıyıcı Kartı (değişmedi) ───────────────────────────────────────────────

class _GelenKarti extends StatelessWidget {
  final IlanModel ilan;

  const _GelenKarti({required this.ilan});

  void _detayaGit(BuildContext context) {
    context.push(AppRoutes.ilanDetayPath(ilan.id));
  }

  @override
  Widget build(BuildContext context) {
    final tarih = ilan.tarih;
    final tarihYazi = tarih != null
        ? '${tarih.day}.${tarih.month}.${tarih.year}'
        : '';

    return InkWell(
      onTap: () => _detayaGit(context),
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tarihYazi.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tarihYazi,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AktifBadge(aktif: ilan.aktif, stil: _AktifBadgeStil.light),
                  if (ilan.ucret.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${ilan.ucret} ₺',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
        style: GoogleFonts.dmSans(
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