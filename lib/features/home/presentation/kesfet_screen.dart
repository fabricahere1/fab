// lib/features/home/presentation/kesfet_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/features/arama/presentation/arama_screen.dart';
import 'sana_ozel_screen.dart';

class KesfetScreen extends StatefulWidget {
  const KesfetScreen({super.key});

  @override
  State<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends State<KesfetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── Üst bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: statusH),

                // ── Arama çubuğu ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) => const AramaScreen(),
                          transitionsBuilder: (_, anim, _, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 200),
                        ),
                      );
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: const Color(0xFFEEEEEE), width: 1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search_rounded,
                              size: 18, color: Color(0xFFCCCCCC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ne arıyorsun ?',
                              style: GoogleFonts.dmSans(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 48,
                  child: TabBar(
                    controller: _tabCtrl,
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.red,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Sana Özel'),
                      Tab(text: 'Keşfet'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── İçerik ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                SanaOzelScreen(),
                _KesfetTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keşfet tab — şimdilik boş
// ─────────────────────────────────────────────────────────────────────────────

class _KesfetTab extends StatelessWidget {
  const _KesfetTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_outlined,
              size: 56,
              color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Yakında',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
