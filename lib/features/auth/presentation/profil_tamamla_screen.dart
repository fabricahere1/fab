// lib/features/auth/presentation/profil_tamamla_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../router/app_router.dart';

const List<String> _tumUlkeler = [
  'Afganistan', 'Almanya', 'Amerika Birleşik Devletleri', 'Arjantin',
  'Avustralya', 'Avusturya', 'Azerbaycan', 'Belçika',
  'Birleşik Arap Emirlikleri', 'Birleşik Krallık', 'Brezilya', 'Çin',
  'Danimarka', 'Endonezya', 'Fas', 'Filipinler', 'Finlandiya', 'Fransa',
  'Güney Afrika', 'Güney Kore', 'Gürcistan', 'Hindistan', 'Hollanda',
  'İngiltere', 'İran', 'İrlanda', 'İspanya', 'İsveç', 'İsviçre', 'İtalya',
  'Japonya', 'Kanada', 'Katar', 'Kazakistan', 'Kuveyt', 'Kuzey Kıbrıs',
  'Lübnan', 'Macaristan', 'Malezya', 'Meksika', 'Mısır', 'Norveç',
  'Özbekistan', 'Pakistan', 'Polonya', 'Portekiz', 'Romanya', 'Rusya',
  'Suudi Arabistan', 'Singapur', 'Tayland', 'Tunus', 'Türkmenistan',
  'Ukrayna', 'Ürdün', 'Vietnam', 'Yunanistan',
];

const List<String> _turkiyeSehirleri = [
  'Adana', 'Ankara', 'Antalya', 'Bursa', 'Diyarbakır', 'Erzurum',
  'Eskişehir', 'Gaziantep', 'İstanbul', 'İzmir', 'Kayseri', 'Konya',
  'Malatya', 'Mersin', 'Samsun', 'Trabzon',
];

class ProfilTamamlaScreen extends ConsumerStatefulWidget {
  final bool ilkGiris;
  const ProfilTamamlaScreen({super.key, this.ilkGiris = true});

  @override
  ConsumerState<ProfilTamamlaScreen> createState() => _ProfilTamamlaScreenState();
}

class _ProfilTamamlaScreenState extends ConsumerState<ProfilTamamlaScreen> {
  final _pageCtrl = PageController();
  int _adim = 0;
  final int _toplamAdim = 4;

  String? _kullaniciTipi;
  String _yasadigiUlke = '';
  final List<String> _geldigiSehirler = [];
  String _bulunduguSehir = '';
  final _telefonCtrl = TextEditingController();
  final _hakkindaCtrl = TextEditingController();
  bool _telefonGizli = false;
  bool _yukleniyor = false;
  String _hata = '';

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
          duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      _kaydet();
    }
  }

  void _geri() {
    if (_adim > 0) {
      setState(() { _adim--; _hata = ''; });
      _pageCtrl.animateToPage(_adim,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _kaydet() async {
    setState(() { _yukleniyor = true; _hata = ''; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _yukleniyor = false; _hata = 'Oturum bulunamadı.'; });
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
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
      setState(() { _yukleniyor = false; _hata = 'Hata: $e'; });
    }
  }

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
          style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700),
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
            children: List.generate(_toplamAdim, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                color: i <= _adim ? AppColors.red : AppColors.divider,
              ),
            )),
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

          // Hata
          if (_hata.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: AppColors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_hata,
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.red)),
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
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _adim == _toplamAdim - 1 ? 'Tamamla' : 'Devam Et',
                            style: GoogleFonts.dmSans(
                                fontSize: 16, fontWeight: FontWeight.w700),
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
            // Header — kırmızı zemin beyaz ikon
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sen kimsin?',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Sana en uygun deneyimi sunmak için seçim yap.',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Bolum(
              baslik: 'Kullanım şeklini seç',
              ikon: Icons.tune_outlined,
              child: Column(
                children: [
                  _TipKart(
                    ikon: Icons.flight_takeoff_outlined,
                    baslik: 'Yurtdışından geliyorum',
                    aciklama: 'Türkiye\'ye seyahat ediyorum, yanımda eşya getirebilirim.',
                    secili: _kullaniciTipi == 'tasiyici',
                    onTap: () => setState(() { _kullaniciTipi = 'tasiyici'; _hata = ''; }),
                  ),
                  const SizedBox(height: 10),
                  _TipKart(
                    ikon: Icons.shopping_bag_outlined,
                    baslik: 'Yurtdışından istiyorum',
                    aciklama: 'Yurtdışından getirilmesini istediğim ürünler var.',
                    secili: _kullaniciTipi == 'istek',
                    onTap: () => setState(() { _kullaniciTipi = 'istek'; _hata = ''; }),
                  ),
                  const SizedBox(height: 10),
                  _TipKart(
                    ikon: Icons.sync_alt_outlined,
                    baslik: 'Her ikisi de',
                    aciklama: 'Hem taşıyıcı hem istek sahibi olarak kullanacağım.',
                    secili: _kullaniciTipi == 'her_ikisi',
                    onTap: () => setState(() { _kullaniciTipi = 'her_ikisi'; _hata = ''; }),
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
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Konum bilgisi',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          _tasiyiciMi
                              ? 'Nerede yaşıyorsun ve Türkiye\'de hangi şehirlere geliyorsun?'
                              : 'Türkiye\'de hangi şehirdesin?',
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
            if (_tasiyiciMi) ...[
              _Bolum(
                baslik: 'Yaşadığın ülke *',
                ikon: Icons.public_outlined,
                child: _AutocompleteAlani(
                  value: _yasadigiUlke,
                  secenekler: _tumUlkeler,
                  hint: 'Ülke ara... (örn: Almanya)',
                  icon: Icons.public_outlined,
                  onSecildi: (v) => setState(() => _yasadigiUlke = v),
                ),
              ),
              const SizedBox(height: 8),
              _Bolum(
                baslik: 'Türkiye\'de geldiğin şehirler *',
                ikon: Icons.location_city_outlined,
                child: _CokluSehirAlani(
                  secilenler: _geldigiSehirler,
                  secenekler: _turkiyeSehirleri,
                  hint: 'Şehir ara... (örn: İstanbul)',
                  onEklendi: (s) {
                    if (!_geldigiSehirler.contains(s)) {
                      setState(() => _geldigiSehirler.add(s));
                    }
                  },
                  onKaldirildi: (s) => setState(() => _geldigiSehirler.remove(s)),
                ),
              ),
            ],
            if (_istekMi) ...[
              const SizedBox(height: 8),
              _Bolum(
                baslik: _tasiyiciMi
                    ? 'Türkiye\'deki şehrin (opsiyonel)'
                    : 'Türkiye\'deki şehrin *',
                ikon: Icons.location_on_outlined,
                child: _AutocompleteAlani(
                  value: _bulunduguSehir,
                  secenekler: _turkiyeSehirleri,
                  hint: 'Şehir ara... (örn: İstanbul)',
                  icon: Icons.location_on_outlined,
                  onSecildi: (v) => setState(() => _bulunduguSehir = v),
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
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.phone_outlined,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('İletişim bilgisi',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('İsteğe bağlı — istersen atlayabilirsin.',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Bolum(
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
                          borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider)),
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
                    onTap: () => setState(() => _telefonGizli = !_telefonGizli),
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
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('Sadece anlaştığın kişiler görebilir',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48, height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: _telefonGizli ? AppColors.red : AppColors.divider,
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _telefonGizli
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 20, height: 20,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: Colors.white),
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
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hakkında',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('İsteğe bağlı — kendini kısaca tanıt.',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Bolum(
              baslik: 'Kendini tanıt',
              ikon: Icons.edit_outlined,
              child: TextField(
                controller: _hakkindaCtrl,
                maxLines: 5,
                maxLength: 200,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Örn: Almanya\'da yaşıyorum, ayda bir İstanbul\'a geliyorum...',
                  hintStyle: GoogleFonts.dmSans(
                      color: AppColors.textHint, fontSize: 14),
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

// ── Tip Kartı ─────────────────────────────────────────────────────────────────

class _TipKart extends StatelessWidget {
  final IconData ikon;
  final String baslik, aciklama;
  final bool secili;
  final VoidCallback onTap;

  const _TipKart({
    required this.ikon, required this.baslik,
    required this.aciklama, required this.secili, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: secili ? AppColors.red.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? AppColors.red : AppColors.divider,
            width: secili ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: secili ? AppColors.red : AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ikon,
                  size: 22,
                  color: secili ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: secili ? AppColors.red : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(aciklama,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secili ? AppColors.red : Colors.transparent,
                border: Border.all(
                    color: secili ? AppColors.red : AppColors.divider, width: 2),
              ),
              child: secili
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bölüm ─────────────────────────────────────────────────────────────────────

class _Bolum extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final Widget child;

  const _Bolum({required this.baslik, required this.ikon, required this.child});

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
              Text(baslik,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Autocomplete Alanı ────────────────────────────────────────────────────────

class _AutocompleteAlani extends StatefulWidget {
  final String value;
  final List<String> secenekler;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onSecildi;

  const _AutocompleteAlani({
    required this.value, required this.secenekler,
    required this.hint, required this.icon, required this.onSecildi,
  });

  @override
  State<_AutocompleteAlani> createState() => _AutocompleteAlaniState();
}

class _AutocompleteAlaniState extends State<_AutocompleteAlani> {
  late TextEditingController _ctrl;
  List<String> _filtreli = [];
  bool _acik = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _filtrele(String q) {
    setState(() {
      _acik = q.isNotEmpty;
      _filtreli = widget.secenekler
          .where((s) => s.toLowerCase().contains(q.toLowerCase()))
          .take(6)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          onChanged: (val) { _filtrele(val); widget.onSecildi(val); },
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
            prefixIcon: Icon(widget.icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                    onPressed: () {
                      _ctrl.clear(); widget.onSecildi('');
                      setState(() => _acik = false);
                    })
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: _filtreli.map((s) => InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  _ctrl.text = s; widget.onSecildi(s);
                  setState(() => _acik = false);
                  FocusScope.of(context).unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.red),
                      const SizedBox(width: 10),
                      Text(s, style: GoogleFonts.dmSans(fontSize: 14)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Çoklu Şehir Alanı ────────────────────────────────────────────────────────

class _CokluSehirAlani extends StatefulWidget {
  final List<String> secilenler, secenekler;
  final String hint;
  final ValueChanged<String> onEklendi, onKaldirildi;

  const _CokluSehirAlani({
    required this.secilenler, required this.secenekler,
    required this.hint, required this.onEklendi, required this.onKaldirildi,
  });

  @override
  State<_CokluSehirAlani> createState() => _CokluSehirAlaniState();
}

class _CokluSehirAlaniState extends State<_CokluSehirAlani> {
  final _ctrl = TextEditingController();
  List<String> _filtreli = [];
  bool _acik = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _filtrele(String q) {
    setState(() {
      _acik = q.isNotEmpty;
      _filtreli = widget.secenekler
          .where((s) => s.toLowerCase().contains(q.toLowerCase()) &&
              !widget.secilenler.contains(s))
          .take(6)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.secilenler.isNotEmpty) ...[
          Wrap(
            spacing: 8, runSpacing: 8,
            children: widget.secilenler.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.red, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s, style: GoogleFonts.dmSans(
                      fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => widget.onKaldirildi(s),
                    child: const Icon(Icons.close, size: 14, color: Colors.white)),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _ctrl,
          onChanged: _filtrele,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
            prefixIcon: const Icon(Icons.add_location_outlined,
                color: AppColors.textSecondary, size: 20),
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: _filtreli.map((s) => InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  widget.onEklendi(s);
                  _ctrl.clear();
                  setState(() => _acik = false);
                  FocusScope.of(context).unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(s, style: GoogleFonts.dmSans(fontSize: 14)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}