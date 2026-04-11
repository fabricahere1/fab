// lib/features/ilanlar/presentation/gelenler_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../presentation/gelenler_form_screen.dart';
import '../presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import '../../../core/cache/app_cache_manager.dart';

class GelenlerScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const GelenlerScreen({super.key, this.embedded = false});

  @override
  ConsumerState<GelenlerScreen> createState() => _GelenlerScreenState();
}

class _GelenlerScreenState extends ConsumerState<GelenlerScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

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
      ref.read(tasiyiciIlanlarProvider.notifier).dahaFazlaYukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(tasiyiciIlanlarProvider);
    final ilanlar = state.filtrelenmis;

    final body = RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
      child: state.yukleniyor && ilanlar.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2))
          : ilanlar.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: _BosEkran(
                        onYenile: () =>
                            ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 600,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: ilanlar.length + (state.dahaFazlaVar ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == ilanlar.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.red),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RepaintBoundary(
                        child: _GelenKarti(ilan: ilanlar[index]),
                      ),
                    );
                  },
                ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GelenlerFormScreen()),
          ),
          backgroundColor: AppColors.red,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('İlan Ver',
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Gelenler',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GelenlerFormScreen()),
        ),
        backgroundColor: AppColors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('İlan Ver',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Modern Kart — sol kare resim + sağda detaylar ─────────────────────────────

class _GelenKarti extends StatelessWidget {
  final IlanModel ilan;
  const _GelenKarti({required this.ilan});

  String? _gelisYazisi() {
    if (ilan.tarih == null) return null;
    final bugun = DateTime.now();
    final tarih = ilan.tarih!;
    final fark = tarih
        .difference(DateTime(bugun.year, bugun.month, bugun.day))
        .inDays;
    if (fark < 0) return null;
    if (fark == 0) return 'Bugün';
    if (fark == 1) return 'Yarın';
    return '$fark gün sonra';
  }

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    final gelisYazisi = _gelisYazisi();
    final kategoriAdiStr = app_constants.kategoriAdi(ilan.kategori);

    Color gelisRenk = AppColors.green;
    Color gelisArkaRenk = const Color(0xFFE8F5E9);
    if (gelisYazisi != null && ilan.tarih != null) {
      final fark = ilan.tarih!.difference(DateTime.now()).inDays;
      if (fark <= 1) {
        gelisRenk = AppColors.red;
        gelisArkaRenk = const Color(0xFFFFEBEE);
      } else if (fark <= 3) {
        gelisRenk = const Color(0xFFE65100);
        gelisArkaRenk = const Color(0xFFFFF3E0);
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sol: Kare Resim ──────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 110,
                child: resimler.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resimler.first,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        memCacheWidth: 200,
                        placeholder: (_, __) => Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.textHint, size: 28),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.textHint, size: 28),
                        ),
                      )
                    // Resim yoksa placeholder
                    : Container(
                        color: AppColors.surface,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flight_takeoff_outlined,
                                color: AppColors.red, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              ilan.nereden.length > 6
                                  ? ilan.nereden.substring(0, 6)
                                  : ilan.nereden,
                              style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // ── Sağ: Detaylar ────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Güzergah
                    Row(
                      children: [
                        const Icon(Icons.flight_takeoff_outlined,
                            size: 13, color: AppColors.red),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${ilan.nereden} → ${ilan.nereye}',
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Tarih + Geliş badge
                    Row(
                      children: [
                        if (ilan.tarih != null) ...[
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${ilan.tarih!.day}.${ilan.tarih!.month}.${ilan.tarih!.year}',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (gelisYazisi != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: gelisArkaRenk,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              gelisYazisi,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: gelisRenk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Notlar
                    if (ilan.notlar.isNotEmpty)
                      Text(
                        ilan.notlar,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Alt satır: fiyat + kategori + kullanıcı
                    Row(
                      children: [
                        // Kullanıcı avatarı
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.avatarColor(ilan.kullaniciAd),
                          child: Text(
                            ilan.kullaniciAd.isNotEmpty
                                ? ilan.kullaniciAd[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            ilan.kullaniciAd,
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Fiyat
                        if (ilan.ucret.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${ilan.ucret} ₺',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.red),
                            ),
                          ),
                      ],
                    ),

                    // Kategori chip
                    if (kategoriAdiStr.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.chipBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kategoriAdiStr,
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Sağ ok
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 44),
              child: Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textHint),
            ),
          ],
        ),
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
          const Icon(Icons.flight_land_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Henüz ilan yok',
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('İlk ilanı sen ver!',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textHint)),
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