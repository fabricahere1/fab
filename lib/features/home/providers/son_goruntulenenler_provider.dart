// lib/features/home/providers/son_goruntulenenler_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../data/son_goruntulenenler_repository.dart';

part 'son_goruntulenenler_provider.g.dart';

@Riverpod(keepAlive: true)
class SonGoruntulenenler extends _$SonGoruntulenenler {
  static const _maxAdet = 10;

  SonGoruntulenenlerRepository get _repo =>
      ref.read(sonGoruntulenenlerRepositoryProvider);

  @override
  List<IlanModel> build() {
    _yukle();
    return [];
  }

  Future<void> _yukle() async {
    final liste = await _repo.yukle();
    state = liste;
  }

  void kaydet(IlanModel ilan) {
    final guncellenmis = [
      ilan,
      ...state.where((i) => i.id != ilan.id),
    ].take(_maxAdet).toList();
    state = guncellenmis;
    _repo.kaydet(guncellenmis);
  }

  void temizle() {
    state = [];
    _repo.kaydet([]);
  }
}

// Kolaylık provider'ı — tek satırla erişmek için
// ref.watch(sonGoruntulenenlerListesiProvider)
@riverpod
List<IlanModel> sonGoruntulenenlerListesi(Ref ref) {
  return ref.watch(sonGoruntulenenlerProvider);
}
