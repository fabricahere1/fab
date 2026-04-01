import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../router/app_router.dart';
 
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
 
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  bool _sifreGizli = true;
  String _hata = '';
 
  @override
  void dispose() {
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _girisYap() async {
    if (_emailCtrl.text.trim().isEmpty || _sifreCtrl.text.trim().isEmpty) {
      setState(() => _hata = 'E-posta ve şifre boş olamaz.');
      return;
    }
    setState(() => _hata = '');
 
    final sonuc = await ref.read(authProvider.notifier).emailIleGiris(
          email: _emailCtrl.text,
          sifre: _sifreCtrl.text,
        );
 
    if (!mounted) return;
 
    if (!sonuc.basarili) {
      setState(() => _hata = sonuc.hata ?? 'Bir hata oluştu.');
    }
  }
 
  Future<void> _googleIleGiris() async {
    setState(() => _hata = '');
    final sonuc = await ref.read(authProvider.notifier).googleIleGiris();
    if (!mounted) return;
    if (!sonuc.basarili) {
      setState(() => _hata = sonuc.hata ?? 'Google girişi başarısız.');
    }
  }
 
  Future<void> _sifreSifirla() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Şifremi Unuttum',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ornek@email.com',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppColors.textSecondary, size: 20),
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
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(authProvider.notifier).sifreSifirla(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Şifre sıfırlama e-postası gönderildi.',
                        style: GoogleFonts.dmSans()),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Gönder',
                style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(authProvider).isLoading;
    final h = MediaQuery.of(context).size.height;
 
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.10),
              Center(
                child: Text('İSTE',
                    style: GoogleFonts.dmSans(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.red,
                      letterSpacing: 3,
                      height: 1,
                    )),
              ),
              SizedBox(height: h * 0.005),
              Center(
                child: Text('Hesabına giriş yap',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textSecondary)),
              ),
              SizedBox(height: h * 0.05),
 
              Text('E-posta',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
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
 
              Text('Şifre',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _sifreCtrl,
                obscureText: _sifreGizli,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _girisYap(),
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
 
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sifreSifirla,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Şifremi unuttum',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
              ),
 
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
 
              SizedBox(height: h * 0.024),
 
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: yukleniyor ? null : _girisYap,
                  child: yukleniyor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Giriş Yap',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: h * 0.018),
 
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('veya',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textHint, fontSize: 12)),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              SizedBox(height: h * 0.018),
 
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: yukleniyor ? null : _googleIleGiris,
                  icon: const Icon(Icons.g_mobiledata,
                      color: AppColors.textPrimary, size: 24),
                  label: Text('Google ile Giriş Yap',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              SizedBox(height: h * 0.014),
 
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: yukleniyor
                      ? null
                      : () => context.push(AppRoutes.register),
                  child: Text('Kayıt Ol',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
              SizedBox(height: h * 0.028),
 
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text('Giriş yapmadan devam et',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textHint,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textHint,
                      )),
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