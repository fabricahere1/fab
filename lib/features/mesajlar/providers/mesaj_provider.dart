import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/mesaj_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/data/kullanici_repository.dart';
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
  bool _okunduIsaretlendi = false;
 
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
    Future.microtask(() => _okunduIsaretle());
 
    return const SohbetEkraniState();
  }
 
  MesajRepository get _repo => ref.read(mesajRepositoryProvider);
 
  void _mesajlariDinle() {
    final stream = _repo.mesajlarStream(sohbetId: _sohbetId);
    stream.listen((snap) {
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
          dahaFazlaVar:
              snap.docs.length >= Pagination.mesajSayfaBoyutu,
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
 
      if (!_okunduIsaretlendi && yeniMap.isNotEmpty) {
        _okunduIsaretle();
      }
    });
  }
 
  List<Map<String, dynamic>> _sirala(
      Map<String, Map<String, dynamic>> map) {
    final liste = map.values.toList();
    liste.sort((a, b) {
      final zamanA =
          (a['zaman'] as Timestamp).millisecondsSinceEpoch;
      final zamanB =
          (b['zaman'] as Timestamp).millisecondsSinceEpoch;
      return zamanB.compareTo(zamanA);
    });
    return liste;
  }
 
  Future<void> dahaFazlaYukle() async {
    if (state.yukleniyor ||
        !state.dahaFazlaVar ||
        state.enEskiDoc == null) return;
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
      dahaFazlaVar:
          snap.docs.length >= Pagination.mesajSayfaBoyutu,
      enEskiDoc:
          snap.docs.isNotEmpty ? snap.docs.last : state.enEskiDoc,
    );
  }
 
  Future<void> mesajGonder({
    required String metin,
    required String karsiKullaniciId,
    required String karsiAd,
    required String ilanId,
    required String ilanBaslik,
    String ilanResimUrl = '',
  }) async {
    if (metin.trim().isEmpty || state.gonderiyor) return;
    state = state.copyWith(gonderiyor: true);
    final benimAd = await _getBenimAd();
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
      );
    } finally {
      state = state.copyWith(gonderiyor: false);
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
 
  Future<void> _okunduIsaretle() async {
    if (_okunduIsaretlendi) return;
    _okunduIsaretlendi = true;
    await _repo.okunduIsaretle(
      sohbetId: _sohbetId,
      kullaniciId: _benimId,
    );
  }
 
  Future<String> _getBenimAd() async {
    try {
      final doc = await ref
          .read(kullaniciRepositoryProvider)
          .kullaniciGetir(_benimId);
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