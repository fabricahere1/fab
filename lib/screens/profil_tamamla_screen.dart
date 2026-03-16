import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'g_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
 
const _primary = GColors.textPrimary;
// Seçili kart rengi: koyu gri (siyah değil)
const _seciliRenk = Color(0xFF5C5C5C);
const _surface = Color(0xFFF5F5F5);
const _divider = Color(0xFFE0E0E0);
const _textPrimary = GColors.textPrimary;
const _textSecondary = Color(0xFF757575);
const _red = Color(0xFFE53935);
 
const List<String> _tumUlkeler = [
  'Afganistan', 'Almanya', 'Amerika Birleşik Devletleri', 'Arjantin',
  'Avustralya', 'Avusturya', 'Azerbaycan', 'Belçika', 'Birleşik Arap Emirlikleri',
  'Birleşik Krallık', 'Brezilya', 'Çin', 'Danimarka', 'Endonezya',
  'Fas', 'Filipinler', 'Finlandiya', 'Fransa', 'Güney Afrika', 'Güney Kore',
  'Gürcistan', 'Hindistan', 'Hollanda', 'İngiltere', 'İran', 'İrlanda',
  'İspanya', 'İsveç', 'İsviçre', 'İtalya', 'Japonya', 'Kanada',
  'Katar', 'Kazakistan', 'Kuveyt', 'Kuzey Kıbrıs', 'Lübnan', 'Macaristan',
  'Malezya', 'Meksika', 'Mısır', 'Norveç', 'Özbekistan', 'Pakistan',
  'Polonya', 'Portekiz', 'Romanya', 'Rusya', 'Suudi Arabistan',
  'Singapur', 'Tayland', 'Tunus', 'Türkmenistan', 'Ukrayna',
  'Ürdün', 'Vietnam', 'Yunanistan',
];
 
const List<String> _turkiyeSehirleri = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya',
  'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir',
  'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis',
  'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
  'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
  'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
  'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
  'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu',
  'Kayseri', 'Kilis', 'Kırıkkale', 'Kırklareli', 'Kırşehir',
  'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Mardin',
  'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye',
  'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop',
  'Şırnak', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli',
  'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
];
 
class ProfilTamamlaScreen extends StatefulWidget {
  final bool ilkGiris;
  const ProfilTamamlaScreen({super.key, this.ilkGiris = true});
 
  @override
  State<ProfilTamamlaScreen> createState() => _ProfilTamamlaScreenState();
}
 
class _ProfilTamamlaScreenState extends State<ProfilTamamlaScreen> {
  String? _kullaniciTipi;
  String _yasadigiUlke = '';
  final List<String> _geldigiSehirler = [];
  String _bulunduguSehir = '';
  final _hakkindaController = TextEditingController();
  bool _yukleniyor = false;
  String _hata = '';
 
  // Kullanıcı adı için
  String _kullaniciAdi = '';
 
  @override
  void initState() {
    super.initState();
    _mevcutVerileriYukle();
    _kullaniciAdiniAl();
  }
 
  void _kullaniciAdiniAl() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final displayName = user.displayName ?? '';
    // Sadece ilk ismi al (örn: "John Doe" → "John")
    final isim = displayName.split(' ').first;
    setState(() => _kullaniciAdi = isim);
  }
 
  Future<void> _mevcutVerileriYukle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(user.uid)
        .get();
    if (!mounted) return;
    final data = doc.data();
    if (data == null) return;
    setState(() {
      _kullaniciTipi = data['kullaniciTipi']?.toString();
      _yasadigiUlke = data['yasadigiUlke']?.toString() ?? '';
      _bulunduguSehir = data['bulunduguSehir']?.toString() ?? '';
      if (data['geldigiSehirler'] != null) {
        _geldigiSehirler.addAll(List<String>.from(data['geldigiSehirler']));
      }
      if (data['hakkinda'] != null) {
        _hakkindaController.text = data['hakkinda'];
      }
      // Firestore'dan da isim al
      final adSoyad = data['adSoyad']?.toString() ?? '';
      if (adSoyad.isNotEmpty) {
        _kullaniciAdi = adSoyad.split(' ').first;
      }
    });
  }
 
  @override
  void dispose() {
    _hakkindaController.dispose();
    super.dispose();
  }
 
  bool get _tasiyiciMi =>
      _kullaniciTipi == 'tasiyici' || _kullaniciTipi == 'her_ikisi';
  bool get _istekMi =>
      _kullaniciTipi == 'istek' || _kullaniciTipi == 'her_ikisi';
 
  Future<void> _kaydet() async {
    if (_kullaniciTipi == null) {
      setState(() => _hata = 'Lütfen kullanıcı tipini seçin.');
      return;
    }
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
        'kullaniciTipi': _kullaniciTipi,
        'yasadigiUlke': _tasiyiciMi ? _yasadigiUlke.trim() : '',
        'geldigiSehirler': _tasiyiciMi ? _geldigiSehirler : [],
        'bulunduguSehir': _istekMi ? _bulunduguSehir.trim() : '',
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
          style: GoogleFonts.dmSans(
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
            // Hoş geldin başlığı
            if (widget.ilkGiris) ...[
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 32, color: _red),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _kullaniciAdi.isNotEmpty
                          ? 'Hoş geldin, $_kullaniciAdi!'
                          : 'Hoş geldin!',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sana özel deneyim için profilini tamamla.',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: _textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
 
            // Kullanıcı tipi seçimi
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _baslik('Sen kimsin? *'),
                  const SizedBox(height: 6),
                  Text(
                    'Platformu nasıl kullanacaksın?',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: _textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TipKarti(
                          emoji: '✈️',
                          baslik: 'Yurtdışından geliyorum',
                          aciklama: 'Türkiye\'ye eşya\ngetirebilirim',
                          secili: _kullaniciTipi == 'tasiyici',
                          onTap: () => setState(
                              () => _kullaniciTipi = 'tasiyici'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TipKarti(
                          emoji: '🛍️',
                          baslik: 'Yurtdışından istiyorum',
                          aciklama: 'Türkiye\'ye getirilmesini\nistiyorum',
                          secili: _kullaniciTipi == 'istek',
                          onTap: () =>
                              setState(() => _kullaniciTipi = 'istek'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TipKartiGenis(
                    emoji: '🔄',
                    baslik: 'Her İkisi De',
                    aciklama: 'Hem getiririm hem de istek veririm',
                    secili: _kullaniciTipi == 'her_ikisi',
                    onTap: () =>
                        setState(() => _kullaniciTipi = 'her_ikisi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
 
            // Taşıyıcı alanları
            if (_tasiyiciMi) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('✈️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        _baslik('Taşıyıcı Bilgileri'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _etiket('Hangi ülkede yaşıyorsun? *'),
                    const SizedBox(height: 8),
                    _AutocompleteAlani(
                      value: _yasadigiUlke,
                      secenekler: _tumUlkeler,
                      hint: 'Ülke ara... (örn: Almanya)',
                      icon: Icons.public_outlined,
                      onSecildi: (val) =>
                          setState(() => _yasadigiUlke = val),
                    ),
                    const SizedBox(height: 16),
                    _etiket('Türkiye\'de hangi şehirlere geliyorsun? *'),
                    const SizedBox(height: 4),
                    Text(
                      'Birden fazla şehir ekleyebilirsin',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _CokluSehirAlani(
                      secilenler: _geldigiSehirler,
                      secenekler: _turkiyeSehirleri,
                      hint: 'Şehir ara... (örn: İstanbul)',
                      onEklendi: (sehir) {
                        if (!_geldigiSehirler.contains(sehir)) {
                          setState(() => _geldigiSehirler.add(sehir));
                        }
                      },
                      onKaldirildi: (sehir) =>
                          setState(() => _geldigiSehirler.remove(sehir)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
 
            // İstek veren alanları
            if (_kullaniciTipi == 'istek') ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🛍️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        _baslik('Konum Bilgisi'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _etiket('Türkiye\'de hangi şehirdesin? *'),
                    const SizedBox(height: 8),
                    _AutocompleteAlani(
                      value: _bulunduguSehir,
                      secenekler: _turkiyeSehirleri,
                      hint: 'Şehir ara... (örn: İstanbul)',
                      icon: Icons.location_on_outlined,
                      onSecildi: (val) =>
                          setState(() => _bulunduguSehir = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
 
            // Her ikisi seçiliyse
            if (_kullaniciTipi == 'her_ikisi') ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        _baslik('Türkiye\'deki Şehrin'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'İstek verirken kullanılacak (opsiyonel)',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: _textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _AutocompleteAlani(
                      value: _bulunduguSehir,
                      secenekler: _turkiyeSehirleri,
                      hint: 'Şehir ara... (örn: İstanbul)',
                      icon: Icons.location_on_outlined,
                      onSecildi: (val) =>
                          setState(() => _bulunduguSehir = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
 
            // Hakkında
            if (_kullaniciTipi != null) ...[
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
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: _textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hakkindaController,
                      maxLines: 3,
                      maxLength: 200,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Örn: Almanya\'da yaşıyorum, ayda bir İstanbul\'a geliyorum...',
                        hintStyle: GoogleFonts.dmSans(
                            color: const Color(0xFFBDBDBD), fontSize: 13),
                        prefixIcon: const Icon(Icons.info_outline,
                            color: _textSecondary, size: 18),
                        filled: true,
                        fillColor: _surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
 
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
                      const Icon(Icons.error_outline, color: _red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_hata,
                            style: GoogleFonts.dmSans(
                                color: _red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
 
            // Kaydet butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : _kaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                          widget.ilkGiris ? 'Devam Et' : 'Kaydet',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: 0.2,
        ),
      );
 
  Widget _etiket(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
      );
}
 
// ── Tip Kartı (küçük, yan yana) ──────────────────────────
 
class _TipKarti extends StatelessWidget {
  final String emoji;
  final String baslik;
  final String aciklama;
  final bool secili;
  final VoidCallback onTap;
 
  const _TipKarti({
    required this.emoji,
    required this.baslik,
    required this.aciklama,
    required this.secili,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: secili ? _seciliRenk : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? _seciliRenk : _divider,
            width: secili ? 2 : 1.5,
          ),
          boxShadow: secili
              ? [
                  BoxShadow(
                    color: _seciliRenk.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(
              baslik,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: secili ? Colors.white : _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              aciklama,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: secili
                    ? Colors.white.withValues(alpha: 0.75)
                    : _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secili ? _red : Colors.transparent,
                border: Border.all(
                  color: secili ? _red : _divider,
                  width: 2,
                ),
              ),
              child: secili
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Tip Kartı (geniş, tam genişlik) ──────────────────────
 
class _TipKartiGenis extends StatelessWidget {
  final String emoji;
  final String baslik;
  final String aciklama;
  final bool secili;
  final VoidCallback onTap;
 
  const _TipKartiGenis({
    required this.emoji,
    required this.baslik,
    required this.aciklama,
    required this.secili,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: secili ? _seciliRenk : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? _seciliRenk : _divider,
            width: secili ? 2 : 1.5,
          ),
          boxShadow: secili
              ? [
                  BoxShadow(
                    color: _seciliRenk.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: secili ? Colors.white : _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aciklama,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: secili
                          ? Colors.white.withValues(alpha: 0.75)
                          : _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secili ? _red : Colors.transparent,
                border: Border.all(
                  color: secili ? _red : _divider,
                  width: 2,
                ),
              ),
              child: secili
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Autocomplete Alanı (tek seçim) ───────────────────────
 
class _AutocompleteAlani extends StatefulWidget {
  final String value;
  final List<String> secenekler;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onSecildi;
 
  const _AutocompleteAlani({
    required this.value,
    required this.secenekler,
    required this.hint,
    required this.icon,
    required this.onSecildi,
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
  void didUpdateWidget(_AutocompleteAlani old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          onChanged: (val) {
            _filtrele(val);
            // Elle yazılanı da kaydet — listeden seçmek zorunlu değil
            widget.onSecildi(val);
          },
          onTap: () {
            if (_ctrl.text.isNotEmpty) _filtrele(_ctrl.text);
          },
          // Focus kaybedince dropdown kapat ama değeri koru
          onEditingComplete: () {
            setState(() => _acik = false);
            FocusScope.of(context).unfocus();
          },
          style: GoogleFonts.dmSans(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                GoogleFonts.dmSans(color: const Color(0xFFBDBDBD), fontSize: 14),
            prefixIcon:
                Icon(widget.icon, color: _textSecondary, size: 18),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 16, color: _textSecondary),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onSecildi('');
                      setState(() => _acik = false);
                    },
                  )
                : null,
            filled: true,
            fillColor: _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: _filtreli.map((s) {
                return InkWell(
                  onTap: () {
                    _ctrl.text = s;
                    widget.onSecildi(s);
                    setState(() => _acik = false);
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(s,
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, color: _textPrimary)),
                        ),
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
 
// ── Çoklu Şehir Alanı ────────────────────────────────────
 
class _CokluSehirAlani extends StatefulWidget {
  final List<String> secilenler;
  final List<String> secenekler;
  final String hint;
  final ValueChanged<String> onEklendi;
  final ValueChanged<String> onKaldirildi;
 
  const _CokluSehirAlani({
    required this.secilenler,
    required this.secenekler,
    required this.hint,
    required this.onEklendi,
    required this.onKaldirildi,
  });
 
  @override
  State<_CokluSehirAlani> createState() => _CokluSehirAlaniState();
}
 
class _CokluSehirAlaniState extends State<_CokluSehirAlani> {
  final _ctrl = TextEditingController();
  List<String> _filtreli = [];
  bool _acik = false;
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  void _filtrele(String q) {
    setState(() {
      _acik = q.isNotEmpty;
      _filtreli = widget.secenekler
          .where((s) =>
              s.toLowerCase().contains(q.toLowerCase()) &&
              !widget.secilenler.contains(s))
          .take(6)
          .toList();
    });
  }
 
  // Elle yazılanı ekle
  void _elleEkle() {
    final metin = _ctrl.text.trim();
    if (metin.isEmpty) return;
    if (!widget.secilenler.contains(metin)) {
      widget.onEklendi(metin);
    }
    _ctrl.clear();
    setState(() => _acik = false);
    FocusScope.of(context).unfocus();
  }
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.secilenler.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.secilenler.map((sehir) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _seciliRenk,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sehir,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => widget.onKaldirildi(sehir),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
 
        TextField(
          controller: _ctrl,
          onChanged: _filtrele,
          // Enter'a basınca elle ekle
          onSubmitted: (_) => _elleEkle(),
          textInputAction: TextInputAction.done,
          style: GoogleFonts.dmSans(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                GoogleFonts.dmSans(color: const Color(0xFFBDBDBD), fontSize: 14),
            prefixIcon: const Icon(Icons.add_location_outlined,
                color: _textSecondary, size: 18),
            // Sağda "Ekle" butonu
            suffixIcon: _ctrl.text.trim().isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: _seciliRenk, size: 22),
                    onPressed: _elleEkle,
                  )
                : null,
            filled: true,
            fillColor: _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
 
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: _filtreli.map((s) {
                return InkWell(
                  onTap: () {
                    widget.onEklendi(s);
                    _ctrl.clear();
                    setState(() => _acik = false);
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16, color: _textSecondary),
                        const SizedBox(width: 10),
                        Text(s,
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: _textPrimary)),
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