// lib/features/home/providers/sana_ozel_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/features/profil/domain/kullanici_model.dart';
import 'package:iste_v3/features/profil/providers/profil_provider.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/features/auth/providers/auth_provider.dart';

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
      .where((i) => bedenEslesiyor(i, profil))
      .toList();
}

bool bedenEslesiyor(IlanModel ilan, KullaniciModel profil) {
  final b = ilan.beden.trim();
  if (b.isEmpty) return false;

  // Çocuk ürünleri 'cinsiyet' alanıyla değil, anaKategori == 'cocuk' ile ayırt
  // edilir — çocuk ilanlarında cinsiyet 'Kız'/'Erkek'/'Unisex' olabiliyor,
  // tek başına "çocuk mu yetişkin mi" ayrımını yapmıyor.
  if (ilan.anaKategori == 'cocuk') {
    return profil.cocukAyakkabi.contains(b);
  }

  // toLowerCase() kullanılmıyor: Türkçe 'ı' (noktasız) ile kod içindeki 'i'
  // (noktalı) farklı Unicode karakterlerdir, toLowerCase() bunu eşitlemez
  // ('Kadın'.toLowerCase() == 'kadın' ≠ 'kadin'). Orijinal string'lerle
  // (ilan_form_screen.dart'taki _cinsiyetler listesindeki tam haliyle) karşılaştır.
  switch (ilan.cinsiyet) {
    case 'Kadın':
      return profil.kadinUstBeden.contains(b) ||
          profil.kadinAltBeden.contains(b) ||
          profil.kadinAyakkabi.contains(b);
    case 'Erkek':
      return profil.erkekUstBeden.contains(b) ||
          profil.erkekAltBeden.contains(b) ||
          profil.erkekAyakkabi.contains(b);
    default:
      // 'Unisex' ya da beklenmeyen bir değer — yetişkin bedenlerinin
      // tamamına bak (çocuk zaten yukarıda ayrıca ele alındı).
      return profil.kadinUstBeden.contains(b) ||
          profil.kadinAltBeden.contains(b) ||
          profil.kadinAyakkabi.contains(b) ||
          profil.erkekUstBeden.contains(b) ||
          profil.erkekAltBeden.contains(b) ||
          profil.erkekAyakkabi.contains(b);
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

/// Geçmişte görüntülenen ilanların kategorilerine benzer, henüz
/// görüntülenmemiş ilanlar (istek + taşıyıcı ilanları birlikte).
@riverpod
List<IlanModel> gecmisGoruntulenenlereBenzerIlanlar(Ref ref) {
  final gorunenler = ref.watch(sonGoruntulenenlerProvider);
  if (gorunenler.isEmpty) return [];

  final kategoriler = <String>{};
  for (final g in gorunenler) {
    if (g.kategori.isNotEmpty) kategoriler.add(g.kategori);
    if (g.anaKategori.isNotEmpty) kategoriler.add(g.anaKategori);
  }
  if (kategoriler.isEmpty) return [];

  final gorulenIdler = gorunenler.map((g) => g.id).toSet();
  return [
    ...ref.watch(istekIlanlarProvider).filtrelenmis,
    ...ref.watch(tasiyiciIlanlarProvider).filtrelenmis,
  ]
      .where((i) =>
          !gorulenIdler.contains(i.id) &&
          (kategoriler.contains(i.kategori) || kategoriler.contains(i.anaKategori)))
      .toList();
}

/// Favorilenen ilanların kategorilerinden, son 7 günde açılmış yeni
/// taşıyıcı ilanları (istekçi tarafına özel — favorilenen ilanın kendisi hariç).
@riverpod
List<IlanModel> favoriKategorilerYeniIlanlar(Ref ref) {
  final favoriler = ref.watch(favorilerProvider).value ?? const [];
  if (favoriler.isEmpty) return [];

  final kategoriler = favoriler
      .map((f) => f['kategori'] as String? ?? '')
      .where((k) => k.isNotEmpty)
      .toSet();
  if (kategoriler.isEmpty) return [];

  final favoriIlanIdleri =
      favoriler.map((f) => f['ilanId'] as String? ?? '').toSet();
  final simdi = DateTime.now();

  final sonuc = ref.watch(tasiyiciIlanlarProvider).filtrelenmis.where((i) {
    if (favoriIlanIdleri.contains(i.id)) return false;
    if (!kategoriler.contains(i.kategori) && !kategoriler.contains(i.anaKategori)) {
      return false;
    }
    final olusturma = i.olusturmaTarihi;
    return olusturma != null && simdi.difference(olusturma).inDays <= 7;
  }).toList();

  sonuc.sort((a, b) =>
      (b.olusturmaTarihi ?? simdi).compareTo(a.olusturmaTarihi ?? simdi));
  return sonuc;
}

/// Takip edilen taşıyıcıların, takip başladıktan SONRA açtığı ilanlar.
@riverpod
List<IlanModel> takipEdilenTasiyicilarinYeniIlanlari(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return [];

  final takipTarihleri =
      ref.watch(takipEdilenTarihleriProvider(uid)).value ?? const {};
  if (takipTarihleri.isEmpty) return [];

  return ref.watch(tasiyiciIlanlarProvider).filtrelenmis.where((i) {
    final takipTarihi = takipTarihleri[i.kullaniciId];
    final olusturma = i.olusturmaTarihi;
    if (takipTarihi == null || olusturma == null) return false;
    return olusturma.isAfter(takipTarihi);
  }).toList();
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

/// Favorilenen istek ilanlarının kategorilerinden, son 7 günde açılmış yeni
/// istek ilanları (taşıyıcı tarafına özel — favorilenen ilanın kendisi hariç).
@riverpod
List<IlanModel> favoriKategorilerYeniIstekIlanlari(Ref ref) {
  final favoriler = ref.watch(favorilerProvider).value ?? const [];
  if (favoriler.isEmpty) return [];

  final kategoriler = favoriler
      .map((f) => f['kategori'] as String? ?? '')
      .where((k) => k.isNotEmpty)
      .toSet();
  if (kategoriler.isEmpty) return [];

  final favoriIlanIdleri =
      favoriler.map((f) => f['ilanId'] as String? ?? '').toSet();
  final simdi = DateTime.now();

  final sonuc = ref.watch(istekIlanlarProvider).filtrelenmis.where((i) {
    if (favoriIlanIdleri.contains(i.id)) return false;
    if (!kategoriler.contains(i.kategori) && !kategoriler.contains(i.anaKategori)) {
      return false;
    }
    final olusturma = i.olusturmaTarihi;
    return olusturma != null && simdi.difference(olusturma).inDays <= 7;
  }).toList();

  sonuc.sort((a, b) =>
      (b.olusturmaTarihi ?? simdi).compareTo(a.olusturmaTarihi ?? simdi));
  return sonuc;
}

/// Takip edilen istekçilerin, takip başladıktan SONRA açtığı istek ilanları.
@riverpod
List<IlanModel> takipEdilenIstekcilerinYeniIlanlari(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return [];

  final takipTarihleri =
      ref.watch(takipEdilenTarihleriProvider(uid)).value ?? const {};
  if (takipTarihleri.isEmpty) return [];

  return ref.watch(istekIlanlarProvider).filtrelenmis.where((i) {
    final takipTarihi = takipTarihleri[i.kullaniciId];
    final olusturma = i.olusturmaTarihi;
    if (takipTarihi == null || olusturma == null) return false;
    return olusturma.isAfter(takipTarihi);
  }).toList();
}
