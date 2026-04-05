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

// ── Dünya Şehirleri & Ülkeleri ────────────────────────────────────────────────

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

// ── Form Screen ───────────────────────────────────────────────────────────────

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
  final _urunCtrl    = TextEditingController();
  final _nereyeCtrl  = TextEditingController();
  final _neredenCtrl = TextEditingController();
  final _ucretCtrl   = TextEditingController();
  final _notlarCtrl  = TextEditingController();

  // Kategori seçimi: iki aşamalı
  // _seciliAnaKategori → AnaKategori key'i
  // _seciliAltKategori → AltKategori key'i (opsiyonel)
  String? _seciliAnaKategori;
  String? _seciliAltKategori;

  bool _ucretBelirtmiyorum = false;
  bool _neredenFarketmez   = false;
  final List<File>   _yeniResimler   = [];
  List<String>       _mevcutResimler = [];
  final _picker = ImagePicker();

  bool get _istekMi        => widget.tip == IlanTip.istek;
  bool get _duzenlemeModuMu => widget.duzenlenecekIlan != null;

  /// Firestore'a kaydedilecek gerçek kategori key'i:
  /// Alt seçiliyse alt key, yoksa ana key
  String? get _kaydedilecekKategori =>
      _seciliAltKategori ?? _seciliAnaKategori;

  @override
  void initState() {
    super.initState();
    if (_duzenlemeModuMu) {
      final ilan = widget.duzenlenecekIlan!;
      _urunCtrl.text    = ilan.urun;
      _neredenCtrl.text = ilan.nereden == 'Farketmez' ? '' : ilan.nereden;
      _nereyeCtrl.text  = ilan.nereye;
      _ucretCtrl.text   = ilan.ucret;
      _notlarCtrl.text  = ilan.notlar;
      _neredenFarketmez = ilan.nereden == 'Farketmez';
      _ucretBelirtmiyorum = ilan.ucret.isEmpty;
      _mevcutResimler   = List<String>.from(ilan.tumResimler);

      // Mevcut kategori key'ini ana/alt olarak ayır
      if (ilan.kategori.isNotEmpty) {
        _initKategoriState(ilan.kategori);
      }
    }
  }

  /// Mevcut bir key'den ana/alt durumunu çöz
  void _initKategoriState(String key) {
    for (final ana in kKategoriAgaci) {
      if (ana.key == key) {
        _seciliAnaKategori = key;
        return;
      }
      for (final alt in ana.altlar) {
        if (alt.key == key) {
          _seciliAnaKategori = ana.key;
          _seciliAltKategori = key;
          return;
        }
      }
    }
    // Bulunamazsa ana olarak ata
    _seciliAnaKategori = key;
  }

  @override
  void dispose() {
    _urunCtrl.dispose();
    _nereyeCtrl.dispose();
    _neredenCtrl.dispose();
    _ucretCtrl.dispose();
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
    if (_istekMi && _kaydedilecekKategori == null) {
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
        'nereye':  _nereyeCtrl.text.trim(),
        'ucret':   _ucretBelirtmiyorum ? '' : _ucretCtrl.text.trim(),
        'notlar':  _notlarCtrl.text.trim(),
        'kategori': _kaydedilecekKategori ?? 'diger',
        if (_istekMi) 'urun': _urunCtrl.text.trim(),
      };
      await ref
          .read(ilanRepositoryProvider)
          .ilanGuncelle(widget.duzenlenecekIlan!.id, data);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İlan güncellendi!', style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(istekIlanlarProvider.notifier).yenile();
    } else {
      final ilan = IlanModel(
        id: '',
        tip:      widget.tip,
        nereden:  _neredenFarketmez ? 'Farketmez' : _neredenCtrl.text.trim(),
        nereye:   _nereyeCtrl.text.trim(),
        urun:     _urunCtrl.text.trim(),
        ucret:    _ucretBelirtmiyorum ? '' : _ucretCtrl.text.trim(),
        notlar:   _notlarCtrl.text.trim(),
        kategori: _kaydedilecekKategori ?? 'diger',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlan başarıyla yayınlandı!',
                style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(istekIlanlarProvider.notifier).yenile();
      } else {
        _snack('İlan yayınlanamadı. Tekrar deneyin.');
      }
    }
  }

  void _snack(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj, style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Kategori Seçici ──────────────────────────────────────────────────────

  /// Seçilen ana kategori değişince alt kategori sıfırlanır
  void _anaKategoriSec(String key) {
    setState(() {
      _seciliAnaKategori = key;
      _seciliAltKategori = null;
    });
  }

  void _altKategoriSec(String key) {
    setState(() => _seciliAltKategori = key);
  }

  /// Seçili kategorinin gösterim metni
  String get _kategoriGorunum {
    if (_seciliAnaKategori == null) return '';
    final ana = kKategoriAgaci.firstWhere(
      (k) => k.key == _seciliAnaKategori,
      orElse: () => AnaKategori(key: '', ad: '', emoji: ''),
    );
    if (_seciliAltKategori != null) {
      final alt = ana.altlar.firstWhere(
        (a) => a.key == _seciliAltKategori,
        orElse: () => AltKategori(key: '', ad: ''),
      );
      if (alt.key.isNotEmpty) return '${ana.emoji} ${ana.ad}  ›  ${alt.ad}';
    }
    return '${ana.emoji} ${ana.ad}';
  }

  @override
  Widget build(BuildContext context) {
    final yukleniyor  = ref.watch(ilanOlusturProvider).yukleniyor;
    final progress    = ref.watch(ilanOlusturProvider).yuklemeProgress;
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
              // ── Ürün adı (sadece istek) ─────────────────────────────
              if (_istekMi) ...[
                _Bolum(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Etiket('Ürün Adı *'),
                      const SizedBox(height: 8),
                      _Alan(
                        controller: _urunCtrl,
                        hint: 'Örn: iPhone 15 Pro, Nike Air Max...',
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Nereden / Nereye ────────────────────────────────────
              _Bolum(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Nereden *'),
                    const SizedBox(height: 8),
                    if (!_neredenFarketmez)
                      _AutocompleteAlan(
                        controller: _neredenCtrl,
                        hint: 'Ülke veya şehir ara...',
                        icon: Icons.flight_takeoff_outlined,
                        secenekler: [
                          ...kDunyaUlkeleri,
                          ...kDunyaSehirleri,
                        ],
                      ),
                    if (_istekMi) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _neredenFarketmez = !_neredenFarketmez;
                          if (_neredenFarketmez) _neredenCtrl.clear();
                        }),
                        child: Row(
                          children: [
                            _Checkbox(secili: _neredenFarketmez),
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
                    _Etiket('Nereye *'),
                    const SizedBox(height: 8),
                    _AutocompleteAlan(
                      controller: _nereyeCtrl,
                      hint: 'Ülke veya şehir ara...',
                      icon: Icons.flight_land_outlined,
                      secenekler: [
                        ...kDunyaUlkeleri,
                        ...kDunyaSehirleri,
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Kategori (sadece istek) — 2 adımlı ─────────────────
              if (_istekMi) ...[
                _Bolum(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Etiket('Kategori *'),
                          const Spacer(),
                          // Seçim özeti
                          if (_kategoriGorunum.isNotEmpty)
                            Flexible(
                              child: Text(
                                _kategoriGorunum,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Adım 1: Ana kategoriler
                      Text('Ana Kategori',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kKategoriAgaci.map((ana) {
                          final secili = _seciliAnaKategori == ana.key;
                          return GestureDetector(
                            onTap: () => _anaKategoriSec(ana.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: secili
                                    ? AppColors.red
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: secili
                                      ? AppColors.red
                                      : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                '${ana.emoji} ${ana.ad}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: secili
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: secili
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Adım 2: Alt kategoriler — sadece ana seçiliyse göster
                      if (_seciliAnaKategori != null) ...[
                        () {
                          final ana = kKategoriAgaci.firstWhere(
                            (k) => k.key == _seciliAnaKategori,
                            orElse: () =>
                                AnaKategori(key: '', ad: '', emoji: ''),
                          );
                          if (ana.altlar.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Divider(
                                  height: 1, color: AppColors.divider),
                              const SizedBox(height: 14),
                              Text('Alt Kategori',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ana.altlar.map((alt) {
                                  final secili =
                                      _seciliAltKategori == alt.key;
                                  return GestureDetector(
                                    onTap: () =>
                                        _altKategoriSec(alt.key),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: secili
                                            ? AppColors.red
                                            : AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: secili
                                              ? AppColors.red
                                              : AppColors.divider,
                                        ),
                                      ),
                                      child: Text(
                                        alt.ad,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: secili
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: secili
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        }(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Ücret ───────────────────────────────────────────────
              _Bolum(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Ücret'),
                    const SizedBox(height: 8),
                    if (!_ucretBelirtmiyorum)
                      _Alan(
                        controller: _ucretCtrl,
                        hint: 'Örn: 150',
                        icon: Icons.attach_money_outlined,
                        klavye: TextInputType.number,
                        suffix: Text('₺',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 15)),
                      ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _ucretBelirtmiyorum = !_ucretBelirtmiyorum;
                        if (_ucretBelirtmiyorum) _ucretCtrl.clear();
                      }),
                      child: Row(
                        children: [
                          _Checkbox(secili: _ucretBelirtmiyorum),
                          const SizedBox(width: 8),
                          Text('Belirtmek istemiyorum',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Notlar ──────────────────────────────────────────────
              _Bolum(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Notlar'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notlarCtrl,
                      maxLines: 3,
                      maxLength: 300,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ek bilgi veya notlarınız...',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.textHint, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Resimler (sadece istek) ──────────────────────────────
              if (_istekMi) ...[
                _Bolum(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Etiket('Fotoğraflar'),
                          const Spacer(),
                          Text(
                            '$toplamResim/${Pagination.maxResimSayisi}',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (toplamResim < Pagination.maxResimSayisi)
                              GestureDetector(
                                onTap: _resimEkle,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(
                                        color: AppColors.divider),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: AppColors.textSecondary,
                                          size: 28),
                                      const SizedBox(height: 4),
                                      Text('Ekle',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ..._mevcutResimler.asMap().entries.map((e) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    margin:
                                        const EdgeInsets.only(right: 8),
                                    child: Image.network(e.value,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _mevcutResimSil(e.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            ..._yeniResimler.asMap().entries.map((e) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    margin:
                                        const EdgeInsets.only(right: 8),
                                    child: Image.file(e.value,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _yeniResimSil(e.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
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

              if (yukleniyor && _yeniResimler.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        color: AppColors.red,
                        backgroundColor: AppColors.divider,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resimler yükleniyor... %${(progress * 100).toInt()}',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: yukleniyor ? null : _kaydet,
                    child: yukleniyor
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _duzenlemeModuMu ? 'Güncelle' : 'İlanı Yayınla',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
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

// ── Yardımcı Widget'lar ───────────────────────────────────────────────────────

class _Bolum extends StatelessWidget {
  final Widget child;
  const _Bolum({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary));
  }
}

/// Tekrar kullanılabilir checkbox widget'ı
class _Checkbox extends StatelessWidget {
  final bool secili;
  const _Checkbox({required this.secili});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: secili ? AppColors.red : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: secili ? AppColors.red : AppColors.divider,
        ),
      ),
      child: secili
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _Alan extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType klavye;
  final Widget? suffix;

  const _Alan({
    required this.controller,
    required this.hint,
    required this.icon,
    this.klavye = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: klavye,
      style: GoogleFonts.dmSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ── Autocomplete Alan ─────────────────────────────────────────────────────────

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
      final tumSonuclar = [...baslayan, ...icerenler];
      _filtreli = tumSonuclar.length == 1
          ? tumSonuclar
          : tumSonuclar.take(8).toList();
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
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _filtreli.map((s) {
                return InkWell(
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
                            size: 16,
                            color: AppColors.textSecondary),
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
