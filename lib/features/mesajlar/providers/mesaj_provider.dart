import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/mesaj_repository.dart';
import '../domain/mesaj_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/data/kullanici_repository.dart';
import '../../bildirimler/data/bildirim_repository.dart';
import '../../bildirimler/domain/bildirim_model.dart';
import '../../../shared/constants/app_constants.dart';

part 'mesaj_provider.g.dart';

// ── Sohbet listesi ────────────────────────────────────────────────────────────
// SohbetModel döndürür — raw map yok

@riverpod
Stream<List<SohbetModel>> sohbetler(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(mesajRepositoryProvider).sohbetlerStream(uid);
}

// ── Okunmamış sayısı ──────────────────────────────────────────────────────────
// SohbetModel'den hesaplanır

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
// Presentation'da doğrudan çağrılır — tek kaynak profil koleksiyonu

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

// DocumentSnapshot YOK — cursor olarak DateTime kullanılır
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
    // repository Timestamp → DateTime dönüşümünü yaptı — burada ham tip yok
    _mesajSub = _repo.mesajlarStream(sohbetId: _sohbetId).listen((mesajlar) {
      final yeniMap = Map<String, Map<String, dynamic>>.from(state.mesajMap);
      final gelenIds = <String>{};
      for (final mesaj in mesajlar) {
        final id = mesaj['id'] as String?;
        if (id == null || mesaj['zaman'] == null) continue;
        yeniMap[id] = mesaj;
        gelenIds.add(id);
      }
      yeniMap.removeWhere((id, _) => !gelenIds.contains(id));

      // zaman artık DateTime — Timestamp yok
      DateTime? enEskiZaman = state.enEskiZaman;
      if (mesajlar.isNotEmpty) {
        final sonZaman = mesajlar.last['zaman'];
        if (sonZaman is DateTime) enEskiZaman = sonZaman;
      }
      state = state.copyWith(
        mesajMap: yeniMap,
        siraliMesajlar: _sirala(yeniMap),
        yukleniyor: false,
        dahaFazlaVar: mesajlar.length >= Pagination.mesajSayfaBoyutu,
        enEskiZaman: enEskiZaman,
      );

      if (mesajlar.isNotEmpty) {
        final sonMesajId = mesajlar.first['id'] as String?;
        if (sonMesajId != null && _sonOkunduMesajId != sonMesajId) {
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
      // repository'den DateTime geliyor — Timestamp yok
      final zA = a['zaman'] as DateTime?;
      final zB = b['zaman'] as DateTime?;
      final msA = zA?.millisecondsSinceEpoch ?? 0;
      final msB = zB?.millisecondsSinceEpoch ?? 0;
      return msB.compareTo(msA);
    });
    return liste;
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor || !state.dahaFazlaVar || state.enEskiZaman == null) return;
    // repository DateTime cursor kullanıyor — Timestamp yok
    final mesajlar = await _repo.eskiMesajlariGetir(
      sohbetId: _sohbetId,
      sonZaman: state.enEskiZaman!,
    );
    final yeniMap = Map<String, Map<String, dynamic>>.from(state.mesajMap);
    DateTime? enEskiZaman = state.enEskiZaman;
    for (final mesaj in mesajlar) {
      final id = mesaj['id'] as String?;
      if (id == null || mesaj['zaman'] == null) continue;
      if (!yeniMap.containsKey(id)) {
        yeniMap[id] = mesaj;
      }
    }
    if (mesajlar.isNotEmpty) {
      final sonZaman = mesajlar.last['zaman'];
      if (sonZaman is DateTime) enEskiZaman = sonZaman;
    }
    state = state.copyWith(
      mesajMap: yeniMap,
      siraliMesajlar: _sirala(yeniMap),
      dahaFazlaVar: mesajlar.length >= Pagination.mesajSayfaBoyutu,
      enEskiZaman: enEskiZaman,
    );
  }

  // gondereAd ve karsiAd artık YOK — profil koleksiyonundan gelir
  Future<void> mesajGonder({
    required String metin,
    required String karsiKullaniciId,
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
        karsiId: karsiKullaniciId,
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

  Future<void> anlasmaKabul({
    required String mesajId,
    required String gondereId,
    String ilanBaslik = '',
    String ilanSahibiAd = '',
  }) async {
    try {
      await _repo.anlasmaKabul(sohbetId: _sohbetId, mesajId: mesajId);
      await ref.read(bildirimRepositoryProvider).bildirimOlustur(
        kullaniciId: gondereId,
        tip: BildirimTip.mesaj,
        baslik: ilanBaslik.isNotEmpty ? ilanBaslik : 'Anlaşma',
        icerik: '✅ Anlaşma teklifiniz kabul edildi!',
        hedefId: _sohbetId,
        gondereId: _benimId,
        gondereAd: ilanSahibiAd,
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
      // currentUserProvider — Firebase direkt erişim yok
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
