import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../../profil/presentation/kullanim_kosullari_screen.dart';
 
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
 
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _adCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _sifreTekrarCtrl = TextEditingController();
 
  bool _sifreGizli = true;
  bool _sifreTekrarGizli = true;
  bool _kosullariKabul = false;
  String _hata = '';
 
  @override
  void dispose() {
    _adCtrl.dispose();
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    _sifreTekrarCtrl.dispose();
    super.dispose();
  }
 
  bool _validate() {
    final ad = _adCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final sifre = _sifreCtrl.text;
    final sifreTekrar = _sifreTekrarCtrl.text;
 
    if (ad.isEmpty || ad.length < 2) {
      setState(() => _hata = 'Ad Soyad en az 2 karakter olmalıdır.');
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _hata = 'Geçerli bir e-posta adresi girin.');
      return false;
    }
    if (sifre.length < 6) {
      setState(() => _hata = 'Şifre en az 6 karakter olmalıdır.');
      return false;
    }
    if (sifre != sifreTekrar) {
      setState(() => _hata = 'Şifreler eşleşmiyor.');
      return false;
    }
    if (!_kosullariKabul) {
      setState(() => _hata = 'Kullanım koşullarını kabul etmeniz gerekmektedir.');
      return false;
    }
    return true;
  }
 
  Future<void> _kayitOl() async {
    if (!_validate()) return;
    setState(() => _hata = '');
 
    final sonuc = await ref.read(authProvider.notifier).emailIleKayit(
          adSoyad: _adCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          sifre: _sifreCtrl.text,
        );
 
    if (!mounted) return;
 
    if (sonuc.basarili) {
      context.go(AppRoutes.profilTamamla);
    } else {
      setState(() => _hata = sonuc.hata ?? 'Bir hata oluştu.');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(authProvider).isLoading;
    final h = MediaQuery.of(context).size.height;
 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.01),
              Center(
                child: Text('İSTE',
                    style: GoogleFonts.dmSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.red,
                      letterSpacing: 3,
                      height: 1,
                    )),
              ),
              SizedBox(height: h * 0.005),
              Center(
                child: Text('Yeni hesap oluştur',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textSecondary)),
              ),
              SizedBox(height: h * 0.04),
 
              _Etiket('Ad Soyad'),
              const SizedBox(height: 6),
              TextField(
                controller: _adCtrl,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Adınız Soyadınız',
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
              SizedBox(height: h * 0.022),
 
              _Etiket('E-posta'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'ornek@email.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
              SizedBox(height: h * 0.022),
 
              _Etiket('Şifre'),
              const SizedBox(height: 6),
              TextField(
                controller: _sifreCtrl,
                obscureText: _sifreGizli,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _sifreGizli
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _sifreGizli = !_sifreGizli),
                  ),
                ),
              ),
              SizedBox(height: h * 0.022),
 
              _Etiket('Şifre Tekrar'),
              const SizedBox(height: 6),
              TextField(
                controller: _sifreTekrarCtrl,
                obscureText: _sifreTekrarGizli,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _kayitOl(),
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _sifreTekrarGizli
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _sifreTekrarGizli = !_sifreTekrarGizli),
                  ),
                ),
              ),
              SizedBox(height: h * 0.02),
 
              if (_hata.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.red, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_hata,
                            style: GoogleFonts.dmSans(
                                color: AppColors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
 
              SizedBox(height: h * 0.01),

              GestureDetector(
                onTap: () => setState(() => _kosullariKabul = !_kosullariKabul),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _kosullariKabul,
                        onChanged: (v) => setState(() => _kosullariKabul = v ?? false),
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Okudum, ',
                            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KullanimKosullariScreen()),
                            ),
                            child: Text(
                              'Kullanım Koşulları',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            '\'nı kabul ediyorum.',
                            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h * 0.02),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: yukleniyor ? null : _kayitOl,
                  child: yukleniyor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Kayıt Ol',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: h * 0.02),
 
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary, fontSize: 13),
                      children: [
                        const TextSpan(text: 'Zaten hesabın var mı? '),
                        TextSpan(
                          text: 'Giriş yap',
                          style: GoogleFonts.dmSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.03),
            ],
          ),
        ),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary));
  }
}