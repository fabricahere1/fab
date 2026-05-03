import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/islem_durumu.dart';
import '../data/mesaj_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../degerlendirme/data/degerlendirme_repository.dart';

// ── Providers ─────────────────────────────────────────────

final islemDurumuProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, sohbetId) {
  return ref.read(mesajRepositoryProvider).islemDurumuStream(sohbetId);
});

final _ilanSahibiIdProvider =
    StreamProvider.family<String, String>((ref, sohbetId) {
  return ref.read(mesajRepositoryProvider).ilanSahibiIdStream(sohbetId);
});

final _ilanTipProvider =
    StreamProvider.family<String, String>((ref, sohbetId) {
  return ref.read(mesajRepositoryProvider).ilanTipStream(sohbetId);
});

final _sohbetKullanicilarProvider =
    StreamProvider.family<List<String>, String>((ref, sohbetId) {
  return ref.read(mesajRepositoryProvider).sohbetKullanicilarStream(sohbetId);
});

// ── Panel ─────────────────────────────────────────────────

class IslemDurumuPanel extends ConsumerWidget {
  final String sohbetId;
  const IslemDurumuPanel({super.key, required this.sohbetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benimUid     = ref.watch(currentUserProvider)?.uid ?? '';
    final durumlari    = ref.watch(islemDurumuProvider(sohbetId)).value ?? {};
    final ilanSahibiId = ref.watch(_ilanSahibiIdProvider(sohbetId)).value ?? '';
    final kullanicilar = ref.watch(_sohbetKullanicilarProvider(sohbetId)).value ?? [];
    final ilanTip      = ref.watch(_ilanTipProvider(sohbetId)).value ?? 'istek';
    final adimlar      = IlanTipiAdimlar.forTip(ilanTip);
    final benimIlanSahibi = benimUid == ilanSahibiId;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 20,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_horiz_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'İşlem Durumu',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: adimlar.map((durum) {
                    final tamamlandi = durumlari[durum.firestoreKey] == true;
                    final idx = adimlar.indexOf(durum);
                    final oncekiTamamlandi = idx == 0 ||
                        durumlari[adimlar[idx - 1].firestoreKey] == true;
                    final aktif = !tamamlandi && oncekiTamamlandi;
                    final iletisimAdimi = durum == IslemDurumu.iletisimBasladi;
                    bool isaretleyebilir = false;
                    if (aktif && !iletisimAdimi) {
                      final kim = durum.ilanSahibiMiForTip(ilanTip);
                      isaretleyebilir =
                          kim == null ? true : kim == benimIlanSahibi;
                    }
                    return _AdimSatiri(
                      durum: durum,
                      tamamlandi: tamamlandi,
                      aktif: aktif,
                      isaretleyebilir: isaretleyebilir,
                      sonMu: idx == adimlar.length - 1,
                      ilanTip: ilanTip,
                      onTap: isaretleyebilir
                          ? () => _adimIsaretle(ref, durum)
                          : null,
                    );
                  }).toList(),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Teslim tamamlandığında değerlendirme ekranı açılır.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textHint,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _adimIsaretle(WidgetRef ref, IslemDurumu durum) async {
    if (durum == IslemDurumu.teslimAlindi) {
      await ref
          .read(mesajRepositoryProvider)
          .teslimTamamla(sohbetId: sohbetId);
    } else {
      await ref.read(mesajRepositoryProvider).islemDurumuGuncelle(
            sohbetId: sohbetId,
            durum: durum.firestoreKey,
          );
    }
  }
}

// ── Adım Satırı ───────────────────────────────────────────

class _AdimSatiri extends StatelessWidget {
  final IslemDurumu durum;
  final bool tamamlandi;
  final bool aktif;
  final bool isaretleyebilir;
  final bool sonMu;
  final String ilanTip;
  final VoidCallback? onTap;

  const _AdimSatiri({
    required this.durum,
    required this.tamamlandi,
    required this.aktif,
    required this.isaretleyebilir,
    required this.sonMu,
    required this.ilanTip,
    this.onTap,
  });

  IconData get _ikon => durum.ikon;
  String get _kimYapar => durum.kimYaparForTip(ilanTip);

  @override
  Widget build(BuildContext context) {
    final Color renk = tamamlandi
        ? const Color(0xFF43A047)
        : aktif
            ? AppColors.primary
            : AppColors.textHint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: renk.withValues(alpha: tamamlandi ? 0.12 : 0.08),
                    shape: BoxShape.circle,
                    border: aktif && !tamamlandi
                        ? Border.all(color: renk, width: 2)
                        : null,
                  ),
                  child: Icon(_ikon, color: renk, size: 20),
                ),
                if (!sonMu)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: tamamlandi
                          ? const Color(0xFF43A047).withValues(alpha: 0.3)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(left: 4, bottom: sonMu ? 0 : 20, top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          durum.etiket,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: tamamlandi || aktif
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: tamamlandi || aktif
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                        Text(
                          _kimYapar,
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  if (tamamlandi)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF43A047), size: 22)
                  else if (isaretleyebilir)
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('İşaretle',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.divider, width: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sağ kenar tetikleyicisi ───────────────────────────────

class IslemDurumuTetikleyici extends ConsumerStatefulWidget {
  final String sohbetId;
  const IslemDurumuTetikleyici({super.key, required this.sohbetId});

  @override
  ConsumerState<IslemDurumuTetikleyici> createState() =>
      _IslemDurumuTetikleyiciState();
}

class _IslemDurumuTetikleyiciState
    extends ConsumerState<IslemDurumuTetikleyici>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleX;
  late Animation<double> _scaleY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleX = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.6)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 70),
    ]).animate(_ctrl);
    _scaleY = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 70),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() async {
    _ctrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        barrierDismissible: true,
        pageBuilder: (ctx, anim, _) => Align(
          alignment: Alignment.centerRight,
          child: IslemDurumuPanel(sohbetId: widget.sohbetId),
        ),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durumlari = ref.watch(islemDurumuProvider(widget.sohbetId)).value ?? {};
    final tamamlanan = IslemDurumu.values
        .where((d) => durumlari[d.firestoreKey] == true)
        .length;
    final toplam = IslemDurumu.values.length;

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Transform(
          alignment: Alignment.centerRight,
          transform: Matrix4.identity()
            ..scale(_scaleX.value, _scaleY.value, 1.0),
          child: Container(
            width: 28,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF81C784),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(48),
                bottomLeft: Radius.circular(48),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF81C784).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chevron_left_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(
                  '$tamamlanan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Container(
                  width: 12,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.6),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                Text(
                  '$toplam',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}