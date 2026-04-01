import 'package:flutter/material.dart';
 
/// Uygulamanın tüm renk sabitleri tek yerden yönetilir.
/// Renk değiştirmek için sadece buraya bakmak yeterli.
class AppColors {
  AppColors._();
 
  // ── Ana Renkler ───────────────────────────────────────
  static const primary     = Color(0xFF3C3C3C);
  static const accent      = Color(0xFF5C5C5C);
  static const red         = Color(0xFFE53935);
  static const orange      = Color(0xFFFF6B35);
 
  // ── Arka Plan ─────────────────────────────────────────
  static const white       = Color(0xFFFFFFFF);
  static const surface     = Color(0xFFF5F5F5);
  static const surfaceAlt  = Color(0xFFEEEEEE);
 
  // ── Kenarlık & Ayraç ──────────────────────────────────
  static const divider     = Color(0xFFE0E0E0);
 
  // ── Metin ─────────────────────────────────────────────
  static const textPrimary   = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint      = Color(0xFFBDBDBD);
 
  // ── Chip & Avatar ─────────────────────────────────────
  static const avatarBg    = Color(0xFFEEEEEE);
  static const chipBg      = Color(0xFFE8E8E8);
 
  // ── Özel ──────────────────────────────────────────────
  static const yellow      = Color(0xFFFFB300);
  static const redLight    = Color(0xFFFFEBEE);
  static const green       = Color(0xFF2E7D32);
  static const greenLight  = Color(0xFFE8F5E9);
 
  // ── Avatar Renkleri ───────────────────────────────────
  static const List<Color> avatarColors = [
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFFE67E22),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];
 
  /// İsme göre sabit bir avatar rengi döndürür.
  static Color avatarColor(String isim) {
    if (isim.isEmpty) return avatarColors[0];
    return avatarColors[isim.codeUnitAt(0) % avatarColors.length];
  }
}