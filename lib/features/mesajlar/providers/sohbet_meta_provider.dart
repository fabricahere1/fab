// lib/features/mesajlar/providers/sohbet_meta_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'mesaj_provider.dart';
import '../../ilanlar/providers/ilan_provider.dart';

part 'sohbet_meta_provider.g.dart';

class SohbetMeta {
  final String ilanBaslik;
  final String ilanResimUrl;
  final String ilanSahibiId;
  final String ilanTip;

  const SohbetMeta({
    this.ilanBaslik = '',
    this.ilanResimUrl = '',
    this.ilanSahibiId = '',
    this.ilanTip = 'istek',
  });
}

@riverpod
Future<SohbetMeta> sohbetMeta(Ref ref, {required String sohbetId, required String ilanId}) async {
  // sohbetDurumuStream (mesaj_repository.dart:423-429) doküman yoksa boş Map
  // döner (null DEĞİL, dönüş tipi zaten Stream<Map<String,dynamic>> non-nullable)
  // — bu yüzden null-check değil, doğrudan alan boşluğu kontrol edilir.
  final d = await ref.watch(sohbetDokumanProvider(sohbetId).future);
  final baslik = (d['ilanBaslik'] as String?) ?? '';
  if (baslik.isNotEmpty) {
    return SohbetMeta(
      ilanBaslik: baslik,
      ilanResimUrl: (d['ilanResimUrl'] as String?) ?? '',
      ilanSahibiId: (d['ilanSahibiId'] as String?) ?? '',
      ilanTip: (d['ilanTip'] as String?) ?? 'istek',
    );
  }

  // Sohbet yok ya da ilanBaslik boş (ilk temas / eski-kirli doküman) — ilana düş.
  if (ilanId.isEmpty) return const SohbetMeta();
  final ilan = await ref.watch(ilanByIdProvider(ilanId).future);
  if (ilan == null) return const SohbetMeta();
  return SohbetMeta(
    ilanBaslik: ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
    ilanResimUrl: ilan.resimThumbUrl.isNotEmpty ? ilan.resimThumbUrl : ilan.resimUrl,
    ilanSahibiId: ilan.kullaniciId,
    ilanTip: ilan.tip,
  );
}
