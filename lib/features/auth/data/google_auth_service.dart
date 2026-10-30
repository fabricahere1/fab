// lib/features/auth/data/google_auth_service.dart
//
// Tek bir paylaşılan GoogleSignIn örneği — giriş ve çıkış akışının AYNI
// örneği kullanması gerekiyor (ayrı örnekler kullanılırsa çıkışta
// signOut() gerçek giriş örneğine yansımıyor, bir dahaki girişte hesap
// seçici çıkmadan doğrudan önceki hesapla giriliyor). Çekmece'deki
// (ikinciel) aynı dosyanın birebir aynısı.

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static GoogleSignIn get instance => _googleSignIn;
}
