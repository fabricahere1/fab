// lib/features/auth/presentation/profil_tamamla_widgets.dart
//
// profil_tamamla_screen.dart'tan ayrılan yardımcı widget'lar:
// _TipKart, _Bolum, _AutocompleteAlani, _CokluSehirAlani
// + adım build metodları ProfilTamamlaAdimlar sınıfına taşındı.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';

// Ülke ve şehir listeleri buraya taşındı (screen dosyasından kaldırıldı)
const List<String> kTumUlkeler = [
  'Afganistan', 'Almanya', 'Amerika Birleşik Devletleri', 'Arjantin',
  'Avustralya', 'Avusturya', 'Azerbaycan', 'Belçika',
  'Birleşik Arap Emirlikleri', 'Birleşik Krallık', 'Brezilya', 'Çin',
  'Danimarka', 'Endonezya', 'Fas', 'Filipinler', 'Finlandiya', 'Fransa',
  'Güney Afrika', 'Güney Kore', 'Gürcistan', 'Hindistan', 'Hollanda',
  'İngiltere', 'İran', 'İrlanda', 'İspanya', 'İsveç', 'İsviçre', 'İtalya',
  'Japonya', 'Kanada', 'Katar', 'Kazakistan', 'Kuveyt', 'Kuzey Kıbrıs',
  'Lübnan', 'Macaristan', 'Malezya', 'Meksika', 'Mısır', 'Norveç',
  'Özbekistan', 'Pakistan', 'Polonya', 'Portekiz', 'Romanya', 'Rusya',
  'Suudi Arabistan', 'Singapur', 'Tayland', 'Tunus', 'Türkmenistan',
  'Ukrayna', 'Ürdün', 'Vietnam', 'Yunanistan',
];

const List<String> kTurkiyeSehirleri = [
  'Adana', 'Ankara', 'Antalya', 'Bursa', 'Diyarbakır', 'Erzurum',
  'Eskişehir', 'Gaziantep', 'İstanbul', 'İzmir', 'Kayseri', 'Konya',
  'Malatya', 'Mersin', 'Samsun', 'Trabzon',
];

// ── Tip Kartı ─────────────────────────────────────────────────────────────────

class ProfilTipKart extends StatelessWidget {
  final IconData ikon;
  final String baslik, aciklama;
  final bool secili;
  final VoidCallback onTap;

  const ProfilTipKart({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: secili
              ? AppColors.red.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? AppColors.red : AppColors.divider,
            width: secili ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: secili
                    ? AppColors.red
                    : AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ikon,
                  size: 22,
                  color: secili ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: secili
                              ? AppColors.red
                              : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(aciklama,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secili ? AppColors.red : Colors.transparent,
                border: Border.all(
                    color: secili ? AppColors.red : AppColors.divider,
                    width: 2),
              ),
              child: secili
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bölüm ─────────────────────────────────────────────────────────────────────

class ProfilBolum extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final Widget child;

  const ProfilBolum({
    super.key,
    required this.baslik,
    required this.ikon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, size: 17, color: AppColors.red),
              ),
              const SizedBox(width: 10),
              Text(baslik,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Adım Header ───────────────────────────────────────────────────────────────
// Her adımda tekrar eden kırmızı ikon + başlık + açıklama bloğu

class ProfilAdimHeader extends StatelessWidget {
  final IconData ikon;
  final String baslik, aciklama;

  const ProfilAdimHeader({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(ikon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(aciklama,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Autocomplete Alanı ────────────────────────────────────────────────────────

class AutocompleteAlani extends StatefulWidget {
  final String value;
  final List<String> secenekler;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onSecildi;

  const AutocompleteAlani({
    super.key,
    required this.value,
    required this.secenekler,
    required this.hint,
    required this.icon,
    required this.onSecildi,
  });

  @override
  State<AutocompleteAlani> createState() => _AutocompleteAlaniState();
}

class _AutocompleteAlaniState extends State<AutocompleteAlani> {
  late TextEditingController _ctrl;
  List<String> _filtreli = [];
  bool _acik = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _filtrele(String q) {
    setState(() {
      _acik    = q.isNotEmpty;
      _filtreli = widget.secenekler
          .where((s) => s.toLowerCase().contains(q.toLowerCase()))
          .take(6)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          onChanged: (val) {
            _filtrele(val);
            widget.onSecildi(val);
          },
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
            prefixIcon:
                Icon(widget.icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onSecildi('');
                      setState(() => _acik = false);
                    })
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: _filtreli
                  .map((s) => InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _ctrl.text = s;
                          widget.onSecildi(s);
                          setState(() => _acik = false);
                          FocusScope.of(context).unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.red),
                              const SizedBox(width: 10),
                              Text(s,
                                  style: GoogleFonts.dmSans(fontSize: 14)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ── Çoklu Şehir Alanı ────────────────────────────────────────────────────────

class CokluSehirAlani extends StatefulWidget {
  final List<String> secilenler, secenekler;
  final String hint;
  final ValueChanged<String> onEklendi, onKaldirildi;

  const CokluSehirAlani({
    super.key,
    required this.secilenler,
    required this.secenekler,
    required this.hint,
    required this.onEklendi,
    required this.onKaldirildi,
  });

  @override
  State<CokluSehirAlani> createState() => _CokluSehirAlaniState();
}

class _CokluSehirAlaniState extends State<CokluSehirAlani> {
  final _ctrl     = TextEditingController();
  List<String> _filtreli = [];
  bool _acik      = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _filtrele(String q) {
    setState(() {
      _acik    = q.isNotEmpty;
      _filtreli = widget.secenekler
          .where((s) =>
              s.toLowerCase().contains(q.toLowerCase()) &&
              !widget.secilenler.contains(s))
          .take(6)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.secilenler.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.secilenler
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => widget.onKaldirildi(s),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _ctrl,
          onChanged: _filtrele,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
            prefixIcon: const Icon(Icons.add_location_outlined,
                color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: _filtreli
                  .map((s) => InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          widget.onEklendi(s);
                          _ctrl.clear();
                          setState(() => _acik = false);
                          FocusScope.of(context).unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.add,
                                  size: 16,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Text(s,
                                  style: GoogleFonts.dmSans(fontSize: 14)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
