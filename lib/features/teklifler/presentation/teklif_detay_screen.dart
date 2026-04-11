// lib/features/teklifler/presentation/teklif_detay_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/teklif_model.dart';
import '../providers/teklif_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../profil/presentation/kullanici_profil_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';

class TeklifDetayScreen extends ConsumerWidget {
  final String teklifId;
  const TeklifDetayScreen({super.key, required this.teklifId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tekliflerAsync = ref.watch(teklifDetayProvider(teklifId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Teklif Detayı',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: tekliflerAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2)),
        error: (e, _) => Center(
          child: Text('Teklif yüklenemedi.',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        data: (teklif) {
          if (teklif == null) {
            return Center(
              child: Text('Teklif bulunamadı.',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            );
          }
          return _TeklifDetayIcerik(teklif: teklif);
        },
      ),
    );
  }
}

class _TeklifDetayIcerik extends ConsumerWidget {
  final TeklifModel teklif;
  const _TeklifDetayIcerik({required this.teklif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benimUid   = ref.watch(currentUserProvider)?.uid ?? '';
    final benimAd    = ref.watch(currentUserProvider)?.displayName ?? '';
    final benimIlan  = benimUid == teklif.ilanSahibiId;
    final yukleniyor = ref.watch(teklifProvider).isLoading;
    final anlasmaSaglandi = teklif.durum == TeklifDurum.kabul;

    final karsiKullaniciId = benimIlan ? teklif.teklifVerenId : teklif.ilanSahibiId;
    final karsiKullaniciAd = benimIlan ? teklif.teklifVerenAd : teklif.ilanSahibiAd;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Teklif özet kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teklif.ilanBaslik,
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                _FiyatSatiri(label: 'İlan Fiyatı', miktar: teklif.ilanMiktar, renk: AppColors.textSecondary),
                const SizedBox(height: 12),
                _FiyatSatiri(label: 'Teklif', miktar: teklif.miktar, renk: const Color(0xFFFF9800), buyuk: true),
                if (teklif.karsiTeklifMiktar != null) ...[
                  const SizedBox(height: 12),
                  _FiyatSatiri(label: 'Karşı Teklif', miktar: teklif.karsiTeklifMiktar!, renk: AppColors.red, buyuk: true),
                ],
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                _DurumBadge(durum: teklif.durum),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Taraflar kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taraflar',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 14),

                // İlan sahibi — tıklayınca profil açılır
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => KullaniciProfilScreen(
                      kullaniciId: teklif.ilanSahibiId,
                      kullaniciAd: teklif.ilanSahibiAd,
                    ),
                  )),
                  child: _KisiSatiri(ad: teklif.ilanSahibiAd, rol: 'İlan Sahibi', gosterOk: true),
                ),
                const SizedBox(height: 10),

                // Teklif veren — tıklayınca profil açılır
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => KullaniciProfilScreen(
                      kullaniciId: teklif.teklifVerenId,
                      kullaniciAd: teklif.teklifVerenAd,
                    ),
                  )),
                  child: _KisiSatiri(ad: teklif.teklifVerenAd, rol: 'Teklif Veren', gosterOk: true),
                ),

                // Anlaşma sağlandıysa mesaj butonu
                if (anlasmaSaglandi) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (ctx, anim, secAnim) => SohbetScreen(
                            karsiKullaniciId: karsiKullaniciId,
                            karsiKullaniciAd: karsiKullaniciAd,
                            ilanId: teklif.ilanId,
                            ilanBaslik: teklif.ilanBaslik,
                          ),
                          transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
                            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                          transitionDuration: const Duration(milliseconds: 280),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text('$karsiKullaniciAd ile Mesajlaş',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Zaman
          if (teklif.olusturmaTarihi != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.access_time_outlined, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('Teklif tarihi: ${_tarihYazi(teklif.olusturmaTarihi!)}',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),

          // Aksiyon butonları
          if (teklif.durum == TeklifDurum.bekliyor || teklif.durum == TeklifDurum.karsiTeklif) ...[

            if (benimIlan) ...[
              _AksiyonButon(
                label: 'Kabul Et',
                ikon: Icons.check_circle_outline,
                renk: AppColors.green,
                yukleniyor: yukleniyor,
                onTap: () async {
                  final basarili = await ref.read(teklifProvider.notifier).teklifKabul(
                    teklif: teklif, kabulEdenId: benimUid, kabulEdenAd: benimAd,
                  );
                  if (basarili && context.mounted) {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const _AnlasmaDialog(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  } else if (context.mounted) {
                    _snack(context, 'Hata oluştu.', AppColors.red);
                  }
                },
              ),
              const SizedBox(height: 10),
              _AksiyonButon(
                label: 'Karşı Teklif Ver',
                ikon: Icons.swap_horiz_outlined,
                renk: const Color(0xFFFF9800),
                outlined: true,
                yukleniyor: yukleniyor,
                onTap: () => _karsiTeklifDialog(context, ref),
              ),
              const SizedBox(height: 10),
              _AksiyonButon(
                label: 'Reddet',
                ikon: Icons.cancel_outlined,
                renk: AppColors.red,
                outlined: true,
                yukleniyor: yukleniyor,
                onTap: () async {
                  final onay = await _onayDialog(context, 'Teklifi reddet?', 'Bu teklifi reddetmek istediğine emin misin?');
                  if (onay == true && context.mounted) {
                    final basarili = await ref.read(teklifProvider.notifier).teklifReddet(teklif);
                    if (context.mounted) {
                      _snack(context, basarili ? 'Teklif reddedildi.' : 'Hata oluştu.',
                          basarili ? AppColors.textSecondary : AppColors.red);
                      if (basarili) Navigator.pop(context);
                    }
                  }
                },
              ),
            ],

            if (!benimIlan && teklif.karsiTeklifMiktar != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${teklif.ilanSahibiAd} karşı teklif verdi: ${teklif.karsiTeklifMiktar!.toStringAsFixed(0)} ₺',
                        style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFE65100), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AksiyonButon(
                label: 'Kabul Et',
                ikon: Icons.check_circle_outline,
                renk: AppColors.green,
                yukleniyor: yukleniyor,
                onTap: () async {
                  final basarili = await ref.read(teklifProvider.notifier).teklifKabul(
                    teklif: teklif, kabulEdenId: benimUid, kabulEdenAd: benimAd,
                  );
                  if (basarili && context.mounted) {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const _AnlasmaDialog(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  } else if (context.mounted) {
                    _snack(context, 'Hata oluştu.', AppColors.red);
                  }
                },
              ),
              const SizedBox(height: 10),
              _AksiyonButon(
                label: 'Reddet',
                ikon: Icons.cancel_outlined,
                renk: AppColors.red,
                outlined: true,
                yukleniyor: yukleniyor,
                onTap: () async {
                  final onay = await _onayDialog(context, 'Teklifi reddet?', 'Bu teklifi reddetmek istediğine emin misin?');
                  if (onay == true && context.mounted) {
                    final basarili = await ref.read(teklifProvider.notifier).teklifReddet(teklif);
                    if (context.mounted) {
                      _snack(context, basarili ? 'Reddedildi.' : 'Hata oluştu.',
                          basarili ? AppColors.textSecondary : AppColors.red);
                      if (basarili) Navigator.pop(context);
                    }
                  }
                },
              ),
            ],

            if (!benimIlan && teklif.karsiTeklifMiktar == null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_empty_outlined, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text('Teklifiniz ilan sahibinin onayı bekleniyor.',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
          ],

          if (teklif.durum == TeklifDurum.kabul)
            _SonucKarti(
              ikon: Icons.handshake_outlined,
              mesaj: 'Anlaşma sağlandı! Yukarıdan mesajlaşmaya başlayabilirsiniz.',
              renk: AppColors.green,
            ),
          if (teklif.durum == TeklifDurum.reddedildi)
            _SonucKarti(ikon: Icons.cancel_outlined, mesaj: 'Bu teklif reddedildi.', renk: AppColors.textSecondary),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _karsiTeklifDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: teklif.miktar.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Karşı Teklif', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gelen teklif: ${teklif.miktar.toStringAsFixed(0)} ₺\nİlan fiyatı: ${teklif.ilanMiktar.toStringAsFixed(0)} ₺',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl, autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                suffixText: '₺',
                suffixStyle: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
                ),
                hintText: 'Teklifiniz',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('İptal', style: GoogleFonts.dmSans(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              final miktar = double.tryParse(ctrl.text.trim());
              if (miktar == null || miktar <= 0) return;
              Navigator.pop(ctx);
              final basarili = await ref.read(teklifProvider.notifier).karsiTeklifVer(teklif: teklif, karsiMiktar: miktar);
              if (context.mounted) {
                _snack(context, basarili ? 'Karşı teklifiniz gönderildi!' : 'Hata oluştu.',
                    basarili ? const Color(0xFFFF9800) : AppColors.red);
              }
            },
            child: Text('Gönder', style: GoogleFonts.dmSans(color: const Color(0xFFFF9800), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _onayDialog(BuildContext context, String baslik, String icerik) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(baslik, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(icerik, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
              child: Text('İptal', style: GoogleFonts.dmSans(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(c, true),
              child: Text('Evet', style: GoogleFonts.dmSans(color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj, style: GoogleFonts.dmSans()),
      backgroundColor: renk, behavior: SnackBarBehavior.floating,
    ));
  }

  String _tarihYazi(DateTime t) {
    const ay = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${t.day} ${ay[t.month]} ${t.year}';
  }
}

// Anlaşma Dialog
class _AnlasmaDialog extends StatefulWidget {
  const _AnlasmaDialog();
  @override
  State<_AnlasmaDialog> createState() => _AnlasmaDialogState();
}

class _AnlasmaDialogState extends State<_AnlasmaDialog> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), () { if (mounted) Navigator.pop(context); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.handshake_outlined, color: Color(0xFF4CAF50), size: 44),
                ),
              ),
              const SizedBox(height: 20),
              Text('Anlaşma Sağlandı!', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Teklif detayından\nmesajlaşmaya başlayabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// Yardımcı widget'lar
class _FiyatSatiri extends StatelessWidget {
  final String label;
  final double miktar;
  final Color renk;
  final bool buyuk;
  const _FiyatSatiri({required this.label, required this.miktar, required this.renk, this.buyuk = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
        Text('${miktar.toStringAsFixed(0)} ₺',
            style: GoogleFonts.dmSans(fontSize: buyuk ? 22 : 15, fontWeight: FontWeight.w700, color: renk)),
      ],
    );
  }
}

class _KisiSatiri extends StatelessWidget {
  final String ad;
  final String rol;
  final bool gosterOk;
  const _KisiSatiri({required this.ad, required this.rol, this.gosterOk = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          AvatarWidget(isim: ad, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(rol, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (gosterOk) const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _DurumBadge extends StatelessWidget {
  final TeklifDurum durum;
  const _DurumBadge({required this.durum});

  @override
  Widget build(BuildContext context) {
    final (renk, bg, label) = switch (durum) {
      TeklifDurum.bekliyor    => (const Color(0xFFFF9800), const Color(0xFFFFF3E0), 'Bekliyor'),
      TeklifDurum.kabul       => (AppColors.green,         const Color(0xFFE8F5E9), 'Kabul Edildi ✓'),
      TeklifDurum.reddedildi  => (AppColors.textSecondary, AppColors.surface,       'Reddedildi'),
      TeklifDurum.karsiTeklif => (AppColors.red,           const Color(0xFFFFEBEE), 'Karşı Teklif'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: renk)),
    );
  }
}

class _AksiyonButon extends StatelessWidget {
  final String label;
  final IconData ikon;
  final Color renk;
  final bool outlined;
  final bool yukleniyor;
  final VoidCallback onTap;
  const _AksiyonButon({required this.label, required this.ikon, required this.renk,
      required this.yukleniyor, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: yukleniyor ? null : onTap,
              style: OutlinedButton.styleFrom(foregroundColor: renk,
                  side: BorderSide(color: renk, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: Icon(ikon, size: 20),
              label: Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600)))
          : ElevatedButton.icon(
              onPressed: yukleniyor ? null : onTap,
              style: ElevatedButton.styleFrom(backgroundColor: renk, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: yukleniyor
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(ikon, size: 20),
              label: Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600))),
    );
  }
}

class _SonucKarti extends StatelessWidget {
  final IconData ikon;
  final String mesaj;
  final Color renk;
  const _SonucKarti({required this.ikon, required this.mesaj, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(ikon, color: renk, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(mesaj,
              style: GoogleFonts.dmSans(fontSize: 14, color: renk, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}