// lib/features/home/presentation/kesfet/tabs/canli_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/shared/constants/app_constants.dart' show IlanTip;
import 'package:iste_v3/router/app_router.dart';
import 'package:iste_v3/features/home/providers/kesfet_computed_providers.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/core/cache/app_cache_manager.dart';

class CanliTab extends ConsumerWidget {
  const CanliTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final istatistik     = ref.watch(kesfetIstatistikProvider);
    final sonAktiviteler = ref.watch(sonAktivitelerProvider);
    final trendKatlar    = ref.watch(trendKategorilerProvider);
    final spotlight      = ref.watch(spotlightIlanProvider);
    final flashIlanlar   = ref.watch(flashIlanlarProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [

        // ── Anlık Durum ────────────────────────────────────────────────────
        _BolumBasligi(baslik: 'ANLIK DURUM', canli: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _AnlikDurumRow(istatistik: istatistik),
        ),

        // ── Bu Haftanın Yıldızı (Spotlight) ──────────────────────────────
        if (spotlight != null) ...[
          _BolumBasligi(baslik: 'BU HAFTANIN YILDIZI'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _SpotlightKart(spotlight: spotlight),
          ),
        ],

        // ── Canlı Akış (Feed) ─────────────────────────────────────────────
        _BolumBasligi(baslik: 'CANLI AKIŞ', canli: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _CanliAkis(ilanlar: sonAktiviteler),
        ),

        // ── Kategori Isı Grafiği ───────────────────────────────────────────
        if (trendKatlar.isNotEmpty) ...[
          _BolumBasligi(baslik: 'KATEGORİ ISISI'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _KategoriIsiGrafigi(kategoriler: trendKatlar),
          ),
        ],

        // ── Flash İlanlar (son 1 saat) ─────────────────────────────────────
        if (flashIlanlar.isNotEmpty) ...[
          _BolumBasligi(baslik: '⚡ SON 1 SAATTE EKLENDİ'),
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: flashIlanlar.length,
              itemBuilder: (_, i) => _FlashKart(
                ilan: flashIlanlar[i],
                onTap: () {
                  ref
                      .read(sonGoruntulenenlerProvider.notifier)
                      .kaydet(flashIlanlar[i]);
                  context.push(
                    AppRoutes.ilanDetayPath(flashIlanlar[i].id),
                    extra: flashIlanlar[i],
                  );
                },
              ),
            ),
          ),
        ],

        // ── Tüm ilanlar yoksa bilgi mesajı ────────────────────────────────
        if (sonAktiviteler.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 48,
                      color: const Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz aktivite yok',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
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
  final bool canli;
  const _BolumBasligi({required this.baslik, this.canli = false});

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
        ],
      ),
    );
  }
}

// ── Anlık Durum Row ───────────────────────────────────────────────────────────

class _AnlikDurumRow extends StatelessWidget {
  final KesfetIstatistik istatistik;
  const _AnlikDurumRow({required this.istatistik});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatKart(
          sayi: '${istatistik.toplamAktif}',
          label: 'aktif ilan',
          renk: AppColors.red,
        ),
        const SizedBox(width: 6),
        _StatKart(
          sayi: '${istatistik.bugunEklenen}',
          label: 'bugün eklendi',
          renk: const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 6),
        _StatKart(
          sayi: '${istatistik.suAnYolda}',
          label: 'şu an yolda',
          renk: const Color(0xFF64B5F6),
        ),
      ],
    );
  }
}

class _StatKart extends StatelessWidget {
  final String sayi;
  final String label;
  final Color renk;
  const _StatKart(
      {required this.sayi, required this.label, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              sayi,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: renk,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFFBBBBBB),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Spotlight Kart ────────────────────────────────────────────────────────────

class _SpotlightKart extends ConsumerWidget {
  final SpotlightIlan spotlight;
  const _SpotlightKart({required this.spotlight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ilan = spotlight.ilan;
    return GestureDetector(
      onTap: () {
        ref.read(sonGoruntulenenlerProvider.notifier).kaydet(ilan);
        context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A00), Color(0xFF3D1500)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.red.withValues(alpha: 0.2), width: 0.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✦  EN ÇOK İSTENEN',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ilan.urun.isNotEmpty
                  ? ilan.urun
                  : '${ilan.nereden} → ${ilan.nereye}',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            if (ilan.nereden.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '✈ ${ilan.nereden} → ${ilan.nereye}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${spotlight.istemeSayisi}',
                  style: GoogleFonts.dmSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'aktif istek',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Canlı Akış Feed ───────────────────────────────────────────────────────────

class _CanliAkis extends ConsumerWidget {
  final List<IlanModel> ilanlar;
  const _CanliAkis({required this.ilanlar});

  String _zamanYazi(IlanModel i) {
    if (i.olusturmaTarihi == null) return '';
    final fark = DateTime.now().difference(i.olusturmaTarihi!);
    if (fark.inSeconds < 60) return '${fark.inSeconds}sn';
    if (fark.inMinutes < 60) return '${fark.inMinutes}dk';
    if (fark.inHours < 24) return '${fark.inHours}sa';
    return '${fark.inDays}g';
  }

  Color _avatarRenk(String uid) {
    const list = [
      Color(0xFFE24B4A), Color(0xFF1565C0),
      Color(0xFF2E7D32), Color(0xFF6A1B9A), Color(0xFFE65100),
    ];
    return list[uid.hashCode.abs() % list.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ilanlar.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Henüz aktivite yok',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFFBBBBBB),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        children: ilanlar.take(8).toList().asMap().entries.map((e) {
          final idx  = e.key;
          final ilan = e.value;
          final zaman = _zamanYazi(ilan);
          final renk  = _avatarRenk(ilan.kullaniciId);
          final isIstek = ilan.tip == IlanTip.istek;
          final isNew   = idx == 0;

          return Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: e.key < (ilanlar.take(8).length - 1)
                    ? BorderSide(
                        color: const Color(0xFFF2F2F2),
                        width: 0.5)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [renk, renk.withValues(alpha: 0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      ilan.nereden.isNotEmpty
                          ? ilan.nereden[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık satırı
                      Row(
                        children: [
                          Text(
                            ilan.nereden.isNotEmpty
                                ? '${ilan.nereden}\'dan biri'
                                : 'Biri',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isIstek ? 'istedi' : 'güzergah açtı',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFFAAAAAA),
                            ),
                          ),
                          const Spacer(),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'YENİ',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.red,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else if (zaman.isNotEmpty)
                            Text(
                              zaman,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: const Color(0xFFCCCCCC),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Ürün/güzergah
                      Text(
                        ilan.urun.isNotEmpty
                            ? '${ilan.urun} · ${ilan.nereden}→${ilan.nereye}'
                            : '${ilan.nereden} → ${ilan.nereye}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF555555),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isIstek
                              ? AppColors.red.withValues(alpha: 0.12)
                              : const Color(0xFF64B5F6)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isIstek ? '● İSTEK' : '✈ TAŞIYICI',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isIstek
                                ? AppColors.red
                                : const Color(0xFF64B5F6),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Kategori Isı Grafiği ──────────────────────────────────────────────────────

class _KategoriIsiGrafigi extends StatelessWidget {
  final List<TrendKategori> kategoriler;
  const _KategoriIsiGrafigi({required this.kategoriler});

  @override
  Widget build(BuildContext context) {
    final maxSayi = kategoriler.isEmpty
        ? 1
        : kategoriler
            .map((k) => k.ilanSayisi)
            .reduce((a, b) => a > b ? a : b);

    final barRenkler = [
      const LinearGradient(colors: [Color(0xFFE24B4A), Color(0xFFFF6B6B)]),
      const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
      const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
      const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFFA726)]),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: kategoriler.asMap().entries.map((e) {
          final idx = e.key;
          final k   = e.value;
          final oran = maxSayi == 0 ? 0.0 : k.ilanSayisi / maxSayi;
          final yukseliyor = k.degisimYuzdesi >= 0;
          final gradient   = barRenkler[idx % barRenkler.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(k.emoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    k.ad,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      color: const Color(0xFFF0F0F0),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: oran,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 22,
                  child: Text(
                    '${k.ilanSayisi}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFBBBBBB),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (k.degisimYuzdesi != 0)
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${yukseliyor ? '+' : ''}${k.degisimYuzdesi.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
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
        }).toList(),
      ),
    );
  }
}

// ── Flash Kart ────────────────────────────────────────────────────────────────

class _FlashKart extends StatelessWidget {
  final IlanModel ilan;
  final VoidCallback onTap;
  const _FlashKart({required this.ilan, required this.onTap});

  String _zamanYazi() {
    if (ilan.olusturmaTarihi == null) return '';
    final fark = DateTime.now().difference(ilan.olusturmaTarihi!);
    if (fark.inMinutes < 1) return 'Az önce';
    return '${fark.inMinutes} dk önce';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.red.withValues(alpha: 0.2), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ilan.tumResimler.isNotEmpty
                      ? CachedNetworkImage(
                          cacheManager: AppCacheManager.instance,
                          imageUrl: ilan.tumResimler.first,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          errorWidget: (ctx, err, _) => Container(
                            color: const Color(0xFFF0F0F0),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 24,
                              color: const Color(0xFFF0F0F0),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0F0F0),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            size: 24,
                            color: const Color(0xFFF0F0F0),
                          ),
                        ),
                  // Badge
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⚡ YENİ',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bilgi
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : ilan.nereden,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_zamanYazi().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _zamanYazi(),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFFCCCCCC),
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
  }
}