import 'package:flutter/material.dart';
 
/// Uygulamanın tüm renk sabitleri tek yerden yönetilir.
/// Renk değiştirmek için sadece buraya bakmak yeterli.
class AppColors {
  AppColors._();
 
  // ── Ana Renkler ───────────────────────────────────────
  static const primary     = Color(0xFF00C17C); // Dolap yeşili
  static const accent      = Color(0xFF00A86B); // Dolap yeşili koyu
  static const red         = Color(0xFFE53935);
  static const orange      = Color(0xFFFF6B35);
 
  // ── Arka Plan ─────────────────────────────────────────
  static const white       = Color(0xFFFFFFFF);
  static const surface     = Color(0xFFF7F5F2);
  static const surfaceAlt  = Color(0xFFEDE8E3);
 
  // ── Kenarlık & Ayraç ──────────────────────────────────
  static const divider     = Color(0xFFE8E3DE);
 
  // ── Metin ─────────────────────────────────────────────
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
  static const textHint      = Color(0xFFBBBBBB);
 
  // ── Chip & Avatar ─────────────────────────────────────
  static const avatarBg    = Color(0xFFEDE8E3);
  static const chipBg      = Color(0xFFEDE8E3);
 
  // ── Özel ──────────────────────────────────────────────
  static const yellow      = Color(0xFFFFB300);
  static const purple      = Color(0xFF7C3AED);
  static const redLight    = Color(0xFFFFEBEE);
  static const green       = Color(0xFF00C17C);
  static const greenLight  = Color(0xFFE6F9F3);
 
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