// lib/features/home/providers/sana_ozel_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/profil/domain/kullanici_model.dart';
import 'package:iste_v3/features/profil/providers/profil_provider.dart';

part 'sana_ozel_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// İSTEK kullanıcısı bölümleri
// ─────────────────────────────────────────────────────────────────────────────

/// Şehrine gelecek taşıyıcı ilanları (nereye == user.bulunduguSehir)
@riverpod
List<IlanModel> sehirGelecekIlanlar(Ref ref) {
  final profil = ref.watch(benimKullaniciProfilProvider).value;
  if (profil == null || profil.bulunduguSehir.isEmpty) return [];
  final sehir = profil.bulunduguSehir.toLowerCase();
  return ref
      .watch(tasiyiciIlanlarProvider)
      .filtrelenmis
      .where((i) => i.nereye.toLowerCase() == sehir)
      .toList();
}

/// Taşıyıcı ilanları kullanıcının ilgi kategorileriyle eşleşenler
@riverpod
List<IlanModel> kategorilereGoreIlanlar(Ref ref) {
  final profil = ref.watch(benimKullaniciProfilProvider).value;
  if (profil == null || profil.ilgiKategorileri.isEmpty) return [];
  final kategoriler = profil.ilgiKategorileri.toSet();
  return ref
      .watch(tasiyiciIlanlarProvider)
      .filtrelenmis
      .where((i) =>
          kategoriler.contains(i.anaKategori) ||
          kategoriler.contains(i.kategori))
      .toList();
}

/// Taşıyıcı ilanları kullanıcının beden bilgisiyle eşleşenler
@riverpod
List<IlanModel> bedenGoreIlanlar(Ref ref) {
  final profil = ref.watch(benimKullaniciProfilProvider).value;
  if (profil == null) return [];
  return ref
      .watch(tasiyiciIlanlarProvider)
      .filtrelenmis
      .where((i) => _bedenEslesiyor(i, profil))
      .toList();
}

bool _bedenEslesiyor(IlanModel ilan, KullaniciModel profil) {
  final b = ilan.beden.trim();
  if (b.isEmpty) return false;
  switch (ilan.cinsiyet.toLowerCase()) {
    case 'kadin':
      return profil.kadinUstBeden.contains(b) ||
          profil.kadinAltBeden.contains(b) ||
          profil.kadinAyakkabi.contains(b);
    case 'erkek':
      return profil.erkekUstBeden.contains(b) ||
          profil.erkekAltBeden.contains(b) ||
          profil.erkekAyakkabi.contains(b);
    case 'cocuk':
      return profil.cocukAyakkabi.contains(b);
    default:
      return profil.kadinUstBeden.contains(b) ||
          profil.kadinAltBeden.contains(b) ||
          profil.kadinAyakkabi.contains(b) ||
          profil.erkekUstBeden.contains(b) ||
          profil.erkekAltBeden.contains(b) ||
          profil.erkekAyakkabi.contains(b) ||
          profil.cocukAyakkabi.contains(b);
  }
}

/// Diğer kullanıcıların aynı kategorilerde en çok istediği ürünler
@riverpod
List<IlanModel> populerKategoriIstekleri(Ref ref) {
  final profil = ref.watch(benimKullaniciProfilProvider).value;
  if (profil == null || profil.ilgiKategorileri.isEmpty) return [];
  final kategoriler = profil.ilgiKategorileri.toSet();
  return ([
    ...ref.watch(istekIlanlarProvider).filtrelenmis.where((i) =>
        kategoriler.contains(i.anaKategori) ||
        kategoriler.contains(i.kategori))
  ]..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi)))
      .take(20)
      .toList();
}

/// Duty Free alışveriş yapabilecek taşıyıcılar
@riverpod
List<IlanModel> dutyFreeYapabilecekIlanlar(Ref ref) {
  return ref
      .watch(tasiyiciIlanlarProvider)
      .filtrelenmis
      .where((i) => i.sahipDutyFree)
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// TAŞIYICI kullanıcısı bölümleri
// ─────────────────────────────────────────────────────────────────────────────

/// Taşıyıcının seyahat edeceği şehirden açılan istek ilanları
@riverpod
List<IlanModel> seyahatSehriIlanlar(Ref ref) {
  final profil = ref.watch(benimKullaniciProfilProvider).value;
  if (profil == null || profil.geldigiSehirler.isEmpty) return [];
  final sehirler =
      profil.geldigiSehirler.map((s) => s.toLowerCase()).toSet();
  return ref
      .watch(istekIlanlarProvider)
      .filtrelenmis
      .where((i) => sehirler.contains(i.nereye.toLowerCase()))
      .toList();
}

/// Kargo teslim kabul eden istekçilerin ilanları
@riverpod
List<IlanModel> kargoKabulIstekler(Ref ref) {
  return ref
      .watch(istekIlanlarProvider)
      .filtrelenmis
      .where((i) =>
          i.sahipIstekTeslimatTercihi == null ||
          i.sahipIstekTeslimatTercihi == 'kargo' ||
          i.sahipIstekTeslimatTercihi == 'ikisi_de')
      .toList();
}

/// Elden teslim kabul eden istekçilerin ilanları
@riverpod
List<IlanModel> eldenKabulIstekler(Ref ref) {
  return ref
      .watch(istekIlanlarProvider)
      .filtrelenmis
      .where((i) =>
          i.sahipIstekTeslimatTercihi == null ||
          i.sahipIstekTeslimatTercihi == 'elden' ||
          i.sahipIstekTeslimatTercihi == 'ikisi_de')
      .toList();
}

/// 4 puan ve üzeri değerlendirme alan kullanıcıların istek ilanları
@riverpod
List<IlanModel> onayliIstekler(Ref ref) {
  return ref
      .watch(istekIlanlarProvider)
      .filtrelenmis
      .where((i) => i.kullaniciPuan >= 4.0)
      .toList();
}
