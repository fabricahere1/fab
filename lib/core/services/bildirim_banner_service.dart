// lib/core/services/bildirim_banner_service.dart
//
// "anlasildi" ve "sistem" (işlem durumu) tipindeki bildirimleri dinler,
// karşı tarafın ekranında banner gösterir.
//
// Eskiden Firebase Auth'un authStateChanges()'ini dinleyip doğrudan
// Firestore'daki bildirimler koleksiyonunu sorguluyordu — Google/e-posta
// girişi artık Firebase Auth'u hiç tetiklemediği için (AWS migrasyonu)
// bu dinleyici asla gerçek bir kullanıcı görmüyordu, banner hiç
// gösterilmiyordu. Artık AWS backend'ini 20sn'de bir polling ile
// yenileyen bildirimlerProvider'ı dinliyor — önceki listede olmayıp
// yeni listede beliren, ve ilk yükleme OLMAYAN bildirimler banner olarak
// gösteriliyor (gerçek zamanlı değil, en fazla 20sn gecikmeli).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'banner_service.dart';
import '../../features/bildirimler/domain/bildirim_model.dart';
import '../../features/bildirimler/providers/bildirim_provider.dart';

class BildirimBannerService {
  BildirimBannerService._();
  static final instance = BildirimBannerService._();

  ProviderSubscription<AsyncValue<List<BildirimModel>>>? _sub;
  Set<String> _bilinenIdler = {};
  bool _ilkSnapshot = true;

  static const _bannerGosterilecekTipler = {
    BildirimTip.anlasildi,
    BildirimTip.sistem,
  };

  void init(WidgetRef ref) {
    _ilkSnapshot = true;
    _bilinenIdler = {};
    _sub = ref.listenManual<AsyncValue<List<BildirimModel>>>(
      bildirimlerProvider,
      (previous, next) {
        final liste = next.value;
        if (liste == null) return;

        // İlk snapshot — uygulama açılırken zaten var olan eski
        // bildirimler. Bunlar için banner gösterme, sadece baseline
        // olarak kabul et.
        if (_ilkSnapshot) {
          _ilkSnapshot = false;
          _bilinenIdler = liste.map((b) => b.id).toSet();
          return;
        }

        for (final b in liste) {
          if (_bilinenIdler.contains(b.id)) continue;
          if (_bannerGosterilecekTipler.contains(b.tip) && b.icerik.isNotEmpty) {
            BannerService.instance.goster(baslik: b.baslik, icerik: b.icerik, tip: 'islem');
          }
        }
        _bilinenIdler = liste.map((b) => b.id).toSet();
      },
    );
  }

  void dispose() {
    _sub?.close();
  }
}
