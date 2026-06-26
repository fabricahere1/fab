// lib/features/home/presentation/kategori_vitrini_bolum.dart
//
// Keşfet sayfasında, ana kategorilerin (Kadın, Erkek, Çocuk, vb.) ikonlu
// kısayol satırı. Her kategoriye dokununca o kategorideki ilanlar
// KesfetBolumDetayScreen ile (mevcut, güvenli yönlendirme deseniyle) açılır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'kesfet_bolum_detay_screen.dart';

class KategoriVitriniBolum extends ConsumerWidget {
  const KategoriVitriniBolum({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final istek    = ref.watch(istekIlanlarProvider).filtrelenmis;
    final tasiyici = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
    final tumIlanlar = <IlanModel>[...istek, ...tasiyici];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.red),
            const SizedBox(width: 6),
            Text('Kategoriler',
                style: GoogleFonts.dmSerifDisplay(fontSize: 15, color: AppColors.textPrimary)),
          ]),
        ),
        SizedBox(
          height: 92,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: kKategoriAgaci.length,
            itemBuilder: (_, i) {
              final node = kKategoriAgaci[i];
              final altKeyler = node.altlar.map((a) => a.key).toSet();
              final ilgiliIlanlar = tumIlanlar.where((ilan) =>
                  ilan.kategoriYolu.contains(node.key) ||
                  altKeyler.contains(ilan.kategori) ||
                  ilan.anaKategori == node.key).toList();

              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KesfetBolumDetayScreen(
                      baslik: node.ad,
                      ilanlar: ilgiliIlanlar,
                      ikon: Icons.grid_view_rounded,
                    ),
                  ),
                ),
                child: Container(
                  width: 76,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Center(
                          child: Text(node.emoji, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(node.ad,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}