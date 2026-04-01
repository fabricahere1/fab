import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
 
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profil_tamamla_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/presentation/home_screen.dart';
 
part 'app_router.g.dart';
 
abstract class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';
  static const register      = '/register';
  static const profilTamamla = '/profil-tamamla';
  static const home          = '/home';
}
 
@riverpod
GoRouter router(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
 
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (authAsync.isLoading) return null;
 
      final user = authAsync.value;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
 
      if (loc == AppRoutes.splash) {
        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      }
 
      if (!isLoggedIn &&
          loc != AppRoutes.login &&
          loc != AppRoutes.register) {
        return AppRoutes.login;
      }
 
      if (isLoggedIn &&
          (loc == AppRoutes.login || loc == AppRoutes.register)) {
        return AppRoutes.home;
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