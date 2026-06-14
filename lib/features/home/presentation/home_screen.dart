// lib/features/home/presentation/home_screen.dart

import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ilanlar/presentation/ilanlar_screen.dart';
import '../../ilanlar/providers/grid_tercihi_notifier.dart';
import '../../ilanlar/presentation/gelenler_screen.dart';
import '../../ilanlar/presentation/ilan_form_screen.dart';
import '../../ilanlar/presentation/gelenler_form_screen.dart';
import '../../mesajlar/presentation/mesajlar_screen.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../profil/presentation/profil_screen.dart';
import 'kesfet_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? _sonGeriTusu;
  bool _fabAcik = false;

  bool get _fabGoster =>
      _selectedIndex <= 1 &&
      !(_selectedIndex == 0 &&
          ref.read(gridTercihiProvider) == GoruntulemeModeli.swipe);

  @override
  void initState() {
    super.initState();
  }

  void _ilanVer() {
    setState(() => _fabAcik = !_fabAcik);
  }

  @override
  Widget build(BuildContext context) {
    final uid             = ref.watch(currentUserProvider)?.uid;
    final toplamOkunmamis = ref.watch(okunmamisSayiProvider);
    final bottomPadding   = MediaQuery.of(context).padding.bottom;

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
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: const [
                _IsteklerSayfa(),
                GelenlerScreen(embedded: true),
                MesajlarScreen(),
                ProfilScreen(),
                KesfetScreen(),
              ],
            ),
            if (_fabAcik)
              GestureDetector(
                onTap: () => setState(() => _fabAcik = false),
                child: AnimatedOpacity(
                  opacity: _fabAcik ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _fabGoster ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSlide(
              offset: _fabAcik ? Offset.zero : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _fabAcik ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  ignoring: !_fabAcik,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 160,
                        child: FloatingActionButton.extended(
                          heroTag: 'istek',
                          onPressed: () {
                            setState(() => _fabAcik = false);
                            Navigator.push(context, CupertinoPageRoute(
                              builder: (_) => IlanFormScreen(tip: IlanTip.istek),
                            ));
                          },
                          backgroundColor: const Color(0xFF9575CD),
                          elevation: 3,
                          label: Text('İstek İlanı Ver',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          icon: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 160,
                        child: FloatingActionButton.extended(
                          heroTag: 'gelen',
                          onPressed: () {
                            setState(() { _fabAcik = false; _selectedIndex = 1; });
                            Navigator.push(context, CupertinoPageRoute(
                              builder: (_) => const GelenlerFormScreen(),
                            ));
                          },
                          backgroundColor: const Color(0xFF9575CD),
                          elevation: 3,
                          label: Text('Gelen İlanı Ver',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          icon: const Icon(Icons.flight_takeoff_outlined,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            FloatingActionButton(
              heroTag: 'main',
              onPressed: _ilanVer,
              backgroundColor: const Color(0xFF66BB6A),
              elevation: 4,
              child: AnimatedRotation(
                turns: _fabAcik ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        )
        : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // iOS'ta scroll ile gizlenip görünür; Android'de her zaman sabit.
          height: (ref.watch(navBarGizliProvider) && !Platform.isAndroid)
              ? 0
              : 62 + bottomPadding,
          child: ClipRect(child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    _NavItem(
                      secili: _selectedIndex == 0,
                      onTap: () { setState(() { _selectedIndex = 0; _fabAcik = false; }); ref.read(navBarGizliProvider.notifier).goster(); },
                      label: 'İstekler',
                      child: Icon(Symbols.home, size: 24, fill: _selectedIndex == 0 ? 1 : 0, weight: 300,
                          color: _selectedIndex == 0 ? AppColors.red : Colors.black),
                    ),
                    _NavItem(
                      secili: _selectedIndex == 1,
                      onTap: () { setState(() { _selectedIndex = 1; _fabAcik = false; }); ref.read(navBarGizliProvider.notifier).goster(); },
                      label: 'Gelenler',
                      child: Icon(Symbols.flight_land, size: 24, fill: _selectedIndex == 1 ? 1 : 0, weight: 300,
                          color: _selectedIndex == 1 ? AppColors.red : Colors.black),
                    ),
                    _NavItem(
                      secili: _selectedIndex == 2,
                      onTap: () { setState(() { _selectedIndex = 2; _fabAcik = false; }); ref.read(navBarGizliProvider.notifier).goster(); },
                      label: 'Mesajlar',
                      child: uid == null || toplamOkunmamis == 0
                          ? Icon(Symbols.chat_bubble, size: 24, fill: _selectedIndex == 2 ? 1 : 0, weight: 300,
                              color: _selectedIndex == 2 ? AppColors.red : Colors.black)
                          : Badge(
                              label: Text(toplamOkunmamis > 99 ? '99+' : '$toplamOkunmamis',
                                  style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                              backgroundColor: AppColors.red,
                              child: Icon(Symbols.chat_bubble, size: 24, fill: _selectedIndex == 2 ? 1 : 0, weight: 300,
                                  color: _selectedIndex == 2 ? AppColors.red : Colors.black),
                            ),
                    ),
                    _NavItem(
                      secili: _selectedIndex == 3,
                      onTap: () { setState(() { _selectedIndex = 3; _fabAcik = false; }); ref.read(navBarGizliProvider.notifier).goster(); },
                      label: 'Profil',
                      child: Icon(Symbols.person, size: 24, fill: _selectedIndex == 3 ? 1 : 0, weight: 300,
                          color: _selectedIndex == 3 ? AppColors.red : Colors.black),
                    ),
                    _NavItem(
                      secili: _selectedIndex == 4,
                      onTap: () { setState(() { _selectedIndex = 4; _fabAcik = false; }); ref.read(navBarGizliProvider.notifier).goster(); },
                      label: 'Keşfet',
                      child: Icon(Symbols.explore, size: 24, fill: _selectedIndex == 4 ? 1 : 0, weight: 300,
                          color: _selectedIndex == 4 ? AppColors.red : Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

// ── İstekler sayfası wrapper ──────────────────────────────────────────────────

class _IsteklerSayfa extends StatelessWidget {
  const _IsteklerSayfa();

  @override
  Widget build(BuildContext context) => const IsteklerIcEkran();
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
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                color: secili ? AppColors.red : Colors.black,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}