import '../../../shared/utils/app_hata_yonetici.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/degerlendirme_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';

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
    final state = ref.watch(kullaniciDegerlendirmeleriProvider(kullaniciId));
    final notifier =
        ref.read(kullaniciDegerlendirmeleriProvider(kullaniciId).notifier);

    Widget body;
    if (state.yukleniyor && state.liste.isEmpty) {
      body = LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.red, strokeWidth: 2)),
          ),
        ),
      );
    } else if (state.hata != null && state.liste.isEmpty) {
      body = LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.red, size: 40),
                  const SizedBox(height: 8),
                  Text('Değerlendirmeler yüklenemedi.',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(state.hata.toString(),
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textHint),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (state.liste.isEmpty) {
      body = LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
            ),
          ),
        ),
      );
    } else {
      body = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels > metrics.maxScrollExtent - 400) {
            notifier.dahaFazlaYukle();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: state.liste.length + (state.dahaFazlaVar ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i >= state.liste.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppColors.red, strokeWidth: 2),
                  ),
                ),
              );
            }
            return DegerlendirmeKarti(data: state.liste[i]);
          },
        ),
      );
    }

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
      body: RefreshIndicator(
        onRefresh: notifier.yenile,
        child: body,
      ),
    );
  }
}

// ── Kart — B stili (tırnak + ilan bilgisi) ───────────────

class DegerlendirmeKarti extends ConsumerWidget {
  final Map<String, dynamic> data;

  const DegerlendirmeKarti({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final degerlendireninId = data['degerlendireninId'] as String? ?? '';
    final puan       = (data['puan'] as num?)?.toDouble() ?? 0.0;
    final yorum      = data['yorum'] as String? ?? '';
    final ilanBaslik = data['ilanBaslik'] as String? ?? '';
    final tarih      = data['tarih'];

    String tarihYazi = '';
    if (tarih != null) {
      try {
        final dt = (tarih as dynamic).toDate() as DateTime;
        const aylar = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
            'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
        tarihYazi = '${dt.day} ${aylar[dt.month]} ${dt.year}';
      } catch (e, s) { AppHataYonetici.logla(e, s, etiket: 'degerlendirmelerListeScreen'); }
    }

    final profilAsync = ref.watch(kullaniciBilgiProvider(degerlendireninId));
    final ad      = profilAsync.value?.adSoyad ?? '';
    final fotoUrl = profilAsync.value?.fotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── İlan badge — sadece varsa ─────────────────────────
          if (ilanBaslik.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.6),
                      width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ilanBaslik,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Yorum alanı ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Stack(
              children: [
                // Büyük tırnak arka planda
                Positioned(
                  top: -4,
                  left: -2,
                  child: Text(
                    '“',
                    style: GoogleFonts.dmSans(
                      fontSize: 52,
                      height: 1,
                      color: AppColors.divider,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: yorum.isNotEmpty
                      ? Text(
                          yorum,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          'Yorum yapılmadı.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // ── Alt: avatar + isim + tarih | yıldızlar ───────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                // Avatar
                fotoUrl != null && fotoUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(fotoUrl),
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.red.withValues(alpha: 0.12),
                        child: Text(
                          ad.isNotEmpty ? ad[0].toUpperCase() : '?',
                          style: GoogleFonts.dmSans(
                              color: AppColors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                const SizedBox(width: 8),
                // İsim + tarih
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.isNotEmpty ? ad : 'Kullanıcı',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      if (tarihYazi.isNotEmpty)
                        Text(
                          tarihYazi,
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textHint),
                        ),
                    ],
                  ),
                ),
                // Yıldızlar
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
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}