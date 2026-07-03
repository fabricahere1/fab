import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bekleyen_bildirim_provider.g.dart';

/// Cold-start bildirimi — uygulama kapalıyken tıklanan bildirim.
/// HomeScreen açılınca okur ve null'a sıfırlar.
@Riverpod(keepAlive: true)
class BekleyenBildirim extends _$BekleyenBildirim {
  @override
  RemoteMessage? build() => null;

  void set(RemoteMessage message) => state = message;
  void temizle() => state = null;
}
