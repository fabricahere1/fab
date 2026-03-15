import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'profil_tamamla_screen.dart';
 
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
 
  Future<void> _profilKontrolEtVeYonlendir(String uid) async {
    debugPrint('=== PROFİL KONTROL ===');
    debugPrint('uid: $uid');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .get();
      debugPrint('doc exists: ${doc.exists}');
      debugPrint('doc data: ${doc.data()}');
      final profilTamamlandi = doc.data()?['profilTamamlandi'] == true;
      debugPrint('profilTamamlandi: $profilTamamlandi');
      debugPrint('=== PROFİL KONTROL END ===');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => profilTamamlandi
              ? const HomeScreen()
              : const ProfilTamamlaScreen(ilkGiris: true),
        ),
      );
    } catch (e) {
      debugPrint('PROFİL KONTROL HATA: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilTamamlaScreen(ilkGiris: true)),
      );
    }
  }
 
  Future<void> _login() async {
    if (!_validateInputs()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted && credential.user != null) {
        await _profilKontrolEtVeYonlendir(credential.user!.uid);
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
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      final uid = user?.uid;
 
      if (uid == null) return;
 
      final doc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .get();
 
      if (!doc.exists) {
        final adSoyad = user?.displayName ?? '';
        final email = user?.email ?? '';
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .set({
          'adSoyad': adSoyad,
          'email': email,
          'sehir': '',
          'telefon': '',
          'telefonGizli': false,
          'profilTamamlandi': false,
          'olusturmaTarihi': FieldValue.serverTimestamp(),
        });
      }
 
      if (mounted) {
        await _profilKontrolEtVeYonlendir(uid);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getFirebaseErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage =
          'Google ile giriş yapılamadı. Tekrar deneyin.');
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
                prefixIcon: const Icon(Icons.email_outlined,
                    color: Color(0xFF9E9E9E), size: 20),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
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
              Center(
                child: Text(
                  'İSTE',
                  style: GoogleFonts.roboto(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFE53935),
                    letterSpacing: 3,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: h * 0.005),
              Center(
                child: Text(
                  'Hesabına giriş yap',
                  style: GoogleFonts.roboto(
                      fontSize: 14, color: const Color(0xFF9E9E9E)),
                ),
              ),
              SizedBox(height: h * 0.05),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Şifremi unuttum',
                      style: GoogleFonts.roboto(
                          color: const Color(0xFF757575), fontSize: 12)),
                ),
              ),
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
              SizedBox(height: h * 0.024),
              _S1PrimaryButton(
                label: 'Giriş Yap',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _login,
              ),
              SizedBox(height: h * 0.018),
              Row(
                children: [
                  const Expanded(
                      child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('veya',
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFFBDBDBD), fontSize: 12)),
                  ),
                  const Expanded(
                      child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
                ],
              ),
              SizedBox(height: h * 0.018),
              _S1GoogleButton(
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _loginWithGoogle,
              ),
              SizedBox(height: h * 0.014),
              _S1OutlinedButton(
                label: 'Kayıt Ol',
                onPressed: _isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
              ),
              SizedBox(height: h * 0.028),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                  child: Text(
                    'Giriş yapmadan devam et',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFBDBDBD),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFBDBDBD),
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
 
class _S1PrimaryButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _S1PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });
 
  @override
  State<_S1PrimaryButton> createState() => _S1PrimaryButtonState();
}
 
class _S1PrimaryButtonState extends State<_S1PrimaryButton> {
  bool _hovered = false;
 
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: widget.onPressed == null
              ? const Color(0xFFBDBDBD)
              : _hovered
                  ? const Color(0xFFC62828)
                  : const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(6),
          boxShadow: _hovered && widget.onPressed != null
              ? [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Transform.translate(
          offset: Offset(0, _hovered && widget.onPressed != null ? -1 : 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(6),
              splashColor: Colors.white.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.label,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 
class _S1GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _S1GoogleButton({required this.isLoading, required this.onPressed});
 
  @override
  State<_S1GoogleButton> createState() => _S1GoogleButtonState();
}
 
class _S1GoogleButtonState extends State<_S1GoogleButton> {
  bool _hovered = false;
 
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(6),
            splashColor: Colors.black.withValues(alpha: 0.04),
            highlightColor: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: _GoogleLogoPainter()),
                ),
                const SizedBox(width: 10),
                Text(
                  'Google ile Giriş Yap',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF424242),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 
class _S1OutlinedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  const _S1OutlinedButton({required this.label, required this.onPressed});
 
  @override
  State<_S1OutlinedButton> createState() => _S1OutlinedButtonState();
}
 
class _S1OutlinedButtonState extends State<_S1OutlinedButton> {
  bool _hovered = false;
 
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF5F5F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _hovered ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(6),
            splashColor: Colors.black.withValues(alpha: 0.04),
            highlightColor: Colors.transparent,
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF212121),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const sweepAngle = 2 * 3.14159265;
 
    canvas.drawArc(rect, -0.5, sweepAngle * 0.25, false,
        Paint()..color = const Color(0xFFEA4335)..strokeWidth = size.width * 0.28..style = PaintingStyle.stroke);
    canvas.drawArc(rect, -0.5 + sweepAngle * 0.25, sweepAngle * 0.25, false,
        Paint()..color = const Color(0xFFFBBC05)..strokeWidth = size.width * 0.28..style = PaintingStyle.stroke);
    canvas.drawArc(rect, -0.5 + sweepAngle * 0.5, sweepAngle * 0.25, false,
        Paint()..color = const Color(0xFF34A853)..strokeWidth = size.width * 0.28..style = PaintingStyle.stroke);
    canvas.drawArc(rect, -0.5 + sweepAngle * 0.75, sweepAngle * 0.25, false,
        Paint()..color = const Color(0xFF4285F4)..strokeWidth = size.width * 0.28..style = PaintingStyle.stroke);
  }
 
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF212121)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(color: const Color(0xFFBDBDBD), fontSize: 14),
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
          borderSide: const BorderSide(color: Color(0xFF3C3C3C), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}