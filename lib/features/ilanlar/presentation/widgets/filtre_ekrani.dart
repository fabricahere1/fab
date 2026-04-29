// lib/features/ilanlar/presentation/widgets/filtre_ekrani.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart';

// ── Filtre Ekranı ─────────────────────────────────────────────────────────────

class FiltreEkrani extends StatefulWidget {
  final String? seciliAnaKey;
  final String? seciliAltKey;
  final void Function(String? anaKey, String? altKey) onSecildi;
  final VoidCallback onTemizle;

  const FiltreEkrani({
    super.key,
    required this.seciliAnaKey,
    required this.seciliAltKey,
    required this.onSecildi,
    required this.onTemizle,
  });

  @override
  State<FiltreEkrani> createState() => _FiltreEkraniState();
}

class _FiltreEkraniState extends State<FiltreEkrani> {
  String? _acikAnaKey;

  @override
  void initState() {
    super.initState();
    _acikAnaKey = widget.seciliAnaKey;
  }

  IconData _kategoriIkon(String key) {
    switch (key) {
      case 'giyim':      return Icons.checkroom_outlined;
      case 'elektronik': return Icons.smartphone_outlined;
      case 'guzellik':   return Icons.favorite_border;
      case 'ev':         return Icons.home_outlined;
      case 'spor':       return Icons.sports_soccer_outlined;
      case 'kultur':     return Icons.menu_book_outlined;
      case 'gida':       return Icons.coffee_outlined;
      default:           return Icons.grid_view_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text('Kategori',
                      style: GoogleFonts.dmSans(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (widget.seciliAnaKey != null)
                    GestureDetector(
                      onTap: widget.onTemizle,
                      child: Text('Temizle',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                itemCount: kKategoriAgaci.length,
                itemBuilder: (ctx, i) {
                  final ana       = kKategoriAgaci[i];
                  final acik      = _acikAnaKey == ana.key;
                  final secili    = widget.seciliAnaKey == ana.key;
                  final altSecili = ana.altlar
                      .any((a) => a.key == widget.seciliAltKey);
                  final vurgulu   = secili || altSecili;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          if (ana.altlar.isEmpty) {
                            widget.onSecildi(ana.key, null);
                          } else {
                            setState(() =>
                                _acikAnaKey = acik ? null : ana.key);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: (secili && !altSecili)
                                ? AppColors.red.withValues(alpha: 0.05)
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider
                                    .withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(_kategoriIkon(ana.key),
                                  size: 22,
                                  color: vurgulu
                                      ? AppColors.red
                                      : Colors.black87),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  ana.ad,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: vurgulu
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: vurgulu
                                        ? AppColors.red
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: acik ? 0.25 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: acik
                                      ? AppColors.red
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (acik && ana.altlar.isNotEmpty)
                        Container(
                          color: AppColors.surface,
                          child: Column(
                            children: [
                              _AltKategoriSatiri(
                                ad: 'Tümü',
                                secili: widget.seciliAnaKey == ana.key &&
                                    widget.seciliAltKey == null,
                                onTap: () =>
                                    widget.onSecildi(ana.key, null),
                              ),
                              ...ana.altlar.map((alt) =>
                                  _AltKategoriSatiri(
                                    ad: alt.ad,
                                    secili:
                                        widget.seciliAltKey == alt.key,
                                    onTap: () => widget.onSecildi(
                                        ana.key, alt.key),
                                  )),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AltKategoriSatiri extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;

  const _AltKategoriSatiri({
    required this.ad,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.only(left: 58, right: 20, top: 13, bottom: 13),
        decoration: BoxDecoration(
          color: secili
              ? AppColors.red.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ad,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
                  color: secili ? AppColors.red : AppColors.textPrimary,
                ),
              ),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: AppColors.red),
          ],
        ),
      ),
    );
  }
}

// ── Boş Ekranlar ──────────────────────────────────────────────────────────────

class FiltreBosBekran extends StatelessWidget {
  final VoidCallback onTemizle;
  const FiltreBosBekran({super.key, required this.onTemizle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_outlined,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Sonuç bulunamadı',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Filtre veya aramayı temizlemeyi deneyin',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onTemizle,
            child: Text('Filtreyi Temizle',
                style: GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class BosEkran extends StatelessWidget {
  final VoidCallback onYenile;
  const BosEkran({super.key, required this.onYenile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Henüz ilan yok',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('İlk ilanı sen ver!',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onYenile,
            child: Text('Yenile',
                style: GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
