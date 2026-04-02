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
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/avatar_widget.dart';
 
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
    _otuzGunKontrol();
  }
 
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
 
  // 30 gün geçmişse ilanı pasife al
  Future<void> _otuzGunKontrol() async {
    final tarih = widget.ilan.olusturmaTarihi;
    if (tarih == null) return;
    final fark = DateTime.now().difference(tarih).inDays;
    if (fark >= 30 && widget.ilan.aktif) {
      await ref
          .read(ilanRepositoryProvider)
          .ilanPasifYap(widget.ilan.id);
    }
  }
 
  bool get _benimIlanim {
    final uid = ref.read(currentUserProvider)?.uid;
    return uid != null && uid == widget.ilan.kullaniciId;
  }
 
  void _mesajGonder() {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final ilan = widget.ilan;
    final resimler = ilan.tumResimler;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SohbetScreen(
          karsiKullaniciId: ilan.kullaniciId,
          karsiKullaniciAd: ilan.kullaniciAd,
          ilanId: ilan.id,
          ilanBaslik: ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
          ilanResimUrl: resimler.isNotEmpty ? resimler.first : null,
        ),
      ),
    );
  }
 
  void _ucNoktaMenu() {
    final uid = ref.read(currentUserProvider)?.uid;
    final ilan = widget.ilan;
 
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
 
            if (_benimIlanim)
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
                        tip: ilan.tip,
                        duzenlenecekIlan: ilan,
                      ),
                    ),
                  ).then((_) {
                    ref.read(istekIlanlarProvider.notifier).yenile();
                    ref.read(tasiyiciIlanlarProvider.notifier).yenile();
                  });
                },
              ),
 
            if (_benimIlanim)
              _MenuItem(
                icon: Icons.delete_outline,
                iconColor: AppColors.red,
                label: 'İlanı Sil',
                labelColor: AppColors.red,
                onTap: () async {
                  Navigator.pop(ctx);
                  final onay = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      title: Text('İlanı Sil',
                          style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      content: Text(
                          'Bu ilanı silmek istediğine emin misin?',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text('İptal',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text('Sil',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (onay == true && mounted) {
                    await ref
                        .read(ilanRepositoryProvider)
                        .ilanSil(ilan.id);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
 
            if (uid != null && !_benimIlanim)
              _MenuItem(
                icon: Icons.flag_outlined,
                iconColor: AppColors.red,
                label: 'Şikayet Et',
                labelColor: AppColors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _sikayetDialog(uid);
                },
              ),
 
            if (uid != null && !_benimIlanim)
              _MenuItem(
                icon: Icons.block_outlined,
                iconColor: AppColors.red,
                label: 'Kullanıcıyı Engelle',
                labelColor: AppColors.red,
                onTap: () async {
                  Navigator.pop(ctx);
                  final onay = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      title: Text('Kullanıcıyı Engelle',
                          style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      content: Text(
                          '${ilan.kullaniciAd} adlı kullanıcıyı engellemek istiyor musun?',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text('İptal',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text('Engelle',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (onay == true && mounted) {
                    await ref.read(engellemeProvider.notifier).engelle(
                          benimUid: uid,
                          hedefUid: ilan.kullaniciId,
                        );
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
 
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
 
  Future<void> _sikayetDialog(String uid) async {
    String? seciliSebep;
    final sebepler = [
      'Sahte ilan', 'Yanıltıcı bilgi', 'Uygunsuz içerik', 'Spam', 'Diğer',
    ];
 
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: Text('Şikayet Et',
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: sebepler.map((s) {
              return RadioListTile<String>(
                value: s,
                groupValue: seciliSebep,
                onChanged: (v) => setS(() => seciliSebep = v),
                title: Text(s,
                    style: GoogleFonts.dmSans(fontSize: 14)),
                activeColor: AppColors.red,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: seciliSebep == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await ref
                          .read(sikayetProvider.notifier)
                          .sikayetGonder(
                            sikayetEdenId: uid,
                            hedefId: widget.ilan.kullaniciId,
                            hedefAd: widget.ilan.kullaniciAd,
                            sebep: seciliSebep!,
                            ilanId: widget.ilan.id,
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Şikayetiniz iletildi.',
                                style: GoogleFonts.dmSans()),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: Text('Gönder',
                  style: GoogleFonts.dmSans(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600)),
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
    final kategoriAdi_ = kategoriAdi(ilan.kategori);
    final uid = ref.watch(currentUserProvider)?.uid;
 
    final favoriAsync = uid != null && !_benimIlanim
        ? ref.watch(ilanFavorideMiProvider(ilan.id))
        : const AsyncData(false);
    final favorideMi = favoriAsync.value ?? false;
 
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: resimler.isNotEmpty ? 300 : 0,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: AppColors.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (uid != null && !_benimIlanim)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      favorideMi
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: favorideMi
                          ? AppColors.red
                          : AppColors.textPrimary,
                    ),
                  ),
                  onPressed: () async {
                    if (favorideMi) {
                      await ref
                          .read(ilanRepositoryProvider)
                          .favoridanCikar(
                              kullaniciId: uid, ilanId: ilan.id);
                    } else {
                      await ref
                          .read(ilanRepositoryProvider)
                          .favoriyeEkle(
                              kullaniciId: uid, ilan: ilan);
                    }
                  },
                ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert,
                      size: 20, color: AppColors.textPrimary),
                ),
                onPressed: _ucNoktaMenu,
              ),
            ],
            flexibleSpace: resimler.isNotEmpty
                ? FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        // Hero animasyonlu resim
                        PageView.builder(
                          controller: _pageController,
                          itemCount: resimler.length,
                          onPageChanged: (i) =>
                              setState(() => _aktifResim = i),
                          itemBuilder: (_, i) => i == 0
                              ? Hero(
                                  tag: 'ilan_resim_${ilan.id}',
                                  child: CachedNetworkImage(
                                    imageUrl: resimler[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    fadeInDuration: Duration.zero,
                                    placeholder: (_, __) => Container(
                                        color: AppColors.surface),
                                    errorWidget: (_, __, ___) =>
                                        Container(
                                            color: AppColors.surface,
                                            child: const Icon(
                                                Icons.image_outlined,
                                                color: AppColors.textHint,
                                                size: 48)),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: resimler[i],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  fadeInDuration: Duration.zero,
                                  placeholder: (_, __) =>
                                      Container(color: AppColors.surface),
                                  errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surface,
                                      child: const Icon(
                                          Icons.image_outlined,
                                          color: AppColors.textHint,
                                          size: 48)),
                                ),
                        ),
                        if (resimler.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: List.generate(
                                resimler.length,
                                (i) => AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: _aktifResim == i ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _aktifResim == i
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.5),
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : null,
          ),
 
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kategoriAdi_.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(kategoriAdi_,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.red,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 10),
                  ],
 
                  Text(
                    ilan.urun.isNotEmpty ? ilan.urun : 'İlan',
                    style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
 
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_money_outlined,
                            size: 20,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          ilan.ucret.isNotEmpty
                              ? '${ilan.ucret} ₺'
                              : 'Ücret belirtilmemiş',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ilan.ucret.isNotEmpty
                                ? AppColors.red
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
 
                  _BilgiSatiri(
                    icon: Icons.flight_takeoff_outlined,
                    etiket: 'Nereden',
                    deger: ilan.nereden,
                  ),
                  const SizedBox(height: 12),
                  _BilgiSatiri(
                    icon: Icons.flight_land_outlined,
                    etiket: 'Nereye',
                    deger: ilan.nereye,
                  ),
 
                  if (ilan.tarih != null) ...[
                    const SizedBox(height: 12),
                    _BilgiSatiri(
                      icon: Icons.calendar_today_outlined,
                      etiket: 'Seyahat Tarihi',
                      deger:
                          '${ilan.tarih!.day}.${ilan.tarih!.month}.${ilan.tarih!.year}',
                    ),
                  ],
 
                  // İlan tarihi
                  if (ilan.olusturmaTarihi != null) ...[
                    const SizedBox(height: 12),
                    _BilgiSatiri(
                      icon: Icons.access_time_outlined,
                      etiket: 'İlan Tarihi',
                      deger: _tamTarih(ilan.olusturmaTarihi!),
                    ),
                  ],
 
                  if (ilan.notlar.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    Text('Notlar',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      ilan.notlar,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5),
                    ),
                  ],
 
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
 
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KullaniciProfilScreen(
                          kullaniciId: ilan.kullaniciId,
                          kullaniciAd: ilan.kullaniciAd,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        AvatarWidget(
                            isim: ilan.kullaniciAd, radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(ilan.kullaniciAd,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              Text('Profili görüntüle',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
 
      bottomNavigationBar: uid != null && !_benimIlanim
          ? Container(
              padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: AppColors.divider)),
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _mesajGonder,
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white, size: 18),
                  label: Text('Mesaj Gönder',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            )
          : null,
    );
  }
 
  String _tamTarih(DateTime tarih) {
    final ay = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${tarih.day} ${ay[tarih.month]} ${tarih.year}';
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
              fontSize: 14,
              color: labelColor,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
 
class _BilgiSatiri extends StatelessWidget {
  final IconData icon;
  final String etiket;
  final String deger;
 
  const _BilgiSatiri({
    required this.icon,
    required this.etiket,
    required this.deger,
  });
 
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiket,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(deger,
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}