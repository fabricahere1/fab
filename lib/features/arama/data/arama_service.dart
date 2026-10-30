// lib/features/arama/data/arama_service.dart
//
// Eskiden Algolia'ya (Firestore Cloud Functions ile senkronize edilen,
// Firestore kapatıldığı için artık donmuş bir index) gidiyordu — yeni
// ilanlar hiç görünmüyordu. Artık AWS backend'in /v3/ilanlar-filtrele ve
// /v3/ilanlar/sehir-ara uçlarını kullanıyor (bkz. v3_ilan_filtrele.go).
// Fonksiyon imzaları/dönüş tipleri AYNEN korundu — ilanlar_screen.dart,
// arama_screen.dart, gelenler_screen.dart hiç değişmeden çalışmaya devam
// ediyor.

import '../../../core/api/api_client.dart';
import '../../../shared/constants/app_constants.dart';

// ── Arama sonucu modeli ───────────────────────────────────────────────────────

class AramaSonucu {
  final String objectID;
  final String urun;
  final String nereden;
  final String nereye;
  final String kategori;
  final String tip;
  final String? resimUrl;
  final String kullaniciId;

  const AramaSonucu({
    required this.objectID,
    required this.urun,
    required this.nereden,
    required this.nereye,
    required this.kategori,
    required this.tip,
    this.resimUrl,
    this.kullaniciId = '',
  });

  factory AramaSonucu.fromJson(Map<String, dynamic> json) => AramaSonucu(
        objectID:    json['id']          as String? ?? '',
        urun:        json['urun']        as String? ?? '',
        nereden:     json['nereden']     as String? ?? '',
        nereye:      json['nereye']      as String? ?? '',
        kategori:    json['kategori']    as String? ?? 'diger',
        tip:         json['tip']         as String? ?? '',
        resimUrl:    json['resimUrl']    as String?,
        kullaniciId: json['kullaniciId'] as String? ?? '',
      );
}

// ── Filtre sonucu modeli ──────────────────────────────────────────────────────
// ilanlar artık ham v3Ilan JSON'ı (IlanModel.fromJson ile uyumlu) —
// ilanlar_screen.dart._hittenIlan bunu doğrudan IlanModel.fromJson'a verir.

class AlgoliaFiltreSonucu {
  final List<Map<String, dynamic>> ilanlar;
  final int toplamSayfa;
  final int mevcutSayfa;
  final int toplamSonuc;
  final Map<String, int> kategoriFacets;

  const AlgoliaFiltreSonucu({
    required this.ilanlar,
    required this.toplamSayfa,
    required this.mevcutSayfa,
    required this.toplamSonuc,
    this.kategoriFacets = const {},
  });
}

// ── Arama (arama ekranı için) ─────────────────────────────────────────────────

Future<List<AramaSonucu>> algoliaAra(String sorgu, {String? katFiltre}) async {
  if (sorgu.trim().isEmpty && katFiltre == null) return [];

  final response = await ApiClient.dio.get('/ilanlar', queryParameters: {
    'arama': sorgu,
    'hitsPerPage': 30,
  });
  var hits = (response.data['ilanlar'] as List)
      .map((h) => h as Map<String, dynamic>)
      .toList();

  if (katFiltre != null) {
    final altKeyler = tumAltKeyler(katFiltre);
    hits = hits.where((h) {
      final kategoriYolu = (h['kategoriYolu'] as List<dynamic>?)?.cast<String>() ?? [];
      final kategori = h['kategori'] as String? ?? '';
      return altKeyler.contains(kategori) || kategoriYolu.any(altKeyler.contains);
    }).toList();
  }

  return hits.map(AramaSonucu.fromJson).toList();
}

// ── Türkiye dışı yer arama ─────────────────────────────────────────────────────
//
// alan parametresi hangi alana bakılacağını belirler:
// 'nereye' -> istekler ekranı (isteğin teslim edileceği yer)
// 'nereden' -> gelenler ekranı (taşıyıcının geldiği yer)

Future<List<String>> algoliaYerAra(String sorgu, {String alan = 'nereye'}) async {
  if (sorgu.trim().isEmpty) return [];

  final response = await ApiClient.dio.get('/ilanlar/sehir-ara', queryParameters: {
    'sorgu': sorgu,
    'alan': alan,
  });
  final liste = (response.data as List)
      .cast<String>()
      .where((n) => n.isNotEmpty)
      .toSet()
      .where((n) => !kTurkiyeSehirleri.any((s) => s.toLowerCase() == n.toLowerCase()))
      .toList();

  return _siralaOneriler(liste, sorgu);
}

List<String> _siralaOneriler(List<String> liste, String sorgu) {
  final sorguKucuk = sorgu.toLowerCase();
  liste.sort((a, b) {
    final aBasliyor = a.toLowerCase().startsWith(sorguKucuk);
    final bBasliyor = b.toLowerCase().startsWith(sorguKucuk);
    if (aBasliyor && !bBasliyor) return -1;
    if (!aBasliyor && bBasliyor) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  });
  return liste;
}

// ── Filtreleme (ilanlar ekranı için) ─────────────────────────────────────────
//
// İstekler ekranı: ulkeSehir parametresi nereye alanına filtre uygular
// (isteğin teslim edileceği yer — örn. Londra'dan Milano'ya gidecek biri
// Milano'ya teslim edilecek istek arar).
//
// Gelenler ekranı: nerdenUlkeSehir parametresi nereden alanına filtre uygular
// (taşıyıcının geldiği yer — örn. Milano'da yaşayan biri Londra'dan gelen
// taşıyıcı arar).

Future<AlgoliaFiltreSonucu> algoliaFiltrele({
  List<String> kategoriYolu    = const [],
  List<String> seciliAltKeyler = const [],
  List<String> sehirler        = const [],
  String ulkeSehir       = '',   // Türkiye dışı - nereye filtresi (istekler için)
  String nerdenUlkeSehir = '',   // Türkiye dışı - nereden filtresi (gelenler için)
  String neredenUlke     = '',   // "Nereden Geliyor" - kDunyaUlkeleri'nden seçilen
                                  // kanonik ülke adıyla nereden filtresi (gelenler
                                  // için, Türkiye dışı serbest metin filtresinden
                                  // AYRI, bağımsız bir AND koşulu).
  String siralama  = 'enYeni',
  String ilanTipi  = 'istek',
  int sayfa        = 0,
  int hitsPerPage  = 24,
}) async {
  List<String> altKeyler = seciliAltKeyler;
  if (altKeyler.isEmpty && kategoriYolu.isNotEmpty) {
    altKeyler = tumAltKeyler(kategoriYolu.last).toList();
  }

  try {
    final response = await ApiClient.dio.get('/ilanlar-filtrele', queryParameters: {
      'tip': ilanTipi,
      if (altKeyler.isNotEmpty) 'altKeyler': altKeyler,
      if (sehirler.isNotEmpty) 'sehirler': sehirler,
      if (ulkeSehir.isNotEmpty) 'ulkeSehir': ulkeSehir,
      if (nerdenUlkeSehir.isNotEmpty) 'nerdenUlkeSehir': nerdenUlkeSehir,
      if (neredenUlke.isNotEmpty) 'neredenUlke': neredenUlke,
      'siralama': siralama,
      'sayfa': sayfa,
      'hitsPerPage': hitsPerPage,
    });

    final data = response.data as Map<String, dynamic>;
    final hits = (data['ilanlar'] as List).map((h) => h as Map<String, dynamic>).toList();
    final kategoriFacetsRaw = data['kategoriFacets'] as Map<String, dynamic>? ?? {};

    return AlgoliaFiltreSonucu(
      ilanlar:        hits,
      toplamSayfa:    data['toplamSayfa'] as int? ?? 1,
      mevcutSayfa:    data['mevcutSayfa'] as int? ?? 0,
      toplamSonuc:    data['toplamSonuc'] as int? ?? 0,
      kategoriFacets: kategoriFacetsRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  } catch (_) {
    return const AlgoliaFiltreSonucu(
      ilanlar: [], toplamSayfa: 0, mevcutSayfa: 0, toplamSonuc: 0,
    );
  }
}
