// lib/features/ilanlar/presentation/widgets/filtre_ekrani.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_constants.dart';
import '../ilanlar_screen.dart' show kategoriIkon;
import '../../../../shared/widgets/turkiye_disi_arama_ekrani.dart';
import '../../../../shared/widgets/sehir_secim_widget.dart';

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
  final List<String> seciliAltKeyler;
  final SiralamaTipi siralama;
  final List<String> istekSehirleri;
  final String ulkeSehir; // Türkiye dışı serbest metin

  const FiltreSecimi({
    required this.kategoriYolu,
    this.seciliAltKeyler = const [],
    required this.siralama,
    required this.istekSehirleri,
    this.ulkeSehir = '',
  });
}

// ── Filtre Ekranı ─────────────────────────────────────────────────────────────

class FiltreEkrani extends StatefulWidget {
  final List<String> seciliKategoriYolu;
  final List<String> seciliAltKeyler;
  final SiralamaTipi seciliSiralama;
  final List<String> seciliIstekSehirleri;
  final Map<String, int> kategoriFacets;
  final void Function(FiltreSecimi secim) onUygula;
  final VoidCallback onTemizle;

  const FiltreEkrani({
    super.key,
    required this.seciliKategoriYolu,
    this.seciliAltKeyler = const [],
    required this.seciliSiralama,
    this.seciliIstekSehirleri = const [],
    this.kategoriFacets = const {},
    required this.onUygula,
    required this.onTemizle,
  });

  @override
  State<FiltreEkrani> createState() => _FiltreEkraniState();
}

class _FiltreEkraniState extends State<FiltreEkrani> {
  List<String>  _gezinmeYolu    = [];
  List<String>  _geciciAltKeyler = [];
  List<String>  _modalAltKeyler  = [];
  late List<String>  _modalKategori;
  // Kilitli ana kategori key'i — seçim yapılan ana kategorinin key'i
  // Başka ana kategoriye tıklanınca eski seçimler sıfırlanır
  String?       _kilitliAnaKey;
  late SiralamaTipi  _modalSiralama;
  late List<String>  _modalSehirler;

  static const _turuncu = Color(0xFFFF6600);
  static const _maviLink = Color(0xFF1565C0);

  String _modalUlkeSehir = '';          // serbest metin (ülke/şehir)
  @override
  void initState() {
    super.initState();
    _modalKategori   = List.from(widget.seciliKategoriYolu);
    _modalAltKeyler  = List.from(widget.seciliAltKeyler);
    _geciciAltKeyler = List.from(widget.seciliAltKeyler);
    _modalSiralama   = widget.seciliSiralama;
    _modalSehirler   = List.from(widget.seciliIstekSehirleri);
    // Eğer önceden seçim varsa hangi ana kategoriye ait olduğunu bul
    if (_modalAltKeyler.isNotEmpty && widget.seciliKategoriYolu.isNotEmpty) {
      _kilitliAnaKey = widget.seciliKategoriYolu.first;
    }
  }

  bool get _altSayfada => _gezinmeYolu.isNotEmpty;

  bool get _herhangiSecildi =>
      _modalKategori.isNotEmpty ||
      _modalAltKeyler.isNotEmpty ||
      _modalSiralama != SiralamaTipi.enYeni ||
      _modalSehirler.isNotEmpty ||
      _modalUlkeSehir.isNotEmpty;

  String get _gosterMetni {
    final parcalar = <String>[];
    if (_modalAltKeyler.isNotEmpty) {
      parcalar.add('${_modalAltKeyler.length} alt kategori');
    } else if (_modalKategori.isNotEmpty) {
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
    if (_modalUlkeSehir.isNotEmpty) {
      parcalar.add(_modalUlkeSehir);
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

  // Bir ana kategorinin kilitli olup olmadığını kontrol et
  // Kilitli değilse veya bu ana kategoriyse true döner
  bool _anaKategoriAktifMi(String anaKey) {
    if (_kilitliAnaKey == null) return true;
    return _kilitliAnaKey == anaKey;
  }

  void _anaKategoriTiklandi(KategoriNode node) {
    if (node.yaprakMi) {
      setState(() {
        if (_modalAltKeyler.contains(node.key)) {
          // Seçimi kaldır
          _modalAltKeyler.remove(node.key);
          if (_modalAltKeyler.isEmpty) {
            _modalKategori = [];
            _kilitliAnaKey = null;
          }
        } else {
          // Farklı ana kategoriden seçim — önceki seçimleri sıfırla
          final buAnaKey = node.key; // yaprak olduğu için key direkt ana key
          if (_kilitliAnaKey != null && _kilitliAnaKey != buAnaKey) {
            _modalAltKeyler.clear();
          }
          _modalAltKeyler.add(node.key);
          _modalKategori = [node.key];
          _kilitliAnaKey = buAnaKey;
        }
        _geciciAltKeyler = List.from(_modalAltKeyler);
      });
    } else {
      // Alt kategorileri olan — farklı ana kategoriyse önceki seçimleri sıfırla
      setState(() {
        if (_kilitliAnaKey != null && _kilitliAnaKey != node.key) {
          _modalAltKeyler.clear();
          _modalKategori = [];
          _kilitliAnaKey = null;
        }
        _gezinmeYolu     = [node.key];
        _geciciAltKeyler = List.from(_modalAltKeyler);
      });
    }
  }

  void _altKategoriTiklandi(KategoriNode node) {
    if (node.yaprakMi) {
      setState(() {
        if (_geciciAltKeyler.contains(node.key)) {
          _geciciAltKeyler.remove(node.key);
        } else {
          _geciciAltKeyler.add(node.key);
        }
      });
    } else {
      setState(() {
        _gezinmeYolu = [..._gezinmeYolu, node.key];
      });
    }
  }

  void _secimOnayla() {
    setState(() {
      _modalAltKeyler = List.from(_geciciAltKeyler);
      if (_modalAltKeyler.isNotEmpty) {
        _modalKategori = List.from(_gezinmeYolu);
        _kilitliAnaKey = _gezinmeYolu.isNotEmpty ? _gezinmeYolu.first : null;
      } else {
        _modalKategori = [];
        _kilitliAnaKey = null;
      }
      _gezinmeYolu = [];
    });
  }

  void _tumunuSec() {
    final nodes = _mevcutNodes();
    final yaprakKeyler = nodes
        .where((n) => n.yaprakMi)
        .map((n) => n.key)
        .toList();
    setState(() {
      final hepsiSecili = yaprakKeyler.every((k) => _geciciAltKeyler.contains(k));
      if (hepsiSecili) {
        for (final k in yaprakKeyler) { _geciciAltKeyler.remove(k); }
      } else {
        for (final k in yaprakKeyler) {
          if (!_geciciAltKeyler.contains(k)) _geciciAltKeyler.add(k);
        }
      }
    });
  }

  bool _altNodeSeciliMi(KategoriNode node) => _geciciAltKeyler.contains(node.key);

  bool _tumSeciliMi() {
    final nodes = _mevcutNodes();
    final yaprakKeyler = nodes.where((n) => n.yaprakMi).map((n) => n.key).toList();
    if (yaprakKeyler.isEmpty) return false;
    return yaprakKeyler.every((k) => _geciciAltKeyler.contains(k));
  }

  bool get _geciciSecimVar => _geciciAltKeyler.isNotEmpty;

  String? _kartSecimMetni(KategoriNode anaNode) {
    final altKeyler = tumAltKeyler(anaNode.key);
    final seciliSayisi = _modalAltKeyler
        .where((k) => altKeyler.contains(k))
        .length;
    if (seciliSayisi == 0) return null;
    if (seciliSayisi == 1) {
      final key = _modalAltKeyler.firstWhere((k) => altKeyler.contains(k));
      return kategoriNodeBul(key)?.ad ?? key;
    }
    return '$seciliSayisi alt kategori';
  }


  // ── Türkiye dışı popup ───────────────────────────────────────────────────────

  void _turkiyeDisiDialogAc() async {
    final sonuc = await Navigator.push<String>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, _, _) => TurkiyeDisiAramaEkrani(
          mevcutSecim: _modalUlkeSehir,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    if (sonuc != null) {
      setState(() => _modalUlkeSehir = sonuc == '__temizle__' ? '' : sonuc);
    }
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
                          setState(() {
                            _gezinmeYolu     = [];
                            _geciciAltKeyler = List.from(_modalAltKeyler);
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
                          _modalKategori   = [];
                          _modalAltKeyler  = [];
                          _geciciAltKeyler = [];
                          _kilitliAnaKey   = null;
                          _modalSiralama   = SiralamaTipi.enYeni;
                          _modalSehirler   = [];
                          _modalUlkeSehir  = '';
                          _gezinmeYolu     = [];
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
                  if (anaGorunu)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.85,
                      ),
                      itemCount: nodes.length,
                      itemBuilder: (_, i) {
                        final node   = nodes[i];
                        final aktif  = _anaKategoriAktifMi(node.key);
                        return _buildAnaKart(
                          node,
                          aktif: aktif,
                          onTap: () => _anaKategoriTiklandi(node),
                        );
                      },
                    ),

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
                      child: _SiralamaSegmented(
                        secili: _modalSiralama,
                        onSecim: (tip) => setState(() => _modalSiralama = tip),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.divider),
                    SehirSecimBolumu(
                      baslik: 'İstek Şehri',
                      seciliSehirler: _modalSehirler,
                      onDegisti: (yeni) => setState(() => _modalSehirler = yeni),
                      renk: _turuncu,
                      sagWidget: GestureDetector(
                        onTap: _turkiyeDisiDialogAc,
                        child: Text(
                          _modalUlkeSehir.isNotEmpty
                              ? _modalUlkeSehir
                              : 'Türkiye dışı',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _maviLink,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: _maviLink,
                          ),
                        ),
                      ),
                    ),

                  ],
                ],
              ),
            ),

            // ── Alt buton ─────────────────────────────────────────────────────
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
                            kategoriYolu:    List.from(_modalKategori),
                            seciliAltKeyler: List.from(_modalAltKeyler),
                            siralama:        _modalSiralama,
                            istekSehirleri:  List.from(_modalSehirler),
                            ulkeSehir:       _modalUlkeSehir,
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

  Widget _buildAnaKart(KategoriNode node, {required bool aktif, required VoidCallback onTap}) {
    final secimMetni = _kartSecimMetni(node);
    final secili     = secimMetni != null;
    final soluk      = !aktif && !secili;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: soluk ? 0.35 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: secili
                ? _turuncu.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: secili
                  ? _turuncu.withValues(alpha: 0.5)
                  : const Color(0xFFEEEEEE),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      kategoriIkon(node.key),
                      size: 32,
                      color: kategoriRengi(node.key),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        node.ad,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: secili ? _turuncu : AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if ((widget.kategoriFacets[node.key] ?? 0) > 0)
                  Text(
                    '(${widget.kategoriFacets[node.key]}) Aktif ilan',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
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
              child: Text(
                ad,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: (secili || vurgulu)
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: secili ? renk : AppColors.textPrimary,
                ),
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
          const Icon(Icons.search_off_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Sonuç bulunamadı',
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Filtre veya aramayı temizlemeyi deneyin',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textHint)),
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
          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Henüz ilan yok',
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('İlk ilanı sen ver!',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textHint)),
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

// ── Sıralama Dropdown ─────────────────────────────────────────────────────────

// ── Sıralama Segmented Control ────────────────────────────────────────────────

class _SiralamaSegmented extends StatelessWidget {
  final SiralamaTipi secili;
  final ValueChanged<SiralamaTipi> onSecim;

  const _SiralamaSegmented({
    required this.secili,
    required this.onSecim,
  });

  static const _turuncu = Color(0xFFFF6600);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: SiralamaTipi.values.map((tip) {
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
                      ? Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 0.5,
                        )
                      : null,
                ),
                child: Text(
                  tip.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: seciliMi ? FontWeight.w600 : FontWeight.w400,
                    color: seciliMi ? _turuncu : AppColors.textSecondary,
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