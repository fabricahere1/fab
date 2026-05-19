import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profil_tamamla_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/ilanlar/domain/ilan_model.dart';
import '../features/ilanlar/presentation/ilan_detay_screen.dart';
import '../features/ilanlar/presentation/gelenler_screen.dart';
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
  static const gelenler      = '/gelenler';

  static String ilanDetayPath(String ilanId) => '/ilan/$ilanId';
  static String gelenlerPath({List<String> kategoriYolu = const []}) {
    if (kategoriYolu.isEmpty) return gelenler;
    return '$gelenler?kategori=${kategoriYolu.join(',')}';
  }
}

class _AppStateNotifier extends ChangeNotifier {
  _AppStateNotifier(this._ref) {
    _authSub   = _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _profilSub = _ref.listen(benimKullaniciProfilProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription _authSub;
  late final ProviderSubscription _profilSub;

  @override
  void dispose() {
    _authSub.close();
    _profilSub.close();
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
          final ilan = state.extra as IlanModel?;
          return IlanDetayScreen(ilanId: ilanId, ilan: ilan);
        },
      ),
      GoRoute(
        path: AppRoutes.gelenler,
        builder: (_, state) {
          final kategoriParam = state.uri.queryParameters['kategori'] ?? '';
          final kategoriYolu = kategoriParam.isNotEmpty
              ? kategoriParam.split(',')
              : <String>[];
          return GelenlerDetayScreen(kategoriYolu: kategoriYolu);
        },
      ),
    ],
  );
}

String _hedefBelirle(Ref ref, User user) {
  final profilAsync = ref.read(benimKullaniciProfilProvider);
  if (profilAsync.isLoading) return AppRoutes.splash;

  final emailKullanicisi =
      user.providerData.any((p) => p.providerId == 'password');
  final googleKullanicisi =
      user.providerData.any((p) => p.providerId == 'google.com');
  final telefonKullanicisi =
      user.providerData.any((p) => p.providerId == 'phone');

  // Sadece email/password kullananlar profil tamamlama adımını atlar
  if (emailKullanicisi && !googleKullanicisi && !telefonKullanicisi) {
    return AppRoutes.home;
  }

  final tamamlandi = profilAsync.value?.profilTamamlandi ?? false;
  return tamamlandi ? AppRoutes.home : AppRoutes.profilTamamla;
}

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _hintOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOutBack)),
    );
    _hintOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Image.asset(
                    'assets/images/logo_seffaf.png',
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _hintOpacity.value,
                child: Text(
                  'Yeter ki Sen İste',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}