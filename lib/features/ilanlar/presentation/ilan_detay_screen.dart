// lib/features/ilanlar/presentation/ilan_detay_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../teklifler/providers/teklif_provider.dart';
import '../../teklifler/domain/teklif_model.dart';
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

  void _teklifVerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TeklifVerSheet(ilan: widget.ilan),
    );
  }

  void _gelenTekliflerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => _GelenTekliflerSheet(
          ilanId: widget.ilan.id,
          ilanBaslik: widget.ilan.urun.isNotEmpty ? widget.ilan.urun : 'İlan',
          scrollController: scrollCtrl,
        ),
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

    final teklifOzetAsync = benimIlan
        ? ref.watch(ilanTeklifOzetProvider(ilan.id))
        : null;
    final teklifOzet = teklifOzetAsync?.value;

    // ✅ Kabul edilmiş teklif var mı? (teklif veren için)
    final kabulTeklifAsync = !benimIlan && uid != null
        ? ref.watch(ilanKabulTeklifiProvider(ilan.id, uid))
        : null;
    final anlasildi = kabulTeklifAsync?.value != null;

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
                      Row(
                        children: [
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
                          // İlan sahibine teklif badge
                          if (benimIlan && teklifOzet != null && teklifOzet.sayi > 0) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _gelenTekliflerSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_offer_outlined,
                                        size: 15, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text(
                                      teklifOzet.sayi == 1
                                          ? '${teklifOzet.enYuksek!.toStringAsFixed(0)} ₺ teklif'
                                          : '${teklifOzet.sayi} teklif • En yüksek: ${teklifOzet.enYuksek!.toStringAsFixed(0)} ₺',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // ✅ Teklif verene anlaşıldı badge
                          if (!benimIlan && anlasildi) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.green.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.handshake_outlined,
                                      size: 15, color: AppColors.green),
                                  const SizedBox(width: 5),
                                  Text('Anlaşıldı',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.green)),
                                ],
                              ),
                            ),
                          ],
                        ],
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

      // ✅ Bottom bar: anlaşıldıysa teklif ver yerine anlaşıldı badge göster
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
                  if (ilan.ucret.isNotEmpty) ...[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        // ✅ Anlaşıldıysa badge, değilse teklif ver butonu
                        child: anlasildi
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.green.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.handshake_outlined,
                                        size: 18, color: AppColors.green),
                                    const SizedBox(width: 8),
                                    Text('Anlaşıldı',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.green)),
                                  ],
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: _teklifVerSheet,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF9800),
                                  side: const BorderSide(
                                      color: Color(0xFFFF9800), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.local_offer_outlined, size: 18),
                                label: Text('Teklif Ver',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
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

// ── Teklif Ver Sheet ──────────────────────────────────────────────────────────

class _TeklifVerSheet extends ConsumerStatefulWidget {
  final IlanModel ilan;
  const _TeklifVerSheet({required this.ilan});

  @override
  ConsumerState<_TeklifVerSheet> createState() => _TeklifVerSheetState();
}

class _TeklifVerSheetState extends ConsumerState<_TeklifVerSheet> {
  final _ctrl    = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ilan       = widget.ilan;
    final ilanMiktar = double.tryParse(ilan.ucret) ?? 0;
    final yukleniyor = ref.watch(teklifProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Teklif Ver',
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (ilanMiktar > 0)
                Text('İlan fiyatı: ${ilan.ucret} ₺',
                    style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textHint),
                  suffixText: '₺',
                  suffixStyle: GoogleFonts.dmSans(
                      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Lütfen bir tutar girin';
                  final m = double.tryParse(v);
                  if (m == null || m <= 0) return 'Geçerli bir tutar girin';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (ilanMiktar > 0)
                Wrap(
                  spacing: 8,
                  children: [0.9, 0.8, 0.7].map((oran) {
                    final deger = (ilanMiktar * oran).round();
                    return ActionChip(
                      label: Text('$deger ₺',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.divider),
                      onPressed: () => setState(() => _ctrl.text = deger.toString()),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: yukleniyor ? null : _gonder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: yukleniyor
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Teklifi Gönder',
                          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _gonder() async {
    if (!_formKey.currentState!.validate()) return;

    final miktar    = double.parse(_ctrl.text.trim());
    final kullanici = ref.read(currentUserProvider);
    if (kullanici == null) return;

    final ilan       = widget.ilan;
    final ilanMiktar = double.tryParse(ilan.ucret) ?? 0;
    final profil     = ref.read(benimKullaniciProfilProvider).value;
    final adSoyad    = profil?.adSoyad ?? kullanici.displayName ?? 'Kullanıcı';

    final basarili = await ref.read(teklifProvider.notifier).teklifVer(
      ilanId:        ilan.id,
      ilanBaslik:    ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
      ilanSahibiId:  ilan.kullaniciId,
      ilanSahibiAd:  ilan.kullaniciAd,
      teklifVerenId: kullanici.uid,
      teklifVerenAd: adSoyad,
      miktar:        miktar,
      ilanMiktar:    ilanMiktar,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        basarili ? 'Teklifiniz gönderildi! 🎉' : 'Bir hata oluştu, tekrar deneyin.',
        style: GoogleFonts.dmSans(),
      ),
      backgroundColor: basarili ? AppColors.green : AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Gelen Teklifler Sheet ─────────────────────────────────────────────────────

class _GelenTekliflerSheet extends ConsumerWidget {
  final String ilanId;
  final String ilanBaslik;
  final ScrollController scrollController;

  const _GelenTekliflerSheet({
    required this.ilanId,
    required this.ilanBaslik,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tekliflerAsync = ref.watch(ilanTeklifleriProvider(ilanId));

    return Column(
      children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text('Gelen Teklifler',
                  style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              tekliflerAsync.when(
                data: (t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${t.length} teklif',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF9800))),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: tekliflerAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2)),
            error: (_, _) => Center(
                child: Text('Bir hata oluştu',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary))),
            data: (teklifler) {
              if (teklifler.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 48, color: AppColors.divider),
                      const SizedBox(height: 12),
                      Text('Henüz teklif yok',
                          style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: teklifler.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) => _TeklifKarti(teklif: teklifler[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Teklif Kartı ──────────────────────────────────────────────────────────────

class _TeklifKarti extends ConsumerWidget {
  final TeklifModel teklif;
  const _TeklifKarti({required this.teklif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yukleniyor = ref.watch(teklifProvider).isLoading;
    final benimUid   = ref.watch(currentUserProvider)?.uid ?? '';
    final benimAd    = ref.watch(currentUserProvider)?.displayName ?? '';
    final karsiCtrl  = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(isim: teklif.teklifVerenAd, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teklif.teklifVerenAd,
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (teklif.olusturmaTarihi != null)
                      Text(_zamanFarki(teklif.olusturmaTarihi!),
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${teklif.miktar.toStringAsFixed(0)} ₺',
                  style: GoogleFonts.dmSans(
                      fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFE65100)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: yukleniyor
                        ? null
                        : () async {
                            final basarili = await ref
                                .read(teklifProvider.notifier)
                                .teklifKabul(
                                  teklif: teklif,
                                  kabulEdenId: benimUid,
                                  kabulEdenAd: benimAd,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                  basarili ? 'Teklif kabul edildi! 🎉' : 'Hata oluştu.',
                                  style: GoogleFonts.dmSans(),
                                ),
                                backgroundColor: basarili ? AppColors.green : AppColors.red,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Kabul Et',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: yukleniyor
                        ? null
                        : () => _karsiTeklifDialog(context, ref, karsiCtrl),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9800),
                      side: const BorderSide(color: Color(0xFFFF9800)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Karşı Teklif',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38, width: 38,
                child: IconButton(
                  onPressed: yukleniyor
                      ? null
                      : () async {
                          await ref.read(teklifProvider.notifier).teklifReddet(teklif);
                        },
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _karsiTeklifDialog(BuildContext context, WidgetRef ref, TextEditingController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Karşı Teklif',
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gelen teklif: ${teklif.miktar.toStringAsFixed(0)} ₺',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Teklifiniz',
                suffixText: '₺',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final miktar = double.tryParse(ctrl.text.trim());
              if (miktar == null || miktar <= 0) return;
              Navigator.pop(ctx);
              await ref.read(teklifProvider.notifier)
                  .karsiTeklifVer(teklif: teklif, karsiMiktar: miktar);
            },
            child: Text('Gönder',
                style: GoogleFonts.dmSans(
                    color: const Color(0xFFFF9800), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _zamanFarki(DateTime tarih) {
    final fark = DateTime.now().difference(tarih);
    if (fark.inMinutes < 1) return 'Az önce';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dk önce';
    if (fark.inHours < 24) return '${fark.inHours} saat önce';
    return '${fark.inDays} gün önce';
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