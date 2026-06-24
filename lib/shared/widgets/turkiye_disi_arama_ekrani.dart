// lib/shared/widgets/turkiye_disi_arama_ekrani.dart
//
// Hem istekler (filtre_ekrani.dart) hem gelenler (gelenler_screen.dart)
// ekranlarında kullanılan ortak "Türkiye dışı" yer arama sayfası.
// algoliaYerAra fonksiyonu ile arama yapar, seçilen yeri pop ile döner.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../../features/arama/data/arama_service.dart';

class TurkiyeDisiAramaEkrani extends StatefulWidget {
  final String mevcutSecim;
  // 'nereye' -> istekler ekranı, 'nereden' -> gelenler ekranı
  final String alan;
  final String hint;
  const TurkiyeDisiAramaEkrani({
    super.key,
    required this.mevcutSecim,
    this.alan = 'nereye',
    this.hint = 'Ülke veya şehir girin...',
  });

  @override
  State<TurkiyeDisiAramaEkrani> createState() =>
      _TurkiyeDisiAramaEkraniState();
}

class _TurkiyeDisiAramaEkraniState extends State<TurkiyeDisiAramaEkrani> {
  late final TextEditingController _ctrl;
  List<String> _oneriler = [];
  bool _yukleniyor = false;
  static const _mavi = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.mevcutSecim);
    if (widget.mevcutSecim.isNotEmpty) _ara(widget.mevcutSecim);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _ara(String v) async {
    if (v.trim().isEmpty) {
      setState(() { _oneriler = []; _yukleniyor = false; });
      return;
    }
    setState(() => _yukleniyor = true);
    try {
      final sonuclar = await algoliaYerAra(v, alan: widget.alan);
      if (mounted) setState(() { _oneriler = sonuclar; _yukleniyor = false; });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _sec(String yer) => Navigator.pop(context, yer);

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Arama çubuğu ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(8, statusH + 8, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textHint),
                        prefixIcon: const Icon(Icons.public_outlined,
                            size: 18, color: _mavi),
                        suffixIcon: _ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: AppColors.textSecondary),
                                onPressed: () {
                                  _ctrl.clear();
                                  setState(() => _oneriler = []);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _ara,
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) _sec(v.trim());
                      },
                    ),
                  ),
                ),
                if (widget.mevcutSecim.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pop(context, '__temizle__'),
                    child: Text('Temizle',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Sonuçlar ──────────────────────────────────────────────────────
          Expanded(
            child: _yukleniyor
                ? const Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _mavi),
                    ),
                  )
                : _oneriler.isEmpty && _ctrl.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_off_outlined,
                                size: 48, color: AppColors.divider),
                            const SizedBox(height: 12),
                            Text('Öneri bulunamadı',
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _sec(_ctrl.text.trim()),
                              child: Text(
                                '"${_ctrl.text.trim()}" ile devam et',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: _mavi,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _oneriler.length,
                        itemBuilder: (_, i) => InkWell(
                          onTap: () => _sec(_oneriler[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: AppColors.divider
                                        .withValues(alpha: 0.5),
                                    width: 0.5),
                              ),
                            ),
                            child: Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 18, color: _mavi),
                              const SizedBox(width: 12),
                              Text(_oneriler[i],
                                  style: GoogleFonts.dmSans(fontSize: 15)),
                            ]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}