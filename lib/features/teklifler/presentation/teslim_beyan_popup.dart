// lib/features/teklifler/presentation/teslim_beyan_popup.dart
//
// Getiren (ilan sahibi) teslim beyanı yapar:
// - Elden teslim ettim
// - Henüz teslim etmedim

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';
import '../providers/teklif_provider.dart';
import 'kargo_bilgi_sheet.dart';

class TeslimBeyanPopup extends ConsumerWidget {
  final String teklifId;
  const TeslimBeyanPopup({super.key, required this.teklifId});

  static Future<void> goster(BuildContext context, String teklifId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => TeslimBeyanPopup(teklifId: teklifId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yukleniyor = ref.watch(teslimProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Text('Teslim Durumu',
              style: GoogleFonts.dmSans(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Ürünü nasıl teslim etmek istiyorsun?',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // Elden teslim
          _TeslimSecenegi(
            ikon: Icons.handshake_outlined,
            baslik: 'Elden Teslim',
            aciklama: 'Ürünü yüz yüze teslim ettim',
            renk: AppColors.green,
            yukleniyor: yukleniyor,
            onTap: () async {
              final basarili = await ref
                  .read(teslimProvider.notifier)
                  .eldenTeslimBeyan(teklifId: teklifId);
              if (context.mounted) {
                Navigator.pop(context);
                if (basarili) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Teslim beyanı kaydedildi.',
                        style: GoogleFonts.dmSans()),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
          const SizedBox(height: 12),

          // Kargo ile
          _TeslimSecenegi(
            ikon: Icons.local_shipping_outlined,
            baslik: 'Kargo ile Gönder',
            aciklama: 'Kargo şirketi ve takip numarası gir',
            renk: AppColors.red,
            yukleniyor: yukleniyor,
            onTap: () {
              Navigator.pop(context);
              KargoBilgiSheet.goster(context, teklifId);
            },
          ),
          const SizedBox(height: 12),

          // Henüz değil
          _TeslimSecenegi(
            ikon: Icons.schedule_outlined,
            baslik: 'Henüz Teslim Etmedim',
            aciklama: 'Teslim etmediğimi bildir',
            renk: AppColors.textSecondary,
            yukleniyor: yukleniyor,
            outlined: true,
            onTap: () async {
              final basarili = await ref
                  .read(teslimProvider.notifier)
                  .henuzDegilBeyan(teklifId: teklifId);
              if (context.mounted) {
                Navigator.pop(context);
                if (basarili) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Bildirim kaydedildi.',
                        style: GoogleFonts.dmSans()),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TeslimSecenegi extends StatelessWidget {
  final IconData ikon;
  final String baslik, aciklama;
  final Color renk;
  final bool yukleniyor, outlined;
  final VoidCallback onTap;

  const _TeslimSecenegi({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.renk,
    required this.yukleniyor,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: yukleniyor ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : renk.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: outlined
                ? AppColors.divider
                : renk.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: outlined
                    ? AppColors.surface
                    : renk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, color: renk, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: outlined
                              ? AppColors.textSecondary
                              : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(aciklama,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
