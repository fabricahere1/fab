import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/mesajlar/presentation/sohbet_screen.dart';
import '../../router/app_router.dart';

/// Tüm bildirim yönlendirme mantığının tek kaynağı.
/// Hem sıcak yol (arka plan, _bildirimNavigation) hem soğuk yol
/// (kill → onIlkAcilis → bekleyenBildirimProvider) buraya delege eder.
void bildirimNavigasyonuIsle(WidgetRef ref, RemoteMessage message) {
  final data     = message.data;
  final tip      = data['tip']      as String?;
  final ilanId   = data['ilanId']   as String?;
  final sohbetId = data['sohbetId'] as String?;

  final panelBildirimi = data['islem'] == 'true';

  if (tip == 'degerlendirme') {
    ref.read(routerProvider).go(AppRoutes.home);
    return;
  }

  // Panel bildirimleri ilanId içerse bile ilan detayına gitmemeli
  if (!panelBildirimi && ilanId != null && ilanId.isNotEmpty && tip != 'mesaj') {
    ref.read(routerProvider).push(AppRoutes.ilanDetayPath(ilanId));
    return;
  }

  if (sohbetId != null && sohbetId.isNotEmpty) {
    final karsiKullaniciId = data['karsiKullaniciId'] as String? ?? '';
    final karsiKullaniciAd = data['karsiKullaniciAd'] as String? ?? '';
    final bildirimIlanId   = data['ilanId']           as String? ?? '';
    final ilanSahibiId     = data['ilanSahibiId']     as String? ?? '';
    final ilanBaslik       = data['ilanBaslik']        as String? ?? '';
    final ilanResimUrl     = data['ilanResimUrl']      as String? ?? '';
    final mesajId          = data['mesajId']           as String? ?? '';
    final mesajMetin       = data['mesajMetin']        as String? ?? '';
    final mesajZamanStr    = data['mesajZaman']        as String? ?? '';
    final bildirimMesaji   = mesajId.isNotEmpty && mesajMetin.isNotEmpty
        ? (id: mesajId, metin: mesajMetin, zaman: DateTime.tryParse(mesajZamanStr))
        : null;

    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SohbetScreen(
        sohbetId:         sohbetId,
        karsiKullaniciId: karsiKullaniciId,
        karsiKullaniciAd: karsiKullaniciAd,
        ilanId:           bildirimIlanId,
        ilanBaslik:       ilanBaslik,
        ilanResimUrl:     ilanResimUrl,
        ilanSahibiId:     ilanSahibiId,
        autoOpenPanel:    panelBildirimi,
        bildirimMesaji:   bildirimMesaji,
      ),
    ));
  }
}
