import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profil_tamamla_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/profil/providers/profil_provider.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';
  static const register      = '/register';
  static const profilTamamla = '/profil-tamamla';
  static const home          = '/home';
}

// FirebaseAuth.instance YOK — currentUserProvider üzerinden auth durumu izlenir
class _AppStateNotifier extends ChangeNotifier {
  _AppStateNotifier(this._ref) {
    // Auth stream'i currentUserProvider üzerinden dinle
    _sub = _ref.listen(authStateProvider, (prev, next) => notifyListeners());

    // Profil değişince yenile
    _ref.listen(benimKullaniciProfilProvider, (prev, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _sub;

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
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      // currentUserProvider — Firebase direkt erişim yok
      final user = ref.read(currentUserProvider);
      final girisYapildi = user != null;
      final loc = state.matchedLocation;

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
        builder: (ctx, st) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, st) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (ctx, st) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilTamamla,
        builder: (ctx, st) => const ProfilTamamlaScreen(ilkGiris: true),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (ctx, st) => const HomeScreen(),
      ),
    ],
  );
}

String _hedefBelirle(Ref ref, dynamic user) {
  final profilAsync = ref.read(benimKullaniciProfilProvider);
  if (profilAsync.isLoading) return AppRoutes.splash;

  final providerData = user.providerData as List;
  final emailKullanicisi = providerData.any((p) => p.providerId == 'password');
  final googleKullanicisi = providerData.any((p) => p.providerId == 'google.com');
  final telefonKullanicisi = providerData.any((p) => p.providerId == 'phone');

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
