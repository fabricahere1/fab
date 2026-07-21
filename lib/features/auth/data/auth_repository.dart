import '../../../core/firebase/app_firestore.dart';
import 'package:flutter/foundation.dart' show VoidCallback, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/fcm_service.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: AppFirestore.instance,
  );
}

// ── Auth Yöntemi Sınıflandırması ──────────────────────────
//
// user.providerData'dan hangi giriş yöntemiyle geldiğini belirleyen TEK
// kaynak — ayarlar_screen.dart (_hesapSilDialog) ve app_router.dart
// (_hedefBelirle) eskiden bunu ayrı ayrı elle kopyalayıp yazıyordu; yeni
// bir provider eklendiğinde iki yerin de senkron güncellenmesi garanti
// değildi. Öncelik sırası (google > telefon > email) her iki eski
// kopyanın da zımni davrandığı sırayla aynı.
enum AuthYontemi { google, telefon, email, bilinmiyor }

AuthYontemi authYontemiBelirle(User user) {
  if (user.providerData.any((p) => p.providerId == 'google.com')) {
    return AuthYontemi.google;
  }
  if (user.providerData.any((p) => p.providerId == 'phone')) {
    return AuthYontemi.telefon;
  }
  if (user.providerData.any((p) => p.providerId == 'password')) {
    return AuthYontemi.email;
  }
  return AuthYontemi.bilinmiyor;
}

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final _googleSignIn = GoogleSignIn();

  AuthRepository({required this.auth, required this.firestore});

  Stream<User?> authStateChanges() => auth.authStateChanges();
  User? get currentUser => auth.currentUser;

  Future<UserCredential> emailIleGiris({
    required String email,
    required String sifre,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: sifre.trim(),
    );
    if (credential.user != null && !credential.user!.emailVerified) {
      await auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Emailinizi doğrulamadan giriş yapamazsınız.',
      );
    }
    return credential;
  }

  Future<UserCredential> emailIleKayit({
    required String adSoyad,
    required String email,
    required String sifre,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: sifre.trim(),
    );
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(adSoyad.trim());
      await user.sendEmailVerification();
      await firestore.collection(Collections.kullanicilar).doc(user.uid).set({
        'adSoyad':          adSoyad.trim(),
        'email':            user.email,
        'sehir':            '',
        'telefon':          '',
        'profilTamamlandi': false,
        'olusturmaTarihi':  FieldValue.serverTimestamp(),
      });
    }
    return credential;
  }

  Future<UserCredential> googleIleGiris() async {
    await _googleSignIn.signOut();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google girişi iptal edildi.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final doc = await firestore
          .collection(Collections.kullanicilar)
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        await firestore
            .collection(Collections.kullanicilar)
            .doc(user.uid)
            .set({
          'adSoyad':          user.displayName ?? '',
          'email':            user.email ?? '',
          'sehir':            '',
          'telefon':          '',
          'telefonGizli':     false,
          'profilTamamlandi': false,
          'olusturmaTarihi':  FieldValue.serverTimestamp(),
        });
      }
    }
    return userCredential;
  }

  // ── Telefon Girişi ────────────────────────────────────────

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
        onHata(hataMesaji(e.code));
      },
      codeSent: (verificationId, _) {
        onKodGonderildi(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> telefonIleGiris({
    required String verificationId,
    required String smsKodu,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsKodu,
    );
    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      final doc = await firestore
          .collection(Collections.kullanicilar)
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        await firestore
            .collection(Collections.kullanicilar)
            .doc(user.uid)
            .set({
          'adSoyad':          '',
          'email':            '',
          'sehir':            '',
          'telefon':          user.phoneNumber ?? '',
          'telefonGizli':     false,
          'profilTamamlandi': false,
          'olusturmaTarihi':  FieldValue.serverTimestamp(),
        });
      }
    }
    return userCredential;
  }

  Future<void> cikisYap() async {
    await FcmService.instance.oturumKapanisTemizligi();
    try { await _googleSignIn.signOut(); } catch (e, s) { AppHataYonetici.logla(e, s, etiket: 'cikis.googleSignOut'); /* bilinçli sessiz: kullanıcıya gösterilmez, sadece iz */ }
    await auth.signOut();
  }

  // ── Re-authentication ─────────────────────────────────

  Future<void> emailIleYenidenGiris({
    required String email,
    required String sifre,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'Oturum bulunamadı.');
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: sifre.trim(),
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> googleIleYenidenGiris({VoidCallback? onHesapSecildi}) async {
    final user = auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'Oturum bulunamadı.');
    await _googleSignIn.signOut();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google girişi iptal edildi.',
      );
    }
    onHesapSecildi?.call();
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> telefonIleYenidenGiris({
    required String verificationId,
    required String smsKodu,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'Oturum bulunamadı.');
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsKodu,
    );
    await user.reauthenticateWithCredential(credential);
  }

  // ── Hesap Sil ─────────────────────────────────────────
  //
  // Tüm silme mantığı artık sunucu tarafında (hesapSilSunucu Cloud
  // Function, admin SDK ile çalışıyor). Client, sadece tetikliyor —
  // Firestore güvenlik kurallarına bağımlı, parçalı bir silme akışı
  // yerine, sunucuda tek, atomik bir işlem.
  Future<void> hesapSil() async {
    final user = auth.currentUser;
    if (user == null) return;

    await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('hesapSilSunucu')
        .call({});

    // DÜZELTME: sunucunun admin.auth().deleteUser() çağrısı, client'taki
    // Firebase Auth SDK'sının authStateChanges() stream'ini OTOMATİK
    // olarak null'a tetiklemiyor — bu yanlış bir varsayımdı (gerçek
    // testte doğrulandı: hesap silindikten sonra kullanıcı, login
    // ekranına yönlendirilmeden, eski oturumla mesaj göndermeyi
    // sürdürebiliyordu). Client'ın kendi signOut() çağrısı, anlık olarak
    // authStateChanges()'i null yayınlatıp router'ı hemen login'e
    // yönlendiriyor.
    try { await _googleSignIn.signOut(); } catch (e, s) { debugPrint('[hesapSil.googleSignOut] $e\n$s'); }
    try { await auth.signOut(); } catch (e, s) { debugPrint('[hesapSil.signOut] $e\n$s'); }
  }

  Future<bool> profilTamamlandiMi(String uid) async {
    final doc = await firestore
        .collection(Collections.kullanicilar)
        .doc(uid)
        .get();
    return doc.data()?['profilTamamlandi'] == true;
  }

  static String hataMesaji(String code) {
    switch (code) {
      case 'user-not-found': return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password': return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'invalid-email': return 'Geçersiz e-posta adresi.';
      case 'email-already-in-use': return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password': return 'Şifre çok zayıf. Daha güçlü bir şifre deneyin.';
      case 'user-disabled': return 'Bu hesap devre dışı bırakılmış.';
      case 'invalid-verification-code': return 'Doğrulama kodu hatalı.';
      case 'invalid-phone-number': return 'Geçersiz telefon numarası.';
      case 'too-many-requests': return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed': return 'İnternet bağlantınızı kontrol edin.';
      case 'email-not-verified': return 'Emailinizi doğrulamadan giriş yapamazsınız.';
      case 'google-sign-in-cancelled': return 'Google girişi iptal edildi.';
      case 'requires-recent-login': return 'Güvenlik için tekrar giriş yapmanız gerekiyor.';
      default: return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}