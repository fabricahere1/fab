// lib/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ilanlar/presentation/ilanlar_screen.dart';
import '../../ilanlar/presentation/gelenler_screen.dart';
import '../../mesajlar/presentation/mesajlar_screen.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../../profil/presentation/profil_screen.dart';
import 'kesfet_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/bildirim_cani_widget.dart';

class _UcCizgiIkon extends StatelessWidget {
  final Color renk;
  const _UcCizgiIkon({required this.renk});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22, height: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(height: 2, decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(1))),
          Container(height: 2, decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(1))),
          Container(height: 2, width: 15, decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? _sonGeriTusu;

  late final TabController _ilanTabCtrl;

  @override
  void initState() {
    super.initState();
    _ilanTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ilanTabCtrl.dispose();
    super.dispose();
  }

  Widget _anaSayfa() {
    return Column(
      children: [
        _AnaSayfaAppBar(ilanTabCtrl: _ilanTabCtrl),
        Expanded(
          child: TabBarView(
            controller: _ilanTabCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              IsteklerIcEkran(),
              GelenlerScreen(embedded: true),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final toplamOkunmamis = ref.watch(okunmamisSayiProvider);

    final pages = [
      _anaSayfa(),
      const KesfetScreen(),
      const MesajlarScreen(),
      const ProfilScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }
        final simdi = DateTime.now();
        if (_sonGeriTusu == null ||
            simdi.difference(_sonGeriTusu!) > const Duration(seconds: 2)) {
          _sonGeriTusu = simdi;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Çıkmak için tekrar basın', style: GoogleFonts.dmSans()),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _NavItem(
                    secili: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                    label: 'Ana Sayfa',
                    child: _selectedIndex == 0
                        ? const Icon(Icons.home_rounded, size: 24, color: AppColors.red)
                        : const Icon(Icons.home_outlined, size: 24, color: AppColors.textSecondary),
                  ),
                  _NavItem(
                    secili: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                    label: 'Keşfet',
                    child: _selectedIndex == 1
                        ? const Icon(Icons.explore_rounded, size: 24, color: AppColors.red)
                        : const Icon(Icons.explore_outlined, size: 24, color: AppColors.textSecondary),
                  ),
                  _NavItem(
                    secili: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                    label: 'Mesajlar',
                    child: uid == null || toplamOkunmamis == 0
                        ? Icon(
                            _selectedIndex == 2 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                            size: 24,
                            color: _selectedIndex == 2 ? AppColors.red : AppColors.textSecondary,
                          )
                        : Badge(
                            label: Text(
                              toplamOkunmamis > 99 ? '99+' : '$toplamOkunmamis',
                              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: AppColors.red,
                            child: Icon(
                              _selectedIndex == 2 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                              size: 24,
                              color: _selectedIndex == 2 ? AppColors.red : AppColors.textSecondary,
                            ),
                          ),
                  ),
                  _NavItem(
                    secili: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                    label: 'Menü',
                    child: _UcCizgiIkon(
                      renk: _selectedIndex == 3 ? AppColors.red : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool secili;
  final VoidCallback onTap;
  final Widget child;
  final String label;

  const _NavItem({
    required this.secili,
    required this.onTap,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: secili ? FontWeight.w700 : FontWeight.w400,
                color: secili ? AppColors.red : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnaSayfaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController ilanTabCtrl;

  const _AnaSayfaAppBar({required this.ilanTabCtrl});

  @override
  Size get preferredSize => const Size.fromHeight(56 + 44);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'İSTE',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.red,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    const BildirimCaniWidget(),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: TabBar(
              controller: ilanTabCtrl,
              labelColor: AppColors.red,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.red,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [Tab(text: 'İstekler'), Tab(text: 'Gelenler')],
            ),
          ),
        ],
      ),
    );
  }
}