import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/utils/app_snackbar.dart';
import 'ilan_form_screen.dart' show KategoriSecimSheet, BedenCinsiyetBolum;
import '../../../shared/widgets/autocomplete_alan.dart';

class GelenlerFormScreen extends ConsumerStatefulWidget {
  const GelenlerFormScreen({super.key});

  @override
  ConsumerState<GelenlerFormScreen> createState() =>
      _GelenlerFormScreenState();
}

class _GelenlerFormScreenState extends ConsumerState<GelenlerFormScreen> {
  final _ilanAdiCtrl = TextEditingController();
  final _neredenCtrl = TextEditingController();
  final _nereyeCtrl  = TextEditingController();
  final _notlarCtrl  = TextEditingController();
  final _picker      = ImagePicker();

  DateTime?    _seyahatTarihi;
  List<String> _kategoriYolu   = [];
  String       _tasimaTercihi  = 'istekler';
  final List<File> _resimler   = [];
  String _cinsiyet = '';
  String _beden    = '';
  String _pantolonBel = '';
  String _pantolonBoy = '';

  String get _kayitKategoriKey =>
      _kategoriYolu.isNotEmpty ? _kategoriYolu.last : 'diger';

  String get _kayitAnaKategoriKey =>
      _kategoriYolu.isNotEmpty ? _kategoriYolu.first : '';

  String get _kategoriGorunumAdi =>
      _kategoriYolu.isEmpty ? '' : kategoriYoluMetni(_kategoriYolu);

  @override
  void dispose() {
    _ilanAdiCtrl.dispose();
    _neredenCtrl.dispose();
    _nereyeCtrl.dispose();
    _notlarCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_neredenCtrl.text.trim().isEmpty) {
      _snack('Nereden alanını doldurun.');
      return false;
    }
    if (_nereyeCtrl.text.trim().isEmpty) {
      _snack('Nereye alanını doldurun.');
      return false;
    }
    if (_seyahatTarihi == null) {
      _snack('Seyahat tarihini seçin.');
      return false;
    }
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
    return true;
  }

  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: bugun,
      firstDate: bugun,
      lastDate: bugun.add(const Duration(days: 365)),
      locale: const Locale('tr'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.red,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (secilen != null) setState(() => _seyahatTarihi = secilen);
  }

  Future<void> _resimEkle() async {
    if (_resimler.length >= Pagination.maxResimSayisi) {
      _snack('En fazla ${Pagination.maxResimSayisi} resim ekleyebilirsin.');
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _resimler.add(File(picked.path)));
  }

  void _kategoriSec() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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

  Future<void> _ilanVer() async {
    if (!_validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _snack('Giriş yapmanız gerekiyor.');
      return;
    }

    final tipi = bedenTipiGetir(_kategoriYolu);
    final bedenDeger = tipi == BedenTipi.pantolon
        ? (_pantolonBel.isNotEmpty && _pantolonBoy.isNotEmpty
            ? '$_pantolonBel/$_pantolonBoy'
            : '')
        : _beden;

    final profilSnapshot = await ref.read(kullaniciBilgiProvider(user.uid).future);
    final ilan = IlanModel(
      id:           '',
      tip:          IlanTip.tasiyici,
      urun:         _ilanAdiCtrl.text.trim(),
      nereden:      _neredenCtrl.text.trim(),
      nereye:       _nereyeCtrl.text.trim(),
      ucret:        '',
      notlar:       _notlarCtrl.text.trim(),
      kategori:     _kayitKategoriKey,
      anaKategori:  _kayitAnaKategoriKey,
      kategoriYolu: _kategoriYolu,
      kullaniciId:  user.uid,
      kullaniciAd:  user.displayName ?? user.email ?? '',
      tarih:        _seyahatTarihi,
      cinsiyet:     _cinsiyet,
      beden:        bedenDeger,
      kullaniciPuan: profilSnapshot?.ortalamaPuan ?? 0.0,
      sahipDutyFree: profilSnapshot?.dutyFreeIlgileniyor ?? false,
    );

    final id = await ref.read(ilanOlusturProvider.notifier).olustur(
      ilan: ilan,
      resimler: _resimler,
    );

    if (!mounted) return;

    if (id != null) {
      Navigator.pop(context);
      AppSnackBar.basari(context, 'İlan başarıyla yayınlandı!');
      ref.read(tasiyiciIlanlarProvider.notifier).yenile();
    } else {
      _snack('İlan yayınlanamadı. Tekrar deneyin.');
    }
  }

  void _snack(String mesaj) => AppSnackBar.hata(context, mesaj);

  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(ilanOlusturProvider).yukleniyor;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Taşıyıcı İlanı Ver',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header Banner ─────────────────────────
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_outlined,
                        color: AppColors.red, size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nereye gidiyorsun?',
                              style: GoogleFonts.dmSans(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            'Güzergahını paylaş, getirmek istediklerin sana ulaşsın.',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── İlan Adı ──────────────────────────────
              _Bolum(
                baslik: 'İlan Adı',
                ikon: Icons.label_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _ilanAdiCtrl,
                      maxLength: 60,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Örn: Elektronik, Kozmetik, Giyim...',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.textHint, fontSize: 14),
                        prefixIcon: const Icon(Icons.label_outline,
                            color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Kategori ─────────────────────────────
              _Bolum(
                baslik: 'Kategori',
                ikon: Icons.category_outlined,
                child: GestureDetector(
                  onTap: _kategoriSec,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: _kategoriYolu.isNotEmpty
                          ? AppColors.red.withValues(alpha: 0.05)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kategoriYolu.isNotEmpty
                            ? AppColors.red.withValues(alpha: 0.3)
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _kategoriYolu.isNotEmpty
                                ? _kategoriGorunumAdi
                                : 'Kategori seç... (opsiyonel)',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: _kategoriYolu.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: _kategoriYolu.isNotEmpty
                                ? AppColors.red
                                : AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Beden / Cinsiyet ──────────────────────
              Builder(builder: (context) {
                final tipi = bedenTipiGetir(_kategoriYolu);
                if (tipi == BedenTipi.yok) return const SizedBox.shrink();
                return _Bolum(
                  baslik: tipi == BedenTipi.ayakkabi ? 'Numara & Cinsiyet' : 'Beden & Cinsiyet',
                  ikon: Icons.straighten_outlined,
                  child: BedenCinsiyetBolum(
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
                );
              }),
              const SizedBox(height: 8),

              // ── Güzergah ─────────────────────────────
              _Bolum(
                baslik: 'Güzergah',
                ikon: Icons.route_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormEtiket('Nereden *'),
                    const SizedBox(height: 8),
                    AutocompleteAlan(
                      controller: _neredenCtrl,
                      hint: 'Ülke veya şehir ara...',
                      icon: Icons.flight_takeoff_outlined,
                      secenekler: [...kDunyaUlkeleri, ...kDunyaSehirleri],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_downward,
                                size: 14, color: AppColors.red),
                            const SizedBox(width: 4),
                            Text('Varış noktası',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.red,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FormEtiket('Nereye *'),
                    const SizedBox(height: 8),
                    AutocompleteAlan(
                      controller: _nereyeCtrl,
                      hint: 'Ülke veya şehir ara...',
                      icon: Icons.flight_land_outlined,
                      secenekler: [...kDunyaUlkeleri, ...kDunyaSehirleri],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Seyahat Tarihi ────────────────────────
              _Bolum(
                baslik: 'Seyahat Tarihi *',
                ikon: Icons.calendar_today_outlined,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _tarihSec,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: _seyahatTarihi != null
                              ? AppColors.red.withValues(alpha: 0.05)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _seyahatTarihi != null
                                ? AppColors.red.withValues(alpha: 0.3)
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 20,
                                color: _seyahatTarihi != null
                                    ? AppColors.red
                                    : AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _seyahatTarihi != null
                                    ? '${_seyahatTarihi!.day}.${_seyahatTarihi!.month}.${_seyahatTarihi!.year}'
                                    : 'Tarih seç...',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: _seyahatTarihi != null
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: _seyahatTarihi != null
                                    ? AppColors.red
                                    : AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...[
                      ('istekler',     'İsteklere açığım',       Icons.search_outlined),
                      ('getirebilirim','Bunları getirebilirim',   Icons.inventory_2_outlined),
                      ('hepsi',        'Her ikisi de',            Icons.swap_horiz_outlined),
                    ].map((item) {
                      final key   = item.$1;
                      final label = item.$2;
                      final icon  = item.$3;
                      final secili = _tasimaTercihi == key;
                      return GestureDetector(
                        onTap: () => setState(() => _tasimaTercihi = key),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: secili
                                ? AppColors.red.withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: secili
                                  ? AppColors.red.withValues(alpha: 0.4)
                                  : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 20,
                                  color: secili
                                      ? AppColors.red
                                      : AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(label,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: secili
                                          ? AppColors.red
                                          : AppColors.textPrimary,
                                      fontWeight: secili
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    )),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secili ? AppColors.red : Colors.white,
                                  border: Border.all(
                                    color: secili
                                        ? AppColors.red
                                        : AppColors.divider,
                                    width: 1.5,
                                  ),
                                ),
                                child: secili
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Fotoğraflar ───────────────────────────
              _Bolum(
                baslik: 'Fotoğraflar',
                ikon: Icons.photo_library_outlined,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    '${_resimler.length}/${Pagination.maxResimSayisi}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opsiyonel — resim ekleyerek daha hızlı eşleşirsin.',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_resimler.length < Pagination.maxResimSayisi)
                            GestureDetector(
                              onTap: _resimEkle,
                              child: Container(
                                width: 120, height: 120,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.red.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: AppColors.red, size: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Fotoğraf Ekle',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: AppColors.red,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ..._resimler.asMap().entries.map((e) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    e.value,
                                    width: 120, height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 6, right: 16,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _resimler.removeAt(e.key)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (e.key == 0)
                                  Positioned(
                                    bottom: 6, left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('Kapak',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 10)),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Notlar ────────────────────────────────
              _Bolum(
                baslik: 'Notlar',
                ikon: Icons.notes_outlined,
                child: TextField(
                  controller: _notlarCtrl,
                  maxLines: 4,
                  maxLength: 300,
                  style: GoogleFonts.dmSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ek bilgi veya notlarınız...',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppColors.textHint, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Yayınla Butonu ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: yukleniyor ? null : _ilanVer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: yukleniyor
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text('İlanı Yayınla',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────

class _Bolum extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final Widget child;
  final Widget? trailing;

  const _Bolum({
    required this.baslik,
    required this.ikon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, size: 17, color: AppColors.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(baslik,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FormEtiket extends StatelessWidget {
  final String text;
  const _FormEtiket(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }
}