import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/degerlendirme_repository.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';

// ── Provider ──────────────────────────────────────────────

final kullaniciDegerlendirmeleriProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
        (ref, kullaniciId) => ref
            .read(degerlendirmeRepositoryProvider)
            .kullaniciDegerlendirmeleriStream(kullaniciId));

// ── Ekran ─────────────────────────────────────────────────

class DegerlendirmelerListeScreen extends ConsumerWidget {
  final String kullaniciId;
  final String kullaniciAd;

  const DegerlendirmelerListeScreen({
    super.key,
    required this.kullaniciId,
    required this.kullaniciAd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync =
        ref.watch(kullaniciDegerlendirmeleriProvider(kullaniciId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '$kullaniciAd · Değerlendirmeler',
          style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: listAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.red, strokeWidth: 2)),
        error: (err, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 40),
              const SizedBox(height: 8),
              Text('Değerlendirmeler yüklenemedi.',
                  style:
                      GoogleFonts.dmSans(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(err.toString(),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textHint),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (liste) {
          if (liste.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_outline_rounded,
                      size: 56, color: AppColors.divider),
                  const SizedBox(height: 12),
                  Text('Henüz değerlendirme yok',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: liste.length,
            itemBuilder: (ctx, i) => DegerlendirmeKarti(
              data: liste[i],
            ),
          );
        },
      ),
    );
  }
}

// ── Kart ──────────────────────────────────────────────────

class DegerlendirmeKarti extends ConsumerWidget {
  final Map<String, dynamic> data;

  const DegerlendirmeKarti({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final degerlendireninId = data['degerlendireninId'] as String? ?? '';
    final puan = (data['puan'] as num?)?.toDouble() ?? 0.0;
    final yorum = data['yorum'] as String? ?? '';
    final tarih = data['tarih'];

    String tarihYazi = '';
    if (tarih != null) {
      try {
        final dt = (tarih as dynamic).toDate() as DateTime;
        tarihYazi =
            '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }

    final profilAsync = ref.watch(kullaniciBilgiProvider(degerlendireninId));
    final ad = profilAsync.value?.adSoyad ?? '';
    final fotoUrl = profilAsync.value?.fotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              fotoUrl != null && fotoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(fotoUrl),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppColors.red.withValues(alpha: 0.12),
                      child: Text(
                        ad.isNotEmpty ? ad[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.isNotEmpty ? ad : 'Kullanıcı',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    if (tarihYazi.isNotEmpty)
                      Text(
                        tarihYazi,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < puan.floor()
                        ? Icons.star_rounded
                        : (i < puan
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded),
                    color: const Color(0xFFFFA726),
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          if (yorum.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              yorum,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}