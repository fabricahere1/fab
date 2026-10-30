import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'screens/bildirim_gonder_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/degerlendirme_moderasyon_screen.dart';
import 'screens/ilan_detay_screen.dart';
import 'screens/ilan_listesi_screen.dart';
import 'screens/kullanici_detay_screen.dart';
import 'screens/kullanici_listesi_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/admin_shell.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter adminRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final girisEkrani = state.matchedLocation == '/login';
      // adminAuthStateProvider (Stream<User?>) yerine doğrudan
      // FirebaseAuth.instance.currentUser okunuyor — signInWithEmailAndPassword
      // dönüşünce currentUser senkron olarak dolar, ama authStateChanges()
      // stream'inin bunu yayması bir tık gecikebiliyor. redirect stale
      // stream değerini okursa login'i başarılı bir girişten hemen sonra
      // tekrar '/login'e atıyordu.
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return girisEkrani ? null : '/login';

      final sonuc = await user.getIdTokenResult(true);
      final admin = sonuc.claims?['admin'] == true;
      if (!admin) return girisEkrani ? null : '/login';

      if (girisEkrani) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/ilanlar', builder: (context, state) => const IlanListesiScreen()),
          GoRoute(
            path: '/ilanlar/:ilanId',
            builder: (context, state) =>
                IlanDetayScreen(ilanId: state.pathParameters['ilanId']!),
          ),
          GoRoute(
              path: '/kullanicilar',
              builder: (context, state) => const KullaniciListesiScreen()),
          GoRoute(
            path: '/kullanicilar/:uid',
            builder: (context, state) =>
                KullaniciDetayScreen(uid: state.pathParameters['uid']!),
          ),
          GoRoute(
              path: '/degerlendirmeler',
              builder: (context, state) => const DegerlendirmeModerasyonScreen()),
          GoRoute(
              path: '/bildirim',
              builder: (context, state) => const BildirimGonderScreen()),
        ],
      ),
    ],
  );
}
