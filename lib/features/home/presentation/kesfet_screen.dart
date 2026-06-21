// lib/features/home/presentation/kesfet_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/arama/presentation/arama_screen.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/ilanlar/presentation/ilan_form_screen.dart';
import 'sana_ozel_screen.dart';
import 'kesfet_vitrin_tab.dart';
import 'kesfet_vitrin2_tab.dart';

class KesfetScreen extends ConsumerStatefulWidget {
  const KesfetScreen({super.key});

  @override
  ConsumerState<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends ConsumerState<KesfetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  double _sonPixel = 0;
  static const _threshold = 80.0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) return;
      _sonPixel = 0;
      ref.read(navBarGizliProvider.notifier).goster();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification n) {
    if (n.metrics.axis == Axis.horizontal) return false;
    if (n is! ScrollUpdateNotification) return false;
    if (n.scrollDelta == null) return false;

    final simdi = n.metrics.pixels;
    final gizli = ref.read(navBarGizliProvider);

    if (n.scrollDelta! > 0) {
      _sonPixel = simdi;
      if (!gizli) ref.read(navBarGizliProvider.notifier).gizle();
    } else if (n.scrollDelta! < 0) {
      if (simdi < _sonPixel - _threshold) {
        _sonPixel = simdi;
        if (gizli) ref.read(navBarGizliProvider.notifier).goster();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusH  = MediaQuery.of(context).padding.top;
    // navBarGizliProvider'ı dinle — nav bar gizliyse üst bar da gizlenir
    final ustGizli = ref.watch(navBarGizliProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Status bar — her zaman sabit
          Container(height: statusH, color: Colors.white),

          // Arama + Tab bar — nav bar ile senkron
          Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    heightFactor: ustGizli ? 0.0 : 1.0,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) => const AramaScreen(),
                            transitionsBuilder: (_, anim, _, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 200),
                          ),
                        ),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(Icons.search_rounded, size: 18, color: Color(0xFFCCCCCC)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Ne arıyorsun ?',
                                    style: GoogleFonts.dmSans(color: const Color(0xFFCCCCCC), fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabCtrl,
                  labelStyle: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w500),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.red,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [Tab(text: 'Keşfet'), Tab(text: 'Sana Özel')],
                ),
              ],
            ),
          ),

          // ── Promosyon bandı — arama/tab ile içerik arasında ──────────────
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => IlanFormScreen(tip: IlanTip.istek),
              ),
            ),
            child: Container(
              width: double.infinity,
              color: const Color(0xFFEDE7F6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'İlk ilanını ver, öne çıkaralım!',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.black54),
                ],
              ),
            ),
          ),

          // İçerik
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onNotification,
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _KesfetTumEkran(),
                  SanaOzelScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Keşfet tam ekranı — vitrin1 + vitrin2 alt alta ───────────────────────────

class _KesfetTumEkran extends ConsumerWidget {
  const _KesfetTumEkran();

  Future<void> _yenile(WidgetRef ref) async {
    await Future.wait([
      ref.read(istekIlanlarProvider.notifier).yenile(),
      ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _yenile(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: const [
            KesfetVitrinTab(),
            KesfetVitrin2Tab(),
          ],
        ),
      ),
    );
  }
}