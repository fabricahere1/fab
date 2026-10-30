// lib/features/auth/data/auth_repository.dart
//
// Firebase Auth + Firestore'un yerini AWS Go backend'i (/v3 route'ları)
// alıyor — Çekmece'nin (ikinciel) aynı dosyasındaki desenle birebir aynı.
// Telefon girişi hâlâ Firebase Phone Auth'tan geçiyor (SMS/OTP altyapımız
// AWS'de yok) ama sonucu backend'e gönderip KENDİ JWT'mizi alıyoruz.

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/fcm_service.dart';
import '../../../shared/utils/app_hata_yonetici.dart';
import '../providers/aktif_kullanici_provider.dart';
import 'google_auth_service.dart';

part 'auth_repository.g.dart';

// keepAlive ZORUNLU: _girisSonucunuIsle() ağ çağrısı bittikten SONRA
// kendi ref'i üzerinden başka bir provider'ı invalidate ediyor
// (aktifKullaniciProvider) — autoDispose olsaydı, o awaitlerin arasında
// bu provider'ı dinleyen kalmayınca (ör. login ekranı rebuild olunca)
// Riverpod bu provider'ı erken temizliyor ve "Ref ... disposed" hatası
// fırlatıyordu (bkz. 2026-10-23 Google girişi 500/TANI hatası).
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(auth: FirebaseAuth.instance, ref: ref);
}

/// Backend'den dönen {token, kullanici} yanıtını temsil eder.
class V3GirisSonucu {
  final String token;
  final Map<String, dynamic> kullanici;
  V3GirisSonucu({required this.token, required this.kullanici});
}

class AuthRepository {
  // Telefon OTP'si hâlâ Firebase Phone Auth'tan geçtiği için auth
  // örneğine ihtiyacımız var — e-posta/şifre ve Google için artık
  // KULLANILMIYOR.
  final FirebaseAuth auth;
  final Ref ref;
  GoogleSignIn get _googleSignIn => GoogleAuthService.instance;

  AuthRepository({required this.auth, required this.ref}) {
    auth.setLanguageCode('tr');
  }

  Future<V3GirisSonucu> _girisSonucunuIsle(
    Future<Response> Function() istek,
  ) async {
    final response = await istek();
    final jwtToken = response.data['token'] as String;
    final kullanici = response.data['kullanici'] as Map<String, dynamic>;
    await ApiClient.tokenKaydet(jwtToken);
    await aktifKullaniciKaydet(kullanici);
    // SharedPreferences'a yazmak tek başına currentUserProvider'ı
    // GÜNCELLEMEZ — AktifKullaniciNotifier sadece build() anında okur.
    // invalidate olmadan giriş "başarılı" olur ama navbar/profil hâlâ
    // eski (null) durumu gösterir.
    ref.invalidate(aktifKullaniciProvider);
    FcmService.instance.girisSonrasiTokenKaydet();
    return V3GirisSonucu(token: jwtToken, kullanici: kullanici);
  }

  Future<V3GirisSonucu> epostaIleGiris({
    required String email,
    required String sifre,
  }) {
    return _girisSonucunuIsle(() => ApiClient.dio.post('/auth/eposta-giris', data: {
      'email': email.trim(),
      'sifre': sifre.trim(),
    }));
  }

  Future<V3GirisSonucu> epostaIleKayit({
    required String adSoyad,
    required String email,
    required String sifre,
  }) {
    return _girisSonucunuIsle(() => ApiClient.dio.post('/auth/eposta-kayit', data: {
      'email': email.trim(),
      'sifre': sifre.trim(),
      'adSoyad': adSoyad.trim(),
    }));
  }

  /// Google Sign-In'den aldığı idToken'ı backend'e gönderir — Çekmece'deki
  /// GoogleAuthService.girisYap ile aynı mantık, burada repository'nin
  /// kendi metodu olarak (v3'ün mevcut AuthNotifier çağrı şekliyle uyumlu
  /// kalsın diye).
  Future<V3GirisSonucu> googleIleGiris() async {
    await _googleSignIn.signOut();
    final googleKullanici = await _googleSignIn.signIn();
    if (googleKullanici == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google girişi iptal edildi.',
      );
    }
    final googleAuth = await googleKullanici.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google kimlik doğrulama tamamlanamadı (idToken alınamadı).',
      );
    }
    return _girisSonucunuIsle(
      () => ApiClient.dio.post('/auth/google', data: {'idToken': idToken}),
    );
  }

  // ── Yeniden Kimlik Doğrulama (hesap silmeden önce) ─────────
  // Stateless JWT'de sunucu tarafı "reauthenticate" kavramı yok — bunun
  // yerine aynı giriş uç noktasını tekrar çağırıp kimlik bilgisinin HÂLÂ
  // doğru olduğunu teyit ediyoruz (başarılı dönerse zaten yeni bir JWT da
  // almış oluyoruz, zararı yok).
  Future<void> epostaIleYenidenGiris({
    required String email,
    required String sifre,
  }) => epostaIleGiris(email: email, sifre: sifre);

  Future<void> telefonIleYenidenGiris({
    required String verificationId,
    required String smsKodu,
  }) => telefonIleGiris(verificationId: verificationId, smsKodu: smsKodu);

  Future<void> googleIleYenidenGiris() => googleIleGiris();

  /// Hesabı sil — backend'in DELETE /v3/auth/hesap'i (henüz yazılmadı,
  /// bkz. backlog) çağrılır, başarılıysa local oturum da temizlenir.
  Future<void> hesapSil() async {
    await ApiClient.dio.delete('/auth/hesap');
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await ApiClient.tokenSil();
    await aktifKullaniciSil();
    ref.invalidate(aktifKullaniciProvider);
  }

  // ── Telefon Girişi ────────────────────────────────────────
  // SMS/OTP hâlâ Firebase Phone Auth üzerinden (AWS'de kendi SMS
  // altyapımız yok), doğrulama sonrası backend'e idToken gönderip kendi
  // JWT'mizi alıyoruz — Çekmece'deki /auth/telefon ile aynı desen.

  Future<void> telefonKoduGonder({
    required String telefon,
    required void Function(String verificationId) onKodGonderildi,
    required void Function(String hata) onHata,
    void Function(String smsKodu)? onOtomatikGiris,
  }) async {
    await auth.verifyPhoneNumber(
      phoneNumber: telefon,
      verificationCompleted: (credential) async {
        final smsKodu = credential.smsCode ?? '';
        if (smsKodu.isNotEmpty) {
          onOtomatikGiris?.call(smsKodu);
        }
      },
      verificationFailed: (e) {
        onHata('${hataMesaji(e.code)} [${e.code}] ${e.message}');
      },
      codeSent: (verificationId, _) {
        onKodGonderildi(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<V3GirisSonucu> telefonIleGiris({
    required String verificationId,
    required String smsKodu,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsKodu,
    );
    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'telefon-giris-basarisiz',
        message: 'Telefon ile giriş tamamlanamadı.',
      );
    }
    final idToken = await user.getIdToken();

    final sonuc = await _girisSonucunuIsle(
      () => ApiClient.dio.post('/auth/telefon', data: {'idToken': idToken}),
    );

    // Firebase Auth oturumuna artık ihtiyaç yok — kimlik doğrulama sadece
    // SMS'i doğrulamak için kullanıldı, uygulama kendi JWT'siyle çalışıyor.
    await auth.signOut();
    return sonuc;
  }

  Future<void> cikisYap() async {
    await FcmService.instance.oturumKapanisTemizligi();
    try {
      await _googleSignIn.signOut();
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'cikis.googleSignOut');
    }
    await ApiClient.tokenSil();
    await aktifKullaniciSil();
    ref.invalidate(aktifKullaniciProvider);
  }

  static String hataMesaji(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre deneyin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'invalid-verification-code':
      case 'invalid-credential':
        // Yeni firebase_auth sürümlerinde yanlış/süresi dolmuş SMS kodu
        // 'invalid-verification-code' yerine (ya da onunla birlikte)
        // 'invalid-credential' olarak geliyor — eşlenmemiş kalırsa
        // kullanıcı anlamsız bir "Bir hata oluştu" görüyordu.
        return 'Doğrulama kodu hatalı ya da süresi dolmuş.';
      case 'session-expired':
        return 'Kodun süresi doldu. Lütfen yeni kod iste.';
      case 'invalid-verification-id':
      case 'missing-verification-id':
        return 'Doğrulama oturumu geçersiz. Lütfen yeni kod iste.';
      case 'credential-already-in-use':
        return 'Bu telefon numarası başka bir hesapla ilişkili.';
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası.';
      case 'operation-not-allowed':
        return 'Telefonla giriş şu an kullanılamıyor.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'google-sign-in-cancelled':
        return 'Google girişi iptal edildi.';
      case 'requires-recent-login':
        return 'Güvenlik için tekrar giriş yapmanız gerekiyor.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
