// lib/shared/widgets/tur_icerik.dart
//
// Coach mark turlarında (ana sayfa turu, işlem paneli mini-turu) ortak
// kullanılan içerik — Çekmece'deki (ikinciel) tanitim_turu_service.dart ile
// aynı yeşil neon spotlight stili: koyu zemin, neon çerçeve/glow, neon
// metin + ok/check butonu. Tekrar yazılmasın diye tek yerde tutuluyor.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

const turNeonYesil = Color(0xFF39FF14);

/// Hedefin çevresindeki spotlight çerçevesi — [home_screen.dart]'taki her
/// TargetFocus'a `radius: 12, borderSide: turNeonBorder` olarak eklenir.
const turNeonBorder = BorderSide(color: turNeonYesil, width: 3);

TargetContent turIcerik(
  String metin, {
  ContentAlign align = ContentAlign.bottom,
  bool sonAdim = false,
}) =>
    TargetContent(
      align: align,
      builder: (context, controller) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: turNeonYesil, width: 1.4),
          boxShadow: const [
            BoxShadow(color: turNeonYesil, blurRadius: 14, spreadRadius: -4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              metin,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: turNeonYesil,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => controller.next(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sonAdim ? 'Bitir' : 'İleri',
                          style: GoogleFonts.dmSans(
                            color: turNeonYesil,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          sonAdim ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          size: 18,
                          color: turNeonYesil,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

const turSkipWidget = Text(
  'Geç',
  style: TextStyle(color: turNeonYesil, fontWeight: FontWeight.w600),
);
