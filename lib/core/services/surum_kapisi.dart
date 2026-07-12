// lib/core/services/surum_kapisi.dart
//
// Minimum sürüm kapısı — eski build'lerin güncel backend'le konuşmasını
// engeller. Bir güvenlik kapısı DEĞİL, hijyen kapısıdır: her hata/timeout/
// doküman-yok durumunda FAIL-OPEN davranır (kullanıcıyı kilitlemez).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/constants/app_constants.dart';
import '../firebase/app_firestore.dart';

part 'surum_kapisi.g.dart';

@Riverpod(keepAlive: true)
Future<SurumDurumu> surumDurumu(Ref ref) => SurumKapisi.kontrolEt();

class SurumDurumu {
  final bool uygun;
  final String? link;

  const SurumDurumu({required this.uygun, this.link});

  static const uygunSonuc = SurumDurumu(uygun: true);

  factory SurumDurumu.guncellemeGerekli(String? link) =>
      SurumDurumu(uygun: false, link: link);
}

class SurumKapisi {
  SurumKapisi._();

  static Future<SurumDurumu> kontrolEt() async {
    try {
      final paketBilgisi = await PackageInfo.fromPlatform();
      final cihazBuild = int.tryParse(paketBilgisi.buildNumber);
      if (cihazBuild == null) return SurumDurumu.uygunSonuc;

      final doc = await AppFirestore.instance
          .collection(Collections.ayarlar)
          .doc('uygulama')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) return SurumDurumu.uygunSonuc;

      final minSurumKodu = doc.data()?['minSurumKodu'] as int?;
      if (minSurumKodu == null) return SurumDurumu.uygunSonuc;

      if (cihazBuild < minSurumKodu) {
        final link = doc.data()?['guncellemeLinki'] as String?;
        return SurumDurumu.guncellemeGerekli(
          (link != null && link.isNotEmpty) ? link : null,
        );
      }

      return SurumDurumu.uygunSonuc;
    } catch (_) {
      return SurumDurumu.uygunSonuc;
    }
  }
}
