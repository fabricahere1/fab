import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart' show IlanTip;
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/kesfet_computed_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/features/home/presentation/kesfet/widgets/kesfet_widgets.dart';


class CanliTab extends ConsumerWidget {
  const CanliTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final istekYukleniyor    = ref.watch(istekIlanlarProvider).yukleniyor;
    final tasiyiciYukleniyor = ref.watch(tasiyiciIlanlarProvider).yukleniyor;
    final yukleniyor         = istekYukleniyor || tasiyiciYukleniyor;

    // Memoize edilmiş provider'lar — her build'de yeniden hesaplanmaz
    final istatistik    = ref.watch(kesfetIstatistikProvider);
    final suAnHavada    = ref.watch(suAnHavadaIlanlarProvider);
    final trendIstekler = ref.watch(trendIsteklerProvider);
    final sonAktiviteler = ref.watch(sonAktivitelerProvider);

    return CustomScrollView(
      slivers: [
        // ── İstatistik kartları ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                StatKart(
                  sayi: '${istatistik.toplamAktif}',
                  label: 'Aktif ilan',
                  renk: AppColors.red,
                ),
                const SizedBox(width: 8),
                StatKart(
                  sayi: '${istatistik.bugunEklenen}',
                  label: 'Bugün eklendi',
                  renk: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                StatKart(
                  sayi: '${istatistik.buHaftaEklenen}',
                  label: 'Bu hafta',
                  renk: const Color(0xFF1565C0),
                ),
              ],
            ),
          ),
        ),

        // ── Şu an havada ─────────────────────────────────────────────────────
        if (suAnHavada.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: SuAnHavadaKart(ilanlar: suAnHavada),
            ),
          ),

        // ── Trend istekler ───────────────────────────────────────────────────
        if (trendIstekler.isNotEmpty) ...[
          SliverToBoxAdapter(child: bolumBasligi('🔥 Trend istekler')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48, // 38'den 48'e — Material minimum dokunma alanı
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                itemCount: trendIstekler.length,
                itemBuilder: (context, i) {
                  final ilan = trendIstekler[i];
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(sonGoruntulenenlerProvider.notifier)
                          .kaydet(ilan);
                      context.push(AppRoutes.ilanDetayPath(ilan.id));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: i == 0
                            ? AppColors.red
                            : i == 1
                                ? const Color(0xFFFF8C42)
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              i < 2 ? Colors.transparent : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 0)
                            const Text('🔥 ',
                                style: TextStyle(fontSize: 11)),
                          Text(
                            ilan.urun.isNotEmpty
                                ? ilan.urun
                                : '${ilan.nereden} → ${ilan.nereye}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: i < 2
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // ── Son aktiviteler ──────────────────────────────────────────────────
        SliverToBoxAdapter(child: bolumBasligi('⚡ Son aktiviteler')),

        if (yukleniyor)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: _AktiviteSkeletonSatiri(),
              ),
              childCount: 6,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ilan   = sonAktiviteler[index];
                final ne     = ilan.tip == IlanTip.istek
                    ? 'istedi'
                    : 'güzergah ekledi';
                final dakika = ilan.olusturmaTarihi == null
                    ? '?'
                    : '${DateTime.now().difference(ilan.olusturmaTarihi!).inMinutes}';

                return GestureDetector(
                  onTap: () {
                    ref
                        .read(sonGoruntulenenlerProvider.notifier)
                        .kaydet(ilan);
                    context.push(AppRoutes.ilanDetayPath(ilan.id));
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ilan.tip == IlanTip.istek
                                ? AppColors.red.withValues(alpha: 0.1)
                                : const Color(0xFF1565C0)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            ilan.tip == IlanTip.istek
                                ? Icons.shopping_bag_outlined
                                : Icons.flight_takeoff_rounded,
                            size: 18,
                            color: ilan.tip == IlanTip.istek
                                ? AppColors.red
                                : const Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ilan.kullaniciAd.isNotEmpty
                                          ? ilan.kullaniciAd
                                          : 'Kullanıcı',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    TextSpan(
                                      text:
                                          ' ${ilan.urun.isNotEmpty ? ilan.urun : "${ilan.nereden} → ${ilan.nereye}"} $ne',
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$dakika dk önce',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: sonAktiviteler.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// Aktivite satırı skeleton
class _AktiviteSkeletonSatiri extends StatefulWidget {
  const _AktiviteSkeletonSatiri();

  @override
  State<_AktiviteSkeletonSatiri> createState() =>
      _AktiviteSkeletonSatiriState();
}

class _AktiviteSkeletonSatiriState extends State<_AktiviteSkeletonSatiri>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 10,
                        width: double.infinity,
                        color: AppColors.surface),
                    const SizedBox(height: 6),
                    Container(
                        height: 8, width: 60, color: AppColors.surface),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
