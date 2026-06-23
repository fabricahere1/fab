import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/bildirim_model.dart';
import '../providers/bildirim_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../degerlendirme/presentation/degerlendirme_screen.dart';
import '../../degerlendirme/providers/degerlendirme_provider.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/utils/app_snackbar.dart';

class BildirimlerScreen extends ConsumerStatefulWidget {
  const BildirimlerScreen({super.key});

  @override
  ConsumerState<BildirimlerScreen> createState() => _BildirimlerScreenState();
}

class _BildirimlerScreenState extends ConsumerState<BildirimlerScreen>
    with AutomaticKeepAliveClientMixin {

  // Optimistic: Firestore'u beklemeden anında okundu göster
  final _okunduIdler = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bildirimlerAsync = ref.watch(bildirimlerProvider);

    ref.listen(bildirimlerProvider, (_, sonraki) {
      if (sonraki.hasError) {
        AppSnackBar.hata(context, 'Bildirimler yüklenemedi.');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final bildirimler = bildirimlerAsync.asData?.value ?? [];
              setState(() {
                _okunduIdler.addAll(bildirimler.map((b) => b.id));
              });
              ref.read(bildirimProvider.notifier).tumunuOkunduIsaretle();
            },
            child: Text(
              'Tümünü oku',
              style: GoogleFonts.inter(
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
          child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
        ),
        error: (_, _) => Center(
          child: Text(
            'Bildirimler yüklenemedi.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        data: (bildirimler) {
          if (bildirimler.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_outlined,
                      size: 64, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bildirim yok',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            itemCount: bildirimler.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RepaintBoundary(
                child: _BildirimSatiri(
                  bildirim: bildirimler[index],
                  okunduIdler: _okunduIdler,
                  onOkundu: () => setState(
                      () => _okunduIdler.add(bildirimler[index].id)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BildirimSatiri extends ConsumerWidget {
  final BildirimModel bildirim;
  final Set<String> okunduIdler;
  final VoidCallback onOkundu;

  const _BildirimSatiri({
    required this.bildirim,
    required this.okunduIdler,
    required this.onOkundu,
  });

  Future<void> _navigate(BuildContext context, WidgetRef ref) async {
    // ── Mesaj bildirimi → sohbet ekranı ──────────────────────────────────
    if (bildirim.tip == BildirimTip.mesaj && bildirim.hedefId.isNotEmpty) {
      final parts = bildirim.hedefId.split('_');
      if (parts.length < 3) return;

      final ilanId = parts.last;
      final karsiUid = bildirim.gondereId.isNotEmpty
          ? bildirim.gondereId
          : (() {
              final benimUid = ref.read(currentUserProvider)?.uid ?? '';
              return parts
                  .sublist(0, parts.length - 1)
                  .firstWhere((p) => p != benimUid, orElse: () => '');
            })();

      if (karsiUid.isEmpty) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SohbetScreen(
            karsiKullaniciId: karsiUid,
            karsiKullaniciAd: bildirim.gondereAd,
            ilanId: ilanId,
            ilanBaslik: bildirim.baslik,
          ),
        ),
      );
      return;
    }

    // ── Anlaşıldı bildirimi → sohbet + panel otomatik aç ─────────────────
    if (bildirim.tip == BildirimTip.anlasildi && bildirim.hedefId.isNotEmpty) {
      final sohbetId = bildirim.hedefId;
      final karsiId  = bildirim.gondereId;
      final karsiAd  = bildirim.gondereAd;

      if (karsiId.isEmpty) return;

      final d = await ref.read(sohbetIslemleriProvider.notifier).getir(sohbetId);
      if (d == null) return;
      final ilanId     = d['ilanId']     as String? ?? '';
      final ilanBaslik = d['ilanBaslik'] as String? ?? '';
      final ilanTip    = d['ilanTip']    as String? ?? 'istek';

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SohbetScreen(
            karsiKullaniciId: karsiId,
            karsiKullaniciAd: karsiAd,
            ilanId:        ilanId,
            ilanBaslik:    ilanBaslik,
            ilanTip:       ilanTip,
            autoOpenPanel: true,
          ),
        ),
      );
      return;
    }

    // ── Değerlendirme bildirimi → değerlendirme popup ─────────────────────
    if (bildirim.tip == BildirimTip.degerlendirme && bildirim.hedefId.isNotEmpty) {
      final sohbetId = bildirim.hedefId;
      final karsiId  = bildirim.gondereId;
      final karsiAd  = bildirim.gondereAd;

      if (karsiId.isEmpty) return;

      final benimUid = ref.read(currentUserProvider)?.uid ?? '';
      if (benimUid.isEmpty) return;

      final zaten = await ref.read(degerlendirmeIslemleriProvider.notifier).zatenYaptimMi(
        sohbetId: sohbetId,
        kullaniciId: benimUid,
      );
      if (zaten) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Bu ilanı zaten değerlendirdin.',
                style: GoogleFonts.dmSans()),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      if (!context.mounted) return;

      final tamamlandi = await DegerlendirmeModal.goster(
        context: context,
        sohbetId: sohbetId,
        hedefKullaniciId: karsiId,
        hedefKullaniciAd: karsiAd,
      );

      if (tamamlandi && context.mounted) {
        await ref.read(degerlendirmeIslemleriProvider.notifier).bekleyenTamamla(
          sohbetId: sohbetId,
          kullaniciId: benimUid,
        );
      }
    }
  }

  IconData get _ikon => switch (bildirim.tip) {
        BildirimTip.mesaj         => Icons.chat_bubble_outline,
        BildirimTip.ilan          => Icons.list_alt_outlined,
        BildirimTip.sistem        => Icons.notifications_outlined,
        BildirimTip.degerlendirme => Icons.star_outline_rounded,
        BildirimTip.anlasildi     => Icons.handshake_outlined,
      };

  Color get _ikonRenk => const Color(0xFF666666);

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
    final okundu = bildirim.okundu || okunduIdler.contains(bildirim.id);

    return Dismissible(
      key: Key(bildirim.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          ref.read(bildirimProvider.notifier).bildirimSil(bildirim.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          if (!okundu) {
            onOkundu();
            ref.read(bildirimProvider.notifier).okunduIsaretle(bildirim.id);
          }
          _navigate(context, ref);
        },
        child: Container(
          decoration: BoxDecoration(
            color: okundu ? Colors.white : const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sol şerit — okunmamış
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: okundu ? 0 : 4,
                    color: _ikonRenk,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
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
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: okundu
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _zamanYazi(bildirim.tarih),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bildirim.icerik,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
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