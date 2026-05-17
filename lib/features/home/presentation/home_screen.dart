// lib/features/home/presentation/home_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bildirimler/providers/bildirim_provider.dart';
import '../../ilanlar/presentation/ilanlar_screen.dart';
import '../../ilanlar/presentation/gelenler_screen.dart';
import '../../ilanlar/presentation/ilan_form_screen.dart';
import '../../ilanlar/presentation/gelenler_form_screen.dart';
import '../../mesajlar/presentation/mesajlar_screen.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../../bildirimler/presentation/bildirimler_screen.dart';

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
    final toplamOkunmamis = ref.watch(okunmamisSayiProvider);
    final okunmamisBildirim = ref.watch(okunmamisBildirimSayiProvider).value ?? 0;
    final bottomPadding   = MediaQuery.of(context).padding.bottom;

    final pages = [
      const _IsteklerSayfa(),
      const GelenlerScreen(embedded: true),
      const MesajlarScreen(),
      const BildirimlerScreen(),
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
                  // ── Anasayfa ────────────────────────────────────────────
                  _XNavItem(
                    secili: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                    label: 'İstekler',
                    icon: _selectedIndex == 0
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                  ),

                  // ── Gelenler ────────────────────────────────────────────
                  _XNavItem(
                    secili: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                    label: 'Gelenler',
                    icon: Icons.flight_land_rounded,
                  ),

                  // ── İlan Ver — siyah yükseltilmiş ──────────────────────
                  Expanded(
                    child: GestureDetector(
                      onTap: _ilanVer,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: _AnimatedPressWidget(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Bildirimler ─────────────────────────────────────────
                  _XNavItem(
                    secili: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                    label: 'Bildirim',
                    icon: _selectedIndex == 3
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    badge: okunmamisBildirim > 0 ? okunmamisBildirim : null,
                  ),

                  // ── Mesajlar ────────────────────────────────────────────
                  _XNavItem(
                    secili: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                    label: 'Mesajlar',
                    icon: _selectedIndex == 2
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    badge: toplamOkunmamis > 0 ? toplamOkunmamis : null,
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

// ── Lazy IndexedStack ─────────────────────────────────────────────────────────

class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _LazyIndexedStack({required this.index, required this.children});

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _initialized;

  @override
  void initState() {
    super.initState();
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
        (i) => _initialized[i] ? widget.children[i] : const SizedBox.shrink(),
      ),
    );
  }
}

// ── İstekler wrapper ──────────────────────────────────────────────────────────

class _IsteklerSayfa extends StatelessWidget {
  const _IsteklerSayfa();

  @override
  Widget build(BuildContext context) => const IsteklerIcEkran();
}

// ── X stili nav item ──────────────────────────────────────────────────────────

class _XNavItem extends StatelessWidget {
  final bool secili;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final int? badge;

  const _XNavItem({
    required this.secili,
    required this.onTap,
    required this.icon,
    required this.label,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _AnimatedPressWidget(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: secili ? AppColors.red : AppColors.textSecondary,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
                  color: secili ? AppColors.red : const Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: secili ? 4 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Basınca büyüme animasyonu ─────────────────────────────────────────────────

class _AnimatedPressWidget extends StatefulWidget {
  final Widget child;
  const _AnimatedPressWidget({required this.child});

  @override
  State<_AnimatedPressWidget> createState() => _AnimatedPressWidgetState();
}

class _AnimatedPressWidgetState extends State<_AnimatedPressWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _ctrl.forward(),
      onPointerUp: (_) => _ctrl.reverse(),
      onPointerCancel: (_) => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}