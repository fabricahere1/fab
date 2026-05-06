import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/banner_service.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/mesajlar/domain/islem_durumu.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  

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

class IsteApp extends ConsumerStatefulWidget {
  const IsteApp({super.key});

  @override
  ConsumerState<IsteApp> createState() => _IsteAppState();
}

class _IsteAppState extends ConsumerState<IsteApp> {
  final Map<String, StreamSubscription> _islemListeners = {};
  final Map<String, Map<String, dynamic>> _oncekiDurumlar = {};
  StreamSubscription? _sohbetlerSub;

  @override
  void initState() {
    super.initState();
    FcmService.instance.init(onBildirimAc: _bildirimdenAc);
    _islemDurumuDinlemeyiBaslat();
  }

  @override
  void dispose() {
    FcmService.instance.dispose();
    _sohbetlerSub?.cancel();
    for (final sub in _islemListeners.values) {
      sub.cancel();
    }
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

  void _islemDurumuDinlemeyiBaslat() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _sohbetlerSub?.cancel();
      for (final sub in _islemListeners.values) {
        sub.cancel();
      }
      _islemListeners.clear();
      _oncekiDurumlar.clear();

      if (user == null) return;

      _sohbetlerSub = FirebaseFirestore.instance
          .collection('sohbetler')
          .where('kullanicilar', arrayContains: user.uid)
          .snapshots()
          .listen((snap) {
        for (final doc in snap.docs) {
          final sohbetId = doc.id;
          if (_islemListeners.containsKey(sohbetId)) continue;

          final sub = FirebaseFirestore.instance
              .collection('sohbetler')
              .doc(sohbetId)
              .snapshots()
              .listen((sohbetDoc) {
            if (!sohbetDoc.exists) return;
            final d = sohbetDoc.data() as Map<String, dynamic>;
            final islemDurumlari = Map<String, dynamic>.from(
                d['islemDurumlari'] as Map? ?? {});
            final onceki = _oncekiDurumlar[sohbetId] ?? {};

            for (final durum in IslemDurumu.values) {
              final key = durum.firestoreKey;
              final yeniDeger = islemDurumlari[key] == true;
              final eskiDeger = onceki[key] == true;

              if (yeniDeger && !eskiDeger) {
                final kullanicilar =
                    List<String>.from(d['kullanicilar'] ?? []);
                final karsiUid = kullanicilar
                    .firstWhere((id) => id != user.uid, orElse: () => '');

                if (karsiUid.isNotEmpty) {
                  final ilanBaslik = d['ilanBaslik'] as String? ?? 'İlan';

                  FirebaseFirestore.instance
                      .collection('kullanicilar')
                      .doc(karsiUid)
                      .get()
                      .then((karsiDoc) {
                    if (!karsiDoc.exists) return;
                    final karsiAd =
                        (karsiDoc.data()?['adSoyad'] as String?) ??
                            'Karşı taraf';

                    BannerService.instance.goster(
                      baslik: karsiAd,
                      icerik: '"$ilanBaslik" ilanınızı '
                          '${durum.gecmisDonusu}',
                      tip: 'islem',
                    );
                  });
                }
              }
            }

            _oncekiDurumlar[sohbetId] =
                Map<String, dynamic>.from(islemDurumlari);
          });

          _islemListeners[sohbetId] = sub;
        }
      });
    });
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