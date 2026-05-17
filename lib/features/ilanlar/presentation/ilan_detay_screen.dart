// lib/features/ilanlar/presentation/ilan_detay_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../data/ilan_repository.dart';
import '../providers/ilan_provider.dart';
import '../presentation/ilan_form_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../profil/presentation/kullanici_profil_screen.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/utils/app_layout.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import '../../../core/cache/app_cache_manager.dart';

class IlanDetayScreen extends ConsumerStatefulWidget {
  final String ilanId;
  final IlanModel? ilan;

  const IlanDetayScreen({super.key, required this.ilanId, this.ilan});

  @override
  ConsumerState<IlanDetayScreen> createState() => _IlanDetayScreenState();
}

class _IlanDetayScreenState extends ConsumerState<IlanDetayScreen> {
  int _aktifResim = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _otuzGunKontrol(IlanModel ilan) async {
    final tarih = ilan.olusturmaTarihi;
    if (tarih == null) return;
    final fark = DateTime.now().difference(tarih).inDays;
    if (fark >= 30 && ilan.aktif) {
      await ref.read(ilanRepositoryProvider).ilanPasifYap(ilan.id);
    }
  }

  String get _benimUid => ref.read(currentUserProvider)?.uid ?? '';

  void _mesajGonder(IlanModel ilan) {
    if (_benimUid.isEmpty) return;
    final resimler = ilan.tumResimler;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secAnim) => SohbetScreen(
          karsiKullaniciId: ilan.kullaniciId,
          karsiKullaniciAd: ilan.kullaniciAd,
          ilanId: ilan.id,
          ilanBaslik: ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
          ilanResimUrl: resimler.isNotEmpty ? resimler.first : null,
          ilanSahibiId: ilan.kullaniciId,
          ilanTip: ilan.tip,
        ),
        transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _ucNoktaMenu(IlanModel ilan) {
    final benimIlan = _benimUid.isNotEmpty && _benimUid == ilan.kullaniciId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomSheetHandle(),
            if (benimIlan) ...[
              _MenuItem(
                icon: Icons.edit_outlined,
                iconColor: AppColors.primary,
                label: 'İlanı Düzenle',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IlanFormScreen(
                          tip: ilan.tip, duzenlenecekIlan: ilan),
                    ),
                  ).then((_) {
                    ref.read(istekIlanlarProvider.notifier).yenile();
                    ref.read(tasiyiciIlanlarProvider.notifier).yenile();
                  });
                },
              ),
              _MenuItem(
                icon: Icons.delete_outline,
                iconColor: AppColors.red,
                label: 'İlanı Sil',
                labelColor: AppColors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _ilanSilDialog(ilan.id);
                },
              ),
            ],
            if (_benimUid.isNotEmpty && !benimIlan) ...[
              _MenuItem(
                icon: Icons.flag_outlined,
                iconColor: AppColors.red,
                label: 'Şikayet Et',
                labelColor: AppColors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _sikayetDialog(_benimUid, ilan);
                },
              ),
              _MenuItem(
                icon: Icons.block_outlined,
                iconColor: AppColors.red,
                label: 'Kullanıcıyı Engelle',
                labelColor: AppColors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _engelleDialog(ilan);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _ilanSilDialog(String ilanId) async {
    final onay = await _onayDialog(
      baslik: 'İlanı Sil',
      icerik: 'Bu ilanı silmek istediğine emin misin?',
      onayMetin: 'Sil',
    );
    if (onay == true && mounted) {
      await ref.read(ilanRepositoryProvider).ilanSil(ilanId);
      if (mounted) context.pop();
    }
  }

  Future<void> _engelleDialog(IlanModel ilan) async {
    final onay = await _onayDialog(
      baslik: 'Kullanıcıyı Engelle',
      icerik: '${ilan.kullaniciAd} adlı kullanıcıyı engellemek istiyor musun?',
      onayMetin: 'Engelle',
    );
    if (onay == true && mounted) {
      await ref.read(engellemeProvider.notifier).engelle(
            benimUid: _benimUid,
            hedefUid: ilan.kullaniciId,
          );
      if (mounted) context.pop();
    }
  }

  Future<bool?> _onayDialog({
    required String baslik,
    required String icerik,
    required String onayMetin,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(baslik,
            style: GoogleFonts.dmSans(fontSize: AppLayout.fs(context, 16), fontWeight: FontWeight.w600)),
        content: Text(icerik,
            style: GoogleFonts.dmSans(fontSize: AppLayout.fs(context, 14), color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(onayMetin,
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _sikayetDialog(String uid, IlanModel ilan) async {
    String? seciliSebep;
    final sebepler = ['Sahte ilan', 'Yanıltıcı bilgi', 'Uygunsuz içerik', 'Spam', 'Diğer'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Şikayet Et',
              style: GoogleFonts.dmSans(fontSize: AppLayout.fs(context, 16), fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: sebepler
                .map((s) => RadioListTile<String>(
                      value: s,
                      groupValue: seciliSebep,
                      title: Text(s, style: GoogleFonts.dmSans(fontSize: AppLayout.fs(context, 14))),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.red
                            : null,
                      ),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setS(() => seciliSebep = v),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: seciliSebep == null
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      final basarili = await ref
                          .read(sikayetProvider.notifier)
                          .sikayetGonder(
                            sikayetEdenId: uid,
                            hedefId: ilan.kullaniciId,
                            hedefAd: ilan.kullaniciAd,
                            sebep: seciliSebep!,
                            ilanId: ilan.id,
                          );
                      if (basarili) {
                        messenger.showSnackBar(SnackBar(
                          content: Text('Şikayetiniz iletildi.',
                              style: GoogleFonts.dmSans()),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
              child: Text('Gönder',
                  style: GoogleFonts.dmSans(
                      color: AppColors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ilanProp = widget.ilan;

    if (ilanProp != null) {
      final streamDegeri = ref.watch(ilanByIdProvider(widget.ilanId)).value;
      final ilan = streamDegeri ?? ilanProp;
      return _detayScaffold(context, ilan);
    }

    final ilanAsync = ref.watch(ilanByIdProvider(widget.ilanId));
    return ilanAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('İlan yüklenemedi.',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
      ),
      data: (ilan) {
        if (ilan == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('İlan bulunamadı veya silindi.',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            ),
          );
        }
        return _detayScaffold(context, ilan);
      },
    );
  }

  Widget _detayScaffold(BuildContext context, IlanModel ilan) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otuzGunKontrol(ilan);
    });
    return _IlanDetayIcerik(
      ilan: ilan,
      aktifResim: _aktifResim,
      pageController: _pageController,
      onResimDegis: (i) => setState(() => _aktifResim = i),
      onMesajGonder: () => _mesajGonder(ilan),
      onUcNokta: () => _ucNoktaMenu(ilan),
    );
  }
}

// ── İçerik widget'ı ───────────────────────────────────────────────────────────

class _IlanDetayIcerik extends ConsumerWidget {
  final IlanModel ilan;
  final int aktifResim;
  final PageController pageController;
  final ValueChanged<int> onResimDegis;
  final VoidCallback onMesajGonder;
  final VoidCallback onUcNokta;

  const _IlanDetayIcerik({
    required this.ilan,
    required this.aktifResim,
    required this.pageController,
    required this.onResimDegis,
    required this.onMesajGonder,
    required this.onUcNokta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resimler = ilan.tumResimler;
    final kategoriAdiStr = app_constants.kategoriAdi(ilan.kategori);
    final uid = ref.watch(currentUserProvider)?.uid;
    final benimIlan = uid != null && uid.isNotEmpty && ilan.kullaniciId.isNotEmpty && uid == ilan.kullaniciId;

    final favoriAsync = uid != null && !benimIlan
        ? ref.watch(ilanFavorideMiProvider(ilan.id))
        : const AsyncData(false);
    final favorideMi = favoriAsync.value ?? false;

    final favoriSayisi =
        ref.watch(ilanFavoriSayisiProvider(ilan.id)).value ?? ilan.favoriSayisi;

    final benzerIlanlarAsync = ref.watch(istekIlanlarProvider);
    final benzerIlanlar = benzerIlanlarAsync.filtrelenmis
        .where((i) => i.id != ilan.id && i.kategori == ilan.kategori && i.aktif)
        .take(6)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            forceMaterialTransparency: false,
            leading: _CircleIconButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => context.pop(),
            ),
            actions: [
              if (uid != null && !benimIlan)
                _FavoriButon(
                  favorideMi: favorideMi,
                  favoriSayisi: favoriSayisi,
                  onTap: () async {
                    if (favorideMi) {
                      await ref.read(ilanRepositoryProvider)
                          .favoridanCikar(kullaniciId: uid, ilanId: ilan.id);
                      ref.read(istekIlanlarProvider.notifier)
                          .ilanFavoriSayisiGuncelle(ilan.id, -1);
                      ref.read(tasiyiciIlanlarProvider.notifier)
                          .ilanFavoriSayisiGuncelle(ilan.id, -1);
                    } else {
                      await ref.read(ilanRepositoryProvider)
                          .favoriyeEkle(kullaniciId: uid, ilan: ilan);
                      ref.read(istekIlanlarProvider.notifier)
                          .ilanFavoriSayisiGuncelle(ilan.id, 1);
                      ref.read(tasiyiciIlanlarProvider.notifier)
                          .ilanFavoriSayisiGuncelle(ilan.id, 1);
                    }
                  },
                ),
              _CircleIconButton(icon: Icons.more_vert, onTap: onUcNokta),
            ],
          ),

          // ── Resim slider ─────────────────────────────────────────────────
          if (resimler.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: pageController,
                          itemCount: resimler.length,
                          onPageChanged: onResimDegis,
                          itemBuilder: (_, i) => _ResimWidget(
                            url: resimler[i],
                            tumResimler: resimler,
                            baslangicIndex: i,
                          ),
                        ),
                        if (resimler.length > 1)
                          Positioned(
                            top: 12, right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${aktifResim + 1}/${resimler.length}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppLayout.fs(context, 12),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ── Thumbnail strip ──────────────────────────────────────
                  if (resimler.length > 1)
                    Container(
                      height: 68,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: resimler.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () {
                            pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: aktifResim == i
                                    ? AppColors.red
                                    : const Color(0xFFE0E0E0),
                                width: aktifResim == i ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: CachedNetworkImage(
                                cacheManager: AppCacheManager.instance,
                                imageUrl: resimler[i],
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                memCacheWidth: 104,
                                placeholder: (_, _) => Container(color: const Color(0xFFF5F5F5)),
                                errorWidget: (_, _, _) => Container(
                                  color: const Color(0xFFF5F5F5),
                                  child: const Icon(Icons.image_outlined,
                                      size: 16, color: AppColors.textHint),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık + Kategori + Tip badge ───────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (kategoriAdiStr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(kategoriAdiStr,
                                  style: GoogleFonts.dmSans(
                                      fontSize: AppLayout.fs(context, 12),
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w500)),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ilan.tip == 'istek'
                                  ? const Color(0xFF1976D2).withValues(alpha: 0.1)
                                  : const Color(0xFF388E3C).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ilan.tip == 'istek' ? '📦 İstek' : '✈️ Taşıyıcı',
                              style: GoogleFonts.dmSans(
                                fontSize: AppLayout.fs(context, 12),
                                fontWeight: FontWeight.w500,
                                color: ilan.tip == 'istek'
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFF388E3C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ── Ürün başlığı — Syne font ─────────────────────────
                      Text(
                        ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                        style: GoogleFonts.nunito(
                          fontSize: AppLayout.fs(context, 24),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (ilan.ucret.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ilan.ucret,
                          style: GoogleFonts.dmSans(
                            fontSize: AppLayout.fs(context, 18),
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Güzergah + Tarih ────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GuzergahSatiri(nereden: ilan.nereden, nereye: ilan.nereye),
                      if (ilan.tarih != null) ...[
                        const SizedBox(height: 12),
                        _BilgiSatiri(
                          icon: Icons.calendar_today_outlined,
                          label: _tamTarih(ilan.tarih!),
                        ),
                      ],
                      if (ilan.tasimaTercihi.isNotEmpty && ilan.tasimaTercihi != 'hepsi') ...[
                        const SizedBox(height: 12),
                        _BilgiSatiri(
                          icon: Icons.inventory_2_outlined,
                          label: ilan.tasimaTercihi == 'kargo'
                              ? 'Kargo ile taşınabilir'
                              : 'El bagajı tercih edilir',
                        ),
                      ],
                      if (ilan.urunLinki.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _BilgiSatiri(
                          icon: Icons.link_outlined,
                          label: ilan.urunLinki,
                          color: const Color(0xFF1976D2),
                        ),
                      ],
                      if (ilan.olusturmaTarihi != null) ...[
                        const SizedBox(height: 12),
                        _BilgiSatiri(
                          icon: Icons.access_time_outlined,
                          label: 'İlan tarihi: ${_tamTarih(ilan.olusturmaTarihi!)}',
                          small: true,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Notlar ──────────────────────────────────────────────────
                if (ilan.notlar.isNotEmpty) ...[
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notlar',
                            style: GoogleFonts.dmSans(
                                fontSize: AppLayout.fs(context, 13),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                          ilan.notlar,
                          style: GoogleFonts.dmSans(
                              fontSize: AppLayout.fs(context, 14),
                              color: AppColors.textPrimary,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── İlan sahibi profil kartı ──────────────────────────────
                _IlanSahibiKarti(kullaniciId: ilan.kullaniciId, kullaniciAd: ilan.kullaniciAd),

                const SizedBox(height: 8),

                // ── Benzer İlanlar ───────────────────────────────────────
                if (benzerIlanlar.isNotEmpty) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Benzer İlanlar',
                            style: GoogleFonts.dmSans(
                                fontSize: AppLayout.fs(context, 13),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: benzerIlanlar.length,
                            itemBuilder: (context, index) =>
                                _BenzerIlanKarti(ilan: benzerIlanlar[index]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: uid != null && !benimIlan
          ? Container(
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.divider)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (favorideMi) {
                        await ref.read(ilanRepositoryProvider)
                            .favoridanCikar(kullaniciId: uid, ilanId: ilan.id);
                        ref.read(istekIlanlarProvider.notifier)
                            .ilanFavoriSayisiGuncelle(ilan.id, -1);
                        ref.read(tasiyiciIlanlarProvider.notifier)
                            .ilanFavoriSayisiGuncelle(ilan.id, -1);
                      } else {
                        await ref.read(ilanRepositoryProvider)
                            .favoriyeEkle(kullaniciId: uid, ilan: ilan);
                        ref.read(istekIlanlarProvider.notifier)
                            .ilanFavoriSayisiGuncelle(ilan.id, 1);
                        ref.read(tasiyiciIlanlarProvider.notifier)
                            .ilanFavoriSayisiGuncelle(ilan.id, 1);
                      }
                    },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: favorideMi
                            ? AppColors.red.withValues(alpha: 0.08)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: favorideMi
                              ? AppColors.red.withValues(alpha: 0.3)
                              : AppColors.divider,
                        ),
                      ),
                      child: Icon(
                        favorideMi ? Icons.favorite : Icons.favorite_border,
                        color: favorideMi ? AppColors.red : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onMesajGonder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE0E0E0),
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.message_outlined, size: 18),
                        label: Text('İletişime Geç',
                            style: GoogleFonts.dmSans(
                                fontSize: AppLayout.fs(context, 14),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  static String _tamTarih(DateTime tarih) {
    const ay = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${tarih.day} ${ay[tarih.month]} ${tarih.year}';
  }
}

// ── Ortak widget'lar ──────────────────────────────────────────────────────────

class _GuzergahSatiri extends StatelessWidget {
  final String nereden;
  final String nereye;
  const _GuzergahSatiri({required this.nereden, required this.nereye});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.flight_takeoff_outlined, size: 15, color: AppColors.textHint),
        const SizedBox(width: 10),
        Text(
          nereden.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textHint),
        ),
        Text(
          nereye.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _BilgiSatiri extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool bold;
  final bool small;
  final Color? color;

  const _BilgiSatiri({
    required this.icon,
    required this.label,
    this.bold = false,
    this.small = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? (small ? AppColors.textHint : AppColors.textPrimary);
    final fontSize = small ? 12.0 : 14.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: small ? 14 : 16,
            color: color ?? AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _IlanSahibiKarti extends ConsumerWidget {
  final String kullaniciId;
  final String kullaniciAd;

  const _IlanSahibiKarti({
    required this.kullaniciId,
    required this.kullaniciAd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(kullaniciBilgiProvider(kullaniciId));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İlan Sahibi',
              style: GoogleFonts.dmSans(
                  fontSize: AppLayout.fs(context, 13),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          profilAsync.when(
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (profil) {
              final puan = profil?.ortalamaPuan ?? 0.0;
              final sayi = profil?.degerlendirmeSayisi ?? 0;
              final fotoUrl = profil?.fotoUrl;

              return GestureDetector(
                onTap: kullaniciId.isEmpty ? null : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KullaniciProfilScreen(
                      kullaniciId: kullaniciId,
                      kullaniciAd: kullaniciAd,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ClipOval(
                        child: fotoUrl != null && fotoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: fotoUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppColors.surface),
                                errorWidget: (_, __, ___) => _AvatarHarf(ad: kullaniciAd),
                              )
                            : _AvatarHarf(ad: kullaniciAd),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kullaniciAd,
                            style: GoogleFonts.dmSans(
                              fontSize: AppLayout.fs(context, 15),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (sayi > 0) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: Color(0xFFFFA726)),
                                const SizedBox(width: 3),
                                Text(
                                  puan.toStringAsFixed(1),
                                  style: GoogleFonts.dmSans(
                                    fontSize: AppLayout.fs(context, 13),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($sayi değerlendirme)',
                                  style: GoogleFonts.dmSans(
                                    fontSize: AppLayout.fs(context, 12),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 3),
                            Text(
                              'Henüz değerlendirme yok',
                              style: GoogleFonts.dmSans(
                                fontSize: AppLayout.fs(context, 12),
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AvatarHarf extends StatelessWidget {
  final String ad;
  const _AvatarHarf({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.red.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          ad.isNotEmpty ? ad[0].toUpperCase() : '?',
          style: GoogleFonts.dmSans(
            fontSize: AppLayout.fs(context, 18),
            fontWeight: FontWeight.w700,
            color: AppColors.red,
          ),
        ),
      ),
    );
  }
}

class _BenzerIlanKarti extends StatelessWidget {
  final IlanModel ilan;
  const _BenzerIlanKarti({required this.ilan});

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.ilanDetayPath(ilan.id), extra: ilan),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: resimler.isNotEmpty
                  ? CachedNetworkImage(
                      cacheManager: AppCacheManager.instance,
                      imageUrl: resimler.first,
                      width: 130, height: 90, fit: BoxFit.cover,
                      fadeInDuration: Duration.zero, memCacheWidth: 260,
                      placeholder: (_, __) => Container(height: 90, color: AppColors.divider),
                      errorWidget: (_, __, ___) => Container(height: 90, color: AppColors.divider,
                          child: const Icon(Icons.image_outlined, color: AppColors.textHint)))
                  : Container(width: 130, height: 90, color: AppColors.divider,
                      child: const Icon(Icons.image_outlined, color: AppColors.textHint)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                  style: GoogleFonts.dmSans(
                      fontSize: AppLayout.fs(context, 12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriButon extends StatelessWidget {
  final bool favorideMi;
  final int favoriSayisi;
  final VoidCallback onTap;
  const _FavoriButon({required this.favorideMi, required this.favoriSayisi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(favorideMi ? Icons.favorite : Icons.favorite_border,
                color: favorideMi ? AppColors.red : AppColors.textPrimary, size: 20),
            if (favoriSayisi > 0) ...[
              const SizedBox(width: 4),
              Text('$favoriSayisi',
                  style: GoogleFonts.dmSans(
                      fontSize: AppLayout.fs(context, 13),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
      onPressed: onTap,
    );
  }
}

class _ResimWidget extends StatelessWidget {
  final String url;
  final List<String> tumResimler;
  final int baslangicIndex;
  const _ResimWidget({required this.url, required this.tumResimler, required this.baslangicIndex});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(
        opaque: false,
        pageBuilder: (ctx, anim, secAnim) => _ResimBuyukEkran(
            resimler: tumResimler, baslangicIndex: baslangicIndex),
        transitionsBuilder: (ctx, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      )),
      child: CachedNetworkImage(
        cacheManager: AppCacheManager.instance,
        imageUrl: url, fit: BoxFit.cover, width: double.infinity,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        memCacheWidth: MediaQuery.of(context).size.width.toInt(),
        placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
        errorWidget: (_, __, ___) => Container(color: const Color(0xFFF5F5F5),
            child: const Icon(Icons.image_outlined, color: AppColors.textHint, size: 48)),
      ),
    );
  }
}

class _ResimBuyukEkran extends StatefulWidget {
  final List<String> resimler;
  final int baslangicIndex;
  const _ResimBuyukEkran({required this.resimler, required this.baslangicIndex});

  @override
  State<_ResimBuyukEkran> createState() => _ResimBuyukEkranState();
}

class _ResimBuyukEkranState extends State<_ResimBuyukEkran> {
  late int _aktif;
  late TransformationController _transformController;

  @override
  void initState() {
    super.initState();
    _aktif = widget.baslangicIndex;
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _doubleTapZoom(TapDownDetails details) {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final p = details.localPosition;
      _transformController.value = Matrix4.identity()
        ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: widget.resimler.length > 1
            ? Text('${_aktif + 1} / ${widget.resimler.length}',
                style: TextStyle(color: Colors.white, fontSize: AppLayout.fs(context, 14)))
            : null,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: widget.baslangicIndex),
        itemCount: widget.resimler.length,
        onPageChanged: (i) {
          setState(() => _aktif = i);
          _transformController.value = Matrix4.identity();
        },
        itemBuilder: (_, i) => GestureDetector(
          onDoubleTapDown: _doubleTapZoom,
          onDoubleTap: () {},
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: CachedNetworkImage(
                cacheManager: AppCacheManager.instance,
                imageUrl: widget.resimler[i],
                fit: BoxFit.contain,
                fadeInDuration: Duration.zero,
                placeholder: (_, __) => const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
                errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor = AppColors.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: AppLayout.fs(context, 14),
              color: labelColor,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}