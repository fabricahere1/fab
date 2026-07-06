// lib/features/profil/presentation/profil_duzenle_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' show kDunyaUlkeleri, kTurkiyeSehirleri, turkceKarsilastir;
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/widgets/autocomplete_alan.dart';

const _kIlgiKategoriler = [
  ('kadin_giyim', '👗 Kadın Giyim'),
  ('erkek_giyim', '👔 Erkek Giyim'),
  ('cocuk_giyim', '🧸 Çocuk Giyim'),
  ('elektronik',  '📱 Elektronik'),
  ('ev',          '🏠 Ev'),
];

const _kKadinUstHarf    = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
const _kKadinUstNumarik = ['34', '36', '38', '40', '42', '44'];
const _kKadinAltNumarik = ['34', '36', '38', '40', '42', '44'];
const _kKadinAltHarf    = ['XS', 'S', 'M', 'L', 'XL'];
const _kErkekBeden      = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
const _kAyakkabiKadin   = ['36', '37', '38', '39', '40', '41', '42'];
const _kAyakkabiErkek   = ['38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48'];
const _kAyakkabiCocuk   = ['25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35'];

class ProfilDuzenleScreen extends ConsumerStatefulWidget {
  const ProfilDuzenleScreen({super.key});

  @override
  ConsumerState<ProfilDuzenleScreen> createState() => _ProfilDuzenleScreenState();
}

class _ProfilDuzenleScreenState extends ConsumerState<ProfilDuzenleScreen> {
  final _adSoyadCtrl        = TextEditingController();
  final _telefonCtrl        = TextEditingController();
  final _hakkindaCtrl       = TextEditingController();
  final _yasadigiUlkeCtrl   = TextEditingController();
  final _bulunduguSehirCtrl = TextEditingController();

  bool _yukleniyor   = false;
  bool _veriYuklendi = false;

  // Kategori & beden
  final List<String> _ilgiKategorileri = [];
  final List<String> _kadinUstBeden    = [];
  final List<String> _kadinAltBeden    = [];
  final List<String> _erkekUstBeden    = [];
  final List<String> _erkekAltBeden    = [];
  final List<String> _kadinAyakkabi    = [];
  final List<String> _erkekAyakkabi    = [];
  final List<String> _cocukAyakkabi    = [];

  bool get _kadinGiyimSecili => _ilgiKategorileri.contains('kadin_giyim');
  bool get _erkekGiyimSecili => _ilgiKategorileri.contains('erkek_giyim');
  bool get _cocukGiyimSecili => _ilgiKategorileri.contains('cocuk_giyim');
  bool get _herhangiGiyimSecili => _kadinGiyimSecili || _erkekGiyimSecili || _cocukGiyimSecili;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    _adSoyadCtrl.dispose();
    _telefonCtrl.dispose();
    _hakkindaCtrl.dispose();
    _yasadigiUlkeCtrl.dispose();
    _bulunduguSehirCtrl.dispose();
    super.dispose();
  }

  void _verileriYukle() {
    final profil = ref.read(benimKullaniciProfilProvider).value;
    if (profil != null) {
      _adSoyadCtrl.text        = profil.adSoyad;
      _telefonCtrl.text        = profil.telefon ?? '';
      _hakkindaCtrl.text       = profil.hakkinda;
      _yasadigiUlkeCtrl.text   = profil.yasadigiUlke;
      _bulunduguSehirCtrl.text = profil.bulunduguSehir;
      _ilgiKategorileri.addAll(profil.ilgiKategorileri);
      _kadinUstBeden.addAll(profil.kadinUstBeden);
      _kadinAltBeden.addAll(profil.kadinAltBeden);
      _erkekUstBeden.addAll(profil.erkekUstBeden);
      _erkekAltBeden.addAll(profil.erkekAltBeden);
      _kadinAyakkabi.addAll(profil.kadinAyakkabi);
      _erkekAyakkabi.addAll(profil.erkekAyakkabi);
      _cocukAyakkabi.addAll(profil.cocukAyakkabi);
      setState(() => _veriYuklendi = true);
    }
  }

  void _kategoriToggle(String key) {
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

  void _bedenToggle(List<String> liste, String deger) {
    setState(() {
      if (liste.contains(deger)) {
        liste.remove(deger);
      } else {
        liste.add(deger);
      }
    });
  }

  Future<void> _kaydet() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    if (_adSoyadCtrl.text.trim().isEmpty) {
      AppSnackBar.hata(context, 'Ad soyad boş bırakılamaz.');
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      await ref.read(profilDuzenleProvider.notifier).profilGuncelle(
        uid: uid,
        data: {
          'adSoyad':          _adSoyadCtrl.text.trim(),
          'telefon':          _telefonCtrl.text.trim(),
          'hakkinda':         _hakkindaCtrl.text.trim(),
          'yasadigiUlke':     _yasadigiUlkeCtrl.text.trim(),
          'bulunduguSehir':   _bulunduguSehirCtrl.text.trim(),
          'ilgiKategorileri': _ilgiKategorileri,
          'kadinUstBeden':    _kadinUstBeden,
          'kadinAltBeden':    _kadinAltBeden,
          'erkekUstBeden':    _erkekUstBeden,
          'erkekAltBeden':    _erkekAltBeden,
          'kadinAyakkabi':    _kadinAyakkabi,
          'erkekAyakkabi':    _erkekAyakkabi,
          'cocukAyakkabi':    _cocukAyakkabi,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.basari(context, 'Profil güncellendi!');
    } catch (e) {
      if (mounted) AppSnackBar.hata(context, 'Bir hata oluştu. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(benimKullaniciProfilProvider, (_, next) {
      if (_veriYuklendi) return;
      next.whenData((profil) {
        if (profil == null) return;
        _adSoyadCtrl.text        = profil.adSoyad;
        _telefonCtrl.text        = profil.telefon ?? '';
        _hakkindaCtrl.text       = profil.hakkinda;
        _yasadigiUlkeCtrl.text   = profil.yasadigiUlke;
        _bulunduguSehirCtrl.text = profil.bulunduguSehir;
          _ilgiKategorileri.addAll(profil.ilgiKategorileri);
        _kadinUstBeden.addAll(profil.kadinUstBeden);
        _kadinAltBeden.addAll(profil.kadinAltBeden);
        _erkekUstBeden.addAll(profil.erkekUstBeden);
        _erkekAltBeden.addAll(profil.erkekAltBeden);
        _kadinAyakkabi.addAll(profil.kadinAyakkabi);
        _erkekAyakkabi.addAll(profil.erkekAyakkabi);
        _cocukAyakkabi.addAll(profil.cocukAyakkabi);
        setState(() => _veriYuklendi = true);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Profili Düzenle',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _yukleniyor ? null : _kaydet,
            child: _yukleniyor
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red))
                : Text('Kaydet', style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Kişisel Bilgiler ──────────────────────────────────────────
              _Bolum(
                baslik: 'Kişisel Bilgiler',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Ad Soyad *'),
                    const SizedBox(height: 8),
                    _Alan(controller: _adSoyadCtrl, hint: 'Adınız ve soyadınız', icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    _Etiket('Hakkında'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hakkindaCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      decoration: _dekorasyon(hint: 'Kendinizi kısaca tanıtın...', icon: Icons.info_outline),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── İletişim ──────────────────────────────────────────────────
              _Bolum(
                baslik: 'İletişim',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Telefon'),
                    const SizedBox(height: 8),
                    _Alan(controller: _telefonCtrl, hint: '05XX XXX XX XX', icon: Icons.phone_outlined, klavye: TextInputType.phone),
                    const SizedBox(height: 6),
                    Text(
                      'Numaranın görünürlüğünü Ayarlar > Numarayı Gizle\'den yönetebilirsin.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Konum ─────────────────────────────────────────────────────
              _Bolum(
                baslik: 'Konum',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Yaşadığım Ülke'),
                    const SizedBox(height: 8),
                    AutocompleteAlan(
                      controller: _yasadigiUlkeCtrl,
                      hint: 'Ülke ara...',
                      icon: Icons.public_outlined,
                      secenekler: kDunyaUlkeleri,
                    ),
                    const SizedBox(height: 16),
                    _Etiket('Türkiye\'deki Şehrim'),
                    const SizedBox(height: 8),
                    AutocompleteAlan(
                      controller: _bulunduguSehirCtrl,
                      hint: 'Şehir ara...',
                      icon: Icons.location_on_outlined,
                      secenekler: ([...kTurkiyeSehirleri]..sort(turkceKarsilastir)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── İlgi Kategorileri ─────────────────────────────────────────
              _Bolum(
                baslik: 'İlgi Kategorileri',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('En çok ne tür ürünlerle ilgilenirsin?',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kIlgiKategoriler.map((entry) {
                        final (key, label) = entry;
                        final secili = _ilgiKategorileri.contains(key);
                        return GestureDetector(
                          onTap: () => _kategoriToggle(key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: secili ? AppColors.red : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: secili ? AppColors.red : AppColors.divider,
                                width: secili ? 1.5 : 1,
                              ),
                            ),
                            child: Text(label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: secili ? Colors.white : AppColors.textPrimary)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // ── Beden Bilgileri ───────────────────────────────────────────
              if (_herhangiGiyimSecili) ...[
                const SizedBox(height: 8),
                _Bolum(
                  baslik: 'Beden Bilgileri',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_kadinGiyimSecili) ...[
                        _BedenBaslik('👗 Kadın Üst Beden'),
                        const SizedBox(height: 8),
                        _BedenSecici(liste: [..._kKadinUstHarf, ..._kKadinUstNumarik], secili: _kadinUstBeden, onToggle: (v) => _bedenToggle(_kadinUstBeden, v)),
                        const SizedBox(height: 14),
                        _BedenBaslik('👗 Kadın Alt Beden'),
                        const SizedBox(height: 8),
                        _BedenSecici(liste: [..._kKadinAltNumarik, ..._kKadinAltHarf], secili: _kadinAltBeden, onToggle: (v) => _bedenToggle(_kadinAltBeden, v)),
                        const SizedBox(height: 14),
                        _BedenBaslik('👠 Kadın Ayakkabı'),
                        const SizedBox(height: 8),
                        _BedenSecici(liste: _kAyakkabiKadin, secili: _kadinAyakkabi, onToggle: (v) => _bedenToggle(_kadinAyakkabi, v)),
                        const SizedBox(height: 14),
                      ],
                      if (_erkekGiyimSecili) ...[
                        _BedenBaslik('👔 Erkek Üst Beden'),
                        const SizedBox(height: 8),
                        _BedenSecici(liste: _kErkekBeden, secili: _erkekUstBeden, onToggle: (v) => _bedenToggle(_erkekUstBeden, v)),
                        const SizedBox(height: 14),
                        _BedenBaslik('👔 Erkek Alt Beden'),
                        const SizedBox(height: 8),
                        _BedenSecici(liste: _kErkekBeden, secili: _erkekAltBeden, onToggle: (v) => _bedenToggle(_erkekAltBeden, v)),
                        const SizedBox(height: 14),
                        _BedenBaslik('👟 Erkek Ayakkabı'),
                        const SizedBox(height: 8),
                        _BedenSecici(liste: _kAyakkabiErkek, secili: _erkekAyakkabi, onToggle: (v) => _bedenToggle(_erkekAyakkabi, v)),
                      ],
                      if (_cocukGiyimSecili) ...[
                        if (_kadinGiyimSecili || _erkekGiyimSecili) const SizedBox(height: 14),
                        _BedenBaslik('🧸 Çocuk Ayakkabı'),
                        const SizedBox(height: 8),
                        _BedenSecici(liste: _kAyakkabiCocuk, secili: _cocukAyakkabi, onToggle: (v) => _bedenToggle(_cocukAyakkabi, v)),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dekorasyon({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────────────────────────

class _Bolum extends StatelessWidget {
  final String baslik;
  final Widget child;
  const _Bolum({required this.baslik, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  final String text;
  const _Etiket(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }
}

class _BedenBaslik extends StatelessWidget {
  final String text;
  const _BedenBaslik(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }
}

class _BedenSecici extends StatelessWidget {
  final List<String> liste;
  final List<String> secili;
  final void Function(String) onToggle;
  const _BedenSecici({required this.liste, required this.secili, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: liste.map((b) {
        final sec = secili.contains(b);
        return GestureDetector(
          onTap: () => onToggle(b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48, height: 36,
            decoration: BoxDecoration(
              color: sec ? AppColors.red : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sec ? AppColors.red : AppColors.divider),
            ),
            alignment: Alignment.center,
            child: Text(b, style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: sec ? Colors.white : AppColors.textPrimary)),
          ),
        );
      }).toList(),
    );
  }
}

class _Alan extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType klavye;
  const _Alan({required this.controller, required this.hint, required this.icon, this.klavye = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: klavye,
      style: GoogleFonts.dmSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}