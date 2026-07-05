import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/badge_service.dart';
import 'core/services/bildirim_banner_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/bildirim_yonlendirici.dart';
import 'features/bildirimler/providers/bekleyen_bildirim_provider.dart';
import 'shared/widgets/baglanti_banner.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
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

  // Crashlytics — release modda tüm hataları yakala
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Edge-to-edge — nav bar şeffaf, uygulama altına kadar uzar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
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
    FcmService.instance.init(
      onBildirimAc: _bildirimdenAc,
      onIlkAcilis: (message) =>
          ref.read(bekleyenBildirimProvider.notifier).set(message),
    );
    BildirimBannerService.instance.init();
    BadgeService.instance.init();
  }

  @override
  void dispose() {
    FcmService.instance.dispose();
    BildirimBannerService.instance.dispose();
    BadgeService.instance.dispose();
    super.dispose();
  }

  void _bildirimdenAc(RemoteMessage message) {
    _bildirimNavigation(message);
  }

  void _bildirimNavigation(RemoteMessage message) =>
      bildirimNavigasyonuIsle(ref, message);

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
          child: BaglantiSarmalayici(child: child!),
        );
      },
    );
  }
}