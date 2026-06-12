// lib/features/home/presentation/beden_donusturucu_bolum.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';

// ── Veri ─────────────────────────────────────────────────────────────────────

enum _TabTipi { kadinUst, kadinAlt, kadinAyak, erkekUst, erkekAlt, erkekAyak }

class _TabBilgi {
  final String baslik;
  final _TabTipi tip;
  const _TabBilgi(this.baslik, this.tip);
}

const _tablar = [
  _TabBilgi('Kadın Üst',      _TabTipi.kadinUst),
  _TabBilgi('Kadın Alt',      _TabTipi.kadinAlt),
  _TabBilgi('Kadın Ayakkabı', _TabTipi.kadinAyak),
  _TabBilgi('Erkek Üst',      _TabTipi.erkekUst),
  _TabBilgi('Erkek Alt',      _TabTipi.erkekAlt),
  _TabBilgi('Erkek Ayakkabı', _TabTipi.erkekAyak),
];

// TR beden → [US, UK, EU, İtalya]
const _kadinUstData = {
  'XS':  ['0-2',   '6-8',   '32-34', '36'],
  'S':   ['4-6',   '8-10',  '36-38', '38-40'],
  'M':   ['8-10',  '12-14', '40-42', '42-44'],
  'L':   ['12-14', '16-18', '44-46', '46-48'],
  'XL':  ['16-18', '20-22', '48-50', '50-52'],
  'XXL': ['20-22', '24-26', '52-54', '54-56'],
};

// TR numara → [US, UK, JP cm]
const _kadinAyakData = {
  '36': ['5.5-6',   '3.5-4', '22.5'],
  '37': ['6.5-7',   '4.5-5', '23.5'],
  '38': ['7.5-8',   '5.5-6', '24'],
  '39': ['8.5-9',   '6.5-7', '25'],
  '40': ['9.5-10',  '7.5-8', '25.5'],
  '41': ['10.5-11', '8.5-9', '26.5'],
};

// TR/EU → [US, UK, JP cm]
const _erkekAyakData = {
  '39': ['6.5', '6',    '25'],
  '40': ['7',   '6.5',  '25.5'],
  '41': ['8',   '7.5',  '26'],
  '42': ['9',   '8.5',  '27'],
  '43': ['10',  '9.5',  '27.5'],
  '44': ['11',  '10.5', '28.5'],
  '45': ['12',  '11.5', '29'],
  '46': ['13',  '12.5', '29.5'],
};

// ── Ana widget ────────────────────────────────────────────────────────────────

class BedenDonusturuculBolum extends StatefulWidget {
  const BedenDonusturuculBolum({super.key});

  @override
  State<BedenDonusturuculBolum> createState() => _BedenDonusturucuBolumState();
}

class _BedenDonusturucuBolumState extends State<BedenDonusturuculBolum> {
  _TabTipi _aktifTab = _TabTipi.kadinUst;
  String? _seciliBeden;

  void _tabDegistir(_TabTipi tip) {
    setState(() { _aktifTab = tip; _seciliBeden = null; });
  }

  void _bedenSec(String beden) {
    setState(() => _seciliBeden = beden);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(children: [
            const Icon(Symbols.straighten, size: 16, color: AppColors.red),
            const SizedBox(width: 6),
            Text('Bedenini bul',
                style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ]),
        ),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 0.8)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tablar.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final aktif = _aktifTab == t.tip;
                return GestureDetector(
                  onTap: () => _tabDegistir(t.tip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: aktif ? AppColors.textPrimary : Colors.white,
                      border: i < _tablar.length - 1
                          ? Border(right: BorderSide(color: AppColors.divider, width: 0.8))
                          : null,
                    ),
                    child: Text(t.baslik,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                            color: aktif ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // İçerik
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildIcerik(),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildIcerik() {
    switch (_aktifTab) {
      case _TabTipi.kadinUst:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BedenSecici(bedenler: _kadinUstData.keys.toList(), secili: _seciliBeden, onSec: _bedenSec),
          if (_seciliBeden != null) _SonucKarti(
            basliklar: ['🇺🇸 US', '🇬🇧 UK', '🇪🇺 EU', '🇮🇹 İtalya'],
            degerler: _kadinUstData[_seciliBeden]!,
          ),
          const SizedBox(height: 12),
          _Tablo(
            sutunlar: ['TR', '🇺🇸 US', '🇬🇧 UK', '🇪🇺 EU', '🇮🇹 İtalya'],
            satirlar: _kadinUstData.entries.map((e) => [e.key, ...e.value]).toList(),
            vurgulu: _seciliBeden,
          ),
        ]);
      case _TabTipi.kadinAlt:
        return _Tablo(
          sutunlar: ['TR', '🇺🇸 US', '🇬🇧 UK', '🇪🇺 EU', 'Bel (cm)'],
          satirlar: [
            ['34', '0', '6', '34', '63-65'],
            ['36', '2', '8', '36', '67-69'],
            ['38', '4-6', '10', '38', '71-73'],
            ['40', '8', '12', '40', '75-77'],
            ['42', '10-12', '14-16', '42', '79-81'],
            ['44', '14', '18', '44', '83-87'],
          ],
        );
      case _TabTipi.kadinAyak:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BedenSecici(bedenler: _kadinAyakData.keys.toList(), secili: _seciliBeden, onSec: _bedenSec),
          if (_seciliBeden != null) _SonucKarti(
            basliklar: ['🇺🇸 US', '🇬🇧 UK', '🇯🇵 JP cm'],
            degerler: _kadinAyakData[_seciliBeden]!,
          ),
          const SizedBox(height: 12),
          _Tablo(
            sutunlar: ['TR/EU', '🇺🇸 US', '🇬🇧 UK', '🇯🇵 JP (cm)'],
            satirlar: _kadinAyakData.entries.map((e) => [e.key, ...e.value]).toList(),
            vurgulu: _seciliBeden,
          ),
        ]);
      case _TabTipi.erkekUst:
        return _Tablo(
          sutunlar: ['TR', '🇺🇸 US', '🇬🇧 UK', '🇪🇺 EU', 'Göğüs (cm)'],
          satirlar: [
            ['S',    'S',    'S',    '44-46', '88-92'],
            ['M',    'M',    'M',    '48-50', '96-100'],
            ['L',    'L',    'L',    '52-54', '104-108'],
            ['XL',   'XL',   'XL',   '56-58', '112-116'],
            ['XXL',  'XXL',  'XXL',  '60-62', '120-124'],
            ['XXXL', 'XXXL', 'XXXL', '64-66', '128-132'],
          ],
        );
      case _TabTipi.erkekAlt:
        return _Tablo(
          sutunlar: ['TR (bel)', '🇺🇸 US W', '🇬🇧 UK', '🇪🇺 EU'],
          satirlar: [
            ['44', '28', '28', '44'],
            ['46', '30', '30', '46'],
            ['48', '32', '32', '48'],
            ['50', '34', '34', '50'],
            ['52', '36', '36', '52'],
            ['54', '38', '38', '54'],
          ],
        );
      case _TabTipi.erkekAyak:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BedenSecici(bedenler: _erkekAyakData.keys.toList(), secili: _seciliBeden, onSec: _bedenSec),
          if (_seciliBeden != null) _SonucKarti(
            basliklar: ['🇺🇸 US', '🇬🇧 UK', '🇯🇵 JP cm'],
            degerler: _erkekAyakData[_seciliBeden]!,
          ),
          const SizedBox(height: 12),
          _Tablo(
            sutunlar: ['TR/EU', '🇺🇸 US', '🇬🇧 UK', '🇯🇵 JP (cm)'],
            satirlar: _erkekAyakData.entries.map((e) => [e.key, ...e.value]).toList(),
            vurgulu: _seciliBeden,
          ),
        ]);
    }
  }
}

// ── Beden seçici ──────────────────────────────────────────────────────────────

class _BedenSecici extends StatelessWidget {
  final List<String> bedenler;
  final String? secili;
  final void Function(String) onSec;
  const _BedenSecici({required this.bedenler, required this.secili, required this.onSec});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Türkiye bedenini seç',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 0.8)),
          child: Row(
            children: bedenler.asMap().entries.map((e) {
              final i = e.key;
              final b = e.value;
              final aktif = secili == b;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSec(b),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: aktif ? AppColors.textPrimary : Colors.white,
                      border: i < bedenler.length - 1
                          ? Border(right: BorderSide(color: AppColors.divider, width: 0.8))
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(b,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                            color: aktif ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Sonuç kartı ───────────────────────────────────────────────────────────────

class _SonucKarti extends StatelessWidget {
  final List<String> basliklar;
  final List<String> degerler;
  const _SonucKarti({required this.basliklar, required this.degerler});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: AppColors.surface,
            child: Text('Diğer ülkelerdeki karşılığı',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
          ),
          Row(
            children: List.generate(basliklar.length, (i) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: i < basliklar.length - 1
                      ? Border(right: BorderSide(color: AppColors.divider, width: 0.8))
                      : null,
                ),
                child: Column(children: [
                  Text(basliklar[i],
                      style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(degerler[i],
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ]),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

// ── Tablo ─────────────────────────────────────────────────────────────────────

class _Tablo extends StatelessWidget {
  final List<String> sutunlar;
  final List<List<String>> satirlar;
  final String? vurgulu;
  const _Tablo({required this.sutunlar, required this.satirlar, this.vurgulu});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 0.8)),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: AppColors.divider, width: 0.8),
          verticalInside: BorderSide(color: AppColors.divider, width: 0.8),
        ),
        children: [
          // Başlık satırı
          TableRow(
            decoration: BoxDecoration(color: AppColors.surface),
            children: sutunlar.map((s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(s, textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
            )).toList(),
          ),
          // Veri satırları
          ...satirlar.map((satir) => TableRow(
            decoration: BoxDecoration(
              color: vurgulu != null && satir[0] == vurgulu
                  ? AppColors.surface
                  : Colors.white,
            ),
            children: satir.map((hucre) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(hucre, textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: vurgulu != null && satir[0] == vurgulu
                          ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary)),
            )).toList(),
          )),
        ],
      ),
    );
  }
}