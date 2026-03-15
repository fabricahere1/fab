import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GColors {
  static const primary = Color(0xFF3C3C3C);
  static const accent = Color(0xFF5C5C5C);
  static const red = Color(0xFFE53935);
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const surfaceAlt = Color(0xFFEEEEEE);
  static const divider = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);
  static const avatarBg = Color(0xFFEEEEEE);
  static const chipBg = Color(0xFFE8E8E8);
  static const blue = primary;
  static const green = accent;
  static const yellow = Color(0xFFFFB300);
  static const blueLight = avatarBg;
  static const greenLight = chipBg;
  static const redLight = Color(0xFFFFEBEE);
  static const lightOrange = Color(0xFFFF8A65);
}

String gunFarki(DateTime tarih) {
  final bugun = DateTime.now();
  final fark = tarih.difference(DateTime(bugun.year, bugun.month, bugun.day)).inDays;
  if (fark < 0) return 'GEÇMİŞ TARİH';
  if (fark == 0) return 'BUGÜN GELİYOR';
  if (fark == 1) return 'YARIN GELİYOR';
  return '$fark GÜN SONRA GELİYOR';
}

Color tarihChipBgRenk(DateTime tarih) {
  final bugun = DateTime.now();
  final fark = tarih.difference(DateTime(bugun.year, bugun.month, bugun.day)).inDays;
  if (fark < 0) return const Color(0xFFEEEEEE);
  return const Color(0xFFE8F5E9);
}

Color tarihChipTextRenk(DateTime tarih) {
  final bugun = DateTime.now();
  final fark = tarih.difference(DateTime(bugun.year, bugun.month, bugun.day)).inDays;
  if (fark < 0) return const Color(0xFF9E9E9E);
  return const Color(0xFF2E7D32);
}

Color avatarRenk(String isim) {
  final renkler = [
    const Color(0xFFE53935),
    const Color(0xFF8E24AA),
    const Color(0xFF1E88E5),
    const Color(0xFF00897B),
    const Color(0xFF43A047),
    const Color(0xFFE67E22),
    const Color(0xFF6D4C41),
    const Color(0xFF546E7A),
  ];
  final index = isim.codeUnitAt(0) % renkler.length;
  return renkler[index];
}

Widget avatarWidget({
  required String isim,
  String? fotoUrl,
  required double radius,
  double? fontSize,
}) {
  if (fotoUrl != null && fotoUrl.isNotEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(fotoUrl),
      onBackgroundImageError: (_, __) {},
    );
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: avatarRenk(isim),
    child: Text(
      isim[0].toUpperCase(),
      style: GoogleFonts.roboto(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: fontSize ?? radius * 0.7,
      ),
    ),
  );
}

class BosEkran extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  final String altMesaj;
  final Color renk;
  const BosEkran({
    super.key,
    required this.icon,
    required this.mesaj,
    required this.altMesaj,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: GColors.divider),
          const SizedBox(height: 16),
          Text(mesaj, style: GoogleFonts.roboto(color: GColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 4),
          Text(altMesaj, style: GoogleFonts.roboto(color: GColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }
}

class GirisGerekli extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  final VoidCallback onGirisYap;
  const GirisGerekli({
    super.key,
    required this.icon,
    required this.mesaj,
    required this.onGirisYap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: GColors.divider),
          const SizedBox(height: 16),
          Text(mesaj, style: GoogleFonts.roboto(color: GColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onGirisYap,
            style: ElevatedButton.styleFrom(
              backgroundColor: GColors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text('Giriş Yap',
                style: GoogleFonts.roboto(color: GColors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class GChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  const GChip({
    super.key,
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class DuzenleAlani extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType klavye;
  final int maxLines;
  final bool readonly;

  const DuzenleAlani({
    super.key,
    required this.label,
    required this.controller,
    this.klavye = TextInputType.text,
    this.maxLines = 1,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 12, fontWeight: FontWeight.w500, color: GColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: klavye,
          maxLines: maxLines,
          readOnly: readonly,
          style: GoogleFonts.roboto(fontSize: 14, color: GColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: GColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: GColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: GColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: GColors.blue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}