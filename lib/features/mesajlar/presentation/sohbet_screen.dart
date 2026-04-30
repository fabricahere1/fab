import 'dart:math';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../teklifler/providers/teklif_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/mesaj_provider.dart';
import '../data/mesaj_repository.dart';import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import 'anlasma_oneri_sheet.dart';
 
class SohbetScreen extends ConsumerStatefulWidget {
  final String karsiKullaniciId;
  final String karsiKullaniciAd;
  final String ilanId;
  final String ilanBaslik;
  final String? ilanResimUrl;
  final String? ilanSahibiId;
  final String? ilanSahibiAd;
  final double? ilanFiyat;
  final String? sohbetId;
  final bool anlasmaVar;

  const SohbetScreen({
    super.key,
    required this.karsiKullaniciId,
    required this.karsiKullaniciAd,
    required this.ilanId,
    required this.ilanBaslik,
    this.ilanResimUrl,
    this.sohbetId,
    this.ilanSahibiId,
    this.ilanSahibiAd,
    this.ilanFiyat,
    this.anlasmaVar = false,
  });
 
  @override
  ConsumerState<SohbetScreen> createState() => _SohbetScreenState();
}
 
class _SohbetScreenState extends ConsumerState<SohbetScreen> {
  final _mesajCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
 
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
    final sohbetId = _sohbetId;
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
                    content: Text('Bu sohbet sadece senin için silinecek.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text('İptal',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: Text('Sil',
                            style: GoogleFonts.dmSans(
                                color: AppColors.red,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
                if (onay == true && mounted) {
                  await ref.read(mesajRepositoryProvider).sohbetiGizle(
                        sohbetId: sohbetId,
                        kullaniciId: benimUid,
                      );
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: AppColors.red),
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
                        '${widget.karsiKullaniciAd} adlı kullanıcıyı engellemek istiyor musun?\n\nBu kişiyle olan tüm sohbetler gizlenecek.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text('İptal',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: Text('Engelle',
                            style: GoogleFonts.dmSans(
                                color: AppColors.red,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
                if (onay == true && mounted) {
                  await ref.read(engellemeProvider.notifier).engelle(
                        benimUid: benimUid,
                        hedefUid: widget.karsiKullaniciId,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${widget.karsiKullaniciAd} engellendi.',
                            style: GoogleFonts.dmSans()),
                        backgroundColor: AppColors.textSecondary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
 
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: widget.ilanResimUrl != null &&
                      widget.ilanResimUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.ilanResimUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      errorWidget: (_, _, _) => _IlanResimPlaceholder(),
                    )
                  : _IlanResimPlaceholder(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ilanBaslik,
                    style: GoogleFonts.dmSans(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.karsiKullaniciAd,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () => _ucNoktaMenu(benimUid),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Anlaşma Barı ─────────────────────────────────
          if (widget.anlasmaVar)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.10),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.green.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_rounded,
                        color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ilanBaslik.isNotEmpty
                              ? widget.ilanBaslik
                              : 'İlan',
                          style: GoogleFonts.dmSans(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Kabul edilmiş teklif',
                          style: GoogleFonts.dmSans(
                            color: AppColors.green.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _WatermarkPainter()),
                ),
                sohbetState.yukleniyor && sohbetState.siraliMesajlar.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.red, strokeWidth: 2))
                    : sohbetState.siraliMesajlar.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 50, color: AppColors.divider),
                                const SizedBox(height: 12),
                                Text('Henüz mesaj yok.',
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.textSecondary,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('İlk mesajı sen gönder!',
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.textHint,
                                        fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            itemCount: sohbetState.siraliMesajlar.length +
                                (sohbetState.dahaFazlaVar ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == sohbetState.siraliMesajlar.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () => ref
                                          .read(sohbetProvider(
                                            karsiKullaniciId:
                                                widget.karsiKullaniciId,
                                            ilanId: widget.ilanId,
                                          ).notifier)
                                          .dahaFazlaYukle(),
                                      child: Text('Daha fazla mesaj yükle',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              color: AppColors.textSecondary)),
                                    ),
                                  ),
                                );
                              }
 
                              final mesaj = sohbetState.siraliMesajlar[index];
                              final tip = mesaj['tip'] ?? 'mesaj';

                              if (tip == 'sistem') {
                                return _SistemMesaji(metin: mesaj['metin'] ?? '');
                              }

                              final benimMesajim = mesaj['gondereId'] == benimUid;
                              // Zaman değeri her zaman DateTime olarak alınır
                              // Timestamp dönüşümü mesaj_provider._sirala'da yapılıyor
                              final zamanRaw = mesaj['zaman'];
                              final zaman = zamanRaw is DateTime
                                  ? zamanRaw
                                  : (zamanRaw as dynamic)?.toDate() as DateTime?;
                              final zamanYazi = zaman != null
                                  ? '${zaman.hour.toString().padLeft(2, '0')}:${zaman.minute.toString().padLeft(2, '0')}'
                                  : '';
                              final metin  = mesaj['metin'] ?? '';
                              final okundu = mesaj['okundu'] as bool? ?? false;

                              // Anlaşma mesajı — özel balon
                              if (tip == 'anlasma') {
                                final tutar        = (mesaj['tutar'] as num?)?.toDouble() ?? 0;
                                final anlasmaEvet  = mesaj['anlasmaEvet'] as bool? ?? false;
                                final anlasmaRed   = mesaj['anlasmaRed']  as bool? ?? false;
                                final mesajId      = mesaj['id'] as String? ?? '';

                                return RepaintBoundary(
                                  key: ValueKey(mesajId),
                                  child: _AnlasmaBalonu(
                                    tutar: tutar,
                                    benimMesajim: benimMesajim,
                                    zaman: zamanYazi,
                                    anlasmaEvet: anlasmaEvet,
                                    anlasmaRed: anlasmaRed,
                                    ilanBaslik: widget.ilanBaslik,
                                    onKabul: benimMesajim ? null : () async {
                                      if (mesajId.isEmpty) return;
                                      await ref.read(sohbetProvider(
                                        karsiKullaniciId: widget.karsiKullaniciId,
                                        ilanId: widget.ilanId,
                                      ).notifier).anlasmaKabul(
                                        mesajId: mesajId,
                                        gondereId: mesaj['gondereId'] as String? ?? '',
                                        ilanBaslik: widget.ilanBaslik,
                                        ilanSahibiAd: widget.ilanSahibiAd ?? '',
                                      );
                                    },
                                    onRed: benimMesajim ? null : () async {
                                      if (mesajId.isEmpty) return;
                                      final sohbetId = sohbetIdUret(
                                        benimUid,
                                        widget.karsiKullaniciId,
                                        widget.ilanId,
                                      );
                                      await ref.read(mesajRepositoryProvider)
                                          .anlasmaRed(
                                            sohbetId: sohbetId,
                                            mesajId: mesajId,
                                          );
                                    },
                                  ),
                                );
                              }

                              // Resim mesajı
                              if (tip == 'resim') {
                                final resimUrl = mesaj['resimUrl'] as String? ?? '';
                                return RepaintBoundary(
                                  key: ValueKey(mesaj['id']),
                                  child: _ResimBalonu(
                                    resimUrl: resimUrl,
                                    benimMesajim: benimMesajim,
                                    zaman: zamanYazi,
                                    karsiOkudu: benimMesajim && okundu,
                                  ),
                                );
                              }

                              return RepaintBoundary(
                                key: ValueKey(mesaj['id']),
                                child: _MesajBalonu(
                                  metin: metin,
                                  benimMesajim: benimMesajim,
                                  zaman: zamanYazi,
                                  karsiOkudu: benimMesajim && okundu,
                                  gondereAd: benimMesajim
                                      ? null
                                      : widget.karsiKullaniciAd,
                                  onLongPress: benimMesajim
                                      ? () => _mesajSilDialog(mesaj['id'], metin)
                                      : null,
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── Ek butonu ─────────────────────────────────
                GestureDetector(
                  onTap: () => _ekMenuAc(benimUid),
                  child: Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _mesajCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _gonder(benimUid),
                      maxLines: 5,
                      minLines: 1,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        hintStyle:
                            GoogleFonts.dmSans(color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: sohbetState.gonderiyor ? null : () => _gonder(benimUid),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: sohbetState.gonderiyor
                          ? AppColors.divider
                          : AppColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: sohbetState.gonderiyor
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
          ),
        ],
      ),
    );
  }
 
  Future<void> _ekMenuAc(String benimUid) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              _EkMenuItem(
                ikon: Icons.photo_library_outlined,
                baslik: 'Resim Gönder',
                aciklama: 'Galeriden fotoğraf seç',
                renk: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _resimSec(benimUid);
                },
              ),
              const SizedBox(height: 10),
              _EkMenuItem(
                ikon: Icons.handshake_outlined,
                baslik: 'Hızlı Anlaş',
                aciklama: 'İstekçinin fiyatından getirebilirsin',
                renk: AppColors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  _anlasmaOner(benimUid);
                },
              ),
              const SizedBox(height: 10),
              _EkMenuItem(
                ikon: Icons.local_offer_outlined,
                baslik: 'Teklif Ver',
                aciklama: 'Resmi teklif akışını başlat',
                renk: AppColors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _teklifVerAc();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resimSec(String benimUid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked == null || !mounted) return;

    await ref.read(sohbetProvider(
      karsiKullaniciId: widget.karsiKullaniciId,
      ilanId: widget.ilanId,
    ).notifier).resimGonder(
      dosya: File(picked.path),
      karsiKullaniciId: widget.karsiKullaniciId,
      ilanId: widget.ilanId,
      ilanBaslik: widget.ilanBaslik,
      ilanResimUrl: widget.ilanResimUrl ?? '',
    );
  }

  void _teklifVerAc() {
    final ilanSahibiId = widget.ilanSahibiId;
    final ilanSahibiAd = widget.ilanSahibiAd;
    if (ilanSahibiId == null || ilanSahibiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teklif verebilmek için ilan detayına git.',
              style: GoogleFonts.dmSans()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SohbetTeklifSheet(
        ilanId: widget.ilanId,
        ilanBaslik: widget.ilanBaslik,
        ilanSahibiId: ilanSahibiId,
        ilanSahibiAd: ilanSahibiAd ?? 'İlan Sahibi',
        ilanFiyat: widget.ilanFiyat ?? 0,
      ),
    );
  }

  Future<void> _anlasmaOner(String benimUid) async {
    final onaylandi = await AnlasmaOneriSheet.goster(
      context,
      karsiKullaniciAd: widget.karsiKullaniciAd,
      ilanBaslik: widget.ilanBaslik,
      onerilenfiyat: widget.ilanFiyat,
    );
    if (onaylandi != true || !mounted) return;

    final fiyat = widget.ilanFiyat ?? 0;
    await ref.read(sohbetProvider(
      karsiKullaniciId: widget.karsiKullaniciId,
      ilanId: widget.ilanId,
    ).notifier).mesajGonder(
      metin: fiyat > 0
          ? '🤝 İstekçinin fiyatından getirebilirim: ${fiyat.toStringAsFixed(0)} ₺'
          : '💬 İlanınızla ilgileniyorum, hadi konuşalım!',
      karsiKullaniciId: widget.karsiKullaniciId,
      ilanId: widget.ilanId,
      ilanBaslik: widget.ilanBaslik,
      tip: fiyat > 0 ? 'anlasma' : 'mesaj',
      tutar: fiyat > 0 ? fiyat : null,
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
        );
  }
 
  Future<void> _mesajSilDialog(String mesajId, String metin) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text('Mesajı Sil',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Bu mesajı silmek istediğine emin misin?',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('İptal',
                style:
                    GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Sil',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay == true) {
      await ref
          .read(sohbetProvider(
            karsiKullaniciId: widget.karsiKullaniciId,
            ilanId: widget.ilanId,
          ).notifier)
          .mesajSil(mesajId: mesajId, metin: metin);
    }
  }
}
 
class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.28),
      fontSize: 22,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: 2,
    );
    const metin = 'İSTE';
    const satirAraligi = 70.0;
    const sutunAraligi = 110.0;
    const aci = -pi / 6;
    canvas.save();
    canvas.rotate(aci);
    final genislik = size.width * 2 + size.height;
    final yukseklik = size.height * 2 + size.width;
    for (double y = -yukseklik / 2; y < yukseklik; y += satirAraligi) {
      for (double x = -genislik / 2; x < genislik; x += sutunAraligi) {
        final textPainter = TextPainter(
          text: TextSpan(text: metin, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }
 
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
 
class _IlanResimPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image_outlined,
          color: AppColors.textHint, size: 20),
    );
  }
}
 
class _MesajBalonu extends StatelessWidget {
  final String metin;
  final bool benimMesajim;
  final String zaman;
  final String? gondereAd;
  final VoidCallback? onLongPress;
  final bool karsiOkudu;
 
  const _MesajBalonu({
    required this.metin,
    required this.benimMesajim,
    required this.zaman,
    this.gondereAd,
    this.onLongPress,
    this.karsiOkudu = false,
  });
 
  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final balonRenk = benimMesajim ? AppColors.red : Colors.white;
    final metinRenk = benimMesajim ? Colors.white : Colors.black87;
    final zamanRenk = benimMesajim
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.grey.shade500;
    final zamanGenislik = benimMesajim ? 52.0 : 34.0;
 
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16, right: zamanGenislik - 8),
              child: Text(metin,
                  style: TextStyle(
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
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: karsiOkudu
                          ? const Color(0xFF90CAF9)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
 
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Align(
          alignment: benimMesajim
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: benimMesajim
              ? balon
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.red.withValues(alpha: 0.15),
                      child: Text(
                        gondereAd?.isNotEmpty == true
                            ? gondereAd![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    balon,
                  ],
                ),
        ),
      ),
    );
  }
}
 
class _SistemMesaji extends StatelessWidget {
  final String metin;
  const _SistemMesaji({required this.metin});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(metin,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
// ── Ek menü item widget ───────────────────────────────────────────────────────

class _EkMenuItem extends StatelessWidget {
  final IconData ikon;
  final String baslik, aciklama;
  final Color renk;
  final VoidCallback onTap;

  const _EkMenuItem({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: renk.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, color: renk, size: 22),
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
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(aciklama,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Anlaşma Balonu ────────────────────────────────────────────────────────────

class _AnlasmaBalonu extends StatelessWidget {
  final double tutar;
  final bool benimMesajim;
  final String zaman, ilanBaslik;
  final bool anlasmaEvet, anlasmaRed;
  final VoidCallback? onKabul, onRed;

  const _AnlasmaBalonu({
    required this.tutar,
    required this.benimMesajim,
    required this.zaman,
    required this.ilanBaslik,
    required this.anlasmaEvet,
    required this.anlasmaRed,
    this.onKabul,
    this.onRed,
  });

  @override
  Widget build(BuildContext context) {
    final tamamlandi = anlasmaEvet || anlasmaRed;

    return Padding(
      padding: EdgeInsets.only(
        left: benimMesajim ? 60 : 12,
        right: benimMesajim ? 12 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Align(
        alignment: benimMesajim
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: anlasmaEvet
                  ? AppColors.green
                  : anlasmaRed
                      ? AppColors.divider
                      : AppColors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: anlasmaEvet
                      ? AppColors.green.withValues(alpha: 0.08)
                      : anlasmaRed
                          ? AppColors.surface
                          : AppColors.red.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Icon(
                      anlasmaEvet
                          ? Icons.handshake_rounded
                          : anlasmaRed
                              ? Icons.cancel_outlined
                              : Icons.handshake_outlined,
                      size: 18,
                      color: anlasmaEvet
                          ? AppColors.green
                          : anlasmaRed
                              ? AppColors.textSecondary
                              : AppColors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        anlasmaEvet
                            ? 'Anlaşma Sağlandı!'
                            : anlasmaRed
                                ? 'Anlaşma Reddedildi'
                                : 'Anlaşma Önerisi',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: anlasmaEvet
                              ? AppColors.green
                              : anlasmaRed
                                  ? AppColors.textSecondary
                                  : AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tutar ve ilan
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tutar.toStringAsFixed(0)} ₺',
                      style: GoogleFonts.dmSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ilanBaslik,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Kabul/Red butonları — sadece alıcıya, tamamlanmamışsa
              if (!benimMesajim && !tamamlandi) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRed,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                                color: AppColors.divider),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                          child: Text('Reddet',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onKabul,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                          child: Text('Kabul Et',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Saat
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Text(
                  zaman,
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── Resim Balonu ──────────────────────────────────────────────────────────────

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
        bottom: 3,
      ),
      child: Align(
        alignment: benimMesajim ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullscreenResim(resimUrl: resimUrl),
            ),
          ),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
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
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textHint, size: 32),
                    ),
                  ),
                  // Zaman + okundu overlay
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                                  ? Colors.lightBlueAccent
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

// ── Fullscreen Resim Görüntüleyici ────────────────────────────────────────────

class _FullscreenResim extends StatelessWidget {
  final String resimUrl;
  const _FullscreenResim({required this.resimUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: resimUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) => const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
            errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined,
                color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}

// ── Sohbet İçi Teklif Sheet ───────────────────────────────────────────────────

class _SohbetTeklifSheet extends ConsumerStatefulWidget {
  final String ilanId;
  final String ilanBaslik;
  final String ilanSahibiId;
  final String ilanSahibiAd;
  final double ilanFiyat;

  const _SohbetTeklifSheet({
    required this.ilanId,
    required this.ilanBaslik,
    required this.ilanSahibiId,
    required this.ilanSahibiAd,
    required this.ilanFiyat,
  });

  @override
  ConsumerState<_SohbetTeklifSheet> createState() => _SohbetTeklifSheetState();
}

class _SohbetTeklifSheetState extends ConsumerState<_SohbetTeklifSheet> {
  final _ctrl    = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(teklifProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.local_offer_outlined,
                      color: AppColors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Teklif Ver',
                      style: GoogleFonts.dmSans(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.ilanBaslik,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (widget.ilanFiyat > 0) ...[
                const SizedBox(height: 2),
                Text('İlan fiyatı: ${widget.ilanFiyat.toStringAsFixed(0)} ₺',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint),
                  suffixText: '₺',
                  suffixStyle: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Lütfen bir tutar girin';
                  final m = double.tryParse(v);
                  if (m == null || m <= 0) return 'Geçerli bir tutar girin';
                  return null;
                },
              ),
              if (widget.ilanFiyat > 0) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [0.9, 0.8, 0.7].map((oran) {
                    final deger = (widget.ilanFiyat * oran).round();
                    return ActionChip(
                      label: Text('$deger ₺',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.divider),
                      onPressed: () =>
                          setState(() => _ctrl.text = deger.toString()),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: yukleniyor ? null : _gonder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: yukleniyor
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Teklifi Gönder',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _gonder() async {
    if (!_formKey.currentState!.validate()) return;
    final miktar   = double.parse(_ctrl.text.trim());
    final kullanici = ref.read(currentUserProvider);
    if (kullanici == null) return;

    final profil  = ref.read(benimKullaniciProfilProvider).value;
    final adSoyad = profil?.adSoyad ?? kullanici.displayName ?? 'Kullanıcı';

    final basarili = await ref.read(teklifProvider.notifier).teklifVer(
      ilanId:        widget.ilanId,
      ilanBaslik:    widget.ilanBaslik,
      ilanSahibiId:  widget.ilanSahibiId,
      ilanSahibiAd:  widget.ilanSahibiAd,
      teklifVerenId: kullanici.uid,
      teklifVerenAd: adSoyad,
      miktar:        miktar,
      ilanMiktar:    widget.ilanFiyat,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        basarili ? 'Teklifiniz gönderildi! 🎉' : 'Bir hata oluştu, tekrar deneyin.',
        style: GoogleFonts.dmSans(),
      ),
      backgroundColor: basarili ? AppColors.green : AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
