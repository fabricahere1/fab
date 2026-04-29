// lib/features/home/presentation/home_screen.dart
//
// DEĞİŞİKLİKLER:
// - İstekler/Gelenler tab bar KALDIRILDI
// - İstekler otomatik açılıyor (ana ekran)
// - Gelenler nav bar'a taşındı (index 1)
// - Nav sırası: İstekler · Gelenler · Mesajlar · Keşfet · Profil
// - _AnaSayfaAppBar sadeleşti (tab yok)

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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? _sonGeriTusu;

  @override
  Widget build(BuildContext context) {
    final uid             = ref.watch(currentUserProvider)?.uid;
    final toplamOkunmamis = ref.watch(okunmamisSayiProvider);

    final pages = [
      const _IsteklerSayfa(),
      const GelenlerScreen(embedded: true),
      const MesajlarScreen(),
      const KesfetScreen(),
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
            content: Text('Çıkmak için tekrar basın',
                style: GoogleFonts.dmSans()),
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
            border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  // ── İstekler ───────────────────────────────────────
                  _NavItem(
                    secili: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                    label: 'İstekler',
                    child: Icon(
                      _selectedIndex == 0
                          ? Icons.home_rounded
                          : Icons.home_outlined,
                      size: 24,
                      color: _selectedIndex == 0
                          ? AppColors.red
                          : AppColors.textSecondary,
                    ),
                  ),

                  // ── Gelenler ───────────────────────────────────────
                  _NavItem(
                    secili: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                    label: 'Gelenler',
                    child: Icon(
                      _selectedIndex == 1
                          ? Icons.flight_land_rounded
                          : Icons.flight_land_outlined,
                      size: 24,
                      color: _selectedIndex == 1
                          ? AppColors.red
                          : AppColors.textSecondary,
                    ),
                  ),

                  // ── Mesajlar ───────────────────────────────────────
                  _NavItem(
                    secili: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                    label: 'Mesajlar',
                    child: uid == null || toplamOkunmamis == 0
                        ? Icon(
                            _selectedIndex == 2
                                ? Icons.chat_bubble
                                : Icons.chat_bubble_outline,
                            size: 24,
                            color: _selectedIndex == 2
                                ? AppColors.red
                                : AppColors.textSecondary,
                          )
                        : Badge(
                            label: Text(
                              toplamOkunmamis > 99
                                  ? '99+'
                                  : '$toplamOkunmamis',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: AppColors.red,
                            child: Icon(
                              _selectedIndex == 2
                                  ? Icons.chat_bubble
                                  : Icons.chat_bubble_outline,
                              size: 24,
                              color: _selectedIndex == 2
                                  ? AppColors.red
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),

                  // ── Keşfet ─────────────────────────────────────────
                  _NavItem(
                    secili: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                    label: 'Keşfet',
                    child: Icon(
                      _selectedIndex == 3
                          ? Icons.explore_rounded
                          : Icons.explore_outlined,
                      size: 24,
                      color: _selectedIndex == 3
                          ? AppColors.red
                          : AppColors.textSecondary,
                    ),
                  ),

                  // ── Profil ─────────────────────────────────────────
                  _NavItem(
                    secili: _selectedIndex == 4,
                    onTap: () => setState(() => _selectedIndex = 4),
                    label: 'Profil',
                    child: Icon(
                      _selectedIndex == 4
                          ? Icons.person_rounded
                          : Icons.person_outline,
                      size: 24,
                      color: _selectedIndex == 4
                          ? AppColors.red
                          : AppColors.textSecondary,
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

// ── İstekler sayfası wrapper — kendi AppBar'ı var ─────────────────────────────

class _IsteklerSayfa extends StatelessWidget {
  const _IsteklerSayfa();

  @override
  Widget build(BuildContext context) {
    return const IsteklerIcEkran();
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────

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
                fontWeight:
                    secili ? FontWeight.w700 : FontWeight.w400,
                color: secili
                    ? AppColors.red
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}