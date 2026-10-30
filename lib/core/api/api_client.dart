// lib/core/api/api_client.dart
//
// Çekmece'nin (ikinciel) lib/core/api/api_client.dart'ındaki BİREBİR aynı
// desen — AWS Fargate'teki Go backend'imizle (aynı sunucu, /v3 altında
// tamamen izole route'lar) konuşan merkezi HTTP istemcisi. Firebase'in
// yerini bu alıyor.

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://api.cekmece.app/v3';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const String _tokenKey = 'v3_jwt_token';

  /// Backend 401 (token süresi dolmuş/geçersiz) dönünce çağrılır.
  static void Function()? onUnauthorized;

  static Future<void> init() async {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final guncelToken = prefs.getString(_tokenKey);
        if (guncelToken != null) {
          options.headers['Authorization'] = 'Bearer $guncelToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenSil();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  static Future<void> tokenKaydet(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> tokenSil() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<String?> tokenOku() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Dio get dio => _dio;
}
