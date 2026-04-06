import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../profil/providers/profil_provider.dart';
import '../../profil/data/kullanici_repository.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';

class AyarlarScreen extends ConsumerStatefulWidget {
  const AyarlarScreen({super.key});

  @override
  ConsumerState<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends ConsumerState<AyarlarScreen> {
  bool _ilanBildirimleri = true;
  bool _mesajBildirimleri = true;
  bool _sistemBildirimleri = true;
  bool _bildirimlerYuklendi = false;

  @override
  void initState() {
    super.initState();
    _bildirimlerYukle();
  }

  Future<void> _bildirimlerYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ilanBildirimleri = prefs.getBool('bildirim_ilan') ?? true;
      _mesajBildirimleri = prefs.getBool('bildirim_mesaj') ?? true;
      _sistemBildirimleri = prefs.getBool('bildirim_sistem') ?? true;
      _bildirimlerYuklendi = true;
    });
  }

  Future<void> _bildirimKaydet(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final benimProfilAsync = ref.watch(benimKullaniciProfilProvider);
    final engellenenlerAsync = ref.watch(engellenenlerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Ayarlar',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [

          // ── Hesap ───────────────────────────────────
          _BolumBasligi('Hesap'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.email_outlined,
                label: 'E-posta',
                trailing: Text(
                  user?.email ?? '',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                onTap: () {},
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.lock_outline,
                label: 'Şifre Değiştir',
                onTap: () => _sifreDegistirDialog(user?.email),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.phone_outlined,
                label: 'Telefon Numarası',
                trailing: Text(
                  benimProfilAsync.value?.telefon?.isNotEmpty == true
                      ? benimProfilAsync.value!.telefon!
                      : 'Eklenmemiş',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                onTap: () => _telefonGuncelleDialog(
                    benimProfilAsync.value?.telefon ?? ''),
              ),
            ],
          ),

          // ── Bildirimler ─────────────────────────────
          _BolumBasligi('Bildirimler'),
          _Kart(
            children: !_bildirimlerYuklendi
                ? [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.red)),
                    )
                  ]
                : [
                    _SwitchSatir(
                      icon: Icons.mark_chat_unread_outlined,
                      label: 'Mesaj bildirimleri',
                      acik: _mesajBildirimleri,
                      onChanged: (v) {
                        setState(() => _mesajBildirimleri = v);
                        _bildirimKaydet('bildirim_mesaj', v);
                      },
                    ),
                    _Ayrac(),
                    _SwitchSatir(
                      icon: Icons.campaign_outlined,
                      label: 'İlan bildirimleri',
                      acik: _ilanBildirimleri,
                      onChanged: (v) {
                        setState(() => _ilanBildirimleri = v);
                        _bildirimKaydet('bildirim_ilan', v);
                      },
                    ),
                    _Ayrac(),
                    _SwitchSatir(
                      icon: Icons.notifications_outlined,
                      label: 'Sistem bildirimleri',
                      acik: _sistemBildirimleri,
                      onChanged: (v) {
                        setState(() => _sistemBildirimleri = v);
                        _bildirimKaydet('bildirim_sistem', v);
                      },
                    ),
                  ],
          ),

          // ── Gizlilik ────────────────────────────────
          _BolumBasligi('Gizlilik'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.block_outlined,
                label: 'Engellenen Kullanıcılar',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    engellenenlerAsync.value?.length.toString() ?? '0',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () => _engellenenlerSayfasi(
                    engellenenlerAsync.value ?? []),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.privacy_tip_outlined,
                label: 'Gizlilik Politikası',
                onTap: () {},
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.description_outlined,
                label: 'Kullanım Koşulları',
                onTap: () {},
              ),
            ],
          ),

          // ── Destek ──────────────────────────────────
          _BolumBasligi('Destek'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.mail_outline,
                label: 'Bize Ulaşın',
                onTap: () => _iletisimDialog(),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.help_outline,
                label: 'Sık Sorulan Sorular',
                onTap: () {},
              ),
            ],
          ),

          // ── Hesap İşlemleri ─────────────────────────
          _BolumBasligi('Tehlikeli Bölge'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.delete_forever_outlined,
                label: 'Hesabı Sil',
                labelColor: AppColors.red,
                iconColor: AppColors.red,
                showArrow: false,
                onTap: () => _hesapSilDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('İSTE v2.0',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _sifreDegistirDialog(String? email) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Şifre Sıfırla',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(email ?? '',
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (email != null) {
                await ref.read(authProvider.notifier).sifreSifirla(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Şifre sıfırlama e-postası gönderildi.',
                        style: GoogleFonts.dmSans()),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: Text('Gönder',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _telefonGuncelleDialog(String mevcutTelefon) async {
    final ctrl = TextEditingController(text: mevcutTelefon);
    bool gizli = ref.read(benimKullaniciProfilProvider).value?.telefonGizli ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Telefon Numarası',
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '05XX XXX XX XX',
                  hintStyle: GoogleFonts.dmSans(
                      color: AppColors.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.textSecondary, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setS(() => gizli = !gizli),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: gizli ? AppColors.primary : AppColors.divider,
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 150),
                        alignment: gizli
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Telefon numaramı gizle',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final uid = ref.read(currentUserProvider)?.uid;
                if (uid == null) return;
                await ref.read(kullaniciRepositoryProvider).profilGuncelle(
                  uid: uid,
                  data: {'telefon': ctrl.text.trim(), 'telefonGizli': gizli},
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Telefon numarası güncellendi.',
                        style: GoogleFonts.dmSans()),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: Text('Kaydet',
                  style: GoogleFonts.dmSans(
                      color: AppColors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  void _engellenenlerSayfasi(List<String> engellenenUidler) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _EngellenenlerScreen(engellenenUidler: engellenenUidler),
      ),
    );
  }

  Future<void> _iletisimDialog() async {
    final konuCtrl = TextEditingController();
    final mesajCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Bize Ulaşın',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: konuCtrl,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Konu başlığı',
                hintStyle: GoogleFonts.dmSans(
                    color: AppColors.textHint, fontSize: 13),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mesajCtrl,
              maxLines: 4,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Mesajınız...',
                hintStyle: GoogleFonts.dmSans(
                    color: AppColors.textHint, fontSize: 13),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (konuCtrl.text.trim().isEmpty ||
                  mesajCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Mesajınız iletildi, teşekkürler!',
                    style: GoogleFonts.dmSans()),
                backgroundColor: AppColors.green,
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: Text('Gönder',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    konuCtrl.dispose();
    mesajCtrl.dispose();
  }

  Future<void> _hesapSilDialog() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final googleGiris = user.providerData
        .any((p) => p.providerId == 'google.com');

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Hesabı Sil',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Hesabını silersen tüm ilanların, mesajların ve verilerın kalıcı olarak silinecek.\n\nBu işlem geri alınamaz!',
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Devam Et',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    if (googleGiris) {
      await _googleReAuth();
    } else {
      await _emailReAuth(user.email ?? '');
    }
  }

  Future<void> _emailReAuth(String email) async {
    final sifreCtrl = TextEditingController();

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Kimliğini Doğrula',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Güvenlik için şifreni gir.',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sifreCtrl,
              obscureText: true,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Şifren',
                hintStyle: GoogleFonts.dmSans(
                    color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.lock_outline,
                    color: AppColors.textSecondary, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hesabı Sil',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) {
      sifreCtrl.dispose();
      return;
    }

    try {
      await ref.read(authRepositoryProvider).emailIleYenidenGiris(
            email: email,
            sifre: sifreCtrl.text.trim(),
          );
      await ref.read(authRepositoryProvider).hesapSil();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hesabın silindi.', style: GoogleFonts.dmSans()),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: Şifre yanlış veya bir sorun oluştu.',
              style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    sifreCtrl.dispose();
  }

  Future<void> _googleReAuth() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Kimliğini Doğrula',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Hesabını silmek için Google ile tekrar giriş yapman gerekiyor.',
          style: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Google ile Doğrula',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).googleIleYenidenGiris();
      await ref.read(authRepositoryProvider).hesapSil();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hesabın silindi.', style: GoogleFonts.dmSans()),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata oluştu. Tekrar dene.',
              style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ── Engellenenler Sayfası ─────────────────────────────────

class _EngellenenlerScreen extends ConsumerWidget {
  final List<String> engellenenUidler;
  const _EngellenenlerScreen({required this.engellenenUidler});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benimUid = ref.watch(currentUserProvider)?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Engellenen Kullanıcılar',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: engellenenUidler.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block_outlined,
                      size: 64, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text('Engellenen kullanıcı yok',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: engellenenUidler.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final hedefUid = engellenenUidler[index];
                final profilAsync =
                    ref.watch(kullaniciBilgiProvider(hedefUid));

                return profilAsync.when(
                  loading: () => const ListTile(
                    leading: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.red)),
                    title: Text('Yükleniyor...'),
                  ),
                  error: (_, __) => ListTile(
                    leading: AvatarWidget(isim: hedefUid, radius: 24),
                    title: Text('Kullanıcı',
                        style: GoogleFonts.dmSans(fontSize: 14)),
                  ),
                  data: (profil) {
                    final ad = profil?.adSoyad ?? 'Kullanıcı';
                    return ListTile(
                      leading: AvatarWidget(isim: ad, radius: 24),
                      title: Text(ad,
                          style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                      trailing: TextButton(
                        onPressed: () async {
                          final onay = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              title: Text('Engeli Kaldır',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              content: Text(
                                  '$ad adlı kullanıcının engelini kaldırmak istiyor musun?',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: AppColors.textSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text('İptal',
                                      style: GoogleFonts.dmSans(
                                          color: AppColors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text('Kaldır',
                                      style: GoogleFonts.dmSans(
                                          color: AppColors.red,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                          if (onay == true) {
                            await ref
                                .read(engellemeProvider.notifier)
                                .engelKaldir(
                                  benimUid: benimUid,
                                  hedefUid: hedefUid,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('$ad engeli kaldırıldı.',
                                    style: GoogleFonts.dmSans()),
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          }
                        },
                        child: Text('Engeli Kaldır',
                            style: GoogleFonts.dmSans(
                                color: AppColors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                );
              },
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
  final Color iconColor;
  final Color labelColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool showArrow;

  const _SatirOge({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
    this.trailing,
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: labelColor,
                      fontWeight: FontWeight.w500)),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && showArrow)
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchSatir extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool acik;
  final ValueChanged<bool> onChanged;

  const _SwitchSatir({
    required this.icon,
    required this.label,
    required this.acik,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: acik,
            onChanged: onChanged,
            activeColor: AppColors.red,
          ),
        ],
      ),
    );
  }
}