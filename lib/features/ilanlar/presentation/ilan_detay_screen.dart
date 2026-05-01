// lib/features/ilanlar/presentation/ilan_detay_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/ilan_model.dart';
import '../data/ilan_repository.dart';
import '../providers/ilan_provider.dart';
import '../presentation/ilan_form_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../profil/presentation/kullanici_profil_screen.dart';
import '../../mesajlar/presentation/sohbet_screen.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart' as app_constants;
import '../../../shared/widgets/avatar_widget.dart';
import '../../../core/cache/app_cache_manager.dart';

class IlanDetayScreen extends ConsumerStatefulWidget {
  final IlanModel ilan;
  const IlanDetayScreen({super.key, required this.ilan});

  @override
  ConsumerState<IlanDetayScreen> createState() => _IlanDetayScreenState();
}

class _IlanDetayScreenState extends ConsumerState<IlanDetayScreen> {
  int _aktifResim = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otuzGunKontrol();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _otuzGunKontrol() async {
    final tarih = widget.ilan.olusturmaTarihi;
    if (tarih == null) return;
    final fark = DateTime.now().difference(tarih).inDays;
    if (fark >= 30 && widget.ilan.aktif) {
      await ref.read(ilanRepositoryProvider).ilanPasifYap(widget.ilan.id);
    }
  }

  String get _benimUid => ref.read(currentUserProvider)?.uid ?? '';
  bool get _benimIlanim =>
      _benimUid.isNotEmpty && _benimUid == widget.ilan.kullaniciId;

  void _mesajGonder() {
    if (_benimUid.isEmpty) return;
    final ilan = widget.ilan;
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

  void _ucNoktaMenu() {
    final ilan = widget.ilan;
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
            if (_benimIlanim) ...[
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
            if (_benimUid.isNotEmpty && !_benimIlanim) ...[
              _MenuItem(
                icon: Icons.flag_outlined,
                iconColor: AppColors.red,
                label: 'Şikayet Et',
                labelColor: AppColors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _sikayetDialog(_benimUid);
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
      if (mounted) Navigator.pop(context);
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
      if (mounted) Navigator.pop(context);
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
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(icerik,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
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

  Future<void> _sikayetDialog(String uid) async {
    String? seciliSebep;
    final sebepler = ['Sahte ilan', 'Yanıltıcı bilgi', 'Uygunsuz içerik', 'Spam', 'Diğer'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Şikayet Et',
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: sebepler
                .map((s) => RadioListTile<String>(
                      value: s,
                      groupValue: seciliSebep,
                      title: Text(s, style: GoogleFonts.dmSans(fontSize: 14)),
                      activeColor: AppColors.red,
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
                            hedefId: widget.ilan.kullaniciId,
                            hedefAd: widget.ilan.kullaniciAd,
                            sebep: seciliSebep!,
                            ilanId: widget.ilan.id,
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
    final ilan = widget.ilan;
    final resimler = ilan.tumResimler;
    final kategoriAdiStr = app_constants.kategoriAdi(ilan.kategori);
    final uid = ref.watch(currentUserProvider)?.uid;
    final benimIlan = _benimIlanim;

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
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: resimler.isNotEmpty ? 320 : 0,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            leading: _CircleIconButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.pop(context),
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
                    } else {
                      await ref.read(ilanRepositoryProvider)
                          .favoriyeEkle(kullaniciId: uid, ilan: ilan);
                    }
                  },
                ),
              _CircleIconButton(icon: Icons.more_vert, onTap: _ucNoktaMenu),
            ],
            flexibleSpace: resimler.isNotEmpty
                ? FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: resimler.length,
                          onPageChanged: (i) => setState(() => _aktifResim = i),
                          itemBuilder: (_, i) => _ResimWidget(
                            url: resimler[i],
                            tumResimler: resimler,
                            baslangicIndex: i,
                          ),
                        ),
                        if (resimler.length > 1)
                          Positioned(
                            bottom: 12, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                resimler.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _aktifResim == i ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _aktifResim == i
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (resimler.length > 1)
                          Positioned(
                            top: 12, right: 56,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_aktifResim + 1}/${resimler.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : null,
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kategoriAdiStr.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(kategoriAdiStr,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                        style: GoogleFonts.dmSans(
                            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: ilan.ucret.isNotEmpty
                              ? AppColors.red.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money_outlined,
                                size: 18,
                                color: ilan.ucret.isNotEmpty
                                    ? AppColors.red : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              ilan.ucret.isNotEmpty ? '${ilan.ucret} ₺' : 'Ücret belirtilmemiş',
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: ilan.ucret.isNotEmpty
                                    ? AppColors.red : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Güzergah',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Column(
                            children: [
                              Container(width: 10, height: 10,
                                  decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                              Container(width: 2, height: 30, color: AppColors.divider),
                              Container(width: 10, height: 10,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ilan.nereden,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 20),
                                Text(ilan.nereye,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (ilan.tarih != null) ...[
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Seyahat Tarihi: ',
                                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                            Text(
                              '${ilan.tarih!.day}.${ilan.tarih!.month}.${ilan.tarih!.year}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                if (ilan.notlar.isNotEmpty) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notlar',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Text(ilan.notlar,
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (ilan.olusturmaTarihi != null)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 15, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text('İlan tarihi: ${_tamTarih(ilan.olusturmaTarihi!)}',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint)),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İlan Sahibi',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => KullaniciProfilScreen(
                            kullaniciId: ilan.kullaniciId,
                            kullaniciAd: ilan.kullaniciAd,
                          ),
                        )),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              AvatarWidget(isim: ilan.kullaniciAd, radius: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ilan.kullaniciAd,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('Profili görüntüle →',
                                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.red)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                if (benzerIlanlar.isNotEmpty) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Benzer İlanlar',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
                      } else {
                        await ref.read(ilanRepositoryProvider)
                            .favoriyeEkle(kullaniciId: uid, ilan: ilan);
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
                        onPressed: _mesajGonder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text('Mesaj Gönder',
                            style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  String _tamTarih(DateTime tarih) {
    const ay = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${tarih.day} ${ay[tarih.month]} ${tarih.year}';
  }
}

// ── Ortak widget'lar ──────────────────────────────────────────────────────────

class _BenzerIlanKarti extends StatelessWidget {
  final IlanModel ilan;
  const _BenzerIlanKarti({required this.ilan});

  @override
  Widget build(BuildContext context) {
    final resimler = ilan.tumResimler;
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(
        pageBuilder: (ctx, anim, secAnim) => IlanDetayScreen(ilan: ilan),
        transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      )),
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
                      placeholder: (_, _) => Container(height: 90, color: AppColors.divider),
                      errorWidget: (_, _, _) => Container(height: 90, color: AppColors.divider,
                          child: const Icon(Icons.image_outlined, color: AppColors.textHint)))
                  : Container(width: 130, height: 90, color: AppColors.divider,
                      child: const Icon(Icons.image_outlined, color: AppColors.textHint)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(ilan.ucret.isNotEmpty ? '${ilan.ucret} ₺' : 'Belirtilmemiş',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: ilan.ucret.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                          color: ilan.ucret.isNotEmpty ? AppColors.red : AppColors.textHint)),
                ],
              ),
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
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
        fadeInDuration: Duration.zero, memCacheWidth: 600,
        placeholder: (_, _) => Container(color: AppColors.surface),
        errorWidget: (_, _, _) => Container(color: AppColors.surface,
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
                style: const TextStyle(color: Colors.white, fontSize: 14))
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
                placeholder: (_, _) => const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
                errorWidget: (_, _, _) => const Icon(
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
              fontSize: 14, color: labelColor, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
