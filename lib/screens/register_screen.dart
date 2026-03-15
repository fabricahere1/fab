import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'profil_tamamla_screen.dart';
 
const _primary = Color(0xFF3C3C3C);
const _surface = Color(0xFFF5F5F5);
const _divider = Color(0xFFE0E0E0);
const _textPrimary = Color(0xFF212121);
const _textSecondary = Color(0xFF757575);
const _red = Color(0xFFE53935);
 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
 
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen> {
  final _adSoyadController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
 
  final _adFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
 
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';
 
  @override
  void dispose() {
    _adSoyadController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }
 
  bool _validate() {
    final ad = _adSoyadController.text.trim();
    final email = _emailController.text.trim();
    final sifre = _passwordController.text;
    final sifreTekrar = _confirmPasswordController.text;
 
    if (ad.isEmpty) {
      setState(() => _errorMessage = 'Ad Soyad boş olamaz.');
      return false;
    }
    if (ad.length < 2) {
      setState(() => _errorMessage = 'Ad Soyad en az 2 karakter olmalıdır.');
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Geçerli bir e-posta adresi girin.');
      return false;
    }
    if (sifre.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalıdır.');
      return false;
    }
    if (sifre != sifreTekrar) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor.');
      return false;
    }
    return true;
  }
 
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
 
  Future<void> _register() async {
    if (!_validate()) return;
 
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
 
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
 
      final user = credential.user;
      final adSoyad = _adSoyadController.text.trim();
 
      await user?.updateDisplayName(adSoyad);
 
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(user.uid)
            .set({
          'adSoyad': adSoyad,
          'email': user.email,
          'sehir': '',
          'telefon': '',
          'olusturmaTarihi': FieldValue.serverTimestamp(),
        });
      }
 
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const ProfilTamamlaScreen(ilkGiris: true)),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getFirebaseErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.01),
 
              // Logo
              Center(
                child: Text(
                  'İSTE',
                  style: GoogleFonts.roboto(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: _red,
                    letterSpacing: 3,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: h * 0.005),
              Center(
                child: Text(
                  'Yeni hesap oluştur',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
              ),
              SizedBox(height: h * 0.04),
 
              // Ad Soyad
              _Etiket('Ad Soyad'),
              SizedBox(height: h * 0.008),
              _RegisterInput(
                controller: _adSoyadController,
                focusNode: _adFocusNode,
                hint: 'Adınız Soyadınız',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocusNode),
              ),
              SizedBox(height: h * 0.022),
 
              // E-posta
              _Etiket('E-posta'),
              SizedBox(height: h * 0.008),
              _RegisterInput(
                controller: _emailController,
                focusNode: _emailFocusNode,
                hint: 'ornek@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocusNode),
              ),
              SizedBox(height: h * 0.022),
 
              // Şifre
              _Etiket('Şifre'),
              SizedBox(height: h * 0.008),
              _RegisterInput(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_confirmFocusNode),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _textSecondary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              SizedBox(height: h * 0.022),
 
              // Şifre Tekrar
              _Etiket('Şifre Tekrar'),
              SizedBox(height: h * 0.008),
              _RegisterInput(
                controller: _confirmPasswordController,
                focusNode: _confirmFocusNode,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _textSecondary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              SizedBox(height: h * 0.02),
 
              // Hata mesajı
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: _red, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: GoogleFonts.roboto(
                              color: _red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
 
              SizedBox(height: h * 0.01),
 
              // Kayıt ol butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Kayıt Ol',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              SizedBox(height: h * 0.02),
 
              // Giriş yap
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.roboto(
                          color: _textSecondary, fontSize: 13),
                      children: [
                        const TextSpan(text: 'Zaten hesabın var mı? '),
                        TextSpan(
                          text: 'Giriş yap',
                          style: GoogleFonts.roboto(
                            color: _primary,
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
 
// ── Yardımcı Widget'lar ───────────────────────────────────
 
class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);
 
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF424242),
      ),
    );
  }
}
 
class _RegisterInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
 
  const _RegisterInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.suffixIcon,
  });
 
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: GoogleFonts.roboto(
          fontSize: 14, color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
            color: const Color(0xFFBDBDBD), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}