import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/cupertino.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profil_tamamla_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/ilanlar/domain/ilan_model.dart';
import '../features/ilanlar/presentation/ilan_detay_screen.dart';
import '../features/ilanlar/presentation/ilan_form_screen.dart';
import '../shared/constants/app_constants.dart' show IlanTip;
import '../features/ilanlar/presentation/gelenler_screen.dart';
import '../features/auth/data/auth_repository.dart' show AuthYontemi, authYontemiBelirle;
import '../features/auth/providers/auth_provider.dart';
import '../features/profil/providers/profil_provider.dart';
import '../core/services/surum_kapisi.dart';
import '../shared/widgets/guncelleme_gerekli_screen.dart';
import '../features/profil/presentation/takip_listesi_screen.dart';

part 'app_router.g.dart';

// ── Global navigator key — in-app banner için ─────────────
final navigatorKey = GlobalKey<NavigatorState>();


abstract class AppRoutes {
  static const splash              = '/';
  static const guncellemeGerekli   = '/guncelleme-gerekli';
  static const login               = '/login';
  static const register            = '/register';
  static const profilTamamla       = '/profil-tamamla';
  static const home                = '/home';
  static const ilanDetay           = '/ilan/:ilanId';
  static const gelenler            = '/gelenler';
  static const ilanOlusturIstek    = '/home/ilan-olustur/istek';
  static const ilanOlusturTasiyici = '/home/ilan-olustur/tasiyici';

  static String ilanDetayPath(String ilanId) => '/ilan/$ilanId';
  static String gelenlerPath({List<String> kategoriYolu = const [], String? tip}) {
    final params = <String>[];
    if (kategoriYolu.isNotEmpty) params.add('kategori=${kategoriYolu.join(',')}');
    if (tip != null && tip.isNotEmpty) params.add('tip=$tip');
    if (params.isEmpty) return gelenler;
    return '$gelenler?${params.join('&')}';
  }
}

class _AppStateNotifier extends ChangeNotifier {
  _AppStateNotifier(this._ref) {
    _authSub   = _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _profilSub = _ref.listen(benimKullaniciProfilProvider, (_, _) => notifyListeners());
    _surumSub  = _ref.listen(surumDurumuProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription _authSub;
  late final ProviderSubscription _profilSub;
  late final ProviderSubscription _surumSub;

  @override
  void dispose() {
    _authSub.close();
    _profilSub.close();
    _surumSub.close();
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
      final authAsync = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final returnRoute = state.uri.queryParameters['returnRoute'];

      // Sürüm kapısı — auth durumundan bile önce kontrol edilir, misafir
      // kullanıcı da dahil hiçbir route'a izin verilmez.
      final surumAsync = ref.read(surumDurumuProvider);
      if (surumAsync.isLoading && !surumAsync.hasValue) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }
      final surumUygunMu = surumAsync.value?.uygun ?? true;
      if (!surumUygunMu) {
        return loc == AppRoutes.guncellemeGerekli
            ? null
            : AppRoutes.guncellemeGerekli;
      }
      if (loc == AppRoutes.guncellemeGerekli) {
        return AppRoutes.splash;
      }

      if (authAsync.isLoading && !authAsync.hasValue) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final user = authAsync.value;
      final girisYapildi = user != null;

      if (!girisYapildi) {
        if (loc == AppRoutes.login ||
            loc == AppRoutes.register ||
            loc == AppRoutes.home ||
            loc.startsWith('/ilan/') ||
            loc == AppRoutes.gelenler) { return null; }
        if (loc == AppRoutes.ilanOlusturIstek ||
            loc == AppRoutes.ilanOlusturTasiyici) {
          return '${AppRoutes.login}?returnRoute=${Uri.encodeComponent(loc)}';
        }
        return AppRoutes.home;
      }

      // Giriş yapılmışsa splash/login/register → home veya profil tamamlama
      if (loc == AppRoutes.splash ||
          loc == AppRoutes.login  ||
          loc == AppRoutes.register) {
        return _hedefBelirle(ref, user, returnRoute: returnRoute);
      }

      if (loc == AppRoutes.profilTamamla) {
        final profil = ref.read(benimKullaniciProfilProvider).value;
        if (profil?.profilTamamlandi == true) {
          return returnRoute ?? AppRoutes.home;
        }
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
        path: AppRoutes.guncellemeGerekli,
        builder: (_, _) {
          final link = ref.read(surumDurumuProvider).value?.link;
          return GuncellemeGerekliScreen(guncellemeLinki: link);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilTamamla,
        builder: (_, state) => ProfilTamamlaScreen(
          ilkGiris: true,
          returnRoute: state.uri.queryParameters['returnRoute'],
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'ilan-olustur/istek',
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: IlanFormScreen(
                tip: IlanTip.istek,
                duzenlenecekIlan: state.extra as IlanModel?,
              ),
            ),
          ),
          GoRoute(
            path: 'ilan-olustur/tasiyici',
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: IlanFormScreen(
                tip: IlanTip.tasiyici,
                duzenlenecekIlan: state.extra as IlanModel?,
              ),
            ),
          ),
          GoRoute(
            path: 'takip-listesi/:kullaniciId',
            pageBuilder: (context, state) {
              final kullaniciId = state.pathParameters['kullaniciId']!;
              final tabParam = state.uri.queryParameters['tab'];
              final baslangicTab = tabParam == 'takipEdilenler'
                  ? TakipListeTipi.takipEdilenler
                  : TakipListeTipi.takipcilar;
              return CupertinoPage(
                key: state.pageKey,
                child: TakipListesiScreen(
                  kullaniciId: kullaniciId,
                  baslangicTab: baslangicTab,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ilanDetay,
        pageBuilder: (context, state) {
          final ilanId = state.pathParameters['ilanId']!;
          final ilan = state.extra as IlanModel?;
          return CupertinoPage(
            key: state.pageKey,
            child: IlanDetayScreen(ilanId: ilanId, ilan: ilan),
          );
        },
      ), // GoRoute
      GoRoute(
        path: AppRoutes.gelenler,
        builder: (_, state) {
          final kategoriParam = state.uri.queryParameters['kategori'] ?? '';
          final kategoriYolu = kategoriParam.isNotEmpty
              ? kategoriParam.split(',')
              : <String>[];
          final tip = state.uri.queryParameters['tip'];
          return GelenlerDetayScreen(kategoriYolu: kategoriYolu, tip: tip);
        },
      ),
    ],
  );
}

String? _hedefBelirle(Ref ref, User user, {String? returnRoute}) {
  final profilAsync = ref.read(benimKullaniciProfilProvider);
  if (profilAsync.isLoading) return null;

  if (authYontemiBelirle(user) == AuthYontemi.email) {
    return returnRoute ?? AppRoutes.home;
  }

  final tamamlandi = profilAsync.value?.profilTamamlandi ?? false;
  if (!tamamlandi) {
    if (returnRoute != null) {
      return '${AppRoutes.profilTamamla}?returnRoute=${Uri.encodeComponent(returnRoute)}';
    }
    return AppRoutes.profilTamamla;
  }
  return returnRoute ?? AppRoutes.home;
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
      // Gerçek native splash rengi (android/.../styles.xml: #E53935) ile
      // birebir aynı zemin — Android'in sistem splash ikonu, Flutter'ın ilk
      // karesi çizildikten sonra ÜZERİNE bindirilip çıkış animasyonu yapıyor;
      // altındaki bu zemin uyuşmazsa "siyah ekran" hissi oluşuyordu.
      backgroundColor: const Color(0xFFE53935),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Opacity(
            opacity: _logoOpacity.value,
            child: Transform.scale(
              scale: _logoScale.value,
              // Native splash'taki aynı görsel — pürüzsüz, kesintisiz geçiş.
              child: Image.asset(
                'assets/splash/iste_splash.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}