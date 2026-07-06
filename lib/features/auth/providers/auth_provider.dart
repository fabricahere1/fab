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
      final credential = await _repo.telefonIleGiris(
        verificationId: verificationId,
        smsKodu: smsKodu,
      );
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.basarili(credential.user?.uid ?? '');
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) state = const AsyncData(null);
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (e) {
      if (ref.mounted) state = const AsyncData(null);
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
      await _repo.emailIleYenidenGiris(email: email, sifre: sifre);
      return AuthSonuc.basarili('');
    } on FirebaseAuthException catch (e) {
      return AuthSonuc.hata(AuthRepository.hataMesaji(e.code));
    } catch (_) {
      return AuthSonuc.hata('Kimlik doğrulama başarısız.');
    }
  }

  Future<AuthSonuc> googleIleYenidenGiris() async {
    try {
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