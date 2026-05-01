// lib/features/ilanlar/providers/grid_tercihi_notifier.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'grid_tercihi_notifier.g.dart';

enum GoruntulemeModeli { iki, uc, liste }

extension GoruntulemeModeliX on GoruntulemeModeli {
  int get kolonSayisi {
    switch (this) {
      case GoruntulemeModeli.iki:   return 2;
      case GoruntulemeModeli.uc:    return 3;
      case GoruntulemeModeli.liste: return 1;
    }
  }

  GoruntulemeModeli get sonraki {
    switch (this) {
      case GoruntulemeModeli.iki:   return GoruntulemeModeli.uc;
      case GoruntulemeModeli.uc:    return GoruntulemeModeli.liste;
      case GoruntulemeModeli.liste: return GoruntulemeModeli.iki;
    }
  }
}

@Riverpod(keepAlive: true)
class GridTercihi extends _$GridTercihi {
  static const _key = 'goruntuleme_modeli';

  @override
  GoruntulemeModeli build() {
    _init();
    return GoruntulemeModeli.iki;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final deger = prefs.getInt(_key);
    if (deger != null && deger < GoruntulemeModeli.values.length) {
      final mod = GoruntulemeModeli.values[deger];
      if (state != mod) state = mod;
    }
  }

  Future<void> sonrakiModa() async {
    final yeni = state.sonraki;
    state = yeni;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, yeni.index);
  }
}
