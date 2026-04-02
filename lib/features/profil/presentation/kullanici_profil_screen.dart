import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../ilanlar/presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/avatar_widget.dart';
 
class KullaniciProfilScreen extends ConsumerWidget {
  final String kullaniciId;
  final String kullaniciAd;
 
  const KullaniciProfilScreen({
    super.key,
    required this.kullaniciId,
    required this.kullaniciAd,
  });
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benimUid = ref.watch(currentUserProvider)?.uid;
    final profilAsync = ref.watch(kullaniciBilgiProvider(kullaniciId));
    final ilanlarAsync = ref.watch(kullaniciIlanlarStreamProvider(kullaniciId));
 
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: profilAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.red, strokeWidth: 2)),
        error: (_, __) => Center(
          child: Text('Profil yüklenemedi.',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (profil) {
          final ad = profil?.adSoyad ?? kullaniciAd;
          final hakkinda = profil?.hakkinda ?? '';
          final sehir = profil?.bulunduguSehir.isNotEmpty == true
              ? profil!.bulunduguSehir
              : profil?.yasadigiUlke ?? '';
          final puan = profil?.ortalamaPuan ?? 0.0;
          final degerlendirmeSayisi = profil?.degerlendirmeSayisi ?? 0;
          final telefon = profil?.telefonGizli == false
              ? profil?.telefon ?? ''
              : '';
 
          return CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 20, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(ad,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ),
 
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Profil Kartı ─────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AvatarWidget(isim: ad, radius: 44),
                          const SizedBox(height: 16),
                          Text(
                            ad,
                            style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          if (sehir.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(sehir,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
 
                          // Yıldız puanı
                          if (degerlendirmeSayisi > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...List.generate(5, (i) {
                                  return Icon(
                                    i < puan.floor()
                                        ? Icons.star
                                        : (i < puan
                                            ? Icons.star_half
                                            : Icons.star_border),
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '${puan.toStringAsFixed(1)} ($degerlendirmeSayisi değerlendirme)',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
 
                          if (hakkinda.isNotEmpty) ...[
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 12),
                            Text(
                              hakkinda,
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
 
                          if (telefon.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(telefon,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 8),
 
                    // ── İlanları ─────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text('İlanları',
                              style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
 
              // ── İlanlar Listesi ──────────────────────────
              ilanlarAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.red, strokeWidth: 2)),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                        child: Text('İlanlar yüklenemedi.',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary))),
                  ),
                ),
                data: (ilanlar) {
                  if (ilanlar.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.inbox_outlined,
                                  size: 48, color: AppColors.divider),
                              const SizedBox(height: 12),
                              Text('Henüz ilan yok',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
 
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ilan = ilanlar[index];
                        return _IlanSatiri(ilan: ilan);
                      },
                      childCount: ilanlar.length,
                    ),
                  );
                },
              ),
 
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
 
// ── İlan Satırı ───────────────────────────────────────────
 
class _IlanSatiri extends StatelessWidget {
  final IlanModel ilan;
  const _IlanSatiri({required this.ilan});
 
  @override
  Widget build(BuildContext context) {
    final kategoriAdi_ = kategoriAdi(ilan.kategori);
 
    return InkWell(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Tip ikonu
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ilan.tip == IlanTip.istek
                    ? AppColors.red.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                ilan.tip == IlanTip.istek
                    ? Icons.shopping_bag_outlined
                    : Icons.flight_land_outlined,
                size: 18,
                color: ilan.tip == IlanTip.istek
                    ? AppColors.red
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty
                        ? ilan.urun
                        : '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${ilan.nereden} → ${ilan.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ilan.ucret.isNotEmpty)
                  Text(
                    '${ilan.ucret} ₺',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.red),
                  ),
                if (kategoriAdi_.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    color: AppColors.chipBg,
                    child: Text(
                      kategoriAdi_,
                      style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}