// lib/features/home/presentation/home_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ilanlar/presentation/ilanlar_screen.dart';
import '../../ilanlar/presentation/gelenler_screen.dart';
import '../../ilanlar/presentation/ilan_form_screen.dart';
import '../../ilanlar/presentation/gelenler_form_screen.dart';
import '../../mesajlar/presentation/mesajlar_screen.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
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

  void _ilanVer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32, height: 3,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.textPrimary, size: 22),
                title: Text('İstek İlanı Ver',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, CupertinoPageRoute(
                    builder: (_) => IlanFormScreen(tip: IlanTip.istek),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.flight_takeoff_outlined,
                    color: AppColors.textPrimary, size: 22),
                title: Text('Gelen İlanı Ver',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, CupertinoPageRoute(
                    builder: (_) => const GelenlerFormScreen(),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid             = ref.watch(currentUserProvider)?.uid;
    final toplamOkunmamis = ref.watch(okunmamisSayiProvider);
    final bottomPadding   = MediaQuery.of(context).padding.bottom;

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
        body: _LazyIndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          height: 62 + bottomPadding,
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
                  _IlanVerItem(onTap: _ilanVer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lazy IndexedStack — sadece ziyaret edilen sayfaları render eder ───────────

class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _LazyIndexedStack({
    required this.index,
    required this.children,
  });

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _initialized;

  @override
  void initState() {
    super.initState();
    // Sadece aktif tab build edilir, diğerleri ilk ziyarette build edilir
    _initialized = List.generate(
      widget.children.length,
      (i) => i == widget.index,
    );
  }

  @override
  void didUpdateWidget(_LazyIndexedStack old) {
    super.didUpdateWidget(old);
    if (!_initialized[widget.index]) {
      _initialized[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(
        widget.children.length,
        (i) => _initialized[i]
            ? widget.children[i]
            : const SizedBox.shrink(),
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

// ── İlan Ver nav item ────────────────────────────────────────────────────────

class _IlanVerItem extends StatelessWidget {
  final VoidCallback onTap;
  const _IlanVerItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_rounded,
                size: 24, color: Color(0xFF66BB6A)),
            const SizedBox(height: 3),
            Text(
              'İlan Ver',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── İlan tip seçim kartı ─────────────────────────────────────────────────────

class _IlanTipKarti extends StatelessWidget {
  final IconData icon;
  final Color renk;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const _IlanTipKarti({
    required this.icon,
    required this.renk,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: renk, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aciklama,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}