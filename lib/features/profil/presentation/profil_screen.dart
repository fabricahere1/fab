import 'package:flutter/material.dart';
import '../domain/kullanici_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/profil_stilleri.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../favoriler/presentation/favoriler_screen.dart';
import 'ilanlarim_screen.dart';
import 'ayarlar_screen.dart';
import 'profil_duzenle_screen.dart';
import 'gizlilik_politikasi_screen.dart';
import 'kullanim_kosullari_screen.dart';
import '../../degerlendirme/presentation/degerlendirmeler_liste_screen.dart';
import '../../degerlendirme/providers/degerlendirme_provider.dart';
import '../../degerlendirme/presentation/degerlendirme_screen.dart';
import '../../ilanlar/domain/ilan_model.dart';
import '../../ilanlar/presentation/ilan_form_screen.dart';
import '../../ilanlar/providers/ilan_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/rendering.dart';
import '../../../shared/utils/app_hata_yonetici.dart';
import 'widgets/iletisim_form_sheet.dart';
import '../../../shared/utils/app_snackbar.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen>
    with AutomaticKeepAliveClientMixin {

  final _scrollCtrl = ScrollController();
  double _sonScrollPixel = 0;
  static const double _threshold = 80;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    final simdi = pos.pixels;
    if (pos.userScrollDirection == ScrollDirection.reverse) {
      _sonScrollPixel = simdi;
      ref.read(navBarGizliProvider.notifier).gizle();
    } else if (pos.userScrollDirection == ScrollDirection.forward) {
      if (simdi < _sonScrollPixel - _threshold) {
        _sonScrollPixel = simdi;
        ref.read(navBarGizliProvider.notifier).goster();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _cikisDialog() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Çıkış Yap',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Hesabından çıkmak istediğine emin misin?',
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Çıkış Yap',
                style: GoogleFonts.manrope(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (onay == true) {
      ref.read(authProvider.notifier).cikisYap();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(currentUserProvider);

    // Misafir durumu — giriş yapılmamış
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Profil',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE8E3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 40, color: AppColors.textHint),
                ),
                const SizedBox(height: 20),
                Text('Profilini görüntülemek için giriş yap',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('İlanlarını yönet, mesajlarını gör ve değerlendirmelerini takip et.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => context.push(AppRoutes.login),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Giriş Yap',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.push(AppRoutes.register),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Kayıt Ol',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final benimProfilAsync = ref.watch(benimKullaniciProfilProvider);
    final uid = user.uid;

    // Reddedilen ilan sayısı badge için
    final ilanlarAsync = ref.watch(ilanlarimProvider);
    final reddedilenSayi = ilanlarAsync.when(
      data: (liste) => liste.where((i) => i.durum == IlanDurum.reddedildi).length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── Profil Kartı ──────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AvatarWidget(
                  isim: user.displayName ?? user.email ?? '',
                  fotoUrl: benimProfilAsync.value?.fotoUrl ?? user.photoURL,
                  radius: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Kullanıcı',
                        style: ProfilStilleri.isim,
                      ),
                      const SizedBox(height: 2),
                      if ((user.email ?? '').isNotEmpty)
                        Text(user.email!, style: ProfilStilleri.altBilgi),
                      const SizedBox(height: 8),
                      benimProfilAsync.when(
                        data: (profil) {
                          final telefon = profil?.telefon ?? '';
                          final telefonGizli = profil?.telefonGizli ?? false;
                          final sehir = (profil?.bulunduguSehir.isNotEmpty ?? false)
                              ? profil!.bulunduguSehir
                              : (profil?.yasadigiUlke ?? '');
                          final puan = profil?.ortalamaPuan ?? 0.0;
                          final sayi = profil?.degerlendirmeSayisi ?? 0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (telefon.isNotEmpty) ...[
                                Row(children: [
                                  const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(telefon, style: ProfilStilleri.detaySatiri),
                                  if (telefonGizli) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.visibility_off_outlined, size: 12, color: AppColors.textHint),
                                    const SizedBox(width: 2),
                                    Text('Gizli', style: ProfilStilleri.detaySatiriHint),
                                  ],
                                ]),
                                const SizedBox(height: 2),
                              ],
                              if (sehir.isNotEmpty)
                                Row(children: [
                                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(sehir, style: ProfilStilleri.detaySatiri),
                                ])
                              else
                                Text('Konum eklenmemiş',
                                    style: ProfilStilleri.detaySatiriHint),
                              if (sayi > 0) ...[
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    final uid2 = ref.read(currentUserProvider)?.uid ?? '';
                                    final ad = profil?.adSoyad ?? '';
                                    if (uid2.isEmpty) return;
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => DegerlendirmelerListeScreen(
                                        kullaniciId: uid2, kullaniciAd: ad),
                                    ));
                                  },
                                  child: Row(children: [
                                    ...List.generate(5, (i) => Icon(
                                      i < puan.floor() ? Icons.star_rounded
                                          : (i < puan ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                      color: const Color(0xFFFFA726), size: 14,
                                    )),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${puan.toStringAsFixed(1)} ($sayi)',
                                      style: ProfilStilleri.puanYazi,
                                    ),
                                  ]),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) { AppHataYonetici.logla(e, s, etiket: 'profilScreen.puanSatiri'); return const SizedBox.shrink(); },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilDuzenleScreen())),
                ),
              ],
            ),
          ),

          // ── İstatistikler + Güven + Rozetler ─────────
          benimProfilAsync.when(
            data: (profil) {
              if (profil == null) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        _StatKutu(
                          sayi: profil.takipciSayisi.toString(),
                          label: 'Takipçi',
                          onTap: () => context.push('/home/takip-listesi/${profil.id}?tab=takipcilar'),
                        ),
                        _StatAyrac(),
                        _StatKutu(
                          sayi: profil.takipSayisi.toString(),
                          label: 'Takip',
                          onTap: () => context.push('/home/takip-listesi/${profil.id}?tab=takipEdilenler'),
                        ),
                        _StatAyrac(),
                        _StatKutu(sayi: profil.degerlendirmeSayisi.toString(), label: 'Değerlendirme'),
                      ],
                    ),
                  ),
                  if (profil.guvenSkoru > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Puanı', style: ProfilStilleri.bolumBaslik),
                              Text('${profil.guvenSkoru}/100', style: ProfilStilleri.guvenSkoruDeger),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: profil.guvenSkoru / 100,
                              backgroundColor: const Color(0xFFF0F0F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                profil.guvenSkoru >= 80 ? const Color(0xFF4CAF50)
                                    : profil.guvenSkoru >= 60 ? const Color(0xFF2196F3)
                                    : profil.guvenSkoru >= 40 ? const Color(0xFFFFA726)
                                    : AppColors.red,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(profil.guvenSkoruEtiketi, style: ProfilStilleri.detaySatiri),
                        ],
                      ),
                    ),
                  ],
                  if (profil.rozetler.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rozetler', style: ProfilStilleri.bolumBaslik),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: profil.rozetler.map((rozet) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
                              ),
                              child: Text(
                                '${profil.rozetEmoji(rozet)} ${profil.rozetAdi(rozet)}',
                                style: ProfilStilleri.rozet,
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) { AppHataYonetici.logla(e, s, etiket: 'profilScreen.sohbetGecmisi'); return const SizedBox.shrink(); },
          ),

          // ── Hesabım ───────────────────────────────────
          _BolumBasligi('Hesabım'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.list_alt_outlined,
                label: 'İlanlarım',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IlanlarimScreen())),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.favorite_border,
                label: 'Favorilerim',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavorilerScreen())),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.star_border,
                label: 'Aldığım Değerlendirmeler',
                onTap: () {
                  final uid2 = ref.read(currentUserProvider)?.uid ?? '';
                  final ad = ref.read(benimKullaniciProfilProvider).value?.adSoyad ?? '';
                  if (uid2.isEmpty) return;
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DegerlendirmelerListeScreen(kullaniciId: uid2, kullaniciAd: ad),
                  ));
                },
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.hourglass_empty_rounded,
                label: 'Bekleyen Değerlendirmeler',
                onTap: () {
                  if (uid.isEmpty) return;
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _BekleyenDegerlendirmelerScreen(kullaniciId: uid),
                  ));
                },
              ),
              // Reddedilen ilan varsa göster
              if (reddedilenSayi > 0) ...[
                _Ayrac(),
                _SatirOge(
                  icon: Icons.cancel_outlined,
                  label: 'Reddedilen İlanlar',
                  labelColor: AppColors.red,
                  badge: reddedilenSayi,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _ReddedilenIlanlarScreen(uid: uid),
                    ));
                  },
                ),
              ],
            ],
          ),

          // ── Diğer ─────────────────────────────────────
          _BolumBasligi('Diğer'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.settings_outlined,
                label: 'Ayarlar',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AyarlarScreen())),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.mail_outline,
                label: 'İletişim',
                onTap: () => iletisimFormAc(
                  context: context,
                  kaynak: 'iletisim',
                  onGonderildi: () =>
                      AppSnackBar.basari(context, 'Mesajınız iletildi, teşekkürler!'),
                ),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.privacy_tip_outlined,
                label: 'Gizlilik Politikası',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GizlilikPolitikasiScreen())),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.description_outlined,
                label: 'Kullanım Koşulları',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KullanimKosullariScreen())),
              ),
            ],
          ),

          // ── Çıkış Yap ────────────────────────────────
          _BolumBasligi(''),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.logout,
                label: 'Çıkış Yap',
                labelColor: AppColors.red,
                showArrow: false,
                onTap: _cikisDialog,
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('İSTE v3.0',
                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textHint)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Reddedilen İlanlar Ekranı ─────────────────────────────

class _ReddedilenIlanlarScreen extends ConsumerStatefulWidget {
  final String uid;
  const _ReddedilenIlanlarScreen({required this.uid});

  @override
  ConsumerState<_ReddedilenIlanlarScreen> createState() =>
      _ReddedilenIlanlarScreenState();
}

class _ReddedilenIlanlarScreenState
    extends ConsumerState<_ReddedilenIlanlarScreen> {
  bool _genisletilmis = true;

  @override
  Widget build(BuildContext context) {
    final ilanlarAsync = ref.watch(ilanlarimProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Reddedilen İlanlar',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ilanlarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2)),
        error: (_, _) => Center(
          child: Text('Bir hata oluştu.', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
        ),
        data: (ilanlar) {
          final reddedilenler = ilanlar.where((i) => i.durum == IlanDurum.reddedildi).toList();
          if (reddedilenler.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.red),
                  ),
                  const SizedBox(height: 16),
                  Text('Reddedilen ilan yok',
                      style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Tüm ilanların uygun bulundu.',
                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Özet banner ──────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _genisletilmis = !_genisletilmis),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reddedilenler.length} ilan düzenleme bekliyor',
                              style: GoogleFonts.manrope(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Yayınlanmaları için gözden geçir',
                              style: GoogleFonts.manrope(
                                  fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _genisletilmis ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sade liste ───────────────────────────────────────────
              if (_genisletilmis) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < reddedilenler.length; i++) ...[
                        _ReddedilenSatir(ilan: reddedilenler[i]),
                        if (i < reddedilenler.length - 1)
                          const Divider(height: 0.5, color: Color(0xFFF5F5F5)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReddedilenSatir extends ConsumerWidget {
  final IlanModel ilan;
  const _ReddedilenSatir({required this.ilan});

  Future<void> _silOnayi(BuildContext context, WidgetRef ref) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('İlanı Sil',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Bu ilanı silmek istediğine emin misin? Bu işlem geri alınamaz.',
          style: GoogleFonts.manrope(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil',
                style: GoogleFonts.manrope(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay == true) {
      await ref.read(ilanIslemleriProvider.notifier).sil(ilan.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ilan.urun.isNotEmpty ? ilan.urun : '${ilan.nereden} → ${ilan.nereye}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IlanFormScreen(
                  tip: ilan.tip,
                  duzenlenecekIlan: ilan,
                ),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text('Düzenle',
                style: GoogleFonts.manrope(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          IconButton(
            onPressed: () => _silOnayi(context, ref),
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFCCCCCC)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  const _BolumBasligi(this.baslik);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        baslik.toUpperCase(),
        style: ProfilStilleri.bolumUstBaslik,
      ),
    );
  }
}

class _Kart extends StatelessWidget {
  final List<Widget> children;
  const _Kart({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }
}

class _Ayrac extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 54, endIndent: 0);
  }
}

class _SatirOge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;
  final bool showArrow;
  final int badge;

  const _SatirOge({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor = AppColors.textPrimary,
    this.showArrow = true,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: labelColor == AppColors.textPrimary ? const Color(0xFF7C3AED) : labelColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.manrope(fontSize: 15, color: labelColor, fontWeight: FontWeight.w400)),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            if (showArrow)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bekleyen Değerlendirmeler ─────────────────────────────

class _BekleyenDegerlendirmelerScreen extends ConsumerWidget {
  final String kullaniciId;
  const _BekleyenDegerlendirmelerScreen({required this.kullaniciId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bekleyenlerAsync = ref.watch(bekleyenDegerlendirmelerProvider(kullaniciId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Bekleyen Değerlendirmeler',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: bekleyenlerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED), strokeWidth: 2)),
        error: (_, _) => Center(
          child: Text('Bir hata oluştu.', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
        ),
        data: (liste) {
          if (liste.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.hourglass_empty_rounded, size: 36, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(height: 16),
                  Text('Bekleyen değerlendirme yok',
                      style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Teslim aldıktan sonra değerlendirme\nyapabilirsin.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: liste.length,
            itemBuilder: (ctx, i) {
              final item = liste[i];
              final sohbetId = item['sohbetId'] as String? ?? '';
              return _BekleyenKarti(sohbetId: sohbetId, kullaniciId: kullaniciId, index: i);
            },
          );
        },
      ),
    );
  }
}

class _BekleyenKarti extends ConsumerWidget {
  final String sohbetId;
  final String kullaniciId;
  final int index;

  const _BekleyenKarti({required this.sohbetId, required this.kullaniciId, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sohbetAsync = ref.watch(sohbetDurumuProvider(sohbetId));

    return sohbetAsync.when(
      loading: () => const SizedBox(height: 72),
      error: (e, s) { AppHataYonetici.logla(e, s, etiket: 'profilScreen.sohbetDurumu'); return const SizedBox.shrink(); },
      data: (sohbet) {
        if (sohbet.isEmpty) return const SizedBox.shrink();
        final kullanicilar = List<String>.from(sohbet['kullanicilar'] ?? []);
        final karsiId = kullanicilar.where((id) => id != kullaniciId).firstOrNull ?? '';
        final ilanBaslik = sohbet['ilanBaslik'] as String? ?? 'İlan';
        final karsiProfilAsync = karsiId.isNotEmpty ? ref.watch(kullaniciBilgiProvider(karsiId)) : null;
        final karsiAd = karsiProfilAsync?.value?.adSoyad.isNotEmpty == true ? karsiProfilAsync!.value!.adSoyad : 'Kullanıcı';
        final karsiFotoUrl = karsiProfilAsync?.value?.fotoUrl;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.star_rounded, color: Color(0xFF7C3AED), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ilanBaslik,
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(karsiAd, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    if (karsiId.isEmpty) return;
                    final tamamlandi = await DegerlendirmeModal.goster(
                      context: context,
                      sohbetId: sohbetId,
                      hedefKullaniciId: karsiId,
                      hedefKullaniciAd: karsiAd,
                      hedefFotoUrl: karsiFotoUrl,
                    );
                    if (tamamlandi && context.mounted) {
                      await ref.read(degerlendirmeIslemleriProvider.notifier).bekleyenTamamla(
                        sohbetId: sohbetId, kullaniciId: kullaniciId,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(20)),
                    child: Text('Değerlendir',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Stat widget'ları ──────────────────────────────────────

class _StatKutu extends StatelessWidget {
  final String sayi;
  final String label;
  final VoidCallback? onTap;
  const _StatKutu({required this.sayi, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(sayi, style: ProfilStilleri.istatistikSayi),
            const SizedBox(height: 2),
            Text(label, style: ProfilStilleri.istatistikEtiket),
          ],
        ),
      ),
    ),
  );
}

class _StatAyrac extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 0.5, height: 40, color: AppColors.divider);
}