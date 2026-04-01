import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
 
/// Kullanıcı avatarı.
/// Fotoğraf varsa gösterir, yoksa ismin baş harfini renkli arka planla gösterir.
class AvatarWidget extends StatelessWidget {
  final String isim;
  final String? fotoUrl;
  final double radius;
  final double? fontSize;
 
  const AvatarWidget({
    super.key,
    required this.isim,
    this.fotoUrl,
    required this.radius,
    this.fontSize,
  });
 
  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.avatarBg,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: fotoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            errorWidget: (_, __, ___) => _HarfAvatar(
              isim: isim,
              radius: radius,
              fontSize: fontSize,
            ),
          ),
        ),
      );
    }
    return _HarfAvatar(isim: isim, radius: radius, fontSize: fontSize);
  }
}
 
class _HarfAvatar extends StatelessWidget {
  final String isim;
  final double radius;
  final double? fontSize;
 
  const _HarfAvatar({
    required this.isim,
    required this.radius,
    this.fontSize,
  });
 
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.avatarColor(isim),
      child: Text(
        isim.isNotEmpty ? isim[0].toUpperCase() : '?',
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: fontSize ?? radius * 0.7,
        ),
      ),
    );
  }
}
