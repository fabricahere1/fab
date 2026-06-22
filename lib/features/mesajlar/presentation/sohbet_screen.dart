import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/mesaj_provider.dart';
import '../domain/mesaj_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../ilanlar/presentation/ilan_detay_screen.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../profil/presentation/kullanici_profil_screen.dart';
import 'islem_durumu_panel.dart';
import '../../degerlendirme/presentation/degerlendirme_screen.dart';
import '../../degerlendirme/providers/degerlendirme_provider.dart';

class SohbetScreen extends ConsumerStatefulWidget {
  final String karsiKullaniciId;
  final String karsiKullaniciAd;
  final String ilanId;
  final String ilanBaslik;
  final String? ilanResimUrl;
  final String? sohbetId;
  final String? ilgileniyorumMesaji;
  final String ilanSahibiId;
  final String ilanTip;
  final bool autoOpenPanel;

  const SohbetScreen({
    super.key,
    required this.karsiKullaniciId,
    required this.karsiKullaniciAd,
    required this.ilanId,
    required this.ilanBaslik,
    this.ilanResimUrl,
    this.sohbetId,
    this.ilgileniyorumMesaji,
    this.ilanSahibiId = '',
    this.ilanTip = 'istek',
    this.autoOpenPanel = false,
  });

  @override
  ConsumerState<SohbetScreen> createState() => _SohbetScreenState();
}

class _SohbetScreenState extends ConsumerState<SohbetScreen> {
  final _mesajCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _degerlendirmeAcik = false;

  @override
  void initState() {
    super.initState();
    if (widget.ilgileniyorumMesaji != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _gonderIlgileniyorum());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iletisimBasladiIsaretle();
      _degerlendirmeyiDinle();
      if (widget.autoOpenPanel) _panelAc();
    });
  }

  Future<void> _iletisimBasladiIsaretle() async {
    try {
      await ref.read(islemDurumuIslemleriProvider(_sohbetId).notifier)
          .guncelle('iletisimBasladi');
    } catch (_) {}
  }

  void _panelAc() {
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        barrierDismissible: true,
        pageBuilder: (ctx, anim, _) => Align(
          alignment: Alignment.centerRight,
          child: IslemDurumuPanel(
            sohbetId: _sohbetId,
            karsiKullaniciAd: widget.karsiKullaniciAd,
          ),
        ),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  void _degerlendirmeyiDinle() {
    bool ilkSnapshot = true;

    ref.listenManual(
      sohbetDurumuProvider(_sohbetId),
      (_, next) async {
        // İlk snapshot mevcut durumu yansıtır — değerlendirme popup'ı gösterme.
        // Sohbete her girişte yeniden tetiklenmesini önler.
        if (ilkSnapshot) {
          ilkSnapshot = false;
          return;
        }

        if (!mounted) return;
        final d = next.value;
        if (d == null) return;

        final benimUid = ref.read(currentUserProvider)?.uid ?? '';
        if (benimUid.isEmpty) return;

        final teslimAlindi =
            (d['islemDurumlari'] as Map<String, dynamic>?)?['teslimAlindi'] == true;
        final zatenYaptim = d['degerlendirmeYapildi_$benimUid'] == true;

        if (!teslimAlindi || zatenYaptim || _degerlendirmeAcik) return;

        final kullanicilar = List<String>.from(d['kullanicilar'] ?? []);
        final karsiId = kullanicilar.firstWhere(
            (id) => id != benimUid, orElse: () => '');
        if (karsiId.isEmpty || !mounted) return;

        _degerlendirmeAcik = true;

        final sonuc = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black.withValues(alpha: 0.5),
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (ctx, anim, _) => _TeslimAlindiOnayDialog(
            sohbetId: _sohbetId,
            karsiKullaniciAd: widget.karsiKullaniciAd,
          ),
          transitionBuilder: (ctx, anim, _, child) {
            final curved =
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
            return ScaleTransition(
              scale: Tween<double>(begin: 0.75, end: 1.0).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );

        if (!mounted) {
          _degerlendirmeAcik = false;
          return;
        }

        if (sonuc == true) {
          final gonderildi = await DegerlendirmeModal.goster(
            context: context,
            sohbetId: _sohbetId,
            hedefKullaniciId: karsiId,
            hedefKullaniciAd: widget.karsiKullaniciAd,
          );
          if (gonderildi && mounted) {
            await showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF81C784), size: 38),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Değerlendirme için teşekkür ederiz!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tüm değerlendirmelere Profil sayfasından ulaşabilirsin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Kapat',
                              style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        } else if (sonuc == false) {
          await ref.read(degerlendirmeIslemleriProvider.notifier).bekleyenKaydet(
            sohbetId: _sohbetId,
            kullaniciId: benimUid,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                "Değerlendirme Ayarlar > Değerlendirmelerim'de bekliyor.",
                style: GoogleFonts.dmSans(),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ));
          }
        }
        _degerlendirmeAcik = false;
      },
    );
  }

  Future<void> _gonderIlgileniyorum() async {
    final benimUid = ref.read(currentUserProvider)?.uid ?? '';
    if (benimUid.isEmpty) return;
    await ref.read(sohbetProvider(
      karsiKullaniciId: widget.karsiKullaniciId,
      ilanId: widget.ilanId,
    ).notifier).mesajGonder(
      metin: widget.ilgileniyorumMesaji!,
      karsiKullaniciId: widget.karsiKullaniciId,
      ilanId: widget.ilanId,
      ilanBaslik: widget.ilanBaslik,
      ilanResimUrl: widget.ilanResimUrl ?? '',
      ilanSahibiId: widget.ilanSahibiId,
      ilanTip: widget.ilanTip,
    );
  }

  @override
  void dispose() {
    _mesajCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _sohbetId {
    final ids = [
      ref.read(currentUserProvider)?.uid ?? '',
      widget.karsiKullaniciId
    ]..sort();
    return '${ids[0]}_${ids[1]}_${widget.ilanId}';
  }

  Future<void> _ucNoktaMenu(String benimUid) async {
    final sid = _sohbetId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.textSecondary),
              title: Text('Sohbeti Sil',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(ctx);
                final onay = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text('Sohbeti Sil',
                        style: GoogleFonts.dmSans(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    content: Text(
                        'Bu sohbet sadece senin için silinecek.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text('İptal',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary))),
                      TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text('Sil',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700))),
                    ],
                  ),
                );
                if (onay == true && mounted) {
                  await ref.read(sohbetIslemleriProvider.notifier).gizle(
                      sohbetId: sid, kullaniciId: benimUid);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading:
                  const Icon(Icons.block_outlined, color: AppColors.red),
              title: Text('${widget.karsiKullaniciAd} Engelle',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.red,
                      fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(ctx);
                final onay = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text('Kullanıcıyı Engelle',
                        style: GoogleFonts.dmSans(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    content: Text(
                        '${widget.karsiKullaniciAd} adlı kullanıcıyı engellemek istiyor musun?',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text('İptal',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary))),
                      TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text('Engelle',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700))),
                    ],
                  ),
                );
                if (onay == true && mounted) {
                  await ref.read(engellemeProvider.notifier).engelle(
                      benimUid: benimUid,
                      hedefUid: widget.karsiKullaniciId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '${widget.karsiKullaniciAd} engellendi.',
                          style: GoogleFonts.dmSans()),
                      backgroundColor: AppColors.textSecondary,
                      behavior: SnackBarBehavior.floating,
                    ));
                    Navigator.pop(context);
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final benimUid = ref.watch(currentUserProvider)?.uid ?? '';
    final sohbetState = ref.watch(sohbetProvider(
      karsiKullaniciId: widget.karsiKullaniciId,
      ilanId: widget.ilanId,
    ));

    // Mesaj stream hatalarını dinle → snackbar göster
    ref.listen(
      sohbetProvider(
        karsiKullaniciId: widget.karsiKullaniciId,
        ilanId: widget.ilanId,
      ),
      (onceki, sonraki) {
        if (sonraki.hata != null && sonraki.hata != onceki?.hata) {
          AppSnackBar.hata(context, sonraki.hata!);
        }
      },
    );
    final ilanAsync = widget.ilanId.isNotEmpty
        ? ref.watch(ilanByIdProvider(widget.ilanId))
        : null;
    final guzergah = ilanAsync?.value != null
        ? '${ilanAsync!.value!.nereden} → ${ilanAsync.value!.nereye}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(114),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Geri butonu
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // İki kart alt alta
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Kişi kartı
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (ctx, anim, _) => KullaniciProfilScreen(
                                kullaniciId: widget.karsiKullaniciId,
                                kullaniciAd: widget.karsiKullaniciAd,
                              ),
                              transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                                position: Tween(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                    parent: anim, curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                              transitionDuration: const Duration(milliseconds: 280),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider, width: 0.7),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.red.withValues(alpha: 0.15),
                                  child: Text(
                                    widget.karsiKullaniciAd.isNotEmpty
                                        ? widget.karsiKullaniciAd[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.karsiKullaniciAd,
                                    style: GoogleFonts.dmSans(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textHint, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // İlan kartı
                        if (widget.ilanId.isNotEmpty && widget.ilanBaslik.isNotEmpty)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => IlanDetayScreen(ilanId: widget.ilanId),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider, width: 0.7),
                              ),
                              child: Row(
                                children: [
                                  if (widget.ilanResimUrl != null && widget.ilanResimUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.ilanResimUrl!,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        fadeInDuration: Duration.zero,
                                        errorWidget: (_, _, _) => _IlanResimPlaceholder(),
                                      ),
                                    )
                                  else
                                    _IlanResimPlaceholder(),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.ilanBaslik,
                                          style: GoogleFonts.dmSans(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (guzergah.isNotEmpty)
                                          Text(
                                            guzergah,
                                            style: GoogleFonts.dmSans(
                                                color: AppColors.textSecondary,
                                                fontSize: 10),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.textHint, size: 16),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Üç nokta menü
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                    onPressed: () => _ucNoktaMenu(benimUid),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _MesajListesi(
                  sohbetState: sohbetState,
                  benimUid: benimUid,
                  karsiAd: widget.karsiKullaniciAd,
                  karsiId: widget.karsiKullaniciId,
                  ilanId: widget.ilanId,
                  scrollCtrl: _scrollCtrl,
                ),
              ),
              _InputBar(
                mesajCtrl: _mesajCtrl,
                gonderiyor: sohbetState.gonderiyor,
                onResim: () => _resimSec(benimUid),
                onGonder: () => _gonder(benimUid),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IslemDurumuTetikleyici(
                sohbetId: _sohbetId,
                karsiKullaniciAd: widget.karsiKullaniciAd,
                ilanTip: widget.ilanTip,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resimSec(String benimUid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 1080,
        maxHeight: 1080);
    if (picked == null || !mounted) return;
    await ref
        .read(sohbetProvider(
          karsiKullaniciId: widget.karsiKullaniciId,
          ilanId: widget.ilanId,
        ).notifier)
        .resimGonder(
          dosya: File(picked.path),
          karsiKullaniciId: widget.karsiKullaniciId,
          ilanId: widget.ilanId,
          ilanBaslik: widget.ilanBaslik,
          ilanResimUrl: widget.ilanResimUrl ?? '',
          ilanSahibiId: widget.ilanSahibiId,
          ilanTip: widget.ilanTip,
        );
  }

  Future<void> _gonder(String benimUid) async {
    final metin = _mesajCtrl.text.trim();
    if (metin.isEmpty) return;
    _mesajCtrl.clear();
    await ref
        .read(sohbetProvider(
          karsiKullaniciId: widget.karsiKullaniciId,
          ilanId: widget.ilanId,
        ).notifier)
        .mesajGonder(
          metin: metin,
          karsiKullaniciId: widget.karsiKullaniciId,
          ilanId: widget.ilanId,
          ilanBaslik: widget.ilanBaslik,
          ilanResimUrl: widget.ilanResimUrl ?? '',
          ilanSahibiId: widget.ilanSahibiId,
          ilanTip: widget.ilanTip,
        );
  }
}

// ── Mesaj Listesi ─────────────────────────────────────────

class _MesajListesi extends ConsumerWidget {
  final SohbetEkraniState sohbetState;
  final String benimUid;
  final String karsiAd;
  final String karsiId;
  final String ilanId;
  final ScrollController scrollCtrl;

  const _MesajListesi({
    required this.sohbetState,
    required this.benimUid,
    required this.karsiAd,
    required this.karsiId,
    required this.ilanId,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hata var ve hiç mesaj yoksa — imleç yerine anlamlı hata göster
    if (sohbetState.hata != null && sohbetState.siraliMesajlar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                sohbetState.hata!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(sohbetProvider(
                  karsiKullaniciId: karsiId,
                  ilanId: ilanId,
                )),
                child: Text('Tekrar Dene',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }
    if (sohbetState.yukleniyor && sohbetState.siraliMesajlar.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.red, strokeWidth: 2));
    }
    if (sohbetState.siraliMesajlar.isEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: _KurallarBanner(),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 50, color: AppColors.divider),
                  const SizedBox(height: 12),
                  Text('Henüz mesaj yok.',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('İlk mesajı sen gönder!',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    // reverse:true → index 0 = en yeni mesaj (altta), yüksek index = üstte
    // Banner en üstte (konuşma başında) görünmesi için en yüksek indexe ekleniyor
    final dahaFazlaOffset = sohbetState.dahaFazlaVar ? 1 : 0;
    final bannerIndex = sohbetState.siraliMesajlar.length + dahaFazlaOffset;

    return ListView.builder(
      reverse: true,
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: bannerIndex + 1,
      itemBuilder: (context, index) {
        // En üstteki item: Mesajlaşma Kuralları
        if (index == bannerIndex) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _KurallarBanner(),
          );
        }
        // "Daha fazla mesaj yükle" butonu
        if (index == sohbetState.siraliMesajlar.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: TextButton(
                onPressed: () => ref
                    .read(sohbetProvider(
                            karsiKullaniciId: karsiId, ilanId: ilanId)
                        .notifier)
                    .dahaFazlaYukle(),
                child: Text('Daha fazla mesaj yükle',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            ),
          );
        }
        final mesaj = sohbetState.siraliMesajlar[index];
        final benimMesajim = mesaj.gondereId == benimUid;
        final zamanYazi = mesaj.zaman != null
            ? '${mesaj.zaman!.hour.toString().padLeft(2, '0')}:${mesaj.zaman!.minute.toString().padLeft(2, '0')}'
            : '';
        if (mesaj.sistemMesaji) return _SistemMesaji(metin: mesaj.metin);
        if (mesaj.tip == MesajTip.resim) {
          return RepaintBoundary(
            key: ValueKey(mesaj.id),
            child: _ResimBalonu(
              resimUrl: mesaj.resimUrl ?? '',
              benimMesajim: benimMesajim,
              zaman: zamanYazi,
              karsiOkudu: benimMesajim && mesaj.okundu,
            ),
          );
        }
        final ilgileniyorum = mesaj.metin == 'İlanınızla ilgileniyorum';
        return RepaintBoundary(
          key: ValueKey(mesaj.id),
          child: _MesajBalonu(
            metin: mesaj.metin,
            benimMesajim: benimMesajim,
            zaman: zamanYazi,
            karsiOkudu: benimMesajim && mesaj.okundu,
            gondereAd: benimMesajim ? null : karsiAd,
            ilgileniyorum: ilgileniyorum,
          ),
        );
      },
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController mesajCtrl;
  final bool gonderiyor;
  final VoidCallback onResim;
  final VoidCallback onGonder;

  const _InputBar({
    required this.mesajCtrl,
    required this.gonderiyor,
    required this.onResim,
    required this.onGonder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onResim,
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider)),
              child: const Icon(Icons.photo_library_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider)),
              child: TextField(
                controller: mesajCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onGonder(),
                maxLines: 5,
                minLines: 1,
                style: GoogleFonts.dmSans(
                    fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Mesaj yaz...',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: gonderiyor ? null : onGonder,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: gonderiyor ? AppColors.divider : AppColors.red,
                  shape: BoxShape.circle),
              child: gonderiyor
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────

class _IlanResimPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.image_outlined,
            color: AppColors.textHint, size: 16),
      );
}

// ── Mesajlaşma Kuralları Banner ───────────────────────────────────────────────

class _KurallarBanner extends StatelessWidget {
  const _KurallarBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Mesajlaşma Kuralları',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hakaret içeren veya dolandırma amaçlı mesaj göndermeniz durumunda mesajlaşma hakkınız engellenebilir veya hesabınız kapatılabilir.\n\nEğer sizi rahatsız eden bir mesaj alırsanız mesajlaştığınız kişiyi engelleyebilir veya şikayet edebilirsiniz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MesajBalonu extends StatelessWidget {
  final String metin;
  final bool benimMesajim;
  final String zaman;
  final String? gondereAd;
  final bool karsiOkudu;
  final bool ilgileniyorum;

  const _MesajBalonu({
    required this.metin,
    required this.benimMesajim,
    required this.zaman,
    this.gondereAd,
    this.karsiOkudu = false,
    this.ilgileniyorum = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    const Color gidanBalon     = Color(0xFFD2E3FC);
    const Color gelenBalon     = Color(0xFFFFFFFF);
    const Color ilgilirenBalon = Color(0xFFFFF3E0);
    const Color metin202124    = Color(0xFF202124);
    const Color metinYesil     = Color(0xFFE65100);

    final balonRenk = ilgileniyorum
        ? ilgilirenBalon
        : benimMesajim
            ? gidanBalon
            : gelenBalon;
    const metinRenk = metin202124;
    final zamanRenk = metin202124.withValues(alpha: 0.5);

    final balon = Container(
      constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 80),
      decoration: BoxDecoration(
        color: balonRenk,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(benimMesajim ? 16 : 4),
          bottomRight: Radius.circular(benimMesajim ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 44),
              child: ilgileniyorum
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.emoji_people_outlined,
                          color: metinYesil, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(metin,
                            style: const TextStyle(
                                color: metinYesil,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.35)),
                      ),
                    ])
                  : Text(metin,
                      style: const TextStyle(
                          color: metinRenk, fontSize: 15, height: 1.35)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(zaman,
                      style: TextStyle(color: zamanRenk, fontSize: 11)),
                  if (benimMesajim) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.done_all, size: 14,
                        color: karsiOkudu
                            ? const Color(0xFF1A73E8)
                            : metin202124.withValues(alpha: 0.35)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Align(
        alignment:
            benimMesajim ? Alignment.centerRight : Alignment.centerLeft,
        child: benimMesajim
            ? balon
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFF1F3F4),
                    child: Text(
                      gondereAd?.isNotEmpty == true
                          ? gondereAd![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Color(0xFF5F6368),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  balon,
                ],
              ),
      ),
    );
  }
}

class _SistemMesaji extends StatelessWidget {
  final String metin;
  const _SistemMesaji({required this.metin});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(12)),
            child: Text(metin,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF5F6368),
                    fontWeight: FontWeight.w500)),
          ),
        ),
      );
}

class _ResimBalonu extends StatelessWidget {
  final String resimUrl;
  final bool benimMesajim;
  final String zaman;
  final bool karsiOkudu;

  const _ResimBalonu({
    required this.resimUrl,
    required this.benimMesajim,
    required this.zaman,
    this.karsiOkudu = false,
  });

  @override
  Widget build(BuildContext context) {
    const double w = 200;
    const double h = 200;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(benimMesajim ? 16 : 4),
      bottomRight: Radius.circular(benimMesajim ? 4 : 16),
    );
    return Padding(
      padding: EdgeInsets.only(
          left: benimMesajim ? 60 : 12,
          right: benimMesajim ? 12 : 60,
          top: 3,
          bottom: 3),
      child: Align(
        alignment:
            benimMesajim ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      _FullscreenResim(resimUrl: resimUrl))),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: resimUrl,
                    width: w,
                    height: h,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                        color: AppColors.surface,
                        child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textHint))),
                    errorWidget: (_, _, _) => Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.textHint, size: 32)),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(zaman,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          if (benimMesajim) ...[
                            const SizedBox(width: 3),
                            Icon(
                              karsiOkudu
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 13,
                              color: karsiOkudu
                                  ? const Color(0xFF1A73E8)
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenResim extends StatelessWidget {
  final String resimUrl;
  const _FullscreenResim({required this.resimUrl});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: resimUrl,
              fit: BoxFit.contain,
              placeholder: (_, _) => const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
              errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48),
            ),
          ),
        ),
      );
}

// ── Teslim Alındı Onay Dialogu ────────────────────────────

class _TeslimAlindiOnayDialog extends StatefulWidget {
  final String sohbetId;
  final String karsiKullaniciAd;

  const _TeslimAlindiOnayDialog({
    required this.sohbetId,
    required this.karsiKullaniciAd,
  });

  @override
  State<_TeslimAlindiOnayDialog> createState() =>
      _TeslimAlindiOnayDialogState();
}

class _TeslimAlindiOnayDialogState extends State<_TeslimAlindiOnayDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -11.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -11.0, end: 11.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 11.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _shakeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Color(0xFF81C784), size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.karsiKullaniciAd} için\nDeğerlendirme Yapmak İster Misiniz?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deneyimini paylaşarak diğer kullanıcılara yardımcı ol.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF757575),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Evet, Değerlendir',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Şimdi Değil',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: const Color(0xFF757575))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}