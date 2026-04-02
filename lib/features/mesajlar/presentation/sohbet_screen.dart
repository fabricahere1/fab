import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/mesaj_provider.dart';
import '../data/mesaj_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
 
class SohbetScreen extends ConsumerStatefulWidget {
  final String karsiKullaniciId;
  final String karsiKullaniciAd;
  final String ilanId;
  final String ilanBaslik;
  final String? ilanResimUrl;
  final String? sohbetId;
 
  const SohbetScreen({
    super.key,
    required this.karsiKullaniciId,
    required this.karsiKullaniciAd,
    required this.ilanId,
    required this.ilanBaslik,
    this.ilanResimUrl,
    this.sohbetId,
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
                      errorWidget: (_, __, ___) => _IlanResimPlaceholder(),
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
                              final zaman = (mesaj['zaman'] as Timestamp?)?.toDate();
                              final zamanYazi = zaman != null
                                  ? '${zaman.hour.toString().padLeft(2, '0')}:${zaman.minute.toString().padLeft(2, '0')}'
                                  : '';
                              final metin = mesaj['metin'] ?? '';
                              final okundu = mesaj['okundu'] as bool? ?? false;
 
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
          karsiAd: widget.karsiKullaniciAd,
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