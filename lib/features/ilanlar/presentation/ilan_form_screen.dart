import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../data/ilan_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/cache/app_cache_manager.dart';

class IlanFormScreen extends ConsumerStatefulWidget {
  final String tip;
  final IlanModel? duzenlenecekIlan;

  const IlanFormScreen({
    super.key,
    required this.tip,
    this.duzenlenecekIlan,
  });

  @override
  ConsumerState<IlanFormScreen> createState() => _IlanFormScreenState();
}

class _IlanFormScreenState extends ConsumerState<IlanFormScreen>
    with SingleTickerProviderStateMixin {
  int _adim = 0;
  late AnimationController _animCtrl;
  late Animation<double> _sheetAnim;

  final _urunCtrl    = TextEditingController();
  final _neredenCtrl = TextEditingController();
  final _nereyeCtrl  = TextEditingController();
  final _notlarCtrl  = TextEditingController();

  String? _seciliAnaKey;
  String? _seciliAltKey;
  bool _neredenFarketmez = false;
  DateTime? _seciliTarih;
  final List<File> _yeniResimler   = [];
  List<String>     _mevcutResimler = [];
  final _picker = ImagePicker();

  // Her adımda sheet yüksekliği (ekranın yüzdesi)
  static const _sheetYukseklikleri = [0.45, 0.60, 0.78];

  bool get _istekMi        => widget.tip == IlanTip.istek;
  bool get _duzenlemeModuMu => widget.duzenlenecekIlan != null;

  String get _kayitKategoriKey {
    if (_seciliAltKey != null) return _seciliAltKey!;
    if (_seciliAnaKey != null) return _seciliAnaKey!;
    return 'diger';
  }

  String get _kategoriGorunumAdi {
    if (_seciliAnaKey == null) return '';
    final ana = kKategoriAgaci.firstWhere(
      (k) => k.key == _seciliAnaKey,
      orElse: () => AnaKategori(key: '', ad: '', emoji: ''),
    );
    if (_seciliAltKey != null) {
      final alt = ana.altlar.firstWhere(
        (a) => a.key == _seciliAltKey,
        orElse: () => AltKategori(key: '', ad: ''),
      );
      if (alt.key.isNotEmpty) return '${ana.emoji} ${ana.ad} › ${alt.ad}';
    }
    return '${ana.emoji} ${ana.ad}';
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _sheetAnim = Tween<double>(
      begin: _sheetYukseklikleri[0],
      end: _sheetYukseklikleri[0],
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutCubic));

    if (_duzenlemeModuMu) {
      final ilan = widget.duzenlenecekIlan!;
      _urunCtrl.text    = ilan.urun;
      _neredenCtrl.text = ilan.nereden == 'Farketmez' ? '' : ilan.nereden;
      _nereyeCtrl.text  = ilan.nereye;
      _notlarCtrl.text  = ilan.notlar;
      _neredenFarketmez = ilan.nereden == 'Farketmez';
      _seciliTarih      = ilan.tarih;
      _mevcutResimler   = List<String>.from(ilan.tumResimler);
      final key = ilan.kategori;
      for (final ana in kKategoriAgaci) {
        if (ana.key == key) { _seciliAnaKey = key; break; }
        for (final alt in ana.altlar) {
          if (alt.key == key) { _seciliAnaKey = ana.key; _seciliAltKey = key; break; }
        }
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _urunCtrl.dispose();
    _neredenCtrl.dispose();
    _nereyeCtrl.dispose();
    _notlarCtrl.dispose();
    super.dispose();
  }

  void _adimDegistir(int yeniAdim) {
    final baslangic = _sheetYukseklikleri[_adim];
    final hedef     = _sheetYukseklikleri[yeniAdim];
    _sheetAnim = Tween<double>(begin: baslangic, end: hedef).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutCubic),
    );
    _animCtrl.forward(from: 0);
    setState(() => _adim = yeniAdim);
  }

  bool _adimGecerli(int adim) {
    if (_istekMi && adim == 0) {
      if (_urunCtrl.text.trim().isEmpty) { _snack('Ürün adını girin.'); return false; }
      if (_seciliAnaKey == null) { _snack('Kategori seçin.'); return false; }
    }
    if ((!_istekMi && adim == 0) || (_istekMi && adim == 1)) {
      if (!_neredenFarketmez && _neredenCtrl.text.trim().isEmpty) {
        _snack('Nereden alanını doldurun.'); return false;
      }
      if (_nereyeCtrl.text.trim().isEmpty) {
        _snack('Nereye alanını doldurun.'); return false;
      }
    }
    return true;
  }

  void _ileri() {
    if (!_adimGecerli(_adim)) return;
    if (_adim < 2) {
      _adimDegistir(_adim + 1);
    } else {
      _kaydet();
    }
  }

  void _geri() {
    if (_adim > 0) {
      _adimDegistir(_adim - 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _resimEkle() async {
    final toplam = _mevcutResimler.length + _yeniResimler.length;
    if (toplam >= Pagination.maxResimSayisi) {
      _snack('En fazla ${Pagination.maxResimSayisi} resim ekleyebilirsin.');
      return;
    }
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      limit: Pagination.maxResimSayisi - toplam,
    );
    if (picked.isNotEmpty) {
      setState(() {
        for (final img in picked) {
          if (_mevcutResimler.length + _yeniResimler.length < Pagination.maxResimSayisi) {
            _yeniResimler.add(File(img.path));
          }
        }
      });
    }
  }

  Future<void> _kaydet() async {
    final user = ref.read(currentUserProvider);
    if (user == null) { _snack('Giriş yapmanız gerekiyor.'); return; }

    if (_duzenlemeModuMu) {
      await ref.read(ilanRepositoryProvider).ilanGuncelle(
        widget.duzenlenecekIlan!.id,
        {
          'nereden':  _neredenFarketmez ? 'Farketmez' : _neredenCtrl.text.trim(),
          'nereye':   _nereyeCtrl.text.trim(),
          'notlar':   _notlarCtrl.text.trim(),
          'kategori': _kayitKategoriKey,
          if (_istekMi) 'urun': _urunCtrl.text.trim(),
          if (_seciliTarih != null) 'tarih': _seciliTarih,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('İlan güncellendi!', style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating,
      ));
      ref.read(istekIlanlarProvider.notifier).yenile();
    } else {
      final ilan = IlanModel(
        id: '', tip: widget.tip,
        nereden:    _neredenFarketmez ? 'Farketmez' : _neredenCtrl.text.trim(),
        nereye:     _nereyeCtrl.text.trim(),
        urun:       _urunCtrl.text.trim(),
        ucret:      '', notlar: _notlarCtrl.text.trim(),
        kategori:   _kayitKategoriKey,
        kullaniciId: user.uid,
        kullaniciAd: user.displayName ?? user.email ?? '',
        tarih:      _seciliTarih,
      );
      final id = await ref.read(ilanOlusturProvider.notifier).olustur(
        ilan: ilan, resimler: _yeniResimler,
      );
      if (!mounted) return;
      if (id != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('İlan başarıyla yayınlandı!', style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating,
        ));
        ref.read(istekIlanlarProvider.notifier).yenile();
      } else {
        _snack('İlan yayınlanamadı. Tekrar deneyin.');
      }
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(m, style: GoogleFonts.dmSans()),
    backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
  ));

  Future<void> _tarihSec() async {
    final s = await showDatePicker(
      context: context,
      initialDate: _seciliTarih ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (s != null) setState(() => _seciliTarih = s);
  }

  void _kategoriSec() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => KategoriSecimSheet(
        seciliAnaKey: _seciliAnaKey,
        seciliAltKey: _seciliAltKey,
        onSecildi: (anaKey, altKey) {
          setState(() { _seciliAnaKey = anaKey; _seciliAltKey = altKey; });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(ilanOlusturProvider).yukleniyor;
    final progress   = ref.watch(ilanOlusturProvider).yuklemeProgress;
    final screenH    = MediaQuery.of(context).size.height;
    final statusH    = MediaQuery.of(context).padding.top;

    final adimlar = _istekMi
        ? ['Ürün', 'Güzergah', 'Detaylar']
        : ['Güzergah', 'Tarih', 'Detaylar'];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Arka plan ───────────────────────────────────────────────────────
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: statusH),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _geri,
                        child: Icon(
                          _adim == 0 ? Icons.close : Icons.arrow_back,
                          color: AppColors.textPrimary, size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _duzenlemeModuMu ? 'İlanı Düzenle' :
                            (_istekMi ? 'İstek İlanı Ver' : 'Taşıyıcı İlanı Ver'),
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const SizedBox(width: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Büyük adım numarası — arka plan dekoratif
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_adim + 1} / 3',
                        style: GoogleFonts.dmSans(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adimlar[_adim],
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sheet ───────────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _sheetAnim,
            builder: (_, _) {
              final sheetH = screenH * _sheetAnim.value;
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: sheetH,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Handle + nokta göstergesi
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          children: [
                            Container(
                              width: 32, height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: List.generate(3, (i) {
                                final aktif = i == _adim;
                                final tamam = i < _adim;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: aktif ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: aktif
                                        ? AppColors.textPrimary
                                        : tamam
                                            ? AppColors.textSecondary
                                            : AppColors.divider,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      // İçerik
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _adimIcerigi(yukleniyor, progress),
                        ),
                      ),
                      // Alt butonlar
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            20, 12, 20,
                            MediaQuery.of(context).padding.bottom + 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              top: BorderSide(
                                  color: AppColors.divider, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            if (_adim > 0) ...[
                              Expanded(
                                child: GestureDetector(
                                  onTap: _geri,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.divider),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text('Geri',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: yukleniyor ? null : _ileri,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: yukleniyor
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : Text(
                                            _adim == 2 ? 'Yayınla' : 'İleri',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _adimIcerigi(bool yukleniyor, double progress) {
    if (_istekMi) {
      switch (_adim) {
        case 0: return _AdimUrunIcerik(
          urunCtrl: _urunCtrl,
          kategoriAdi: _kategoriGorunumAdi,
          onKategoriSec: _kategoriSec,
        );
        case 1: return _AdimGuzergahIcerik(
          neredenCtrl: _neredenCtrl,
          nereyeCtrl: _nereyeCtrl,
          neredenFarketmez: _neredenFarketmez,
          istekMi: true,
          onFarketmezDegis: (v) => setState(() {
            _neredenFarketmez = v;
            if (v) _neredenCtrl.clear();
          }),
        );
        case 2: return _AdimDetayIcerik(
          notlarCtrl: _notlarCtrl,
          mevcutResimler: _mevcutResimler,
          yeniResimler: _yeniResimler,
          yukleniyor: yukleniyor,
          progress: progress,
          onResimEkle: _resimEkle,
          onMevcutSil: (i) => setState(() => _mevcutResimler.removeAt(i)),
          onYeniSil: (i) => setState(() => _yeniResimler.removeAt(i)),
        );
      }
    } else {
      switch (_adim) {
        case 0: return _AdimGuzergahIcerik(
          neredenCtrl: _neredenCtrl,
          nereyeCtrl: _nereyeCtrl,
          neredenFarketmez: false,
          istekMi: false,
          onFarketmezDegis: (_) {},
        );
        case 1: return _AdimTarihIcerik(
          seciliTarih: _seciliTarih,
          onTarihSec: _tarihSec,
        );
        case 2: return _AdimDetayIcerik(
          notlarCtrl: _notlarCtrl,
          mevcutResimler: _mevcutResimler,
          yeniResimler: _yeniResimler,
          yukleniyor: yukleniyor,
          progress: progress,
          onResimEkle: _resimEkle,
          onMevcutSil: (i) => setState(() => _mevcutResimler.removeAt(i)),
          onYeniSil: (i) => setState(() => _yeniResimler.removeAt(i)),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

// ── Adım içerikleri ───────────────────────────────────────────────────────────

class _AdimUrunIcerik extends StatelessWidget {
  final TextEditingController urunCtrl;
  final String kategoriAdi;
  final VoidCallback onKategoriSec;
  const _AdimUrunIcerik({required this.urunCtrl, required this.kategoriAdi, required this.onKategoriSec});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormEtiket('Ürün adı *'),
        const SizedBox(height: 8),
        TextField(
          controller: urunCtrl,
          autofocus: true,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: _inputDeko('Örn: iPhone 15 Pro, Nike Air Max...'),
        ),
        const SizedBox(height: 20),
        _FormEtiket('Kategori *'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onKategoriSec,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    kategoriAdi.isNotEmpty ? kategoriAdi : 'Kategori seç...',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: kategoriAdi.isNotEmpty
                          ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AdimGuzergahIcerik extends StatelessWidget {
  final TextEditingController neredenCtrl;
  final TextEditingController nereyeCtrl;
  final bool neredenFarketmez;
  final bool istekMi;
  final ValueChanged<bool> onFarketmezDegis;
  const _AdimGuzergahIcerik({
    required this.neredenCtrl, required this.nereyeCtrl,
    required this.neredenFarketmez, required this.istekMi,
    required this.onFarketmezDegis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormEtiket('Nereden *'),
        const SizedBox(height: 8),
        if (!neredenFarketmez)
          _AutocompleteAlan(
            controller: neredenCtrl,
            hint: 'Ülke veya şehir...',
            icon: Icons.flight_takeoff_outlined,
            secenekler: [...kDunyaUlkeleri, ...kDunyaSehirleri],
          ),
        if (istekMi) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => onFarketmezDegis(!neredenFarketmez),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: neredenFarketmez ? AppColors.textPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: neredenFarketmez ? AppColors.textPrimary : AppColors.divider),
                  ),
                  child: neredenFarketmez
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Text('Nereden farketmez',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _FormEtiket('Nereye *'),
        const SizedBox(height: 8),
        _AutocompleteAlan(
          controller: nereyeCtrl,
          hint: 'Ülke veya şehir...',
          icon: Icons.flight_land_outlined,
          secenekler: [...kDunyaUlkeleri, ...kDunyaSehirleri],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AdimTarihIcerik extends StatelessWidget {
  final DateTime? seciliTarih;
  final VoidCallback onTarihSec;
  const _AdimTarihIcerik({required this.seciliTarih, required this.onTarihSec});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormEtiket('Seyahat tarihi'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTarihSec,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  seciliTarih != null
                      ? '${seciliTarih!.day}.${seciliTarih!.month}.${seciliTarih!.year}'
                      : 'Tarih seç...',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: seciliTarih != null
                        ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('İsteğe bağlı — belirtmeden de devam edebilirsin.',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AdimDetayIcerik extends StatelessWidget {
  final TextEditingController notlarCtrl;
  final List<String> mevcutResimler;
  final List<File> yeniResimler;
  final bool yukleniyor;
  final double progress;
  final VoidCallback onResimEkle;
  final ValueChanged<int> onMevcutSil;
  final ValueChanged<int> onYeniSil;

  const _AdimDetayIcerik({
    required this.notlarCtrl, required this.mevcutResimler,
    required this.yeniResimler, required this.yukleniyor,
    required this.progress, required this.onResimEkle,
    required this.onMevcutSil, required this.onYeniSil,
  });

  @override
  Widget build(BuildContext context) {
    final toplam = mevcutResimler.length + yeniResimler.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormEtiket('Notlar'),
        const SizedBox(height: 8),
        TextField(
          controller: notlarCtrl,
          maxLines: 3,
          maxLength: 300,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: _inputDeko('Ek bilgi, özel istekler...'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _FormEtiket('Fotoğraflar'),
            const Spacer(),
            Text('$toplam / ${Pagination.maxResimSayisi}',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Galeriden en fazla ${Pagination.maxResimSayisi} resim seçebilirsin.',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (toplam < Pagination.maxResimSayisi)
                GestureDetector(
                  onTap: onResimEkle,
                  child: Container(
                    width: 100, height: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 24, color: AppColors.textSecondary),
                        const SizedBox(height: 4),
                        Text('Ekle',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ...mevcutResimler.asMap().entries.map((e) => _ResimKutu(
                ilkMi: e.key == 0,
                onSil: () => onMevcutSil(e.key),
                child: CachedNetworkImage(
                  cacheManager: AppCacheManager.instance,
                  imageUrl: e.value,
                  width: 100, height: 100, fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                ),
              )),
              ...yeniResimler.asMap().entries.map((e) => _ResimKutu(
                ilkMi: mevcutResimler.isEmpty && e.key == 0,
                onSil: () => onYeniSil(e.key),
                child: Image.file(e.value, width: 100, height: 100, fit: BoxFit.cover),
              )),
            ],
          ),
        ),
        if (yukleniyor && yeniResimler.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Yükleniyor...',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              Text('%${(progress * 100).toInt()}',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              color: AppColors.textPrimary,
              backgroundColor: AppColors.divider,
              minHeight: 3,
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Resim kutu ───────────────────────────────────────────────────────────────

class _ResimKutu extends StatelessWidget {
  final Widget child;
  final bool ilkMi;
  final VoidCallback onSil;
  const _ResimKutu({required this.child, required this.ilkMi, required this.onSil});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
          if (ilkMi)
            Positioned(
              bottom: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Kapak',
                    style: GoogleFonts.dmSans(
                        fontSize: 9, color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onSil,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı ─────────────────────────────────────────────────────────────────

Widget _FormEtiket(String label) => Text(label,
    style: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary));

InputDecoration _inputDeko(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.divider)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.divider)),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5)),
);

// ── Autocomplete ──────────────────────────────────────────────────────────────

class _AutocompleteAlan extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final List<String> secenekler;
  const _AutocompleteAlan({
    required this.controller, required this.hint,
    required this.icon, required this.secenekler,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (val) {
        if (val.text.isEmpty) return const [];
        return secenekler.where(
            (s) => s.toLowerCase().contains(val.text.toLowerCase()));
      },
      onSelected: (s) => controller.text = s,
      fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
        ctrl.text = controller.text;
        ctrl.addListener(() => controller.text = ctrl.text);
        return TextField(
          controller: ctrl,
          focusNode: focus,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: _inputDeko(hint).copyWith(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint)),
          onEditingComplete: onSubmit,
        );
      },
      optionsViewBuilder: (ctx, onSec, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: MediaQuery.of(ctx).size.width - 48,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: opts.take(5).length,
              itemBuilder: (_, i) {
                final s = opts.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(s, style: GoogleFonts.dmSans(fontSize: 14)),
                  onTap: () => onSec(s),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Kategori Seçim Sheet ──────────────────────────────────────────────────────

class KategoriSecimSheet extends StatefulWidget {
  final String? seciliAnaKey;
  final String? seciliAltKey;
  final void Function(String anaKey, String? altKey) onSecildi;

  const KategoriSecimSheet({
    super.key,
    required this.seciliAnaKey,
    required this.seciliAltKey,
    required this.onSecildi,
  });

  @override
  State<KategoriSecimSheet> createState() => KategoriSecimSheetState();
}

class KategoriSecimSheetState extends State<KategoriSecimSheet> {
  late int _aktifAnaIndex;

  @override
  void initState() {
    super.initState();
    _aktifAnaIndex = _anaIndexBul(widget.seciliAnaKey);
  }

  int _anaIndexBul(String? key) {
    if (key == null) return 0;
    for (int i = 0; i < kKategoriAgaci.length; i++) {
      if (kKategoriAgaci[i].key == key) return i;
      for (final alt in kKategoriAgaci[i].altlar) {
        if (alt.key == key) return i;
      }
    }
    return 0;
  }

  String _secilenMetin() {
    if (widget.seciliAnaKey == null) return '';
    final ana = kKategoriAgaci.firstWhere(
      (k) => k.key == widget.seciliAnaKey,
      orElse: () => AnaKategori(key: '', ad: '', emoji: ''),
    );
    if (widget.seciliAltKey != null) {
      final alt = ana.altlar.firstWhere(
        (a) => a.key == widget.seciliAltKey,
        orElse: () => AltKategori(key: '', ad: ''),
      );
      if (alt.key.isNotEmpty) return '${ana.emoji} ${ana.ad} › ${alt.ad}';
    }
    return '${ana.emoji} ${ana.ad}';
  }

  @override
  Widget build(BuildContext context) {
    final ana = kKategoriAgaci[_aktifAnaIndex];
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(
            width: 32, height: 3,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Kategori Seç',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (widget.seciliAnaKey != null)
                  GestureDetector(
                    onTap: () => widget.onSecildi('diger', null),
                    child: Text('Temizle',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          if (widget.seciliAnaKey != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Text(_secilenMetin(),
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.36,
                  child: Container(
                    color: AppColors.surface,
                    child: ListView.builder(
                      itemCount: kKategoriAgaci.length,
                      itemBuilder: (ctx, i) {
                        final k = kKategoriAgaci[i];
                        final aktif  = i == _aktifAnaIndex;
                        final secili = widget.seciliAnaKey == k.key ||
                            k.altlar.any((a) => a.key == widget.seciliAltKey);
                        return GestureDetector(
                          onTap: () => setState(() => _aktifAnaIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 14),
                            decoration: BoxDecoration(
                              color: aktif ? Colors.white : Colors.transparent,
                              border: aktif
                                  ? const Border(left: BorderSide(
                                      color: AppColors.textPrimary, width: 2))
                                  : null,
                            ),
                            child: Row(children: [
                              Text(k.emoji, style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(k.ad,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: secili
                                          ? FontWeight.w600 : FontWeight.w400,
                                      color: secili || aktif
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    )),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 4, bottom: 32),
                    children: [
                      if (ana.altlar.isNotEmpty)
                        _AltSatir(
                          ad: '${ana.emoji} Tüm ${ana.ad}',
                          secili: widget.seciliAnaKey == ana.key &&
                              widget.seciliAltKey == null,
                          onTap: () => widget.onSecildi(ana.key, null),
                        ),
                      ...ana.altlar.map((alt) => _AltSatir(
                        ad: alt.ad,
                        secili: widget.seciliAltKey == alt.key,
                        onTap: () => widget.onSecildi(ana.key, alt.key),
                      )),
                      if (ana.altlar.isEmpty)
                        _AltSatir(
                          ad: '${ana.emoji} ${ana.ad}',
                          secili: widget.seciliAnaKey == ana.key,
                          onTap: () => widget.onSecildi(ana.key, null),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AltSatir extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;
  const _AltSatir({required this.ad, required this.secili, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: const Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5)),
          color: secili ? AppColors.surface : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(ad,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
                    color: secili
                        ? AppColors.textPrimary : AppColors.textSecondary,
                  )),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}