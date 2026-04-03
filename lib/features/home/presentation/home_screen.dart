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
import '../../bildirimler/presentation/bildirimler_screen.dart';
import '../../bildirimler/providers/bildirim_provider.dart';
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
    BildirimlerScreen(),
    ProfilScreen(),
  ];
 
  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final toplamOkunmamis = ref.watch(okunmamisSayiProvider);
    final okunmamisBildirim = ref.watch(okunmamisBildirimSayiProvider).value ?? 0;
 
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
            // Mesajlar — okunmamış badge
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
            // Bildirimler — okunmamış badge
            NavigationDestination(
              icon: okunmamisBildirim == 0
                  ? const Icon(Icons.notifications_outlined)
                  : Badge(
                      label: Text(
                        okunmamisBildirim > 99 ? '99+' : '$okunmamisBildirim',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AppColors.red,
                      child: const Icon(Icons.notifications_outlined),
                    ),
              selectedIcon: okunmamisBildirim == 0
                  ? const Icon(Icons.notifications, color: AppColors.red)
                  : Badge(
                      label: Text(
                        okunmamisBildirim > 99 ? '99+' : '$okunmamisBildirim',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AppColors.red,
                      child: const Icon(Icons.notifications,
                          color: AppColors.red),
                    ),
              label: 'Bildirimler',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.red),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}