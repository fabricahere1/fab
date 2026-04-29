import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/bildirim_model.dart';
import '../providers/bildirim_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../teklifler/presentation/teklif_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';

class BildirimlerScreen extends ConsumerStatefulWidget {
  const BildirimlerScreen({super.key});

  @override
  ConsumerState<BildirimlerScreen> createState() => _BildirimlerScreenState();
}

class _BildirimlerScreenState extends ConsumerState<BildirimlerScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bildirimlerAsync = ref.watch(bildirimlerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(bildirimProvider.notifier).tumunuOkunduIsaretle(),
            child: Text(
              'Tümünü Oku',
              style: GoogleFonts.dmSans(
                color: AppColors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: bildirimlerAsync.when(
        skipLoadingOnReload: true,
        skipError: true,
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.red,
            strokeWidth: 2,
          ),
        ),
        error: (_, _) => Center(
          child: Text(
            'Bildirimler yüklenemedi.',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ),
        data: (bildirimler) {
          if (bildirimler.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bildirim yok',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: bildirimler.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) => RepaintBoundary(
              child: _BildirimSatiri(bildirim: bildirimler[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BildirimSatiri extends ConsumerWidget {
  final BildirimModel bildirim;

  const _BildirimSatiri({required this.bildirim});

  void _navigate(BuildContext context, WidgetRef ref) {
    // Teklif bildirimi → TeklifDetayScreen
    if (bildirim.tip == BildirimTip.teklif && bildirim.hedefId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeklifDetayScreen(teklifId: bildirim.hedefId),
        ),
      );
      return;
    }

    // Mesaj bildirimi → SohbetScreen
    if (bildirim.tip != BildirimTip.mesaj || bildirim.hedefId.isEmpty) return;

    final parts = bildirim.hedefId.split('_');
    if (parts.length < 3) return;

    final benimUid = ref.read(currentUserProvider)?.uid ?? '';
    final ilanId   = parts.last;
    final karsiUid = parts
        .sublist(0, parts.length - 1)
        .firstWhere((p) => p != benimUid, orElse: () => '');

    if (karsiUid.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SohbetScreen(
          karsiKullaniciId: karsiUid,
          karsiKullaniciAd: bildirim.gondereAd,
          ilanId:           ilanId,
          ilanBaslik:       bildirim.icerik,
        ),
      ),
    );
  }

  IconData get _ikon => switch (bildirim.tip) {
        BildirimTip.mesaj   => Icons.chat_bubble_outline,
        BildirimTip.ilan    => Icons.list_alt_outlined,
        BildirimTip.sistem  => Icons.notifications_outlined,
        BildirimTip.teklif  => Icons.local_offer_outlined, // ← eklendi
      };

  Color get _ikonRenk => switch (bildirim.tip) {
        BildirimTip.mesaj   => AppColors.primary,
        BildirimTip.ilan    => AppColors.red,
        BildirimTip.sistem  => Colors.amber,
        BildirimTip.teklif  => const Color(0xFFFF9800), // turuncu ← eklendi
      };

  String _zamanYazi(DateTime? tarih) {
    if (tarih == null) return '';
    final fark = DateTime.now().difference(tarih);
    if (fark.inMinutes < 1) return 'Az önce';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dk önce';
    if (fark.inHours < 24) return '${fark.inHours} saat önce';
    if (fark.inDays < 7) return '${fark.inDays} gün önce';
    return '${tarih.day}.${tarih.month}.${tarih.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(bildirim.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          ref.read(bildirimProvider.notifier).bildirimSil(bildirim.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          if (!bildirim.okundu) {
            ref.read(bildirimProvider.notifier).okunduIsaretle(bildirim.id);
          }
          _navigate(context, ref);
        },
        child: ColoredBox(
          color: bildirim.okundu
              ? Colors.white
              : AppColors.red.withValues(alpha: 0.04),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IkonCircle(ikon: _ikon, renk: _ikonRenk),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bildirim.baslik,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: bildirim.okundu
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _zamanYazi(bildirim.tarih),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bildirim.icerik,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!bildirim.okundu)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IkonCircle extends StatelessWidget {
  final IconData ikon;
  final Color renk;

  const _IkonCircle({required this.ikon, required this.renk});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(ikon, color: renk, size: 22),
      ),
    );
  }
}