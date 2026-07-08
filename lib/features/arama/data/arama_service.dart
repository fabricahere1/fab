// lib/features/arama/data/arama_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/constants/app_constants.dart';

const _kAlgoliaAppId     = 'NVHD1ZSPLZ';
const _kAlgoliaSearchKey = '97de9ef489349d39ce0d256355b82952';
const _kAlgoliaIndex     = 'ilanlar';

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
        objectID:    json['objectID']    as String? ?? '',
        urun:        json['urun']        as String? ?? '',
        nereden:     json['nereden']     as String? ?? '',
        nereye:      json['nereye']      as String? ?? '',
        kategori:    json['kategori']    as String? ?? '',
        tip:         json['tip']         as String? ?? '',
        resimUrl:    json['resimUrl']    as String?,
        kullaniciId: json['kullaniciId'] as String? ?? '',
      );
}

// ── Filtre sonucu modeli ──────────────────────────────────────────────────────

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

  final url = Uri.parse(
    'https://$_kAlgoliaAppId-dsn.algolia.net/1/indexes/$_kAlgoliaIndex/query',
  );

  final body = <String, dynamic>{
    'query': sorgu,
    'hitsPerPage': 30,
    'attributesToRetrieve': [
      'objectID', 'urun', 'nereden', 'nereye', 'kategori',
      'tip', 'resimUrl', 'kategoriYolu',
    ],
  };

  if (katFiltre != null) {
    final altKeyler = tumAltKeyler(katFiltre);
    final filterParts = altKeyler
        .map((k) => 'kategoriYolu:$k OR kategori:$k')
        .join(' OR ');
    body['filters'] = filterParts;
  }

  final response = await http.post(
    url,
    headers: {
      'X-Algolia-Application-Id': _kAlgoliaAppId,
      'X-Algolia-API-Key': _kAlgoliaSearchKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final hits = data['hits'] as List<dynamic>? ?? [];
  return hits.map((h) => AramaSonucu.fromJson(h as Map<String, dynamic>)).toList();
}

// ── Türkiye dışı yer arama ─────────────────────────────────────────────────────
//
// alan parametresi hangi Algolia field'ına bakılacağını belirler:
// 'nereye' -> istekler ekranı (isteğin teslim edileceği yer)
// 'nereden' -> gelenler ekranı (taşıyıcının geldiği yer)
//
// NOT: ilanlar_nereye index'i sadece 'nereye' alanını içerir. 'nereden' alanı
// için ana 'ilanlar' index'i üzerinden sorgu yapılır (facet/distinct olmadan,
// hits üzerinden manuel benzersizleştirme ile).

Future<List<String>> algoliaYerAra(String sorgu, {String alan = 'nereye'}) async {
  if (sorgu.trim().isEmpty) return [];

  if (alan == 'nereden') {
    return _algoliaYerAraNereden(sorgu);
  }
  return _algoliaYerAraNereye(sorgu);
}

Future<List<String>> _algoliaYerAraNereye(String sorgu) async {
  final url = Uri.parse(
    'https://$_kAlgoliaAppId-dsn.algolia.net/1/indexes/ilanlar_nereye/query',
  );

  final response = await http.post(
    url,
    headers: {
      'X-Algolia-Application-Id': _kAlgoliaAppId,
      'X-Algolia-API-Key': _kAlgoliaSearchKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'query': sorgu,
      'hitsPerPage': 50,
      'attributesToRetrieve': ['nereye'],
    }),
  );

  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final hits = data['hits'] as List<dynamic>? ?? [];

  final liste = hits
      .map((h) => (h as Map<String, dynamic>)['nereye'] as String? ?? '')
      .where((n) => n.isNotEmpty)
      .toSet()
      .where((n) => !kTurkiyeSehirleri.any(
          (s) => s.toLowerCase() == n.toLowerCase()))
      .toList();

  return _siralaOneriler(liste, sorgu);
}

Future<List<String>> _algoliaYerAraNereden(String sorgu) async {
  // ilanlar_nereye index'i nereden alanını içermiyor, ana index'te ara.
  final url = Uri.parse(
    'https://$_kAlgoliaAppId-dsn.algolia.net/1/indexes/$_kAlgoliaIndex/query',
  );

  final response = await http.post(
    url,
    headers: {
      'X-Algolia-Application-Id': _kAlgoliaAppId,
      'X-Algolia-API-Key': _kAlgoliaSearchKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'query': sorgu,
      'restrictSearchableAttributes': ['nereden'],
      'hitsPerPage': 100,
      'attributesToRetrieve': ['nereden'],
      'filters': 'tip:tasiyici AND aktif:true AND durum:yayinda',
    }),
  );

  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final hits = data['hits'] as List<dynamic>? ?? [];

  final liste = hits
      .map((h) => (h as Map<String, dynamic>)['nereden'] as String? ?? '')
      .where((n) => n.isNotEmpty)
      .toSet()
      .where((n) => !kTurkiyeSehirleri.any(
          (s) => s.toLowerCase() == n.toLowerCase()))
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
  String siralama  = 'enYeni',
  String ilanTipi  = 'istek',
  int sayfa        = 0,
  int hitsPerPage  = 24,
}) async {
  final indexAdi = switch (siralama) {
    'enCokFavorilenen' => 'ilanlar_favori',
    'onerilen'         => 'ilanlar_onerilen',
    _                  => _kAlgoliaIndex,
  };

  final url = Uri.parse(
    'https://$_kAlgoliaAppId-dsn.algolia.net/1/indexes/$indexAdi/query',
  );

  final List<String> filterParcalar = [];
  filterParcalar.add('aktif:true');
  filterParcalar.add('durum:yayinda');
  filterParcalar.add('tip:$ilanTipi');

  if (seciliAltKeyler.isNotEmpty) {
    final katFilter = seciliAltKeyler
        .map((k) => 'kategoriYolu:$k OR kategori:$k')
        .join(' OR ');
    filterParcalar.add('($katFilter)');
  } else if (kategoriYolu.isNotEmpty) {
    final sonKey = kategoriYolu.last;
    final altKeyler = tumAltKeyler(sonKey);
    if (altKeyler.isNotEmpty) {
      final katFilter = altKeyler
          .map((k) => 'kategoriYolu:$k OR kategori:$k')
          .join(' OR ');
      filterParcalar.add('($katFilter)');
    }
  }

  if (sehirler.isNotEmpty) {
    final sehirFilter = sehirler.map((s) => 'nereye:"$s"').join(' OR ');
    filterParcalar.add('($sehirFilter)');
  }
  // Türkiye dışı serbest metin filtresi
  // İstekler: nereye filtresi (isteğin teslim edileceği yer)
  if (ulkeSehir.isNotEmpty) {
    filterParcalar.add('nereye:"$ulkeSehir"');
  }
  // Gelenler: nereden filtresi (taşıyıcının geldiği yer)
  if (nerdenUlkeSehir.isNotEmpty) {
    filterParcalar.add('nereden:"$nerdenUlkeSehir"');
  }

  final filtreler = filterParcalar.join(' AND ');

  final body = <String, dynamic>{
    'query': '',
    'filters': filtreler,
    'hitsPerPage': hitsPerPage,
    'page': sayfa,
    'attributesToRetrieve': [
      'objectID', 'urun', 'nereden', 'nereye', 'kategori',
      'anaKategori', 'kategoriYolu', 'tip', 'aktif', 'durum',
      'resimUrl', 'resimThumbUrl', 'resimUrller', 'olusturmaTarihi',
      'kullaniciId', 'kullaniciAd', 'favoriSayisi', 'goruntulenmeSayisi',
      'cinsiyet', 'beden',
    ],
    'facets': ['anaKategori'],
  };

  final response = await http.post(
    url,
    headers: {
      'X-Algolia-Application-Id': _kAlgoliaAppId,
      'X-Algolia-API-Key': _kAlgoliaSearchKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    return const AlgoliaFiltreSonucu(
      ilanlar: [], toplamSayfa: 0, mevcutSayfa: 0, toplamSonuc: 0,
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final hits = (data['hits'] as List<dynamic>? ?? [])
      .map((h) => h as Map<String, dynamic>)
      .toList();

  final facetsRaw = data['facets'] as Map<String, dynamic>?;
  final anaKategoriFacets = facetsRaw?['anaKategori'] as Map<String, dynamic>? ?? {};
  final kategoriFacets = anaKategoriFacets.map(
    (k, v) => MapEntry(k, (v as num).toInt()),
  );

  return AlgoliaFiltreSonucu(
    ilanlar:        hits,
    toplamSayfa:    data['nbPages']  as int? ?? 1,
    mevcutSayfa:    data['page']     as int? ?? 0,
    toplamSonuc:    data['nbHits']   as int? ?? 0,
    kategoriFacets: kategoriFacets,
  );
}