import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/badge_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/islem_durumu_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore offline persistence — uygulama kapatılıp açılınca cache'den gelir
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await FirebaseAppCheck.instance.activate(
    // ignore: deprecated_member_use
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: IsteApp(),
    ),
  );
}

class IsteApp extends ConsumerStatefulWidget {
  const IsteApp({super.key});

  @override
  ConsumerState<IsteApp> createState() => _IsteAppState();
}

class _IsteAppState extends ConsumerState<IsteApp> {
  @override
  void initState() {
    super.initState();
    FcmService.instance.init(onBildirimAc: _bildirimdenAc);
    IslemDurumuService.instance.init();
    BadgeService.instance.init();
  }

  @override
  void dispose() {
    FcmService.instance.dispose();
    IslemDurumuService.instance.dispose();
    BadgeService.instance.dispose();
    super.dispose();
  }

  void _bildirimdenAc(RemoteMessage message) {
    final router   = ref.read(routerProvider);
    final data     = message.data;
    final tip      = data['tip']      as String?;
    final ilanId   = data['ilanId']   as String?;
    final sohbetId = data['sohbetId'] as String?;

    if (tip == 'degerlendirme') {
      router.go(AppRoutes.home);
      return;
    }
    if (ilanId != null && ilanId.isNotEmpty) {
      router.push(AppRoutes.ilanDetayPath(ilanId));
      return;
    }
    if (sohbetId != null && sohbetId.isNotEmpty) {
      debugPrint('[FCM] sohbet bildirimi: $sohbetId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'İSTE',
      routerConfig: router,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: const Locale('tr'),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}