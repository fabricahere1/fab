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
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen>
    with AutomaticKeepAliveClientMixin {

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