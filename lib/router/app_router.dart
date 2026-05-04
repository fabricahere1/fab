import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profil_tamamla_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/ilanlar/presentation/ilan_detay_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/profil/providers/profil_provider.dart';

part 'app_router.g.dart';

// ── Global navigator key — in-app banner için ─────────────
final navigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';
  static const register      = '/register';
  static const profilTamamla = '/profil-tamamla';
  static const home          = '/home';
  static const ilanDetay     = '/ilan/:ilanId';

  static String ilanDetayPath(String ilanId) => '/ilan/$ilanId';
}

class _AppStateNotifier extends ChangeNotifier {
  _AppStateNotifier(this._ref) {
    _sub = _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(benimKullaniciProfilProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final notifier = _AppStateNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final girisYapildi = user != null;
      final loc = state.matchedLocation;

      if (loc.startsWith('/ilan/')) {
        if (!girisYapildi) {
          return '${AppRoutes.login}?redirect=${state.uri}';
        }
        return null;
      }

      if (!girisYapildi) {
        if (loc == AppRoutes.login || loc == AppRoutes.register) return null;
        return AppRoutes.login;
      }

      if (loc == AppRoutes.splash ||
          loc == AppRoutes.login  ||
          loc == AppRoutes.register) {
        return _hedefBelirle(ref, user);
      }

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
      GoRoute(
        path: AppRoutes.ilanDetay,
        builder: (_, state) {
          final ilanId = state.pathParameters['ilanId']!;
          return IlanDetayScreen(ilanId: ilanId);
        },
      ),
    ],
  );
}

String _hedefBelirle(Ref ref, dynamic user) {
  final profilAsync = ref.read(benimKullaniciProfilProvider);
  if (profilAsync.isLoading) return AppRoutes.splash;

  final providerData = user.providerData as List;
  final emailKullanicisi =
      providerData.any((p) => p.providerId == 'password');
  final googleKullanicisi =
      providerData.any((p) => p.providerId == 'google.com');
  final telefonKullanicisi =
      providerData.any((p) => p.providerId == 'phone');

  if (emailKullanicisi && !googleKullanicisi && !telefonKullanicisi) {
    return AppRoutes.home;
  }

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