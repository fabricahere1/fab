// lib/features/teklifler/presentation/teklifler_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/teklif_model.dart';
import '../providers/teklif_provider.dart';
import 'teklif_detay_screen.dart';

class TekliflerScreen extends ConsumerStatefulWidget {
  const TekliflerScreen({super.key});

  @override
  ConsumerState<TekliflerScreen> createState() => _TekliflerScreenState();
}

class _TekliflerScreenState extends ConsumerState<TekliflerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        title: Text('Tekliflerim',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.red,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.red,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [Tab(text: 'Verdiklerim'), Tab(text: 'Aldıklarım')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _TeklifListesi(tip: _TeklifTip.verilen),
          _TeklifListesi(tip: _TeklifTip.alinan),
        ],
      ),
    );
  }
}

enum _TeklifTip { verilen, alinan }

class _TeklifListesi extends ConsumerStatefulWidget {
  final _TeklifTip tip;
  const _TeklifListesi({required this.tip});

  @override
  ConsumerState<_TeklifListesi> createState() => _TeklifListesiState();
}

class _TeklifListesiState extends ConsumerState<_TeklifListesi>
    with AutomaticKeepAliveClientMixin {
  // Tab değişince state korunur — yeniden yüklenme olmaz
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const SizedBox.shrink();

    final tekliflerAsync = widget.tip == _TeklifTip.verilen
        ? ref.watch(benimTekliflerimProvider(uid))
        : ref.watch(ilanSahibiTeklifleriProvider(uid));

    // skipLoadingOnReload: true → yeniden yüklenirken eski veri gösterilir, yanıp sönmez
    return tekliflerAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text('Hata oluştu',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary))),
      data: (teklifler) {
        if (teklifler.isEmpty) return _BosEkran(tip: widget.tip);
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: teklifler.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _TeklifKarti(teklif: teklifler[index]),
        );
      },
    );
  }
}

class _BosEkran extends StatelessWidget {
  final _TeklifTip tip;
  const _BosEkran({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.handshake_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            tip == _TeklifTip.verilen ? 'Henüz teklif vermediniz' : 'Henüz teklif almadınız',
            style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            tip == _TeklifTip.verilen
                ? 'İlan detay sayfasından teklif verebilirsiniz'
                : 'İlanlarınıza gelen teklifler burada görünür',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TeklifKarti extends StatelessWidget {
  final TeklifModel teklif;
  const _TeklifKarti({required this.teklif});

  Color get _durumRenk {
    switch (teklif.durum) {
      case TeklifDurum.kabul:       return AppColors.green;
      case TeklifDurum.reddedildi:  return AppColors.red;
      case TeklifDurum.karsiTeklif: return AppColors.orange;
      case TeklifDurum.bekliyor:    return AppColors.orange;
    }
  }

  String get _durumYazi {
    switch (teklif.durum) {
      case TeklifDurum.kabul:       return 'Kabul';
      case TeklifDurum.reddedildi:  return 'Reddedildi';
      case TeklifDurum.karsiTeklif: return 'Karşı Teklif';
      case TeklifDurum.bekliyor:    return 'Beklemede';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TeklifDetayScreen(teklifId: teklif.id)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teklif.ilanBaslik.isNotEmpty ? teklif.ilanBaslik : 'İlan',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _DurumChip(yazi: _durumYazi, renk: _durumRenk),
                      const Spacer(),
                      Text(
                        '${teklif.miktar.toStringAsFixed(0)} ₺',
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DurumChip extends StatelessWidget {
  final String yazi;
  final Color renk;
  const _DurumChip({required this.yazi, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(yazi, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: renk)),
    );
  }
}
