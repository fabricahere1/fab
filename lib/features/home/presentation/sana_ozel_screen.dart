// lib/features/home/presentation/sana_ozel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/profil/providers/profil_provider.dart';
import 'package:iste_v3/features/profil/domain/kullanici_model.dart';
import 'package:iste_v3/features/home/providers/sana_ozel_providers.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/shared/utils/app_hata_yonetici.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/utils/app_snackbar.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iste_v3/features/home/presentation/kesfet_vitrin_tab.dart'
    show CicekTipi, KartZeminPainter;
import 'package:iste_v3/features/home/presentation/kesfet_bolum_baslik.dart';
import 'package:iste_v3/features/home/presentation/kesfet_bolum_detay_screen.dart';
import 'package:iste_v3/features/profil/presentation/profil_duzenle_screen.dart';
import 'package:iste_v3/features/auth/providers/auth_provider.dart';
import 'package:iste_v3/shared/widgets/login_gerektiren_aksiyon.dart' show loginBottomSheet;
import 'package:iste_v3/shared/widgets/avatar_widget.dart';
import 'package:iste_v3/features/profil/presentation/kullanici_profil_screen.dart';
import 'package:iste_v3/features/ilanlar/presentation/ilan_form_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

/// İlanın "tarih"i (taşıyıcının seyahat/varış tarihi) bir haftadan az kaldıysa true.
bool yakindaGeliyorMu(IlanModel ilan) {
  if (ilan.tip != IlanTip.tasiyici || ilan.tarih == null) return false;
  final fark = ilan.tarih!.difference(DateTime.now());
  return !fark.isNegative && fark.inDays < 7;
}

class SanaOzelScreen extends ConsumerWidget {
  const SanaOzelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(benimKullaniciProfilProvider);

    ref.listen(benimKullaniciProfilProvider, (_, sonraki) {
      if (sonraki.hasError) {
        AppSnackBar.hata(context, 'Profil yüklenemedi.');
      }
    });

    return profilAsync.when(
      loading: () => _SanaOzelShimmer(),
      error: (e, s) { AppHataYonetici.logla(e, s, etiket: 'sanaOzel.profil'); return const SizedBox.shrink(); },
      data: (profil) {
        if (profil == null) return const SizedBox.shrink();
        if (profil.kullaniciTipi == 'her_ikisi') {
          return const _HerIkisiSanaOzel(key: ValueKey('her_ikisi'));
        } else if (profil.tasiyiciMi) {
          return const _TasiyiciSanaOzel(key: ValueKey('tasiyici'));
        } else {
          return const _IstekSanaOzel(key: ValueKey('istek'));
        }
      },
    );
  }
}

// ── İSTEK ────────────────────────────────────────────────────────────────────

class _IstekSanaOzel extends ConsumerWidget {
  const _IstekSanaOzel({super.key});

  Future<void> _yenile(WidgetRef ref) => Future.wait([
    ref.read(istekIlanlarProvider.notifier).yenile(),
    ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
  ]);

  bool _profilEksik(KullaniciModel? profil) {
    if (profil == null) return true;
    return profil.bulunduguSehir.isEmpty ||
        profil.ilgiKategorileri.isEmpty ||
        (profil.kadinUstBeden.isEmpty && profil.erkekUstBeden.isEmpty);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil          = ref.watch(benimKullaniciProfilProvider).value;
    final sonGorunenler   = ref.watch(sonGoruntulenenlerProvider);
    final kategoriler     = ref.watch(kategorilereGoreIlanlarProvider);
    final tumIlanlar      = ref.watch(istekIlanlarProvider).filtrelenmis;
    final yuksekPuanlilar = ref.watch(yuksekPuanliTasiyicilarProvider).value ?? const [];

    final tumu = [
      _BolumData('Senin şehrine gelecek taşıyıcılar', ref.watch(sehirGelecekIlanlarProvider), Icons.flight_land_outlined, CicekTipi.papatya),
      _BolumData('Senin kategorilerin', kategoriler, Icons.interests_outlined, CicekTipi.gul),
      _BolumData('Senin bedenine göre ilanlar', ref.watch(bedenGoreIlanlarProvider), Icons.checkroom_outlined, CicekTipi.lavanta),
      _BolumData('İlgilendiğin kategorilerden en çok istenenler', ref.watch(populerKategoriIstekleriProvider), Icons.trending_up_rounded, CicekTipi.aycicegi),
      _BolumData('Duty Free alışverişi yapabilecek olanlar', ref.watch(dutyFreeYapabilecekIlanlarProvider), Icons.shopping_bag_outlined, CicekTipi.papatya),
      _BolumData('Geçmişte görüntülediğin ürünlere benzer ürünler', ref.watch(gecmisGoruntulenenlereBenzerIlanlarProvider), Icons.history_rounded, CicekTipi.lavanta),
      _BolumData('Favorilediğin kategorilerden yeni ilanlar', ref.watch(favoriKategorilerYeniIlanlarProvider), Icons.new_releases_outlined, CicekTipi.gul),
      _BolumData('Takip ettiğin taşıyıcıların yeni ilanları', ref.watch(takipEdilenTasiyicilarinYeniIlanlariProvider), Icons.notifications_active_outlined, CicekTipi.aycicegi),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    final seen = <String>{};
    final bannerListe = [...sonGorunenler, ...kategoriler, ...tumIlanlar]
        .where((ilan) => seen.add(ilan.id)).take(15).toList();

    final profilBannerVar = _profilEksik(profil);
    final sectionWidgets = <Widget>[
      for (final b in tumu) _Bolum(data: b),
      if (yuksekPuanlilar.isNotEmpty) _YuksekPuanliTasiyicilarBolumu(tasiyicilar: yuksekPuanlilar),
    ];

    final items = <Widget>[
      if (profilBannerVar) const _ProfilTamamlaBanner(),
      _SanaOzelHeroBanner(ilanlar: bannerListe),
      if (sectionWidgets.isEmpty)
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: const _BosEkran(mesaj: 'Henüz sana özel içerik yok.\nProfilini tamamladıktan sonra burada kişiselleştirilmiş ilanlar görünecek.'),
        )
      else
        ...sectionWidgets,
      const _IlanAcCagriBolumu(),
    ];

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _yenile(ref),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: items.length,
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}

// ── TAŞIYICI ─────────────────────────────────────────────────────────────────

class _TasiyiciSanaOzel extends ConsumerWidget {
  const _TasiyiciSanaOzel({super.key});

  Future<void> _yenile(WidgetRef ref) => Future.wait([
    ref.read(istekIlanlarProvider.notifier).yenile(),
    ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
  ]);

  bool _profilEksik(KullaniciModel? profil) {
    if (profil == null) return true;
    return profil.geldigiSehirler.isEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil          = ref.watch(benimKullaniciProfilProvider).value;
    final sonGorunenler   = ref.watch(sonGoruntulenenlerProvider);
    final seyahatSehri    = ref.watch(seyahatSehriIlanlarProvider);
    final tumIlanlar      = ref.watch(istekIlanlarProvider).filtrelenmis;
    final yuksekPuanlilar = ref.watch(yuksekPuanliIstekcilerProvider).value ?? const [];

    final tumu = [
      _BolumData('Seyahat edeceğin şehirden açılan ilanlar', seyahatSehri, Icons.location_on_outlined, CicekTipi.aycicegi),
      _BolumData('Kargo teslim kabul eden istekçiler', ref.watch(kargoKabulIsteklerProvider), Icons.local_shipping_outlined, CicekTipi.lavanta),
      _BolumData('Elden teslim kabul eden istekçiler', ref.watch(eldenKabulIsteklerProvider), Icons.handshake_outlined, CicekTipi.gul),
      _BolumData('Onaylı istekçilerin istekleri', ref.watch(onayliIsteklerProvider), Icons.verified_outlined, CicekTipi.papatya),
      _BolumData('Geçmişte görüntülediğin ürünlere benzer istekler', ref.watch(gecmisGoruntulenenlereBenzerIlanlarProvider), Icons.history_rounded, CicekTipi.lavanta),
      _BolumData('Favorilediğin kategorilerden yeni istekler', ref.watch(favoriKategorilerYeniIstekIlanlariProvider), Icons.new_releases_outlined, CicekTipi.gul),
      _BolumData('Takip ettiğin istekçilerin yeni ilanları', ref.watch(takipEdilenIstekcilerinYeniIlanlariProvider), Icons.notifications_active_outlined, CicekTipi.aycicegi),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    final seen = <String>{};
    final bannerListe = [...sonGorunenler, ...seyahatSehri, ...tumIlanlar]
        .where((ilan) => seen.add(ilan.id)).take(15).toList();

    final profilBannerVar = _profilEksik(profil);
    final sectionWidgets = <Widget>[
      for (final b in tumu) _Bolum(data: b),
      if (yuksekPuanlilar.isNotEmpty) _YuksekPuanliTasiyicilarBolumu(tasiyicilar: yuksekPuanlilar, baslik: 'Yüksek puanlı istekçiler'),
    ];

    final items = <Widget>[
      if (profilBannerVar) const _ProfilTamamlaBanner(),
      _SanaOzelHeroBanner(ilanlar: bannerListe),
      if (sectionWidgets.isEmpty)
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: const _BosEkran(mesaj: 'Henüz sana özel içerik yok.\nSeyahat bilgilerini güncelledikten sonra burada eşleşen istekler görünecek.'),
        )
      else
        ...sectionWidgets,
      const _IlanAcCagriBolumu(),
    ];

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _yenile(ref),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: items.length,
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}

// ── HER İKİSİ ────────────────────────────────────────────────────────────────

enum _HerIkisiRol { istekci, tasiyici }

class _HerIkisiSanaOzel extends ConsumerStatefulWidget {
  const _HerIkisiSanaOzel({super.key});

  @override
  ConsumerState<_HerIkisiSanaOzel> createState() => _HerIkisiSanaOzelState();
}

class _HerIkisiSanaOzelState extends ConsumerState<_HerIkisiSanaOzel> {
  _HerIkisiRol _rol = _HerIkisiRol.istekci;

  Future<void> _yenile(WidgetRef ref) => Future.wait([
    ref.read(istekIlanlarProvider.notifier).yenile(),
    ref.read(tasiyiciIlanlarProvider.notifier).yenile(),
  ]);

  bool _profilEksik(KullaniciModel? profil) {
    if (profil == null) return true;
    return profil.bulunduguSehir.isEmpty ||
        profil.ilgiKategorileri.isEmpty ||
        profil.geldigiSehirler.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(benimKullaniciProfilProvider).value;
    final yuksekPuanliTasiyicilar = ref.watch(yuksekPuanliTasiyicilarProvider).value ?? const [];
    final yuksekPuanliIstekciler = ref.watch(yuksekPuanliIstekcilerProvider).value ?? const [];

    // İstekçi bölümleri
    final istekBolumleri = [
      _BolumData('Senin şehrine gelecek taşıyıcılar', ref.watch(sehirGelecekIlanlarProvider), Icons.flight_land_outlined, CicekTipi.papatya),
      _BolumData('Senin kategorilerin', ref.watch(kategorilereGoreIlanlarProvider), Icons.interests_outlined, CicekTipi.gul),
      _BolumData('Senin bedenine göre ilanlar', ref.watch(bedenGoreIlanlarProvider), Icons.checkroom_outlined, CicekTipi.lavanta),
      _BolumData('İlgilendiğin kategorilerden en çok istenenler', ref.watch(populerKategoriIstekleriProvider), Icons.trending_up_rounded, CicekTipi.aycicegi),
      _BolumData('Duty Free alışverişi yapabilecek olanlar', ref.watch(dutyFreeYapabilecekIlanlarProvider), Icons.shopping_bag_outlined, CicekTipi.papatya),
      _BolumData('Geçmişte görüntülediğin ürünlere benzer ürünler', ref.watch(gecmisGoruntulenenlereBenzerIlanlarProvider), Icons.history_rounded, CicekTipi.lavanta),
      _BolumData('Favorilediğin kategorilerden yeni ilanlar', ref.watch(favoriKategorilerYeniIlanlarProvider), Icons.new_releases_outlined, CicekTipi.gul),
      _BolumData('Takip ettiğin taşıyıcıların yeni ilanları', ref.watch(takipEdilenTasiyicilarinYeniIlanlariProvider), Icons.notifications_active_outlined, CicekTipi.aycicegi),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    // Taşıyıcı bölümleri
    final tasiyiciBolumleri = [
      _BolumData('Seyahat edeceğin şehirden açılan ilanlar', ref.watch(seyahatSehriIlanlarProvider), Icons.location_on_outlined, CicekTipi.aycicegi),
      _BolumData('Kargo teslim kabul eden istekçiler', ref.watch(kargoKabulIsteklerProvider), Icons.local_shipping_outlined, CicekTipi.lavanta),
      _BolumData('Elden teslim kabul eden istekçiler', ref.watch(eldenKabulIsteklerProvider), Icons.handshake_outlined, CicekTipi.gul),
      _BolumData('Onaylı istekçilerin istekleri', ref.watch(onayliIsteklerProvider), Icons.verified_outlined, CicekTipi.papatya),
      _BolumData('Favorilediğin kategorilerden yeni istekler', ref.watch(favoriKategorilerYeniIstekIlanlariProvider), Icons.new_releases_outlined, CicekTipi.gul),
      _BolumData('Takip ettiğin istekçilerin yeni ilanları', ref.watch(takipEdilenIstekcilerinYeniIlanlariProvider), Icons.notifications_active_outlined, CicekTipi.aycicegi),
    ].where((b) => b.ilanlar.isNotEmpty).toList();

    final bannerVar = _profilEksik(profil);
    final secimIstekci = _rol == _HerIkisiRol.istekci;

    final sectionWidgets = <Widget>[
      if (secimIstekci) ...[
        for (final b in istekBolumleri) _Bolum(data: b),
        if (yuksekPuanliTasiyicilar.isNotEmpty) _YuksekPuanliTasiyicilarBolumu(tasiyicilar: yuksekPuanliTasiyicilar),
      ] else ...[
        for (final b in tasiyiciBolumleri) _Bolum(data: b),
        if (yuksekPuanliIstekciler.isNotEmpty) _YuksekPuanliTasiyicilarBolumu(tasiyicilar: yuksekPuanliIstekciler, baslik: 'Yüksek puanlı istekçiler'),
      ],
    ];

    final items = <Widget>[
      if (bannerVar) const _ProfilTamamlaBanner(),
      _HerIkisiRolSecici(
        secimIstekci: secimIstekci,
        onDegisti: (yeniIstekci) => setState(
            () => _rol = yeniIstekci ? _HerIkisiRol.istekci : _HerIkisiRol.tasiyici),
      ),
      if (sectionWidgets.isEmpty)
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: _BosEkran(
            mesaj: secimIstekci
                ? 'Henüz sana özel içerik yok.\nProfilini tamamladıktan sonra eşleşmeler burada görünecek.'
                : 'Henüz sana özel içerik yok.\nSeyahat bilgilerini güncelledikten sonra burada eşleşen istekler görünecek.',
          ),
        )
      else
        ...sectionWidgets,
      const _IlanAcCagriBolumu(),
    ];

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _yenile(ref),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: items.length,
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}

// ── Her ikisi — istekçi/taşıyıcı rol seçici ───────────────────────────────────

class _HerIkisiRolSecici extends StatelessWidget {
  final bool secimIstekci;
  final ValueChanged<bool> onDegisti;
  const _HerIkisiRolSecici({required this.secimIstekci, required this.onDegisti});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Expanded(child: _RolButon(label: 'İstekçi olarak', ikon: Icons.shopping_bag_outlined, secili: secimIstekci, onTap: () => onDegisti(true))),
          Expanded(child: _RolButon(label: 'Taşıyıcı olarak', ikon: Icons.flight_takeoff_rounded, secili: !secimIstekci, onTap: () => onDegisti(false))),
        ]),
      ),
    );
  }
}

class _RolButon extends StatelessWidget {
  final String label;
  final IconData ikon;
  final bool secili;
  final VoidCallback onTap;
  const _RolButon({required this.label, required this.ikon, required this.secili, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: secili ? AppColors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: secili
              ? [BoxShadow(color: AppColors.red.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ikon, size: 16, color: secili ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.raleway(
                fontSize: 13,
                fontWeight: secili ? FontWeight.w700 : FontWeight.w600,
                color: secili ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.2,
              )),
        ]),
      ),
    );
  }
}

// ── Bölüm ─────────────────────────────────────────────────────────────────────

class _BolumData {
  final String baslik;
  final List<IlanModel> ilanlar;
  final IconData ikon;
  final CicekTipi cicekTipi;
  const _BolumData(this.baslik, this.ilanlar, this.ikon, this.cicekTipi);
}

class _Bolum extends StatelessWidget {
  final _BolumData data;
  const _Bolum({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KesfetBolumBaslik(
          baslik: data.baslik,
          ikon: data.ikon,
          onTumunuGor: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KesfetBolumDetayScreen(
                baslik: data.baslik,
                ilanlar: data.ilanlar,
                ikon: data.ikon,
              ),
            ),
          ),
        ),
        // Kartların scroll alanı — çiçekli zemin
        SizedBox(
          height: 270,
          child: Stack(children: [
            Positioned.fill(
              child: CustomPaint(painter: KartZeminPainter(data.cicekTipi)),
            ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: data.ilanlar.length,
              itemBuilder: (_, i) => _SanaOzelKart(ilan: data.ilanlar[i], cicekTipi: data.cicekTipi),
            ),
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SanaOzelKart extends ConsumerWidget {
  final IlanModel ilan;
  final CicekTipi cicekTipi;
  const _SanaOzelKart({required this.ilan, required this.cicekTipi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resim   = ilan.gridResim;
    final katAdi  = kategoriAdi(ilan.kategori);
    final uid     = ref.watch(currentUserProvider)?.uid;
    final gosterFavori = uid != null && uid != ilan.kullaniciId;
    final yakinda = yakindaGeliyorMu(ilan);
    return GestureDetector(
      onTap: () { ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan); context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan); },
      child: Container(
        width: 155,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF888888), width: 0.3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(height: 150, width: double.infinity, color: const Color(0xFFF2F2F2),
                child: resim.isNotEmpty
                    ? CachedNetworkImage(cacheManager: AppCacheManager.instance, imageUrl: resim, fit: BoxFit.cover, fadeInDuration: Duration.zero, placeholder: (_, _) => Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!, child: Container(color: Colors.white)), errorWidget: (_, _, _) => _RenkliArkaplan(cicekTipi: cicekTipi))
                    : _RenkliArkaplan(cicekTipi: cicekTipi)),
            ),
            if (yakinda)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.flight_takeoff_rounded, size: 10, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('Yakında gelecek', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            if (gosterFavori)
              Positioned(top: 2, right: 2, child: _SanaOzelFavoriButon(ilan: ilan, uid: uid)),
          ]),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (ilan.urun.isNotEmpty) Text(ilan.urun, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty)
                Row(children: [const Icon(Icons.flight_takeoff_rounded, size: 10, color: AppColors.textSecondary), const SizedBox(width: 3),
                  Expanded(child: Text('${ilan.nereden} → ${ilan.nereye}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis))]),
              if (katAdi.isNotEmpty)
                Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                    child: Text(katAdi, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.red))),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.visibility_outlined, size: 10, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text('${ref.canliGoruntulenmeSayisi(ilan)}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
                const SizedBox(width: 6),
                const Icon(Icons.favorite_border, size: 10, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text('${ref.canliFavoriSayisi(ilan)}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary)),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _RenkliArkaplan extends StatelessWidget {
  final CicekTipi cicekTipi;
  const _RenkliArkaplan({required this.cicekTipi});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: KartZeminPainter(cicekTipi),
      child: Center(child: Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.textHint.withValues(alpha: 0.4))),
    );
  }
}

// ── Favori butonu (Sana Özel kartı) ───────────────────────────────────────────

class _SanaOzelFavoriButon extends ConsumerStatefulWidget {
  final IlanModel ilan;
  final String uid;
  const _SanaOzelFavoriButon({required this.ilan, required this.uid});

  @override
  ConsumerState<_SanaOzelFavoriButon> createState() => _SanaOzelFavoriButonState();
}

class _SanaOzelFavoriButonState extends ConsumerState<_SanaOzelFavoriButon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle(bool mevcutDurum) {
    _ctrl.forward().then((_) => _ctrl.reverse());
    if (mevcutDurum) {
      ref.read(favoriProvider.notifier).cikar(widget.ilan.id);
    } else {
      ref.read(favoriProvider.notifier).ekle(widget.ilan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gosterilen = ref.watch(
      favoriliIlanIdlerProvider.select((ids) => ids.contains(widget.ilan.id)),
    );
    return GestureDetector(
      onTap: () => _toggle(gosterilen),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Icon(
              Symbols.favorite,
              fill: gosterilen ? 1 : 0,
              weight: 200,
              color: gosterilen ? AppColors.red : Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Yüksek puanlı taşıyıcılar bölümü ──────────────────────────────────────────

class _YuksekPuanliTasiyicilarBolumu extends StatelessWidget {
  final List<KullaniciModel> tasiyicilar;
  final String baslik;
  const _YuksekPuanliTasiyicilarBolumu({required this.tasiyicilar, this.baslik = 'Yüksek puanlı taşıyıcılar'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KesfetBolumBaslik(
          baslik: baslik,
          ikon: Icons.workspace_premium_outlined,
        ),
        SizedBox(
          height: 168,
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: KartZeminPainter(CicekTipi.aycicegi))),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: tasiyicilar.length,
              itemBuilder: (_, i) => _TasiyiciProfilKarti(tasiyici: tasiyicilar[i]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TasiyiciProfilKarti extends StatelessWidget {
  final KullaniciModel tasiyici;
  const _TasiyiciProfilKarti({required this.tasiyici});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KullaniciProfilScreen(
            kullaniciId: tasiyici.id,
            kullaniciAd: tasiyici.adSoyad,
          ),
        ),
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF888888), width: 0.3),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarWidget(isim: tasiyici.adSoyad, fotoUrl: tasiyici.fotoUrl, radius: 28),
            const SizedBox(height: 8),
            Text(tasiyici.adSoyad, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (tasiyici.bulunduguSehir.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(tasiyici.bulunduguSehir, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 3),
              Text('${tasiyici.ortalamaPuan.toStringAsFixed(1)} (${tasiyici.degerlendirmeSayisi})',
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── İlan aç çağrı bölümü ───────────────────────────────────────────────────────

class _IlanAcCagriBolumu extends ConsumerWidget {
  const _IlanAcCagriBolumu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.read(currentUserProvider)?.uid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(right: -24, top: -24,
                  child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
              Positioned(left: -30, bottom: -30,
                  child: Container(width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.travel_explore_rounded, size: 22, color: Color(0xFFFFC857)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('İstediğin ilanı bulamadın mı?',
                            style: GoogleFonts.urbanist(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('Aradığını bulamadıysan, ilk isteyen sen ol — saniyeler içinde ilanını yayınla.',
                        style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.78), height: 1.4)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (uid == null) {
                              loginBottomSheet(context, returnRoute: AppRoutes.ilanOlusturIstek);
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const IlanFormScreen(tip: IlanTip.istek)));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFFFFC857), borderRadius: BorderRadius.circular(12)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.shopping_bag_outlined, size: 16, color: Color(0xFF0F2027)),
                              const SizedBox(width: 6),
                              Text('İstek İlanı Aç',
                                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F2027))),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (uid == null) {
                              loginBottomSheet(context, returnRoute: AppRoutes.ilanOlusturTasiyici);
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const IlanFormScreen(tip: IlanTip.tasiyici)));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5))),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.flight_takeoff_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('Taşıyıcı İlanı Aç',
                                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sana Özel Hero Banner ─────────────────────────────────────────────────────

class _SanaOzelHeroBanner extends ConsumerWidget {
  final List<IlanModel> ilanlar;
  const _SanaOzelHeroBanner({required this.ilanlar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: const Color(0xFF7C3AED), width: 1),
        ),
        child: SizedBox(
          height: 210,
          child: Stack(
            children: [
              // İçerik
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Senin için önerilen',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 15, fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary)),
                        Text('İlgi alanlarına göre seçildi',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ilanlar.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            itemCount: ilanlar.length,
                            itemBuilder: (_, index) {
                              final ilan  = ilanlar[index];
                              final resim = ilan.gridResim;
                              return GestureDetector(
                                onTap: () {
                                  ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
                                  context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
                                },
                                child: Container(
                                  width: 95, height: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFC9A24B), width: 1),
                                  ),
                                  child: resim.isNotEmpty
                                      ? CachedNetworkImage(
                                          cacheManager: AppCacheManager.instance,
                                          imageUrl: resim,
                                          fit: BoxFit.cover,
                                          fadeInDuration: Duration.zero,
                                          placeholder: (_, _) => Shimmer.fromColors(
                                              baseColor: Colors.grey[200]!,
                                              highlightColor: Colors.grey[50]!,
                                              child: Container(color: Colors.white)))
                                      : Container(
                                          color: AppColors.surface,
                                          child: Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 26)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profil Tamamla Banner ─────────────────────────────────────────────────────

class _ProfilTamamlaBanner extends StatelessWidget {
  const _ProfilTamamlaBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 90,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFCDD2), Color(0xFFFFE4EC), Color(0xFFFFF0F5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Stack(
            children: [
              // Dekoratif daireler
              Positioned(right: -20, top: -20,
                child: Container(width: 90, height: 90,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08)))),
              Positioned(right: 40, bottom: -30,
                child: Container(width: 70, height: 70,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06)))),
              // İçerik
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_outline_rounded,
                          color: Color(0xFF880E4F), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Profilini tamamla',
                              style: GoogleFonts.urbanist(
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF880E4F))),
                          Text('Daha iyi eşleşmeler gör',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: const Color(0xFF880E4F).withValues(alpha: 0.75)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfilDuzenleScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Tamamla',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Boş ekran ─────────────────────────────────────────────────────────────────

class _SanaOzelShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 18, width: 140, color: Colors.white),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, __) => Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(height: 18, width: 100, color: Colors.white),
            const SizedBox(height: 16),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _BosEkran extends StatelessWidget {
  final String mesaj;
  const _BosEkran({required this.mesaj});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_search_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(mesaj, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      ])));
  }
}