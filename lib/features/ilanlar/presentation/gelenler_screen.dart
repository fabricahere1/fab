import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../presentation/gelenler_form_screen.dart';
import '../presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';

class GelenlerScreen extends ConsumerStatefulWidget {
  const GelenlerScreen({super.key});

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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Gelenler',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        onRefresh: () =>
            ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
        child: state.yukleniyor && ilanlar.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.red, strokeWidth: 2))
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
                : ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    cacheExtent: 500,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: ilanlar.length + (state.dahaFazlaVar ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 0),
                    itemBuilder: (context, index) {
                      if (index == ilanlar.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.red),
                            ),
                          ),
                        );
                      }
                      return RepaintBoundary(
                        child: _GelenKarti(ilan: ilanlar[index]),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GelenlerFormScreen(),
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
}

// ── Gelen İlan Kartı ──────────────────────────────────────

class _GelenKarti extends StatelessWidget {
  final IlanModel ilan;
  const _GelenKarti({required this.ilan, super.key});

  String? _gelisYazisi() {
    if (ilan.tarih == null) return null;
    final bugun = DateTime.now();
    final tarih = ilan.tarih!;
    final fark = tarih
        .difference(DateTime(bugun.year, bugun.month, bugun.day))
        .inDays;
    if (fark < 0) return null;
    if (fark == 0) return 'Bugün geliyor';
    if (fark == 1) return 'Yarın geliyor';
    return '$fark gün sonra geliyor';
  }

  @override
  Widget build(BuildContext context) {
    final kategoriAdiStr = ilan.kategori.isNotEmpty && ilan.kategori != 'diger'
        ? ilan.kategori
            .split(',')
            .map((k) => kKategoriler[k.trim()] ?? k.trim())
            .join(', ')
        : '';

    final tarihYazi = ilan.tarih != null
        ? '${ilan.tarih!.day}.${ilan.tarih!.month}.${ilan.tarih!.year}'
        : '';

    final gelisYazisi = _gelisYazisi();

    Color gelisRenk = const Color(0xFF2E7D32);
    Color gelisArkaRenk = const Color(0xFFE8F5E9);
    if (gelisYazisi != null) {
      final fark = ilan.tarih!.difference(DateTime.now()).inDays;
      if (fark <= 3) {
        gelisRenk = const Color(0xFFE65100);
        gelisArkaRenk = const Color(0xFFFFF3E0);
      } else if (fark <= 7) {
        gelisRenk = const Color(0xFFF57F17);
        gelisArkaRenk = const Color(0xFFFFFDE7);
      }
    }

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
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOut),
              ),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flight_takeoff_outlined,
                    size: 16, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                if (tarihYazi.isNotEmpty) ...[
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(tarihYazi,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                ],
                if (gelisYazisi != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: gelisArkaRenk,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      gelisYazisi,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: gelisRenk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  ilan.ucret.isNotEmpty
                      ? '${ilan.ucret} ₺'
                      : 'Belirtilmemiş',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: ilan.ucret.isNotEmpty
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: ilan.ucret.isNotEmpty
                        ? AppColors.red
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),

            if (kategoriAdiStr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      kategoriAdiStr,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (ilan.notlar.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                ilan.notlar,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.avatarColor(ilan.kullaniciAd),
                  child: Text(
                    ilan.kullaniciAd.isNotEmpty
                        ? ilan.kullaniciAd[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ilan.kullaniciAd,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
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
          const Icon(Icons.flight_land_outlined,
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