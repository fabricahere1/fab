// lib/features/home/data/son_goruntulenenler_repository.dart

import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ilanlar/domain/ilan_model.dart';

part 'son_goruntulenenler_repository.g.dart';

class SonGoruntulenenlerRepository {
  static const _prefsKey = 'son_goruntulenenler';

  Future<List<IlanModel>> yukle() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return [];
    try {
      return (jsonDecode(jsonStr) as List).map((e) {
        final m = e as Map<String, dynamic>;
        return IlanModel(
          id:              m['id']              as String? ?? '',
          tip:             m['tip']             as String? ?? '',
          nereden:         m['nereden']         as String? ?? '',
          nereye:          m['nereye']          as String? ?? '',
          urun:            m['urun']            as String? ?? '',
          ucret:           m['ucret']           as String? ?? '',
          kategori:        m['kategori']        as String? ?? '',
          anaKategori:     m['anaKategori']     as String? ?? '',
          kullaniciId:     m['kullaniciId']     as String? ?? '',
          kullaniciAd:     m['kullaniciAd']     as String? ?? '',
          resimUrl:        m['resimUrl']        as String? ?? '',
          resimUrller:     List<String>.from(m['resimUrller'] ?? []),
          favoriSayisi:    (m['favoriSayisi'] as num?)?.toInt() ?? 0,
          tarih:           m['tarih'] != null ? DateTime.tryParse(m['tarih']) : null,
          olusturmaTarihi: m['olusturmaTarihi'] != null ? DateTime.tryParse(m['olusturmaTarihi']) : null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> kaydet(List<IlanModel> liste) async {
    final prefs = await SharedPreferences.getInstance();
    final data = liste.map((i) => {
      'id':              i.id,
      'tip':             i.tip,
      'nereden':         i.nereden,
      'nereye':          i.nereye,
      'urun':            i.urun,
      'ucret':           i.ucret,
      'kategori':        i.kategori,
      'anaKategori':     i.anaKategori,
      'kullaniciId':     i.kullaniciId,
      'kullaniciAd':     i.kullaniciAd,
      'resimUrl':        i.resimUrl,
      'resimUrller':     i.resimUrller,
      'favoriSayisi':    i.favoriSayisi,
      'tarih':           i.tarih?.toIso8601String(),
      'olusturmaTarihi': i.olusturmaTarihi?.toIso8601String(),
    }).toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }
}

@Riverpod(keepAlive: true)
SonGoruntulenenlerRepository sonGoruntulenenlerRepository(Ref ref) {
  return SonGoruntulenenlerRepository();
}
