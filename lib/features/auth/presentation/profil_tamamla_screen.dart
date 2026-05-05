// lib/features/auth/presentation/profil_tamamla_screen.dart
//
// DEĞİŞİKLİKLER:
// - _TipKart        → ProfilTipKart        (profil_tamamla_widgets.dart)
// - _Bolum          → ProfilBolum          (profil_tamamla_widgets.dart)
// - _AutocompleteAlani → AutocompleteAlani (profil_tamamla_widgets.dart)
// - _CokluSehirAlani   → CokluSehirAlani   (profil_tamamla_widgets.dart)
// - Adım header tekrarı → ProfilAdimHeader (profil_tamamla_widgets.dart)
// - _buildAdim1..4  → private metodlar bu dosyada kalıyor ama kısa

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profil/providers/profil_provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' show kDunyaUlkeleri, kTurkiyeSehirleri;
import '../../../router/app_router.dart';
import 'profil_tamamla_widgets.dart';

class ProfilTamamlaScreen extends ConsumerStatefulWidget {
  final bool ilkGiris;
  const ProfilTamamlaScreen({super.key, this.ilkGiris = true});

  @override
  ConsumerState<ProfilTamamlaScreen> createState() =>
      _ProfilTamamlaScreenState();
}

class _ProfilTamamlaScreenState
    extends ConsumerState<ProfilTamamlaScreen> {
  final _pageCtrl   = PageController();
  int _adim         = 0;
  final int _toplamAdim = 4;

  // Form state
  String?      _kullaniciTipi;
  String       _yasadigiUlke       = '';
  final List<String> _geldigiSehirler = [];
  String       _bulunduguSehir     = '';
  final _telefonCtrl  = TextEditingController();
  final _hakkindaCtrl = TextEditingController();
  bool   _telefonGizli = false;
  bool   _yukleniyor   = false;
  String _hata         = '';

  bool get _tasiyiciMi =>
      _kullaniciTipi == 'tasiyici' || _kullaniciTipi == 'her_ikisi';
  bool get _istekMi =>
      _kullaniciTipi == 'istek' || _kullaniciTipi == 'her_ikisi';

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
      if (_tasiyiciMi && _yasadigiUlke.trim().isEmpty) {
        setState(() => _hata = 'Yaşadığınız ülkeyi girin.');
        return;
      }
      if (_tasiyiciMi && _geldigiSehirler.isEmpty) {
        setState(() => _hata = 'En az bir şehir ekleyin.');
        return;
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
    // currentUserProvider üzerinden — FirebaseAuth direkt erişim yok
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
      final data = {
        'kullaniciTipi':   _kullaniciTipi,
        'yasadigiUlke':    _tasiyiciMi ? _yasadigiUlke.trim() : '',
        'geldigiSehirler': _tasiyiciMi ? _geldigiSehirler : [],
        'bulunduguSehir':  _istekMi ? _bulunduguSehir.trim() : '',
        'hakkinda':        _hakkindaCtrl.text.trim(),
        'telefon':         _telefonCtrl.text.trim(),
        'telefonGizli':    _telefonGizli,
        'adSoyad':         user?.displayName ?? '',
        'email':           user?.email ?? '',
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
          // İlerleme çubuğu
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

          // Sayfa içeriği
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

          // Hata mesajı
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

          // Devam butonu
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
                    onTap: () => setState(
                        () => _kullaniciTipi = 'tasiyici'),
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
                    onTap: () => setState(
                        () => _kullaniciTipi = 'her_ikisi'),
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ProfilAdimHeader(
              ikon: Icons.location_on_outlined,
              baslik: 'Konum bilgisi',
              aciklama: _tasiyiciMi
                  ? "Nerede yaşıyorsun ve Türkiye'de hangi şehirlere geliyorsun?"
                  : "Türkiye'de hangi şehirdesin?",
            ),
            const SizedBox(height: 8),
            if (_tasiyiciMi) ...[
              ProfilBolum(
                baslik: 'Yaşadığın ülke *',
                ikon: Icons.public_outlined,
                child: AutocompleteAlani(
                  value: _yasadigiUlke,
                  secenekler: kDunyaUlkeleri,
                  hint: 'Ülke ara... (örn: Almanya)',
                  icon: Icons.public_outlined,
                  onSecildi: (v) =>
                      setState(() => _yasadigiUlke = v),
                ),
              ),
              const SizedBox(height: 8),
              ProfilBolum(
                baslik: "Türkiye'de geldiğin şehirler *",
                ikon: Icons.location_city_outlined,
                child: CokluSehirAlani(
                  secilenler: _geldigiSehirler,
                  secenekler: kTurkiyeSehirleri,
                  hint: 'Şehir ara... (örn: İstanbul)',
                  onEklendi: (s) {
                    if (!_geldigiSehirler.contains(s)) {
                      setState(() => _geldigiSehirler.add(s));
                    }
                  },
                  onKaldirildi: (s) =>
                      setState(() => _geldigiSehirler.remove(s)),
                ),
              ),
            ],
            if (_istekMi) ...[
              const SizedBox(height: 8),
              ProfilBolum(
                baslik: _tasiyiciMi
                    ? "Türkiye'deki şehrin (opsiyonel)"
                    : "Türkiye'deki şehrin *",
                ikon: Icons.location_on_outlined,
                child: AutocompleteAlani(
                  value: _bulunduguSehir,
                  secenekler: kTurkiyeSehirleri,
                  hint: 'Şehir ara... (örn: İstanbul)',
                  icon: Icons.location_on_outlined,
                  onSecildi: (v) =>
                      setState(() => _bulunduguSehir = v),
                ),
              ),
            ],
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
                  // Telefon gizle toggle
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
                            width: 48, height: 26,
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
                                width: 20, height: 20,
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