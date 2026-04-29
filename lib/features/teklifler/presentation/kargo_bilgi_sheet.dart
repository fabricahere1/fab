// lib/features/teklifler/presentation/kargo_bilgi_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../providers/teklif_provider.dart';

class KargoBilgiSheet extends ConsumerStatefulWidget {
  final String teklifId;
  const KargoBilgiSheet({super.key, required this.teklifId});

  static Future<void> goster(BuildContext context, String teklifId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => KargoBilgiSheet(teklifId: teklifId),
    );
  }

  @override
  ConsumerState<KargoBilgiSheet> createState() => _KargoBilgiSheetState();
}

class _KargoBilgiSheetState extends ConsumerState<KargoBilgiSheet> {
  KargoSirketi? _seciliSirketi;
  final _takipCtrl = TextEditingController();
  String _hata = '';

  @override
  void dispose() {
    _takipCtrl.dispose();
    super.dispose();
  }

  bool get _gecerli {
    if (_seciliSirketi == null) return false;
    final no = _takipCtrl.text.trim();
    return no.length == _seciliSirketi!.haneSayisi;
  }

  Future<void> _kaydet() async {
    if (!_gecerli) {
      setState(() => _hata = _seciliSirketi == null
          ? 'Kargo şirketi seçin'
          : '${_seciliSirketi!.haneSayisi} haneli takip numarası girin');
      return;
    }

    final basarili = await ref.read(teslimProvider.notifier).kargoVerildiBeyan(
          teklifId: widget.teklifId,
          kargoSirketi: _seciliSirketi!.key,
          kargoTakipNo: _takipCtrl.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            basarili ? 'Kargo bilgileri kaydedildi.' : 'Hata oluştu.',
            style: GoogleFonts.dmSans()),
        backgroundColor: basarili ? AppColors.green : AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(teslimProvider).isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Text('Kargo Bilgileri',
              style: GoogleFonts.dmSans(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Kargo şirketi ve takip numarasını gir',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Kargo şirketi seçimi
          Text('Kargo Şirketi',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: KargoSirketi.hepsi.map((s) {
              final secili = _seciliSirketi?.key == s.key;
              return GestureDetector(
                onTap: () => setState(() {
                  _seciliSirketi = s;
                  _hata = '';
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: secili
                        ? AppColors.red
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: secili
                          ? AppColors.red
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(s.ad,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secili
                            ? Colors.white
                            : AppColors.textPrimary,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Takip numarası
          Text('Takip Numarası',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          TextField(
            controller: _takipCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _hata = ''),
            style: GoogleFonts.dmSans(fontSize: 15),
            decoration: InputDecoration(
              hintText: _seciliSirketi != null
                  ? '${_seciliSirketi!.haneSayisi} haneli numara'
                  : 'Önce kargo şirketi seçin',
              hintStyle: GoogleFonts.dmSans(
                  color: AppColors.textHint, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.red, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
            ),
          ),

          // Hata mesajı
          if (_hata.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: AppColors.red),
                const SizedBox(width: 6),
                Text(_hata,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.red)),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: yukleniyor ? null : _kaydet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: yukleniyor
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Kargo Bilgilerini Kaydet',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
