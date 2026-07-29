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

// Dart'ın toUpperCase()'i Türkçe'ye özel değil: küçük 'i' (noktalı) yanlışlıkla
// noktasız 'I'ya dönüşür (doğrusu 'İ'). Diğer Türkçe karakterler (ı, ş, ğ, ü,
// ö, ç) standart toUpperCase() ile zaten doğru büyüyor, yalnızca 'i' önceden
// elle 'İ'ye çevrilmeli.
String _turkceBuyuk(String s) => s.replaceAll('i', 'İ').toUpperCase();

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

  // Hero banner'daki uçak/bavul deseninin küçültülmüş, nötr renkli ve çok
  // daha soluk hâli — başlık şeridinin arkasına hafif bir doku katıyor,
  // metnin okunurluğunu bozmayacak kadar transparan (bkz. KesfetHeroBanner).
  static const _desenRengi = Color(0xFF455A64); // blue-grey — sayfadaki
  // turuncu/kırmızı vurgularla çakışmasın diye bilinçli olarak nötr seçildi.

  static const _desenIkonlari = <_DesenIkonu>[
    _DesenIkonu(Icons.flight_takeoff_rounded, top: -6, right: 8, size: 34, alpha: 0.08),
    _DesenIkonu(Icons.card_travel_outlined, bottom: -4, right: 60, size: 26, alpha: 0.07),
    _DesenIkonu(Icons.local_shipping_outlined, top: 6, right: 110, size: 22, alpha: 0.06),
    _DesenIkonu(Icons.shopping_bag_outlined, bottom: 2, right: 150, size: 20, alpha: 0.06),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                for (final d in _desenIkonlari)
                  Positioned(
                    top: d.top,
                    bottom: d.bottom,
                    right: d.right,
                    child: Icon(d.ikon, size: d.size, color: _desenRengi.withValues(alpha: d.alpha)),
                  ),
              ],
            ),
          ),
          Column(
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
                  _turkceBuyuk(baslik),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onTumunuGor != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTumunuGor,
                  child: Text(
                    'Tümü →',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
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
        ],
      ),
    );
  }
}

class _DesenIkonu {
  final IconData ikon;
  final double? top;
  final double? bottom;
  final double? right;
  final double size;
  final double alpha;

  const _DesenIkonu(
    this.ikon, {
    this.top,
    this.bottom,
    this.right,
    required this.size,
    required this.alpha,
  });
}