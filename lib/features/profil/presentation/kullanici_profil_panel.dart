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

class KullaniciProfilPanel extends ConsumerStatefulWidget {
  final String kullaniciId;
  final String kullaniciAd;

  const KullaniciProfilPanel({
    super.key,
    required this.kullaniciId,
    required this.kullaniciAd,
  });

  @override
  ConsumerState<KullaniciProfilPanel> createState() =>
      _KullaniciProfilPanelState();
}

class _KullaniciProfilPanelState extends ConsumerState<KullaniciProfilPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _shakeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final benimUid = ref.watch(currentUserProvider)?.uid;
    final benimKisi = benimUid != null && benimUid != widget.kullaniciId;
    final profilAsync = ref.watch(kullaniciBilgiProvider(widget.kullaniciId));
    // keepAlive stream — panel içinde yeniden subscribe olmaz
    final ilanlarAsync = ref.watch(kullaniciIlanlarStreamProvider(widget.kullaniciId));
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.85;

    return SafeArea(
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
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
              // Header
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
                          profil?.adSoyad ?? widget.kullaniciAd,
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                            color: AppColors.textPrimary,
                          ),
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
                        style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.none)),
                  ),
                  data: (profil) {
                    final ad = profil?.adSoyad ?? widget.kullaniciAd;
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
                                        color: AppColors.textPrimary,
                                        decoration: TextDecoration.none,
                                      ),
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
                                                color: AppColors.textSecondary,
                                                decoration: TextDecoration.none,
                                              )),
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
                                                kullaniciId: widget.kullaniciId,
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
                                                color: AppColors.textSecondary,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
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
                                          height: 1.5,
                                          decoration: TextDecoration.none,
                                        ),
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
                                                color: AppColors.textPrimary,
                                                decoration: TextDecoration.none,
                                              )),
                                        ],
                                      ),
                                    ],

                                    if (benimKisi) ...[
                                      const SizedBox(height: 14),
                                      const Divider(color: AppColors.divider),
                                      const SizedBox(height: 14),
                                      // Takip butonu
                                      Consumer(
                                        builder: (ctx, ref, _) {
                                          final takipAsync = ref.watch(takipEdiyorMuProvider(widget.kullaniciId));
                                          final takipEdiyor = takipAsync.value ?? false;
                                          return SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                if (takipEdiyor) {
                                                  await ref.read(takipIslemleriProvider.notifier).takipiBirak(widget.kullaniciId);
                                                } else {
                                                  await ref.read(takipIslemleriProvider.notifier).takipEt(widget.kullaniciId);
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: takipEdiyor ? AppColors.textSecondary : AppColors.textPrimary,
                                                side: BorderSide(color: takipEdiyor ? AppColors.divider : AppColors.textPrimary, width: 0.8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              icon: Icon(takipEdiyor ? Icons.person_remove_outlined : Icons.person_add_outlined, size: 16),
                                              label: Text(
                                                takipEdiyor ? 'Takip Ediliyor' : 'Takip Et',
                                                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
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
                                                      widget.kullaniciId,
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
                                          color: AppColors.textPrimary,
                                          decoration: TextDecoration.none,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // İlanlar — loading state'i ayrı, data gelince stable
                        ilanlarAsync.when(
                          loading: () => const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.red, strokeWidth: 2)),
                            ),
                          ),
                          error: (_, _) =>
                              const SliverToBoxAdapter(child: SizedBox()),
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
                                              color: AppColors.textSecondary,
                                              decoration: TextDecoration.none,
                                            )),
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
                child: Image.network(
                  resim,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
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
                      color: AppColors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (konum.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      konum,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.none,
                      ),
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