import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';

class AnlasmaOneriSheet extends StatefulWidget {
  final String karsiKullaniciAd;
  final String ilanBaslik;
  final double? onerilenfiyat;

  const AnlasmaOneriSheet({
    super.key,
    required this.karsiKullaniciAd,
    required this.ilanBaslik,
    this.onerilenfiyat,
  });

  static Future<double?> goster(
    BuildContext context, {
    required String karsiKullaniciAd,
    required String ilanBaslik,
    double? onerilenfiyat,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnlasmaOneriSheet(
        karsiKullaniciAd: karsiKullaniciAd,
        ilanBaslik: ilanBaslik,
        onerilenfiyat: onerilenfiyat,
      ),
    );
  }

  @override
  State<AnlasmaOneriSheet> createState() => _AnlasmaOneriSheetState();
}

class _AnlasmaOneriSheetState extends State<AnlasmaOneriSheet> {
  final _ctrl = TextEditingController();
  // true = yazan fiyat, false = kendi fiyatı
  bool _yazanFiyatSecili = false;
  String _hata = '';

  bool get _varFiyat => widget.onerilenfiyat != null && widget.onerilenfiyat! > 0;

  @override
  void initState() {
    super.initState();
    if (_varFiyat) {
      _yazanFiyatSecili = true;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _gonder() {
    if (_yazanFiyatSecili && _varFiyat) {
      Navigator.pop(context, widget.onerilenfiyat);
      return;
    }
    final metin = _ctrl.text.trim();
    if (metin.isEmpty) {
      setState(() => _hata = 'Tutar girin');
      return;
    }
    final tutar = double.tryParse(metin);
    if (tutar == null || tutar <= 0) {
      setState(() => _hata = 'Geçerli bir tutar girin');
      return;
    }
    Navigator.pop(context, tutar);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Başlık
          Row(
            children: [
              const Icon(Icons.handshake_outlined, color: AppColors.red, size: 22),
              const SizedBox(width: 8),
              Text('Hızlı Anlaş',
                  style: GoogleFonts.dmSans(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.karsiKullaniciAd} · "${widget.ilanBaslik}"',
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Seçenek 1: Yazan fiyattan (sadece fiyat varsa göster)
          if (_varFiyat) ...[
            GestureDetector(
              onTap: () => setState(() {
                _yazanFiyatSecili = true;
                _ctrl.clear();
                _hata = '';
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _yazanFiyatSecili
                      ? AppColors.green.withValues(alpha: 0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _yazanFiyatSecili ? AppColors.green : AppColors.divider,
                    width: _yazanFiyatSecili ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _yazanFiyatSecili
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: _yazanFiyatSecili ? AppColors.green : AppColors.textHint,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yazan Fiyattan Anlaş',
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _yazanFiyatSecili
                                      ? AppColors.green
                                      : AppColors.textPrimary)),
                          Text(
                            '${widget.onerilenfiyat!.toStringAsFixed(0)} ₺',
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Seçenek 2: Kendin belirle
          GestureDetector(
            onTap: () => setState(() {
              _yazanFiyatSecili = false;
              _hata = '';
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !_yazanFiyatSecili
                    ? AppColors.red.withValues(alpha: 0.05)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: !_yazanFiyatSecili ? AppColors.red.withValues(alpha: 0.4) : AppColors.divider,
                  width: !_yazanFiyatSecili ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        !_yazanFiyatSecili
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: !_yazanFiyatSecili ? AppColors.red : AppColors.textHint,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text('Kendin Belirle',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: !_yazanFiyatSecili
                                  ? AppColors.red
                                  : AppColors.textPrimary)),
                    ],
                  ),
                  if (!_yazanFiyatSecili) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _hata.isNotEmpty ? AppColors.red : AppColors.divider,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text('₺',
                              style: GoogleFonts.dmSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: !_varFiyat,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                              style: GoogleFonts.dmSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: GoogleFonts.dmSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.divider),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() => _hata = ''),
                            ),
                          ),
                          Text('TL',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (_hata.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, size: 13, color: AppColors.red),
                          const SizedBox(width: 4),
                          Text(_hata,
                              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.red)),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Bilgi kutusu
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Karşı taraf onaylarsa anlaşma tamamlanır.',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _gonder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Anlaşmayı Öner',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.handshake_outlined, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}