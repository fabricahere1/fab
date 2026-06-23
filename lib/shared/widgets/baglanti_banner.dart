// lib/shared/widgets/baglanti_banner.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baglanti_banner.g.dart';

@riverpod
Stream<bool> baglantiDurumu(Ref ref) async* {
  final ilk = await Connectivity().checkConnectivity();
  yield ilk.any((s) => s != ConnectivityResult.none);

  yield* Connectivity().onConnectivityChanged
      .map((sonuclar) => sonuclar.any((s) => s != ConnectivityResult.none));
}

class BaglantiSarmalayici extends ConsumerWidget {
  final Widget child;
  const BaglantiSarmalayici({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bagliAsync = ref.watch(baglantiDurumuProvider);
    final bagli = bagliAsync.value ?? true;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          top: bagli ? -(topPadding + 60) : topPadding + 8,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.wifi_off_rounded,
                        size: 16, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Bağlantı Yok',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          )),
                      Text('İnternet erişimi kesildi',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF999999),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}