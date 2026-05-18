import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class NedenIsteBar extends StatefulWidget {
  const NedenIsteBar({super.key});

  @override
  State<NedenIsteBar> createState() => _NedenIsteBarState();
}

class _NedenIsteBarState extends State<NedenIsteBar>
    with SingleTickerProviderStateMixin {
  late final ScrollController _ctrl;
  late final Ticker _ticker;
  double _offset = 0;
  double _contentWidth = 0;

  static const _hiz = 0.6;
  static const _maddeler = [
    'Güvenli alışveriş',
    'Onaylı taşıyıcılar',
    'Uygun fiyat',
    'Kolay iade',
    'Hızlı teslimat',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    final reduceMotion = SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    _ticker = createTicker(_onTick);
    if (!reduceMotion) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!_ctrl.hasClients) return;
    if (_contentWidth == 0) return;
    _offset += _hiz;
    if (_offset >= _contentWidth) _offset = 0;
    _ctrl.jumpTo(_offset);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFC8E6C9),
      height: 28,
      child: LayoutBuilder(builder: (context, constraints) {
        _contentWidth = _maddeler.length * 120.0 + _maddeler.length * 16.0;
        return SingleChildScrollView(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var r = 0; r < 3; r++) ...[
                for (final m in _maddeler) ...[
                  const SizedBox(width: 16),
                  _NedenItem(metin: m),
                  const _NedenAyrac(),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _NedenItem extends StatelessWidget {
  final String metin;
  const _NedenItem({required this.metin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 12, color: Color(0xFF388E3C)),
        const SizedBox(width: 4),
        Text(metin,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20))),
      ],
    );
  }
}

class _NedenAyrac extends StatelessWidget {
  const _NedenAyrac();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
          color: Color(0xFF4CAF50), shape: BoxShape.circle),
    );
  }
}
