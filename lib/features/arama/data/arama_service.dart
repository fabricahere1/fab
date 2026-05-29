import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/constants/app_constants.dart';

const _kAlgoliaAppId     = 'NVHD1ZSPLZ';
const _kAlgoliaSearchKey = '97de9ef489349d39ce0d256355b82952';
const _kAlgoliaIndex     = 'ilanlar';

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
