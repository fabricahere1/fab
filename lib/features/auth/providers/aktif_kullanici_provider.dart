// lib/features/auth/providers/aktif_kullanici_provider.dart
//
// Firebase Auth'un User/currentUserProvider/authStateProvider'ının yerini
// alıyor. Google/telefon/e-posta girişi artık Firebase Auth'u tetiklemiyor
// (sadece Go backend'den JWT alıyor), "ben kimim" bilgisini
// SharedPreferences'a kaydedilen kullanıcı verisinden okuyoruz.
//
// AktifKullanici'nin alan adları (uid/displayName/email) KASITLI OLARAK
// Firebase'in User sınıfıyla aynı — uygulama genelinde 25+ dosya
// `ref.watch(currentUserProvider)?.uid` gibi erişiyor, alan adlarını
// Firebase'inkiyle aynı tutmak o dosyaların HİÇBİRİNİ değiştirmeden
// çalışmasını sağlıyor.

import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'aktif_kullanici_provider.g.dart';

class AktifKullanici {
  final String uid;
  final String? displayName;
  final String? email;

  AktifKullanici({required this.uid, this.displayName, this.email});

  /// Backend'den dönen {"id": ..., "adSoyad": ..., "email": ...} şeklini
  /// okur — alan adları backend'de Türkçe, burada Firebase uyumlu.
  factory AktifKullanici.fromJson(Map<String, dynamic> json) {
    return AktifKullanici(
      uid: json['id'] as String,
      displayName: json['adSoyad'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': uid,
    'adSoyad': displayName,
    'email': email,
  };
}

const _kullaniciKey = 'v3_aktif_kullanici';

/// Login sonrası backend'den dönen kullanici map'ini kaydeder.
Future<void> aktifKullaniciKaydet(Map<String, dynamic> kullanici) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kullaniciKey, jsonEncode(kullanici));
}

/// Çıkış yapılınca çağrılır.
Future<void> aktifKullaniciSil() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kullaniciKey);
}

/// Eski authStateProvider'ın (Firebase'in Stream&lt;User?&gt;'ı) yerini
/// alıyor — AsyncValue
/// tabanlı olması router'ın (`ref.listen`/`ref.read(...).isLoading` vb.)
/// aynı şekilde çalışmasını sağlıyor.
@riverpod
class AktifKullaniciNotifier extends _$AktifKullaniciNotifier {
  @override
  Future<AktifKullanici?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kullaniciKey);
    if (raw == null) return null;
    return AktifKullanici.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> yenile() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Eski `currentUser` (sync, nullable) provider'ının BİREBİR yerini alıyor
/// — uygulama genelindeki `ref.watch(currentUserProvider)?.uid` gibi
/// çağrılar hiç değişmeden çalışmaya devam ediyor.
@riverpod
AktifKullanici? currentUser(Ref ref) {
  return ref.watch(aktifKullaniciProvider).value;
}
