import 'dart:io';
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

const List<String> kDunyaSehirleri = [
  'Adana', 'Ankara', 'Antalya', 'Bursa', 'Diyarbakır', 'Eskişehir',
  'Gaziantep', 'İstanbul', 'İzmir', 'Kayseri', 'Konya', 'Mersin',
  'Samsun', 'Trabzon', 'Adıyaman', 'Afyonkarahisar',
  'Amsterdam', 'Antwerp', 'Athens', 'Atlanta', 'Auckland',
  'Bangkok', 'Barcelona', 'Beijing', 'Berlin', 'Boston', 'Brussels',
  'Budapest', 'Buenos Aires', 'Cairo', 'Calgary', 'Cape Town',
  'Chicago', 'Copenhagen', 'Dallas', 'Delhi', 'Denver', 'Doha',
  'Dubai', 'Dublin', 'Düsseldorf', 'Edinburgh', 'Frankfurt',
  'Geneva', 'Hamburg', 'Helsinki', 'Hong Kong', 'Houston',
  'Jakarta', 'Johannesburg', 'Karachi', 'Kuala Lumpur', 'Kuwait City',
  'Lagos', 'Lahore', 'Las Vegas', 'Lisbon', 'London', 'Los Angeles',
  'Lyon', 'Madrid', 'Manchester', 'Manila', 'Melbourne', 'Mexico City',
  'Miami', 'Milan', 'Montreal', 'Moscow', 'Mumbai', 'Munich',
  'Nairobi', 'New York', 'Nice', 'Osaka', 'Oslo', 'Paris',
  'Prague', 'Riyadh', 'Rome', 'San Francisco', 'Santiago',
  'São Paulo', 'Seoul', 'Shanghai', 'Singapore', 'Stockholm',
  'Sydney', 'Taipei', 'Tehran', 'Tel Aviv', 'Tokyo', 'Toronto',
  'Vancouver', 'Vienna', 'Warsaw', 'Washington DC', 'Zurich',
  'Almaty', 'Baku', 'Tbilisi', 'Tashkent', 'Kyiv', 'Minsk',
  'Bucharest', 'Sofia', 'Belgrade', 'Zagreb', 'Sarajevo',
  'Beirut', 'Amman', 'Baghdad', 'Damascus', 'Muscat', 'Abu Dhabi',
  'Islamabad', 'Dhaka', 'Colombo', 'Kathmandu',
];

const List<String> kDunyaUlkeleri = [
  'Türkiye',
  'Almanya', 'Amerika Birleşik Devletleri', 'Arjantin', 'Avustralya',
  'Avusturya', 'Azerbaycan', 'Belçika', 'Birleşik Arap Emirlikleri',
  'Birleşik Krallık', 'Brezilya', 'Çin', 'Danimarka', 'Endonezya',
  'Fas', 'Filipinler', 'Finlandiya', 'Fransa', 'Güney Afrika',
  'Güney Kore', 'Gürcistan', 'Hindistan', 'Hollanda', 'İran',
  'İrlanda', 'İspanya', 'İsveç', 'İsviçre', 'İtalya', 'Japonya',
  'Kanada', 'Katar', 'Kazakistan', 'Kuveyt', 'Lübnan', 'Macaristan',
  'Malezya', 'Meksika', 'Mısır', 'Norveç', 'Özbekistan', 'Pakistan',
  'Polonya', 'Portekiz', 'Romanya', 'Rusya', 'Suudi Arabistan',
  'Singapur', 'Tayland', 'Ukrayna', 'Ürdün', 'Vietnam', 'Yunanistan',
  'Çek Cumhuriyeti', 'Slovakya', 'Hırvatistan', 'Bosna Hersek',
  'Sırbistan', 'Bulgaristan', 'Arnavutluk', 'Karadağ', 'Kosova',
  'Kıbrıs', 'Irak', 'Suriye', 'İsrail', 'Filistin', 'Umman',
  'Bahreyn', 'Yemen', 'Afganistan', 'Bangladeş', 'Sri Lanka', 'Nepal',
];

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

class _IlanFormScreenState extends ConsumerState<IlanFormScreen> {
  final _urunCtrl = TextEditingController();
  final _nereyeCtrl = TextEditingController();
  final _neredenCtrl = TextEditingController();
  final _notlarCtrl = TextEditingController();

  String? _seciliAnaKey;
  String? _seciliAltKey;
  bool _neredenFarketmez = false;
  final List<File> _yeniResimler = [];
  List<String> _mevcutResimler = [];
  final _picker = ImagePicker();

  bool get _istekMi => widget.tip == IlanTip.istek;
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
    if (_duzenlemeModuMu) {
      final ilan = widget.duzenlenecekIlan!;
      _urunCtrl.text = ilan.urun;
      _neredenCtrl.text = ilan.nereden == 'Farketmez' ? '' : ilan.nereden;
      _nereyeCtrl.text = ilan.nereye;
      _notlarCtrl.text = ilan.notlar;
      _neredenFarketmez = ilan.nereden == 'Farketmez';
      _mevcutResimler = List<String>.from(ilan.tumResimler);

      final key = ilan.kategori;
      for (final ana in kKategoriAgaci) {
        if (ana.key == key) {
          _seciliAnaKey = key;
          break;
        }
        for (final alt in ana.altlar) {
          if (alt.key == key) {
            _seciliAnaKey = ana.key;
            _seciliAltKey = key;
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _urunCtrl.dispose();
    _nereyeCtrl.dispose();
    _neredenCtrl.dispose();
    _notlarCtrl.dispose();
    super.dispose();
  }

  Future<void> _resimEkle() async {
    final toplamResim = _mevcutResimler.length + _yeniResimler.length;
    if (toplamResim >= Pagination.maxResimSayisi) {
      _snack('En fazla ${Pagination.maxResimSayisi} resim ekleyebilirsin.');
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _yeniResimler.add(File(picked.path)));
    }
  }

  void _mevcutResimSil(int index) =>
      setState(() => _mevcutResimler.removeAt(index));

  void _yeniResimSil(int index) =>
      setState(() => _yeniResimler.removeAt(index));

  bool _validate() {
    if (_istekMi && _urunCtrl.text.trim().isEmpty) {
      _snack('Ürün adını girin.');
      return false;
    }
    if (!_neredenFarketmez && _neredenCtrl.text.trim().isEmpty) {
      _snack('Nereden alanını doldurun.');
      return false;
    }
    if (_nereyeCtrl.text.trim().isEmpty) {
      _snack('Nereye alanını doldurun.');
      return false;
    }
    if (_istekMi && _seciliAnaKey == null) {
      _snack('Kategori seçin.');
      return false;
    }
    return true;
  }

  Future<void> _kaydet() async {
    if (!_validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _snack('Giriş yapmanız gerekiyor.');
      return;
    }

    if (_duzenlemeModuMu) {
      final data = {
        'nereden': _neredenFarketmez ? 'Farketmez' : _neredenCtrl.text.trim(),
        'nereye': _nereyeCtrl.text.trim(),
        'ucret': '',
        'notlar': _notlarCtrl.text.trim(),
        'kategori': _kayitKategoriKey,
        if (_istekMi) 'urun': _urunCtrl.text.trim(),
      };
      await ref.read(ilanRepositoryProvider).ilanGuncelle(
          widget.duzenlenecekIlan!.id, data);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('İlan güncellendi!', style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ));
      ref.read(istekIlanlarProvider.notifier).yenile();
    } else {
      final ilan = IlanModel(
        id: '',
        tip: widget.tip,
        nereden: _neredenFarketmez ? 'Farketmez' : _neredenCtrl.text.trim(),
        nereye: _nereyeCtrl.text.trim(),
        urun: _urunCtrl.text.trim(),
        ucret: '',
        notlar: _notlarCtrl.text.trim(),
        kategori: _kayitKategoriKey,
        kullaniciId: user.uid,
        kullaniciAd: user.displayName ?? user.email ?? '',
      );
      final id = await ref.read(ilanOlusturProvider.notifier).olustur(
            ilan: ilan,
            resimler: _yeniResimler,
          );
      if (!mounted) return;
      if (id != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('İlan başarıyla yayınlandı!',
              style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(istekIlanlarProvider.notifier).yenile();
      } else {
        _snack('İlan yayınlanamadı. Tekrar deneyin.');
      }
    }
  }

  void _snack(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj, style: GoogleFonts.dmSans()),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
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
        seciliAnaKey: _seciliAnaKey,
        seciliAltKey: _seciliAltKey,
        onSecildi: (anaKey, altKey) {
          setState(() {
            _seciliAnaKey = anaKey;
            _seciliAltKey = altKey;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(ilanOlusturProvider).yukleniyor;
    final progress = ref.watch(ilanOlusturProvider).yuklemeProgress;
    final toplamResim = _mevcutResimler.length + _yeniResimler.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _duzenlemeModuMu
              ? 'İlanı Düzenle'
              : (_istekMi ? 'İstek İlanı Ver' : 'Taşıyıcı İlanı Ver'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
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
              if (!_duzenlemeModuMu)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _istekMi
                              ? Icons.shopping_bag_outlined
                              : Icons.flight_takeoff_outlined,
                          color: AppColors.red,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // ✅ Güncellendi
                              _istekMi
                                  ? 'Ne istiyorsun?'
                                  : 'Nereye gidiyorsun?',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _istekMi
                                  ? 'Ürün bilgilerini doldur, taşıyıcılar seni bulsun.'
                                  : 'Güzergahını paylaş, getirmek istediklerin sana ulaşsın.',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_duzenlemeModuMu) const SizedBox(height: 8),

              // ── Ürün adı ─────────────────────────────
              if (_istekMi) ...[
                _Bolum(
                  baslik: 'Ürün Bilgisi',
                  ikon: Icons.shopping_bag_outlined,
                  child: _Alan(
                    controller: _urunCtrl,
                    hint: 'Örn: iPhone 15 Pro, Nike Air Max...',
                    icon: Icons.label_outline,
                    etiket: 'Ürün Adı *',
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Güzergah ─────────────────────────────
              _Bolum(
                baslik: 'Güzergah',
                ikon: Icons.route_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormEtiket('Nereden *'),
                    const SizedBox(height: 8),
                    if (!_neredenFarketmez)
                      _AutocompleteAlan(
                        controller: _neredenCtrl,
                        hint: 'Ülke veya şehir ara...',
                        icon: Icons.flight_takeoff_outlined,
                        secenekler: [...kDunyaUlkeleri, ...kDunyaSehirleri],
                      ),
                    if (_istekMi) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => setState(() {
                          _neredenFarketmez = !_neredenFarketmez;
                          if (_neredenFarketmez) _neredenCtrl.clear();
                        }),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _neredenFarketmez
                                    ? AppColors.red
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _neredenFarketmez
                                      ? AppColors.red
                                      : AppColors.divider,
                                ),
                              ),
                              child: _neredenFarketmez
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text('Nereden farketmez',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
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
                    _AutocompleteAlan(
                      controller: _nereyeCtrl,
                      hint: 'Ülke veya şehir ara...',
                      icon: Icons.flight_land_outlined,
                      secenekler: [...kDunyaUlkeleri, ...kDunyaSehirleri],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Kategori ─────────────────────────────
              if (_istekMi) ...[
                _Bolum(
                  baslik: 'Kategori *',
                  ikon: Icons.category_outlined,
                  child: GestureDetector(
                    onTap: _kategoriSec,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _seciliAnaKey != null
                            ? AppColors.red.withValues(alpha: 0.05)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _seciliAnaKey != null
                              ? AppColors.red.withValues(alpha: 0.3)
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _seciliAnaKey != null
                                  ? _kategoriGorunumAdi
                                  : 'Kategori seç...',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: _seciliAnaKey != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: _seciliAnaKey != null
                                ? AppColors.red
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              

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
                    hintText: 'Ürün hakkında ek bilgi, özel istekler...',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppColors.textHint, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.divider),
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

              // ── Resimler ──────────────────────────────
              if (_istekMi) ...[
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
                      '$toplamResim/${Pagination.maxResimSayisi}',
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
                        'Ürünün fotoğrafını ekle, daha hızlı eşleşirsin.',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (toplamResim < Pagination.maxResimSayisi)
                              GestureDetector(
                                onTap: _resimEkle,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.red
                                        .withValues(alpha: 0.05),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.red
                                          .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.red
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: AppColors.red,
                                          size: 22,
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
                            ..._mevcutResimler.asMap().entries.map((e) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: Image.network(
                                      e.value,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _mevcutResimSil(e.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  if (e.key == 0)
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.red,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text('Kapak',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                    ),
                                  Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(
                                          right: 10)),
                                ],
                              );
                            }),
                            ..._yeniResimler.asMap().entries.map((e) {
                              final isIlk =
                                  _mevcutResimler.isEmpty && e.key == 0;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: Image.file(
                                      e.value,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _yeniResimSil(e.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  if (isIlk)
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.red,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text('Kapak',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                    ),
                                  Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(
                                          right: 10)),
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
              ],

              // ── Progress ──────────────────────────────
              if (yukleniyor && _yeniResimler.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_upload_outlined,
                              color: AppColors.red, size: 18),
                          const SizedBox(width: 8),
                          Text('Resimler yükleniyor...',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('%${(progress * 100).toInt()}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: AppColors.red,
                          backgroundColor: AppColors.divider,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Yayınla Butonu ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: yukleniyor ? null : _kaydet,
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
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch_outlined,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _duzenlemeModuMu
                                    ? 'Güncelle'
                                    : 'İlanı Yayınla',
                                style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
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

// ── Kategori Seçim Sheet ──────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final ana = kKategoriAgaci[_aktifAnaIndex];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          // Başlık
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            fontSize: 13,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Seçili badge
          if (widget.seciliAnaKey != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: AppColors.red.withValues(alpha: 0.05),
              child: Text(
                _secilenMetin(),
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.red,
                    fontWeight: FontWeight.w500),
              ),
            ),
          // İki panel
          Expanded(
            child: Row(
              children: [
                // Sol: Ana kategoriler
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.36,
                  child: Container(
                    color: AppColors.surface,
                    child: ListView.builder(
                      itemCount: kKategoriAgaci.length,
                      itemBuilder: (ctx, i) {
                        final k = kKategoriAgaci[i];
                        final aktif = i == _aktifAnaIndex;
                        final secili = widget.seciliAnaKey == k.key ||
                            k.altlar.any(
                                (a) => a.key == widget.seciliAltKey);
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _aktifAnaIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 14),
                            decoration: BoxDecoration(
                              color: aktif
                                  ? Colors.white
                                  : Colors.transparent,
                              border: aktif
                                  ? const Border(
                                      left: BorderSide(
                                          color: AppColors.red,
                                          width: 3))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(k.emoji,
                                    style: const TextStyle(
                                        fontSize: 15)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    k.ad,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: secili
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: secili
                                          ? AppColors.red
                                          : aktif
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Sağ: Alt kategoriler
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
                            onTap: () =>
                                widget.onSecildi(ana.key, alt.key),
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
      if (alt.key.isNotEmpty) {
        return 'Seçili: ${ana.emoji} ${ana.ad} › ${alt.ad}';
      }
    }
    return 'Seçili: ${ana.emoji} Tüm ${ana.ad}';
  }
}

class _AltSatir extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;

  const _AltSatir({
    required this.ad,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: secili
              ? AppColors.red.withValues(alpha: 0.05)
              : null,
          border: Border(
            bottom: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ad,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight:
                      secili ? FontWeight.w600 : FontWeight.w400,
                  color: secili
                      ? AppColors.red
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: AppColors.red),
          ],
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
                width: 32,
                height: 32,
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

class _Alan extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? etiket;

  const _Alan({
    required this.controller,
    required this.hint,
    required this.icon,
    this.etiket,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (etiket != null) ...[
          _FormEtiket(etiket!),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
                color: AppColors.textHint, fontSize: 14),
            prefixIcon:
                Icon(icon, color: AppColors.textSecondary, size: 20),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
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
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _AutocompleteAlan extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final List<String> secenekler;

  const _AutocompleteAlan({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.secenekler,
  });

  @override
  State<_AutocompleteAlan> createState() => _AutocompleteAlanState();
}

class _AutocompleteAlanState extends State<_AutocompleteAlan> {
  List<String> _filtreli = [];
  bool _acik = false;

  void _filtrele(String q) {
    if (q.isEmpty) {
      setState(() => _acik = false);
      return;
    }
    final ql = q.toLowerCase();
    final baslayan = widget.secenekler
        .where((s) => s.toLowerCase().startsWith(ql))
        .toList();
    final icerenler = widget.secenekler
        .where((s) =>
            !s.toLowerCase().startsWith(ql) &&
            s.toLowerCase().contains(ql))
        .toList();
    setState(() {
      _acik = true;
      _filtreli = [...baslayan, ...icerenler].take(8).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _filtrele,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.dmSans(
                color: AppColors.textHint, fontSize: 14),
            prefixIcon: Icon(widget.icon,
                color: AppColors.textSecondary, size: 20),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() => _acik = false);
                    },
                  )
                : null,
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
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
          ),
        ),
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _filtreli.map((s) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    widget.controller.text = s;
                    setState(() => _acik = false);
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.red),
                        const SizedBox(width: 10),
                        Text(s,
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
