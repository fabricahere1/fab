// lib/core/services/banner_service.dart
//
// Uygulama içi banner servisi.
// navigatorKey üzerinden overlay'e erişir.
// FCM foreground bildirimleri ve işlem durumu değişiklikleri buradan gösterilir.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../router/app_router.dart';
import '../../shared/constants/app_colors.dart';

class BannerService {
  BannerService._();
  static final BannerService instance = BannerService._();

  OverlayEntry? _mevcutBanner;
  bool _susturuldu = false;
  Map<String, dynamic>? _bekleyenBanner;

  /// Overlay aktifken bannerları beklet
  void sustur() => _susturuldu = true;

  /// Overlay kapanınca bekleyen varsa göster
  void aktifEt() {
    _susturuldu = false;
    if (_bekleyenBanner != null) {
      final b = _bekleyenBanner!;
      _bekleyenBanner = null;
      goster(
        baslik: b['baslik'] as String,
        icerik: b['icerik'] as String,
        tip: b['tip'] as String,
        onTap: b['onTap'] as VoidCallback?,
      );
    }
  }

  /// Genel banner — başlık + içerik + ikon tipi
  void goster({
    required String baslik,
    required String icerik,
    String tip = 'bilgi', // 'mesaj' | 'degerlendirme' | 'islem' | 'bilgi'
    VoidCallback? onTap,
  }) {
    if (_susturuldu) {
      _bekleyenBanner = {'baslik': baslik, 'icerik': icerik, 'tip': tip, 'onTap': onTap};
      return;
    }
    _kapat();

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _mevcutBanner = OverlayEntry(
      builder: (_) => _InAppBanner(
        baslik: baslik,
        icerik: icerik,
        tip: tip,
        onTap: () {
          _kapat();
          onTap?.call();
        },
        onKapat: _kapat,
      ),
    );

    overlay.insert(_mevcutBanner!);

    // Capture the specific entry — delayed callback must not close a newer banner
    final entry = _mevcutBanner!;
    Future.delayed(const Duration(seconds: 4), () {
      if (_mevcutBanner == entry) _kapat();
    });
  }

  void _kapat() {
    _mevcutBanner?.remove();
    _mevcutBanner = null;
  }
}

// ── Banner Widget ─────────────────────────────────────────

class _InAppBanner extends StatefulWidget {
  final String baslik;
  final String icerik;
  final String tip;
  final VoidCallback onTap;
  final VoidCallback onKapat;

  const _InAppBanner({
    required this.baslik,
    required this.icerik,
    required this.tip,
    required this.onTap,
    required this.onKapat,
  });

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData get _ikon {
    switch (widget.tip) {
      case 'mesaj':         return Icons.chat_bubble_outline_rounded;
      case 'degerlendirme': return Icons.star_outline_rounded;
      case 'islem':         return Icons.swap_horiz_rounded;
      default:              return Icons.notifications_outlined;
    }
  }

  Color get _ikonRenk {
    switch (widget.tip) {
      case 'mesaj':         return AppColors.primary;
      case 'degerlendirme': return const Color(0xFF81C784);
      case 'islem':         return const Color(0xFF81C784);
      default:              return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;

    return Positioned(
      top: statusH + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _ikonRenk.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_ikon, color: _ikonRenk, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.baslik,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.icerik.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.icerik,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onKapat,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
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