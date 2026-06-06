// lib/features/auth/presentation/profil_tamamla_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profil/providers/profil_provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' show kTurkiyeSehirleri, turkceKarsilastir;
import '../../../router/app_router.dart';
import 'profil_tamamla_widgets.dart';

TextStyle _sf({
  double? fontSize,
  Color? color,
  double? height,
  FontStyle? fontStyle,
  TextDecoration? decoration,
  Color? decorationColor,
  double? letterSpacing,
  FontWeight? fontWeight, // kabul edilir ama yok sayılır — her zaman w600
}) =>
    TextStyle(
      fontFamily: 'SF Pro Display',
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      color: color,
      height: height,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
    );

// ── Beden & ilgi sabitleri ────────────────────────────────────────────────────

const _kIlgiKategoriler = [
  ('kadin_giyim', '👗 Kadın Giyim'),
  ('erkek_giyim', '👔 Erkek Giyim'),
  ('cocuk_giyim', '🧸 Çocuk Giyim'),
  ('elektronik',  '📱 Elektronik'),
  ('ev',          '🏠 Ev'),
];

const _kKadinUstHarf     = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
const _kKadinUstNumarik  = ['34', '36', '38', '40', '42', '44'];
const _kKadinAltNumarik  = ['34', '36', '38', '40', '42', '44'];
const _kKadinAltHarf     = ['XS', 'S', 'M', 'L', 'XL'];
const _kErkekBeden       = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
const _kAyakkabiKadin    = ['36', '37', '38', '39', '40', '41', '42'];
const _kAyakkabiErkek    = ['38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48'];
const _kAyakkabiCocuk    = ['25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35'];

const _kYasadigiUlkeler = [
  'Almanya',
  'Amerika Birleşik Devletleri',
  'Andorra',
  'Arnavutluk',
  'Avusturya',
  'Belçika',
  'Bosna-Hersek',
  'Bulgaristan',
  'Çek Cumhuriyeti',
  'Danimarka',
  'Estonya',
  'Finlandiya',
  'Fransa',
  'Hırvatistan',
  'Hollanda',
  'İngiltere',
  'İrlanda',
  'İspanya',
  'İsveç',
  'İsviçre',
  'İtalya',
  'İzlanda',
  'Kanada',
  'Karadağ',
  'Kıbrıs',
  'Kosova',
  'Kuzey Makedonya',
  'Letonya',
  'Liechtenstein',
  'Litvanya',
  'Lüksemburg',
  'Macaristan',
  'Malta',
  'Moldovya',
  'Monako',
  'Norveç',
  'Polonya',
  'Portekiz',
  'Romanya',
  'San Marino',
  'Sırbistan',
  'Slovakya',
  'Slovenya',
  'Ukrayna',
  'Vatikan',
  'Yunanistan',
];

class ProfilTamamlaScreen extends ConsumerStatefulWidget {
  final bool ilkGiris;
  const ProfilTamamlaScreen({super.key, this.ilkGiris = true});

  @override
  ConsumerState<ProfilTamamlaScreen> createState() =>
      _ProfilTamamlaScreenState();
}

class _ProfilTamamlaScreenState extends ConsumerState<ProfilTamamlaScreen> {
  final _pageCtrl      = PageController();
  int _adim            = 0;

  // Sadece pure taşıyıcı 4 adım (adım 2 atlanır); istek ve her_ikisi 5 adım
  int get _toplamAdim   => _kullaniciTipi == 'tasiyici' ? 4 : 5;
  // Görüntüleme adımı — sadece pure taşıyıcı için adım 3+ bir geri alınır
  int get _gosterimAdim =>
      (_kullaniciTipi == 'tasiyici' && _adim >= 3) ? _adim - 1 : _adim;

  // Form state
  String? _kullaniciTipi;
  String  _bulunduguSehir = '';
  final _telefonCtrl  = TextEditingController();
  final _hakkindaCtrl = TextEditingController();
  bool   _telefonGizli = false;
  bool   _yukleniyor   = false;
  String _hata         = '';

  // Taşıyıcı adım-2 state
  bool?        _turkiyedeMi;
  String       _secilenIlTurkiye    = '';
  String       _secilenUlkeYurtdisi = '';
  final List<String> _seyahatEdilenSehirler = [];
  bool?        _dutyFreeIlgileniyor;
  String?      _teslimatTercihi;
  String?      _istekTeslimatTercihi;

  // İstek adım-2: ilgi kategorileri + beden
  final List<String> _ilgiKategorileri = [];
  final List<String> _kadinUstBeden    = [];
  final List<String> _kadinAltBeden    = [];
  final List<String> _erkekUstBeden    = [];
  final List<String> _erkekAltBeden    = [];
  final List<String> _kadinAyakkabi    = [];
  final List<String> _erkekAyakkabi    = [];
  final List<String> _cocukAyakkabi    = [];

  bool get _kadinGiyimSecili    => _ilgiKategorileri.contains('kadin_giyim');
  bool get _erkekGiyimSecili    => _ilgiKategorileri.contains('erkek_giyim');
  bool get _cocukGiyimSecili    => _ilgiKategorileri.contains('cocuk_giyim');
  bool get _herhangiGiyimSecili =>
      _kadinGiyimSecili || _erkekGiyimSecili || _cocukGiyimSecili;

  late final List<String> _sortedTurkiyeSehirleri;

  bool get _tasiyiciMi =>
      _kullaniciTipi == 'tasiyici' || _kullaniciTipi == 'her_ikisi';
  bool get _istekMi =>
      _kullaniciTipi == 'istek' || _kullaniciTipi == 'her_ikisi';

  @override
  void initState() {
    super.initState();
    _sortedTurkiyeSehirleri = [...kTurkiyeSehirleri]..sort(turkceKarsilastir);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _telefonCtrl.dispose();
    _hakkindaCtrl.dispose();
    super.dispose();
  }

  // ── Navigasyon ───────────────────────────────────────────────────────────────

  void _ileri() {
    setState(() => _hata = '');
    if (_adim == 0 && _kullaniciTipi == null) {
      setState(() => _hata = 'Lütfen bir seçenek seçin.');
      return;
    }
    if (_adim == 1) {
      if (_tasiyiciMi) {
        if (_turkiyedeMi == null) {
          setState(() => _hata = "Lütfen Türkiye'de yaşayıp yaşamadığınızı seçin.");
          return;
        }
        if (_turkiyedeMi! && _secilenIlTurkiye.isEmpty) {
          setState(() => _hata = 'Yaşadığınız şehri seçin.');
          return;
        }
        if (!_turkiyedeMi! && _secilenUlkeYurtdisi.isEmpty) {
          setState(() => _hata = 'Yaşadığınız ülkeyi seçin.');
          return;
        }
        if (!_turkiyedeMi! && _seyahatEdilenSehirler.isEmpty) {
          setState(() => _hata = "Türkiye'de gideceğiniz en az bir şehir seçin.");
          return;
        }
        if (_teslimatTercihi == null) {
          setState(() => _hata = 'Teslimat tercihini seçin.');
          return;
        }
        if (_kullaniciTipi == 'tasiyici' && _dutyFreeIlgileniyor == null) {
          setState(() => _hata = 'Duty Free tercihini belirtin.');
          return;
        }
      }
      if (_istekMi && !_tasiyiciMi && _bulunduguSehir.trim().isEmpty) {
        setState(() => _hata = 'Bulunduğunuz şehri girin.');
        return;
      }
      if (_istekMi && !_tasiyiciMi && _istekTeslimatTercihi == null) {
        setState(() => _hata = 'Teslimat tercihini seçin.');
        return;
      }
    }
    final nextAdim = _adim + 1;
    // Adım 2 (ilgi/beden) sadece pure taşıyıcı için atlanır
    final navigateToAdim =
        (nextAdim == 2 && _kullaniciTipi == 'tasiyici') ? 3 : nextAdim;

    if (navigateToAdim <= 4) {
      setState(() => _adim = navigateToAdim);
      _pageCtrl.animateToPage(navigateToAdim,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    } else {
      _kaydet();
    }
  }

  void _geri() {
    if (_adim > 0) {
      final prevAdim = _adim - 1;
      // Adım 2 (ilgi/beden) sadece pure taşıyıcı için atlanır
      final navigateToAdim =
          (prevAdim == 2 && _kullaniciTipi == 'tasiyici') ? 1 : prevAdim;
      setState(() {
        _adim = navigateToAdim;
        _hata = '';
      });
      _pageCtrl.animateToPage(navigateToAdim,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    }
  }

  Future<void> _kaydet() async {
    setState(() {
      _yukleniyor = true;
      _hata       = '';
    });
    final user = ref.read(currentUserProvider);
    final uid  = user?.uid;
    if (uid == null) {
      setState(() {
        _yukleniyor = false;
        _hata       = 'Oturum bulunamadı.';
      });
      return;
    }
    try {
      final String yasadigiUlke;
      final List<String> geldigiSehirler;
      final String bulunduguSehir;

      if (_tasiyiciMi) {
        yasadigiUlke    = _turkiyedeMi == true ? 'Türkiye' : _secilenUlkeYurtdisi;
        geldigiSehirler = _turkiyedeMi == true ? [] : List<String>.from(_seyahatEdilenSehirler);
        bulunduguSehir  = _turkiyedeMi == true ? _secilenIlTurkiye : '';
      } else {
        yasadigiUlke    = '';
        geldigiSehirler = [];
        bulunduguSehir  = _istekMi ? _bulunduguSehir.trim() : '';
      }

      final data = {
        'kullaniciTipi':       _kullaniciTipi,
        'yasadigiUlke':        yasadigiUlke,
        'geldigiSehirler':     geldigiSehirler,
        'bulunduguSehir':      bulunduguSehir,
        'dutyFreeIlgileniyor': _dutyFreeIlgileniyor,
        'teslimatTercihi':     _tasiyiciMi ? (_teslimatTercihi ?? 'ikisi_de') : null,
        'istekTeslimatTercihi': (_istekMi && !_tasiyiciMi) ? _istekTeslimatTercihi : null,
        'ilgiKategorileri':    _ilgiKategorileri,
        'kadinUstBeden':       _kadinUstBeden,
        'kadinAltBeden':       _kadinAltBeden,
        'erkekUstBeden':       _erkekUstBeden,
        'erkekAltBeden':       _erkekAltBeden,
        'kadinAyakkabi':       _kadinAyakkabi,
        'erkekAyakkabi':       _erkekAyakkabi,
        'cocukAyakkabi':       _cocukAyakkabi,
        'hakkinda':            _hakkindaCtrl.text.trim(),
        'telefon':             _telefonCtrl.text.trim(),
        'telefonGizli':        _telefonGizli,
        'adSoyad':             user?.displayName ?? '',
        'email':               user?.email ?? '',
      };
      final basarili = await ref
          .read(profilDuzenleProvider.notifier)
          .profilTamamla(uid: uid, data: data);
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      if (basarili) {
        context.go(AppRoutes.home);
      } else {
        setState(() => _hata = 'Bir hata oluştu. Tekrar deneyin.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yukleniyor = false;
        _hata       = 'Hata: $e';
      });
    }
  }

  // ── Bottom Sheet / Dialog Açıcılar ──────────────────────────────────────────

  void _ilSecimAc(ValueChanged<String> onSecildi, {String secilen = ''}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TekSecimSheet(
        baslik: 'Şehir seçin',
        secenekler: _sortedTurkiyeSehirleri,
        secilen: secilen,
        onSecildi: (v) {
          onSecildi(v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _ulkeSecimAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TekSecimSheet(
        baslik: 'Ülke seçin',
        secenekler: _kYasadigiUlkeler,
        secilen: _secilenUlkeYurtdisi,
        onSecildi: (v) {
          setState(() => _secilenUlkeYurtdisi = v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _cokluSehirSecimAc() {
    final oncekiSecim = List<String>.from(_seyahatEdilenSehirler);
    showDialog(
      context: context,
      builder: (ctx) => _CokluSehirDialog(
        secenekler: _sortedTurkiyeSehirleri,
        baslangicSecim: oncekiSecim,
        onTamam: (secilenler) => setState(() {
          _seyahatEdilenSehirler
            ..clear()
            ..addAll(secilenler);
        }),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _adim > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: AppColors.textPrimary),
                onPressed: _geri,
              )
            : null,
        title: Text(
          widget.ilkGiris ? 'Profilini Tamamla' : 'Profili Düzenle',
          style: _sf(
              fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_gosterimAdim + 1}/$_toplamAdim',
                  style: _sf(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: List.generate(
              _toplamAdim,
              (i) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  color: i <= _gosterimAdim ? AppColors.red : AppColors.divider,
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildAdim1(),
                _buildAdim2(),
                _buildAdim3(),
                _buildAdim4(),
                _buildAdim5(),
              ],
            ),
          ),
          if (_hata.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: AppColors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_hata,
                        style: _sf(
                            fontSize: 13, color: AppColors.red)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _ileri,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _yukleniyor
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _gosterimAdim == _toplamAdim - 1
                                ? 'Tamamla'
                                : 'Devam Et',
                            style: _sf(
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          if (_gosterimAdim < _toplamAdim - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Adım 1: Kim olduğunu seç ─────────────────────────────────────────────────

  Widget _buildAdim1() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ProfilAdimHeader(
              ikon: Icons.person_outline,
              baslik: 'Sen kimsin?',
              aciklama: 'Sana en uygun deneyimi sunmak için seçim yap.',
            ),
            const SizedBox(height: 8),
            ProfilBolum(
              baslik: 'Kullanım şeklini seç',
              ikon: Icons.tune_outlined,
              child: Column(
                children: [
                  ProfilTipKart(
                    ikon: Icons.flight_takeoff_outlined,
                    baslik: 'Yurtdışından geliyorum',
                    aciklama:
                        "Türkiye'ye seyahat ediyorum, yanımda eşya getirebilirim.",
                    secili: _kullaniciTipi == 'tasiyici',
                    onTap: () =>
                        setState(() => _kullaniciTipi = 'tasiyici'),
                  ),
                  const SizedBox(height: 10),
                  ProfilTipKart(
                    ikon: Icons.shopping_bag_outlined,
                    baslik: 'Yurtdışından istiyorum',
                    aciklama:
                        'Yurtdışından getirilmesini istediğim ürünler var.',
                    secili: _kullaniciTipi == 'istek',
                    onTap: () =>
                        setState(() => _kullaniciTipi = 'istek'),
                  ),
                  const SizedBox(height: 10),
                  ProfilTipKart(
                    ikon: Icons.sync_alt_outlined,
                    baslik: 'Her ikisi de',
                    aciklama:
                        'Hem taşıyıcı hem istek sahibi olarak kullanacağım.',
                    secili: _kullaniciTipi == 'her_ikisi',
                    onTap: () =>
                        setState(() => _kullaniciTipi = 'her_ikisi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Adım 2: Konum ────────────────────────────────────────────────────────────

  Widget _buildAdim2() {
    if (_tasiyiciMi) return _buildAdim2Tasiyici();
    return _buildAdim2Istek();
  }

  Widget _buildAdim2Tasiyici() {
    final teslimatGoster = _turkiyedeMi != null &&
        (_turkiyedeMi!
            ? _secilenIlTurkiye.isNotEmpty
            : _secilenUlkeYurtdisi.isNotEmpty);

    final dutyFreeGoster = teslimatGoster && _teslimatTercihi != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ProfilAdimHeader(
              ikon: Icons.location_on_outlined,
              baslik: 'Konum bilgisi',
              aciklama: 'Nerede yaşadığını ve seyahat bilgilerini paylaş.',
            ),
            const SizedBox(height: 8),

            // Türkiye'de mi yaşıyorsun?
            ProfilBolum(
              baslik: "Türkiye'de mi yaşıyorsun?",
              ikon: Icons.public_outlined,
              child: EvetHayirSecici(
                deger: _turkiyedeMi,
                onSecildi: (v) => setState(() {
                  _turkiyedeMi = v;
                  _secilenIlTurkiye = '';
                  _secilenUlkeYurtdisi = '';
                  _seyahatEdilenSehirler.clear();
                  _teslimatTercihi = null;
                  _dutyFreeIlgileniyor = null;
                }),
              ),
            ),

            // Evet → Hangi şehirde yaşıyorsun?
            if (_turkiyedeMi == true) ...[
              const SizedBox(height: 8),
              ProfilBolum(
                baslik: 'Hangi şehirde yaşıyorsun?',
                ikon: Icons.location_city_outlined,
                child: TekSecimAlani(
                  secilen: _secilenIlTurkiye,
                  placeholder: 'Şehir seçin...',
                  onTap: () => _ilSecimAc(
                      (v) => setState(() => _secilenIlTurkiye = v),
                      secilen: _secilenIlTurkiye),
                  onTemizle: () => setState(() {
                    _secilenIlTurkiye = '';
                    _teslimatTercihi = null;
                    _dutyFreeIlgileniyor = null;
                  }),
                ),
              ),
            ],

            // Hayır → Hangi ülkede yaşıyorsun?
            if (_turkiyedeMi == false) ...[
              const SizedBox(height: 8),
              ProfilBolum(
                baslik: 'Hangi ülkede yaşıyorsun?',
                ikon: Icons.public_outlined,
                child: TekSecimAlani(
                  secilen: _secilenUlkeYurtdisi,
                  placeholder: 'Ülke seçin...',
                  onTap: _ulkeSecimAc,
                  onTemizle: () => setState(() {
                    _secilenUlkeYurtdisi = '';
                    _seyahatEdilenSehirler.clear();
                    _teslimatTercihi = null;
                    _dutyFreeIlgileniyor = null;
                  }),
                ),
              ),
            ],

            // Hayır + ülke seçildi → Türkiye'de hangi şehirlere seyahat ediyorsun?
            if (_turkiyedeMi == false && _secilenUlkeYurtdisi.isNotEmpty) ...[
              const SizedBox(height: 8),
              ProfilBolum(
                baslik: "Türkiye'de hangi şehirlere seyahat ediyorsun?",
                ikon: Icons.flight_land_outlined,
                child: CokluSehirSecimAlani(
                  secilenler: _seyahatEdilenSehirler,
                  placeholder: 'Şehir seçin...',
                  onTap: _cokluSehirSecimAc,
                  onKaldirildi: (s) =>
                      setState(() => _seyahatEdilenSehirler.remove(s)),
                ),
              ),
            ],

            // Teslimat tercihi sorusu
            if (teslimatGoster) ...[
              const SizedBox(height: 8),
              ProfilBolum(
                baslik: 'Ürün teslimat tercihin nedir?',
                ikon: Icons.local_shipping_outlined,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _teslimatTercihi != null
                          ? AppColors.primary
                          : AppColors.divider,
                      width: _teslimatTercihi != null ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _teslimatTercihi,
                      hint: Text(
                        'Seçiniz...',
                        style: _sf(
                            color: AppColors.textHint, fontSize: 14),
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                      style: _sf(
                          fontSize: 14, color: AppColors.textPrimary),
                      items: [
                        DropdownMenuItem(
                          value: 'kargo',
                          child: Text('Kargo ile teslimat',
                              style: _sf(
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ),
                        DropdownMenuItem(
                          value: 'elden',
                          child: Text('Elden teslimat',
                              style: _sf(
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ),
                        DropdownMenuItem(
                          value: 'ikisi_de',
                          child: Text('İkisi de olsun',
                              style: _sf(
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _teslimatTercihi = v),
                    ),
                  ),
                ),
              ),
            ],

            // Duty Free sorusu — her_ikisi için 3/5'te gösterildiğinden burada sadece pure taşıyıcı
            if (dutyFreeGoster && _kullaniciTipi == 'tasiyici') ...[
              const SizedBox(height: 8),
              ProfilBolum(
                baslik: 'Duty Free alışverişi ile ilgileniyor musun?',
                ikon: Icons.shopping_bag_outlined,
                child: EvetHayirSecici(
                  deger: _dutyFreeIlgileniyor,
                  onSecildi: (v) =>
                      setState(() => _dutyFreeIlgileniyor = v),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── İlgi kategorisi toggle ───────────────────────────────────────────────────

  void _ilgiKategoriToggle(String key) {
    setState(() {
      if (_ilgiKategorileri.contains(key)) {
        _ilgiKategorileri.remove(key);
        if (key == 'kadin_giyim') {
          _kadinUstBeden.clear(); _kadinAltBeden.clear(); _kadinAyakkabi.clear();
        } else if (key == 'erkek_giyim') {
          _erkekUstBeden.clear(); _erkekAltBeden.clear(); _erkekAyakkabi.clear();
        } else if (key == 'cocuk_giyim') {
          _cocukAyakkabi.clear();
        }
      } else {
        _ilgiKategorileri.add(key);
      }
    });
  }

  // ── Çoklu beden chip satırı ───────────────────────────────────────────────

  Widget _cokluBedenSatiri(List<String> sizes, List<String> secili) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: sizes.map((b) {
        final isSelected = secili.contains(b);
        return GestureDetector(
          onTap: () => setState(() {
            isSelected ? secili.remove(b) : secili.add(b);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.red : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.red : AppColors.divider,
              ),
            ),
            child: Text(
              b,
              style: _sf(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bedenGrupBaslik(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: _sf(fontSize: 13, color: AppColors.red)),
      );

  Widget _bedenAlt(String label) =>
      Text(label, style: _sf(fontSize: 13, color: AppColors.textSecondary));

  // ── Ayakkabı seçim butonu ─────────────────────────────────────────────────

  Widget _ayakkabiButon() {
    final parts = <String>[];
    if (_kadinGiyimSecili && _kadinAyakkabi.isNotEmpty) {
      parts.add('Kadın: ${_kadinAyakkabi.join(', ')}');
    }
    if (_erkekGiyimSecili && _erkekAyakkabi.isNotEmpty) {
      parts.add('Erkek: ${_erkekAyakkabi.join(', ')}');
    }
    if (_cocukGiyimSecili && _cocukAyakkabi.isNotEmpty) {
      parts.add('Çocuk: ${_cocukAyakkabi.join(', ')}');
    }
    final hasSel = parts.isNotEmpty;

    return GestureDetector(
      onTap: _ayakkabiSecimAc,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasSel ? AppColors.red.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasSel
                ? AppColors.red.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasSel ? Icons.check_circle_outline : Icons.add_rounded,
              size: 18,
              color: hasSel ? AppColors.red : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasSel ? parts.join('  |  ') : 'Seçin...',
                style: _sf(
                  fontSize: 13,
                  color: hasSel ? AppColors.textPrimary : AppColors.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: hasSel ? AppColors.red : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _ayakkabiSecimAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AyakkabiBedenSheet(
        kadinSecili: _kadinGiyimSecili,
        erkekSecili: _erkekGiyimSecili,
        cocukSecili: _cocukGiyimSecili,
        kadinAyakkabi: List<String>.from(_kadinAyakkabi),
        erkekAyakkabi: List<String>.from(_erkekAyakkabi),
        cocukAyakkabi: List<String>.from(_cocukAyakkabi),
        onKaydet: (kadin, erkek, cocuk) => setState(() {
          _kadinAyakkabi..clear()..addAll(kadin);
          _erkekAyakkabi..clear()..addAll(erkek);
          _cocukAyakkabi..clear()..addAll(cocuk);
        }),
      ),
    );
  }

  // ── Beden bilgileri bölümü ────────────────────────────────────────────────

  Widget _buildBedenBilgileri() {
    return ProfilBolum(
      baslik: 'Beden Bilgileri',
      ikon: Icons.straighten_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Kadın Giyim
          if (_kadinGiyimSecili) ...[
            _bedenGrupBaslik('👗 Kadın Giyim'),
            const SizedBox(height: 12),
            _bedenAlt('Üst Beden'),
            const SizedBox(height: 8),
            _cokluBedenSatiri(_kKadinUstHarf, _kadinUstBeden),
            const SizedBox(height: 6),
            _cokluBedenSatiri(_kKadinUstNumarik, _kadinUstBeden),
            const SizedBox(height: 14),
            _bedenAlt('Alt Beden'),
            const SizedBox(height: 8),
            _cokluBedenSatiri(_kKadinAltNumarik, _kadinAltBeden),
            const SizedBox(height: 6),
            _cokluBedenSatiri(_kKadinAltHarf, _kadinAltBeden),
          ],

          // Erkek Giyim
          if (_erkekGiyimSecili) ...[
            if (_kadinGiyimSecili) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),
            ],
            _bedenGrupBaslik('👔 Erkek Giyim'),
            const SizedBox(height: 12),
            _bedenAlt('Üst Beden'),
            const SizedBox(height: 8),
            _cokluBedenSatiri(_kErkekBeden, _erkekUstBeden),
            const SizedBox(height: 14),
            _bedenAlt('Alt Beden'),
            const SizedBox(height: 8),
            _cokluBedenSatiri(_kErkekBeden, _erkekAltBeden),
          ],

          // Ayakkabı Bedeni
          if (_kadinGiyimSecili || _erkekGiyimSecili) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
          ],
          _bedenGrupBaslik('👟 Ayakkabı Bedeni'),
          const SizedBox(height: 10),
          _ayakkabiButon(),
        ],
      ),
    );
  }

  Widget _buildAdim2Istek() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ProfilAdimHeader(
              ikon: Icons.location_on_outlined,
              baslik: 'Konum bilgisi',
              aciklama: 'Konumunu paylaşarak, şehrine gelecek yurt dışı yolcularının ilanlarını Keşfet sayfanda görebilirsin.',
            ),
            const SizedBox(height: 8),
            ProfilBolum(
              baslik: "Türkiye'de hangi şehirde ikamet ediyorsun?",
              ikon: Icons.location_on_outlined,
              child: TekSecimAlani(
                secilen: _bulunduguSehir,
                placeholder: 'Şehir seçin...',
                onTap: () => _ilSecimAc(
                  (v) => setState(() => _bulunduguSehir = v),
                  secilen: _bulunduguSehir,
                ),
                onTemizle: () => setState(() => _bulunduguSehir = ''),
              ),
            ),
            const SizedBox(height: 8),
            ProfilBolum(
              baslik: 'İstediğin ürünlerin sana nasıl teslim edilmesini istersin?',
              ikon: Icons.local_shipping_outlined,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _istekTeslimatTercihi != null
                        ? AppColors.primary
                        : AppColors.divider,
                    width: _istekTeslimatTercihi != null ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _istekTeslimatTercihi,
                    hint: Text(
                      'Seçiniz...',
                      style: _sf(color: AppColors.textHint, fontSize: 14),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                    style: _sf(fontSize: 14, color: AppColors.textPrimary),
                    items: [
                      DropdownMenuItem(
                        value: 'kargo',
                        child: Text('Kargo ile teslimat',
                            style: _sf(fontSize: 14, color: AppColors.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'elden',
                        child: Text('Elden teslimat',
                            style: _sf(fontSize: 14, color: AppColors.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'ikisi_de',
                        child: Text('İkisi de olsun',
                            style: _sf(fontSize: 14, color: AppColors.textPrimary)),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _istekTeslimatTercihi = v),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Adım 3: İlgi Alanları (sadece istekçiler) ────────────────────────────────

  Widget _buildAdim3() {
    if (_kullaniciTipi == 'tasiyici') return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ProfilAdimHeader(
              ikon: Icons.interests_outlined,
              baslik: 'İlgi Alanların',
              aciklama: 'Burada vereceğin bilgiler uygulamayı senin için özelleştirmemize yarar.',
            ),
            const SizedBox(height: 8),

            // İlgi kategorileri
            ProfilBolum(
              baslik: 'En çok ne tür ürünlerle ilgilenirsin?',
              ikon: Icons.interests_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kIlgiKategoriler.map((entry) {
                  final (key, label) = entry;
                  final secili = _ilgiKategorileri.contains(key);
                  return GestureDetector(
                    onTap: () => _ilgiKategoriToggle(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: secili ? AppColors.red : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: secili ? AppColors.red : AppColors.divider,
                          width: secili ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: _sf(
                          fontSize: 13,
                          color: secili ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Beden Bilgileri
            if (_herhangiGiyimSecili) ...[
              const SizedBox(height: 8),
              _buildBedenBilgileri(),
            ],

            // Duty Free sorusu
            const SizedBox(height: 8),
            ProfilBolum(
              baslik: 'Duty Free alışverişi ile ilgileniyor musun?',
              ikon: Icons.shopping_bag_outlined,
              child: EvetHayirSecici(
                deger: _dutyFreeIlgileniyor,
                onSecildi: (v) =>
                    setState(() => _dutyFreeIlgileniyor = v),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Adım 4: İletişim ─────────────────────────────────────────────────────────

  Widget _buildAdim4() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ProfilAdimHeader(
              ikon: Icons.phone_outlined,
              baslik: 'İletişim bilgisi',
              aciklama: 'İsteğe bağlı — istersen atlayabilirsin.',
            ),
            const SizedBox(height: 8),
            ProfilBolum(
              baslik: 'Telefon numarası',
              ikon: Icons.phone_outlined,
              child: Column(
                children: [
                  TextField(
                    controller: _telefonCtrl,
                    keyboardType: TextInputType.phone,
                    style: _sf(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Örn: 05XX XXX XX XX',
                      hintStyle: _sf(
                          color: AppColors.textHint, fontSize: 14),
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _telefonGizli = !_telefonGizli),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Numarayı gizle',
                                    style: _sf(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('Sadece anlaştığın kişiler görebilir',
                                    style: _sf(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: _telefonGizli
                                  ? AppColors.red
                                  : AppColors.divider,
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _telefonGizli
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Adım 5: Hakkında ─────────────────────────────────────────────────────────

  Widget _buildAdim5() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ProfilAdimHeader(
              ikon: Icons.info_outline,
              baslik: 'Hakkında',
              aciklama: 'İsteğe bağlı — kendini kısaca tanıt.',
            ),
            const SizedBox(height: 8),
            ProfilBolum(
              baslik: 'Kendini tanıt',
              ikon: Icons.edit_outlined,
              child: TextField(
                controller: _hakkindaCtrl,
                maxLines: 5,
                maxLength: 200,
                style: _sf(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      "Örn: Almanya'da yaşıyorum, ayda bir İstanbul'a geliyorum...",
                  hintStyle: _sf(
                      color: AppColors.textHint, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Tek Seçim Bottom Sheet ────────────────────────────────────────────────────

class _TekSecimSheet extends StatefulWidget {
  final String baslik;
  final List<String> secenekler;
  final String secilen;
  final ValueChanged<String> onSecildi;

  const _TekSecimSheet({
    required this.baslik,
    required this.secenekler,
    required this.secilen,
    required this.onSecildi,
  });

  @override
  State<_TekSecimSheet> createState() => _TekSecimSheetState();
}

class _TekSecimSheetState extends State<_TekSecimSheet> {
  final _aramaCtrl = TextEditingController();
  late List<String> _filtreli;

  @override
  void initState() {
    super.initState();
    _filtreli = widget.secenekler;
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  void _filtrele(String q) {
    setState(() {
      _filtreli = q.isEmpty
          ? widget.secenekler
          : widget.secenekler
              .where((s) => s.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                widget.baslik,
                style: _sf(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AramaAlani(
                ctrl: _aramaCtrl,
                onChanged: _filtrele,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _filtreli.length,
                itemBuilder: (ctx, i) {
                  final item = _filtreli[i];
                  final secili = item == widget.secilen;
                  return InkWell(
                    onTap: () => widget.onSecildi(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: _sf(
                                fontSize: 14,
                                fontWeight: secili
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: secili
                                    ? AppColors.red
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (secili)
                            const Icon(Icons.check,
                                size: 18, color: AppColors.red),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Çoklu Şehir Dialog ───────────────────────────────────────────────────────

class _CokluSehirDialog extends StatefulWidget {
  final List<String> secenekler;
  final List<String> baslangicSecim;
  final ValueChanged<List<String>> onTamam;

  const _CokluSehirDialog({
    required this.secenekler,
    required this.baslangicSecim,
    required this.onTamam,
  });

  @override
  State<_CokluSehirDialog> createState() => _CokluSehirDialogState();
}

class _CokluSehirDialogState extends State<_CokluSehirDialog> {
  late List<String> _tempSecim;
  final _aramaCtrl = TextEditingController();
  late List<String> _filtreli;

  @override
  void initState() {
    super.initState();
    _tempSecim = List<String>.from(widget.baslangicSecim);
    _filtreli  = widget.secenekler;
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  void _filtrele(String q) {
    setState(() {
      _filtreli = q.isEmpty
          ? widget.secenekler
          : widget.secenekler
              .where((s) => s.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              "Türkiye'de hangi şehirlere\nseyahat ediyorsun?",
              style: _sf(
                  fontSize: 15, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AramaAlani(
              ctrl: _aramaCtrl,
              onChanged: _filtrele,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.38,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtreli.length,
              itemBuilder: (ctx, i) {
                final sehir = _filtreli[i];
                final secili = _tempSecim.contains(sehir);
                return CheckboxListTile(
                  value: secili,
                  title: Text(sehir,
                      style: _sf(fontSize: 14)),
                  activeColor: AppColors.red,
                  checkColor: Colors.white,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) => setState(() {
                    if (val == true) {
                      _tempSecim.add(sehir);
                    } else {
                      _tempSecim.remove(sehir);
                    }
                  }),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Vazgeç',
                        style: _sf(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onTamam(List<String>.from(_tempSecim));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Tamam',
                        style: _sf(
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
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

// ── Ortak Arama Alanı ────────────────────────────────────────────────────────

class _AramaAlani extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  const _AramaAlani({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: _sf(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Ara...',
        hintStyle:
            _sf(color: AppColors.textHint, fontSize: 14),
        prefixIcon: const Icon(Icons.search,
            color: AppColors.textSecondary, size: 20),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close,
                    size: 16, color: AppColors.textSecondary),
                onPressed: () => onChanged(''),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

// ── Ayakkabı Beden Seçim Sheet ────────────────────────────────────────────────

class _AyakkabiBedenSheet extends StatefulWidget {
  final bool kadinSecili;
  final bool erkekSecili;
  final bool cocukSecili;
  final List<String> kadinAyakkabi;
  final List<String> erkekAyakkabi;
  final List<String> cocukAyakkabi;
  final void Function(List<String>, List<String>, List<String>) onKaydet;

  const _AyakkabiBedenSheet({
    required this.kadinSecili,
    required this.erkekSecili,
    required this.cocukSecili,
    required this.kadinAyakkabi,
    required this.erkekAyakkabi,
    required this.cocukAyakkabi,
    required this.onKaydet,
  });

  @override
  State<_AyakkabiBedenSheet> createState() => _AyakkabiBedenSheetState();
}

class _AyakkabiBedenSheetState extends State<_AyakkabiBedenSheet> {
  late final List<String> _kadin;
  late final List<String> _erkek;
  late final List<String> _cocuk;

  @override
  void initState() {
    super.initState();
    _kadin = List<String>.from(widget.kadinAyakkabi);
    _erkek = List<String>.from(widget.erkekAyakkabi);
    _cocuk = List<String>.from(widget.cocukAyakkabi);
  }

  void _toggle(List<String> liste, String deger) {
    setState(() {
      liste.contains(deger) ? liste.remove(deger) : liste.add(deger);
    });
  }

  Widget _chipRow(List<String> sizes, List<String> secili) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: sizes.map((s) {
        final selected = secili.contains(s);
        return GestureDetector(
          onTap: () => _toggle(secili, s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.red : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.red : AppColors.divider,
              ),
            ),
            child: Text(
              s,
              style: _sf(
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tabIcerik(List<String> sizes, List<String> secili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: _chipRow(sizes, secili),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabSayisi = [
      widget.kadinSecili,
      widget.erkekSecili,
      widget.cocukSecili,
    ].where((v) => v).length;

    final tabs  = <Tab>[];
    final views = <Widget>[];

    if (widget.kadinSecili) {
      tabs.add(const Tab(text: 'Kadın'));
      views.add(_tabIcerik(_kAyakkabiKadin, _kadin));
    }
    if (widget.erkekSecili) {
      tabs.add(const Tab(text: 'Erkek'));
      views.add(_tabIcerik(_kAyakkabiErkek, _erkek));
    }
    if (widget.cocukSecili) {
      tabs.add(const Tab(text: 'Çocuk'));
      views.add(_tabIcerik(_kAyakkabiCocuk, _cocuk));
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.52,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: tabSayisi,
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 4, 4),
              child: Row(
                children: [
                  Text('Ayakkabı Bedeni',
                      style: _sf(fontSize: 16, color: AppColors.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onKaydet(_kadin, _erkek, _cocuk);
                      Navigator.pop(context);
                    },
                    child: Text('Tamam',
                        style: _sf(fontSize: 14, color: AppColors.red)),
                  ),
                ],
              ),
            ),
            if (tabSayisi > 1)
              TabBar(
                tabs: tabs,
                labelColor: AppColors.red,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.red,
                indicatorWeight: 2,
                labelStyle: _sf(fontSize: 14),
                unselectedLabelStyle: _sf(fontSize: 14),
              ),
            Expanded(
              child: tabSayisi == 1
                  ? views.first
                  : TabBarView(children: views),
            ),
          ],
        ),
      ),
    );
  }
}
