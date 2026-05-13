import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mesajlar/providers/mesaj_provider.dart';
import '../../mesajlar/data/mesaj_repository.dart';
import '../../mesajlar/domain/mesaj_model.dart';
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
            final karsiUid = s.karsiKullaniciId(uid);
            if (engellenenUidler.contains(karsiUid)) return false;
            return !s.gizliMi(uid);
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
                child: _SohbetKarti(sohbet: sohbet, benimUid: uid),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Sohbet Kartı ──────────────────────────────────────────────────────────────

class _SohbetKarti extends ConsumerWidget {
  final SohbetModel sohbet;
  final String benimUid;

  const _SohbetKarti({required this.sohbet, required this.benimUid});

  Future<void> _silDialog(BuildContext context, WidgetRef ref) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            sohbetId: sohbet.id,
            kullaniciId: benimUid,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final karsiUid = sohbet.karsiKullaniciId(benimUid);
    final karsiAdAsync = ref.watch(karsiKullaniciAdProvider(karsiUid));
    final karsiAd = karsiAdAsync.value ?? 'Yükleniyor...';

    final okunmamisSayi = sohbet.okunmamisSayisi(benimUid);
    final zamanYazi = sohbet.sonMesajZamani != null
        ? _zamanFormat(sohbet.sonMesajZamani!)
        : '';
    final sabitlenmis = sohbet.sabitMi(benimUid);

    return GestureDetector(
      onLongPress: () => _silDialog(context, ref),
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => SohbetScreen(
            karsiKullaniciId: karsiUid,
            karsiKullaniciAd: karsiAd,
            ilanId: sohbet.ilanId,
            ilanBaslik: sohbet.ilanBaslik,
            ilanResimUrl: sohbet.ilanResimUrl.isNotEmpty
                ? sohbet.ilanResimUrl
                : null,
            sohbetId: sohbet.id,
            ilanSahibiId: sohbet.ilanSahibiId,
            ilanTip: sohbet.ilanTip,
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
                sohbet.ilanResimUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: sohbet.ilanResimUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          errorWidget: (_, _, _) =>
                              AvatarWidget(isim: karsiAd, radius: 24),
                        ),
                      )
                    : AvatarWidget(isim: karsiAd, radius: 24),
                if (okunmamisSayi > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        okunmamisSayi > 9 ? '9+' : '$okunmamisSayi',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sohbet.ilanBaslik.isNotEmpty ? sohbet.ilanBaslik : 'İlan',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    karsiAd,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sohbet.sonMesaj ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: okunmamisSayi > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: okunmamisSayi > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              zamanYazi,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: okunmamisSayi > 0
                    ? AppColors.red
                    : AppColors.textHint,
                fontWeight: okunmamisSayi > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _zamanFormat(DateTime zaman) {
    final fark = DateTime.now().difference(zaman);
    if (fark.inMinutes < 1) return 'Az önce';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dk';
    if (fark.inHours < 24) return '${fark.inHours} saat';
    if (fark.inDays < 7) return '${fark.inDays} gün';
    return '${zaman.day}.${zaman.month}.${zaman.year}';
  }
}