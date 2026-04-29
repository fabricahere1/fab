import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profil_tamamla_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profil/providers/profil_provider.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';
  static const register      = '/register';
  static const profilTamamla = '/profil-tamamla';
  static const home          = '/home';
}

// ── Auth + profil değişikliklerini dinleyen notifier ─────────────────────────
// Async redirect KALDIRILDI. GoRouter, redirect()'i senkron çalıştırır;
// async kullanmak race condition ve çift yönlendirme sorunlarına yol açar.
// Bunun yerine: benimKullaniciProfilProvider zaten Firestore'u stream ile
// dinliyor. Profil değişince notifier tetikleniyor → GoRouter yeniden
// redirect çalıştırıyor. Firestore'a direkt erişim YOK.

class _AppStateNotifier extends ChangeNotifier {
  _AppStateNotifier(this._ref) {
    // Auth durumu değişince yenile
    _authSub = FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => notifyListeners());

    // Profil değişince yenile (profilTamamlandi alanı dahil)
    _ref.listen(benimKullaniciProfilProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final StreamSubscription<User?> _authSub;

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final notifier = _AppStateNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final user      = FirebaseAuth.instance.currentUser;
      final girisYapildi = user != null;
      final loc       = state.matchedLocation;

      // Giriş yapılmamış → sadece login/register'a izin ver
      if (!girisYapildi) {
        if (loc == AppRoutes.login || loc == AppRoutes.register) return null;
        return AppRoutes.login;
      }

      // Splash veya login/register → nereye gidecek?
      if (loc == AppRoutes.splash ||
          loc == AppRoutes.login  ||
          loc == AppRoutes.register) {
        return _hedefBelirle(ref, user);
      }

      // Onboarding sayfasındayken profil tamamlandıysa → home
      if (loc == AppRoutes.profilTamamla) {
        final profil = ref.read(benimKullaniciProfilProvider).value;
        if (profil?.profilTamamlandi == true) return AppRoutes.home;
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilTamamla,
        builder: (_, _) => const ProfilTamamlaScreen(ilkGiris: true),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );
}

/// Giriş yapılmış kullanıcı splash/login/register'daysa nereye gitmeli?
/// benimKullaniciProfilProvider zaten yüklü olduğundan async'e gerek yok.
String _hedefBelirle(Ref ref, User user) {
  final profilAsync = ref.read(benimKullaniciProfilProvider);

  // Profil henüz yüklenmemişse splash'te bekle
  if (profilAsync.isLoading) return AppRoutes.splash;

  // Email ile kayıt olan kullanıcılar onboarding'e gitmez
  final emailKullanicisi = user.providerData
      .any((p) => p.providerId == 'password');
  final googleKullanicisi = user.providerData
      .any((p) => p.providerId == 'google.com');
  final telefonKullanicisi = user.providerData
      .any((p) => p.providerId == 'phone');

  if (emailKullanicisi && !googleKullanicisi && !telefonKullanicisi) {
    return AppRoutes.home;
  }

  // Google / telefon kullanıcısı → profilTamamlandi kontrolü
  final tamamlandi = profilAsync.value?.profilTamamlandi ?? false;
  return tamamlandi ? AppRoutes.home : AppRoutes.profilTamamla;
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
