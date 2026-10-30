// lib/core/services/badge_service.dart
//
// Okunmamış bildirim sayısını uygulama ikonuna badge olarak yazar.
// Eskiden Firebase Auth'un authStateChanges()'ini dinleyip doğrudan
// Firestore'daki bildirimler koleksiyonunu sorguluyordu — Google/e-posta
// girişi artık Firebase Auth'u hiç tetiklemediği için (AWS migrasyonu)
// bu dinleyici asla gerçek bir kullanıcı görmüyordu, badge hiç
// güncellenmiyordu. Artık AWS backend'ini 20sn'de bir polling ile
// yenileyen okunmamisBildirimSayiProvider'ı dinliyor.

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/bildirimler/providers/bildirim_provider.dart';

class BadgeService {
  BadgeService._();
  static final instance = BadgeService._();

  ProviderSubscription<AsyncValue<int>>? _sub;

  void init(WidgetRef ref) {
    _sub = ref.listenManual<AsyncValue<int>>(
      okunmamisBildirimSayiProvider,
      (previous, next) => AppBadgePlus.updateBadge(next.value ?? 0),
      fireImmediately: true,
    );
  }

  void dispose() {
    _sub?.close();
    AppBadgePlus.updateBadge(0);
  }
}
