import 'g_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ilanlar_page.dart';
import 'favoriler_page.dart';
import 'mesajlar_page.dart';
import 'profil_page.dart';
import 'ilan_olustur_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // IlanlarPage içindeki tab controller burada tutuluyor
  // 0 = İstekler, 1 = Gelenler
  late TabController _ilanlarTabController;

  @override
  void initState() {
    super.initState();
    _ilanlarTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ilanlarTabController.dispose();
    super.dispose();
  }

  void goToProfile() {
    setState(() => _selectedIndex = 3);
  }

  void _goToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _ilanOlusturAc() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('İlan oluşturmak için giriş yapın.',
            style: GoogleFonts.roboto()),
        backgroundColor: GColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Hangi tab aktifse ona göre form aç
    // tab 0 = İstekler → initialTip: 1
    // tab 1 = Gelenler → initialTip: 0
    final aktifTab = _ilanlarTabController.index;
    final initialTip = aktifTab == 1 ? 0 : 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IlanOlusturPage(initialTip: initialTip),
      ),
    ).then((tip) {
      if (tip == null) return;

      // İlanlar sayfasına git
      setState(() => _selectedIndex = 0);

      // Doğru taba geç
      if (tip == 'tasiyici') {
        _ilanlarTabController.animateTo(1);
      } else {
        _ilanlarTabController.animateTo(0);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          tip == 'tasiyici'
              ? '✈️ Taşıyıcı ilanınız yayınlandı!'
              : '🛍️ İstek ilanınız yayınlandı!',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          IlanlarPage(
            onTabChanged: _goToTab,
            tabController: _ilanlarTabController,
          ),
          const FavorilerPage(),
          MesajlarPage(),
          const ProfilPage(),
        ],
      ),
      bottomNavigationBar: _NavBar(
        selectedIndex: _selectedIndex >= 2 ? _selectedIndex + 1 : _selectedIndex,
        onTap: (navIndex) {
          if (navIndex == 2) {
            _ilanOlusturAc();
          } else {
            final stateIndex = navIndex > 2 ? navIndex - 1 : navIndex;
            setState(() => _selectedIndex = stateIndex);
            // İlanlar butonuna basınca her zaman İstekler tabına git
            if (navIndex == 0) {
              _ilanlarTabController.animateTo(0);
            }
          }
        },
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: GColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'İlanlar',
                isActive: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bookmark_outline,
                activeIcon: Icons.bookmark,
                label: 'Favoriler',
                isActive: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItemCreate(onTap: () => onTap(2)),
              _NavItemWithBadge(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Mesajlar',
                isActive: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                isActive: selectedIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? GColors.primary : GColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? GColors.primary : GColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemCreate extends StatelessWidget {
  final VoidCallback onTap;
  const _NavItemCreate({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: GColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? GColors.primary : GColors.textSecondary,
                  size: 24,
                ),
                if (user != null)
                  StreamBuilder<int>(
                    stream: _okunmamisSayisi(user.uid),
                    builder: (context, snapshot) {
                      final sayi = snapshot.data ?? 0;
                      if (sayi == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: GColors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sayi > 9 ? '9+' : '$sayi',
                            style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? GColors.primary : GColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<int> _okunmamisSayisi(String userId) {
    return FirebaseFirestore.instance
        .collection('sohbetler')
        .where('kullanicilar', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int toplam = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final okunmamis = (data['okunmamis'] as Map<String, dynamic>?);
        toplam += ((okunmamis?[userId] as int?) ?? 0);
      }
      return toplam;
    });
  }
}