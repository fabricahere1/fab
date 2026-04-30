import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';

class AnlasmaOneriSheet extends StatelessWidget {
  final String karsiKullaniciAd;
  final String ilanBaslik;
  final double? onerilenfiyat;

  const AnlasmaOneriSheet({
    super.key,
    required this.karsiKullaniciAd,
    required this.ilanBaslik,
    this.onerilenfiyat,
  });

  static Future<bool?> goster(
    BuildContext context, {
    required String karsiKullaniciAd,
    required String ilanBaslik,
    double? onerilenfiyat,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnlasmaOneriSheet(
        karsiKullaniciAd: karsiKullaniciAd,
        ilanBaslik: ilanBaslik,
        onerilenfiyat: onerilenfiyat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Başlık
          Row(
            children: [
              const Icon(Icons.handshake_outlined, color: AppColors.green, size: 22),
              const SizedBox(width: 8),
              Text('Hızlı Anlaş',
                  style: GoogleFonts.dmSans(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$karsiKullaniciAd · "$ilanBaslik"',
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Tek seçenek kartı
          Builder(builder: (context) {
            final varFiyat = onerilenfiyat != null && onerilenfiyat! > 0;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.green, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    varFiyat ? Icons.check_circle_rounded : Icons.chat_bubble_outline_rounded,
                    color: AppColors.green, size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          varFiyat
                              ? 'İstekçinin belirlediği fiyattan getirebilirim'
                              : 'İlanınızla ilgileniyorum, hadi konuşalım!',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          varFiyat
                              ? '${onerilenfiyat!.toStringAsFixed(0)} ₺'
                              : 'Fiyat belirtilmemiş — sohbet başlatır',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),

          // Bilgi kutusu
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Karşı taraf onaylarsa anlaşma tamamlanır.',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Builder(builder: (context) {
            final varFiyat = onerilenfiyat != null && onerilenfiyat! > 0;
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      varFiyat ? 'Anlaşmayı Öner' : 'Mesaj Gönder',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Icon(varFiyat
                        ? Icons.handshake_outlined
                        : Icons.send_rounded,
                        size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
