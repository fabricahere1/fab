import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show VoidCallback, debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';
import '../../../shared/utils/app_hata_yonetici.dart';
// currentUserProvider/AktifKullanici artık burada tanımlı değil ama
// uygulama genelinde 40+ dosya "auth_provider.dart"ı import edip
// currentUserProvider'a erişiyor — hepsini değiştirmek yerine
// re-export ediyoruz.
export 'aktif_kullanici_provider.dart';

part 'auth_provider.g.dart';

/// Backend'in {"hata": "..."} gövdesinden kullanıcıya gösterilecek
/// mesajı çıkarır, yoksa [varsayilan]'a düşer.
String _backendHatasi(Object e, String varsayilan) {
  if (e is DioException) {
    final govde = e.response?.data;
    if (govde is Map && govde['hata'] is String) {
      return govde['hata'] as String;
    }
  }
  return varsayilan;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<AuthSonuc> emailIleGiris({
    required String email,
    required String sifre,
  }) async {
    state = const AsyncLoading();
    try {
      final sonuc = await _repo.epostaIleGiris(email: email, sifre: sifre);
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(sonuc.kullanici['id'] as String);
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(_backendHatasi(e, 'E-posta veya şifre hatalı.'));
    }
  }

  Future<AuthSonuc> emailIleKayit({
    required String adSoyad,
    required String email,
    required String sifre,
  }) async {
    state = const AsyncLoading();
    try {
      final sonuc = await _repo.epostaIleKayit(
        adSoyad: adSoyad,
        email: email,
        sifre: sifre,
      );
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(sonuc.kullanici['id'] as String);
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(_backendHatasi(e, 'Bu e-posta ile kayıt oluşturulamadı.'));
    }
  }

  Future<AuthSonuc> googleIleGiris() async {
    state = const AsyncLoading();
    try {
      final sonuc = await _repo.googleIleGiris();
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(sonuc.kullanici['id'] as String);
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'auth.googleIleGiris');
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata('Google ile giriş yapılamadı.');
    }
  }

  Future<void> telefonKoduGonder({
    required String telefon,
    required void Function(String) onKodGonderildi,
    required void Function(String) onHata,
    void Function(String smsKodu)? onOtomatikGiris,
  }) async {
    await _repo.telefonKoduGonder(
      telefon: telefon,
      onKodGonderildi: onKodGonderildi,
      onHata: onHata,
      onOtomatikGiris: onOtomatikGiris,
    );
  }

  Future<AuthSonuc> telefonIleGiris({
    required String verificationId,
    required String smsKodu,
  }) async {
    state = const AsyncLoading();
    try {
      final sonuc = await _repo.telefonIleGiris(
        verificationId: verificationId,
        smsKodu: smsKodu,
      );
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(sonuc.kullanici['id'] as String);
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      // TANI: "Bir hata oluştu" (hataMesaji'nin eşlenmemiş-kod varsayılanı)
      // raporlandı — gerçek kodu görebilmek için logluyoruz.
      debugPrint('[TELEFON_GIRIS_HATA] code=${e.code} message=${e.message}');
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      debugPrint('[TELEFON_GIRIS_HATA] beklenmeyen tip: $e');
      return AuthSonuc.hata('Doğrulama başarısız. Tekrar dene.');
    }
  }

  Future<void> cikisYap() async {
    await _repo.cikisYap();
  }

  Future<AuthSonuc> emailIleYenidenGiris({
    required String email,
    required String sifre,
  }) async {
    try {
      await _repo.epostaIleYenidenGiris(email: email, sifre: sifre);
      return AuthSonuc.basarili('');
    } catch (_) {
      return AuthSonuc.hata('Kimlik doğrulama başarısız.');
    }
  }

  Future<AuthSonuc> telefonIleYenidenGiris({
    required String verificationId,
    required String smsKodu,
  }) async {
    try {
      await _repo.telefonIleYenidenGiris(verificationId: verificationId, smsKodu: smsKodu);
      return AuthSonuc.basarili('');
    } catch (_) {
      return AuthSonuc.hata('Kimlik doğrulama başarısız.');
    }
  }

  Future<AuthSonuc> googleIleYenidenGiris({VoidCallback? onHesapSecildi}) async {
    try {
      onHesapSecildi?.call();
      await _repo.googleIleYenidenGiris();
      return AuthSonuc.basarili('');
    } catch (_) {
      return AuthSonuc.hata('Google doğrulama başarısız.');
    }
  }

  Future<AuthSonuc> hesapSil() async {
    try {
      await _repo.hesapSil();
      return AuthSonuc.basarili('');
    } catch (_) {
      return AuthSonuc.hata('Hesap silinemedi.');
    }
  }
}

class AuthSonuc {
  final bool basarili;
  final String? uid;
  final String? hata;

  const AuthSonuc._({required this.basarili, this.uid, this.hata});

  factory AuthSonuc.basarili(String uid) =>
      AuthSonuc._(basarili: true, uid: uid);

  factory AuthSonuc.hata(String mesaj) =>
      AuthSonuc._(basarili: false, hata: mesaj);
}
