import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'shared/constants/app_colors.dart';

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
  OverlayEntry? _mevcutBanner;

  @override
  void initState() {
    super.initState();
    _fcmKurulum();
  }

  Future<void> _fcmKurulum() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    // Uygulama açıkken gelen bildirim — in-app banner göster
    FirebaseMessaging.onMessage.listen((message) {
      _bannerGoster(message);
    });

    // Uygulama arka plandayken bildirime tıklandı
    FirebaseMessaging.onMessageOpenedApp.listen(_bildirimdenAc);

    // Uygulama tamamen kapalıyken bildirime tıklanıp açıldı
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bildirimdenAc(initialMessage);
      });
    }
  }

  void _bannerGoster(RemoteMessage message) {
    final notification = message.notification;
    final baslik = notification?.title ?? 'Bildirim';
    final icerik = notification?.body ?? '';

    // Önceki banner varsa kaldır
    _mevcutBanner?.remove();
    _mevcutBanner = null;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _mevcutBanner = OverlayEntry(
      builder: (_) => _InAppBanner(
        baslik: baslik,
        icerik: icerik,
        tip: message.data['tip'] as String? ?? '',
        onTap: () {
          _mevcutBanner?.remove();
          _mevcutBanner = null;
          _bildirimdenAc(message);
        },
        onKapat: () {
          _mevcutBanner?.remove();
          _mevcutBanner = null;
        },
      ),
    );

    overlay.insert(_mevcutBanner!);

    // 4 saniye sonra otomatik kapat
    Future.delayed(const Duration(seconds: 4), () {
      _mevcutBanner?.remove();
      _mevcutBanner = null;
    });
  }

  void _bildirimdenAc(RemoteMessage message) {
    final router = ref.read(routerProvider);
    final data   = message.data;

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
      // router.push(AppRoutes.sohbetPath(sohbetId));
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

// ── In-App Banner ─────────────────────────────────────────────────────────────

class _InAppBanner extends StatefulWidget {
  final String baslik;
  final String icerik;
  final String tip;
  final VoidCallback onTap;
  final VoidCallback onKapat;

  const _InAppBanner({
    required this.baslik,
    required this.icerik,
    required this.tip,
    required this.onTap,
    required this.onKapat,
  });

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData get _ikon {
    switch (widget.tip) {
      case 'mesaj':         return Icons.chat_bubble_outline_rounded;
      case 'degerlendirme': return Icons.star_outline_rounded;
      default:              return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;

    return Positioned(
      top: statusH + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_ikon, color: AppColors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.baslik,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.icerik.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.icerik,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onKapat,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}