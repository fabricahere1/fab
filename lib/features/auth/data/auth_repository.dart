import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/constants/app_constants.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
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

  Future<void> sifreSifirlamaGonder(String email) async {
    await auth.sendPasswordResetEmail(email: email.trim());
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

  // FCM metodları buradan tamamen kaldırıldı.
  // Token yönetimi artık FcmService'in sorumluluğundadır.
  // authStateChanges() → FcmService dinler → token kaydet/sil.

  Future<void> cikisYap() async {
    // FCM token silme FcmService tarafından authStateChanges üzerinden
    // otomatik yapılır (user == null olunca). Burada sadece oturumu kapatırız.
    try { await _googleSignIn.signOut(); } catch (_) {}
    await auth.signOut();
  }

  // ── Re-authentication ─────────────────────────────────

  Future<void> emailIleYenidenGiris({
    required String email,
    required String sifre,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: sifre.trim(),
    );
    await auth.currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> googleIleYenidenGiris() async {
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
    await auth.currentUser!.reauthenticateWithCredential(credential);
  }

  // ── Hesap Sil ─────────────────────────────────────────

  Future<void> hesapSil() async {
    final user = auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final batch = firestore.batch();

    batch.delete(
        firestore.collection(Collections.kullanicilar).doc(uid));

    final ilanlarSnap = await firestore
        .collection(Collections.ilanlar)
        .where('kullaniciId', isEqualTo: uid)
        .get();
    for (final doc in ilanlarSnap.docs) {
      batch.delete(doc.reference);
    }

    final favorilerSnap = await firestore
        .collection(Collections.favoriler)
        .where('kullaniciId', isEqualTo: uid)
        .get();
    for (final doc in favorilerSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    try { await _googleSignIn.signOut(); } catch (_) {}
    await user.delete();
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
      case 'user-not-found':        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'invalid-email':         return 'Geçersiz e-posta adresi.';
      case 'email-already-in-use':  return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':         return 'Şifre çok zayıf. Daha güçlü bir şifre deneyin.';
      case 'user-disabled':         return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':     return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':return 'İnternet bağlantınızı kontrol edin.';
      case 'email-not-verified':    return 'Emailinizi doğrulamadan giriş yapamazsınız.';
      case 'google-sign-in-cancelled': return 'Google girişi iptal edildi.';
      case 'requires-recent-login': return 'Güvenlik için tekrar giriş yapmanız gerekiyor.';
      default:                      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}