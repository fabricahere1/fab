// lib/shared/utils/app_hata_yonetici.dart
//
// Kullanım (context gereken yerler — UI katmanı):
//   AppHataYonetici.yakala(e, s, context: context, mesaj: 'İlan yüklenemedi');
//
// Kullanım (context olmayan yerler — provider/repository katmanı):
//   AppHataYonetici.logla(e, s, etiket: 'mesajlarStream');
//
// Stream onError:
//   onError: (e, s) => AppHataYonetici.logla(e, s, etiket: 'mesajlarStream'),

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_snackbar.dart';

class AppHataYonetici {
  AppHataYonetici._();

  // ── Kullanıcıya göster + Crashlytics'e logla ─────────────────────────────
  //
  // UI katmanında (context erişimi olan yerlerde) kullan.
  // [mesaj] verilmezse, hata tipine göre otomatik Türkçe mesaj seçilir.
  static void yakala(
    Object hata,
    StackTrace? stack, {
    required BuildContext context,
    String? mesaj,
    String? etiket,
    bool fatal = false,
  }) {
    final turkceMessaj = mesaj ?? _turkceHataMesaji(hata);
    logla(hata, stack, etiket: etiket ?? turkceMessaj, fatal: fatal);
    if (context.mounted) {
      AppSnackBar.hata(context, turkceMessaj);
    }
  }

  // ── Sadece logla (context olmayan yerler) ────────────────────────────────
  //
  // Provider/repository/service katmanında, context erişimi olmayan
  // yerlerde kullan. Kullanıcıya hiçbir şey göstermez, sadece loglar.
  static void logla(
    Object hata,
    StackTrace? stack, {
    String? etiket,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('🔴 [${etiket ?? 'AppHata'}] $hata');
      if (stack != null) debugPrint(stack.toString());
    } else {
      FirebaseCrashlytics.instance.recordError(
        hata,
        stack,
        reason: etiket,
        fatal: fatal,
        printDetails: false,
      );
    }
  }

  // ── Stream onError için kısa yardımcı ────────────────────────────────────
  //
  // Stream dinleyicilerinin onError parametresinde kullan:
  //   onError: AppHataYonetici.streamHatasi('mesajlarStream'),
  static void Function(Object, StackTrace) streamHatasi(String etiket) {
    return (hata, stack) => logla(hata, stack, etiket: etiket);
  }

  // ── Firebase hata kodlarını Türkçe mesajlara çevir ───────────────────────

  static String _turkceHataMesaji(Object hata) {
    if (hata is FirebaseAuthException) {
      return _authHatasi(hata.code);
    }
    if (hata is FirebaseException) {
      return _firestoreHatasi(hata.code);
    }
    if (hata is FirebaseStorage) {
      return 'Dosya yüklenirken bir sorun oluştu.';
    }
    final mesaj = hata.toString().toLowerCase();
    if (mesaj.contains('network') || mesaj.contains('socket') ||
        mesaj.contains('connection')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    if (mesaj.contains('timeout')) {
      return 'İstek zaman aşımına uğradı. Tekrar deneyin.';
    }
    return 'Bir sorun oluştu. Lütfen tekrar deneyin.';
  }

  static String _authHatasi(String kod) {
    switch (kod) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi girin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Bir süre bekleyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'requires-recent-login':
        return 'Bu işlem için tekrar giriş yapmanız gerekiyor.';
      case 'invalid-verification-code':
        return 'Doğrulama kodu hatalı.';
      case 'invalid-phone-number':
        return 'Geçerli bir telefon numarası girin.';
      case 'session-expired':
        return 'Doğrulama süresi doldu. Tekrar kod isteyin.';
      case 'quota-exceeded':
        return 'SMS kotası aşıldı. Daha sonra tekrar deneyin.';
      default:
        return 'Giriş sırasında bir sorun oluştu. Tekrar deneyin.';
    }
  }

  static String _firestoreHatasi(String kod) {
    switch (kod) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case 'not-found':
        return 'İstenen içerik bulunamadı.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.';
      case 'cancelled':
        return 'İşlem iptal edildi.';
      case 'already-exists':
        return 'Bu kayıt zaten mevcut.';
      case 'resource-exhausted':
        return 'Çok fazla istek yapıldı. Bir süre bekleyin.';
      case 'unauthenticated':
        return 'Bu işlem için giriş yapmanız gerekiyor.';
      default:
        return 'Bir sorun oluştu. Lütfen tekrar deneyin.';
    }
  }
}