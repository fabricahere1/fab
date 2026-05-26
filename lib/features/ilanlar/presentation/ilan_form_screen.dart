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
import '../../../shared/utils/app_snackbar.dart';

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

  List<String> _kategoriYolu = [];
  String _cinsiyet = '';
  String _beden = '';
  String _pantolonBel = '';
  String _pantolonBoy = '';
  bool _neredenFarketmez = false;
  DateTime? _seciliTarih;
  final List<File> _yeniResimler   = [];
  List<String>     _mevcutResimler = [];
  final _picker = ImagePicker();

  static const _sheetYukseklikleri = [0.45, 0.60, 0.78];

  bool get _istekMi         => widget.tip == IlanTip.istek;
  bool get _duzenlemeModuMu => widget.duzenlenecekIlan != null;

  String get _kayitKategoriKey =>
      _kategoriYolu.isNotEmpty ? _kategoriYolu.last : 'diger';

  String get _kayitAnaKategoriKey =>
      _kategoriYolu.isNotEmpty ? _kategoriYolu.first : '';

  String get _kategoriGorunumAdi =>
      _kategoriYolu.isEmpty ? '' : kategoriYoluMetni(_kategoriYolu);

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
      if (ilan.kategoriYolu.isNotEmpty) {
        _kategoriYolu = List<String>.from(ilan.kategoriYolu);
      } else if (ilan.kategori.isNotEmpty) {
        _kategoriYolu = [ilan.kategori];
      }
      _cinsiyet = ilan.cinsiyet;
      final tipi = bedenTipiGetir(_kategoriYolu);
      if (tipi == BedenTipi.pantolon && ilan.beden.contains('/')) {
        final parcalar = ilan.beden.split('/');
        _pantolonBel = parcalar[0];
        _pantolonBoy = parcalar[1];
      } else {
        _beden = ilan.beden;
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
      if (_kategoriYolu.isEmpty) { _snack('Kategori seçin.'); return false; }
      final tipi = bedenTipiGetir(_kategoriYolu);
      if (tipi != BedenTipi.yok) {
        if (_cinsiyet.isEmpty) { _snack('Cinsiyet seçin.'); return false; }
        if (tipi == BedenTipi.pantolon) {
          if (_pantolonBel.isEmpty || _pantolonBoy.isEmpty) {
            _snack('Bel ve boy değerlerini seçin.'); return false;
          }
        } else if (_beden.isEmpty) {
          _snack(tipi == BedenTipi.ayakkabi ? 'Numara seçin.' : 'Beden seçin.');
          return false;
        }
      }
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

    final tipi = bedenTipiGetir(_kategoriYolu);
    final bedenDeger = tipi == BedenTipi.pantolon
        ? (_pantolonBel.isNotEmpty && _pantolonBoy.isNotEmpty
            ? '$_pantolonBel/$_pantolonBoy'
            : '')
        : _beden;

    if (_duzenlemeModuMu) {
      await ref.read(ilanRepositoryProvider).ilanGuncelle(
        widget.duzenlenecekIlan!.id,
        {
          'nereden':      _neredenFarketmez ? 'Farketmez' : _neredenCtrl.text.trim(),
          'nereye':       _nereyeCtrl.text.trim(),
          'notlar':       _notlarCtrl.text.trim(),
          'kategori':     _kayitKategoriKey,
          'anaKategori':  _kayitAnaKategoriKey,
          'kategoriYolu': _kategoriYolu,
          if (_istekMi) 'urun': _urunCtrl.text.trim(),
          if (_seciliTarih != null) 'tarih': _seciliTarih,
          'cinsiyet': _cinsiyet,
          'beden':    bedenDeger,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.basari(context, 'İlan güncellendi!');
      ref.read(istekIlanlarProvider.notifier).yenile();
    } else {
      final ilan = IlanModel(
        id: '', tip: widget.tip,
        nereden:      _neredenFarketmez ? 'Farketmez' : _neredenCtrl.text.trim(),
        nereye:       _nereyeCtrl.text.trim(),
        urun:         _urunCtrl.text.trim(),
        ucret:        '', notlar: _notlarCtrl.text.trim(),
        kategori:     _kayitKategoriKey,
        anaKategori:  _kayitAnaKategoriKey,
        kategoriYolu: _kategoriYolu,
        kullaniciId:  user.uid,
        kullaniciAd:  user.displayName ?? user.email ?? '',
        tarih:        _seciliTarih,
        cinsiyet:     _cinsiyet,
        beden:        bedenDeger,
      );
      final id = await ref.read(ilanOlusturProvider.notifier).olustur(
        ilan: ilan, resimler: _yeniResimler,
      );
      if (!mounted) return;
      if (id != null) {
        Navigator.pop(context);
        AppSnackBar.basari(context, 'İlan başarıyla yayınlandı!');
        ref.read(istekIlanlarProvider.notifier).yenile();
      } else {
        _snack('İlan yayınlanamadı. Tekrar deneyin.');
      }
    }
  }

  void _snack(String m) => AppSnackBar.hata(context, m);

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
        seciliYol: _kategoriYolu,
        onSecildi: (yol) {
          setState(() {
            _kategoriYolu = yol;
            _beden = '';
            _pantolonBel = '';
            _pantolonBoy = '';
            _cinsiyet = cinsiyetTahminiGetir(yol);
          });
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
                const SizedBox(height: 40),
                Column(
                  children: [
                    Text(
                      '${_adim + 1} / 3',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                    Text(
                      adimlar[_adim],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          AnimatedBuilder(
            animation: _sheetAnim,
            builder: (_, _) {
              final sheetH = screenH * _sheetAnim.value;
              return Positioned(
                bottom: 0, left: 0, right: 0,
                height: sheetH,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
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
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _adimIcerigi(yukleniyor, progress),
                        ),
                      ),
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
        case 0:
          final tipi = bedenTipiGetir(_kategoriYolu);
          return Column(
            children: [
              _AdimUrunIcerik(
                urunCtrl: _urunCtrl,
                kategoriAdi: _kategoriGorunumAdi,
                onKategoriSec: _kategoriSec,
              ),
              if (tipi != BedenTipi.yok) BedenCinsiyetBolum(
                tip: tipi,
                cinsiyet: _cinsiyet,
                beden: _beden,
                pantolonBel: _pantolonBel,
                pantolonBoy: _pantolonBoy,
                onCinsiyetDegis: (v) => setState(() => _cinsiyet = v),
                onBedenDegis: (v) => setState(() => _beden = v),
                onPantolonBelDegis: (v) => setState(() => _pantolonBel = v),
                onPantolonBoyDegis: (v) => setState(() => _pantolonBoy = v),
              ),
            ],
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
  const _AdimUrunIcerik({
    required this.urunCtrl,
    required this.kategoriAdi,
    required this.onKategoriSec,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formEtiket('Ürün adı *'),
        const SizedBox(height: 8),
        TextField(
          controller: urunCtrl,
          autofocus: true,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: _inputDeko('Örn: iPhone 15 Pro, Nike Air Max...'),
        ),
        const SizedBox(height: 20),
        _formEtiket('Kategori *'),
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
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 20),
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
        _formEtiket('Nereden *'),
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
                      color: neredenFarketmez
                          ? AppColors.textPrimary : AppColors.divider),
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
        _formEtiket('Nereye *'),
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
        _formEtiket('Seyahat tarihi'),
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
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
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
        _formEtiket('Notlar'),
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
            _formEtiket('Fotoğraflar'),
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
                child: Image.file(e.value,
                    width: 100, height: 100, fit: BoxFit.cover),
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
  const _ResimKutu({
    required this.child, required this.ilkMi, required this.onSil,
  });

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

Widget _formEtiket(String label) => Text(label,
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

// ── Beden / Cinsiyet Seçici ───────────────────────────────────────────────────

class BedenCinsiyetBolum extends StatelessWidget {
  final BedenTipi tip;
  final String cinsiyet;
  final String beden;
  final String pantolonBel;
  final String pantolonBoy;
  final ValueChanged<String> onCinsiyetDegis;
  final ValueChanged<String> onBedenDegis;
  final ValueChanged<String> onPantolonBelDegis;
  final ValueChanged<String> onPantolonBoyDegis;

  const BedenCinsiyetBolum({
    required this.tip,
    required this.cinsiyet,
    required this.beden,
    required this.pantolonBel,
    required this.pantolonBoy,
    required this.onCinsiyetDegis,
    required this.onBedenDegis,
    required this.onPantolonBelDegis,
    required this.onPantolonBoyDegis,
  });

  List<String> get _cinsiyetler => tip == BedenTipi.cocuk
      ? ['Kız', 'Erkek', 'Unisex']
      : ['Kadın', 'Erkek', 'Unisex'];

  List<String> get _bedenler {
    switch (tip) {
      case BedenTipi.standart: return kBedenStandart;
      case BedenTipi.ayakkabi: return kBedenAyakkabi;
      case BedenTipi.cocuk:    return kBedenCocuk;
      default:                 return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cinsiyet
        _formEtiket('Cinsiyet *'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _cinsiyetler.map((c) {
            final secili = cinsiyet == c;
            return GestureDetector(
              onTap: () => onCinsiyetDegis(secili ? '' : c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: secili ? AppColors.textPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: secili ? AppColors.textPrimary : AppColors.divider,
                  ),
                ),
                child: Text(
                  c,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secili ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Beden — Pantolon ise bel + boy
        if (tip == BedenTipi.pantolon) ...[
          _formEtiket('Beden (Bel / Boy) *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownBeden(
                  hint: 'Bel',
                  secili: pantolonBel,
                  secenekler: kBedenPantolonBel,
                  onDegis: onPantolonBelDegis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownBeden(
                  hint: 'Boy',
                  secili: pantolonBoy,
                  secenekler: kBedenPantolonBoy,
                  onDegis: onPantolonBoyDegis,
                ),
              ),
            ],
          ),
        ] else ...[
          _formEtiket(tip == BedenTipi.ayakkabi ? 'Numara *' : 'Beden *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bedenler.map((b) {
              final secili = beden == b;
              return GestureDetector(
                onTap: () => onBedenDegis(secili ? '' : b),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: secili ? AppColors.textPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: secili ? AppColors.textPrimary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    b,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secili ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 8),
        const SizedBox(height: 20),
      ],
    );
  }
}

class DropdownBeden extends StatelessWidget {
  final String hint;
  final String secili;
  final List<String> secenekler;
  final ValueChanged<String> onDegis;

  const DropdownBeden({
    required this.hint,
    required this.secili,
    required this.secenekler,
    required this.onDegis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: secili.isEmpty ? null : secili,
          hint: Text(hint,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textHint)),
          isExpanded: true,
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textPrimary),
          items: secenekler
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => onDegis(v ?? ''),
        ),
      ),
    );
  }
}

// ── Kategori Seçim Sheet ──────────────────────────────────────────────────────

class KategoriSecimSheet extends StatefulWidget {
  final List<String> seciliYol;
  final void Function(List<String> yol) onSecildi;

  const KategoriSecimSheet({
    super.key,
    required this.seciliYol,
    required this.onSecildi,
  });

  @override
  State<KategoriSecimSheet> createState() => _KategoriSecimSheetState();
}

class _KategoriSecimSheetState extends State<KategoriSecimSheet> {
  late List<String> _yol;

  @override
  void initState() {
    super.initState();
    _yol = List<String>.from(widget.seciliYol);
  }

  List<KategoriNode> _mevcutSeviyeNodes() {
    if (_yol.isEmpty) return kKategoriAgaci;
    List<KategoriNode> liste = kKategoriAgaci;
    for (final key in _yol) {
      final node = liste.firstWhere(
        (n) => n.key == key,
        orElse: () => KategoriNode(key: '', ad: ''),
      );
      if (node.key.isEmpty || node.altlar.isEmpty) break;
      liste = node.altlar;
    }
    return liste;
  }

  String _seviyeBasligi() {
    if (_yol.isEmpty) return 'Kategori Seç';
    final node = kategoriNodeBul(_yol.last);
    return node?.ad ?? 'Kategori Seç';
  }

  String _breadcrumb() {
    if (_yol.isEmpty) return '';
    return _yol.map((key) {
      final node = kategoriNodeBul(key);
      return node?.ad ?? key;
    }).join(' › ');
  }

  void _nodeSecildi(KategoriNode node) {
    if (node.yaprakMi) {
      final yeniYol = [..._yol, node.key];
      widget.onSecildi(yeniYol);
    } else {
      setState(() => _yol = [..._yol, node.key]);
    }
  }

  void _geriGit() {
    if (_yol.isNotEmpty) {
      setState(() => _yol = _yol.sublist(0, _yol.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes      = _mevcutSeviyeNodes();
    final breadcrumb = _breadcrumb();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(
            width: 32, height: 3,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_yol.isNotEmpty)
                  GestureDetector(
                    onTap: _geriGit,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_back_ios_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _seviyeBasligi(),
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (widget.seciliYol.isNotEmpty)
                  GestureDetector(
                    onTap: () => widget.onSecildi([]),
                    child: Text('Temizle',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          if (breadcrumb.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Text(
                breadcrumb,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: nodes.length,
              itemBuilder: (ctx, i) {
                final node   = nodes[i];
                final secili = widget.seciliYol.contains(node.key);
                return InkWell(
                  onTap: () => _nodeSecildi(node),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: secili
                          ? AppColors.red.withValues(alpha: 0.05)
                          : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (node.emoji.isNotEmpty) ...[
                          Text(node.emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            node.ad,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: secili
                                  ? FontWeight.w600 : FontWeight.w400,
                              color: secili
                                  ? AppColors.red : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (secili)
                          const Icon(Icons.check,
                              size: 18, color: AppColors.red)
                        else if (!node.yaprakMi)
                          const Icon(Icons.chevron_right,
                              size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}