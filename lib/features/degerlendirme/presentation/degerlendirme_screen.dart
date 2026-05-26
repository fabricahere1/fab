// lib/features/degerlendirme/presentation/degerlendirme_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/degerlendirme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/utils/app_snackbar.dart';

class DegerlendirmeModal extends ConsumerStatefulWidget {
  final String sohbetId;
  final String hedefKullaniciId;
  final String hedefKullaniciAd;
  final String? hedefFotoUrl;
  final String ilanBaslik;

  const DegerlendirmeModal({
    super.key,
    required this.sohbetId,
    required this.hedefKullaniciId,
    required this.hedefKullaniciAd,
    this.hedefFotoUrl,
    this.ilanBaslik = '',
  });

  static Future<bool> goster({
    required BuildContext context,
    required String sohbetId,
    required String hedefKullaniciId,
    required String hedefKullaniciAd,
    String? hedefFotoUrl,
    String ilanBaslik = '',
  }) async {
    final sonuc = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DegerlendirmeModal(
        sohbetId:         sohbetId,
        hedefKullaniciId: hedefKullaniciId,
        hedefKullaniciAd: hedefKullaniciAd,
        hedefFotoUrl:     hedefFotoUrl,
        ilanBaslik:       ilanBaslik,
      ),
    );
    return sonuc == true;
  }

  @override
  ConsumerState<DegerlendirmeModal> createState() => _DegerlendirmeModalState();
}

class _DegerlendirmeModalState extends ConsumerState<DegerlendirmeModal> {
  int    _secilenYildiz = 0;
  final  _yorumCtrl     = TextEditingController();
  bool   _gonderiyor    = false;

  @override
  void dispose() {
    _yorumCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (_secilenYildiz == 0 || _gonderiyor) return;
    final benimUid = ref.read(currentUserProvider)?.uid ?? '';
    if (benimUid.isEmpty) return;

    setState(() => _gonderiyor = true);
    final basarili = await ref.read(degerlendirmeIslemleriProvider.notifier).gonder(
      sohbetId:          widget.sohbetId,
      degerlendireninId: benimUid,
      hedefKullaniciId:  widget.hedefKullaniciId,
      puan:              _secilenYildiz.toDouble(),
      yorum:             _yorumCtrl.text.trim(),
      ilanBaslik:        widget.ilanBaslik,
    );
    if (!mounted) return;
    if (basarili) {
      Navigator.pop(context, true);
      AppSnackBar.basari(context, 'Değerlendirmen gönderildi!');
    } else {
      setState(() => _gonderiyor = false);
      AppSnackBar.hata(context, 'Bir hata oluştu. Tekrar dene.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil     = ref.watch(kullaniciBilgiProvider(widget.hedefKullaniciId));
    final mevcutPuan = profil.value?.ortalamaPuan ?? 0.0;
    final mevcutSayi = profil.value?.degerlendirmeSayisi ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Text('Değerlendir',
                      style: GoogleFonts.dmSans(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Atla',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  // Kullanıcı bilgisi
                  Row(
                    children: [
                      _Avatar(
                          isim: widget.hedefKullaniciAd,
                          fotoUrl: widget.hedefFotoUrl,
                          radius: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.hedefKullaniciAd,
                                style: GoogleFonts.dmSans(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            if (mevcutSayi > 0)
                              Row(children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFA726), size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  '${mevcutPuan.toStringAsFixed(1)} ($mevcutSayi değerlendirme)',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ])
                            else
                              Text('Henüz değerlendirme yok',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Yıldızlar
                  Text('Bu işlemi nasıl değerlendiriyorsun?',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final y = i + 1;
                      final secili = y <= _secilenYildiz;
                      return GestureDetector(
                        onTap: () => setState(() => _secilenYildiz = y),
                        child: AnimatedScale(
                          scale: _secilenYildiz == y ? 1.25 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              secili ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: secili ? const Color(0xFFFFA726) : AppColors.divider,
                              size: 44,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_secilenYildiz > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      ['', 'Çok kötü', 'Kötü', 'Orta', 'İyi', 'Mükemmel!'][_secilenYildiz],
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _secilenYildiz >= 4
                            ? const Color(0xFF43A047)
                            : _secilenYildiz <= 2
                                ? AppColors.red
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Yorum
                  TextField(
                    controller: _yorumCtrl,
                    maxLines: 3,
                    maxLength: 200,
                    style: GoogleFonts.dmSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Yorum ekle (opsiyonel)',
                      hintStyle: GoogleFonts.dmSans(
                          color: AppColors.textHint, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      counterStyle: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gönder
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _secilenYildiz == 0 || _gonderiyor ? null : _gonder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        disabledBackgroundColor: AppColors.divider,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _gonderiyor
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Değerlendirmeyi Gönder',
                              style: GoogleFonts.dmSans(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
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

class _Avatar extends StatelessWidget {
  final String isim;
  final String? fotoUrl;
  final double radius;

  const _Avatar({required this.isim, this.fotoUrl, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return CircleAvatar(
          radius: radius, backgroundImage: NetworkImage(fotoUrl!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.red.withValues(alpha: 0.15),
      child: Text(
        isim.isNotEmpty ? isim[0].toUpperCase() : '?',
        style: TextStyle(
            color: AppColors.red,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}