import 'package:flutter/material.dart';

/// Responsive layout yardımcısı.
/// Breakpoint'ler:
///   compact  : < 360px  (küçük telefon)
///   normal   : 360-413px (standart telefon) ← base değerler bunun için
///   large    : 414-599px (büyük telefon)
///   tablet   : >= 600px
class AppLayout {
  static bool isCompact(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width < 360;

  static bool isLarge(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= 414 && w < 600;
  }

  static bool isTablet(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).shortestSide >= 600;

  /// Font boyutu — base normal telefon için
  static double fs(BuildContext ctx, double base) {
    if (isCompact(ctx)) return base * 0.92;
    if (isLarge(ctx))   return base * 1.06;
    if (isTablet(ctx))  return base * 1.14;
    return base;
  }

  /// Padding/spacing — base normal telefon için
  static double pad(BuildContext ctx, double base) {
    if (isCompact(ctx)) return base * 0.85;
    if (isLarge(ctx))   return base * 1.10;
    if (isTablet(ctx))  return base * 1.40;
    return base;
  }

  /// İkon boyutu
  static double icon(BuildContext ctx, double base) {
    if (isCompact(ctx)) return base * 0.90;
    if (isLarge(ctx))   return base * 1.08;
    if (isTablet(ctx))  return base * 1.20;
    return base;
  }

  /// Avatar radius
  static double avatar(BuildContext ctx, double base) {
    if (isCompact(ctx)) return base * 0.88;
    if (isLarge(ctx))   return base * 1.08;
    if (isTablet(ctx))  return base * 1.25;
    return base;
  }

  /// Grid kolon sayısı
  static int gridCols(BuildContext ctx, {int phone = 2, int tablet = 3}) =>
      isTablet(ctx) ? tablet : phone;

  static double width(BuildContext ctx)  => MediaQuery.sizeOf(ctx).width;
  static double height(BuildContext ctx) => MediaQuery.sizeOf(ctx).height;
  static double topPad(BuildContext ctx) => MediaQuery.of(ctx).padding.top;
  static double botPad(BuildContext ctx) => MediaQuery.of(ctx).padding.bottom;
}