// lib/features/home/presentation/dunya_trendleri_bolum.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';

// ── Veri modeli ───────────────────────────────────────────────────────────────

enum _TrendBadge { viral, yukselis, yeni }

enum _TrendKat { tumu, moda, guzellik, elektronik, ev, spor }

class _Trend {
  final String ad;
  final String ulke;
  final String ulkeBayrak;
  final String kategori;
  final String aciklama;
  final _TrendBadge badge;
  final String badgeMetin;
  final _TrendKat kat;
  const _Trend(this.ad, this.ulke, this.ulkeBayrak, this.kategori,
      this.aciklama, this.badge, this.badgeMetin, this.kat);
}

const _trendler = [
  _Trend('Loewe Amazona 180', 'İspanya', '🇪🇸', 'Çanta',
      "Yeni tasarımcıların Loewe için ilk koleksiyonu. Spring 2026 en çok konuşulan çanta.",
      _TrendBadge.yeni, 'Yeni', _TrendKat.moda),
  _Trend('NARS Natural Matte Foundation', 'Amerika', '🇺🇸', 'Kozmetik',
      "Mat görünümü sevenler için yeni favorileri. TikTok'ta Mart 2026'dan beri viral.",
      _TrendBadge.viral, 'Viral', _TrendKat.guzellik),
  _Trend('Satchel çanta', 'Global', '🌍', 'Çanta',
      "Shopify verilerine göre 2026'nın en hızlı büyüyen aksesuar kategorisi.",
      _TrendBadge.yukselis, '↑ %831', _TrendKat.moda),
  _Trend('Puffer ceket', 'Global', '🌍', 'Giyim',
      "2026 en hızlı büyüyen giyim kategorisi. Kuzey Amerika ve Avrupa'da patladı.",
      _TrendBadge.yukselis, '↑ %819', _TrendKat.moda),
  _Trend('COSRX Advanced Snail Serum', 'Güney Kore', '🇰🇷', 'Cilt Bakımı',
      "Amazon Best Sellers 1. sıra. Türkiye'de sahte çok, Kore'den orijinali getir.",
      _TrendBadge.viral, 'Viral', _TrendKat.guzellik),
  _Trend('Mighty Patch sivilce bandı', 'Amerika', '🇺🇸', 'Cilt Bakımı',
      "140.000+ Amazon yorumu. Ünlüler bile yüzünde takıyor. Türkiye'de yok.",
      _TrendBadge.viral, 'Viral', _TrendKat.guzellik),
  _Trend('Crop top', 'Global', '🌍', 'Giyim',
      "2026 yaz sezonu dominant trendi. Her markada farklı versiyonları çıktı.",
      _TrendBadge.yukselis, '↑ %758', _TrendKat.moda),
  _Trend('Dyson Airwrap 2026', 'İngiltere', '🇬🇧', 'Saç Bakım',
      "Yeni versiyon çıktı. UK'de Türkiye'den %25 ucuz, garanti ile.",
      _TrendBadge.yukselis, '↑ Yükseliyor', _TrendKat.elektronik),
  _Trend('Merit Beauty & Jones Road', 'Amerika', '🇺🇸', 'Kozmetik',
      "Mayıs 2026 beauty favoritlerinin başında. Clean beauty trendi liderleri.",
      _TrendBadge.yukselis, '↑ Yükseliyor', _TrendKat.guzellik),
  _Trend('New Balance 1906R', 'Amerika', '🇺🇸', 'Sneaker',
      "Retro runner trendinin lideri. ABD'de Türkiye fiyatının yarısı.",
      _TrendBadge.yukselis, '↑ Yükseliyor', _TrendKat.spor),
  _Trend('Stanley Quencher H2.0', 'Amerika', '🇺🇸', 'Ev & Yaşam',
      "Yeni 2026 renk koleksiyonu çıktı. TikTok'ta hala gündem.",
      _TrendBadge.viral, 'Viral', _TrendKat.ev),
  _Trend('Glossier You Solid Parfüm', 'Amerika', '🇺🇸', 'Parfüm',
      "Mayıs 2026 beauty favorilerinin sürprizi. Türkiye'de resmi satış yok.",
      _TrendBadge.yeni, 'Yeni', _TrendKat.guzellik),
  _Trend('Samsung Galaxy S25 Edge', 'Güney Kore', '🇰🇷', 'Telefon',
      "İnce tasarımıyla dikkat çekti. Kore versiyonunda ek AI özellikler var.",
      _TrendBadge.yeni, 'Yeni', _TrendKat.elektronik),
  _Trend('Chino pantolon', 'Global', '🌍', 'Giyim',
      "Smart-casual trendin yükselişi. Zara ve H&M versiyonları tükendi.",
      _TrendBadge.yukselis, '↑ %692', _TrendKat.moda),
  _Trend('Diptyque Baies mum', 'Fransa', '🇫🇷', 'Ev & Yaşam',
      "Yaz sezonu hediye listelerinin zirvesi. Paris'te Türkiye'nin %40 altında.",
      _TrendBadge.yukselis, '↑ Yükseliyor', _TrendKat.ev),
  _Trend('Lemme cilt bakım serisi', 'Amerika', '🇺🇸', 'Cilt Bakımı',
      "Kourtney Kardashian markası. Mayıs 2026 favorilerinde üst sıralarda. Türkiye'de yok.",
      _TrendBadge.viral, 'Viral', _TrendKat.guzellik),
  _Trend('Adidas Gazelle Indoor', 'Almanya', '🇩🇪', 'Sneaker',
      "Samba'nın yerini almaya başladı. Avrupa'da stoklar hızlı tükeniyor.",
      _TrendBadge.yukselis, '↑ Yükseliyor', _TrendKat.spor),
  _Trend('Portable steamer', 'Amerika', '🇺🇸', 'Ev & Yaşam',
      "Amazon best sellers listesinden düşmüyor. Türkiye'de 3x pahalı.",
      _TrendBadge.yukselis, '↑ Yükseliyor', _TrendKat.ev),
  _Trend('Made By Mitchell Curve Case', 'İngiltere', '🇬🇧', 'Kozmetik',
      "TikTok'un vazgeçilmez paleti. 8 krem formüllü çok amaçlı palet. Türkiye'de yok.",
      _TrendBadge.viral, 'Viral', _TrendKat.guzellik),
  _Trend('Multivitamin gummies', 'Amerika', '🇺🇸', 'Sağlık',
      "2026'nın en hızlı büyüyen sağlık ürünü. Costco'dan çok uygun fiyat.",
      _TrendBadge.yukselis, '↑ %573', _TrendKat.spor),
];

const _filtreler = [
  ('tumu', 'Tümü', _TrendKat.tumu),
  ('moda', 'Moda', _TrendKat.moda),
  ('guzellik', 'Güzellik', _TrendKat.guzellik),
  ('elektronik', 'Elektronik', _TrendKat.elektronik),
  ('ev', 'Ev', _TrendKat.ev),
  ('spor', 'Spor', _TrendKat.spor),
];

// ── Ana widget ────────────────────────────────────────────────────────────────

class DunyaTrendleriBolum extends StatefulWidget {
  const DunyaTrendleriBolum({super.key});

  @override
  State<DunyaTrendleriBolum> createState() => _DunyaTrendleriBolumState();
}

class _DunyaTrendleriBolumState extends State<DunyaTrendleriBolum> {
  _TrendKat _aktifKat = _TrendKat.tumu;

  @override
  Widget build(BuildContext context) {
    final filtreli = _aktifKat == _TrendKat.tumu
        ? _trendler
        : _trendler.where((t) => t.kat == _aktifKat).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dünyadan trendler',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18, fontWeight: FontWeight.w500,
                      color: Colors.white, letterSpacing: -0.3)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF333333), width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Haziran 2026',
                    style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF555555))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Son 1-2 ayın öne çıkan ürünleri',
              style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF888888))),

          const SizedBox(height: 14),

          // Filtre
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filtreler.length,
              itemBuilder: (_, i) {
                final (_, isim, kat) = _filtreler[i];
                final aktif = _aktifKat == kat;
                return GestureDetector(
                  onTap: () => setState(() => _aktifKat = kat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: aktif ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: aktif ? Colors.white : const Color(0xFF333333),
                        width: 0.5,
                      ),
                    ),
                    child: Text(isim,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                            color: aktif ? const Color(0xFF111111) : const Color(0xFF888888))),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Trend listesi
          ...filtreli.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final hot = i < 3;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i < filtreli.length - 1
                    ? const Border(bottom: BorderSide(color: Color(0xFF222222), width: 0.5))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text('${i + 1}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: hot ? const Color(0xFFE24B4A) : const Color(0xFF444444))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(t.ad,
                                  style: GoogleFonts.playfairDisplay(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                      height: 1.3)),
                            ),
                            const SizedBox(width: 8),
                            _TrendBadgeWidget(t.badge, t.badgeMetin),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(children: [
                          Text('${t.ulkeBayrak} ${t.ulke}',
                              style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF666666))),
                          const SizedBox(width: 6),
                          Container(width: 2, height: 2,
                              decoration: const BoxDecoration(color: Color(0xFF444444), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(t.kategori,
                              style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF555555))),
                        ]),
                        const SizedBox(height: 5),
                        Text(t.aciklama,
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: const Color(0xFF777777), height: 1.5)),
                      ],
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

// ── Badge widget ──────────────────────────────────────────────────────────────

class _TrendBadgeWidget extends StatelessWidget {
  final _TrendBadge tip;
  final String metin;
  const _TrendBadgeWidget(this.tip, this.metin);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color renk;
    switch (tip) {
      case _TrendBadge.viral:
        bg = const Color(0xFF3D1515); renk = const Color(0xFFF09595); break;
      case _TrendBadge.yukselis:
        bg = const Color(0xFF173404); renk = const Color(0xFF97C459); break;
      case _TrendBadge.yeni:
        bg = const Color(0xFF042C53); renk = const Color(0xFF85B7EB); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(metin,
          style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: renk)),
    );
  }
}