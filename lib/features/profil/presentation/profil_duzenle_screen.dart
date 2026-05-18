import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../profil/data/kullanici_repository.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' show kDunyaUlkeleri, kTurkiyeSehirleri;
import '../../../shared/widgets/autocomplete_alan.dart';
 
class ProfilDuzenleScreen extends ConsumerStatefulWidget {
  const ProfilDuzenleScreen({super.key});
 
  @override
  ConsumerState<ProfilDuzenleScreen> createState() =>
      _ProfilDuzenleScreenState();
}
 
class _ProfilDuzenleScreenState extends ConsumerState<ProfilDuzenleScreen> {
  final _adSoyadCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _hakkindaCtrl = TextEditingController();
  final _yasadigiUlkeCtrl = TextEditingController();
  final _bulunduguSehirCtrl = TextEditingController();
 
  bool _telefonGizli = false;
  bool _yukleniyor = false;
  bool _veriYuklendi = false;
 
  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }
 
  @override
  void dispose() {
    _adSoyadCtrl.dispose();
    _telefonCtrl.dispose();
    _hakkindaCtrl.dispose();
    _yasadigiUlkeCtrl.dispose();
    _bulunduguSehirCtrl.dispose();
    super.dispose();
  }
 
  void _verileriYukle() {
    final profil = ref.read(benimKullaniciProfilProvider).value;
    if (profil != null) {
      _adSoyadCtrl.text = profil.adSoyad;
      _telefonCtrl.text = profil.telefon ?? '';
      _hakkindaCtrl.text = profil.hakkinda;
      _yasadigiUlkeCtrl.text = profil.yasadigiUlke;
      _bulunduguSehirCtrl.text = profil.bulunduguSehir;
      _telefonGizli = profil.telefonGizli;
      setState(() => _veriYuklendi = true);
    }
  }
 
  Future<void> _kaydet() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
 
    if (_adSoyadCtrl.text.trim().isEmpty) {
      _snack('Ad soyad boş bırakılamaz.');
      return;
    }
 
    setState(() => _yukleniyor = true);
 
    try {
      await ref.read(kullaniciRepositoryProvider).profilGuncelle(
        uid: uid,
        data: {
          'adSoyad': _adSoyadCtrl.text.trim(),
          'telefon': _telefonCtrl.text.trim(),
          'hakkinda': _hakkindaCtrl.text.trim(),
          'yasadigiUlke': _yasadigiUlkeCtrl.text.trim(),
          'bulunduguSehir': _bulunduguSehirCtrl.text.trim(),
          'telefonGizli': _telefonGizli,
        },
      );
 
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profil güncellendi!', style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) _snack('Bir hata oluştu. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }
 
  void _snack(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj, style: GoogleFonts.dmSans()),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }
 
  @override
  Widget build(BuildContext context) {
    // initState'te provider henüz yüklenmediyse, ilk data gelince doldur
    ref.listen(benimKullaniciProfilProvider, (_, next) {
      if (_veriYuklendi) return;
      next.whenData((profil) {
        if (profil == null) return;
        _adSoyadCtrl.text      = profil.adSoyad;
        _telefonCtrl.text      = profil.telefon ?? '';
        _hakkindaCtrl.text     = profil.hakkinda;
        _yasadigiUlkeCtrl.text = profil.yasadigiUlke;
        _bulunduguSehirCtrl.text = profil.bulunduguSehir;
        _telefonGizli = profil.telefonGizli;
        setState(() => _veriYuklendi = true);
      });
    });
 
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Profili Düzenle',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _yukleniyor ? null : _kaydet,
            child: _yukleniyor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.red))
                : Text('Kaydet',
                    style: GoogleFonts.dmSans(
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
 
              // ── Kişisel Bilgiler ───────────────────────
              _Bolum(
                baslik: 'Kişisel Bilgiler',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Ad Soyad *'),
                    const SizedBox(height: 8),
                    _Alan(
                      controller: _adSoyadCtrl,
                      hint: 'Adınız ve soyadınız',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _Etiket('Hakkında'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hakkindaCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'Kendinizi kısaca tanıtın...',
                        icon: Icons.info_outline,
                      ),
                    ),
                  ],
                ),
              ),
 
              const SizedBox(height: 8),
 
              // ── İletişim ───────────────────────────────
              _Bolum(
                baslik: 'İletişim',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Telefon'),
                    const SizedBox(height: 8),
                    _Alan(
                      controller: _telefonCtrl,
                      hint: '05XX XXX XX XX',
                      icon: Icons.phone_outlined,
                      klavye: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _telefonGizli = !_telefonGizli),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _telefonGizli
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 150),
                              alignment: _telefonGizli
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
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
              ),
 
              const SizedBox(height: 8),
 
              // ── Konum ──────────────────────────────────
              _Bolum(
                baslik: 'Konum',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Yaşadığım Ülke'),
                    const SizedBox(height: 8),
                    AutocompleteAlan(
                      controller: _yasadigiUlkeCtrl,
                      hint: 'Ülke ara...',
                      icon: Icons.public_outlined,
                      secenekler: kDunyaUlkeleri,
                    ),
                    const SizedBox(height: 16),
                    _Etiket('Türkiye\'deki Şehrim'),
                    const SizedBox(height: 8),
                    AutocompleteAlan(
                      controller: _bulunduguSehirCtrl,
                      hint: 'Şehir ara...',
                      icon: Icons.location_on_outlined,
                      secenekler: kTurkiyeSehirleri,
                    ),
                  ],
                ),
              ),
 
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
 
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
 
// ── Yardımcı Widget'lar ────────────────────────────────────
 
class _Bolum extends StatelessWidget {
  final String baslik;
  final Widget child;
  const _Bolum({required this.baslik, required this.child});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
 
class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);
 
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary));
  }
}
 
class _Alan extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType klavye;
 
  const _Alan({
    required this.controller,
    required this.hint,
    required this.icon,
    this.klavye = TextInputType.text,
  });
 
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: klavye,
      style: GoogleFonts.dmSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
