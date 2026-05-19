// lib/shared/utils/app_snackbar.dart
//
// Kullanım:
//   AppSnackBar.basari(context, 'İlanınız gönderildi');
//   AppSnackBar.hata(context, 'Bir hata oluştu');
//   AppSnackBar.bilgi(context, 'Sohbet gizlendi');

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackBar {
  AppSnackBar._();

  // ── Başarı — B: neredeyse beyaz, hafif amber (0.72) ──────────────────────
  static const _basariBg      = Color(0xB8FFFCF7); // rgba(255,252,247, 0.72)
  static const _basariBorder  = Color(0x40EF9F27); // rgba(239,159,39, 0.25)
  static const _basariIkon    = Color(0xA6BA7517); // rgba(186,117,23, 0.65)
  static const _basariMetin   = Color(0xFF633806);
  static const _basariAlt     = Color(0xFF8B5010);

  // ── Hata ─────────────────────────────────────────────────────────────────
  static const _hataBg        = Color(0xB8FFF5F5);
  static const _hataBorder    = Color(0x40E53935);
  static const _hataIkon      = Color(0xA6E53935);
  static const _hataMetin     = Color(0xFF7F0000);

  // ── Bilgi ─────────────────────────────────────────────────────────────────
  static const _bilgiBg       = Color(0xB8F8F8F8);
  static const _bilgiBorder   = Color(0x33757575);
  static const _bilgiIkon     = Color(0xA6616161);
  static const _bilgiMetin    = Color(0xFF212121);

  // ── Başarı ────────────────────────────────────────────────────────────────
  static void basari(
    BuildContext context,
    String mesaj, {
    String? altMesaj,
    Duration sure = const Duration(seconds: 3),
  }) {
    _goster(
      context,
      mesaj:     mesaj,
      altMesaj:  altMesaj,
      bg:        _basariBg,
      border:    _basariBorder,
      ikonBg:    _basariIkon,
      ikonRenk:  Colors.white,
      metinRenk: _basariMetin,
      altRenk:   _basariAlt,
      ikon:      Icons.check_rounded,
      sure:      sure,
    );
  }

  // ── Hata ─────────────────────────────────────────────────────────────────
  static void hata(
    BuildContext context,
    String mesaj, {
    Duration sure = const Duration(seconds: 3),
  }) {
    _goster(
      context,
      mesaj:     mesaj,
      bg:        _hataBg,
      border:    _hataBorder,
      ikonBg:    _hataIkon,
      ikonRenk:  Colors.white,
      metinRenk: _hataMetin,
      altRenk:   _hataMetin,
      ikon:      Icons.error_outline_rounded,
      sure:      sure,
    );
  }

  // ── Bilgi ─────────────────────────────────────────────────────────────────
  static void bilgi(
    BuildContext context,
    String mesaj, {
    Duration sure = const Duration(seconds: 3),
  }) {
    _goster(
      context,
      mesaj:     mesaj,
      bg:        _bilgiBg,
      border:    _bilgiBorder,
      ikonBg:    _bilgiIkon,
      ikonRenk:  Colors.white,
      metinRenk: _bilgiMetin,
      altRenk:   _bilgiMetin,
      ikon:      Icons.info_outline_rounded,
      sure:      sure,
    );
  }

  // ── İç yardımcı ──────────────────────────────────────────────────────────
  static void _goster(
    BuildContext context, {
    required String mesaj,
    String? altMesaj,
    required Color bg,
    required Color border,
    required Color ikonBg,
    required Color ikonRenk,
    required Color metinRenk,
    required Color altRenk,
    required IconData ikon,
    required Duration sure,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:        SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation:       0,
          duration:        sure,
          margin:          const EdgeInsets.fromLTRB(12, 0, 12, 16),
          padding:         EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color:        bg,
              border:       Border.all(color: border, width: 0.5),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset:     const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width:  34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ikonBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ikon, color: ikonRenk, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mesaj,
                        style: GoogleFonts.inter(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      metinRenk,
                          height:     1.3,
                        ),
                      ),
                      if (altMesaj != null && altMesaj.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          altMesaj,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:    altRenk,
                            height:   1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}