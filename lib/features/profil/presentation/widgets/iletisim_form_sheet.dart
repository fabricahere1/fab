import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/constants/app_colors.dart';

/// Kaynak: 'destek' → konu "[Destek] …", 'iletisim' → "[İletişim] …"
void iletisimFormAc({
  required BuildContext context,
  required String kaynak,
  required VoidCallback onGonderildi,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _IletisimFormSheet(
      kaynak: kaynak,
      onGonderildi: onGonderildi,
    ),
  );
}

class _IletisimFormSheet extends ConsumerStatefulWidget {
  final String kaynak;
  final VoidCallback onGonderildi;

  const _IletisimFormSheet({
    required this.kaynak,
    required this.onGonderildi,
  });

  @override
  ConsumerState<_IletisimFormSheet> createState() => _IletisimFormSheetState();
}

class _IletisimFormSheetState extends ConsumerState<_IletisimFormSheet> {
  static const _kategoriler = [
    (ikon: Icons.bug_report_outlined,  etiket: 'Teknik sorun bildirimi',   hint: 'Lütfen yaşadığınız problemi kısaca açıklayın.'),
    (ikon: Icons.flag_outlined,        etiket: 'Kullanıcı şikayeti',       hint: 'Lütfen ne olduğunu yazın.'),
    (ikon: Icons.lightbulb_outline,    etiket: 'Öneri veya geri bildirim', hint: 'Önerilerinizi sabırsızlıkla bekliyoruz :)'),
    (ikon: Icons.help_outline_rounded, etiket: 'Hesap ile ilgili sorun',   hint: 'Sorununuzu dinliyoruz.'),
    (ikon: Icons.gavel_outlined,       etiket: 'Kural ihlali bildirimi',   hint: 'Sizi dinliyoruz.'),
    (ikon: Icons.more_horiz_rounded,   etiket: 'Diğer',                    hint: 'Diğer her şey için de buradayız.'),
  ];

  String? _secilenKategori;
  final _mesajCtrl = TextEditingController();
  late final TextEditingController _emailCtrl;
  bool _gonderiyor = false;
  String? _emailHata;

  bool get _destek => widget.kaynak == 'destek';
  String get _baslik => _destek ? 'Destek' : 'İletişim';
  String get _konuPrefix => _destek ? '[Destek]' : '[İletişim]';

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(
      text: ref.read(currentUserProvider)?.email ?? '',
    );
  }

  @override
  void dispose() {
    _mesajCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (_gonderiyor) return;

    if (!_destek) {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _emailHata = 'Geçerli bir e-posta gir');
        return;
      }
      setState(() => _emailHata = null);
    }

    if (_mesajCtrl.text.trim().isEmpty || _gonderiyor) return;
    setState(() => _gonderiyor = true);

    try {
      final user = ref.read(currentUserProvider);
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('iletisimGonder')
          .call({
        'konu': _destek
            ? '$_konuPrefix ${_secilenKategori ?? 'Diğer'}'
            : '$_konuPrefix Genel',
        'mesaj': _mesajCtrl.text.trim(),
        'gonderenAd': user?.displayName ?? 'Bilinmiyor',
        'gonderenEmail': _destek ? (user?.email ?? '') : _emailCtrl.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onGonderildi();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gonderiyor = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gönderilemedi, tekrar dene.', style: GoogleFonts.manrope()),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _baslik,
              style: GoogleFonts.manrope(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            if (!_destek) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: _emailCtrl.text.isEmpty,
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'E-posta adresin',
                  hintText: 'Sana dönüş yapabilmemiz için',
                  hintStyle: GoogleFonts.manrope(
                      color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.textSecondary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              if (_emailHata != null) ...[
                const SizedBox(height: 6),
                Text(
                  _emailHata!,
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: AppColors.red),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _mesajCtrl,
                maxLines: 6,
                autofocus: _emailCtrl.text.isNotEmpty,
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Bize iletmek istediğin her şey...',
                  hintStyle: GoogleFonts.manrope(
                      color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.textSecondary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _gonderiyor ? null : _gonder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _gonderiyor
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Gönder',
                          style: GoogleFonts.manrope(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else if (_secilenKategori == null) ...[
              ...List.generate(_kategoriler.length, (i) {
                final k = _kategoriler[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() => _secilenKategori = k.etiket),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(k.ikon, size: 22, color: AppColors.textSecondary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              k.etiket,
                              style: GoogleFonts.manrope(
                                fontSize: 14, fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else ...[
              GestureDetector(
                onTap: () => setState(() {
                  _secilenKategori = null;
                  _mesajCtrl.clear();
                }),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _secilenKategori!,
                      style: GoogleFonts.manrope(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mesajCtrl,
                maxLines: 6,
                autofocus: true,
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _kategoriler
                      .firstWhere((k) => k.etiket == _secilenKategori,
                          orElse: () => _kategoriler.last)
                      .hint,
                  hintStyle: GoogleFonts.manrope(
                      color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.textSecondary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _gonderiyor ? null : _gonder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _gonderiyor
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Gönder',
                          style: GoogleFonts.manrope(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
