// lib/features/arama/presentation/arama_screen.dart

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iste_v3/shared/constants/app_colors.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';
import 'package:iste_v3/core/cache/app_cache_manager.dart';
import 'package:iste_v3/features/ilanlar/presentation/ilan_detay_screen.dart';
import 'package:iste_v3/features/home/providers/son_goruntulenenler_provider.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import '../data/arama_service.dart';

// Popüler arama terimleri — sabit liste
const _kPopulerAramalar = [
  'iPhone', 'Nike', 'Dyson', 'Zara', 'MacBook',
  'Parfüm', 'Lego', 'PlayStation', 'Adidas', 'Vitamins',
];

class AramaScreen extends ConsumerStatefulWidget {
  const AramaScreen({super.key});

  @override
  ConsumerState<AramaScreen> createState() => _AramaScreenState();
}

class _AramaScreenState extends ConsumerState<AramaScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<AramaSonucu> _sonuclar   = [];
  bool              _yukleniyor = false;
  String            _sorgu      = '';
  String?           _katFiltre;
  final List<String> _gecmisFiltreleri = []; // son aramalar = geçmiş filtreler

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _sorguDegisti(String deger, {String? katFiltre}) {
    _debounce?.cancel();
    setState(() { _sorgu = deger; _katFiltre = katFiltre; });
    if (deger.trim().isEmpty && katFiltre == null) {
      setState(() { _sonuclar = []; _yukleniyor = false; });
      return;
    }
    setState(() => _yukleniyor = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final sonuclar = await algoliaAra(deger.trim(), katFiltre: katFiltre);
      if (mounted) setState(() { _sonuclar = sonuclar; _yukleniyor = false; });
    });
  }

  void _gecmisFiltreEkle(String s) {
    if (s.trim().isEmpty) return;
    _gecmisFiltreleri.remove(s);
    _gecmisFiltreleri.insert(0, s);
    if (_gecmisFiltreleri.length > 8) _gecmisFiltreleri.removeLast();
  }

  void _sonucaTikla(AramaSonucu s) {
    _gecmisFiltreEkle(_sorgu);
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => IlanDetayScreen(ilanId: s.objectID),
      ),
    );
  }

  void _kategoriSec(String katKey) {
    _ctrl.clear();
    _sorguDegisti('', katFiltre: katKey);
  }

  void _populerAramaYap(String terim) {
    _ctrl.text = terim;
    _sorguDegisti(terim);
  }

  // Son aramalara göre ilgili kategorileri bul
  List<KategoriNode> _ilgiliKategoriler() {
    if (_gecmisFiltreleri.isEmpty) return kKategoriAgaci.take(5).toList();
    final Set<String> bulunanlar = {};
    for (final arama in _gecmisFiltreleri) {
      final q = arama.toLowerCase();
      for (final kat in kKategoriAgaci) {
        if (kat.ad.toLowerCase().contains(q) || q.contains(kat.key)) {
          bulunanlar.add(kat.key);
        }
      }
    }
    final eslesen = kKategoriAgaci.where((k) => bulunanlar.contains(k.key)).toList();
    final geri = kKategoriAgaci.where((k) => !bulunanlar.contains(k.key)).toList();
    return [...eslesen, ...geri].take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;
    final sonGezilenler = ref.watch(sonGoruntulenenlerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: statusH + 8),

          // ── Arama çubuğu ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: (v) => _sorguDegisti(v),
                    onSubmitted: (v) { _gecmisFiltreEkle(v); _sorguDegisti(v); },
                    cursorColor: AppColors.textSecondary,
                    cursorWidth: 1.5,
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ara...',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 17,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w400,
                      ),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 8),
                      suffixIcon: _sorgu.isNotEmpty
                          ? GestureDetector(
                              onTap: () { _ctrl.clear(); _sorguDegisti(''); },
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.textHint),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'İptal',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Expanded(
            child: _sorgu.isEmpty && _katFiltre == null
                ? _BosHal(
                    sonGezilenler: sonGezilenler,
                    gecmisFiltreleri: _gecmisFiltreleri,
                    ilgiliKategoriler: _ilgiliKategoriler(),
                    onPopulerArama: _populerAramaYap,
                    onGecmisFiltre: (s) { _ctrl.text = s; _sorguDegisti(s); },
                    onGecmisFiltreSil: (s) => setState(() => _gecmisFiltreleri.remove(s)),
                    onKategori: _kategoriSec,
                    onIlanTikla: (ilan) => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => IlanDetayScreen(ilanId: ilan.id, ilan: ilan),
                      ),
                    ),
                  )
                : _yukleniyor
                    ? _YukleniyorHal()
                    : _sonuclar.isEmpty
                        ? _SonucYokHal(sorgu: _sorgu)
                        : _SonucListesi(
                            sonuclar: _sonuclar,
                            sorgu: _sorgu,
                            onTikla: _sonucaTikla,
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Boş hal ───────────────────────────────────────────────────────────────────

class _BosHal extends StatelessWidget {
  final List<IlanModel> sonGezilenler;
  final List<String> gecmisFiltreleri;
  final List<KategoriNode> ilgiliKategoriler;
  final ValueChanged<String> onPopulerArama;
  final ValueChanged<String> onGecmisFiltre;
  final ValueChanged<String> onGecmisFiltreSil;
  final ValueChanged<String> onKategori;
  final ValueChanged<IlanModel> onIlanTikla;

  const _BosHal({
    required this.sonGezilenler,
    required this.gecmisFiltreleri,
    required this.ilgiliKategoriler,
    required this.onPopulerArama,
    required this.onGecmisFiltre,
    required this.onGecmisFiltreSil,
    required this.onKategori,
    required this.onIlanTikla,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [

        // ── Popüler Aramalar ──────────────────────────────────────────────
        _BolumBaslik(baslik: 'Popüler Aramalar', ikon: Icons.local_fire_department_outlined),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: _kPopulerAramalar.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onPopulerArama(_kPopulerAramalar[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF888888), width: 0.3),
                ),
                child: Text(
                  _kPopulerAramalar[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Önceden Gezdiklerin ───────────────────────────────────────────
        if (sonGezilenler.isNotEmpty) ...[
          _BolumBaslik(baslik: 'Önceden Gezdiklerin', ikon: Icons.history_rounded),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: sonGezilenler.length,
              itemBuilder: (_, i) {
                final ilan = sonGezilenler[i];
                final gridResim = ilan.gridResim;
                return GestureDetector(
                  onTap: () => onIlanTikla(ilan),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: gridResim.isNotEmpty
                          ? CachedNetworkImage(
                              cacheManager: AppCacheManager.instance,
                              imageUrl: gridResim,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
                              memCacheWidth: 200,
                              errorWidget: (_, _, _) => _IlanPlaceholder(ilan: ilan),
                            )
                          : _IlanPlaceholder(ilan: ilan),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // ── Geçmiş Filtreler ─────────────────────────────────────────────
        if (gecmisFiltreleri.isNotEmpty) ...[
          _BolumBaslik(baslik: 'Geçmiş Filtreler', ikon: Icons.tune_rounded),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: _kPopulerAramalar.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => onPopulerArama(_kPopulerAramalar[i]),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF888888), width: 0.3),
                  ),
                  child: Text(
                    _kPopulerAramalar[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── İlgini Çekebilecek Kategoriler ───────────────────────────────
        _BolumBaslik(baslik: 'İlgini Çekebilecek Kategoriler', ikon: Icons.category_outlined),
        ...ilgiliKategoriler.map((kat) => _KategoriItem(
              kat: kat,
              onTikla: () => onKategori(kat.key),
            )),
      ],
    );
  }
}

class _IlanPlaceholder extends StatelessWidget {
  final IlanModel ilan;
  const _IlanPlaceholder({required this.ilan});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          ilan.tip == IlanTip.istek
              ? Icons.shopping_bag_outlined
              : Icons.flight_takeoff_outlined,
          size: 20,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

class _BolumBaslik extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  const _BolumBaslik({required this.baslik, required this.ikon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(ikon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            baslik,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KategoriItem extends StatelessWidget {
  final KategoriNode kat;
  final VoidCallback onTikla;
  const _KategoriItem({required this.kat, required this.onTikla});

  IconData _ikonBul(String key) {
    switch (key) {
      case 'elektronik': return Icons.phone_android_outlined;
      case 'giyim':      return Icons.checkroom_outlined;
      case 'guzellik':   return Icons.face_retouching_natural_outlined;
      case 'ev':         return Icons.home_outlined;
      case 'spor':       return Icons.sports_soccer_outlined;
      case 'kultur':     return Icons.menu_book_outlined;
      case 'gida':       return Icons.restaurant_outlined;
      default:           return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTikla,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_ikonBul(kat.key), size: 17, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${kat.emoji}  ${kat.ad}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Yükleniyor ────────────────────────────────────────────────────────────────

class _YukleniyorHal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 76, color: Color(0xFFF5F5F5)),
      itemBuilder: (_, _) => const _SkeletonItem(),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 52, height: 52,
              decoration: BoxDecoration(color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 13, width: 160, color: AppColors.surface),
            const SizedBox(height: 6),
            Container(height: 11, width: 100, color: AppColors.surface),
          ])),
        ],
      ),
    );
  }
}

// ── Sonuç yok ─────────────────────────────────────────────────────────────────

class _SonucYokHal extends StatelessWidget {
  final String sorgu;
  const _SonucYokHal({required this.sorgu});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off_rounded, size: 52, color: AppColors.textHint),
        const SizedBox(height: 12),
        Text('"$sorgu" için sonuç bulunamadı',
            style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Farklı bir kelime deneyin',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textHint)),
      ]),
    );
  }
}

// ── Sonuç listesi ─────────────────────────────────────────────────────────────

class _SonucListesi extends StatelessWidget {
  final List<AramaSonucu> sonuclar;
  final String sorgu;
  final ValueChanged<AramaSonucu> onTikla;
  const _SonucListesi({required this.sonuclar, required this.sorgu, required this.onTikla});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text('${sonuclar.length} sonuç',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: sonuclar.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 76, color: Color(0xFFF5F5F5)),
            itemBuilder: (_, i) => _SonucItem(
              sonuc: sonuclar[i],
              sorgu: sorgu,
              onTikla: () => onTikla(sonuclar[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SonucItem extends StatelessWidget {
  final AramaSonucu sonuc;
  final String sorgu;
  final VoidCallback onTikla;
  const _SonucItem({required this.sonuc, required this.sorgu, required this.onTikla});

  @override
  Widget build(BuildContext context) {
    final isIstek = sonuc.tip == IlanTip.istek;
    return InkWell(
      onTap: onTikla,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52, height: 52,
                child: sonuc.resimUrl != null && sonuc.resimUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: AppCacheManager.instance,
                        imageUrl: sonuc.resimUrl!,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        memCacheWidth: 104,
                        memCacheHeight: 104,
                        errorWidget: (_, _, _) => _PlaceHolder(isIstek: isIstek),
                      )
                    : _PlaceHolder(isIstek: isIstek),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: _HighlightText(
                      text: sonuc.urun.isNotEmpty
                          ? sonuc.urun
                          : '${sonuc.nereden} → ${sonuc.nereye}',
                      sorgu: sorgu,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      highlightStyle: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isIstek
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isIstek ? 'İstek' : 'Taşıyıcı',
                      style: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: isIstek ? AppColors.primary : const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ]),
                if (sonuc.nereden.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.flight_takeoff_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('${sonuc.nereden} → ${sonuc.nereye}',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceHolder extends StatelessWidget {
  final bool isIstek;
  const _PlaceHolder({required this.isIstek});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          isIstek ? Icons.shopping_bag_outlined : Icons.flight_takeoff_rounded,
          size: 22,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String sorgu;
  final TextStyle style;
  final TextStyle highlightStyle;
  const _HighlightText({
    required this.text, required this.sorgu,
    required this.style, required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (sorgu.isEmpty) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    final lower = text.toLowerCase();
    final idx   = lower.indexOf(sorgu.toLowerCase());
    if (idx == -1) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        if (idx > 0) TextSpan(text: text.substring(0, idx), style: style),
        TextSpan(text: text.substring(idx, idx + sorgu.length), style: highlightStyle),
        if (idx + sorgu.length < text.length)
          TextSpan(text: text.substring(idx + sorgu.length), style: style),
      ]),
    );
  }
}