import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/islem_durumu.dart';
import '../providers/mesaj_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';

// ── Panel ─────────────────────────────────────────────────

class IslemDurumuPanel extends ConsumerWidget {
  final String sohbetId;
  final String karsiKullaniciAd;

  const IslemDurumuPanel({
    super.key,
    required this.sohbetId,
    required this.karsiKullaniciAd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benimUid     = ref.watch(currentUserProvider)?.uid ?? '';
    final durumlari    = ref.watch(islemDurumuProvider(sohbetId)).value ?? {};
    final ilanSahibiId = ref.watch(sohbetIlanSahibiIdProvider(sohbetId)).value ?? '';
    final kullanicilar = ref.watch(sohbetKullanicilarProvider(sohbetId)).value ?? [];
    final ilanTip      = ref.watch(sohbetIlanTipProvider(sohbetId)).value ?? 'istek';
    final ilanBaslik   = ref.watch(sohbetIlanBaslikProvider(sohbetId)).value ?? '';

    // iletisimBasladi otomatik tamamlanıyor — listeden ve sayaçtan çıkar
    final tumAdimlar   = IlanTipiAdimlar.forTip(ilanTip);
    final adimlar      = tumAdimlar
        .where((a) => a != IslemDurumu.iletisimBasladi)
        .toList();
    final benimIlanSahibi = benimUid == ilanSahibiId;

    final karsiUid = kullanicilar.firstWhere(
      (id) => id != benimUid,
      orElse: () => '',
    );

    // Tamamlanan adım sayısı
    int tamamlananSayi = 0;
    for (final adim in adimlar) {
      if (_adimTamamlandiMi(adim, durumlari, benimUid, karsiUid)) {
        tamamlananSayi++;
      }
    }

    final ilerleme = adimlar.isEmpty ? 0.0 : tamamlananSayi / adimlar.length;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Üst gradient kart ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE24B4A), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              karsiKullaniciAd,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (ilanBaslik.isNotEmpty)
                              Text(
                                ilanBaslik,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$tamamlananSayi/${adimlar.length}',
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Text(
                            'adım',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── İnce ilerleme çubuğu ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ilerleme,
                    minHeight: 3,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE24B4A)),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Adım listesi ──────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: adimlar.map((durum) {
                    final idx = adimlar.indexOf(durum);
                    final oncekiTamamlandi = idx == 0 ||
                        _adimTamamlandiMi(
                            adimlar[idx - 1], durumlari, benimUid, karsiUid);

                    if (durum.ikiTarafliMi) {
                      final benimOnayim =
                          durumlari['anlasildi_$benimUid'] == true;
                      final karsiOnayi = karsiUid.isNotEmpty &&
                          durumlari['anlasildi_$karsiUid'] == true;
                      final tamTamamlandi = benimOnayim && karsiOnayi;

                      return _AnlasildiSatiri(
                        tamamlandi: tamTamamlandi,
                        benimOnayim: benimOnayim,
                        karsiOnayi: karsiOnayi,
                        oncekiTamamlandi: oncekiTamamlandi,
                        karsiKullaniciAd: karsiKullaniciAd,
                        sonMu: idx == adimlar.length - 1,
                        // Artık VoidCallback değil, Future<void> Function() —
                        // butonun kendisi bu Future'ı await edip yükleniyor/
                        // hata durumunu yönetiyor.
                        onTap: (!benimOnayim && oncekiTamamlandi)
                            ? () => _anlasildiIsaretle(ref, benimUid)
                            : null,
                      );
                    }

                    final tamamlandi =
                        _adimTamamlandiMi(durum, durumlari, benimUid, karsiUid);
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

              // ── Alt bilgi ─────────────────────────────
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

  bool _adimTamamlandiMi(
    IslemDurumu durum,
    Map<String, dynamic> durumlari,
    String benimUid,
    String karsiUid,
  ) {
    if (durum.ikiTarafliMi) {
      return durumlari['anlasildi_$benimUid'] == true &&
          (karsiUid.isEmpty || durumlari['anlasildi_$karsiUid'] == true);
    }
    return durumlari[durum.firestoreKey] == true;
  }

  // Artık Future<void> döndürüyor ve çağıran widget'a rethrow ediyor —
  // widget bu hatayı yakalayıp kullanıcıya snackbar ile gösteriyor.
  Future<void> _anlasildiIsaretle(WidgetRef ref, String benimUid) async {
    await ref.read(islemDurumuIslemleriProvider(sohbetId).notifier)
        .anlasildiIsaretle(benimUid);
  }

  Future<void> _adimIsaretle(WidgetRef ref, IslemDurumu durum) async {
    if (durum == IslemDurumu.teslimAlindi) {
      await ref.read(islemDurumuIslemleriProvider(sohbetId).notifier)
          .teslimTamamla();
    } else {
      await ref.read(islemDurumuIslemleriProvider(sohbetId).notifier)
          .guncelle(durum.firestoreKey);
    }
  }
}

// ── Normal Adım Satırı ────────────────────────────────────
//
// StatelessWidget'tan StatefulWidget'a çevrildi — buton artık kendi
// yerel "gönderiliyor" durumunu tutuyor. Neden gerekli: eskiden bu
// buton, Firestore stream'i güncelleyip UI'ı yeniden çizene kadar HİÇBİR
// görsel değişiklik göstermiyordu (ne devre dışı kalma ne "yükleniyor"
// ifadesi) — kullanıcı "çalışmadı" sanıp 2-3 kez basıyordu. Şimdi:
// tıklanır tıklanmaz buton devre dışı kalıp "..." gösteriyor, hata
// olursa snackbar ile bildirilip buton tekrar aktif oluyor.

class _AdimSatiri extends StatefulWidget {
  final IslemDurumu durum;
  final bool tamamlandi;
  final bool aktif;
  final bool isaretleyebilir;
  final bool sonMu;
  final String ilanTip;
  final Future<void> Function()? onTap;

  const _AdimSatiri({
    required this.durum,
    required this.tamamlandi,
    required this.aktif,
    required this.isaretleyebilir,
    required this.sonMu,
    required this.ilanTip,
    this.onTap,
  });

  @override
  State<_AdimSatiri> createState() => _AdimSatiriState();
}

class _AdimSatiriState extends State<_AdimSatiri> {
  bool _gonderiliyor = false;

  Future<void> _handleTap() async {
    if (widget.onTap == null || _gonderiliyor) return;
    setState(() => _gonderiliyor = true);
    try {
      await widget.onTap!();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşaretlenemedi. Lütfen tekrar dene.'),
            backgroundColor: Color(0xFFE24B4A),
          ),
        );
      }
    } finally {
      // Başarılı olduğunda zaten stream üzerinden 'tamamlandi' true
      // olup bu widget tamamen farklı bir dala (check ikonu) düşecek —
      // yine de yerel bayrağı sıfırlamak zarar vermez ve hata durumunda
      // butonu tekrar tıklanabilir yapmak için ZORUNLU.
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final durum = widget.durum;
    final tamamlandi = widget.tamamlandi;
    final aktif = widget.aktif;
    final isaretleyebilir = widget.isaretleyebilir;
    final ilanTip = widget.ilanTip;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        decoration: aktif
            ? BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        padding: aktif
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            // İkon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tamamlandi
                    ? const Color(0xFFE8F5E9)
                    : aktif
                        ? const Color(0xFFFFEBEB)
                        : const Color(0xFFF5F5F5),
              ),
              child: tamamlandi
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Color(0xFF4CAF50))
                  : aktif
                      ? Text(
                          _adimEmoji(durum),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, height: 2.2),
                        )
                      : Icon(durum.ikon,
                          size: 16, color: const Color(0xFFCCCCCC)),
            ),
            const SizedBox(width: 12),
            // Metin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    durum.etiket,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                      color: tamamlandi
                          ? const Color(0xFFBBBBBB)
                          : aktif
                              ? const Color(0xFFE24B4A)
                              : const Color(0xFFCCCCCC),
                    ),
                  ),
                  if (aktif || tamamlandi)
                    Text(
                      durum.kimYaparForTip(ilanTip),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: aktif
                            ? const Color(0xFFE24B4A).withValues(alpha: 0.6)
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                ],
              ),
            ),
            // Sağ taraf
            if (tamamlandi)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 20)
            else if (isaretleyebilir)
              GestureDetector(
                onTap: _gonderiliyor ? null : _handleTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _gonderiliyor
                        ? const Color(0xFFE24B4A).withValues(alpha: 0.5)
                        : const Color(0xFFE24B4A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _gonderiliyor
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('İşaretle',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                ),
              )
            else if (!aktif)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFEEEEEE), width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Anlaşıldı Satırı ─────────────────────────────────────

class _AnlasildiSatiri extends StatefulWidget {
  final bool tamamlandi;
  final bool benimOnayim;
  final bool karsiOnayi;
  final bool oncekiTamamlandi;
  final String karsiKullaniciAd;
  final bool sonMu;
  final Future<void> Function()? onTap;

  const _AnlasildiSatiri({
    required this.tamamlandi,
    required this.benimOnayim,
    required this.karsiOnayi,
    required this.oncekiTamamlandi,
    required this.karsiKullaniciAd,
    required this.sonMu,
    this.onTap,
  });

  @override
  State<_AnlasildiSatiri> createState() => _AnlasildiSatiriState();
}

class _AnlasildiSatiriState extends State<_AnlasildiSatiri>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  // Yerel "gönderiliyor" bayrağı — az önce _AdimSatiri'de anlattığımız
  // aynı gerekçeyle: tıklamadan Firestore stream'in geri dönüşüne kadar
  // geçen sürede kullanıcıya "işlendi" hissi vermek + hata varsa haber
  // vermek için.
  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_AnlasildiSatiri old) {
    super.didUpdateWidget(old);
    if (old.benimOnayim != widget.benimOnayim ||
        old.tamamlandi != widget.tamamlandi) {
      _syncAnimation();
      // Gerçek veri geldi (benimOnayim değişti) — yerel yükleniyor
      // bayrağının artık hiçbir anlamı yok, kapatalım.
      if (_gonderiliyor) {
        _gonderiliyor = false;
      }
    }
  }

  void _syncAnimation() {
    if (widget.tamamlandi) {
      _ctrl.animateTo(1.0);
    } else if (widget.benimOnayim) {
      _ctrl.animateTo(0.5);
    } else {
      _ctrl.animateTo(0.0);
    }
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null || _gonderiliyor) return;
    setState(() => _gonderiliyor = true);
    try {
      await widget.onTap!();
      // Not: burada _gonderiliyor'u false yapmıyoruz — başarılı olduysa
      // stream birazdan benimOnayim'i true yapıp didUpdateWidget'ı
      // tetikleyecek, orada zaten sıfırlanıyor. Erken sıfırlarsak,
      // stream henüz gelmeden buton kısacık yeniden aktif görünüp
      // ikinci bir tıklamaya izin verebilir.
    } catch (e) {
      if (mounted) {
        setState(() => _gonderiliyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onaylanamadı. Lütfen tekrar dene.'),
            backgroundColor: Color(0xFFE24B4A),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _altYazi {
    if (widget.tamamlandi) return 'İki taraf da onayladı';
    if (widget.benimOnayim && !widget.karsiOnayi) {
      return '${widget.karsiKullaniciAd}\'ın onayı bekleniyor';
    }
    if (!widget.benimOnayim && widget.karsiOnayi) {
      return 'Senin onayın bekleniyor';
    }
    return 'İki tarafın onayı gerekli';
  }

  String get _baslik {
    if (widget.tamamlandi) return 'Anlaşıldı';
    if (widget.benimOnayim || widget.karsiOnayi) return 'Anlaşma önerildi';
    return 'Anlaşma öner';
  }

  @override
  Widget build(BuildContext context) {
    final aktif = widget.oncekiTamamlandi && !widget.tamamlandi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        decoration: aktif
            ? BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        padding: aktif
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.tamamlandi
                        ? const Color(0xFFE8F5E9)
                        : aktif
                            ? const Color(0xFFFFEBEB)
                            : const Color(0xFFF5F5F5),
                  ),
                  child: widget.tamamlandi
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Color(0xFF4CAF50))
                      : aktif
                          ? const Text('🤝',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, height: 2.2))
                          : const Icon(Icons.handshake_outlined,
                              size: 16, color: Color(0xFFCCCCCC)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _baslik,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight:
                              aktif ? FontWeight.w700 : FontWeight.w500,
                          color: widget.tamamlandi
                              ? const Color(0xFFBBBBBB)
                              : aktif
                                  ? const Color(0xFFE24B4A)
                                  : const Color(0xFFCCCCCC),
                        ),
                      ),
                      Text(
                        _altYazi,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: aktif
                              ? const Color(0xFFE24B4A).withValues(alpha: 0.6)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.tamamlandi)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50), size: 20),
              ],
            ),

            // Animasyonlu onay butonu
            if (aktif) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _gonderiliyor ? null : _handleTap,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (_, _) {
                    return Container(
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE24B4A).withValues(alpha: 0.3),
                            width: 1),
                        color: const Color(0xFFFFF5F5),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: _progress.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE24B4A)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          Center(
                            child: _gonderiliyor
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(0xFFE24B4A)),
                                    ),
                                  )
                                : Text(
                                    widget.benimOnayim
                                        ? '✓ Onayladın'
                                        : 'Onayla',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE24B4A),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            if (widget.tamamlandi) ...[
              const SizedBox(height: 6),
              Container(
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFE8F5E9),
                ),
                child: Center(
                  child: Text(
                    '✓ Anlaşıldı',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sağ kenar tetikleyicisi ───────────────────────────────

class IslemDurumuTetikleyici extends ConsumerStatefulWidget {
  final String sohbetId;
  final String karsiKullaniciAd;
  final String ilanTip;

  const IslemDurumuTetikleyici({
    super.key,
    required this.sohbetId,
    required this.karsiKullaniciAd,
    this.ilanTip = 'istek',
  });

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
          child: IslemDurumuPanel(
            sohbetId: widget.sohbetId,
            karsiKullaniciAd: widget.karsiKullaniciAd,
          ),
        ),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durumlari =
        ref.watch(islemDurumuProvider(widget.sohbetId)).value ?? {};
    final tumAdimlar = IlanTipiAdimlar.forTip(widget.ilanTip);
    final adimlar    = tumAdimlar
        .where((a) => a != IslemDurumu.iletisimBasladi)
        .toList();
    final tamamlanan = adimlar.where((d) {
      if (d.ikiTarafliMi) {
        final onaylar = durumlari.entries
            .where((e) => e.key.startsWith('anlasildi_') && e.value == true)
            .length;
        return onaylar >= 2;
      }
      return durumlari[d.firestoreKey] == true;
    }).length;
    final toplam = adimlar.length;

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform(
          alignment: Alignment.centerRight,
          transform: Matrix4.identity()
            ..scaleByDouble(_scaleX.value, _scaleY.value, 1.0, 1.0),
          child: child,
        ),
        child: Container(
          width: 28,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFFE24B4A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(48),
              bottomLeft: Radius.circular(48),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE24B4A).withValues(alpha: 0.4),
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
                color: Colors.white38,
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
              Text(
                '$toplam',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _adimEmoji(IslemDurumu adim) {
  switch (adim) {
    case IslemDurumu.iletisimBasladi: return '💬';
    case IslemDurumu.anlasildi:       return '🤝';
    case IslemDurumu.siparisVerildi:  return '🛒';
    case IslemDurumu.urunAlindi:      return '🛍️';
    case IslemDurumu.yolaCikti:       return '🚚';
    case IslemDurumu.teslimEdildi:    return '📦';
    case IslemDurumu.teslimAlindi:    return '✅';
  }
}