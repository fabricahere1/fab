import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../../mesajlar/data/mesaj_repository.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';
 
class MesajlarScreen extends ConsumerStatefulWidget {
  const MesajlarScreen({super.key});
 
  @override
  ConsumerState<MesajlarScreen> createState() => _MesajlarScreenState();
}
 
class _MesajlarScreenState extends ConsumerState<MesajlarScreen>
    with AutomaticKeepAliveClientMixin {
 
  @override
  bool get wantKeepAlive => true;
 
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = ref.watch(currentUserProvider)?.uid;
    final sohbetlerAsync = ref.watch(sohbetlerProvider);
    final engellenenlerAsync = ref.watch(engellenenlerProvider);
 
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('Mesajlar',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 64, color: AppColors.divider),
              const SizedBox(height: 16),
              Text('Mesajları görmek için giriş yap',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
 
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Mesajlar',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: sohbetlerAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.red, strokeWidth: 2)),
        error: (_, _) => Center(
          child: Text('Bir hata oluştu.',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (sohbetler) {
          final engellenenUidler = (engellenenlerAsync.value ?? []).toSet();
 
          final gorunenler = sohbetler.where((s) {
            final kullanicilar =
                List<String>.from(s['kullanicilar'] ?? []);
            final karsiUid = kullanicilar
                .firstWhere((id) => id != uid, orElse: () => '');
 
            if (engellenenUidler.contains(karsiUid)) return false;
 
            final gizli = (s['gizli'] as Map<String, dynamic>?) ?? {};
            final gizliDeger = gizli[uid];
            if (gizliDeger == null) return true;
            if (gizliDeger is bool && gizliDeger == true) return false;
            if (gizliDeger is Timestamp) {
              final sonMesajZamani = s['sonMesajZamani'] as Timestamp?;
              if (sonMesajZamani == null) return false;
              return sonMesajZamani.toDate().isAfter(gizliDeger.toDate());
            }
            return true;
          }).toList();
 
          if (gorunenler.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 64, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text('Henüz mesajın yok',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('İlanlara tıklayarak mesaj gönderebilirsin',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textHint)),
                ],
              ),
            );
          }
 
          return ListView.separated(
            itemCount: gorunenler.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final sohbet = gorunenler[index];
              return RepaintBoundary(
                child: _SohbetKarti(
                  sohbet: sohbet,
                  benimUid: uid,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
 
// ── Sohbet Kartı ──────────────────────────────────────────
 
class _SohbetKarti extends ConsumerWidget {
  final Map<String, dynamic> sohbet;
  final String benimUid;
 
  const _SohbetKarti({
    required this.sohbet,
    required this.benimUid,
  });
 
  Future<void> _silDialog(
      BuildContext context, WidgetRef ref, String sohbetId) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text('Sohbeti Sil',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Bu sohbet sadece senin için silinecek.',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
 
    if (onay == true && context.mounted) {
      await ref.read(mesajRepositoryProvider).sohbetiGizle(
            sohbetId: sohbetId,
            kullaniciId: benimUid,
          );
    }
  }
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kullanicilar = List<String>.from(sohbet['kullanicilar'] ?? []);
    final karsiUid = kullanicilar
        .firstWhere((id) => id != benimUid, orElse: () => '');
 
    final kullaniciAdlari =
        Map<String, String>.from(sohbet['kullaniciAdlari'] ?? {});
    final karsiAd = kullaniciAdlari[karsiUid] ?? 'Kullanıcı';
 
    final sonMesaj = sohbet['sonMesaj'] as String? ?? '';
    final sonMesajZamani = sohbet['sonMesajZamani'] as Timestamp?;
    final ilanBaslik = sohbet['ilanBaslik'] as String? ?? '';
    final ilanId = sohbet['ilanId'] as String? ?? '';
    final ilanResimUrl = sohbet['ilanResimUrl'] as String? ?? '';
    final sohbetId = sohbet['id'] as String? ?? '';
 
    final okunmamis = (sohbet['okunmamis'] as Map<String, dynamic>?) ?? {};
    final okunmamisSayi = ((okunmamis[benimUid] as num?)?.toInt() ?? 0);
 
    final zamanYazi = sonMesajZamani != null
        ? _zamanFormat(sonMesajZamani.toDate())
        : '';
 
    final sabitlenmis =
        (sohbet['sabitlenmis'] as Map<String, dynamic>?)?[benimUid]
            as bool? ?? false;
 
    return GestureDetector(
      onLongPress: () => _silDialog(context, ref, sohbetId),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SohbetScreen(
            karsiKullaniciId: karsiUid,
            karsiKullaniciAd: karsiAd,
            ilanId: ilanId,
            ilanBaslik: ilanBaslik,
            ilanResimUrl: ilanResimUrl.isNotEmpty ? ilanResimUrl : null,
            sohbetId: sohbetId,
          ),
        ),
      ),
      child: Container(
        color: sabitlenmis ? AppColors.surface : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                ilanResimUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedNetworkImage(
                          imageUrl: ilanResimUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          errorWidget: (_, _, _) =>
                              AvatarWidget(isim: karsiAd, radius: 24),
                        ),
                      )
                    : AvatarWidget(isim: karsiAd, radius: 24),
                if (sabitlenmis)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.push_pin,
                          size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ilanBaslik.isNotEmpty ? ilanBaslik : karsiAd,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: okunmamisSayi > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        zamanYazi,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: okunmamisSayi > 0
                              ? AppColors.red
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (ilanBaslik.isNotEmpty)
                    Text(
                      karsiAd,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sonMesaj,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: okunmamisSayi > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: okunmamisSayi > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (okunmamisSayi > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$okunmamisSayi',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  String _zamanFormat(DateTime zaman) {
    final simdi = DateTime.now();
    final fark = simdi.difference(zaman);
    if (fark.inDays == 0) {
      return '${zaman.hour.toString().padLeft(2, '0')}:${zaman.minute.toString().padLeft(2, '0')}';
    } else if (fark.inDays == 1) {
      return 'Dün';
    } else if (fark.inDays < 7) {
      const gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return gunler[zaman.weekday - 1];
    } else {
      return '${zaman.day}.${zaman.month}.${zaman.year}';
    }
  }
}