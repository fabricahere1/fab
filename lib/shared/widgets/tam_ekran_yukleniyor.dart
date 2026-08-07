import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Bottom sheet/dialog sınırlarının dışına taşan, tüm ekranı kaplayan
/// yükleniyor göstergesi. Root Overlay'e OverlayEntry olarak eklenip
/// çıkarılmak üzere tasarlandı — bkz. TamEkranYukleniyorController.
class TamEkranYukleniyor extends StatelessWidget {
  final String mesaj;
  final Color renk;
  final double spinnerBoyutu;
  final double strokeGenisligi;
  final double fontBoyutu;

  const TamEkranYukleniyor({
    super.key,
    required this.mesaj,
    this.renk = AppColors.red,
    this.spinnerBoyutu = 36,
    this.strokeGenisligi = 2.5,
    this.fontBoyutu = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: spinnerBoyutu,
                height: spinnerBoyutu,
                child: CircularProgressIndicator(
                  color: renk,
                  strokeWidth: strokeGenisligi,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                mesaj,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: fontBoyutu,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Root Overlay üzerinde tek bir TamEkranYukleniyor OverlayEntry'sini
/// göster/gizle yönetimini kapsülleyen küçük yardımcı — sahibi olan
/// State, dispose() içinde gizle() çağırmalı (güvenlik ağı, ekrandan
/// erken çıkılırsa OverlayEntry'nin asılı kalmaması için).
class TamEkranYukleniyorController {
  OverlayEntry? _entry;

  void goster(
    BuildContext context,
    String mesaj, {
    Color renk = AppColors.red,
    double spinnerBoyutu = 36,
    double strokeGenisligi = 2.5,
    double fontBoyutu = 14,
  }) {
    _entry?.remove();
    final entry = OverlayEntry(
      builder: (_) => TamEkranYukleniyor(
        mesaj: mesaj,
        renk: renk,
        spinnerBoyutu: spinnerBoyutu,
        strokeGenisligi: strokeGenisligi,
        fontBoyutu: fontBoyutu,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _entry = entry;
  }

  void gizle() {
    _entry?.remove();
    _entry = null;
  }
}
