// lib/features/home/presentation/kesfet_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../ilanlar/presentation/ilan_detay_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import '../../../shared/constants/app_constants.dart' show kKategoriAgaci, IlanTip;
import '../../../core/cache/app_cache_manager.dart';

final _sonGorutulenler = <IlanModel>[];

void ilanGoruntulendiKaydet(IlanModel ilan) {
  _sonGorutulenler.removeWhere((i) => i.id == ilan.id);
  _sonGorutulenler.insert(0, ilan);
  if (_sonGorutulenler.length > 10) _sonGorutulenler.removeLast();
}

// Renkler
const _baslikRenk = Color(0xFF333333);
const _morZemin = Color(0xFF7C3AED);
const _turuncuZemin = Color(0xFFFF6B2B);

class KesfetScreen extends ConsumerStatefulWidget {
  const KesfetScreen({super.key});

  @override
  ConsumerState<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends ConsumerState<KesfetScreen> {
  final _scrollController = ScrollController();
  String? _seciliKategori;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(istekIlanlarProvider.notifier).dahaFazlaYukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(istekIlanlarProvider);
    final tasiyiciState = ref.watch(tasiyiciIlanlarProvider);

    final tumIlanlar = [
      ...state.filtrelenmis,
      ...tasiyiciState.filtrelenmis,
    ]..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
        .compareTo(a.olusturmaTarihi ?? DateTime(0)));

    final filtreli = _seciliKategori == null
        ? tumIlanlar
        : tumIlanlar.where((i) => i.kategori == _seciliKategori).toList();

    final oneCikan10 = ([...tumIlanlar]
          ..sort((a, b) => b.favoriSayisi.compareTo(a.favoriSayisi)))
        .take(10)
        .toList();

    final yakinGelenler = (tasiyiciState.filtrelenmis
        .where((i) => i.tarih != null && i.tarih!.isAfter(DateTime.now()))
        .toList()
          ..sort((a, b) => a.tarih!.compareTo(b.tarih!)))
        .take(4)
        .toList();

    final yediGunOnce = DateTime.now().subtract(const Duration(days: 7));
    final yeniIlanlar = tumIlanlar
        .where((i) => i.olusturmaTarihi != null &&
            i.olusturmaTarihi!.isAfter(yediGunOnce))
        .take(15)
        .toList();

    final Map<String, int> guzergahSayisi = {};
    for (final ilan in tasiyiciState.filtrelenmis) {
      if (ilan.nereden.isNotEmpty && ilan.nereye.isNotEmpty) {
        final key = '${ilan.nereden} → ${ilan.nereye}';
        guzergahSayisi[key] = (guzergahSayisi[key] ?? 0) + 1;
      }
    }
    final top5Guzergah = (guzergahSayisi.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    final Map<String, int> kategoriSayisi = {};
    for (final ilan in tumIlanlar) {
      if (ilan.kategori.isNotEmpty) {
        kategoriSayisi[ilan.kategori] = (kategoriSayisi[ilan.kategori] ?? 0) + 1;
      }
    }
    final popKategori = (kategoriSayisi.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)));
    final sanaOzel = popKategori.isNotEmpty
        ? tumIlanlar
            .where((i) => i.kategori == popKategori.first.key)
            .take(10)
            .toList()
        : <IlanModel>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [

          // ── App Bar ───────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text('Keşfet',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.red)),
          ),

          // ── Kategori Filtreleri — siyah beyaz ────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _KategoriChip(
                      label: 'Tümü',
                      emoji: '✦',
                      secili: _seciliKategori == null,
                      onTap: () => setState(() => _seciliKategori = null),
                    ),
                    const SizedBox(width: 8),
                    ...kKategoriAgaci.map((ana) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _KategoriChip(
                        label: ana.ad,
                        emoji: ana.emoji,
                        secili: _seciliKategori == ana.key,
                        onTap: () => setState(() =>
                            _seciliKategori =
                                _seciliKategori == ana.key ? null : ana.key),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),

          // ── Filtre aktifken sadece grid ───────────────────────
          if (_seciliKategori != null) ...[
            _BolumBasligi('İlanlar'),
            filtreli.isEmpty
                ? SliverToBoxAdapter(child: _BosFiltre())
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childCount: filtreli.length,
                      itemBuilder: (_, i) => RepaintBoundary(
                        child: _KesfetKarti(ilan: filtreli[i]),
                      ),
                    ),
                  ),
          ],

          if (_seciliKategori == null) ...[

            // Son Görüntülenenler
            if (_sonGorutulenler.isNotEmpty) ...[
              _BolumBasligi('Son görüntülenenler'),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    itemCount: _sonGorutulenler.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _KucukKart(ilan: _sonGorutulenler[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Öne Çıkanlar
            if (oneCikan10.isNotEmpty) ...[
              _BolumBasligi('Öne çıkanlar'),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    itemCount: oneCikan10.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _KucukKart(ilan: oneCikan10[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Bir Kaç Güne Oradayım — başlık koyu gri farklı fon
            if (yakinGelenler.isNotEmpty) ...[
              _BolumBasligiOzel('Bir kaç güne oradayım'),
              SliverToBoxAdapter(
                child: Column(
                  children: yakinGelenler
                      .map((ilan) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: _YakindaGelenKart(ilan: ilan),
                          ))
                      .toList(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // Popüler Güzergahlar
            if (top5Guzergah.isNotEmpty) ...[
              _BolumBasligi('Popüler güzergahlar'),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: top5Guzergah.map((entry) {
                      final parts = entry.key.split(' → ');
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _GuzergahChip(
                          nereden: parts.first,
                          nereye: parts.length > 1 ? parts.last : '',
                          sayi: entry.value,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Sana Özel
            if (sanaOzel.isNotEmpty) ...[
              _BolumBasligi(
                popKategori.isNotEmpty
                    ? 'Sana özel — ${app_constants.kategoriAdi(popKategori.first.key)}'
                    : 'Sana özel',
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    itemCount: sanaOzel.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _KucukKart(ilan: sanaOzel[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Yeni Eklenenler — son 7 gün, max 15 ilan
            if (yeniIlanlar.isNotEmpty) ...[
              _BolumBasligi('Yeni eklenenler — son 7 gün'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childCount: yeniIlanlar.length,
                  itemBuilder: (_, i) => RepaintBoundary(
                    child: _KesfetKarti(ilan: yeniIlanlar[i]),
                  ),
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Center(
                    child: Text('Son 7 günde yeni ilan yok',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Normal Bölüm Başlığı — koyu gri ──────────────────────────────────────────

Widget _BolumBasligi(String baslik) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Text(baslik,
          style: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w700, color: _baslikRenk)),
    ),
  );
}

// ── "Bir Kaç Güne Oradayım" Başlığı — farklı fon + koyu gri ─────────────────

Widget _BolumBasligiOzel(String baslik) {
  return SliverToBoxAdapter(
    child: Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: const Color(0xFFF0EBFF),
      child: Row(
        children: [
          const Icon(Icons.flight_takeoff_outlined, size: 16, color: _baslikRenk),
          const SizedBox(width: 8),
          Text(baslik,
              style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _baslikRenk)),
        ],
      ),
    ),
  );
}

// ── Kategori Chip — siyah beyaz ───────────────────────────────────────────────

class _KategoriChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool secili;
  final VoidCallback onTap;

  const _KategoriChip({
    required this.label, required this.emoji,
    required this.secili, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: secili ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: secili ? const Color(0xFF1A1A1A) : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secili ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Küçük Kart ────────────────────────────────────────────────────────────────

class _KucukKart extends StatelessWidget {
  final IlanModel ilan;
  const _KucukKart({required this.ilan});

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;

    return GestureDetector(
      onTap: () {
        ilanGoruntulendiKaydet(ilan);
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ));
      },
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 70, width: double.infinity,
                child: resimler.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resimler.first,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        memCacheWidth: 220,
                        placeholder: (_, __) => _ResimPlaceholder(ilan: ilan),
                        errorWidget: (_, __, ___) => _ResimPlaceholder(ilan: ilan),
                      )
                    : _ResimPlaceholder(ilan: ilan),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty
                        ? ilan.urun
                        : '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ilan.ucret.isNotEmpty)
                    Text('${ilan.ucret} ₺',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bir Kaç Güne Oradayım Kartı — mavi gradient, turuncu badge ───────────────

class _YakindaGelenKart extends StatelessWidget {
  final IlanModel ilan;
  const _YakindaGelenKart({required this.ilan});

  @override
  Widget build(BuildContext context) {
    final fark = ilan.tarih!.difference(DateTime.now()).inDays;
    final String zamanYazisi = fark == 0
        ? 'Bugün!'
        : fark == 1
            ? 'Yarın'
            : '$fark gün sonra';

    return GestureDetector(
      onTap: () {
        ilanGoruntulendiKaydet(ilan);
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Açık maviden beyaza gradient
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF90CAF9), Color(0xFFF5FBFF)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          children: [
            // Koyu mavi uçak ikonu
            const Icon(Icons.flight_takeoff_outlined, size: 20, color: Color(0xFF1565C0)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(ilan.kullaniciAd,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF555555))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Turuncu zaman badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C42),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(zamanYazisi,
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                if (ilan.ucret.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${ilan.ucret} ₺',
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Popüler Güzergah Chip — turuncu zemin, beyaz yazı ────────────────────────

class _GuzergahChip extends StatelessWidget {
  final String nereden;
  final String nereye;
  final int sayi;

  const _GuzergahChip({
    required this.nereden, required this.nereye, required this.sayi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFB74D), Color(0xFFFFF8F0)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(nereden,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 11, color: Color(0xFF555555)),
              ),
              Text(nereye,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 3),
          Text('$sayi ilan',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF777777))),
        ],
      ),
    );
  }
}

// ── Keşfet Masonry Kartı ──────────────────────────────────────────────────────

class _KesfetKarti extends StatelessWidget {
  final IlanModel ilan;
  const _KesfetKarti({required this.ilan});

  double _yukseklik() {
    final heights = [110.0, 130.0, 100.0, 120.0, 140.0, 105.0];
    return heights[ilan.id.hashCode.abs() % heights.length];
  }

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    final kategoriAdiStr = app_constants.kategoriAdi(ilan.kategori);

    return GestureDetector(
      onTap: () {
        ilanGoruntulendiKaydet(ilan);
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => IlanDetayScreen(ilan: ilan),
          transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: _yukseklik(), width: double.infinity,
                child: resimler.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: resimler.first,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        memCacheWidth: 280,
                        placeholder: (_, __) => _ResimPlaceholder(ilan: ilan),
                        errorWidget: (_, __, ___) => _ResimPlaceholder(ilan: ilan),
                      )
                    : _ResimPlaceholder(ilan: ilan),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty
                        ? ilan.urun
                        : '${ilan.nereden} → ${ilan.nereye}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ilan.ucret.isNotEmpty
                              ? '${ilan.ucret} ₺'
                              : 'Belirtilmemiş',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: ilan.ucret.isNotEmpty
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: ilan.ucret.isNotEmpty
                                ? AppColors.red
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (kategoriAdiStr.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.chipBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(kategoriAdiStr,
                              style: GoogleFonts.dmSans(
                                  fontSize: 8,
                                  color: AppColors.textSecondary)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resim Placeholder ─────────────────────────────────────────────────────────

class _ResimPlaceholder extends StatelessWidget {
  final IlanModel ilan;
  const _ResimPlaceholder({required this.ilan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Icon(
          ilan.tip == IlanTip.tasiyici
              ? Icons.flight_takeoff_outlined
              : Icons.shopping_bag_outlined,
          color: AppColors.red.withValues(alpha: 0.3),
          size: 22,
        ),
      ),
    );
  }
}

// ── Boş Filtre ────────────────────────────────────────────────────────────────

class _BosFiltre extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined,
                size: 44, color: AppColors.divider),
            const SizedBox(height: 10),
            Text('Bu kategoride ilan yok',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}