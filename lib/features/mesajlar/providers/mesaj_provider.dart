import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/utils/app_hata_yonetici.dart';
import '../data/mesaj_repository.dart';
import '../domain/mesaj_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_constants.dart';

export '../data/mesaj_repository.dart' show mesajRepositoryProvider;

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
// ✅ raw Map<String, dynamic> yerine typed MesajModel kullanıyor

class SohbetEkraniState {
  final Map<String, MesajModel> mesajMap;
  final List<MesajModel> siraliMesajlar;
  final bool yukleniyor;
  final bool gonderiyor;
  final bool dahaFazlaVar;
  final DateTime? enEskiZaman;
  final String? hata;

  const SohbetEkraniState({
    this.mesajMap = const {},
    this.siraliMesajlar = const [],
    this.yukleniyor = true,
    this.gonderiyor = false,
    this.dahaFazlaVar = true,
    this.enEskiZaman,
    this.hata,
  });

  SohbetEkraniState copyWith({
    Map<String, MesajModel>? mesajMap,
    List<MesajModel>? siraliMesajlar,
    bool? yukleniyor,
    bool? gonderiyor,
    bool? dahaFazlaVar,
    DateTime? enEskiZaman,
    String? hata,
    bool temizleHata = false,
  }) =>
      SohbetEkraniState(
        mesajMap: mesajMap ?? this.mesajMap,
        siraliMesajlar: siraliMesajlar ?? this.siraliMesajlar,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        gonderiyor: gonderiyor ?? this.gonderiyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        enEskiZaman: enEskiZaman ?? this.enEskiZaman,
        hata: temizleHata ? null : (hata ?? this.hata),
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

    _baslat(karsiKullaniciId);

    ref.onDispose(() {
      _mesajSub?.cancel();
      _okunduTimer?.cancel();
    });

    return const SohbetEkraniState();
  }

  Future<void> _baslat(String karsiKullaniciId) async {
    // mesajGonder() zaten batch içinde sohbet dokümanını merge:true ile
    // oluşturduğu için ayrıca bir "garanti" yazmasına gerek yok.
    // Direkt dinlemeye başlıyoruz — ilk temasta güvenlik kuralı (sohbetKatilimcisiMi)
    // doküman henüz yoksa false dönebilir, ama bu durumda mesajlar stream'i
    // boş kalır (hata vermez), ilk mesaj gönderilince doküman oluşur ve
    // stream otomatik güncellenir.
    if (ref.mounted) _mesajlariDinle();
  }

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  void _mesajlariDinle() {
    _mesajSub?.cancel();
    _mesajSub = _repo.mesajlarStream(sohbetId: _sohbetId).listen((mesajlar) {
      // ✅ Artık List<MesajModel> geliyor — Firestore tipi yok
      final yeniMap = Map<String, MesajModel>.from(state.mesajMap);

      // Gelen snapshot'taki mesajları güncelle
      for (final mesaj in mesajlar) {
        yeniMap[mesaj.id] = mesaj;
      }

      // Snapshot'ta olmayan (silinen) mesajları kaldır
      final snapIds = mesajlar.map((m) => m.id).toSet();
      yeniMap.removeWhere((id, _) => !snapIds.contains(id));

      // En eski zamanı cursor olarak sakla
      final enEskiZaman = mesajlar.isNotEmpty ? mesajlar.last.zaman : state.enEskiZaman;

      state = state.copyWith(
        mesajMap: yeniMap,
        siraliMesajlar: _sirala(yeniMap),
        yukleniyor: false,
        dahaFazlaVar: mesajlar.length >= Pagination.mesajSayfaBoyutu,
        enEskiZaman: enEskiZaman,
      );

      if (mesajlar.isNotEmpty) {
        final sonMesajId = mesajlar.first.id;
        if (_sonOkunduMesajId != sonMesajId) {
          _sonOkunduMesajId = sonMesajId;
          _okunduDebounce();
        }
      }
    }, onError: (hata, stack) {
      AppHataYonetici.logla(hata, stack, etiket: 'mesajlarStream');
      if (ref.mounted) {
        state = state.copyWith(
          yukleniyor: false,
          hata: 'Mesajlar yüklenemedi. Tekrar dene.',
        );
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

  // ✅ Timestamp yok — MesajModel.zaman zaten DateTime
  List<MesajModel> _sirala(Map<String, MesajModel> map) {
    final liste = map.values.toList();
    liste.sort((a, b) {
      final msA = a.zaman?.millisecondsSinceEpoch ?? 0;
      final msB = b.zaman?.millisecondsSinceEpoch ?? 0;
      return msB.compareTo(msA);
    });
    return liste;
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor || !state.dahaFazlaVar || state.enEskiZaman == null) return;

    // ✅ Artık List<MesajModel> geliyor
    final mesajlar = await _repo.eskiMesajlariGetir(
      sohbetId: _sohbetId,
      sonZaman: state.enEskiZaman!,
    );

    // SohbetNotifier autoDispose — kullanıcı await sürerken ekrandan
    // çıkarsa provider yok edilebilir, state'e dokunmadan önce kontrol et.
    if (!ref.mounted) return;

    final yeniMap = Map<String, MesajModel>.from(state.mesajMap);
    for (final mesaj in mesajlar) {
      if (!yeniMap.containsKey(mesaj.id)) {
        yeniMap[mesaj.id] = mesaj;
      }
    }

    final enEskiZaman = mesajlar.isNotEmpty ? mesajlar.last.zaman : state.enEskiZaman;

    state = state.copyWith(
      mesajMap: yeniMap,
      siraliMesajlar: _sirala(yeniMap),
      dahaFazlaVar: mesajlar.length >= Pagination.mesajSayfaBoyutu,
      enEskiZaman: enEskiZaman,
    );
  }

  Future<void> mesajGonder({
    required String metin,
    required String karsiKullaniciId,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
    String ilanSahibiId = '',
    String ilanTip = 'istek',
    String tip = 'mesaj',
  }) async {
    if (metin.trim().isEmpty || state.gonderiyor) return;
    final benimAd = await _getBenimAd();
    if (!ref.mounted) return;
    state = state.copyWith(gonderiyor: true);
    try {
      await _repo.mesajGonder(
        sohbetId: _sohbetId,
        gondereId: _benimId,
        karsiId: karsiKullaniciId,
        ilanId: ilanId,
        ilanBaslik: ilanBaslik,
        ilanResimUrl: ilanResimUrl,
        ilanSahibiId: ilanSahibiId,
        ilanTip: ilanTip,
        metin: metin.trim(),
        tip: tip,
      );
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'mesajGonder');
      if (ref.mounted) {
        state = state.copyWith(
          gonderiyor: false,
          hata: 'Mesaj gönderilemedi. Tekrar dene.',
        );
      }
      return;
    } finally {
      if (ref.mounted) state = state.copyWith(gonderiyor: false);
    }
    // Push bildirimi arka planda
    _repo.mesajBildirimiGonder(
      aliciId: karsiKullaniciId,
      gondereId: _benimId,
      gondereAd: benimAd,
      ilanBaslik: ilanBaslik,
      sohbetId: _sohbetId,
      metin: metin.trim(),
    ).catchError((_) {});
  }

  Future<void> resimGonder({
    required File dosya,
    required String karsiKullaniciId,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
    String ilanSahibiId = '',
    String ilanTip = 'istek',
  }) async {
    if (state.gonderiyor) return;
    final benimAd = await _getBenimAd();
    if (!ref.mounted) return;
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
        ilanSahibiId: ilanSahibiId,
        ilanTip: ilanTip,
        metin: '📷 Fotoğraf',
        tip: 'resim',
        resimUrl: url,
      );
    } catch (e) {
      if (kDebugMode) print('resimGonder hata: $e');
    } finally {
      if (ref.mounted) state = state.copyWith(gonderiyor: false);
    }
    // Push bildirimi artık burada beklenmiyor — fotoğraf zaten gönderildi,
    // buton serbest kaldı. Bildirim arka planda, hatasız şekilde devam eder.
    _repo.mesajBildirimiGonder(
      aliciId: karsiKullaniciId,
      gondereId: _benimId,
      gondereAd: benimAd,
      ilanBaslik: ilanBaslik,
      sohbetId: _sohbetId,
      metin: '📷 Fotoğraf',
    ).catchError((_) {});
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
    if (!ref.mounted) return;
    final yeniMap = Map<String, MesajModel>.from(state.mesajMap)
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

// ── İşlem durumu işlemleri ────────────────────────────────────────────────────

@riverpod
class IslemDurumuIslemleri extends _$IslemDurumuIslemleri {
  @override
  AsyncValue<void> build(String sohbetId) => const AsyncData(null);

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  Future<void> guncelle(String durum) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await _repo.islemDurumuGuncelle(sohbetId: sohbetId, durum: durum, yapanUid: uid);
  }

  Future<void> anlasildiIsaretle(String benimUid) async {
    await _repo.anlasildiIsaretle(sohbetId: sohbetId, benimUid: benimUid);
  }

  Future<void> teslimTamamla() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await _repo.teslimTamamla(sohbetId: sohbetId, yapanUid: uid);
  }
}

// ── Sohbet işlemleri ──────────────────────────────────────────────────────────

@riverpod
class SohbetIslemleri extends _$SohbetIslemleri {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  Future<void> gizle({
    required String sohbetId,
    required String kullaniciId,
  }) async {
    await _repo.sohbetiGizle(sohbetId: sohbetId, kullaniciId: kullaniciId);
  }

  Future<Map<String, dynamic>?> getir(String sohbetId) async {
    return _repo.sohbetGetir(sohbetId);
  }
}

// ── İşlem durumu stream provider'ları (islem_durumu_panel için) ──────────────
//
// Performans notu: eskiden bu 5 provider, AYNI sohbet dökümanını ayrı ayrı
// 5 kere dinliyordu (5 bağımsız Firestore listener'ı, her biri tüm
// dökümanı indirip sadece 1 alanını kullanıyordu). Artık tek bir dinleyici
// (sohbetDokumanProvider) var, diğerleri ondan türetiliyor — gerçek ağ/
// Firestore maliyeti 5'te 1'e indi, UI tarafında kullanım şekli (provider
// adları, .value ile okuma) hiç değişmedi.
//
// Not: Riverpod 3'te StreamProvider'ın .stream özelliği kaldırıldığı için,
// türetilmiş provider'lar StreamProvider.family DEĞİL, normal
// Provider.family olarak tanımlanıp AsyncValue.whenData() ile veri
// dönüştürüyor — bu, .stream'e hiç ihtiyaç duymadan, AsyncValue zincirini
// (loading/error/data) doğru şekilde taşıyor.

final sohbetDokumanProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, sohbetId) {
  return ref.read(mesajRepositoryProvider).sohbetDurumuStream(sohbetId);
});

final islemDurumuProvider =
    Provider.family<AsyncValue<Map<String, dynamic>>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId)).whenData(
      (d) => Map<String, dynamic>.from(d['islemDurumlari'] as Map? ?? {}));
});

final sohbetIlanSahibiIdProvider =
    Provider.family<AsyncValue<String>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId))
      .whenData((d) => d['ilanSahibiId'] as String? ?? '');
});

final sohbetIlanTipProvider =
    Provider.family<AsyncValue<String>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId))
      .whenData((d) => d['ilanTip'] as String? ?? 'istek');
});

final sohbetKullanicilarProvider =
    Provider.family<AsyncValue<List<String>>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId))
      .whenData((d) => List<String>.from(d['kullanicilar'] ?? []));
});

final sohbetIlanBaslikProvider =
    Provider.family<AsyncValue<String>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId))
      .whenData((d) => (d['ilanBaslik'] as String?) ?? '');
});