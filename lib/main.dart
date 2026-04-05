import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
 
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
 
Future<void> _migrateFavoriSayisi() async {
  final firestore = FirebaseFirestore.instance;
  final snap = await firestore.collection('ilanlar').get();
  final batch = firestore.batch();
  for (final doc in snap.docs) {
    if ((doc.data())['favoriSayisi'] == null) {
      batch.update(doc.reference, {'favoriSayisi': 0});
    }
  }
  await batch.commit();
  debugPrint('Migration tamamlandı!');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _migrateFavoriSayisi();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
 
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
 
  runApp(
    const ProviderScope(
      child: IsteApp(),
    ),
  );
}
 
class IsteApp extends ConsumerWidget {
  const IsteApp({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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