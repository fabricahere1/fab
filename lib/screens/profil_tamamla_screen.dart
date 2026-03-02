import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

const _primary = Color(0xFF3C3C3C);
const _surface = Color(0xFFF5F5F5);
const _divider = Color(0xFFE0E0E0);
const _textPrimary = Color(0xFF212121);
const _textSecondary = Color(0xFF757575);
const _red = Color(0xFFE53935);

// Sık gidilen ülkeler listesi
const List<String> _ulkeler = [
  'Almanya', 'Amerika Birleşik Devletleri', 'Amsterdam', 'Avustralya',
  'Avusturya', 'Azerbaycan', 'Belçika', 'Birleşik Arap Emirlikleri',
  'Çin', 'Danimarka', 'Fransa', 'Gürcistan', 'Hollanda', 'İngiltere',
  'İspanya', 'İsveç', 'İsviçre', 'İtalya', 'Japonya', 'Kanada',
  'Katar', 'Kuzey Kıbrıs', 'Norveç', 'Polonya', 'Portekiz',
  'Romanya', 'Rusya', 'Suudi Arabistan', 'Türkiye', 'Ukrayna',
  'Yunanistan',
];

class ProfilTamamlaScreen extends StatefulWidget {
  final bool ilkGiris;
  const ProfilTamamlaScreen({super.key, this.ilkGiris = true});

  @override
  State<ProfilTamamlaScreen> createState() => _ProfilTamamlaScreenState();
}

class _ProfilTamamlaScreenState extends State<ProfilTamamlaScreen> {
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _hakkindaController = TextEditingController();
  final List<String> _secilenUlkeler = [];
  bool _yukleniyor = false;
  String _hata = '';

  @override
  void initState() {
    super.initState();
    // Email'i Google'dan al
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _telefonController.dispose();
    _hakkindaController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    // Validasyon
    if (_emailController.text.trim().isEmpty) {
      setState(() => _hata = 'Email adresi zorunludur.');
      return;
    }
    if (_telefonController.text.trim().isEmpty) {
      setState(() => _hata = 'Telefon numarası zorunludur.');
      return;
    }
    if (_secilenUlkeler.isEmpty) {
      setState(() => _hata = 'En az bir ülke seçiniz.');
      return;
    }

    setState(() {
      _yukleniyor = true;
      _hata = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .set({
        'email': _emailController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'gittigiUlkeler': _secilenUlkeler,
        'hakkinda': _hakkindaController.text.trim(),
        'adSoyad': user.displayName ?? '',
        'profilTamamlandi': true,
        'guncellemeTarihi': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _hata = 'Bir hata oluştu. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _ulkeToggle(String ulke) {
    setState(() {
      if (_secilenUlkeler.contains(ulke)) {
        _secilenUlkeler.remove(ulke);
      } else {
        _secilenUlkeler.add(ulke);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: _divider,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: !widget.ilkGiris,
        title: Text(
          widget.ilkGiris ? 'Profilini Tamamla' : 'Profili Düzenle',
          style: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.ilkGiris) ...[
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.person_add_outlined,
                        size: 48, color: _red),
                    const SizedBox(height: 12),
                    Text(
                      'Hoş geldin! 👋',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Devam etmek için profilini tamamla.',
                      style: GoogleFonts.roboto(
                          fontSize: 14, color: _textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Form alanları
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _baslik('İletişim Bilgileri'),
                  const SizedBox(height: 16),

                  // Email
                  _etiket('Email *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: _textPrimary),
                    decoration: _inputDecoration(
                        'ornek@email.com', Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),

                  // Telefon
                  _etiket('Telefon *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _telefonController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: _textPrimary),
                    decoration: _inputDecoration(
                        '+90 5XX XXX XX XX', Icons.phone_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Ülkeler
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _baslik('En Çok Gittiğin Ülkeler *'),
                  const SizedBox(height: 6),
                  Text(
                    'Türkiye\'ye en sık hangi ülkelerden geliyorsun?',
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: _textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ulkeler.map((ulke) {
                      final secili = _secilenUlkeler.contains(ulke);
                      return GestureDetector(
                        onTap: () => _ulkeToggle(ulke),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: secili ? _primary : _surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: secili ? _primary : _divider,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            ulke,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: secili
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: secili ? Colors.white : _textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Hakkında
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _baslik('Hakkında'),
                  const SizedBox(height: 6),
                  Text(
                    'Kendini kısaca tanıt (opsiyonel)',
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: _textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hakkindaController,
                    maxLines: 3,
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: _textPrimary),
                    decoration: _inputDecoration(
                      'Örn: Sık seyahat eden biri olarak...',
                      Icons.info_outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hata mesajı
            if (_hata.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: _red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_hata,
                            style: GoogleFonts.roboto(
                                color: _red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

            // Kaydet butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : _kaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _yukleniyor
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.ilkGiris
                              ? 'Devam Et'
                              : 'Kaydet',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baslik(String text) => Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: 0.3,
        ),
      );

  Widget _etiket(String text) => Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.roboto(color: const Color(0xFFBDBDBD), fontSize: 14),
        prefixIcon: Icon(icon, color: _textSecondary, size: 18),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      );
}