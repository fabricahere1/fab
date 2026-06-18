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

  const AramaSonucu({
    required this.objectID,
    required this.urun,
    required this.nereden,
    required this.nereye,
    required this.kategori,
    required this.tip,
    this.resimUrl,
  });

  factory AramaSonucu.fromJson(Map<String, dynamic> json) => AramaSonucu(
        objectID: json['objectID'] as String? ?? '',
        urun:     json['urun']     as String? ?? '',
        nereden:  json['nereden']  as String? ?? '',
        nereye:   json['nereye']   as String? ?? '',
        kategori: json['kategori'] as String? ?? '',
        tip:      json['tip']      as String? ?? '',
        resimUrl: json['resimUrl'] as String?,
      );
}

// ── Filtre sonucu modeli ──────────────────────────────────────────────────────

class AlgoliaFiltreSonucu {
  final List<Map<String, dynamic>> ilanlar;
  final int toplamSayfa;
  final int mevcutSayfa;
  final int toplamSonuc;
  final Map<String, int> kategoriFacets; // key -> ilan sayisi

  const AlgoliaFiltreSonucu({
    required this.ilanlar,
    required this.toplamSayfa,
    required this.mevcutSayfa,
    required this.toplamSonuc,
    this.kategoriFacets = const {},
  });
}

// ── Arama (arama ekranı icin) ─────────────────────────────────────────────────

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

// ── Türkiye dışı yer arama (sadece nereye alanında arar) ──────────────────────

Future<List<String>> algoliaYerAra(String sorgu) async {
  if (sorgu.trim().isEmpty) return [];

  // ilanlar_nereye index'i — sadece nereye alanı searchable
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

  final sorguKucuk = sorgu.toLowerCase();
  final liste = hits
      .map((h) => (h as Map<String, dynamic>)['nereye'] as String? ?? '')
      .where((n) => n.isNotEmpty)
      .toSet()
      .where((n) => !kTurkiyeSehirleri.any(
          (s) => s.toLowerCase() == n.toLowerCase()))
      .toList();

  // Sorguyla başlayanlar öne, sonra alfabetik
  liste.sort((a, b) {
    final aBasliyor = a.toLowerCase().startsWith(sorguKucuk);
    final bBasliyor = b.toLowerCase().startsWith(sorguKucuk);
    if (aBasliyor && !bBasliyor) return -1;
    if (!aBasliyor && bBasliyor) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  });

  return liste;
}

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

// ── Filtreleme (ilanlar ekrani icin) ─────────────────────────────────────────
//
// Kategori, sehir, siralama ve sayfalama Algolia sunucusunda yapilir.
// [sayfa] 0-indexed. [hitsPerPage] sayfa basina ilan sayisi.

Future<AlgoliaFiltreSonucu> algoliaFiltrele({
  List<String> kategoriYolu    = const [],
  List<String> seciliAltKeyler = const [],
  List<String> sehirler        = const [],
  String ulkeSehir = '',           // Türkiye dışı serbest metin
  String siralama  = 'enYeni',
  String ilanTipi  = 'istek',
  int sayfa        = 0,
  int hitsPerPage  = 24,
}) async {
  // Sıralamaya göre doğru index'i seç
  final indexAdi = siralama == 'enCokFavorilenen'
      ? 'ilanlar_favori'
      : _kAlgoliaIndex;

  final url = Uri.parse(
    'https://$_kAlgoliaAppId-dsn.algolia.net/1/indexes/$indexAdi/query',
  );

  // ── Filter oluştur ────────────────────────────────────────────────────────
  final List<String> filterParcalar = [];

  // Aktif ve yayinda olan ilanlar
  filterParcalar.add('aktif:true');
  filterParcalar.add('durum:yayinda');

  // İlan tipi (istek veya tasiyici)
  filterParcalar.add('tip:$ilanTipi');

  // Kategori filtresi
  if (seciliAltKeyler.isNotEmpty) {
    // Coklu alt kategori secimi - her birini OR ile birlestir
    final katFilter = seciliAltKeyler
        .map((k) => 'kategoriYolu:$k OR kategori:$k')
        .join(' OR ');
    filterParcalar.add('($katFilter)');
  } else if (kategoriYolu.isNotEmpty) {
    // Tek ana kategori - tum alt keyleri dahil et
    final sonKey = kategoriYolu.last;
    final altKeyler = tumAltKeyler(sonKey);
    if (altKeyler.isNotEmpty) {
      final katFilter = altKeyler
          .map((k) => 'kategoriYolu:$k OR kategori:$k')
          .join(' OR ');
      filterParcalar.add('($katFilter)');
    }
  }

  // Şehir filtresi — nereye alaninda arar
  if (sehirler.isNotEmpty) {
    final sehirFilter = sehirler
        .map((s) => 'nereye:"$s"')
        .join(' OR ');
    filterParcalar.add('($sehirFilter)');
  }
  // Türkiye dışı serbest metin filtresi
  if (ulkeSehir.isNotEmpty) {
    filterParcalar.add('nereye:"$ulkeSehir"');
  }

  final filtreler = filterParcalar.join(' AND ');

  // ── Siralama ──────────────────────────────────────────────────────────────
  // Algolia replica index kullanmak yerine numericFilters ile siralama yapiyoruz.
  // Ana index olusturmaTarihi DESC siralali (en yeni).
  // Diger siralamalari client-side yapiyoruz (kucuk veri setleri icin yeterli).
  final body = <String, dynamic>{
    'query': '',
    'filters': filtreler,
    'hitsPerPage': hitsPerPage,
    'page': sayfa,
    'attributesToRetrieve': [
      'objectID', 'urun', 'nereden', 'nereye', 'kategori',
      'anaKategori', 'kategoriYolu', 'tip', 'aktif', 'durum',
      'resimUrl', 'olusturmaTarihi',
    ],
    'facets': ['anaKategori'],
  };

  // En eskiye gore siralama icin sort replica kullanmak yerine
  // olusturmaTarihi ASC sorgusu gonderiyoruz
  if (siralama == 'enEski') {
    // Algolia'da varsayilan DESC — ASC icin replica lazim, yoksa client-side
    // Simdilik hitsPerPage kadar alip client sort yapiyoruz
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

  if (response.statusCode != 200) {
    return const AlgoliaFiltreSonucu(
      ilanlar: [], toplamSayfa: 0, mevcutSayfa: 0, toplamSonuc: 0,
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final hits = (data['hits'] as List<dynamic>? ?? [])
      .map((h) => h as Map<String, dynamic>)
      .toList();

  // Facet sayilarini parse et
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