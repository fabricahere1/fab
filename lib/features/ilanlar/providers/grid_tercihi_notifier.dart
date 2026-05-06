// lib/features/ilanlar/providers/grid_tercihi_notifier.dart
//
// Değişiklikler:
//   • GoruntulemeModeli.liste → GoruntulemeModeli.swipe
//   • Döngü: iki → uc → swipe → iki
//   • SharedPreferences kaydı aynen korundu

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'grid_tercihi_notifier.g.dart';

enum GoruntulemeModeli { iki, uc, swipe }

extension GoruntulemeModeliX on GoruntulemeModeli {
  int get kolonSayisi {
    switch (this) {
      case GoruntulemeModeli.iki:   return 2;
      case GoruntulemeModeli.uc:    return 3;
      case GoruntulemeModeli.swipe: return 1; // swipe'ta kullanılmaz
    }
  }

  GoruntulemeModeli get sonraki {
    switch (this) {
      case GoruntulemeModeli.iki:   return GoruntulemeModeli.uc;
      case GoruntulemeModeli.uc:    return GoruntulemeModeli.swipe;
      case GoruntulemeModeli.swipe: return GoruntulemeModeli.iki;
    }
  }

  IconData get ikon {
    switch (this) {
      case GoruntulemeModeli.iki:   return Icons.grid_view_rounded;
      case GoruntulemeModeli.uc:    return Icons.view_module_rounded;
      case GoruntulemeModeli.swipe: return Icons.swipe_rounded;
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

  Future<void> modSec(GoruntulemeModeli mod) async {
    state = mod;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mod.index);
  }
}