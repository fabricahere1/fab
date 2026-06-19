// lib/features/ilanlar/presentation/widgets/arama_widgetlari.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart';

const double kKategoriBarYuksekligi = 46.0;

// ── Sıralama enum ─────────────────────────────────────────────────────────────

enum AramaSiralamaTipi { enYeni, enEski, ucretArtan, ucretAzalan }

extension AramaSiralamaTipiX on AramaSiralamaTipi {
  String get label {
    switch (this) {
      case AramaSiralamaTipi.enYeni:      return 'En yeni';
      case AramaSiralamaTipi.enEski:      return 'En eski';
      case AramaSiralamaTipi.ucretArtan:  return 'Ücret: Düşük → Yüksek';
      case AramaSiralamaTipi.ucretAzalan: return 'Ücret: Yüksek → Düşük';
    }
  }
}

// ── Şık Arama Çubuğu ─────────────────────────────────────────────────────────
// Köşeli (radius 12), subtle border, temiz görünüm

class AramaCubugu extends StatelessWidget {
  final TextEditingController controller;
  final String aramaMetni;
  final ValueChanged<String> onChanged;
  final VoidCallback onTemizle;

  const AramaCubugu({
    super.key,
    required this.controller,
    required this.aramaMetni,
    required this.onChanged,
    required this.onTemizle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Ara veya keşfet...',
          hintStyle: GoogleFonts.dmSans(
              color: AppColors.textHint, fontSize: 13),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: aramaMetni.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textSecondary),
                  onPressed: onTemizle,
                  padding: EdgeInsets.zero,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        ),
      ),
    );
  }
}

// ── Sıralama Butonu ───────────────────────────────────────────────────────────

class SiralamaButon extends StatelessWidget {
  final VoidCallback onTap;

  const SiralamaButon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: const Icon(Icons.tune_rounded,
            color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

// ── Filtre Butonu ─────────────────────────────────────────────────────────────
// Aktifken kırmızı dolgu

class FiltreButon extends StatelessWidget {
  final bool aktif;
  final VoidCallback onTap;

  const FiltreButon({super.key, required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: aktif ? AppColors.red : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: aktif ? AppColors.red : AppColors.divider,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: aktif ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            if (aktif)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Grid Toggle Butonu ────────────────────────────────────────────────────────

class GridToggleButon extends StatelessWidget {
  final int kolonSayisi;
  final VoidCallback onTap;

  const GridToggleButon({
    super.key,
    required this.kolonSayisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Icon(
          kolonSayisi == 2
              ? Icons.grid_view_rounded
              : Icons.view_column_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

// ── Filtre Badge ──────────────────────────────────────────────────────────────

class FiltreBadge extends StatelessWidget {
  final String metin;
  final VoidCallback onKaldir;

  const FiltreBadge({super.key, required this.metin, required this.onKaldir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metin,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onKaldir,
            child: const Icon(Icons.close_rounded,
                size: 13, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}

// ── Kategori Barı ─────────────────────────────────────────────────────────────

class KategoriBar extends StatelessWidget {
  final ScrollController scrollController;
  final String? seciliKey;
  final ValueChanged<String> onSec;

  const KategoriBar({
    super.key,
    required this.scrollController,
    required this.seciliKey,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kKategoriBarYuksekligi,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kKategoriAgaci.length,
        itemBuilder: (context, i) {
          final kat    = kKategoriAgaci[i];
          final secili = seciliKey == kat.key;

          return GestureDetector(
            onTap: () => onSec(kat.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin:
                  const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: secili ? AppColors.red : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                kat.ad,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secili ? Colors.white : const Color(0xFF222222),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}