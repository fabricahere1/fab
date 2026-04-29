// lib/features/ilanlar/providers/grid_tercihi_notifier.dart
//
// Kullanıcının grid kolon tercihini (2 veya 3) SharedPreferences ile saklar.
// Uygulama kapatılıp açıldığında tercih korunur.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'grid_tercihi_notifier.g.dart';

@Riverpod(keepAlive: true)
class GridTercihi extends _$GridTercihi {
  static const _key = 'grid_kolonu';

  @override
  int build() {
    _init();
    return 2; // varsayılan 2 kolon
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final deger = prefs.getInt(_key);
    if (deger != null && state != deger) {
      state = deger;
    }
  }

  Future<void> degistir(int kolon) async {
    state = kolon;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, kolon);
  }
}
