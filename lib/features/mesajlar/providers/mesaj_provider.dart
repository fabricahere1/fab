import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/mesaj_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/data/kullanici_repository.dart';
import '../../bildirimler/data/bildirim_repository.dart';
import '../../bildirimler/domain/bildirim_model.dart';
import '../../../shared/constants/app_constants.dart';

part 'mesaj_provider.g.dart';

@riverpod
Stream<List<Map<String, dynamic>>> sohbetler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(mesajRepositoryProvider).sohbetlerStream(uid);
}

@riverpod
int okunmamisSayi(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return 0;
  final sohbetListesi = ref.watch(sohbetlerProvider).value ?? [];
  int toplam = 0;
  for (final s in sohbetListesi) {
    final gizli = (s['gizli'] as Map<String, dynamic>?) ?? {};
    final gizliDeger = gizli[uid];
    if (gizliDeger != null) {
      if (gizliDeger is bool && gizliDeger == true) continue;
      if (gizliDeger is Timestamp) {
        final sonMesajZamani = s['sonMesajZamani'] as Timestamp?;
        if (sonMesajZamani == null) continue;
        if (!sonMesajZamani.toDate().isAfter(gizliDeger.toDate())) continue;
      }
    }
    final okunmamis = (s['okunmamis'] as Map<String, dynamic>?) ?? {};
    toplam += ((okunmamis[uid] as num?)?.toInt() ?? 0);
  }
  return toplam;
}

class SohbetEkraniState {
  final Map<String, Map<String, dynamic>> mesajMap;
  final List<Map<String, dynamic>> siraliMesajlar;
  final bool yukleniyor;
  final bool gonderiyor;
  final bool dahaFazlaVar;
  final DocumentSnapshot? enEskiDoc;

  const SohbetEkraniState({
    this.mesajMap = const {},
    this.siraliMesajlar = const [],
    this.yukleniyor = true,
    this.gonderiyor = false,
    this.dahaFazlaVar = true,
    this.enEskiDoc,
  });

  SohbetEkraniState copyWith({
    Map<String, Map<String, dynamic>>? mesajMap,
    List<Map<String, dynamic>>? siraliMesajlar,
    bool? yukleniyor,
    bool? gonderiyor,
    bool? dahaFazlaVar,
    DocumentSnapshot? enEskiDoc,
  }) =>
      SohbetEkraniState(
        mesajMap: mesajMap ?? this.mesajMap,
        siraliMesajlar: siraliMesajlar ?? this.siraliMesajlar,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        gonderiyor: gonderiyor ?? this.gonderiyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        enEskiDoc: enEskiDoc ?? this.enEskiDoc,
      );
}

@riverpod
class SohbetNotifier extends _$SohbetNotifier {
  late String _sohbetId;
  late String _benimId;
  StreamSubscription? _mesajSub;

  Timer? _okunduTimer;
  String? _sonOkunduMesajId;

  @override
  SohbetEkraniState build({
    required String karsiKullaniciId,
    required String ilanId,
  }) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SohbetEkraniState();

    _benimId = user.uid;
    final ids = [_benimId, karsiKullaniciId]..sort();
    _sohbetId = '${ids[0]}_${ids[1]}_$ilanId';

    _mesajlariDinle();

    ref.onDispose(() {
      _mesajSub?.cancel();
      _mesajSub = null;
      _okunduTimer?.cancel();
      _okunduTimer = null;
    });

    return const SohbetEkraniState();
  }

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  void _mesajlariDinle() {
    _mesajSub?.cancel();

    final stream = _repo.mesajlarStream(sohbetId: _sohbetId);
    _mesajSub = stream.listen((snap) {
      final yeniMap =
          Map<String, Map<String, dynamic>>.from(state.mesajMap);
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['zaman'] == null) continue;
        yeniMap[doc.id] = {...data, 'id': doc.id};
      }
      final snapIds = snap.docs.map((d) => d.id).toSet();
      yeniMap.removeWhere((id, _) => !snapIds.contains(id));

      if (snap.docs.isNotEmpty) {
        state = state.copyWith(
          mesajMap: yeniMap,
          siraliMesajlar: _sirala(yeniMap),
          yukleniyor: false,
          dahaFazlaVar: snap.docs.length >= Pagination.mesajSayfaBoyutu,
          enEskiDoc: snap.docs.last,
        );
      } else {
        state = state.copyWith(
          mesajMap: yeniMap,
          siraliMesajlar: _sirala(yeniMap),
          yukleniyor: false,
          dahaFazlaVar: false,
        );
      }

      if (snap.docs.isNotEmpty) {
        final sonMesajId = snap.docs.first.id;
        if (_sonOkunduMesajId != sonMesajId) {
          _sonOkunduMesajId = sonMesajId;
          _okunduDebounce();
        }
      }
    });
  }

  void _okunduDebounce() {
    _okunduTimer?.cancel();
    _okunduTimer = Timer(const Duration(milliseconds: 500), () {
      _okunduIsaretle();
    });
  }

  Future<void> _okunduIsaretle() async {
    try {
      await _repo.okunduIsaretle(
        sohbetId: _sohbetId,
        kullaniciId: _benimId,
      );
    } catch (_) {}
  }

  List<Map<String, dynamic>> _sirala(
      Map<String, Map<String, dynamic>> map) {
    final liste = map.values.toList();
    liste.sort((a, b) {
      final zamanA = (a['zaman'] as Timestamp).millisecondsSinceEpoch;
      final zamanB = (b['zaman'] as Timestamp).millisecondsSinceEpoch;
      return zamanB.compareTo(zamanA);
    });
    return liste;
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor ||
        !state.dahaFazlaVar ||
        state.enEskiDoc == null) {
      return;
    }
    final snap = await _repo.eskiMesajlariGetir(
      sohbetId: _sohbetId,
      sonDoc: state.enEskiDoc!,
    );
    final yeniMap =
        Map<String, Map<String, dynamic>>.from(state.mesajMap);
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['zaman'] == null) continue;
      if (!yeniMap.containsKey(doc.id)) {
        yeniMap[doc.id] = {...data, 'id': doc.id};
      }
    }
    state = state.copyWith(
      mesajMap: yeniMap,
      siraliMesajlar: _sirala(yeniMap),
      dahaFazlaVar: snap.docs.length >= Pagination.mesajSayfaBoyutu,
      enEskiDoc: snap.docs.isNotEmpty ? snap.docs.last : state.enEskiDoc,
    );
  }

  Future<void> mesajGonder({
    required String metin,
    required String karsiKullaniciId,
    required String karsiAd,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
    String tip = 'mesaj',
    double? tutar,
  }) async {
    if (metin.trim().isEmpty || state.gonderiyor) return;

    final benimAd = await _getBenimAd();
    state = state.copyWith(gonderiyor: true);
    try {
      await _repo.mesajGonder(
        sohbetId: _sohbetId,
        gondereId: _benimId,
        gondereAd: benimAd,
        karsiId: karsiKullaniciId,
        karsiAd: karsiAd,
        ilanId: ilanId,
        ilanBaslik: ilanBaslik,
        ilanResimUrl: ilanResimUrl,
        metin: metin.trim(),
        tip: tip,
        tutar: tutar,
      );
      try {
        await ref.read(bildirimRepositoryProvider).mesajBildirimiGonder(
              aliciId: karsiKullaniciId,
              gondereId: _benimId,
              gondereAd: benimAd,
              ilanBaslik: ilanBaslik,
              sohbetId: _sohbetId,
            );
      } catch (_) {}
    } finally {
      if (ref.mounted) state = state.copyWith(gonderiyor: false);
    }
  }

  Future<void> anlasmaKabul({
    required String mesajId,
    required String gondereId,
    required String gondereAd,
  }) async {
    try {
      await _repo.anlasmaKabul(sohbetId: _sohbetId, mesajId: mesajId);
      // Anlaşmayı teklif edene bildirim gönder
      await ref.read(bildirimRepositoryProvider).bildirimOlustur(
        kullaniciId: gondereId,
        tip: BildirimTip.teklif,
        baslik: gondereAd.isNotEmpty ? gondereAd : 'Anlaşma',
        icerik: '✅ Anlaşma teklifiniz kabul edildi!',
        hedefId: _sohbetId,
        gondereId: _benimId,
        gondereAd: '',
      );
    } catch (e) {
      if (kDebugMode) print('anlasmaKabul hata: $e');
    }
  }

  Future<void> anlasmaRed({required String mesajId}) async {
    try {
      await _repo.anlasmaRed(sohbetId: _sohbetId, mesajId: mesajId);
    } catch (e) {
      if (kDebugMode) print('anlasmaRed hata: $e');
    }
  }

  Future<void> mesajSil({
    required String mesajId,
    required String metin,
  }) async {
    await _repo.mesajSil(
      sohbetId: _sohbetId,
      mesajId: mesajId,
      metin: metin,
    );
    final yeniMap =
        Map<String, Map<String, dynamic>>.from(state.mesajMap)
          ..remove(mesajId);
    state = state.copyWith(
      mesajMap: yeniMap,
      siraliMesajlar: _sirala(yeniMap),
    );
  }

  // ✅ Timeout eklendi — takılmayı önle
  Future<String> _getBenimAd() async {
    try {
      final doc = await ref
          .read(kullaniciRepositoryProvider)
          .kullaniciGetir(_benimId)
          .timeout(const Duration(seconds: 5));
      return doc?.adSoyad ?? '';
    } catch (_) {
      return '';
    }
  }

  String get sohbetId => _sohbetId;
}

@riverpod
Stream<Map<String, dynamic>?> kullaniciProfil(Ref ref, String uid) {
  return ref
      .watch(kullaniciRepositoryProvider)
      .kullaniciDataStream(uid);
}

@riverpod
Stream<Map<String, dynamic>?> benimProfil(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref
      .watch(kullaniciRepositoryProvider)
      .kullaniciDataStream(uid);
}