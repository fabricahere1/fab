import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class ProfilStilleri {
  ProfilStilleri._();

  // ── İsim / başlık ─────────────────────────────────────────────────────────
  static TextStyle get isim => GoogleFonts.manrope(
      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // ── İkincil bilgi (e-posta, kısa açıklama) ───────────────────────────────
  static TextStyle get altBilgi =>
      GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary);

  // ── Küçük detay satırı (şehir, telefon, puan yazısı) ─────────────────────
  static TextStyle get detaySatiri =>
      GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary);

  static TextStyle get detaySatiriHint =>
      GoogleFonts.manrope(fontSize: 12, color: AppColors.textHint);

  // ── Bölüm başlığı (Güven Skoru, Rozetler, İlanları…) ─────────────────────
  static TextStyle get bolumBaslik => GoogleFonts.manrope(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // ── Bölüm üst başlık (HESABIM, DİĞER gibi uppercase etiketler) ───────────
  static TextStyle get bolumUstBaslik => GoogleFonts.manrope(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 1.0);

  // ── Güven skoru değeri (kırmızı) ─────────────────────────────────────────
  static TextStyle get guvenSkoruDeger => GoogleFonts.manrope(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red);

  // ── Rozet etiketi ─────────────────────────────────────────────────────────
  static TextStyle get rozet => GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF633806));

  // ── Puan satırı (underline) ───────────────────────────────────────────────
  static TextStyle get puanYazi => GoogleFonts.manrope(
      fontSize: 11,
      color: AppColors.textSecondary,
      decoration: TextDecoration.underline);

  // ── İstatistik sayıları — dmSans bilinçli kontrast ────────────────────────
  static TextStyle get istatistikSayi => GoogleFonts.dmSans(
      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  // ── İstatistik etiketi (Takipçi, Takip, Değerlendirme) ───────────────────
  static TextStyle get istatistikEtiket =>
      GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary);
}
