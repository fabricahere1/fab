// lib/features/home/presentation/kesfet/tabs/kesfet_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/features/ilanlar/providers/ilan_provider.dart';
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/kesfet_computed_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/core/cache/app_cache_manager.dart';

class KesfetTab extends ConsumerStatefulWidget {
  const KesfetTab({super.key});

  @override
  ConsumerState<KesfetTab> createState() => _KesfetTabState();
}

class _KesfetTabState extends ConsumerState<KesfetTab> {
  String? _seciliKategori;

  @override
  Widget build(BuildContext context) {
    final oneCikan      = ref.watch(oneCikanIlanlarProvider);
    final yakinGelenler = ref.watch(yakinGelenIlanlarProvider);
    final suAnHavada    = ref.watch(suAnHavadaIlanlarProvider);
    final populer       = ref.watch(populerGuzergahlarProvider);
    final trendKatlar   = ref.watch(trendKategorilerProvider);
    final sonAktiviteler = ref.watch(sonAktivitelerProvider);

    final istekler    = ref.watch(istekIlanlarProvider).filtrelenmis;
    final tasiyicilar = ref.watch(tasiyiciIlanlarProvider).filtrelenmis;
    final yukleniyor  = ref.watch(istekIlanlarProvider).yukleniyor;

    final tumIlanlar = [...istekler, ...tasiyicilar]
      ..sort((a, b) => (b.olusturmaTarihi ?? DateTime(0))
          .compareTo(a.olusturmaTarihi ?? DateTime(0)));

    final filtreliIlanlar = _seciliKategori == null
        ? tumIlanlar
        : tumIlanlar
            .where((i) =>
                i.kategori == _seciliKategori ||
                i.anaKategori == _seciliKategori)
            .toList();

    // En aktif taşıyıcılar — unique kullaniciId ile
    final tasiyiciMap = <String, IlanModel>{};
    for (final i in sonAktiviteler) {
      if (i.tip == IlanTip.tasiyici &&
          !tasiyiciMap.containsKey(i.kullaniciId)) {
        tasiyiciMap[i.kullaniciId] = i;
        if (tasiyiciMap.length >= 8) break;
      }
    }
    final enAktifTasiyicilar = tasiyiciMap.values.toList();

    return CustomScrollView(
      slivers: [

        // Kategori pill bar
        SliverToBoxAdapter(
          child: _KategoriPillBar(
            seciliKategori: _seciliKategori,
            onSecildi: (k) => setState(() => _seciliKategori = k),
          ),
        ),

        if (_seciliKategori == null) ...[

          // Aktif Güzergahlar (uçuş tahtası)
          SliverToBoxAdapter(
            child: _BolumBasligi(baslik: 'AKTİF GÜZERGAHLAR', canli: true),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _UcusTahtasi(populer: populer),
            ),
          ),

          // Şu An Yolda
          if (suAnHavada.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _BolumBasligi(baslik: 'ŞU AN YOLDA ✈', canli: true),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _SuAnYoldaKart(ilanlar: suAnHavada),
              ),
            ),
          ],

          // Yakında Gelenler
          if (yakinGelenler.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _BolumBasligi(baslik: 'YAKINDA GELENLER', buton: 'Tümü →'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _YakinGelenlerListesi(ilanlar: yakinGelenler),
              ),
            ),
          ],

          // Bu Hafta Trend
          if (trendKatlar.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _BolumBasligi(baslik: 'BU HAFTA TREND'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _TrendKategoriler(kategoriler: trendKatlar),
              ),
            ),
          ],

          // Öne Çıkanlar (01/02/03 dergi stili)
          if (oneCikan.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _BolumBasligi(baslik: 'ÖNE ÇIKANLAR', buton: 'Tümü →'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _OneCikanlarListesi(
                    ilanlar: oneCikan.take(5).toList()),
              ),
            ),
          ],

          // En Aktif Taşıyıcılar
          if (enAktifTasiyicilar.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _BolumBasligi(baslik: 'EN AKTİF TAŞIYICILAR'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: enAktifTasiyicilar.length,
                  itemBuilder: (_, i) {
                    final ilan = enAktifTasiyicilar[i];
                    final sayi = sonAktiviteler
                        .where((x) => x.kullaniciId == ilan.kullaniciId)
                        .length;
                    return _TasiyiciAvatar(
                      ad: ilan.kullaniciAd,
                      ilanSayisi: sayi,
                    );
                  },
                ),
              ),
            ),
          ],

          // Popüler Güzergahlar
          if (populer.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _BolumBasligi(baslik: 'POPÜLER GÜZERGAHLAR'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: populer.length,
                  itemBuilder: (_, i) => _GuzergahPill(
                    guzergah: populer[i],
                    hot: i < 2,
                  ),
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],

        // Tüm İlanlar başlığı
        SliverToBoxAdapter(
          child: _BolumBasligi(
            baslik: _seciliKategori == null
                ? 'TÜM İLANLAR'
                : kategoriAdi(_seciliKategori).toUpperCase(),
            buton: '${filtreliIlanlar.length} ilan',
          ),
        ),

        // Grid
        if (yukleniyor)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, _) => _SkeletonKart(),
                childCount: 6,
              ),
            ),
          )
        else if (filtreliIlanlar.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'Bu kategoride ilan yok',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) =>
                    _KaranlikIlanKarti(ilan: filtreliIlanlar[i]),
                childCount: filtreliIlanlar.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YARDIMCI WİDGET'LAR
// ─────────────────────────────────────────────────────────────────────────────

// ── Bölüm Başlığı ─────────────────────────────────────────────────────────────

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  final String? buton;
  final bool canli;
  const _BolumBasligi({required this.baslik, this.buton, this.canli = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        children: [
          Text(
            baslik,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF888888),
              letterSpacing: 1.5,
            ),
          ),
          if (canli) ...[
            const SizedBox(width: 8),
            Container(
              width: 5, height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50), shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'CANLI',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4CAF50),
                letterSpacing: 0.5,
              ),
            ),
          ],
          const Spacer(),
          if (buton != null)
            Text(
              buton!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Kategori Pill Bar ─────────────────────────────────────────────────────────

class _KategoriPillBar extends StatelessWidget {
  final String? seciliKategori;
  final ValueChanged<String?> onSecildi;
  const _KategoriPillBar({required this.seciliKategori, required this.onSecildi});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFFF5F5F5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        itemCount: kKategoriAgaci.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _Pill(
              label: '✦  Tümü',
              secili: seciliKategori == null,
              onTap: () => onSecildi(null),
            );
          }
          final kat    = kKategoriAgaci[i - 1];
          final secili = seciliKategori == kat.key;
          return _Pill(
            label: kat.emoji.isNotEmpty
                ? '${kat.emoji}  ${kat.ad}'
                : kat.ad,
            secili: secili,
            onTap: () => onSecildi(secili ? null : kat.key),
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool secili;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.secili, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: secili
              ? AppColors.red
              : const Color(0xFFEBEBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: secili
                ? AppColors.red
                : const Color(0xFFEBEBEB),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: secili
                ? Colors.white
                : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}

// ── Uçuş Tahtası ─────────────────────────────────────────────────────────────

class _UcusTahtasi extends StatelessWidget {
  final List<GuzergahSatiri> populer;
  const _UcusTahtasi({required this.populer});

  @override
  Widget build(BuildContext context) {
    final rows = populer.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEBEBEB), width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _BhText('GÜZERGAH', flex: 2),
                _BhText('DURUM', flex: 2, center: true),
                _BhText('İLAN', flex: 1, right: true),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Veri yükleniyor...',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFFBBBBBB)),
              ),
            )
          else
            ...rows.map((g) {
              final durum = g.ilanSayisi >= 5
                  ? 'AKTİF'
                  : g.ilanSayisi >= 2
                      ? 'SINIRLI'
                      : 'AZ';
              final n1 = g.nereden.split(' ').first.toUpperCase();
              final n2 = g.nereye.split(' ').first.toUpperCase();
              return _TahtaSatiri(
                kod: '$n1→$n2',
                durum: durum,
                sayi: g.ilanSayisi,
                onIlanaGit: null,
              );
            }),
        ],
      ),
    );
  }
}

class _BhText extends StatelessWidget {
  final String text;
  final int flex;
  final bool center;
  final bool right;
  const _BhText(this.text,
      {this.flex = 1, this.center = false, this.right = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center
            ? TextAlign.center
            : right
                ? TextAlign.right
                : TextAlign.left,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFCCCCCC),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TahtaSatiri extends StatelessWidget {
  final String kod;
  final String durum;
  final int sayi;
  final VoidCallback? onIlanaGit;

  const _TahtaSatiri({
    required this.kod,
    required this.durum,
    required this.sayi,
    this.onIlanaGit,
  });

Color get _renkOnd {
    if (durum == 'AKTİF') return const Color(0xFF4CAF50);
    if (durum == 'SINIRLI') return const Color(0xFFFFC107);
    return const Color(0xFF999999); // AZ
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: const Color(0xFFF2F2F2), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              kod,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _renkOnd.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  durum,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _renkOnd,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$sayi',
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFAAAAAA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Şu An Yolda ───────────────────────────────────────────────────────────────

class _SuAnYoldaKart extends StatelessWidget {
  final List<IlanModel> ilanlar;
  const _SuAnYoldaKart({required this.ilanlar});

  String _eta(IlanModel i) {
    if (i.tarih == null) return '';
    final fark = i.tarih!.difference(DateTime.now()).inDays;
    if (fark == 0) return 'BUGÜN İNİYOR';
    if (fark == 1) return 'YARIN';
    return '$fark GÜN';
  }

  Color _etaRenk(IlanModel i) {
    if (i.tarih == null) return const Color(0xFF64B5F6);
    final fark = i.tarih!.difference(DateTime.now()).inDays;
    if (fark == 0) return AppColors.red;
    if (fark <= 2) return const Color(0xFFFFC107);
    return const Color(0xFF64B5F6);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
            width: 0.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded,
                  size: 14, color: Color(0xFF64B5F6)),
              const SizedBox(width: 6),
              Text(
                '${ilanlar.length} kişi şu an havada',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4, height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CANLI',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4CAF50),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...ilanlar.map((ilan) {
            final eta  = _eta(ilan);
            final eRenk = _etaRenk(ilan);
            return Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flight_rounded,
                        size: 14, color: Color(0xFF64B5F6)),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ilan.nereden} → ${ilan.nereye}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ilan.urun.isNotEmpty)
                          Text(
                            ilan.urun,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFFAAAAAA),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (eta.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: eRenk.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        eta,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: eRenk,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Yakında Gelenler ──────────────────────────────────────────────────────────

class _YakinGelenlerListesi extends ConsumerWidget {
  final List<IlanModel> ilanlar;
  const _YakinGelenlerListesi({required this.ilanlar});

  String _whenText(IlanModel i) {
    if (i.tarih == null) return '';
    final fark = i.tarih!.difference(DateTime.now()).inDays;
    if (fark == 0) return 'BUGÜN';
    if (fark == 1) return 'YARIN';
    return '$fark GÜN';
  }

  Color _whenColor(IlanModel i) {
    if (i.tarih == null) return const Color(0xFFBBBBBB);
    final fark = i.tarih!.difference(DateTime.now()).inDays;
    if (fark == 0) return AppColors.red;
    if (fark <= 2) return const Color(0xFFFFC107);
    return const Color(0xFFBBBBBB);
  }

  Color _ikonRenk(int index) {
    const list = [
      Color(0xFFE24B4A), Color(0xFF1565C0),
      Color(0xFF2E7D32), Color(0xFF6A1B9A), Color(0xFFE65100),
    ];
    return list[index % list.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: ilanlar.asMap().entries.map((e) {
        final idx   = e.key;
        final ilan  = e.value;
        final wt    = _whenText(ilan);
        final wc    = _whenColor(ilan);
        final renk  = _ikonRenk(idx);

        return GestureDetector(
          onTap: () {
            ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
            context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFF0F0F0),
                  width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: renk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      size: 16, color: renk),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ilan.urun.isNotEmpty
                            ? ilan.urun
                            : '${ilan.nereden} → ${ilan.nereye}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '✈ ${ilan.nereden} → ${ilan.nereye}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFFBBBBBB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (wt.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: wc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      wt,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: wc,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Trend Kategoriler ─────────────────────────────────────────────────────────

class _TrendKategoriler extends StatelessWidget {
  final List<TrendKategori> kategoriler;
  const _TrendKategoriler({required this.kategoriler});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 2.8,
      ),
      itemCount: kategoriler.length,
      itemBuilder: (_, i) {
        final k         = kategoriler[i];
        final yukseliyor = k.degisimYuzdesi >= 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFEEEEEE), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Text(k.emoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      k.ad,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${k.ilanSayisi} ilan',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: const Color(0xFFBBBBBB),
                      ),
                    ),
                  ],
                ),
              ),
              if (k.degisimYuzdesi != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (yukseliyor
                            ? const Color(0xFF4CAF50)
                            : AppColors.red)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${yukseliyor ? '+' : ''}${k.degisimYuzdesi.toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: yukseliyor
                          ? const Color(0xFF4CAF50)
                          : AppColors.red,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Öne Çıkanlar (01/02/03 dergi stili) ──────────────────────────────────────

class _OneCikanlarListesi extends ConsumerWidget {
  final List<IlanModel> ilanlar;
  const _OneCikanlarListesi({required this.ilanlar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: ilanlar.asMap().entries.map((e) {
        final idx  = e.key;
        final ilan = e.value;
        return GestureDetector(
          onTap: () {
            ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
            context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: const Color(0xFFF0F0F0),
                    width: 0.5),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    (idx + 1).toString().padLeft(2, '0'),
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFEBEBEB),
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 42, height: 42,
                    color: const Color(0xFFF0F0F0),
                    child: ilan.tumResimler.isNotEmpty
                        ? CachedNetworkImage(
                            cacheManager: AppCacheManager.instance,
                            imageUrl: ilan.tumResimler.first,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                          )
                        : Icon(
                            Icons.inventory_2_rounded,
                            size: 18,
                            color: const Color(0xFFDDDDDD),
                          ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ilan.urun.isNotEmpty
                            ? ilan.urun
                            : '${ilan.nereden} → ${ilan.nereye}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '✈ ${ilan.nereden} → ${ilan.nereye}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFFBBBBBB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ilan.kategori.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '● ${kategoriAdi(ilan.kategori).toUpperCase()}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Taşıyıcı Avatar ───────────────────────────────────────────────────────────

class _TasiyiciAvatar extends StatelessWidget {
  final String ad;
  final int ilanSayisi;
  const _TasiyiciAvatar({required this.ad, required this.ilanSayisi});

  Color get _renk {
    const list = [
      Color(0xFFE24B4A), Color(0xFF1565C0),
      Color(0xFF2E7D32), Color(0xFF6A1B9A), Color(0xFFE65100),
    ];
    return list[ad.hashCode.abs() % list.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_renk, _renk.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFEEEEEE),
                      width: 1.5),
                ),
                child: Center(
                  child: Text(
                    ad.isNotEmpty ? ad[0].toUpperCase() : '?',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -1, right: -1,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFF5F5F5), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$ilanSayisi',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 48,
            child: Text(
              '$ilanSayisi ilan',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFAAAAAA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Güzergah Pill ─────────────────────────────────────────────────────────────

class _GuzergahPill extends StatelessWidget {
  final GuzergahSatiri guzergah;
  final bool hot;
  const _GuzergahPill({required this.guzergah, required this.hot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: hot
            ? AppColors.red.withValues(alpha: 0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hot
              ? AppColors.red.withValues(alpha: 0.2)
              : const Color(0xFFEBEBEB),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✈ ${guzergah.nereden.split(' ').first}→${guzergah.nereye.split(' ').first}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hot
                  ? AppColors.red
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${guzergah.ilanSayisi}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Karanlık İlan Kartı ───────────────────────────────────────────────────────

class _KaranlikIlanKarti extends ConsumerWidget {
  final IlanModel ilan;
  const _KaranlikIlanKarti({required this.ilan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resimler = ilan.tumResimler;
    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFEBEBEB), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  resimler.isNotEmpty
                      ? CachedNetworkImage(
                          cacheManager: AppCacheManager.instance,
                          imageUrl: resimler.first,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          errorWidget: (ctx, err, _) => _placeHolder,
                        )
                      : _placeHolder,
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7, left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: (ilan.tip == IlanTip.istek
                                ? AppColors.red
                                : const Color(0xFF1565C0))
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        ilan.tip == IlanTip.istek
                            ? 'İSTEK'
                            : 'TAŞIYICI',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ilan.urun.isNotEmpty
                          ? ilan.urun
                          : '${ilan.nereden} → ${ilan.nereye}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.flight_rounded,
                          size: 9,
                          color: const Color(0xFFCCCCCC),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${ilan.nereden} → ${ilan.nereye}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color:
                                  const Color(0xFFCCCCCC),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _placeHolder => Container(
        color: const Color(0xFFF0F0F0),
        child: Center(
          child: Icon(
            Icons.inventory_2_rounded,
            size: 28,
            color: const Color(0xFFF0F0F0),
          ),
        ),
      );
}

// ── Skeleton Kart ─────────────────────────────────────────────────────────────

class _SkeletonKart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}