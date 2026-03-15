import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profil_tamamla_screen.dart';
 
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
 
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
 
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
 
  runApp(const IsteApp());
}
 
class IsteApp extends StatelessWidget {
  const IsteApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İste',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3C3C3C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
 
// ── Splash Screen ──────────────────────────────────────────
 
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
 
  @override
  void initState() {
    super.initState();
 
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
 
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
 
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
 
    _animController.forward();
 
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
 
      final prefs = await SharedPreferences.getInstance();
      final onboardingTamamlandi =
          prefs.getBool('onboarding_tamamlandi') ?? false;
 
      if (!mounted) return;
 
      await _animController.reverse();
 
      if (!mounted) return;
 
      if (!onboardingTamamlandi) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const OnboardingScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        return;
      }
 
      final user = FirebaseAuth.instance.currentUser;
 
      debugPrint('=== SPLASH DEBUG ===');
      debugPrint('user: $user');
      debugPrint('user uid: ${user?.uid}');
      debugPrint('user email: ${user?.email}');
 
      if (user == null) {
        debugPrint('user null → LoginScreen');
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        return;
      }
 
      await _fcmTokenKaydet(user.uid);
 
      final doc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .get();
 
      debugPrint('doc exists: ${doc.exists}');
      debugPrint('doc data: ${doc.data()}');
 
      final profilTamamlandi = doc.data()?['profilTamamlandi'] == true;
      debugPrint('profilTamamlandi: $profilTamamlandi');
      debugPrint('=== SPLASH DEBUG END ===');
 
      if (!mounted) return;
 
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => profilTamamlandi
              ? const HomeScreen()
              : const ProfilTamamlaScreen(ilkGiris: true),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }
 
  Future<void> _fcmTokenKaydet(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
 
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
 
      final token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .update({'fcmToken': token});
      }
 
      messaging.onTokenRefresh.listen((yeniToken) {
        FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .update({'fcmToken': yeniToken});
      });
    } catch (_) {
      // Token alınamazsa sessizce geç
    }
  }
 
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
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
        ),
      ),
    );
  }
}