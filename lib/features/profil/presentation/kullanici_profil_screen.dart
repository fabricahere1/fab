import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/cache/app_cache_manager.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/profil_stilleri.dart';
import '../../degerlendirme/presentation/degerlendirmeler_liste_screen.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../router/app_router.dart';
import '../domain/kullanici_model.dart';
import '../../../shared/utils/app_snackbar.dart';

class KullaniciProfilScreen extends ConsumerStatefulWidget {
  final String kullaniciId;
  final String kullaniciAd;

  const KullaniciProfilScreen({
    super.key,
    required this.kullaniciId,
    required this.kullaniciAd,
  });

  @override
  ConsumerState<KullaniciProfilScreen> createState() =>
      _KullaniciProfilScreenState();
}

class _KullaniciProfilScreenState extends ConsumerState<KullaniciProfilScreen> {
  String get kullaniciId => widget.kullaniciId;
  String get kullaniciAd => widget.kullaniciAd;

  @override
  void dispose() {
    ref.read(takipciDeltaProvider.notifier).temizle(kullaniciId);
    super.dispose();
  }

  void _degerlendirmeleriGoster(
      BuildContext context, String kullaniciId, String kullaniciAd) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DegerlendirmelerListeScreen(
          kullaniciId: kullaniciId,
          kullaniciAd: kullaniciAd,
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final benimUid      = ref.watch(currentUserProvider)?.uid;
    final benimKisi     = benimUid != null && benimUid != kullaniciId;
    final benOnuEngellemisim = benimKisi
        ? (ref.watch(benimKullaniciProfilProvider).value
                ?.engellenenler.contains(kullaniciId) ??
            false)
        : false;
    final profilAsync   = ref.watch(kullaniciBilgiProvider(kullaniciId));
    final ilanlarAsync  = ref.watch(kullaniciIlanlarStreamProvider(kullaniciId));
    final takipciDelta  = ref.watch(
        takipciDeltaProvider.select((m) => m[kullaniciId] ?? 0));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: profilAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2)),
        error: (_, _) => Center(
          child: Text('Profil yüklenemedi.',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (profil) {
          if (profil == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 48, color: AppColors.divider),
                  const SizedBox(height: 12),
                  Text('Kullanıcı bulunamadı.',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          final ad = profil.adSoyad;
          final hakkinda = profil.hakkinda;
          final sehir = profil.bulunduguSehir.isNotEmpty
              ? profil.bulunduguSehir
              : profil.yasadigiUlke;
          final puan = profil.ortalamaPuan;
          final degerlendirmeSayisi = profil.degerlendirmeSayisi;
          final telefon = profil.telefonGizli == false
              ? profil.telefon ?? ''
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          Text(ad, style: ProfilStilleri.isim),
                          if (sehir.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(sehir, style: ProfilStilleri.altBilgi),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Yıldız puanı
                          if (degerlendirmeSayisi > 0) ...[
                            GestureDetector(
                              onTap: () => _degerlendirmeleriGoster(
                                  context, kullaniciId, ad),
                              child: Row(
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
                                    style: ProfilStilleri.puanYazi,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (hakkinda.isNotEmpty) ...[
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 12),
                            Text(
                              hakkinda,
                              style: ProfilStilleri.altBilgi.copyWith(height: 1.5),
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
                                    size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(telefon, style: ProfilStilleri.altBilgi.copyWith(color: AppColors.textPrimary)),
                              ],
                            ),
                          ],

                          // ── İstatistikler ────────────────
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider),
                          Row(
                            children: [
                              Expanded(child: Column(children: [
                                Text('${(profil.takipciSayisi + takipciDelta).clamp(0, 999999)}', style: ProfilStilleri.istatistikSayi),
                                Text('Takipçi', style: ProfilStilleri.istatistikEtiket),
                              ])),
                              Container(width: 0.5, height: 36, color: AppColors.divider),
                              Expanded(child: Column(children: [
                                Text('${profil.takipSayisi}', style: ProfilStilleri.istatistikSayi),
                                Text('Takip', style: ProfilStilleri.istatistikEtiket),
                              ])),
                            ],
                          ),

                          // ── Güven Skoru ───────────────────
                          if ((profil.guvenSkoru) > 0) ...[
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Puanı', style: ProfilStilleri.bolumBaslik),
                                Text('${profil.guvenSkoru}/100', style: ProfilStilleri.guvenSkoruDeger),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: profil.guvenSkoru / 100,
                                backgroundColor: const Color(0xFFF0F0F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  profil.guvenSkoru >= 80 ? const Color(0xFF4CAF50)
                                      : profil.guvenSkoru >= 60 ? const Color(0xFF2196F3)
                                      : profil.guvenSkoru >= 40 ? const Color(0xFFFFA726)
                                      : AppColors.red,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(profil.guvenSkoruEtiketi, style: ProfilStilleri.detaySatiri),
                          ],

                          // ── Rozetler ──────────────────────
                          if ((profil.rozetler).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profil.rozetler.map((rozet) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
                                ),
                                child: Text(
                                  '${profil.rozetEmoji(rozet)} ${profil.rozetAdi(rozet)}',
                                  style: ProfilStilleri.rozet,
                                ),
                              )).toList(),
                            ),
                          ],

                          // ── Takip + Mesaj Butonları ────────
                          if (benimKisi) ...[
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 16),
                            Consumer(
                              builder: (ctx, ref, _) {
                                final takipEdiyor = ref.watch(takipEdiyorMuProvider(kullaniciId));
                                return SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (takipEdiyor) {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text('Takibi Bırak'),
                                            content: Text('$kullaniciAd takipten çıkılsın mı?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogContext),
                                                child: const Text('İptal'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(dialogContext);
                                                  ref.read(takipIslemleriProvider.notifier).takipiBirak(kullaniciId);
                                                },
                                                child: const Text('Takibi Bırak'),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        ref.read(takipIslemleriProvider.notifier).takipEt(kullaniciId);
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
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (ctx, anim, secAnim) => SohbetScreen(
                                      karsiKullaniciId: kullaniciId,
                                      karsiKullaniciAd: ad,
                                      ilanId: '',
                                    ),
                                    transitionsBuilder: (ctx, anim, secAnim, child) =>
                                        SlideTransition(
                                      position: Tween(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                          parent: anim, curve: Curves.easeOutCubic)),
                                      child: child,
                                    ),
                                    transitionDuration:
                                        const Duration(milliseconds: 280),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                label: Text('Mesaj Gönder',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  if (benOnuEngellemisim) {
                                    await ref
                                        .read(engellemeProvider.notifier)
                                        .engelKaldir(
                                          benimUid: benimUid,
                                          hedefUid: kullaniciId,
                                        );
                                    if (context.mounted) {
                                      AppSnackBar.bilgi(
                                          context, '$kullaniciAd engeli kaldırıldı.');
                                    }
                                  } else {
                                    await ref
                                        .read(engellemeProvider.notifier)
                                        .engelle(
                                          benimUid: benimUid,
                                          hedefUid: kullaniciId,
                                        );
                                    if (context.mounted) {
                                      AppSnackBar.bilgi(
                                          context, '$kullaniciAd engellendi.');
                                    }
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: benOnuEngellemisim
                                      ? AppColors.primary
                                      : AppColors.red,
                                  side: BorderSide(
                                      color: benOnuEngellemisim
                                          ? AppColors.primary
                                          : AppColors.red),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(
                                    benOnuEngellemisim
                                        ? Icons.lock_open_outlined
                                        : Icons.block_outlined,
                                    size: 18),
                                label: Text(
                                    benOnuEngellemisim ? 'Engeli Kaldır' : 'Engelle',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
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
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.grid_view_rounded,
                                size: 13, color: AppColors.red),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ilanlarAsync.value != null
                                ? 'İlanları (${ilanlarAsync.value!.length})'
                                : 'İlanları',
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
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
                error: (_, _) => SliverToBoxAdapter(
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
                      (context, index) => _IlanSatiri(ilan: ilanlar[index]),
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
    final resim = ilan.gridResim;

    return InkWell(
      onTap: () => context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 0.5)),
        ),
        child: Row(
          children: [
            // ── Gerçek ürün fotoğrafı (önceden sadece kategori ikonu vardı) ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52, height: 52,
                    color: const Color(0xFFF2F2F2),
                    child: resim.isNotEmpty
                        ? CachedNetworkImage(
                            cacheManager: AppCacheManager.instance,
                            imageUrl: resim,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            errorWidget: (_, _, _) => Icon(
                              ilan.tip == IlanTip.istek
                                  ? Icons.shopping_bag_outlined
                                  : Icons.flight_land_outlined,
                              size: 20, color: AppColors.textHint,
                            ),
                          )
                        : Icon(
                            ilan.tip == IlanTip.istek
                                ? Icons.shopping_bag_outlined
                                : Icons.flight_land_outlined,
                            size: 20, color: AppColors.textHint,
                          ),
                  ),
                ),
                if (ilan.yeniMi)
                  const Positioned(top: -2, left: -2, child: _KucukYeniNoktasi()),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : '${ilan.nereden} → ${ilan.nereye}',
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
                              fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (kategoriAdi_.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        kategoriAdi_,
                        style: GoogleFonts.dmSans(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (ilan.ucret.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${ilan.ucret} ₺',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red),
                ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Liste satırındaki küçük görsel için sade "yeni" göstergesi — ana
/// sayfadaki IlanKarti'nın 12 kenarlı yıldız+yazı rozetinden KASITLI
/// OLARAK daha sade: 52px'lik küçük bir küçük resimde tam rozet
/// (yıldız + "YENİ" yazısı) okunaksız kalırdı, bu yüzden sadece renkli
/// bir nokta kullanılıyor.
class _KucukYeniNoktasi extends StatelessWidget {
  const _KucukYeniNoktasi();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFF2912E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}