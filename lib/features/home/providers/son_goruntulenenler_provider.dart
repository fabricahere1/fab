// lib/features/home/providers/son_goruntulenenler_provider.dart
//
// Daha önce global mutable liste olan _sonGorutulenler buraya taşındı.
// Riverpod ile yönetildiği için:
//   • Hot reload'da kaybolmaz (keepAlive: true)
//   • Test edilebilir
//   • ref.watch ile reaktif

import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ilanlar/domain/ilan_model.dart';

part 'son_goruntulenenler_provider.g.dart';

@Riverpod(keepAlive: true)
class SonGoruntulenenler extends _$SonGoruntulenenler {
  static const _maxAdet = 10;
  static const _prefsKey = 'son_goruntulenenler';

  @override
  List<IlanModel> build() {
    _yukle();
    return [];
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return;
    try {
      final liste = (jsonDecode(jsonStr) as List).map((e) {
        final m = e as Map<String, dynamic>;
        return IlanModel(
          id:          m['id']          as String? ?? '',
          tip:         m['tip']         as String? ?? '',
          nereden:     m['nereden']     as String? ?? '',
          nereye:      m['nereye']      as String? ?? '',
          urun:        m['urun']        as String? ?? '',
          ucret:       m['ucret']       as String? ?? '',
          kategori:    m['kategori']    as String? ?? '',
          anaKategori: m['anaKategori'] as String? ?? '',
          kullaniciId: m['kullaniciId'] as String? ?? '',
          kullaniciAd: m['kullaniciAd'] as String? ?? '',
          resimUrl:    m['resimUrl']    as String? ?? '',
          resimUrller: List<String>.from(m['resimUrller'] ?? []),
          favoriSayisi: (m['favoriSayisi'] as num?)?.toInt() ?? 0,
          tarih:       m['tarih'] != null ? DateTime.tryParse(m['tarih']) : null,
          olusturmaTarihi: m['olusturmaTarihi'] != null ? DateTime.tryParse(m['olusturmaTarihi']) : null,
        );
      }).toList();
      state = liste;
    } catch (_) {}
  }

  Future<void> _kaydet(List<IlanModel> liste) async {
    final prefs = await SharedPreferences.getInstance();
    final data = liste.map((i) => {
      'id':          i.id,
      'tip':         i.tip,
      'nereden':     i.nereden,
      'nereye':      i.nereye,
      'urun':        i.urun,
      'ucret':       i.ucret,
      'kategori':    i.kategori,
      'anaKategori': i.anaKategori,
      'kullaniciId': i.kullaniciId,
      'kullaniciAd': i.kullaniciAd,
      'resimUrl':    i.resimUrl,
      'resimUrller': i.resimUrller,
      'favoriSayisi': i.favoriSayisi,
      'tarih':       i.tarih?.toIso8601String(),
      'olusturmaTarihi': i.olusturmaTarihi?.toIso8601String(),
    }).toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  void kaydet(IlanModel ilan) {
    final guncellenmis = [
      ilan,
      ...state.where((i) => i.id != ilan.id),
    ].take(_maxAdet).toList();
    state = guncellenmis;
    _kaydet(guncellenmis);
  }

  void temizle() {
    state = [];
    _kaydet([]);
  }
}

// Kolaylık provider'ı — tek satırla erişmek için
// ref.watch(sonGoruntulenenlerListesiProvider)
@riverpod
List<IlanModel> sonGoruntulenenlerListesi(Ref ref) {
  return ref.watch(sonGoruntulenenlerProvider);
}
