import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/utils/app_hata_yonetici.dart';
import '../data/mesaj_repository.dart';
import '../domain/mesaj_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';

export '../data/mesaj_repository.dart' show mesajRepositoryProvider;

part 'mesaj_provider.g.dart';

const _sohbetYenilemeAraligi = Duration(seconds: 15);

// ── Sohbet listesi ────────────────────────────────────────────────────────────
// Artık Stream DEĞİL (AWS backend'inde canlı akış yok) — periyodik
// yenileme (Çekmece'deki ve v3'ün diğer taşınmış özelliklerindeki aynı
// desen).

@Riverpod(keepAlive: true)
class Sohbetler extends _$Sohbetler {
  Timer? _zamanlayici;

  @override
  Future<List<SohbetModel>> build() async {
    ref.onDispose(() => _zamanlayici?.cancel());
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return [];

    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(_sohbetYenilemeAraligi, (_) => yenile());

    return ref.read(mesajRepositoryProvider).sohbetleriGetir();
  }

  Future<void> yenile() async {
    if (ref.read(currentUserProvider)?.uid == null) return;
    try {
      final liste = await ref.read(mesajRepositoryProvider).sohbetleriGetir();
      if (!ref.mounted) return;
      state = AsyncData(liste);
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'sohbetler.yenile');
    }
  }
}

// ── Okunmamış sayısı ──────────────────────────────────────────────────────────

@riverpod
int okunmamisSayi(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return 0;
  final sohbetListesi = ref.watch(sohbetlerProvider).value ?? [];
  final engellenenUidler = (ref.watch(engellenenlerProvider).value ?? []).toSet();
  int toplam = 0;
  for (final s in sohbetListesi) {
    if (s.gizliMi(uid)) continue;
    final karsiUid = s.karsiKullaniciId(uid);
    if (engellenenUidler.contains(karsiUid)) continue;
    toplam += s.okunmamisSayisi(uid);
  }
  return toplam;
}

// ── Karşı kullanıcı adı provider ─────────────────────────────────────────────

@Riverpod(keepAlive: true)
Future<String> karsiKullaniciAd(Ref ref, String uid) async {
  if (uid.isEmpty) return 'Kullanıcı';
  final data = await ref.read(kullaniciRepositoryProvider).kullaniciDataGetir(uid);
  if (data == null) return 'Kullanıcı';
  final adSoyad = data['adSoyad'] as String? ?? '';
  if (adSoyad.isNotEmpty) return adSoyad;
  final displayName = data['displayName'] as String? ?? '';
  return displayName.isNotEmpty ? displayName : 'Kullanıcı';
}

// ── Karşı kullanıcı foto provider ────────────────────────────────────────────

@Riverpod(keepAlive: true)
Future<String?> karsiKullaniciFoto(Ref ref, String uid) async {
  if (uid.isEmpty) return null;
  final data = await ref.read(kullaniciRepositoryProvider).kullaniciDataGetir(uid);
  return data?['fotoUrl'] as String?;
}

// ── Sohbet ekranı state ───────────────────────────────────────────────────────

class SohbetEkraniState {
  final Map<String, MesajModel> mesajMap;
  final List<MesajModel> siraliMesajlar;
  final bool yukleniyor;
  final bool gonderiyor;
  final String? hata;
  final List<File> geciciResimler;

  const SohbetEkraniState({
    this.mesajMap = const {},
    this.siraliMesajlar = const [],
    this.yukleniyor = true,
    this.gonderiyor = false,
    this.hata,
    this.geciciResimler = const [],
  });

  SohbetEkraniState copyWith({
    Map<String, MesajModel>? mesajMap,
    List<MesajModel>? siraliMesajlar,
    bool? yukleniyor,
    bool? gonderiyor,
    String? hata,
    bool temizleHata = false,
    List<File>? geciciResimler,
  }) =>
      SohbetEkraniState(
        mesajMap: mesajMap ?? this.mesajMap,
        siraliMesajlar: siraliMesajlar ?? this.siraliMesajlar,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        gonderiyor: gonderiyor ?? this.gonderiyor,
        hata: temizleHata ? null : (hata ?? this.hata),
        geciciResimler: geciciResimler ?? this.geciciResimler,
      );
}

@riverpod
class SohbetNotifier extends _$SohbetNotifier {
  String? _sohbetId;
  Timer? _yenilemeTimer;
  final _geciciIdler = <String>{};

  // firestore.rules.oneri.txt'teki mesajHizSiniriGecerliMi() ile AYNI
  // pencere — ağ gecikmesi payı için 1100ms.
  DateTime? _sonGonderimZamani;

  Future<void> _mesajHizSiniriBekle() async {
    final onceki = _sonGonderimZamani;
    _sonGonderimZamani = DateTime.now();
    if (onceki == null) return;
    const minAralik = Duration(milliseconds: 1100);
    final gecen = _sonGonderimZamani!.difference(onceki);
    if (gecen < minAralik) {
      await Future.delayed(minAralik - gecen);
    }
  }

  @override
  SohbetEkraniState build({
    required String karsiKullaniciId,
    required String ilanId,
    String? sohbetId,
  }) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SohbetEkraniState();

    _baslat(sohbetId);

    ref.onDispose(() => _yenilemeTimer?.cancel());

    return const SohbetEkraniState();
  }

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  /// [sohbetIdBiliniyor] mesaj listesinden (var olan bir sohbete) girildiğinde
  /// doludur — bu durumda sohbet-baslat'ı HİÇ çağırmıyoruz. Önemli: o uç
  /// karşı tarafı her zaman "ilan sahibi" varsayıyor, ilan sahibi KENDİ
  /// ilanıyla ilgili var olan bir sohbeti tekrar açmaya çalışınca
  /// (benimID == ilan sahibi) "kendi ilanınla sohbet başlatamazsın" diye
  /// reddediyordu — var olan sohbete asla yeniden "başlamaya" gerek yok,
  /// zaten ID'si elimizde.
  ///
  /// ID bilinmiyorsa (ilan detayından ilk kez "mesaj gönder") sohbet-baslat
  /// çağrılır — sunucu tarafında gen_random_uuid ile üretilen gerçek ID bu
  /// şekilde alınır (idempotent: aynı ilan+kullanıcı çifti için hep AYNI
  /// sohbeti döner).
  Future<void> _baslat(String? sohbetIdBiliniyor) async {
    try {
      if (sohbetIdBiliniyor != null && sohbetIdBiliniyor.isNotEmpty) {
        _sohbetId = sohbetIdBiliniyor;
      } else {
        final sohbet = await _repo.sohbetBaslat(ilanId: ilanId);
        if (!ref.mounted) return;
        _sohbetId = sohbet.id;
      }
      await _mesajlariYenile();
      _yenilemeTimer?.cancel();
      _yenilemeTimer = Timer.periodic(const Duration(seconds: 4), (_) => _mesajlariYenile());
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'sohbetNotifier.baslat');
      if (ref.mounted) {
        state = state.copyWith(yukleniyor: false, hata: 'Sohbet başlatılamadı. Tekrar dene.');
      }
    }
  }

  Future<void> _mesajlariYenile() async {
    if (_sohbetId == null) return;
    try {
      final mesajlar = await _repo.mesajlariGetir(_sohbetId!);
      if (!ref.mounted) return;

      final yeniMap = Map<String, MesajModel>.from(state.mesajMap);
      for (final mesaj in mesajlar) {
        yeniMap[mesaj.id] = mesaj;
      }
      final sunucuIdler = mesajlar.map((m) => m.id).toSet();
      _geciciIdler.removeWhere((id) => sunucuIdler.contains(id));
      yeniMap.removeWhere((id, _) => !sunucuIdler.contains(id) && !_geciciIdler.contains(id));

      state = state.copyWith(
        mesajMap: yeniMap,
        siraliMesajlar: _sirala(yeniMap),
        yukleniyor: false,
      );

      if (mesajlar.isNotEmpty) {
        unawaited(_repo.okunduIsaretle(_sohbetId!).catchError((e, s) {
          AppHataYonetici.logla(e, s, etiket: 'sohbetNotifier.okunduIsaretle');
        }));
      }
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'sohbetNotifier.mesajlariYenile');
      if (ref.mounted) {
        state = state.copyWith(yukleniyor: false, hata: 'Mesajlar yüklenemedi. Tekrar dene.');
      }
    }
  }

  List<MesajModel> _sirala(Map<String, MesajModel> map) {
    final liste = map.values.toList();
    liste.sort((a, b) {
      final msA = a.zaman?.millisecondsSinceEpoch ?? 0;
      final msB = b.zaman?.millisecondsSinceEpoch ?? 0;
      return msB.compareTo(msA);
    });
    return liste;
  }

  void geciciMesajEkle({
    required String id,
    required String metin,
    required String gondereId,
    DateTime? zaman,
  }) {
    if (state.mesajMap.containsKey(id)) return;
    _geciciIdler.add(id);
    final gecici = MesajModel(
      id: id,
      metin: metin,
      gondereId: gondereId,
      zaman: zaman ?? DateTime.now(),
      okundu: false,
      gonderiliyor: false,
    );
    final yeniMap = Map<String, MesajModel>.from(state.mesajMap)..[id] = gecici;
    state = state.copyWith(mesajMap: yeniMap, siraliMesajlar: _sirala(yeniMap));
  }

  /// Backend şu an tüm mesajları (limitsiz) döndüğü için "daha fazla yükle"
  /// (eski mesaj sayfalama) kavramı kalmadı — her yenilemede zaten tüm
  /// geçmiş geliyor. Bu metod geriye dönük uyumluluk için duruyor.
  Future<void> dahaFazlaYukle() async {}

  Future<void> mesajGonder({
    required String metin,
    required String karsiKullaniciId,
    required String karsiKullaniciAd,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
    String ilanSahibiId = '',
    String ilanTip = '',
    String tip = 'mesaj',
  }) async {
    if (metin.trim().isEmpty || _sohbetId == null) return;
    await _mesajHizSiniriBekle();
    try {
      await _repo.mesajGonder(sohbetId: _sohbetId!, metin: metin.trim());
      if (!ref.mounted) return;
      await _mesajlariYenile();
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'mesajGonder');
      if (ref.mounted) state = state.copyWith(hata: 'Mesaj gönderilemedi. Tekrar dene.');
    }
  }

  Future<void> resimGonder({
    required File dosya,
    required String karsiKullaniciId,
    required String karsiKullaniciAd,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
    String ilanSahibiId = '',
    String ilanTip = '',
  }) async {
    if (state.gonderiyor || _sohbetId == null) return;

    state = state.copyWith(gonderiyor: true, geciciResimler: [...state.geciciResimler, dosya]);
    try {
      await _mesajHizSiniriBekle();
      await _repo.mesajGonder(sohbetId: _sohbetId!, metin: '📷 Fotoğraf', resim: dosya);
      if (!ref.mounted) return;
      await _mesajlariYenile();
      if (ref.mounted) {
        final updated = List<File>.from(state.geciciResimler)..remove(dosya);
        state = state.copyWith(geciciResimler: updated);
      }
    } catch (e, s) {
      AppHataYonetici.logla(e, s, etiket: 'resimGonder');
      if (ref.mounted) {
        final updated = List<File>.from(state.geciciResimler)..remove(dosya);
        state = state.copyWith(gonderiyor: false, geciciResimler: updated, hata: 'Resim gönderilemedi. Tekrar dene.');
      }
      return;
    } finally {
      if (ref.mounted) state = state.copyWith(gonderiyor: false);
    }
  }

  Future<void> mesajSil({required String mesajId, required String metin}) async {
    if (_sohbetId == null) return;
    await _repo.mesajSil(sohbetId: _sohbetId!, mesajId: mesajId);
    if (!ref.mounted) return;
    final yeniMap = Map<String, MesajModel>.from(state.mesajMap)..remove(mesajId);
    state = state.copyWith(mesajMap: yeniMap, siraliMesajlar: _sirala(yeniMap));
  }

  // build() parametresi olan "sohbetId" ile çakışmasın diye farklı isim —
  // bu, sohbet-baslat çağrısından SONRA kesinleşen GERÇEK (çözümlenmiş) ID.
  String? get cozumlenenSohbetId => _sohbetId;
}

// ── İşlem durumu işlemleri ────────────────────────────────────────────────────

@riverpod
class IslemDurumuIslemleri extends _$IslemDurumuIslemleri {
  @override
  AsyncValue<void> build(String sohbetId) => const AsyncData(null);

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  /// [bildirimIcerigi] — ekran tarafında IslemDurumu.gecmisDonusu'ndan
  /// üretilip buraya geçiriliyor (backend sadece aynen iletiyor, üretme
  /// mantığı client'ta kalıyor).
  Future<void> guncelle(String durum, {String? bildirimIcerigi}) async {
    await _repo.islemDurumuGuncelle(sohbetId: sohbetId, anahtar: durum, bildirimIcerigi: bildirimIcerigi);
  }

  Future<void> anlasildiIsaretle(String benimUid) async {
    await _repo.anlasildiIsaretle(sohbetId: sohbetId, benimUid: benimUid);
  }

  Future<void> teslimTamamla() async {
    await _repo.teslimTamamla(sohbetId: sohbetId);
  }
}

// ── Sohbet işlemleri ──────────────────────────────────────────────────────────

@riverpod
class SohbetIslemleri extends _$SohbetIslemleri {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  MesajRepository get _repo => ref.read(mesajRepositoryProvider);

  Future<void> gizle({required String sohbetId, required String kullaniciId}) async {
    await _repo.sohbetiGizle(sohbetId);
  }

  Future<SohbetModel?> getir(String sohbetId) async {
    return _repo.sohbetGetir(sohbetId);
  }
}

// ── İşlem durumu provider'ları (islem_durumu_panel için) ─────────────────────
// Artık Stream DEĞİL — tek seferlik okuma (FutureProvider.family), ekranlar
// gerektiğinde ref.invalidate ile tazeler.

final sohbetDokumanProvider =
    FutureProvider.family<SohbetModel?, String>((ref, sohbetId) {
  return ref.read(mesajRepositoryProvider).sohbetGetir(sohbetId);
});

final islemDurumuProvider =
    Provider.family<AsyncValue<Map<String, dynamic>>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId)).whenData((s) => s?.islemDurumlari ?? {});
});

final sohbetIlanSahibiIdProvider =
    Provider.family<AsyncValue<String>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId)).whenData((s) => s?.ilanSahibiId ?? '');
});

final sohbetIlanTipProvider =
    Provider.family<AsyncValue<String>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId)).whenData((s) => s?.ilanTip ?? 'istek');
});

final sohbetKullanicilarProvider =
    Provider.family<AsyncValue<List<String>>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId)).whenData((s) => s?.kullanicilar ?? []);
});

final sohbetIlanBaslikProvider =
    Provider.family<AsyncValue<String>, String>((ref, sohbetId) {
  return ref.watch(sohbetDokumanProvider(sohbetId)).whenData((s) => s?.ilanBaslik ?? '');
});
