// lib/features/home/providers/son_goruntulenenler_provider.dart
//
// Daha önce global mutable liste olan _sonGorutulenler buraya taşındı.
// Riverpod ile yönetildiği için:
//   • Hot reload'da kaybolmaz (keepAlive: true)
//   • Test edilebilir
//   • ref.watch ile reaktif

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../ilanlar/domain/ilan_model.dart';

part 'son_goruntulenenler_provider.g.dart';

@Riverpod(keepAlive: true)
class SonGoruntulenenler extends _$SonGoruntulenenler {
  static const _maxAdet = 10;

  @override
  List<IlanModel> build() => [];

  void kaydet(IlanModel ilan) {
    // Varsa önce çıkar, sonra başa ekle (en son görüntülenen en üstte)
    final guncellenmis = [
      ilan,
      ...state.where((i) => i.id != ilan.id),
    ];
    state = guncellenmis.take(_maxAdet).toList();
  }

  void temizle() => state = [];
}

// Kolaylık provider'ı — tek satırla erişmek için
// ref.watch(sonGoruntulenenlerListesiProvider)
@riverpod
List<IlanModel> sonGoruntulenenlerListesi(Ref ref) {
  return ref.watch(sonGoruntulenenlerProvider);
}
