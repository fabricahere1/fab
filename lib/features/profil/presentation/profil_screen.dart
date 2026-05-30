import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../favoriler/presentation/favoriler_screen.dart';
import 'ilanlarim_screen.dart';
import 'ayarlar_screen.dart';
import 'profil_duzenle_screen.dart';
import '../../degerlendirme/presentation/degerlendirmeler_liste_screen.dart';
import '../../degerlendirme/providers/degerlendirme_provider.dart';
import '../../degerlendirme/presentation/degerlendirme_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import 'package:flutter/rendering.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen>
    with AutomaticKeepAliveClientMixin {

  final _scrollCtrl = ScrollController();
  double _sonScrollPixel = 0;
  static const double _threshold = 80;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    final simdi = pos.pixels;
    if (pos.userScrollDirection == ScrollDirection.reverse) {
      _sonScrollPixel = simdi;
      ref.read(navBarGizliProvider.notifier).gizle();
    } else if (pos.userScrollDirection == ScrollDirection.forward) {
      if (simdi < _sonScrollPixel - _threshold) {
        _sonScrollPixel = simdi;
        ref.read(navBarGizliProvider.notifier).goster();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _cikisDialog() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Çıkış Yap',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
            'Hesabından çıkmak istediğine emin misin?',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Çıkış Yap',
                style: GoogleFonts.dmSans(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay == true) {
      ref.read(authProvider.notifier).cikisYap();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(currentUserProvider);
    final benimProfilAsync = ref.watch(benimKullaniciProfilProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── Profil Kartı ──────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AvatarWidget(
                  isim: user?.displayName ?? user?.email ?? '',
                  radius: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Kullanıcı',
                        style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      benimProfilAsync.when(
                        data: (profil) {
                          final sehir = profil?.sehir ?? '';
                          final puan = profil?.ortalamaPuan ?? 0.0;
                          final sayi = profil?.degerlendirmeSayisi ?? 0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sehir.isNotEmpty)
                                Row(children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(sehir,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ])
                              else
                                Text('Profil tamamlanmamış',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.textHint)),
                              if (sayi > 0) ...[
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    final uid = ref.read(currentUserProvider)?.uid ?? '';
                                    final ad = profil?.adSoyad ?? '';
                                    if (uid.isEmpty) return;
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => DegerlendirmelerListeScreen(
                                        kullaniciId: uid,
                                        kullaniciAd: ad,
                                      ),
                                    ));
                                  },
                                  child: Row(children: [
                                    ...List.generate(5, (i) => Icon(
                                      i < puan.floor()
                                          ? Icons.star_rounded
                                          : (i < puan
                                              ? Icons.star_half_rounded
                                              : Icons.star_outline_rounded),
                                      color: const Color(0xFFFFA726),
                                      size: 14,
                                    )),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${puan.toStringAsFixed(1)} ($sayi)',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          decoration: TextDecoration.underline),
                                    ),
                                  ]),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfilDuzenleScreen()),
                  ),
                ),
              ],
            ),
          ),

          // ── Hesabım ───────────────────────────────────
          _BolumBasligi('Hesabım'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.list_alt_outlined,
                label: 'İlanlarım',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IlanlarimScreen()),
                ),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.favorite_border,
                label: 'Favorilerim',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FavorilerScreen()),
                ),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.star_border,
                label: 'Değerlendirmelerim',
                onTap: () {
                  final uid = ref.read(currentUserProvider)?.uid ?? '';
                  final ad = ref.read(benimKullaniciProfilProvider).value?.adSoyad ?? '';
                  if (uid.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DegerlendirmelerListeScreen(
                        kullaniciId: uid,
                        kullaniciAd: ad,
                      ),
                    ),
                  );
                },
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.hourglass_empty_rounded,
                label: 'Bekleyen Değerlendirmeler',
                onTap: () {
                  final uid = ref.read(currentUserProvider)?.uid ?? '';
                  if (uid.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _BekleyenDegerlendirmelerScreen(
                        kullaniciId: uid,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Diğer ─────────────────────────────────────
          _BolumBasligi('Diğer'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.settings_outlined,
                label: 'Ayarlar',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AyarlarScreen()),
                ),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.mail_outline,
                label: 'İletişim',
                onTap: () {},
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.privacy_tip_outlined,
                label: 'Gizlilik Politikası',
                onTap: () {},
              ),
            ],
          ),

          // ── Çıkış Yap ────────────────────────────────
          _BolumBasligi(''),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.logout,
                label: 'Çıkış Yap',
                labelColor: AppColors.red,
                showArrow: false,
                onTap: _cikisDialog,
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'İSTE v3.0',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  const _BolumBasligi(this.baslik);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        baslik.toUpperCase(),
        style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0),
      ),
    );
  }
}

class _Kart extends StatelessWidget {
  final List<Widget> children;
  const _Kart({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Ayrac extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 54, endIndent: 0);
  }
}

class _SatirOge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;
  final bool showArrow;

  const _SatirOge({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor = AppColors.textPrimary,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.black87, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: labelColor,
                      fontWeight: FontWeight.w500)),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bekleyen Değerlendirmeler ─────────────────────────────

class _BekleyenDegerlendirmelerScreen extends ConsumerWidget {
  final String kullaniciId;
  const _BekleyenDegerlendirmelerScreen({required this.kullaniciId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bekleyenlerAsync =
        ref.watch(bekleyenDegerlendirmelerProvider(kullaniciId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Bekleyen Değerlendirmeler',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: bekleyenlerAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF81C784), strokeWidth: 2)),
        error: (_, _) => Center(
          child: Text('Bir hata oluştu.',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (liste) {
          if (liste.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_empty_rounded,
                        size: 36, color: Color(0xFF81C784)),
                  ),
                  const SizedBox(height: 16),
                  Text('Bekleyen değerlendirme yok',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Teslim aldıktan sonra değerlendirme\nyapabilirsin.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: liste.length,
            itemBuilder: (ctx, i) {
              final item = liste[i];
              final sohbetId = item['sohbetId'] as String? ?? '';
              return _BekleyenKarti(
                sohbetId: sohbetId,
                kullaniciId: kullaniciId,
                index: i,
              );
            },
          );
        },
      ),
    );
  }
}

class _BekleyenKarti extends ConsumerWidget {
  final String sohbetId;
  final String kullaniciId;
  final int index;

  const _BekleyenKarti({
    required this.sohbetId,
    required this.kullaniciId,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sohbetAsync = ref.watch(sohbetDurumuProvider(sohbetId));

    return sohbetAsync.when(
      loading: () => const SizedBox(height: 72),
      error: (_, _) => const SizedBox.shrink(),
      data: (sohbet) {
        if (sohbet.isEmpty) return const SizedBox.shrink();

        final kullanicilar = List<String>.from(sohbet['kullanicilar'] ?? []);
        final karsiId =
            kullanicilar.where((id) => id != kullaniciId).firstOrNull ?? '';
        final ilanBaslik = sohbet['ilanBaslik'] as String? ?? 'İlan';

        final karsiProfilAsync = karsiId.isNotEmpty
            ? ref.watch(kullaniciBilgiProvider(karsiId))
            : null;
        final karsiAd =
            karsiProfilAsync?.value?.adSoyad.isNotEmpty == true
                ? karsiProfilAsync!.value!.adSoyad
                : 'Kullanıcı';
        final karsiFotoUrl = karsiProfilAsync?.value?.fotoUrl;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Color(0xFF81C784), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ilanBaslik,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        karsiAd,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    if (karsiId.isEmpty) return;
                    final tamamlandi = await DegerlendirmeModal.goster(
                      context: context,
                      sohbetId: sohbetId,
                      hedefKullaniciId: karsiId,
                      hedefKullaniciAd: karsiAd,
                      hedefFotoUrl: karsiFotoUrl,
                    );
                    if (tamamlandi && context.mounted) {
                      await ref
                          .read(degerlendirmeIslemleriProvider.notifier)
                          .bekleyenTamamla(
                            sohbetId: sohbetId,
                            kullaniciId: kullaniciId,
                          );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Değerlendir',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}