// lib/features/ilanlar/presentation/widgets/gelenler_filtre_ekrani.dart
//
// gelenler_screen.dart'ın eski showModalBottomSheet (alttan açılan) filtre
// popup'ının yerine geçen, ilanlar_screen.dart + FiltreEkrani ile aynı
// mimariyi paylaşan, tam sayfa + sağdan slide ile açılan filtre ekranı.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart' as app_constants;
import '../../../../shared/widgets/turkiye_disi_arama_ekrani.dart';
import '../../../../shared/widgets/sehir_secim_widget.dart';

// ── Filtre sonuç veri sınıfı ──────────────────────────────────────────────────

class GelenlerFiltreSecimi {
  final List<String> kategoriYolu;
  final List<String> altKeyler;
  final app_constants.SiralamaTipi siralama;
  final List<String> sehirler;
  final String ulkeSehir;

  const GelenlerFiltreSecimi({
    required this.kategoriYolu,
    required this.altKeyler,
    required this.siralama,
    required this.sehirler,
    required this.ulkeSehir,
  });
}

// ── Açılış yardımcısı ─────────────────────────────────────────────────────────

void gelenlerFiltreAc({
  required BuildContext context,
  required List<String> seciliKategoriYolu,
  required List<String> seciliAltKeyler,
  required app_constants.SiralamaTipi seciliSiralama,
  required List<String> seciliSehirler,
  required String seciliUlkeSehir,
  required Map<String, int> kategoriFacets,
  required void Function(GelenlerFiltreSecimi secim) onUygula,
  required VoidCallback onTemizle,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0), end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(
        position: slide,
        child: Material(
          color: Colors.transparent,
          child: GelenlerFiltreEkrani(
            seciliKategoriYolu: seciliKategoriYolu,
            seciliAltKeyler: seciliAltKeyler,
            seciliSiralama: seciliSiralama,
            seciliSehirler: seciliSehirler,
            seciliUlkeSehir: seciliUlkeSehir,
            kategoriFacets: kategoriFacets,
            onUygula: onUygula,
            onTemizle: onTemizle,
          ),
        ),
      );
    },
  );
}

// ── Filtre Ekranı ─────────────────────────────────────────────────────────────

class GelenlerFiltreEkrani extends StatefulWidget {
  final List<String> seciliKategoriYolu;
  final List<String> seciliAltKeyler;
  final app_constants.SiralamaTipi seciliSiralama;
  final List<String> seciliSehirler;
  final String seciliUlkeSehir;
  final Map<String, int> kategoriFacets;
  final void Function(GelenlerFiltreSecimi secim) onUygula;
  final VoidCallback onTemizle;

  const GelenlerFiltreEkrani({
    super.key,
    required this.seciliKategoriYolu,
    required this.seciliAltKeyler,
    required this.seciliSiralama,
    required this.seciliSehirler,
    required this.seciliUlkeSehir,
    required this.kategoriFacets,
    required this.onUygula,
    required this.onTemizle,
  });

  @override
  State<GelenlerFiltreEkrani> createState() => _GelenlerFiltreEkraniState();
}

class _GelenlerFiltreEkraniState extends State<GelenlerFiltreEkrani> {
  late List<String> _modalKategoriYolu;
  late List<String> _modalAltKeyler;
  late app_constants.SiralamaTipi _modalSiralama;
  late List<String> _modalSehirler;
  late String _modalUlkeSehir;

  @override
  void initState() {
    super.initState();
    _modalKategoriYolu = List<String>.from(widget.seciliKategoriYolu);
    _modalAltKeyler    = List<String>.from(widget.seciliAltKeyler);
    _modalSiralama     = widget.seciliSiralama;
    _modalSehirler     = List<String>.from(widget.seciliSehirler);
    _modalUlkeSehir    = widget.seciliUlkeSehir;
  }

  bool get _herhangiSecildi =>
      _modalKategoriYolu.isNotEmpty ||
      _modalAltKeyler.isNotEmpty ||
      _modalSehirler.isNotEmpty ||
      _modalUlkeSehir.isNotEmpty ||
      _modalSiralama != app_constants.SiralamaTipi.enYeni;

  void _temizle() {
    Navigator.pop(context);
    widget.onTemizle();
  }

  void _uygula() {
    Navigator.pop(context);
    widget.onUygula(GelenlerFiltreSecimi(
      kategoriYolu: _modalKategoriYolu,
      altKeyler:    _modalAltKeyler,
      siralama:     _modalSiralama,
      sehirler:     _modalSehirler,
      ulkeSehir:    _modalUlkeSehir,
    ));
  }

  Future<void> _anaKategoriTiklandi(app_constants.KategoriNode node) async {
    if (node.yaprakMi) {
      setState(() {
        _modalKategoriYolu = [node.key];
        _modalAltKeyler    = [];
      });
      return;
    }

    final altSecim = await showGeneralDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, _, _) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0), end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: Material(
            color: Colors.transparent,
            child: _AltKategoriSayfasi(
              anaNode: node,
              mevcutSecim: _modalKategoriYolu.isNotEmpty &&
                      _modalKategoriYolu.first == node.key
                  ? _modalAltKeyler
                  : const [],
            ),
          ),
        );
      },
    );

    if (altSecim != null) {
      setState(() {
        _modalKategoriYolu = [node.key];
        _modalAltKeyler    = altSecim;
      });
    }
  }

  Future<void> _ulkeSehirSec() async {
    final sonuc = await Navigator.push<String>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) =>
            TurkiyeDisiAramaEkrani(mevcutSecim: _modalUlkeSehir),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (sonuc != null) {
      setState(() => _modalUlkeSehir = sonuc == '__temizle__' ? '' : sonuc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ilanSayilari = widget.kategoriFacets;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Sabit başlık ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  Text('Kategoriler',
                      style: GoogleFonts.dmSans(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  if (_herhangiSecildi)
                    GestureDetector(
                      onTap: _temizle,
                      child: Text('Temizle',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppColors.red,
                              fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // ── Scrollable içerik ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      // Ana kategori listesi
                      ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        children: app_constants.kKategoriAgaci.map((node) {
                          final secili = _modalKategoriYolu.isNotEmpty &&
                              _modalKategoriYolu.first == node.key;
                          final altSecimVar = secili && _modalAltKeyler.isNotEmpty;
                          return _FiltreKategoriSatiri(
                            ad: node.ad,
                            ikon: gelenlerKategoriIkon(node.key),
                            secili: secili,
                            derinlikOku: !node.yaprakMi,
                            ilanSayisi: ilanSayilari[node.key] ?? 0,
                            altBilgi: altSecimVar
                                ? '${_modalAltKeyler.length} alt kategori seçili'
                                : null,
                            onTap: () => _anaKategoriTiklandi(node),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Sıralama',
                            style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                        child: _GSiralamaSegmented(
                          secili: _modalSiralama,
                          onSecim: (tip) => setState(() => _modalSiralama = tip),
                        ),
                      ),

                      const Divider(height: 24),

                      SehirSecimBolumu(
                        baslik: 'Varış Şehri',
                        seciliSehirler: _modalSehirler,
                        onDegisti: (yeni) => setState(() => _modalSehirler = yeni),
                        renk: AppColors.red,
                        sagWidget: GestureDetector(
                          onTap: _ulkeSehirSec,
                          child: Text(
                            _modalUlkeSehir.isNotEmpty
                                ? _modalUlkeSehir
                                : 'Türkiye dışı',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _uygula,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Uygula',
                                style: GoogleFonts.dmSans(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filtre Kategori Satırı ────────────────────────────────────────────────────

class _FiltreKategoriSatiri extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;
  final bool derinlikOku;
  final bool vurgulu;
  final int? ilanSayisi;
  final String? altBilgi;
  final IconData? ikon;

  const _FiltreKategoriSatiri({
    required this.ad,
    required this.secili,
    required this.onTap,
    this.derinlikOku = false,
    this.vurgulu = false,
    this.ilanSayisi,
    this.altBilgi,
    this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: secili ? AppColors.red.withValues(alpha: 0.05) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (ikon != null) ...[
              Icon(ikon, size: 18,
                  color: secili ? AppColors.red : AppColors.textSecondary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        ad,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: (secili || vurgulu) ? FontWeight.w600 : FontWeight.w400,
                          color: secili ? AppColors.red : AppColors.textPrimary,
                        ),
                      ),
                      if (ilanSayisi != null && ilanSayisi! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '($ilanSayisi)',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (altBilgi != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      altBilgi!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: AppColors.red)
            else if (derinlikOku)
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Alt Kategori Tam Sayfa ────────────────────────────────────────────────────

class _AltKategoriSayfasi extends StatefulWidget {
  final app_constants.KategoriNode anaNode;
  final List<String> mevcutSecim;

  const _AltKategoriSayfasi({
    required this.anaNode,
    required this.mevcutSecim,
  });

  @override
  State<_AltKategoriSayfasi> createState() => _AltKategoriSayfasiState();
}

class _AltKategoriSayfasiState extends State<_AltKategoriSayfasi> {
  late List<String> _gezinmeYolu;
  late List<String> _seciliKeyler;

  @override
  void initState() {
    super.initState();
    _gezinmeYolu  = [widget.anaNode.key];
    _seciliKeyler = List<String>.from(widget.mevcutSecim);
  }

  List<app_constants.KategoriNode> _mevcutNodes() {
    List<app_constants.KategoriNode> liste = app_constants.kKategoriAgaci;
    for (final key in _gezinmeYolu) {
      final node = liste.firstWhere(
        (n) => n.key == key,
        orElse: () => app_constants.KategoriNode(key: '', ad: ''),
      );
      if (node.key.isEmpty || node.altlar.isEmpty) break;
      liste = node.altlar;
    }
    return liste;
  }

  String _baslik() =>
      app_constants.kategoriNodeBul(_gezinmeYolu.last)?.ad ?? '';

  void _geriGit() {
    if (_gezinmeYolu.length > 1) {
      setState(() => _gezinmeYolu = _gezinmeYolu.sublist(0, _gezinmeYolu.length - 1));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _mevcutNodes();

    return PopScope(
      canPop: _gezinmeYolu.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _geriGit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                size: 18, color: AppColors.textPrimary),
            onPressed: _geriGit,
          ),
          title: Text(
            _baslik(),
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          actions: [
            if (_seciliKeyler.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _seciliKeyler.clear()),
                child: Text('Temizle',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.red,
                        fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: ListView(
                  children: [
                    _FiltreKategoriSatiri(
                      ad: 'Tüm "${_baslik()}" Ürünleri',
                      secili: _seciliKeyler.isEmpty,
                      vurgulu: true,
                      onTap: () => Navigator.pop(context, <String>[]),
                    ),
                    ...nodes.map((node) => _FiltreKategoriSatiri(
                      ad: node.ad,
                      secili: _seciliKeyler.contains(node.key),
                      derinlikOku: !node.yaprakMi,
                      onTap: () {
                        if (node.yaprakMi) {
                          setState(() {
                            if (_seciliKeyler.contains(node.key)) {
                              _seciliKeyler.remove(node.key);
                            } else {
                              _seciliKeyler.add(node.key);
                            }
                          });
                        } else {
                          setState(() => _gezinmeYolu = [..._gezinmeYolu, node.key]);
                        }
                      },
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _seciliKeyler),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _seciliKeyler.isEmpty
                    ? 'Tümünü Göster'
                    : '${_seciliKeyler.length} kategori seçildi',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gelenler Sıralama Segmented ───────────────────────────────────────────────

class _GSiralamaSegmented extends StatelessWidget {
  final app_constants.SiralamaTipi secili;
  final ValueChanged<app_constants.SiralamaTipi> onSecim;

  const _GSiralamaSegmented({
    required this.secili,
    required this.onSecim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: app_constants.SiralamaTipi.values.map((tip) {
          final seciliMi = secili == tip;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSecim(tip),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: seciliMi ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: seciliMi
                      ? Border.all(color: const Color(0xFFE0E0E0), width: 0.5)
                      : null,
                ),
                child: Text(
                  tip.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: seciliMi ? FontWeight.w600 : FontWeight.w400,
                    color: seciliMi ? AppColors.red : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

IconData gelenlerKategoriIkon(String key) {
  switch (key) {
    case 'kadin':       return Symbols.face_3;
    case 'erkek':       return Symbols.face;
    case 'cocuk':       return Symbols.face_retouching_natural;
    case 'ev':          return Symbols.cottage;
    case 'elektronik':  return Symbols.headphones;
    case 'supplement':  return Symbols.vaccines;
    default:            return Symbols.package_2;
  }
}