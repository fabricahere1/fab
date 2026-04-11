import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profil_tamamla_screen.dart';
import '../features/home/presentation/home_screen.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';
  static const register      = '/register';
  static const profilTamamla = '/profil-tamamla';
  static const home          = '/home';
}

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _sub = FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

Future<bool> _profilTamamlandiMi(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .get();
    return doc.data()?['profilTamamlandi'] as bool? ?? false;
  } catch (_) {
    return false;
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final notifier = _AuthChangeNotifier();
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;

      // Splash — her zaman kontrol et
      if (loc == AppRoutes.splash) {
        if (!isLoggedIn) return AppRoutes.login;
        final tamamlandi = await _profilTamamlandiMi(user.uid);
        return tamamlandi ? AppRoutes.home : AppRoutes.profilTamamla;
      }

      // Giriş yapılmamış — login/register dışında her yerden login'e gönder
      if (!isLoggedIn &&
          loc != AppRoutes.login &&
          loc != AppRoutes.register) {
        return AppRoutes.login;
      }

      // ✅ Giriş yapılmış ama login/register sayfasında — profil kontrolü yap
      if (isLoggedIn &&
          (loc == AppRoutes.login || loc == AppRoutes.register)) {
        final tamamlandi = await _profilTamamlandiMi(user.uid);
        return tamamlandi ? AppRoutes.home : AppRoutes.profilTamamla;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilTamamla,
        builder: (_, __) => const ProfilTamamlaScreen(ilkGiris: true),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}