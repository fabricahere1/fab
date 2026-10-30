// lib/core/services/surum_kapisi.dart
//
// Minimum sürüm kapısı — eski build'lerin güncel backend'le konuşmasını
// engeller. Bir güvenlik kapısı DEĞİL, hijyen kapısıdır: her hata/timeout/
// doküman-yok durumunda FAIL-OPEN davranır (kullanıcıyı kilitlemez).
//
// AWS'ye taşınmadan ÖNCE Firestore'daki ayarlar/uygulama dökümanını
// `Source.server` (cache atlanarak) okuyordu — Firestore artık v3 için
// kapatıldığı için bu döküman hiç yanıt vermiyordu ve her soğuk açılışta
// 5 saniyelik timeout'un TAMAMI bekleniyordu (bkz. app_router.dart'taki
// "sürüm kapısı splash'te bile kontrol edilir" mantığı — bu bekleme
// doğrudan splash süresine ekleniyordu). Backend'de henüz bir sürüm
// kontrolü ucu yok, bu yüzden kapı şimdilik senkron/ağsız olarak hep
// "uygun" dönüyor — fail-open davranışıyla zaten aynı sonuç, sadece
// 5sn'lik bekleme olmadan. Gerçek bir min-sürüm zorlaması gerekirse
// AWS backend'ine küçük bir /v3/surum-durumu ucu eklenip buradan
// çağrılmalı (backlog).
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'surum_kapisi.g.dart';

@Riverpod(keepAlive: true)
Future<SurumDurumu> surumDurumu(Ref ref) async => SurumDurumu.uygunSonuc;

class SurumDurumu {
  final bool uygun;
  final String? link;

  const SurumDurumu({required this.uygun, this.link});

  static const uygunSonuc = SurumDurumu(uygun: true);

  factory SurumDurumu.guncellemeGerekli(String? link) =>
      SurumDurumu(uygun: false, link: link);
}
