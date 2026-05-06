import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/features/home/presentation/kesfet/tabs/harita_tab.dart';
import 'package:iste_v3/features/home/presentation/kesfet/tabs/canli_tab.dart';
import 'package:iste_v3/features/home/presentation/kesfet/tabs/kesfet_tab.dart';


class KesfetScreen extends ConsumerStatefulWidget {
  const KesfetScreen({super.key});

  @override
  ConsumerState<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends ConsumerState<KesfetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
          Container(height: statusH, color: Colors.white),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Keşfet',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: AppColors.red,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.red,
                  indicatorWeight: 2.5,
                  labelStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: const [
                    Tab(text: '🌍  Harita'),
                    Tab(text: '⚡  Canlı'),
                    Tab(text: '✨  Keşfet'),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.divider),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                HaritaTab(),
                CanliTab(),
                KesfetTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
