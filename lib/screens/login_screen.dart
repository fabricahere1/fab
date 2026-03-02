import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'E-posta adresi boş olamaz.');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      setState(() => _errorMessage = 'Geçerli bir e-posta adresi girin.');
      return false;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Şifre boş olamaz.');
      return false;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalıdır.');
      return false;
    }
    return true;
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  Future<void> _login() async {
    if (!_validateInputs()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getFirebaseErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Google ile giriş yapılamadı. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final resetEmailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Şifremi Unuttum',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
              style: GoogleFonts.roboto(color: const Color(0xFF757575), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.roboto(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ornek@email.com',
                hintStyle: GoogleFonts.roboto(color: const Color(0xFFBDBDBD)),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF9E9E9E), size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF3C3C3C), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: GoogleFonts.roboto(color: const Color(0xFF757575))),
          ),
          TextButton(
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: resetEmailController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Şifre sıfırlama e-postası gönderildi.',
                          style: GoogleFonts.roboto()),
                      backgroundColor: const Color(0xFF3C3C3C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() => _errorMessage = _getFirebaseErrorMessage(e.code));
                }
              }
            },
            child: Text('Gönder',
                style: GoogleFonts.roboto(
                    color: const Color(0xFF3C3C3C), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    resetEmailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.10),

              // İste logosu
              Center(
                child: Text(
                  'İste',
                  style: GoogleFonts.pacifico(
                    fontSize: 64,
                    color: const Color(0xFFE53935),
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: h * 0.005),
              Center(
                child: Text(
                  'Hesabına giriş yap',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
              SizedBox(height: h * 0.05),

              // E-posta
              Text('E-posta',
                  style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242))),
              SizedBox(height: h * 0.008),
              _LoginInput(
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
              Text('Şifre',
                  style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242))),
              SizedBox(height: h * 0.008),
              _LoginInput(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF9E9E9E),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              // Şifremi unuttum
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Şifremi unuttum',
                    style: GoogleFonts.roboto(
                        color: const Color(0xFF757575), fontSize: 12),
                  ),
                ),
              ),

              // Hata mesajı
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFE53935), size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_errorMessage,
                            style: GoogleFonts.roboto(
                                color: const Color(0xFFE53935), fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: h * 0.022),

              // Giriş butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C3C3C),
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Giriş Yap',
                          style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                ),
              ),
              SizedBox(height: h * 0.018),

              // Ayırıcı
              Row(
                children: [
                  Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('veya',
                        style: GoogleFonts.roboto(
                            color: const Color(0xFFBDBDBD), fontSize: 12)),
                  ),
                  Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1)),
                ],
              ),
              SizedBox(height: h * 0.018),

              // Google butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata,
                          size: 26, color: Color(0xFFE53935)),
                      const SizedBox(width: 8),
                      Text('Google ile Giriş Yap',
                          style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF424242))),
                    ],
                  ),
                ),
              ),
              SizedBox(height: h * 0.02),

              // Kayıt ol
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.roboto(
                          color: const Color(0xFF9E9E9E), fontSize: 13),
                      children: [
                        const TextSpan(text: 'Hesabın yok mu? '),
                        TextSpan(
                          text: 'Kayıt ol',
                          style: GoogleFonts.roboto(
                              color: const Color(0xFF3C3C3C),
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
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

class _LoginInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _LoginInput({
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
      style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF212121)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.roboto(color: const Color(0xFFBDBDBD), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide:
              const BorderSide(color: Color(0xFF3C3C3C), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}