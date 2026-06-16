// lib/features/ilanlar/presentation/widgets/filtre_ekrani.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart';
import '../ilanlar_screen.dart';

// Türkiye'nin 81 ili
const kTurkiyeSehirleri = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya',
  'Artvin', 'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu',
  'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır',
  'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
  'Gümüşhane', 'Hakkari', 'Hatay', 'Isparta', 'İçel (Mersin)', 'İstanbul',
  'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir', 'Kocaeli',
  'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla',
  'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Rize', 'Sakarya', 'Samsun', 'Siirt',
  'Sinop', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Şanlıurfa',
  'Uşak', 'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt', 'Karaman',
  'Kırıkkale', 'Batman', 'Şırnak', 'Bartın', 'Ardahan', 'Iğdır', 'Yalova',
  'Karabük', 'Kilis', 'Osmaniye', 'Düzce',
];

// ── Filtre sonuç veri sınıfı ──────────────────────────────────────────────────

class FiltreSecimi {
  final List<String> kategoriYolu;
  final SiralamaTipi siralama;
  final List<String> istekSehirleri;

  const FiltreSecimi({
    required this.kategoriYolu,
    required this.siralama,
    required this.istekSehirleri,
  });
}

// ── Filtre Ekranı ─────────────────────────────────────────────────────────────

class FiltreEkrani extends StatefulWidget {
  final List<String> seciliKategoriYolu;
  final SiralamaTipi seciliSiralama;
  final List<String> seciliIstekSehirleri;
  final void Function(FiltreSecimi secim) onUygula;
  final VoidCallback onTemizle;

  const FiltreEkrani({
    super.key,
    required this.seciliKategoriYolu,
    required this.seciliSiralama,
    this.seciliIstekSehirleri = const [],
    required this.onUygula,
    required this.onTemizle,
  });

  @override
  State<FiltreEkrani> createState() => _FiltreEkraniState();
}

class _FiltreEkraniState extends State<FiltreEkrani> {
  // _gezinmeYolu boşken → ana sayfa (grid + sıralama + şehir + Göster)
  // _gezinmeYolu doluyken → alt kategori listesi + Seç butonu
  List<String>  _gezinmeYolu   = [];
  // Alt kategori sayfasında geçici seçim (Seç'e basılınca _modalKategori'ye kopyalanır)
  List<String>  _geciciKategori = [];
  late List<String>  _modalKategori;
  late SiralamaTipi  _modalSiralama;
  late List<String>  _modalSehirler;

  static const _turuncu = Color(0xFFFF6600);

  @override
  void initState() {
    super.initState();
    _modalKategori  = List.from(widget.seciliKategoriYolu);
    _geciciKategori = List.from(widget.seciliKategoriYolu);
    _modalSiralama  = widget.seciliSiralama;
    _modalSehirler  = List.from(widget.seciliIstekSehirleri);
    // Eğer önceden seçim varsa gezinme yolunu başlat
    if (widget.seciliKategoriYolu.isNotEmpty) {
      _gezinmeYolu = [];  // Ana sayfadan başla her zaman
    }
  }

  bool get _altSayfada => _gezinmeYolu.isNotEmpty;

  bool get _herhangiSecildi =>
      _modalKategori.isNotEmpty ||
      _modalSiralama != SiralamaTipi.enYeni ||
      _modalSehirler.isNotEmpty;

  // Göster butonundaki özet metin
  String get _gosterMetni {
    final parcalar = <String>[];
    if (_modalKategori.isNotEmpty) {
      parcalar.add(kategoriYoluMetni(_modalKategori));
    }
    if (_modalSiralama != SiralamaTipi.enYeni) {
      parcalar.add(_modalSiralama.label);
    }
    if (_modalSehirler.isNotEmpty) {
      parcalar.add(_modalSehirler.length == 1
          ? _modalSehirler.first
          : '${_modalSehirler.length} şehir');
    }
    if (parcalar.isEmpty) return 'Göster';
    return 'Göster  ·  ${parcalar.join(' · ')}';
  }

  List<KategoriNode> _mevcutNodes() {
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

  String _seviyeBasligi() {
    if (_gezinmeYolu.isEmpty) return 'Kategoriler';
    return kategoriNodeBul(_gezinmeYolu.last)?.ad ?? 'Kategori';
  }

  String _breadcrumb() {
    if (_gezinmeYolu.isEmpty) return '';
    return _gezinmeYolu
        .map((key) => kategoriNodeBul(key)?.ad ?? key)
        .join(' › ');
  }

  // Ana grid'den bir kategoriye tıklanınca
  void _anaKategoriTiklandi(KategoriNode node) {
    if (node.yaprakMi) {
      // Direkt yaprak — gecici seçim yap ve ana sayfada göster
      setState(() {
        _geciciKategori = [node.key];
        _modalKategori  = [node.key];
      });
    } else {
      // Alt kategorileri olan — alt sayfaya geç
      setState(() {
        _gezinmeYolu    = [node.key];
        _geciciKategori = List.from(_modalKategori); // mevcut seçimi koru
      });
    }
  }

  // Alt sayfada bir kategoriye tıklanınca
  void _altKategoriTiklandi(KategoriNode node) {
    if (node.yaprakMi) {
      setState(() => _geciciKategori = [..._gezinmeYolu, node.key]);
    } else {
      setState(() {
        _gezinmeYolu = [..._gezinmeYolu, node.key];
      });
    }
  }

  // "Seç" butonuna basınca — gecici seçimi kalıcı yap, ana sayfaya dön
  void _secimOnayla() {
    setState(() {
      _modalKategori = List.from(_geciciKategori);
      _gezinmeYolu   = [];
    });
  }

  // Alt sayfada "Tüm X Ürünleri" seçilince
  void _tumunuSec() {
    setState(() => _geciciKategori = List.from(_gezinmeYolu));
  }

  bool _altNodeSeciliMi(KategoriNode node) => _geciciKategori.contains(node.key);

  bool _tumSeciliMi() {
    if (_geciciKategori.isEmpty || _gezinmeYolu.isEmpty) return false;
    return _geciciKategori.length == _gezinmeYolu.length &&
        _geciciKategori.last == _gezinmeYolu.last;
  }

  bool get _geciciSecimVar => _geciciKategori.isNotEmpty &&
      _geciciKategori.first == _gezinmeYolu.first;

  // Ana kategori kartı için turuncu alt metin (seçili alt kategori varsa)
  String? _kartSecimMetni(KategoriNode anaNode) {
    if (_modalKategori.isEmpty) return null;
    if (!_modalKategori.contains(anaNode.key)) {
      // Bu ana kategorinin alt keylerinde seçim var mı?
      final altKeyler = tumAltKeyler(anaNode.key);
      final seciliAlt = _modalKategori.lastOrNull;
      if (seciliAlt == null) return null;
      if (!altKeyler.contains(seciliAlt) && _modalKategori.first != anaNode.key) return null;
      if (_modalKategori.first != anaNode.key) return null;
    }
    if (_modalKategori.first != anaNode.key) return null;

    if (_modalKategori.length == 1) return 'Tümü seçili';
    final seciliKey = _modalKategori.last;
    final seciliNode = kategoriNodeBul(seciliKey);
    return seciliNode?.ad ?? seciliKey;
  }

  void _sehirDialogAc() async {
    List<String> temp = List.from(_modalSehirler);
    await showDialog<void>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('İstek Şehri',
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            height: 340,
            child: ListView(
              children: [
                CheckboxListTile(
                  dense: true,
                  title: Text('Tümü', style: GoogleFonts.dmSans(fontSize: 14)),
                  value: temp.isEmpty,
                  activeColor: _turuncu,
                  onChanged: (v) {
                    if (v == true) setDlg(() => temp.clear());
                  },
                ),
                ...kTurkiyeSehirleri.map((s) => CheckboxListTile(
                  dense: true,
                  title: Text(s, style: GoogleFonts.dmSans(fontSize: 14)),
                  value: temp.contains(s),
                  activeColor: _turuncu,
                  onChanged: (v) {
                    setDlg(() => v == true ? temp.add(s) : temp.remove(s));
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: Text('İptal',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                setState(() => _modalSehirler = List.from(temp));
                Navigator.pop(dlgCtx);
              },
              child: Text('Tamam',
                  style: GoogleFonts.dmSans(
                      color: _turuncu, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes      = _mevcutNodes();
    final breadcrumb = _breadcrumb();
    final baslik     = _seviyeBasligi();
    final anaGorunu  = !_altSayfada;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  if (!anaGorunu)
                    GestureDetector(
                      onTap: () {
                        if (_gezinmeYolu.length > 1) {
                          setState(() => _gezinmeYolu =
                              _gezinmeYolu.sublist(0, _gezinmeYolu.length - 1));
                        } else {
                          // En üst alt seviyedeyiz — ana sayfaya dön, geçici seçimi iptal et
                          setState(() {
                            _gezinmeYolu    = [];
                            _geciciKategori = List.from(_modalKategori);
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back_ios_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      baslik,
                      style: anaGorunu
                          ? const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)
                          : GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_herhangiSecildi)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _modalKategori = [];
                          _modalSiralama = SiralamaTipi.enYeni;
                          _modalSehirler = [];
                          _gezinmeYolu   = [];
                        });
                        widget.onTemizle();
                      },
                      child: Text('Temizle',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: _turuncu,
                              fontWeight: FontWeight.w500)),
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

            if (breadcrumb.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: AppColors.surface,
                child: Text(breadcrumb,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),

            // ── İçerik ────────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: anaGorunu
                    ? const EdgeInsets.fromLTRB(14, 14, 14, 0)
                    : EdgeInsets.zero,
                children: [
                  // Ana seviye: 2'li grid
                  if (anaGorunu)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.55,
                      ),
                      itemCount: nodes.length,
                      itemBuilder: (_, i) => _buildAnaKart(nodes[i], onTap: () => _anaKategoriTiklandi(nodes[i])),
                    ),

                  // Alt seviye: liste
                  if (!anaGorunu) ...[
                    _KategoriSatiri(
                      ad: 'Tüm "$baslik" Ürünleri',
                      secili: _tumSeciliMi(),
                      onTap: _tumunuSec,
                      vurgulu: true,
                      renk: _turuncu,
                    ),
                    ...nodes.map((node) => _KategoriSatiri(
                          ad: node.emoji.isNotEmpty
                              ? '${node.emoji}  ${node.ad}'
                              : node.ad,
                          secili: _altNodeSeciliMi(node),
                          onTap: () => _altKategoriTiklandi(node),
                          derinlikOku: !node.yaprakMi,
                          renk: _turuncu,
                        )),
                  ],

                  // ── Sıralama (sadece ana görünümde) ─────────────────────────
                  if (anaGorunu) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text('Sıralama',
                          style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SiralamaTipi.values.map((tip) {
                          final secili = _modalSiralama == tip;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _modalSiralama = tip),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: secili
                                    ? _turuncu.withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: secili
                                      ? _turuncu
                                      : const Color(0xFFE0E0E0),
                                  width: secili ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                tip.label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: secili
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: secili
                                      ? _turuncu
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── İstek Şehri ──────────────────────────────────────────
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Text('İstek Şehri',
                              style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const Spacer(),
                          if (_modalSehirler.isNotEmpty)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _modalSehirler = []),
                              child: Text('Temizle',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: _turuncu,
                                      fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: GestureDetector(
                        onTap: _sehirDialogAc,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _modalSehirler.isEmpty
                                ? AppColors.surface
                                : _turuncu.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _modalSehirler.isEmpty
                                  ? AppColors.divider
                                  : _turuncu.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 18,
                                  color: _modalSehirler.isEmpty
                                      ? AppColors.textSecondary
                                      : _turuncu),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _modalSehirler.isEmpty
                                      ? 'Tüm şehirler'
                                      : _modalSehirler.join(', '),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: _modalSehirler.isEmpty
                                        ? AppColors.textHint
                                        : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: _modalSehirler.isEmpty
                                      ? AppColors.textSecondary
                                      : _turuncu),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Alt buton: Seç (alt sayfa) / Göster (ana sayfa) ──────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.5)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: _altSayfada
                    ? ElevatedButton(
                        onPressed: _geciciSecimVar ? _secimOnayla : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _turuncu,
                          disabledBackgroundColor: AppColors.divider,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Seç',
                            style: GoogleFonts.dmSans(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          final secim = FiltreSecimi(
                            kategoriYolu: List.from(_modalKategori),
                            siralama: _modalSiralama,
                            istekSehirleri: List.from(_modalSehirler),
                          );
                          Navigator.of(context).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            widget.onUygula(secim);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _turuncu,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          _gosterMetni,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnaKart(KategoriNode node, {required VoidCallback onTap}) {
    final secimMetni = _kartSecimMetni(node);
    final secili     = secimMetni != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: secili
              ? _turuncu.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: secili ? _turuncu.withValues(alpha: 0.5) : const Color(0xFFEEEEEE),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (node.emoji.isNotEmpty) ...[
                    Text(node.emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      node.ad,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secili
                            ? _turuncu
                            : AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (secimMetni != null) ...[
                const SizedBox(height: 4),
                Text(
                  '✓ $secimMetni',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _turuncu,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kategori satırı ───────────────────────────────────────────────────────────

class _KategoriSatiri extends StatelessWidget {
  final String ad;
  final bool secili;
  final VoidCallback onTap;
  final bool derinlikOku;
  final bool vurgulu;
  final Color renk;

  const _KategoriSatiri({
    required this.ad,
    required this.secili,
    required this.onTap,
    this.derinlikOku = false,
    this.vurgulu = false,
    this.renk = AppColors.red,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: secili ? renk.withValues(alpha: 0.05) : Colors.white,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: (secili || vurgulu)
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: secili ? renk : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (secili)
              Icon(Icons.check_circle, size: 18, color: renk)
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
