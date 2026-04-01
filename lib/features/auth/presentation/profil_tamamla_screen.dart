import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profil/providers/profil_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
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
  ConsumerState<ProfilTamamlaScreen> createState() =>
      _ProfilTamamlaScreenState();
}
 
class _ProfilTamamlaScreenState extends ConsumerState<ProfilTamamlaScreen> {
  String? _kullaniciTipi;
  String _yasadigiUlke = '';
  final List<String> _geldigiSehirler = [];
  String _bulunduguSehir = '';
  final _hakkindaCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  bool _telefonGizli = false;
  bool _yukleniyor = false;
  String _hata = '';
 
  @override
  void dispose() {
    _hakkindaCtrl.dispose();
    _telefonCtrl.dispose();
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
 
    setState(() { _yukleniyor = true; _hata = ''; });
 
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
 
    final data = {
      'kullaniciTipi':   _kullaniciTipi,
      'yasadigiUlke':    _tasiyiciMi ? _yasadigiUlke.trim() : '',
      'geldigiSehirler': _tasiyiciMi ? _geldigiSehirler : [],
      'bulunduguSehir':  _istekMi ? _bulunduguSehir.trim() : '',
      'hakkinda':        _hakkindaCtrl.text.trim(),
      'telefon':         _telefonCtrl.text.trim(),
      'telefonGizli':    _telefonGizli,
      'adSoyad':
          ref.read(currentUserProvider)?.displayName ?? '',
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
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          widget.ilkGiris ? 'Profilini Tamamla' : 'Profili Düzenle',
          style: GoogleFonts.dmSans(
              fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: !widget.ilkGiris,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                        color: AppColors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 32, color: AppColors.red),
                    ),
                    const SizedBox(height: 14),
                    Text('Hoş geldin!',
                        style: GoogleFonts.dmSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Sana özel deneyim için profilini tamamla.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
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
                  Text('Sen kimsin? *',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TipKart(
                          emoji: '✈️',
                          baslik: 'Yurtdışından geliyorum',
                          aciklama: "Türkiye'ye eşya getirebilirim",
                          secili: _kullaniciTipi == 'tasiyici',
                          onTap: () => setState(
                              () => _kullaniciTipi = 'tasiyici'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TipKart(
                          emoji: '🛍️',
                          baslik: 'Yurtdışından istiyorum',
                          aciklama: "Türkiye'ye getirilmesini istiyorum",
                          secili: _kullaniciTipi == 'istek',
                          onTap: () =>
                              setState(() => _kullaniciTipi = 'istek'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TipKartGenis(
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
                    Text('✈️  Taşıyıcı Bilgileri',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Text('Hangi ülkede yaşıyorsun? *',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
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
                    Text("Türkiye'de hangi şehirlere geliyorsun? *",
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _CokluSehirAlani(
                      secilenler: _geldigiSehirler,
                      secenekler: _turkiyeSehirleri,
                      hint: 'Şehir ara... (örn: İstanbul)',
                      onEklendi: (s) {
                        if (!_geldigiSehirler.contains(s)) {
                          setState(() => _geldigiSehirler.add(s));
                        }
                      },
                      onKaldirildi: (s) =>
                          setState(() => _geldigiSehirler.remove(s)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
 
            // İstek veren alanı
            if (_kullaniciTipi == 'istek' ||
                _kullaniciTipi == 'her_ikisi') ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _kullaniciTipi == 'istek'
                          ? "🛍️  Türkiye'deki Şehrin *"
                          : "📍  Türkiye'deki Şehrin",
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
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
 
            // Telefon
            if (_kullaniciTipi != null) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Telefon Numarası',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(
                        'Taşıyıcılar seninle iletişime geçebilsin (opsiyonel)',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telefonCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Örn: 05XX XXX XX XX',
                        prefixIcon: Icon(Icons.phone_outlined,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(
                          () => _telefonGizli = !_telefonGizli),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _telefonGizli
                                  ? AppColors.primary
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
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Telefon numaramı gizle',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: _telefonGizli
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary)),
                        ],
                      ),
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
                    Text('Hakkında',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Kendini kısaca tanıt (opsiyonel)',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hakkindaCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText:
                            "Örn: Almanya'da yaşıyorum, ayda bir İstanbul'a geliyorum...",
                        prefixIcon: Icon(Icons.info_outline,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
 
            // Hata
            if (_hata.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_hata,
                            style: GoogleFonts.dmSans(
                                color: AppColors.red, fontSize: 13)),
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
                  child: _yukleniyor
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.ilkGiris ? 'Devam Et' : 'Kaydet',
                          style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Tip Kartı ─────────────────────────────────────────────
 
class _TipKart extends StatelessWidget {
  final String emoji, baslik, aciklama;
  final bool secili;
  final VoidCallback onTap;
 
  const _TipKart({
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
          color: secili ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? AppColors.accent : AppColors.divider,
            width: secili ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(baslik,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: secili ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(aciklama,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: secili
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.textSecondary,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }
}
 
class _TipKartGenis extends StatelessWidget {
  final String emoji, baslik, aciklama;
  final bool secili;
  final VoidCallback onTap;
 
  const _TipKartGenis({
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
          color: secili ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? AppColors.accent : AppColors.divider,
            width: secili ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: secili
                              ? Colors.white
                              : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(aciklama,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: secili
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Autocomplete Alanı ────────────────────────────────────
 
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
      children: [
        TextField(
          controller: _ctrl,
          onChanged: (val) {
            _filtrele(val);
            widget.onSecildi(val);
          },
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon:
                Icon(widget.icon, color: AppColors.textSecondary, size: 18),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onSecildi('');
                      setState(() => _acik = false);
                    },
                  )
                : null,
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
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: _filtreli
                  .map((s) => InkWell(
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
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
 
// ── Çoklu Şehir Alanı ─────────────────────────────────────
 
class _CokluSehirAlani extends StatefulWidget {
  final List<String> secilenler, secenekler;
  final String hint;
  final ValueChanged<String> onEklendi, onKaldirildi;
 
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
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.secilenler.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.secilenler
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => widget.onKaldirildi(s),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _ctrl,
          onChanged: _filtrele,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.add_location_outlined,
                color: AppColors.textSecondary, size: 18),
          ),
        ),
        if (_acik && _filtreli.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: _filtreli
                  .map((s) => InkWell(
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
                              const Icon(Icons.add,
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
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}