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
import '../../../shared/constants/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? _sonGeriTusu;

  final List<Widget> _pages = const [
    IsteklerScreen(),
    GelenlerScreen(),
    MesajlarScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final toplamOkunmamis = ref.watch(okunmamisSayiProvider);

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Çıkmak için tekrar basın',
                  style: GoogleFonts.dmSans()),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.red.withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppColors.red),
              label: 'İstekler',
            ),
            const NavigationDestination(
              icon: Icon(Icons.flight_land_outlined),
              selectedIcon: Icon(Icons.flight_land, color: AppColors.red),
              label: 'Gelenler',
            ),
            NavigationDestination(
              icon: uid == null || toplamOkunmamis == 0
                  ? const Icon(Icons.chat_bubble_outline)
                  : Badge(
                      label: Text(
                        toplamOkunmamis > 99 ? '99+' : '$toplamOkunmamis',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AppColors.red,
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
              selectedIcon: uid == null || toplamOkunmamis == 0
                  ? const Icon(Icons.chat_bubble, color: AppColors.red)
                  : Badge(
                      label: Text(
                        toplamOkunmamis > 99 ? '99+' : '$toplamOkunmamis',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AppColors.red,
                      child: const Icon(Icons.chat_bubble,
                          color: AppColors.red),
                    ),
              label: 'Mesajlar',
            ),
            // ✅ 3 çizgi ikonu
            const NavigationDestination(
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu, color: AppColors.red),
              label: 'Menü',
            ),
          ],
        ),
      ),
    );
  }
}