// lib/features/ilanlar/presentation/widgets/filtre_ekrani.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart';
import '../ilanlar_screen.dart';

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

            // ── Liste ────────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                children: [
                  // "Tüm X" seçeneği — ana seviyede değilsek göster
                  if (_gezinmeYolu.isNotEmpty) ...[
                    _KategoriSatiri(
                      ad: 'Tüm "$baslik" Ürünleri',
                      secili: _tumSeciliMi(),
                      onTap: _tumunuSec,
                      vurgulu: true,
                    ),
                  ],

                  // Alt kategoriler
                  ...nodes.map((node) => _KategoriSatiri(
                    ad: node.emoji.isNotEmpty
                        ? '${node.emoji}  ${node.ad}'
                        : node.ad,
                    secili: _nodeSeciliMi(node),
                    onTap: () => _nodeSecildi(node),
                    derinlikOku: !node.yaprakMi,
                  )),

                  // ── Sıralama bölümü — sadece ana seviyede göster ──────────
                  if (_gezinmeYolu.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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

class BosEkran extends StatelessWidget {
  final VoidCallback onYenile;
  const BosEkran({super.key, required this.onYenile});

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