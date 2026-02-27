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
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
      });
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

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

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
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Google ile giriş yapılamadı. Tekrar deneyin.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final resetEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Şifremi Unuttum',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'ornek@email.com',
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.deepOrangeAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: resetEmailController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Şifre sıfırlama e-postası gönderildi.'),
                      backgroundColor: Colors.green,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child:
                const Text('Gönder', style: TextStyle(color: Colors.white)),
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
              SizedBox(height: h * 0.08),

              // Logo
              Center(
                child: Container(
                  width: h * 0.11,
                  height: h * 0.11,
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.language,
                          size: h * 0.06, color: Colors.deepOrangeAccent),
                      Positioned(
                        right: h * 0.01,
                        bottom: h * 0.01,
                        child: Icon(Icons.flight,
                            size: h * 0.027, color: Colors.deepOrangeAccent),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: h * 0.025),

              // Uygulama adı
              Center(
                child: Text(
                  'Glocal',
                  style: GoogleFonts.lobster(
                    fontSize: h * 0.05,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
              ),
              SizedBox(height: h * 0.005),
              const Center(
                child: Text(
                  'Hesabına giriş yap',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
              SizedBox(height: h * 0.04),

              // E-posta
              const Text(
                'E-posta',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              SizedBox(height: h * 0.008),
              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                },
                decoration: InputDecoration(
                  hintText: 'ornek@email.com',
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Colors.deepOrangeAccent, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: h * 0.02),

              // Şifre
              const Text(
                'Şifre',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              SizedBox(height: h * 0.008),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Colors.deepOrangeAccent, width: 1.5),
                  ),
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
                  child: const Text(
                    'Şifremi unuttum',
                    style: TextStyle(
                        color: Colors.deepOrangeAccent, fontSize: 13),
                  ),
                ),
              ),

              // Hata mesajı
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: h * 0.02),

              // Giriş butonu
              SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    disabledBackgroundColor:
                        Colors.deepOrangeAccent.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Giriş Yap',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              SizedBox(height: h * 0.02),

              // Ayırıcı
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('veya',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              SizedBox(height: h * 0.02),

              // Google butonu
              SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata,
                      size: 28, color: Colors.red),
                  label: const Text(
                    'Google ile Giriş Yap',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              SizedBox(height: h * 0.015),

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
                    text: const TextSpan(
                      text: 'Hesabın yok mu? ',
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: 'Kayıt ol',
                          style: TextStyle(
                              color: Colors.deepOrangeAccent,
                              fontWeight: FontWeight.w600),
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