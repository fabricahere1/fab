import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';
import 'ilan_form_screen.dart' show kDunyaUlkeleri, kDunyaSehirleri;
 
class GelenlerFormScreen extends ConsumerStatefulWidget {
  const GelenlerFormScreen({super.key});
 
  @override
  ConsumerState<GelenlerFormScreen> createState() =>
      _GelenlerFormScreenState();
}
 
class _GelenlerFormScreenState extends ConsumerState<GelenlerFormScreen> {
  final _neredenCtrl = TextEditingController();
  final _nereyeCtrl = TextEditingController();
  final _ucretCtrl = TextEditingController();
  final _notlarCtrl = TextEditingController();
 
  DateTime? _seyahatTarihi;
  bool _ucretBelirtmiyorum = false;
  final Set<String> _seciliKategoriler = {};
 
  @override
  void dispose() {
    _neredenCtrl.dispose();
    _nereyeCtrl.dispose();
    _ucretCtrl.dispose();
    _notlarCtrl.dispose();
    super.dispose();
  }
 
  bool _validate() {
    if (_neredenCtrl.text.trim().isEmpty) {
      _snack('Nereden alanını doldurun.');
      return false;
    }
    if (_nereyeCtrl.text.trim().isEmpty) {
      _snack('Nereye alanını doldurun.');
      return false;
    }
    if (_seyahatTarihi == null) {
      _snack('Seyahat tarihini seçin.');
      return false;
    }
    return true;
  }
 
  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: bugun,
      firstDate: bugun,
      lastDate: bugun.add(const Duration(days: 365)),
      locale: const Locale('tr'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.red,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (secilen != null) {
      setState(() => _seyahatTarihi = secilen);
    }
  }
 
  Future<void> _ilanVer() async {
    if (!_validate()) return;
 
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _snack('Giriş yapmanız gerekiyor.');
      return;
    }
 
    final ilan = IlanModel(
      id: '',
      tip: IlanTip.tasiyici,
      nereden: _neredenCtrl.text.trim(),
      nereye: _nereyeCtrl.text.trim(),
      ucret: _ucretBelirtmiyorum ? '' : _ucretCtrl.text.trim(),
      notlar: _notlarCtrl.text.trim(),
      kategori: _seciliKategoriler.isNotEmpty
          ? _seciliKategoriler.join(',')
          : 'diger',
      kullaniciId: user.uid,
      kullaniciAd: user.displayName ?? user.email ?? '',
      tarih: _seyahatTarihi,
    );
 
    final id = await ref.read(ilanOlusturProvider.notifier).olustur(
          ilan: ilan,
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
      ref.read(tasiyiciIlanlarProvider.notifier).yenile();
    } else {
      _snack('İlan yayınlanamadı. Tekrar deneyin.');
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
 
  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(ilanOlusturProvider).yukleniyor;
 
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Taşıyıcı İlanı Ver',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
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
              // ── Nereden / Nereye ─────────────────────────
              _Bolum(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Nereden *'),
                    const SizedBox(height: 8),
                    _AutocompleteAlan(
                      controller: _neredenCtrl,
                      hint: 'Ülke veya şehir ara...',
                      icon: Icons.flight_takeoff_outlined,
                      secenekler: [
                        ...kDunyaUlkeleri,
                        ...kDunyaSehirleri
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Etiket('Nereye *'),
                    const SizedBox(height: 8),
                    _AutocompleteAlan(
                      controller: _nereyeCtrl,
                      hint: 'Ülke veya şehir ara...',
                      icon: Icons.flight_land_outlined,
                      secenekler: [
                        ...kDunyaUlkeleri,
                        ...kDunyaSehirleri
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
 
              // ── Seyahat Tarihi ────────────────────────────
              _Bolum(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Seyahat Tarihi *'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _tarihSec,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 20,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              _seyahatTarihi != null
                                  ? '${_seyahatTarihi!.day}.${_seyahatTarihi!.month}.${_seyahatTarihi!.year}'
                                  : 'Tarih seç...',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: _seyahatTarihi != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
 
              // ── Ne Getirebilirim ──────────────────────────
              _Bolum(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Ne Getirebilirim?'),
                    const SizedBox(height: 4),
                    Text('Birden fazla seçebilirsiniz',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kKategoriler.entries.map((e) {
                        final secili =
                            _seciliKategoriler.contains(e.key);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (secili) {
                              _seciliKategoriler.remove(e.key);
                            } else {
                              _seciliKategoriler.add(e.key);
                            }
                          }),
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
                              e.value,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
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
                ),
              ),
              const SizedBox(height: 8),
 
              // ── Ücret ────────────────────────────────────
              _Bolum(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Etiket('Ücret'),
                    const SizedBox(height: 8),
                    if (!_ucretBelirtmiyorum)
                      TextField(
                        controller: _ucretCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.dmSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Örn: 150',
                          hintStyle: GoogleFonts.dmSans(
                              color: AppColors.textHint, fontSize: 14),
                          prefixIcon: const Icon(
                              Icons.attach_money_outlined,
                              color: AppColors.textSecondary,
                              size: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text('₺',
                                style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 15)),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                              minWidth: 0, minHeight: 0),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.divider),
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
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _ucretBelirtmiyorum = !_ucretBelirtmiyorum;
                        if (_ucretBelirtmiyorum) _ucretCtrl.clear();
                      }),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _ucretBelirtmiyorum
                                  ? AppColors.red
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _ucretBelirtmiyorum
                                    ? AppColors.red
                                    : AppColors.divider,
                              ),
                            ),
                            child: _ucretBelirtmiyorum
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
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
 
              // ── Notlar ───────────────────────────────────
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
 
              // ── İlan Ver butonu ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: yukleniyor ? null : _ilanVer,
                    child: yukleniyor
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('İlanı Yayınla',
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
 
// ── Yardımcı Widget'lar ───────────────────────────────────
 
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
      .where((s) => !s.toLowerCase().startsWith(ql) && s.toLowerCase().contains(ql))
      .toList();
  setState(() {
    _acik = true;
    final tumSonuclar = [...baslayan, ...icerenler];
    if (tumSonuclar.length == 1) {
      _filtreli = tumSonuclar;
    } else {
      _filtreli = tumSonuclar.take(8).toList();
    }
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