import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
 
const _primary = Color(0xFF3C3C3C);
const _surface = Color(0xFFF5F5F5);
const _divider = Color(0xFFE0E0E0);
const _textPrimary = Color(0xFF212121);
const _textSecondary = Color(0xFF757575);
const _red = Color(0xFFE53935);
 
class IlanOlusturPage extends StatefulWidget {
  final int initialTip;
  final VoidCallback? onSuccess;
  const IlanOlusturPage({super.key, this.initialTip = 1, this.onSuccess});
 
  @override
  State<IlanOlusturPage> createState() => _IlanOlusturPageState();
}
 
class _IlanOlusturPageState extends State<IlanOlusturPage> {
  late int _tip;
 
  final _neredenController = TextEditingController();
  final _nereyeController = TextEditingController();
  final _ucretController = TextEditingController();
  final _urunController = TextEditingController();
  final _notlarController = TextEditingController();
 
  DateTime? _secilenTarih;
  bool _yukleniyor = false;
  File? _secilenResim;
 
  bool _neredenFarketmez = false;
 
  @override
  void initState() {
    super.initState();
    _tip = widget.initialTip;
  }
 
  @override
  void dispose() {
    _neredenController.dispose();
    _nereyeController.dispose();
    _ucretController.dispose();
    _urunController.dispose();
    _notlarController.dispose();
    super.dispose();
  }
 
  Future<void> _tarihSec() async {
    final simdi = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _secilenTarih ?? simdi,
      firstDate: simdi,
      lastDate: DateTime(simdi.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
          ),
          child: child!,
        );
      },
    );
    if (secilen != null) {
      setState(() => _secilenTarih = secilen);
    }
  }
 
  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _secilenResim = File(picked.path));
    }
  }
 
  Future<void> _ilanOlustur() async {
    final nereden = _neredenFarketmez
        ? 'Farketmez'
        : _neredenController.text.trim();
    final nereye = _nereyeController.text.trim();
 
    if (nereden.isEmpty || nereye.isEmpty) {
      _snackbar('Nereden ve Nereye alanları zorunludur.', hata: true);
      return;
    }
    if (_tip == 1 && _urunController.text.trim().isEmpty) {
      _snackbar('Ürün adı zorunludur.', hata: true);
      return;
    }
 
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snackbar('İlan vermek için giriş yapmalısınız.', hata: true);
      return;
    }
 
    setState(() => _yukleniyor = true);
 
    try {
      debugPrint('İLAN OLUSTURULUYOR...');
 
      final kullaniciDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .get();
      final kullaniciAd = kullaniciDoc.data()?['adSoyad'] ??
          user.displayName ??
          user.email?.split('@')[0] ??
          'Kullanıcı';
 
      String? resimUrl;
      if (_tip == 1 && _secilenResim != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('ilan_resimleri')
            .child(
                '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_secilenResim!);
        resimUrl = await ref.getDownloadURL();
      }
 
      await FirebaseFirestore.instance.collection('ilanlar').add({
        'tip': _tip == 0 ? 'tasiyici' : 'istek',
        'nereden': nereden,
        'nereye': nereye,
        'ucret': _ucretController.text.trim(),
        'urun': _urunController.text.trim(),
        'notlar': _notlarController.text.trim(),
        'tarih': _secilenTarih != null
            ? Timestamp.fromDate(_secilenTarih!)
            : null,
        'kullaniciId': user.uid,
        'kullaniciAd': kullaniciAd,
        'aktif': true,
        'olusturmaTarihi': FieldValue.serverTimestamp(),
        if (resimUrl != null) 'resimUrl': resimUrl,
      });
 
      debugPrint('İLAN FIRESTORE\'A YAZILDI');
 
      if (mounted) {
        final ilanTip = _tip == 0 ? 'tasiyici' : 'istek';
        debugPrint('mounted: true, ilanTip: $ilanTip');
        debugPrint('onSuccess: ${widget.onSuccess}');
 
        if (widget.onSuccess != null) {
          _snackbar('İlan başarıyla oluşturuldu!');
          _formuTemizle();
          widget.onSuccess!();
        } else {
          debugPrint('Navigator.pop çağrılıyor...');
          Navigator.pop(context, ilanTip);
        }
      } else {
        debugPrint('mounted: false — Navigator.pop çağrılamadı!');
      }
    } catch (e, stack) {
      debugPrint('İlan oluşturma hatası: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        _snackbar('Hata: $e', hata: true);
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }
 
  void _formuTemizle() {
    _neredenController.clear();
    _nereyeController.clear();
    _ucretController.clear();
    _urunController.clear();
    _notlarController.clear();
    setState(() {
      _secilenTarih = null;
      _secilenResim = null;
      _neredenFarketmez = false;
    });
  }
 
  void _snackbar(String mesaj, {bool hata = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj,
            style: GoogleFonts.roboto(color: Colors.white)),
        backgroundColor: hata ? _red : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _divider,
        title: Text(
          'İlan Ver',
          style: GoogleFonts.roboto(
            color: _textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _divider),
                ),
                child: Row(
                  children: [
                    _TipButon(
                      label: '🛍️  İstek var',
                      secili: _tip == 1,
                      onTap: () => setState(() => _tip = 1),
                    ),
                    _TipButon(
                      label: '✈️  Gelenler',
                      secili: _tip == 0,
                      onTap: () => setState(() => _tip = 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
 
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Nereden',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _neredenFarketmez
                                    ? _textPrimary
                                    : _textSecondary,
                              ),
                              child: const Text('Farketmez'),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _neredenFarketmez = !_neredenFarketmez;
                                  if (_neredenFarketmez) {
                                    _neredenController.clear();
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                width: 44,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _neredenFarketmez
                                      ? _textPrimary
                                      : const Color(0xFFE0E0E0),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  alignment: _neredenFarketmez
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_neredenFarketmez)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: _surface,
                          border: Border.all(color: _divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flight_takeoff_outlined,
                                color: _textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Nereden gelirse gelsin',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: _textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _Alan(
                        label: '',
                        showLabel: false,
                        controller: _neredenController,
                        hint: 'Örn: New York',
                        icon: Icons.flight_takeoff_outlined,
                        sehirAutocomplete: true,
                      ),
                    const SizedBox(height: 14),
                    _Alan(
                      label: 'Nereye',
                      controller: _nereyeController,
                      hint: 'Örn: İstanbul',
                      icon: Icons.flight_land_outlined,
                      sehirAutocomplete: true,
                    ),
                    if (_tip == 1) ...[
                      const SizedBox(height: 14),
                      _Alan(
                        label: 'Ürün',
                        controller: _urunController,
                        hint: 'Örn: Spor ayakkabı',
                        icon: Icons.shopping_bag_outlined,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Ürün Resmi',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _resimSec,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: _surface,
                            border: Border.all(color: _divider),
                          ),
                          child: _secilenResim != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_secilenResim!,
                                        fit: BoxFit.cover),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _secilenResim = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white,
                                              size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 32,
                                        color: _textSecondary),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ürün resmi ekle',
                                      style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          color: _textSecondary),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _Alan(
                      label: 'Ücret (₺) — isteğe bağlı',
                      controller: _ucretController,
                      hint: 'Belirtmek istemiyorum',
                      icon: Icons.payments_outlined,
                      klavye: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _tip == 0 ? 'Geliş Tarihi' : 'Son Tarih',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _tarihSec,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: _surface,
                          border: Border.all(color: _divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: _textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _secilenTarih != null
                                  ? '${_secilenTarih!.day}.${_secilenTarih!.month}.${_secilenTarih!.year}'
                                  : 'Tarih seç',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: _secilenTarih != null
                                    ? _textPrimary
                                    : const Color(0xFFBDBDBD),
                              ),
                            ),
                            const Spacer(),
                            if (_secilenTarih != null)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _secilenTarih = null),
                                child: const Icon(Icons.close,
                                    color: _textSecondary, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Alan(
                      label: 'Notlar (isteğe bağlı)',
                      controller: _notlarController,
                      hint: 'Ek bilgi ekleyin...',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
 
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : _ilanOlustur,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA5D6A7),
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
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
                          'İlanı Yayınla',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
 
// ── Tip Buton ──────────────────────────────────────────────
 
class _TipButon extends StatelessWidget {
  final String label;
  final bool secili;
  final VoidCallback onTap;
 
  const _TipButon({
    required this.label,
    required this.secili,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: secili ? const Color(0xFFE0E0E0) : Colors.white,
            border: Border(
              bottom: BorderSide(
                  color: secili
                      ? const Color(0xFF9E9E9E)
                      : Colors.transparent,
                  width: 2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
              color: secili ? _textPrimary : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
 
// ── Şehir Listesi ──────────────────────────────────────────
 
const List<String> _sehirler = [
  'İstanbul (Türkiye)', 'Ankara (Türkiye)', 'İzmir (Türkiye)',
  'Bursa (Türkiye)', 'Antalya (Türkiye)', 'Adana (Türkiye)',
  'Konya (Türkiye)', 'Gaziantep (Türkiye)', 'Mersin (Türkiye)',
  'Trabzon (Türkiye)', 'Kayseri (Türkiye)', 'Eskişehir (Türkiye)',
  'Diyarbakır (Türkiye)', 'Samsun (Türkiye)', 'Denizli (Türkiye)',
  'Londra (İngiltere)', 'Manchester (İngiltere)',
  'Birmingham (İngiltere)', 'Edinburgh (İngiltere)',
  'Bristol (İngiltere)',
  'Paris (Fransa)', 'Lyon (Fransa)', 'Marsilya (Fransa)', 'Nice (Fransa)',
  'Berlin (Almanya)', 'Münih (Almanya)', 'Frankfurt (Almanya)',
  'Hamburg (Almanya)', 'Düsseldorf (Almanya)', 'Stuttgart (Almanya)',
  'Madrid (İspanya)', 'Barselona (İspanya)', 'Valencia (İspanya)',
  'Sevilla (İspanya)',
  'Roma (İtalya)', 'Milano (İtalya)', 'Napoli (İtalya)',
  'Venedik (İtalya)', 'Floransa (İtalya)',
  'Amsterdam (Hollanda)', 'Rotterdam (Hollanda)', 'La Haye (Hollanda)',
  'Viyana (Avusturya)', 'Salzburg (Avusturya)',
  'Brüksel (Belçika)', 'Antwerp (Belçika)',
  'Zürih (İsviçre)', 'Cenevre (İsviçre)', 'Bern (İsviçre)',
  'Prag (Çekya)', 'Varşova (Polonya)', 'Budapeşte (Macaristan)',
  'Stockholm (İsveç)', 'Oslo (Norveç)', 'Kopenhag (Danimarka)',
  'Helsinki (Finlandiya)', 'Dublin (İrlanda)', 'Lizbon (Portekiz)',
  'Atina (Yunanistan)', 'Lüksemburg (Lüksemburg)',
  'New York (ABD)', 'Los Angeles (ABD)', 'Chicago (ABD)',
  'Houston (ABD)', 'Miami (ABD)', 'Las Vegas (ABD)',
  'San Francisco (ABD)', 'Seattle (ABD)', 'Boston (ABD)',
  'Washington DC (ABD)', 'Dallas (ABD)', 'Atlanta (ABD)',
  'Denver (ABD)', 'Phoenix (ABD)', 'Detroit (ABD)',
  'Toronto (Kanada)', 'Montreal (Kanada)', 'Vancouver (Kanada)',
  'Calgary (Kanada)', 'Ottawa (Kanada)',
  'Mexico City (Meksika)', 'Cancun (Meksika)',
  'Dubai (BAE)', 'Abu Dhabi (BAE)', 'Doha (Katar)',
  'Riyad (Suudi Arabistan)', 'Cidde (Suudi Arabistan)',
  'Kuveyt (Kuveyt)', 'Muskat (Umman)', 'Beyrut (Lübnan)',
  'Amman (Ürdün)', 'Tel Aviv (İsrail)',
  'Tokyo (Japonya)', 'Osaka (Japonya)', 'Seoul (Güney Kore)',
  'Pekin (Çin)', 'Şanghay (Çin)', 'Hong Kong (Çin)',
  'Singapur (Singapur)', 'Bangkok (Tayland)',
  'Kuala Lumpur (Malezya)', 'Jakarta (Endonezya)',
  'Manila (Filipinler)', 'Mumbai (Hindistan)',
  'Delhi (Hindistan)', 'Bangalore (Hindistan)',
  'Karaçi (Pakistan)', 'Dakka (Bangladeş)', 'Colombo (Sri Lanka)',
  'Taşkent (Özbekistan)', 'Almatı (Kazakistan)',
  'Bişkek (Kırgızistan)', 'Bakü (Azerbaycan)',
  'Tiflis (Gürcistan)', 'Yerevan (Ermenistan)',
  'Tahran (İran)', 'Bağdat (Irak)', 'Kahire (Mısır)',
  'Tunus (Tunus)', 'Kazablanka (Fas)', 'Cezayir (Cezayir)',
  'Lagos (Nijerya)', 'Nairobi (Kenya)',
  'Johannesburg (Güney Afrika)', 'Cape Town (Güney Afrika)',
  'Accra (Gana)',
  'Sydney (Avustralya)', 'Melbourne (Avustralya)',
  'Brisbane (Avustralya)', 'Auckland (Yeni Zelanda)',
  'São Paulo (Brezilya)', 'Rio de Janeiro (Brezilya)',
  'Buenos Aires (Arjantin)', 'Bogota (Kolombiya)',
  'Lima (Peru)', 'Santiago (Şili)', 'Caracas (Venezuela)',
];
 
// ── Form Alanı ──────────────────────────────────────────────
 
class _Alan extends StatefulWidget {
  final String label;
  final bool showLabel;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType klavye;
  final int maxLines;
  final bool sehirAutocomplete;
 
  const _Alan({
    required this.label,
    this.showLabel = true,
    required this.controller,
    required this.hint,
    required this.icon,
    this.klavye = TextInputType.text,
    this.maxLines = 1,
    this.sehirAutocomplete = false,
  });
 
  @override
  State<_Alan> createState() => _AlanState();
}
 
class _AlanState extends State<_Alan> {
  TextEditingController? _fieldController;
 
  @override
  void dispose() {
    _fieldController?.dispose();
    super.dispose();
  }
 
  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
          color: const Color(0xFFBDBDBD), fontSize: 14),
      prefixIcon: Icon(icon, color: _textSecondary, size: 18),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 14),
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
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (widget.sehirAutocomplete)
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue value) {
              if (value.text.length < 2) return const [];
              final query = value.text.toLowerCase();
              return _sehirler.where(
                (s) => s.toLowerCase().contains(query),
              );
            },
            onSelected: (String secilen) {
              widget.controller.text = secilen;
            },
            fieldViewBuilder:
                (context, fieldController, focusNode, onSubmit) {
              if (_fieldController == null) {
                _fieldController = fieldController;
                fieldController.text = widget.controller.text;
                fieldController.addListener(() {
                  widget.controller.text = fieldController.text;
                });
              }
              return TextField(
                controller: fieldController,
                focusNode: focusNode,
                onEditingComplete: onSubmit,
                style: GoogleFonts.roboto(
                    fontSize: 14, color: _textPrimary),
                decoration: _decoration(widget.hint, widget.icon),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxHeight: 200, maxWidth: 320),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 16, color: _textSecondary),
                                const SizedBox(width: 8),
                                Text(option,
                                    style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: _textPrimary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
        else
          TextField(
            controller: widget.controller,
            keyboardType: widget.klavye,
            maxLines: widget.maxLines,
            style: GoogleFonts.roboto(fontSize: 14, color: _textPrimary),
            decoration: _decoration(widget.hint, widget.icon),
          ),
      ],
    );
  }
}