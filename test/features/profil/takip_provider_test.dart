import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iste_v3/features/auth/providers/auth_provider.dart';
import 'package:iste_v3/features/profil/data/kullanici_repository.dart';
import 'package:iste_v3/features/profil/providers/profil_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockKullaniciRepository extends Mock implements KullaniciRepository {}

class _MockUser extends Mock implements User {}

void main() {
  const benimUid = 'uidA';
  const takipEdilenId = 'uidB';

  late _MockKullaniciRepository mockRepo;
  late _MockUser mockUser;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockKullaniciRepository();
    mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn(benimUid);

    container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        kullaniciRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
      '1) optimistik değer true iken, ham stream HENÜZ HİÇ değer vermeden '
      'bile takipEdiyorMu true döner (optimistik önceliklidir)', () {
    final controller = StreamController<bool>();
    addTearDown(controller.close);
    when(() => mockRepo.takipEdiyorMu(
          takipciId: any(named: 'takipciId'),
          takipEdilenId: any(named: 'takipEdilenId'),
        )).thenAnswer((_) => controller.stream);

    container.read(optimistikTakipProvider.notifier).takipEt(takipEdilenId);

    // hamAsync henüz AsyncLoading (controller hiç emit etmedi) — buna
    // rağmen optimistik değer öncelikli olduğu için senkron true dönmeli.
    expect(container.read(takipEdiyorMuProvider(takipEdilenId)), isTrue);
  });

  test(
      '2) optimistik değer null iken, ham stream\'in gerçek değeri (true) '
      'döndürülür', () async {
    when(() => mockRepo.takipEdiyorMu(
          takipciId: any(named: 'takipciId'),
          takipEdilenId: any(named: 'takipEdilenId'),
        )).thenAnswer((_) => Stream.value(true));

    // autoDispose'un, .future tamamlanır tamamlanmaz (dinleyici yokken)
    // provider'ı yok etmesini önlemek için — üretimde widget'ın watch
    // etmesinin karşılığı.
    final sub =
        container.listen(takipEdiyorMuProvider(takipEdilenId), (_, _) {});
    addTearDown(sub.close);

    // Ham stream'in ilk değerinin AsyncValue'ya yansımasını bekle.
    await container.read(takipEdiyorMuHamProvider(takipEdilenId).future);

    expect(container.read(takipEdiyorMuProvider(takipEdilenId)), isTrue);
  });

  test(
      '3) optimistik değer false iken (henüz takip edilmiyor "yaması"), ham '
      'stream true dönse BİLE takipEdiyorMu false döner — optimistik null '
      'olmadığı sürece (false dahil) ham\'ı hep ezer', () async {
    when(() => mockRepo.takipEdiyorMu(
          takipciId: any(named: 'takipciId'),
          takipEdilenId: any(named: 'takipEdilenId'),
        )).thenAnswer((_) => Stream.value(true));

    final sub =
        container.listen(takipEdiyorMuProvider(takipEdilenId), (_, _) {});
    addTearDown(sub.close);

    await container.read(takipEdiyorMuHamProvider(takipEdilenId).future);
    container
        .read(optimistikTakipProvider.notifier)
        .takipiBirak(takipEdilenId);

    // Kod: optimistik ?? hamAsync.value ?? false — `??` yalnızca null'da
    // devreye girer, `false` bir null DEĞİLDİR — bu yüzden optimistik=false,
    // ham=true olsa bile sonuç false olmalı.
    expect(container.read(takipEdiyorMuProvider(takipEdilenId)), isFalse);
  });

  test(
      '4) takipEdiyorMuHam, optimistikTakipProvider\'a HİÇ bağımlı değil — '
      'flicker bug\'ının regresyon testi: optimistik değer kaç kez '
      'değişirse değişsin, repository.takipEdiyorMu() yalnızca BİR KEZ '
      'çağrılmalı (ham stream yeniden abone olmamalı)', () async {
    when(() => mockRepo.takipEdiyorMu(
          takipciId: any(named: 'takipciId'),
          takipEdilenId: any(named: 'takipEdilenId'),
        )).thenAnswer((_) => Stream.value(false));

    // takipEdiyorMuProvider'ı canlı tutan bir dinleyici — autoDispose'un
    // testler arasında devreden çıkmasını önler, üretimdeki widget'ın
    // watch etmesini simüle eder.
    final sub =
        container.listen(takipEdiyorMuProvider(takipEdilenId), (_, _) {});
    addTearDown(sub.close);

    await container.read(takipEdiyorMuHamProvider(takipEdilenId).future);

    container.read(optimistikTakipProvider.notifier).takipEt(takipEdilenId);
    container.read(takipEdiyorMuProvider(takipEdilenId));

    container
        .read(optimistikTakipProvider.notifier)
        .takipiBirak(takipEdilenId);
    container.read(takipEdiyorMuProvider(takipEdilenId));

    container.read(optimistikTakipProvider.notifier).temizle(takipEdilenId);
    container.read(takipEdiyorMuProvider(takipEdilenId));

    // Optimistik değer üç kez değişti (true → false → temizlendi) ama
    // repository.takipEdiyorMu() yalnızca BİR KEZ çağrılmış olmalı —
    // ham stream'in kendi aboneliği yeniden kurulmadı.
    verify(() => mockRepo.takipEdiyorMu(
          takipciId: any(named: 'takipciId'),
          takipEdilenId: any(named: 'takipEdilenId'),
        )).called(1);
  });
}
