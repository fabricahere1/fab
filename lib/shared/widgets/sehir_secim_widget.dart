// lib/shared/widgets/sehir_secim_widget.dart
//
// Hem istekler (filtre_ekrani.dart, "İstek Şehri") hem gelenler
// (gelenler_screen.dart, "Varış Şehri") ekranlarında kullanılan ortak
// şehir seçim alanı. 81 ili checkbox listesi olarak gösterir, üstte
// "Tümü" seçeneği vardır. Sadece görsel + dialog state'i kapsar;
// Algolia'ya filtre olarak hangi alana (nereye/nereden) gönderileceği
// çağıran taraf tarafından yönetilir.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart' as app_constants;

class SehirSecimWidget extends StatelessWidget {
  final String baslik;          // 'İstek Şehri' veya 'Varış Şehri'
  final List<String> seciliSehirler;
  final ValueChanged<List<String>> onDegisti;
  final Color renk;

  const SehirSecimWidget({
    super.key,
    required this.baslik,
    required this.seciliSehirler,
    required this.onDegisti,
    this.renk = AppColors.red,
  });

  Future<void> _dialogAc(BuildContext context) async {
    List<String> temp = List.from(seciliSehirler);
    await showDialog<void>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(baslik,
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            height: 340,
            child: ListView(
              children: [
                CheckboxListTile(
                  dense: true,
                  title: Text('Tümü', style: GoogleFonts.dmSans(fontSize: 14)),
                  value: temp.isEmpty,
                  activeColor: renk,
                  onChanged: (v) {
                    if (v == true) setDlg(() => temp.clear());
                  },
                ),
                ...app_constants.kTurkiyeSehirleri.map((s) => CheckboxListTile(
                  dense: true,
                  title: Text(s, style: GoogleFonts.dmSans(fontSize: 14)),
                  value: temp.contains(s),
                  activeColor: renk,
                  onChanged: (v) {
                    setDlg(() => v == true ? temp.add(s) : temp.remove(s));
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: Text('İptal',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                onDegisti(List.from(temp));
                Navigator.pop(dlgCtx);
              },
              child: Text('Tamam',
                  style: GoogleFonts.dmSans(
                      color: renk, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dialogAc(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: seciliSehirler.isEmpty
              ? AppColors.surface
              : renk.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seciliSehirler.isEmpty
                ? AppColors.divider
                : renk.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 18,
                color: seciliSehirler.isEmpty
                    ? AppColors.textSecondary
                    : renk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                seciliSehirler.isEmpty
                    ? 'Tüm şehirler'
                    : seciliSehirler.join(', '),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: seciliSehirler.isEmpty
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: seciliSehirler.isEmpty
                    ? AppColors.textSecondary
                    : renk),
          ],
        ),
      ),
    );
  }
}

/// Başlık + Temizle linki + SehirSecimWidget'ı birlikte gösteren satır.
/// İçinde "Türkiye dışı" linki de opsiyonel olarak eklenebilir.
class SehirSecimBolumu extends StatelessWidget {
  final String baslik;
  final List<String> seciliSehirler;
  final ValueChanged<List<String>> onDegisti;
  final Color renk;
  final Widget? sagWidget; // örn. "Türkiye dışı" linki

  const SehirSecimBolumu({
    super.key,
    required this.baslik,
    required this.seciliSehirler,
    required this.onDegisti,
    this.renk = AppColors.red,
    this.sagWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text(baslik,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (seciliSehirler.isNotEmpty)
                GestureDetector(
                  onTap: () => onDegisti([]),
                  child: Text('Temizle',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: renk,
                          fontWeight: FontWeight.w500)),
                ),
              if (seciliSehirler.isNotEmpty && sagWidget != null)
                const SizedBox(width: 12),
              if (sagWidget != null) sagWidget!,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: SehirSecimWidget(
            baslik: baslik,
            seciliSehirler: seciliSehirler,
            onDegisti: onDegisti,
            renk: renk,
          ),
        ),
      ],
    );
  }
}