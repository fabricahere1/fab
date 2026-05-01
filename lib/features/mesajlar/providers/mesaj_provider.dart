import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/mesaj_repository.dart';
import '../domain/mesaj_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/data/kullanici_repository.dart';
import '../../bildirimler/data/bildirim_repository.dart';
import '../../../shared/constants/app_constants.dart';

part 'mesaj_provider.g.dart';

// ── Sohbet listesi ────────────────────────────────────────────────────────────

@riverpod
Stream<List<SohbetModel>> sohbetler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(mesajRepositoryProvider).sohbetlerStream(uid);
}

// ── Okunmamış sayısı ──────────────────────────────────────────────────────────

@riverpod
int okunmamisSayi(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return 0;
  final sohbetListesi = ref.watch(sohbetlerProvider).value ?? [];
  int toplam = 0;
  for (final s in sohbetListesi) {
    if (s.gizliMi(uid)) continue;
    toplam += s.okunmamisSayisi(uid);
  }
  return toplam;
}

// ── Karşı kullanıcı adı provider ─────────────────────────────────────────────

@riverpod
Stream<String> karsiKullaniciAd(Ref ref, String uid) {
  if (uid.isEmpty) return Stream.value('Kullanıcı');
  return ref
      .watch(kullaniciRepositoryProvider)
      .kullaniciDataStream(uid)
      .map((data) {
    if (data == null) return 'Kullanıcı';
    final adSoyad = data['adSoyad'] as String? ?? '';
    if (adSoyad.isNotEmpty) return adSoyad;
    final displayName = data['displayName'] as String? ?? '';
    return displayName.isNotEmpty ? displayName : 'Kullanıcı';
  });
}

// ── Sohbet ekranı state ───────────────────────────────────────────────────────

class SohbetEkraniState {
  final Map<String, Map<String, dynamic>> mesajMap;
  final List<Map<String, dynamic>> siraliMesajlar;
  final bool yukleniyor;
  final bool gonderiyor;
  final bool dahaFazlaVar;
  final DateTime? enEskiZaman;

  const SohbetEkraniState({
    this.mesajMap = const {},
    this.siraliMesajlar = const [],
    this.yukleniyor = true,
    this.gonderiyor = false,
    this.dahaFazlaVar = true,
    this.enEskiZaman,
  });

  SohbetEkraniState copyWith({
    Map<String, Map<String, dynamic>>? mesajMap,
    List<Map<String, dynamic>>? siraliMesajlar,
    bool? yukleniyor,
    bool? gonderiyor,
    bool? dahaFazlaVar,
    DateTime? enEskiZaman,
  }) =>
      SohbetEkraniState(
        mesajMap: mesajMap ?? this.mesajMap,
        siraliMesajlar: siraliMesajlar ?? this.siraliMesajlar,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        gonderiyor: gonderiyor ?? this.gonderiyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        enEskiZaman: enEskiZaman ?? this.enEskiZaman,
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
      _okunduTimer?.cancel();
    });

    return const SohbetEkraniState();
  }

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  void _mesajlariDinle() {
    _mesajSub?.cancel();
    _mesajSub = _repo.mesajlarStream(sohbetId: _sohbetId).listen((snap) {
      final yeniMap = Map<String, Map<String, dynamic>>.from(state.mesajMap);
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['zaman'] == null) continue;
        yeniMap[doc.id] = {...data, 'id': doc.id};
      }
      final snapIds = snap.docs.map((d) => d.id).toSet();
      yeniMap.removeWhere((id, _) => !snapIds.contains(id));

      DateTime? enEskiZaman = state.enEskiZaman;
      if (snap.docs.isNotEmpty) {
        final sonData = snap.docs.last.data() as Map<String, dynamic>;
        final ts = sonData['zaman'];
        if (ts is Timestamp) enEskiZaman = ts.toDate();
      }
      state = state.copyWith(
        mesajMap: yeniMap,
        siraliMesajlar: _sirala(yeniMap),
        yukleniyor: false,
        dahaFazlaVar: snap.docs.length >= Pagination.mesajSayfaBoyutu,
        enEskiZaman: enEskiZaman,
      );

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
    _okunduTimer = Timer(const Duration(milliseconds: 500), _okunduIsaretle);
  }

  Future<void> _okunduIsaretle() async {
    try {
      await _repo.okunduIsaretle(sohbetId: _sohbetId, kullaniciId: _benimId);
    } catch (_) {}
  }

  List<Map<String, dynamic>> _sirala(Map<String, Map<String, dynamic>> map) {
    final liste = map.values.toList();
    liste.sort((a, b) {
      int msA = 0, msB = 0;
      final zA = a['zaman'];
      final zB = b['zaman'];
      if (zA is Timestamp) {
        msA = zA.millisecondsSinceEpoch;
      } else if (zA is DateTime) msA = zA.millisecondsSinceEpoch;
      if (zB is Timestamp) {
        msB = zB.millisecondsSinceEpoch;
      } else if (zB is DateTime) msB = zB.millisecondsSinceEpoch;
      return msB.compareTo(msA);
    });
    return liste;
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor || !state.dahaFazlaVar || state.enEskiZaman == null) return;
    final snap = await _repo.eskiMesajlariGetir(
      sohbetId: _sohbetId,
      sonZaman: state.enEskiZaman!,
    );
    final yeniMap = Map<String, Map<String, dynamic>>.from(state.mesajMap);
    DateTime? enEskiZaman = state.enEskiZaman;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['zaman'] == null) continue;
      if (!yeniMap.containsKey(doc.id)) {
        yeniMap[doc.id] = {...data, 'id': doc.id};
      }
    }
    if (snap.docs.isNotEmpty) {
      final sonData = snap.docs.last.data() as Map<String, dynamic>;
      final ts = sonData['zaman'];
      if (ts is Timestamp) enEskiZaman = ts.toDate();
    }
    state = state.copyWith(
      mesajMap: yeniMap,
      siraliMesajlar: _sirala(yeniMap),
      dahaFazlaVar: snap.docs.length >= Pagination.mesajSayfaBoyutu,
      enEskiZaman: enEskiZaman,
    );
  }

  Future<void> mesajGonder({
    required String metin,
    required String karsiKullaniciId,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
    String tip = 'mesaj',
  }) async {
    if (metin.trim().isEmpty || state.gonderiyor) return;
    final benimAd = await _getBenimAd();
    state = state.copyWith(gonderiyor: true);
    try {
      await _repo.mesajGonder(
        sohbetId: _sohbetId,
        gondereId: _benimId,
        karsiId: karsiKullaniciId,
        ilanId: ilanId,
        ilanBaslik: ilanBaslik,
        ilanResimUrl: ilanResimUrl,
        metin: metin.trim(),
        tip: tip,
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

  Future<void> resimGonder({
    required File dosya,
    required String karsiKullaniciId,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
  }) async {
    if (state.gonderiyor) return;
    final benimAd = await _getBenimAd();
    state = state.copyWith(gonderiyor: true);
    try {
      final url = await _repo.resimYukle(dosya: dosya, gondereId: _benimId);
      await _repo.mesajGonder(
        sohbetId: _sohbetId,
        gondereId: _benimId,
        karsiId: karsiKullaniciId,
        ilanId: ilanId,
        ilanBaslik: ilanBaslik,
        ilanResimUrl: ilanResimUrl,
        metin: '📷 Fotoğraf',
        tip: 'resim',
        resimUrl: url,
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
    } catch (e) {
      if (kDebugMode) print('resimGonder hata: $e');
    } finally {
      if (ref.mounted) state = state.copyWith(gonderiyor: false);
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
    final yeniMap = Map<String, Map<String, dynamic>>.from(state.mesajMap)
      ..remove(mesajId);
    state = state.copyWith(
      mesajMap: yeniMap,
      siraliMesajlar: _sirala(yeniMap),
    );
  }

  Future<String> _getBenimAd() async {
    try {
      final doc = await ref
          .read(kullaniciRepositoryProvider)
          .kullaniciGetir(_benimId)
          .timeout(const Duration(seconds: 5));
      final adSoyad = doc?.adSoyad ?? '';
      if (adSoyad.isNotEmpty) return adSoyad;
      return ref.read(currentUserProvider)?.displayName ?? '';
    } catch (_) {
      return ref.read(currentUserProvider)?.displayName ?? '';
    }
  }

  String get sohbetId => _sohbetId;
}

@riverpod
Stream<Map<String, dynamic>?> kullaniciProfil(Ref ref, String uid) {
  return ref.watch(kullaniciRepositoryProvider).kullaniciDataStream(uid);
}

@riverpod
Stream<Map<String, dynamic>?> benimProfil(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(kullaniciRepositoryProvider).kullaniciDataStream(uid);
}
