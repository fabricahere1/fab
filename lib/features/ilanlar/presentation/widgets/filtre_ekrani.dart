// lib/features/ilanlar/presentation/widgets/filtre_ekrani.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart';
import '../ilanlar_screen.dart';

// Ana kategori local asset yolları
const _kKategoriGorseller = <String, String>{
  'giyim':      'assets/images/kategoriler/giyim.png',
  'elektronik': 'assets/images/kategoriler/elektronik.png',
  'guzellik':   'assets/images/kategoriler/guzellik.png',
  'ev':         'assets/images/kategoriler/ev.png',
  'spor':       'assets/images/kategoriler/spor.png',
  'kultur':     'assets/images/kategoriler/kultur.png',
  'gida':       'assets/images/kategoriler/gida.png',
  'diger':      'assets/images/kategoriler/diger.png',
};

// ── Filtre Ekranı ─────────────────────────────────────────────────────────────

class FiltreEkrani extends StatefulWidget {
  final List<String> seciliKategoriYolu;
  final SiralamaTipi seciliSiralama;
  final void Function(List<String> yol) onKategoriSecildi;
  final VoidCallback onTemizle;
  final ValueChanged<SiralamaTipi> onSiralamaSecildi;

  const FiltreEkrani({
    super.key,
    required this.seciliKategoriYolu,
    required this.seciliSiralama,
    required this.onKategoriSecildi,
    required this.onTemizle,
    required this.onSiralamaSecildi,
  });

  @override
  State<FiltreEkrani> createState() => _FiltreEkraniState();
}

class _FiltreEkraniState extends State<FiltreEkrani> {
  // Filtre ekranında gezinme yolu (hangi seviyedeyiz)
  List<String> _gezinmeYolu = [];
  late SiralamaTipi _seciliSiralama;

  @override
  void initState() {
    super.initState();
    _seciliSiralama = widget.seciliSiralama;
    // Eğer seçili bir yol varsa o seviyeden başla
    if (widget.seciliKategoriYolu.isNotEmpty) {
      // Son elemandan bir üst seviyede başla
      _gezinmeYolu = List<String>.from(widget.seciliKategoriYolu)
        ..removeLast();
    }
  }

  // Mevcut seviyedeki node listesi
  List<KategoriNode> _mevcutSeviyeNodes() {
    if (_gezinmeYolu.isEmpty) return kKategoriAgaci;
    List<KategoriNode> liste = kKategoriAgaci;
    for (final key in _gezinmeYolu) {
      final node = liste.firstWhere(
        (n) => n.key == key,
        orElse: () => KategoriNode(key: '', ad: ''),
      );
      if (node.key.isEmpty || node.altlar.isEmpty) break;
      liste = node.altlar;
    }
    return liste;
  }

  // Mevcut seviyenin başlığı
  String _seviyeBasligi() {
    if (_gezinmeYolu.isEmpty) return 'Kategori';
    final node = kategoriNodeBul(_gezinmeYolu.last);
    return node?.ad ?? 'Kategori';
  }

  // Breadcrumb
  String _breadcrumb() {
    if (_gezinmeYolu.isEmpty) return '';
    return _gezinmeYolu.map((key) {
      final node = kategoriNodeBul(key);
      return node?.ad ?? key;
    }).join(' › ');
  }

  void _nodeSecildi(KategoriNode node) {
    if (node.yaprakMi) {
      // En alt seviye — doğrudan seç
      final yeniYol = [..._gezinmeYolu, node.key];
      widget.onKategoriSecildi(yeniYol);
    } else {
      // Ara seviye — bir alt in
      setState(() => _gezinmeYolu = [..._gezinmeYolu, node.key]);
    }
  }

  void _tumunuSec() {
    // Mevcut seviyeyi seç (daha derine inmeden)
    widget.onKategoriSecildi(List<String>.from(_gezinmeYolu));
  }

  void _geriGit() {
    if (_gezinmeYolu.isNotEmpty) {
      setState(() => _gezinmeYolu = _gezinmeYolu.sublist(0, _gezinmeYolu.length - 1));
    }
  }

  bool _nodeSeciliMi(KategoriNode node) {
    if (widget.seciliKategoriYolu.isEmpty) return false;
    return widget.seciliKategoriYolu.contains(node.key);
  }

  bool _tumSeciliMi() {
    if (widget.seciliKategoriYolu.isEmpty) return false;
    if (_gezinmeYolu.isEmpty) return false;
    // Mevcut seviye seçiliyse (daha alt seçim yoksa)
    return widget.seciliKategoriYolu.length == _gezinmeYolu.length &&
        widget.seciliKategoriYolu.last == _gezinmeYolu.last;
  }

  @override
  Widget build(BuildContext context) {
    final nodes      = _mevcutSeviyeNodes();
    final breadcrumb = _breadcrumb();
    final baslik     = _seviyeBasligi();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  if (_gezinmeYolu.isNotEmpty)
                    GestureDetector(
                      onTap: _geriGit,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back_ios_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      baslik,
                      style: GoogleFonts.dmSans(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.seciliKategoriYolu.isNotEmpty)
                    GestureDetector(
                      onTap: widget.onTemizle,
                      child: Text('Temizle',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Breadcrumb
            if (breadcrumb.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                color: AppColors.surface,
                child: Text(
                  breadcrumb,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // ── Liste / Grid ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: _gezinmeYolu.isEmpty
                    ? const EdgeInsets.fromLTRB(14, 14, 14, 0)
                    : EdgeInsets.zero,
                children: [
                  // Ana seviyede: 2'li görsel grid
                  if (_gezinmeYolu.isEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: nodes.length,
                      itemBuilder: (_, i) {
                        final node   = nodes[i];
                        final secili = _nodeSeciliMi(node);
                        final imgUrl = _kKategoriGorseller[node.key] ?? '';
                        return GestureDetector(
                          onTap: () => _nodeSecildi(node),
                          child: Container(
                            decoration: BoxDecoration(
                              color: secili
                                  ? AppColors.red.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: secili ? AppColors.red : const Color(0xFFEEEEEE),
                                width: secili ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: [
                                // Kategori adı
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Text(
                                      node.ad,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: secili
                                            ? AppColors.red
                                            : AppColors.textPrimary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                // Ürün görseli — şeffaf arka planlı local asset
                                if (imgUrl.isNotEmpty)
                                  Container(
                                    width: 88,
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(
                                      imgUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => Center(
                                        child: Text(
                                          node.emoji,
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Alt seviyelerde: klasik liste
                  if (_gezinmeYolu.isNotEmpty) ...[
                    _KategoriSatiri(
                      ad: 'Tüm "$baslik" Ürünleri',
                      secili: _tumSeciliMi(),
                      onTap: _tumunuSec,
                      vurgulu: true,
                    ),
                    ...nodes.map((node) => _KategoriSatiri(
                      ad: node.emoji.isNotEmpty
                          ? '${node.emoji}  ${node.ad}'
                          : node.ad,
                      secili: _nodeSeciliMi(node),
                      onTap: () => _nodeSecildi(node),
                      derinlikOku: !node.yaprakMi,
                    )),
                  ],

                  // ── Sıralama bölümü — sadece ana seviyede göster ──────────
                  if (_gezinmeYolu.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.divider),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text('Sıralama',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    ...SiralamaTipi.values.map((tip) {
                      final secili = _seciliSiralama == tip;
                      return InkWell(
                        onTap: () {
                          setState(() => _seciliSiralama = tip);
                          widget.onSiralamaSecildi(tip);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: secili
                                ? AppColors.red.withValues(alpha: 0.05)
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                tip == SiralamaTipi.enYeni
                                    ? Icons.schedule_outlined
                                    : tip == SiralamaTipi.enEski
                                        ? Icons.history_outlined
                                        : tip == SiralamaTipi.enCokFavorilenen
                                            ? Icons.favorite_border
                                            : Icons.verified_outlined,
                                size: 22,
                                color: secili
                                    ? AppColors.red
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  tip.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: secili
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: secili
                                        ? AppColors.red
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (secili)
                                const Icon(Icons.check,
                                    size: 16, color: AppColors.red),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KategoriSatiri extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;
  final bool derinlikOku;
  final bool vurgulu;

  const _KategoriSatiri({
    required this.ad,
    required this.secili,
    required this.onTap,
    this.derinlikOku = false,
    this.vurgulu = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: secili
              ? AppColors.red.withValues(alpha: 0.05)
              : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ad,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: (secili || vurgulu)
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: secili
                      ? AppColors.red
                      : vurgulu
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
                ),
              ),
            ),
            if (secili)
              const Icon(Icons.check, size: 16, color: AppColors.red)
            else if (derinlikOku)
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Boş Ekranlar ──────────────────────────────────────────────────────────────

class FiltreBosBekran extends StatelessWidget {
  final VoidCallback onTemizle;
  const FiltreBosBekran({super.key, required this.onTemizle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_outlined,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Sonuç bulunamadı',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Filtre veya aramayı temizlemeyi deneyin',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onTemizle,
            child: Text('Filtreyi Temizle',
                style: GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class IlanBosEkran extends StatelessWidget {
  final VoidCallback onYenile;
  const IlanBosEkran({super.key, required this.onYenile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Henüz ilan yok',
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('İlk ilanı sen ver!',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onYenile,
            child: Text('Yenile',
                style: GoogleFonts.dmSans(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}