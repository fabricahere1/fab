// lib/features/home/presentation/kesfet_bolum_baslik.dart
//
// Keşfet (vitrin1/vitrin2) ve Sana Özel ekranlarındaki TÜM bölüm
// başlıklarının ortak, tek noktadan yönetilen hâli. Önceden her dosya
// kendi başlık satırını (farklı font: dmSerifDisplay, farklı "Tümünü Gör"
// yerleşimi: üstte/yanda) ayrı ayrı çiziyordu — bu tutarsızlığı ortadan
// kaldırıp, tek bir widget'a indiriyor.
//
// Tasarım kararı: dmSerifDisplay yerine DM Sans w800 kullanılıyor —
// uygulamanın gövde metniyle AYNI font ailesi, sadece ağırlık/boyutla
// hiyerarşi kuruluyor. İkon, soluk kırmızı bir daire içine alındı, başlığın
// altına ince bir kırmızı vurgu çizgisi eklendi.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';

class KesfetBolumBaslik extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final VoidCallback? onTumunuGor;

  const KesfetBolumBaslik({
    super.key,
    required this.baslik,
    required this.ikon,
    this.onTumunuGor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, size: 14, color: AppColors.red),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onTumunuGor != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTumunuGor,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'Tümünü Gör',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 37),
            child: Container(
              height: 2,
              width: 32,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}