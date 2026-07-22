import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/features/profil/data/kullanici_repository.dart';
import 'package:mocktail/mocktail.dart';

// takipEt()/takipiBirak() ne storage ne auth çağırıyor — bu yüzden bu
// ikisi hiç kullanılmayan, yalnızca constructor'ı doldurmak için gereken
// mock'lar (mocktail: gerçek Firebase başlatmaya gerek kalmadan).
class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late KullaniciRepository repo;

  const takipciId = 'uidA'; // takip eden
  const takipEdilenId = 'uidB'; // takip edilen
  final takipId = '${takipciId}_$takipEdilenId';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = KullaniciRepository(
      firestore: firestore,
      storage: _MockFirebaseStorage(),
      auth: _MockFirebaseAuth(),
    );
  });

  group('takipEt', () {
    test('1) doğru koleksiyona, doğru doküman ID\'siyle, doğru alanlarla '
        'bir doküman oluşturur', () async {
      await repo.takipEt(takipciId: takipciId, takipEdilenId: takipEdilenId);

      final snap =
          await firestore.collection('takipler').doc(takipId).get();

      expect(snap.exists, isTrue);
      final d = snap.data()!;
      expect(d['takipciId'], takipciId);
      expect(d['takipEdilenId'], takipEdilenId);
      expect(d['tarih'], isNotNull);
    });

    test('3) zaten var olan bir takip ilişkisinde tekrar çağrılırsa '
        '(idempotency) — transaction içindeki "if (snap.exists) return;" '
        'guard\'ı sayesinde ikinci çağrı hiçbir şeyi değiştirmez', () async {
      await repo.takipEt(takipciId: takipciId, takipEdilenId: takipEdilenId);
      final ilkSnap =
          await firestore.collection('takipler').doc(takipId).get();
      final ilkTarih = ilkSnap.data()!['tarih'];

      // İkinci çağrı — hata fırlatmamalı, mevcut dokümana dokunmamalı.
      await repo.takipEt(takipciId: takipciId, takipEdilenId: takipEdilenId);
      final ikinciSnap =
          await firestore.collection('takipler').doc(takipId).get();

      expect(ikinciSnap.exists, isTrue);
      // 'tarih' İLK yazımdaki değerle AYNI kalmalı — ikinci çağrı guard'a
      // takılıp transaction içinde erken return ettiği için üzerine
      // yazılmamış olmalı.
      expect(ikinciSnap.data()!['tarih'], ilkTarih);
    });

    test('4) kendi kendini takip etme — repository seviyesinde bir kontrol '
        'YOK (kod okundu: takipEt() içinde takipciId==takipEdilenId '
        'kontrolü bulunmuyor) — bu güvenlik, client kodunun değil, '
        'firestore.rules\'ın (takipEdilenId != request.auth.uid) '
        'sorumluluğunda. Bu yüzden bu senaryo burada test EDİLMİYOR, '
        'kapsam dışı.', () {}, skip: 'Kasıtlı: bkz. yorum — rules\'ın işi.');
  });

  group('takipiBirak', () {
    test('2) var olan bir takip dokümanını gerçekten siler', () async {
      // Önce var olan bir ilişki kur.
      await firestore.collection('takipler').doc(takipId).set({
        'takipciId': takipciId,
        'takipEdilenId': takipEdilenId,
        'tarih': DateTime.now(),
      });

      await repo.takipiBirak(
          takipciId: takipciId, takipEdilenId: takipEdilenId);

      final snap =
          await firestore.collection('takipler').doc(takipId).get();
      expect(snap.exists, isFalse);
    });

    test('var olmayan bir ilişkiyi silmeye çalışmak hata fırlatmaz '
        '(guard: "if (!snap.exists) return;")', () async {
      await expectLater(
        repo.takipiBirak(takipciId: takipciId, takipEdilenId: takipEdilenId),
        completes,
      );
    });
  });
}
