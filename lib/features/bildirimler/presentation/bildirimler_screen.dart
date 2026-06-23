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

class BildirimlerScreen extends ConsumerStatefulWidget {
  const BildirimlerScreen({super.key});

  @override
  ConsumerState<BildirimlerScreen> createState() => _BildirimlerScreenState();
}

class _BildirimlerScreenState extends ConsumerState<BildirimlerScreen>
    with AutomaticKeepAliveClientMixin {

  final _okunduIdler = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bildirimlerAsync = ref.watch(bildirimlerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final bildirimler = bildirimlerAsync.asData?.value ?? [];
              // UI anında güncelle
              setState(() {
                _okunduIdler.addAll(bildirimler.map((b) => b.id));
              });
              // Firebase arka planda, UI'ı beklemiyor
              ref.read(bildirimProvider.notifier).tumunuOkunduIsaretle()
                  .catchError((_) {});
            },
            child: Text(
              'Tümünü oku',
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
          child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_off_outlined,
                  size: 48, color: AppColors.divider),
              const SizedBox(height: 12),
              Text(
                'Bildirimler yüklenemedi.',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
            ],
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
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Bugün / Bu hafta / Önceki grupla
          final bugun = <BildirimModel>[];
          final buHafta = <BildirimModel>[];
          final onceki = <BildirimModel>[];
          final simdi = DateTime.now();

          for (final b in bildirimler) {
            if (b.tarih == null) {
              onceki.add(b);
              continue;
            }
            final fark = simdi.difference(b.tarih!);
            if (fark.inDays == 0) {
              bugun.add(b);
            } else if (fark.inDays < 7) {
              buHafta.add(b);
            } else {
              onceki.add(b);
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (bugun.isNotEmpty) ...[
                _GrupBasligi(baslik: 'Bugün'),
                _GrupKarti(
                  bildirimler: bugun,
                  okunduIdler: _okunduIdler,
                  onOkundu: (id) => setState(() => _okunduIdler.add(id)),
                ),
                const SizedBox(height: 16),
              ],
              if (buHafta.isNotEmpty) ...[
                _GrupBasligi(baslik: 'Bu Hafta'),
                _GrupKarti(
                  bildirimler: buHafta,
                  okunduIdler: _okunduIdler,
                  onOkundu: (id) => setState(() => _okunduIdler.add(id)),
                ),
                const SizedBox(height: 16),
              ],
              if (onceki.isNotEmpty) ...[
                _GrupBasligi(baslik: 'Önceki'),
                _GrupKarti(
                  bildirimler: onceki,
                  okunduIdler: _okunduIdler,
                  onOkundu: (id) => setState(() => _okunduIdler.add(id)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Grup başlığı ─────────────────────────────────────────

class _GrupBasligi extends StatelessWidget {
  final String baslik;
  const _GrupBasligi({required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        baslik.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Grup kartı (iOS gruplu liste) ─────────────────────────

class _GrupKarti extends ConsumerWidget {
  final List<BildirimModel> bildirimler;
  final Set<String> okunduIdler;
  final void Function(String id) onOkundu;

  const _GrupKarti({
    required this.bildirimler,
    required this.okunduIdler,
    required this.onOkundu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: bildirimler.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          final ilk = i == 0;
          final son = i == bildirimler.length - 1;

          return _BildirimSatiri(
            bildirim: b,
            okunduIdler: okunduIdler,
            ilkMi: ilk,
            sonMu: son,
            onOkundu: () => onOkundu(b.id),
          );
        }).toList(),
      ),
    );
  }
}

// ── Bildirim satırı ───────────────────────────────────────

class _BildirimSatiri extends ConsumerWidget {
  final BildirimModel bildirim;
  final Set<String> okunduIdler;
  final bool ilkMi;
  final bool sonMu;
  final VoidCallback onOkundu;

  const _BildirimSatiri({
    required this.bildirim,
    required this.okunduIdler,
    required this.ilkMi,
    required this.sonMu,
    required this.onOkundu,
  });

  Future<void> _navigate(BuildContext context, WidgetRef ref) async {
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

  Color get _ikonArkaRenk => switch (bildirim.tip) {
    BildirimTip.mesaj         => const Color(0xFFFFF0F0),
    BildirimTip.degerlendirme => const Color(0xFFFFF8E1),
    BildirimTip.anlasildi     => const Color(0xFFE8F5E9),
    _                         => const Color(0xFFF5F5F5),
  };

  Color get _ikonRenk => switch (bildirim.tip) {
    BildirimTip.mesaj         => AppColors.red,
    BildirimTip.degerlendirme => const Color(0xFFF59E0B),
    BildirimTip.anlasildi     => const Color(0xFF4CAF50),
    _                         => const Color(0xFF999999),
  };

  String _zamanYazi(DateTime? tarih) {
    if (tarih == null) return '';
    final fark = DateTime.now().difference(tarih);
    if (fark.inMinutes < 1) return 'Az önce';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dk';
    if (fark.inHours < 24) return '${fark.inHours} sa';
    if (fark.inDays < 7) return '${fark.inDays} gün';
    return '${tarih.day}.${tarih.month}';
  }

  BorderRadius get _borderRadius {
    if (ilkMi && sonMu) return BorderRadius.circular(12);
    if (ilkMi) return const BorderRadius.vertical(top: Radius.circular(12));
    if (sonMu) return const BorderRadius.vertical(bottom: Radius.circular(12));
    return BorderRadius.zero;
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
          borderRadius: _borderRadius,
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
            color: Colors.white,
            borderRadius: _borderRadius,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // İkon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _ikonArkaRenk,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_ikon, color: _ikonRenk, size: 18),
                    ),
                    const SizedBox(width: 12),
                    // İçerik
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  bildirim.baslik,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: okundu
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: okundu
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _zamanYazi(bildirim.tarih),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bildirim.icerik,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Okunmamış nokta
                    if (!okundu) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Ayırıcı (son elemanda değil)
              if (!sonMu)
                const Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 68,
                  endIndent: 0,
                  color: Color(0xFFF0F0F0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}