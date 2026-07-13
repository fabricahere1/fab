// lib/features/home/providers/kesfet_akis_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../ilanlar/data/ilan_repository.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

part 'kesfet_akis_provider.g.dart';

class KesfetAkisState {
  final List<IlanModel> ilanlar;
  final DateTime? sonTarih;
  final bool yukleniyor;
  final bool dahaFazlaVar;
  final Object? hata;

  const KesfetAkisState({
    this.ilanlar = const [],
    this.sonTarih,
    this.yukleniyor = false,
    this.dahaFazlaVar = true,
    this.hata,
  });

  KesfetAkisState copyWith({
    List<IlanModel>? ilanlar,
    DateTime? sonTarih,
    bool? yukleniyor,
    bool? dahaFazlaVar,
    Object? hata,
    bool temizleHata = false,
  }) => KesfetAkisState(
        ilanlar: ilanlar ?? this.ilanlar,
        sonTarih: sonTarih ?? this.sonTarih,
        yukleniyor: yukleniyor ?? this.yukleniyor,
        dahaFazlaVar: dahaFazlaVar ?? this.dahaFazlaVar,
        hata: temizleHata ? null : (hata ?? this.hata),
      );
}

// keepAlive BİLİNÇLİ — iki gerekçe:
// (1) Parametre uzayı 2 değerle sınırlı ('istek'/'tasiyici') — kullaniciIlanlarStream'deki
//     sınırsız-kullanıcı birikme riski (bkz. ilan_provider.dart:498) burada YOK.
//     Bu deseni sınırsız parametreli bir family'ye KOPYALAMA.
// (2) TabBarView tab geçişlerinde widget'ı dispose EDEBİLİR (garanti değil, cache
//     davranışına bağlı); autoDispose bu durumda pagination state'ini sıfırlar —
//     keepAlive bu riski kapatır. Liste yalnızca yenile() ile tazelenir
//     (forceServer: true) — bilinçli tasarım kararı.
@Riverpod(keepAlive: true)
class KesfetAkis extends _$KesfetAkis {
  IlanRepository get _repo => ref.read(ilanRepositoryProvider);

  @override
  KesfetAkisState build(String tip) {
    Future.microtask(_ilkYukle);
    return const KesfetAkisState(yukleniyor: true);
  }

  Future<void> _ilkYukle({bool forceServer = false}) async {
    state = state.copyWith(yukleniyor: true, temizleHata: true);
    try {
      final sonuc = tip == 'istek'
          ? await _repo.istekIlanlariniGetir(forceServer: forceServer)
          : await _repo.tasiyiciIlanlariniGetir(forceServer: forceServer);
      if (!ref.mounted) return;
      state = state.copyWith(
        ilanlar: sonuc.ilanlar,
        sonTarih: sonuc.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
    } catch (e, stack) {
      AppHataYonetici.logla(e, stack, etiket: 'KesfetAkis.ilkYukle');
      if (!ref.mounted) return;
      state = state.copyWith(yukleniyor: false, hata: e);
    }
  }

  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor || !state.dahaFazlaVar || state.sonTarih == null) return;
    state = state.copyWith(yukleniyor: true);
    try {
      final sonuc = await _repo.sonrakiSayfayiGetir(
        tip: tip,
        sonTarih: state.sonTarih!,
        siralama: 'olusturma',
      );
      if (!ref.mounted) return;
      final mevcutIdler = state.ilanlar.map((i) => i.id).toSet();
      final yeniIlanlar =
          sonuc.ilanlar.where((i) => !mevcutIdler.contains(i.id)).toList();
      state = state.copyWith(
        ilanlar: [...state.ilanlar, ...yeniIlanlar],
        sonTarih: sonuc.sonTarih ?? state.sonTarih,
        dahaFazlaVar: !sonuc.bitti,
        yukleniyor: false,
      );
    } catch (e, stack) {
      AppHataYonetici.logla(e, stack, etiket: 'KesfetAkis.dahaFazlaYukle');
      if (!ref.mounted) return;
      state = state.copyWith(yukleniyor: false, hata: e);
    }
  }

  Future<void> yenile() async {
    state = const KesfetAkisState(yukleniyor: true);
    await _ilkYukle(forceServer: true);
  }
}
