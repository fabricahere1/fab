import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

@riverpod
User? currentUser(Ref ref) {
  // authStateProvider stream'inden gelir — FirebaseAuth direkt erişim yok
  return ref.watch(authStateProvider).value;
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
      final credential = await _repo.emailIleGiris(
        email: email,
        sifre: sifre,
      );
      if (credential.user == null) {
        if (ref.mounted) state = const AsyncData(null);
        return AuthSonuc.hata('Giriş başarısız.');
      }
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata('Beklenmeyen bir hata oluştu.');
    }
  }

  Future<AuthSonuc> emailIleKayit({
    required String adSoyad,
    required String email,
    required String sifre,
  }) async {
    state = const AsyncLoading();
    try {
      final credential = await _repo.emailIleKayit(
        adSoyad: adSoyad,
        email: email,
        sifre: sifre,
      );
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(credential.user?.uid ?? '');
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata('Beklenmeyen bir hata oluştu.');
    }
  }

  Future<AuthSonuc> googleIleGiris() async {
    state = const AsyncLoading();
    try {
      final credential = await _repo.googleIleGiris();
      if (credential.user == null) {
        if (ref.mounted) state = const AsyncData(null);
        return AuthSonuc.hata('Google girişi başarısız.');
      }
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata('Google ile giriş yapılamadı.');
    }
  }

  Future<AuthSonuc> sifreSifirla(String email) async {
    state = const AsyncLoading();
    try {
      await _repo.sifreSifirlamaGonder(email);
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili('');
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata('Şifre sıfırlama başarısız.');
    }
  }

  Future<void> cikisYap() async {
    await _repo.cikisYap();
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