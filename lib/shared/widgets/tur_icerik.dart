// lib/shared/widgets/tur_icerik.dart
//
// Coach mark turlarında (ana sayfa turu, işlem paneli mini-turu) ortak
// kullanılan içerik: büyük metin + dolu beyaz daire içinde ok/check
// butonu. Tekrar yazılmasın diye tek yerde tutuluyor.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

TargetContent turIcerik(
  String metin, {
  ContentAlign align = ContentAlign.bottom,
  bool sonAdim = false,
}) =>
    TargetContent(
      align: align,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metin,
            style: GoogleFonts.dmSans(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => controller.next(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    sonAdim ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

const turSkipWidget = Text(
  'Geç',
  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
);
