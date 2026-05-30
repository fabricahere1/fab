import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../degerlendirme/presentation/degerlendirmeler_liste_screen.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../../router/app_router.dart';

class KullaniciProfilPanel extends ConsumerWidget {
  final String kullaniciId;
  final String kullaniciAd;

  const KullaniciProfilPanel({
    super.key,
    required this.kullaniciId,
    required this.kullaniciAd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benimUid = ref.watch(currentUserProvider)?.uid;
    final benimKisi = benimUid != null && benimUid != kullaniciId;
    final profilAsync = ref.watch(kullaniciBilgiProvider(kullaniciId));
    final ilanlarAsync = ref.watch(kullaniciIlanlarStreamProvider(kullaniciId));
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.85;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
      child: Container(
        width: panelWidth,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: profilAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                      data: (profil) => Text(
                        profil?.adSoyad ?? kullaniciAd,
                        style: GoogleFonts.dmSans(
                            fontSize: 17, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 22, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: profilAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.red, strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text('Profil yüklenemedi.',
                      style:
                          GoogleFonts.dmSans(color: AppColors.textSecondary)),
                ),
                data: (profil) {
                  final ad = profil?.adSoyad ?? kullaniciAd;
                  final hakkinda = profil?.hakkinda ?? '';
                  final sehir = profil?.bulunduguSehir.isNotEmpty == true
                      ? profil!.bulunduguSehir
                      : profil?.yasadigiUlke ?? '';
                  final puan = profil?.ortalamaPuan ?? 0.0;
                  final degerlendirmeSayisi =
                      profil?.degerlendirmeSayisi ?? 0;
                  final telefon = profil?.telefonGizli == false
                      ? profil?.telefon ?? ''
                      : '';

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Profil Kartı
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  AvatarWidget(isim: ad, radius: 40),
                                  const SizedBox(height: 12),
                                  Text(
                                    ad,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                  if (sehir.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(sehir,
                                            style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),

                                  if (degerlendirmeSayisi > 0) ...[
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DegerlendirmelerListeScreen(
                                              kullaniciId: kullaniciId,
                                              kullaniciAd: ad,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ...List.generate(5, (i) {
                                            return Icon(
                                              i < puan.floor()
                                                  ? Icons.star
                                                  : (i < puan
                                                      ? Icons.star_half
                                                      : Icons.star_border),
                                              color: Colors.amber,
                                              size: 18,
                                            );
                                          }),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${puan.toStringAsFixed(1)} ($degerlendirmeSayisi)',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary,
                                                decoration: TextDecoration
                                                    .underline),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  if (hakkinda.isNotEmpty) ...[
                                    const Divider(color: AppColors.divider),
                                    const SizedBox(height: 10),
                                    Text(
                                      hakkinda,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.5),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],

                                  if (telefon.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    const Divider(color: AppColors.divider),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 16,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(telefon,
                                            style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textPrimary)),
                                      ],
                                    ),
                                  ],

                                  if (benimKisi) ...[
                                    const SizedBox(height: 14),
                                    const Divider(color: AppColors.divider),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder:
                                                  (ctx, anim, secAnim) =>
                                                      SohbetScreen(
                                                karsiKullaniciId:
                                                    kullaniciId,
                                                karsiKullaniciAd: ad,
                                                ilanId: '',
                                                ilanBaslik: '',
                                              ),
                                              transitionsBuilder: (ctx, anim,
                                                      secAnim, child) =>
                                                  SlideTransition(
                                                position: Tween(
                                                  begin: const Offset(1, 0),
                                                  end: Offset.zero,
                                                ).animate(CurvedAnimation(
                                                    parent: anim,
                                                    curve:
                                                        Curves.easeOutCubic)),
                                                child: child,
                                              ),
                                              transitionDuration:
                                                  const Duration(
                                                      milliseconds: 280),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.red,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        icon: const Icon(
                                            Icons.chat_bubble_outline,
                                            size: 16),
                                        label: Text('Mesaj Gönder',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              color: Colors.white,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                children: [
                                  Text('İlanları',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      ilanlarAsync.when(
                        loading: () => const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.red, strokeWidth: 2)),
                          ),
                        ),
                        error: (_, _) => const SliverToBoxAdapter(
                            child: SizedBox()),
                        data: (ilanlar) {
                          if (ilanlar.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.inbox_outlined,
                                          size: 40,
                                          color: AppColors.divider),
                                      const SizedBox(height: 8),
                                      Text('Henüz ilan yok',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              color:
                                                  AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _PanelIlanSatiri(ilan: ilanlar[index]),
                              childCount: ilanlar.length,
                            ),
                          );
                        },
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _PanelIlanSatiri extends StatelessWidget {
  final IlanModel ilan;

  const _PanelIlanSatiri({required this.ilan});

  @override
  Widget build(BuildContext context) {
    final resim = ilan.resimThumbUrl.isNotEmpty
        ? ilan.resimThumbUrl
        : ilan.resimUrl.isNotEmpty
            ? ilan.resimUrl
            : ilan.resimUrller.isNotEmpty
                ? ilan.resimUrller.first
                : null;
    final baslik = ilan.urun.isNotEmpty ? ilan.urun : ilan.nereden;
    final konum = ilan.nereden.isNotEmpty ? ilan.nereden : '';

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.push(AppRoutes.ilanDetayPath(ilan.id));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider, width: 0.7),
        ),
        child: Row(
          children: [
            if (resim != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: resim,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  errorWidget: (_, _, _) => Container(
                    width: 52,
                    height: 52,
                    color: AppColors.divider,
                    child: const Icon(Icons.image_not_supported_outlined,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined,
                    size: 22, color: AppColors.textSecondary),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (konum.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      konum,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
