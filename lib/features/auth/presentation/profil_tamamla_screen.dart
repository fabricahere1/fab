// lib/features/auth/presentation/profil_tamamla_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profil/providers/profil_provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' show kTurkiyeSehirleri;
import '../../../router/app_router.dart';
import 'profil_tamamla_widgets.dart';

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
  final int _toplamAdim = 4;

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

  late final List<String> _sortedTurkiyeSehirleri;

  bool get _tasiyiciMi =>
      _kullaniciTipi == 'tasiyici' || _kullaniciTipi == 'her_ikisi';
  bool get _istekMi =>
      _kullaniciTipi == 'istek' || _kullaniciTipi == 'her_ikisi';

  @override
  void initState() {
    super.initState();
    _sortedTurkiyeSehirleri = [...kTurkiyeSehirleri]
    ..sort((a, b) {
      const tr = {
        'ç': 'c', 'ğ': 'g', 'ı': 'i',
        'ö': 'o', 'ş': 's', 'ü': 'u',
        'Ç': 'C', 'Ğ': 'G', 'İ': 'I',
        'Ö': 'O', 'Ş': 'S', 'Ü': 'U',
      };
      String norm(String s) =>
          s.splitMapJoin('', onNonMatch: (c) => tr[c] ?? c);
      return norm(a).compareTo(norm(b));
    });
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
        if (_dutyFreeIlgileniyor == null) {
          setState(() => _hata = 'Duty Free tercihini belirtin.');
          return;
        }
      }
      if (_istekMi && !_tasiyiciMi && _bulunduguSehir.trim().isEmpty) {
        setState(() => _hata = 'Bulunduğunuz şehri girin.');
        return;
      }
    }
    if (_adim < _toplamAdim - 1) {
      setState(() => _adim++);
      _pageCtrl.animateToPage(_adim,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    } else {
      _kaydet();
    }
  }

  void _geri() {
    if (_adim > 0) {
      setState(() {
        _adim--;
        _hata = '';
      });
      _pageCtrl.animateToPage(_adim,
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
        'dutyFreeIlgileniyor': _tasiyiciMi ? (_dutyFreeIlgileniyor ?? false) : null,
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

  void _ilSecimAc(ValueChanged<String> onSecildi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TekSecimSheet(
        baslik: 'Şehir seçin',
        secenekler: _sortedTurkiyeSehirleri,
        secilen: _secilenIlTurkiye,
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
          style: GoogleFonts.dmSans(
              fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_adim + 1}/$_toplamAdim',
                  style: GoogleFonts.dmSans(
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
                  color: i <= _adim ? AppColors.red : AppColors.divider,
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
                        style: GoogleFonts.dmSans(
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
                            _adim == _toplamAdim - 1
                                ? 'Tamamla'
                                : 'Devam Et',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          if (_adim < _toplamAdim - 1) ...[
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
    final dutyFreeGoster = _turkiyedeMi != null &&
        (_turkiyedeMi!
            ? _secilenIlTurkiye.isNotEmpty
            : _secilenUlkeYurtdisi.isNotEmpty);

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
                      (v) => setState(() => _secilenIlTurkiye = v)),
                  onTemizle: () => setState(() {
                    _secilenIlTurkiye = '';
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

            // Duty Free sorusu
            if (dutyFreeGoster) ...[
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

  Widget _buildAdim2Istek() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ProfilAdimHeader(
              ikon: Icons.location_on_outlined,
              baslik: 'Konum bilgisi',
              aciklama: "Türkiye'de hangi şehirdesin?",
            ),
            const SizedBox(height: 8),
            ProfilBolum(
              baslik: "Türkiye'deki şehrin *",
              ikon: Icons.location_on_outlined,
              child: AutocompleteAlani(
                value: _bulunduguSehir,
                secenekler: kTurkiyeSehirleri,
                hint: 'Şehir ara... (örn: İstanbul)',
                icon: Icons.location_on_outlined,
                onSecildi: (v) => setState(() => _bulunduguSehir = v),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Adım 3: İletişim ─────────────────────────────────────────────────────────

  Widget _buildAdim3() {
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
                    style: GoogleFonts.dmSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Örn: 05XX XXX XX XX',
                      hintStyle: GoogleFonts.dmSans(
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
                                    style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('Sadece anlaştığın kişiler görebilir',
                                    style: GoogleFonts.dmSans(
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

  // ── Adım 4: Hakkında ─────────────────────────────────────────────────────────

  Widget _buildAdim4() {
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
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      "Örn: Almanya'da yaşıyorum, ayda bir İstanbul'a geliyorum...",
                  hintStyle: GoogleFonts.dmSans(
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
                style: GoogleFonts.dmSans(
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
                              style: GoogleFonts.dmSans(
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
              style: GoogleFonts.dmSans(
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
                      style: GoogleFonts.dmSans(fontSize: 14)),
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
                        style: GoogleFonts.dmSans(
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
                        style: GoogleFonts.dmSans(
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
      style: GoogleFonts.dmSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Ara...',
        hintStyle:
            GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
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