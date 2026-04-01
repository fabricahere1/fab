import 'package:flutter/material.dart';
import 'ayarlar_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/ilanlarim_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../favoriler/presentation/favoriler_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';
 
class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});
 
  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}
 
class _ProfilScreenState extends ConsumerState<ProfilScreen> {
 
  Future<void> _cikisDialog() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
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
    final user = ref.watch(currentUserProvider);
    final benimProfilAsync = ref.watch(benimKullaniciProfilProvider);
 
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Profil',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Ayarlar sayfası
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.white,
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
                          if (sehir.isNotEmpty) {
                            return Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text(sehir,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            );
                          }
                          return Text('Profil tamamlanmamış',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textHint));
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () {
                    // TODO: Profil düzenle
                  },
                ),
              ],
            ),
          ),
 
          const SizedBox(height: 8),
 
          Container(
            color: Colors.white,
            child: Column(
              children: [
               _MenuOgesi(
  icon: Icons.list_alt_outlined,
  label: 'İlanlarım',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => const IlanlarimScreen()),
  ),
),
                const Divider(height: 1, indent: 56),
                _MenuOgesi(
                  icon: Icons.favorite_border_outlined,
                  label: 'Favorilerim',
                  iconColor: AppColors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FavorilerScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _MenuOgesi(
                  icon: Icons.star_border_outlined,
                  label: 'Değerlendirmelerim',
                  iconColor: Colors.amber,
                  onTap: () {},
                ),
              ],
            ),
          ),
 
          const SizedBox(height: 8),
 
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _MenuOgesi(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirimler',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _MenuOgesi(
  icon: Icons.settings_outlined,
  label: 'Ayarlar',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AyarlarScreen()),
  ),
),
                const Divider(height: 1, indent: 56),
                _MenuOgesi(
                  icon: Icons.mail_outline,
                  label: 'İletişim',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _MenuOgesi(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Gizlilik Politikası',
                  onTap: () {},
                ),
              ],
            ),
          ),
 
          const SizedBox(height: 8),
 
          Container(
            color: Colors.white,
            child: _MenuOgesi(
              icon: Icons.logout,
              label: 'Çıkış Yap',
              iconColor: AppColors.red,
              labelColor: AppColors.red,
              showArrow: false,
              onTap: _cikisDialog,
            ),
          ),
 
          const SizedBox(height: 32),
 
          Center(
            child: Text(
              'İSTE v2.0',
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
 
class _MenuOgesi extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;
  final bool showArrow;
 
  const _MenuOgesi({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
    this.showArrow = true,
  });
 
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
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