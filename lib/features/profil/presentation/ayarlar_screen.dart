import 'dart:async';
import '../../../shared/utils/app_hata_yonetici.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../../degerlendirme/presentation/degerlendirmeler_liste_screen.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/widgets/avatar_widget.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_router.dart' show AppRoutes, navigatorKey;
import 'sss_screen.dart';
import 'kullanim_kosullari_screen.dart';
import 'gizlilik_politikasi_screen.dart';
import 'widgets/iletisim_form_sheet.dart';

class AyarlarScreen extends ConsumerStatefulWidget {
  const AyarlarScreen({super.key});

  @override
  ConsumerState<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends ConsumerState<AyarlarScreen> {
  bool _ilanBildirimleri    = true;
  bool _mesajBildirimleri   = true;
  bool _sistemBildirimleri  = true;
  bool _bildirimlerYuklendi = false;
  final _silmeAsamasi = ValueNotifier<String>('Kimlik doğrulanıyor...');

  @override
  void initState() {
    super.initState();
    _bildirimlerYukle();
  }

  @override
  void dispose() {
    _silmeAsamasi.dispose();
    super.dispose();
  }

  Future<void> _bildirimlerYukle() async {
    final uid = ref.read(currentUserProvider)?.uid;
    // Önce local cache'den yükle (hızlı)
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _ilanBildirimleri   = prefs.getBool('bildirim_ilan')   ?? true;
      _mesajBildirimleri  = prefs.getBool('bildirim_mesaj')  ?? true;
      _sistemBildirimleri = prefs.getBool('bildirim_sistem') ?? true;
      _bildirimlerYuklendi = true;
    });
    // Firestore'dan güncel değeri al (doğru kaynak)
    if (uid == null) return;
    try {
      final tercihler = await ref.read(kullaniciRepositoryProvider)
          .bildirimTercihleriGetir(uid);
      if (tercihler == null) return;
      if (!mounted) return;
      setState(() {
        _mesajBildirimleri  = tercihler['mesaj']  ?? true;
        _ilanBildirimleri   = tercihler['ilan']   ?? true;
        _sistemBildirimleri = tercihler['sistem'] ?? true;
      });
      await prefs.setBool('bildirim_mesaj',  _mesajBildirimleri);
      await prefs.setBool('bildirim_ilan',   _ilanBildirimleri);
      await prefs.setBool('bildirim_sistem', _sistemBildirimleri);
    } catch (e, s) { AppHataYonetici.logla(e, s, etiket: 'ayarlarScreen'); }
  }

  Future<void> _bildirimKaydet(String key, bool value) async {
    // Local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    // Firestore'a yaz
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final firestoreKey = key.replaceFirst('bildirim_', '');
    try {
      await ref.read(kullaniciRepositoryProvider)
          .bildirimTercihGuncelle(uid, firestoreKey, value);
    } catch (e, s) { AppHataYonetici.logla(e, s, etiket: 'ayarlarScreen'); }
  }

  @override
  Widget build(BuildContext context) {
    final user               = ref.watch(currentUserProvider);
    final benimProfilAsync   = ref.watch(benimKullaniciProfilProvider);
    final engellenenlerAsync = ref.watch(engellenenlerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Ayarlar',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [

          // ── Hesap ───────────────────────────────────
          _BolumBasligi('Hesap'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.email_outlined,
                label: 'E-posta',
                trailing: Text(
                  user?.email ?? '',
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                onTap: () {},
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.phone_outlined,
                label: 'Telefon Numarası',
                trailing: Text(
                  benimProfilAsync.value?.telefon?.isNotEmpty == true
                      ? benimProfilAsync.value!.telefon!
                      : 'Eklenmemiş',
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                onTap: () => _telefonGuncelleDialog(
                    benimProfilAsync.value?.telefon ?? ''),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.visibility_off_outlined,
                label: 'Numarayı Gizle',
                showArrow: false,
                trailing: Transform.scale(
                  scale: 0.85,
                  child: CupertinoSwitch(
                    value: benimProfilAsync.value?.telefonGizli ?? false,
                    onChanged: (val) => _telefonGizliDegistir(val),
                    activeTrackColor: AppColors.purple,
                  ),
                ),
                onTap: () => _telefonGizliDegistir(
                    !(benimProfilAsync.value?.telefonGizli ?? false)),
              ),
            ],
          ),

          // ── Bildirimler ─────────────────────────────
          _BolumBasligi('Bildirimler'),
          _Kart(
            children: !_bildirimlerYuklendi
                ? [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.red)),
                    )
                  ]
                : [
                    _SwitchSatir(
                      icon: Icons.mark_chat_unread_outlined,
                      label: 'Mesaj bildirimleri',
                      acik: _mesajBildirimleri,
                      onChanged: (v) {
                        setState(() => _mesajBildirimleri = v);
                        _bildirimKaydet('bildirim_mesaj', v);
                      },
                    ),
                    _Ayrac(),
                    _SwitchSatir(
                      icon: Icons.campaign_outlined,
                      label: 'İlan bildirimleri',
                      acik: _ilanBildirimleri,
                      onChanged: (v) {
                        setState(() => _ilanBildirimleri = v);
                        _bildirimKaydet('bildirim_ilan', v);
                      },
                    ),
                    _Ayrac(),
                    _SwitchSatir(
                      icon: Icons.notifications_outlined,
                      label: 'Sistem bildirimleri',
                      acik: _sistemBildirimleri,
                      onChanged: (v) {
                        setState(() => _sistemBildirimleri = v);
                        _bildirimKaydet('bildirim_sistem', v);
                      },
                    ),
                  ],
          ),

          // ── Gizlilik ────────────────────────────────
          _BolumBasligi('Gizlilik'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.block_outlined,
                label: 'Engellenen Kullanıcılar',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    engellenenlerAsync.value?.length.toString() ?? '0',
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () => _engellenenlerSayfasi(
                    engellenenlerAsync.value ?? []),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.privacy_tip_outlined,
                label: 'Gizlilik Politikası',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GizlilikPolitikasiScreen()),
                ),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.description_outlined,
                label: 'Kullanım Koşulları',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const KullanimKosullariScreen()),
                ),
              ),
            ],
          ),

          // ── Değerlendirmelerim ───────────────────────
          _BolumBasligi('Aldığım Değerlendirmeler'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.rate_review_outlined,
                label: 'Tüm Değerlendirmelerim',
                onTap: () {
                  final uid = ref.read(currentUserProvider)?.uid ?? '';
                  final ad  = ref
                          .read(benimKullaniciProfilProvider)
                          .value
                          ?.adSoyad ??
                      'Ben';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DegerlendirmelerListeScreen(
                        kullaniciId: uid,
                        kullaniciAd: ad,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Destek ──────────────────────────────────
          _BolumBasligi('Destek'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.support_agent_outlined,
                label: 'Destek',
                onTap: () => iletisimFormAc(
                  context: context,
                  kaynak: 'destek',
                  onGonderildi: () =>
                      AppSnackBar.basari(context, 'Mesajınız iletildi, teşekkürler!'),
                ),
              ),
              _Ayrac(),
              _SatirOge(
                icon: Icons.help_outline,
                label: 'Sık Sorulan Sorular',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SssScreen()),
                ),
              ),
            ],
          ),

          // ── Admin ───────────────────────────────────
          if (user?.email == 'fabricahere@gmail.com')
            _BolumBasligi('Admin'),
          if (user?.email == 'fabricahere@gmail.com')
            _Kart(
              children: [
                _SatirOge(
                  icon: Icons.sync_outlined,
                  label: 'Algolia Toplu Aktar',
                  iconColor: Colors.blue,
                  onTap: () async {
                    try {
                      await FirebaseFunctions
                          .instanceFor(region: 'europe-west1')
                          .httpsCallable('algoliaTopluAktar')
                          .call({});
                      if (context.mounted) {
                        AppSnackBar.basari(context, 'Aktarım tamamlandı.');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackBar.hata(context, 'Hata: $e');
                      }
                    }
                  },
                ),
              ],
            ),

          // ── Tehlikeli Bölge ─────────────────────────
          _BolumBasligi('Tehlikeli Bölge'),
          _Kart(
            children: [
              _SatirOge(
                icon: Icons.delete_forever_outlined,
                label: 'Hesabı Sil',
                labelColor: AppColors.red,
                iconColor: AppColors.red,
                showArrow: false,
                onTap: () => _hesapSilDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('İSTE v3.0',
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textHint)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _telefonGizliDegistir(bool yeniDeger) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(profilDuzenleProvider.notifier).profilGuncelle(
      uid: uid,
      data: {'telefonGizli': yeniDeger},
    );
    ref.invalidate(benimKullaniciProfilProvider);
  }

  Future<void> _telefonGuncelleDialog(String mevcutTelefon) async {
    final ctrl = TextEditingController(text: mevcutTelefon);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Telefon Numarası',
              style: GoogleFonts.manrope(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '05XX XXX XX XX',
                  hintStyle: GoogleFonts.manrope(
                      color: AppColors.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.textSecondary, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal',
                  style: GoogleFonts.manrope(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final uid = ref.read(currentUserProvider)?.uid;
                if (uid == null) return;
                await ref.read(profilDuzenleProvider.notifier).profilGuncelle(
                  uid: uid,
                  data: {'telefon': ctrl.text.trim()},
                );
                ref.invalidate(benimKullaniciProfilProvider);
                if (mounted) {
                  AppSnackBar.basari(context, 'Telefon numarası güncellendi.');
                }
              },
              child: Text('Kaydet',
                  style: GoogleFonts.manrope(
                      color: AppColors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
    );
    ctrl.dispose();
  }

  void _engellenenlerSayfasi(List<String> engellenenUidler) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _EngellenenlerScreen(engellenenUidler: engellenenUidler),
      ),
    );
  }


  Future<void> _hesapSilDialog() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final googleGiris =
        user.providerData.any((p) => p.providerId == 'google.com');

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hesabı Sil',
            style: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Hesabını silersen tüm ilanların, mesajların ve verilerın kalıcı olarak silinecek.\n\nBu işlem geri alınamaz!',
          style: GoogleFonts.manrope(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Devam Et',
                style: GoogleFonts.manrope(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    // 10 saniyelik geri sayım — iptal edilirse işlem durur
    final devamEt = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _GeriSayimDialog(),
    );
    if (devamEt != true || !mounted) return;

    if (googleGiris) {
      await _googleReAuth();
    } else {
      await _emailReAuth(user.email ?? '');
    }
  }

  Future<void> _emailReAuth(String email) async {
    final sifreCtrl = TextEditingController();

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Kimliğini Doğrula',
            style: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Güvenlik için şifreni gir.',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: sifreCtrl,
              obscureText: true,
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Şifren',
                hintStyle: GoogleFonts.manrope(
                    color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.lock_outline,
                    color: AppColors.textSecondary, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hesabı Sil',
                style: GoogleFonts.manrope(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) {
      sifreCtrl.dispose();
      return;
    }

    // Dialog reauth'tan ÖNCE açılıyor — "Kimlik doğrulanıyor..." görünür
    _silmeProgressGoster('Kimlik doğrulanıyor...');
    try {
      final yenidenGiris = await ref.read(authProvider.notifier)
          .emailIleYenidenGiris(email: email, sifre: sifreCtrl.text.trim());
      if (!yenidenGiris.basarili) throw Exception(yenidenGiris.hata);
      // Reauth başarılı → metin güncelle, CF çağrısına geç
      await _hesapSilVeYonlendir();
    } catch (e) {
      _silmeDialogKapat();
      if (mounted) AppSnackBar.hata(context, 'Hata: Şifre yanlış veya bir sorun oluştu.');
    }
    sifreCtrl.dispose();
  }

  Future<void> _googleReAuth() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Kimliğini Doğrula',
            style: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Hesabını silmek için Google ile tekrar giriş yapman gerekiyor.',
          style: GoogleFonts.manrope(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Google ile Doğrula',
                style: GoogleFonts.manrope(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    try {
      final yenidenGiris = await ref.read(authProvider.notifier)
          .googleIleYenidenGiris(
        onHesapSecildi: () {
          // Hesap seçildi, reauth ağ çağrıları başlıyor — kullanıcı boşluk görmesin
          if (mounted) _silmeProgressGoster('Kimlik doğrulanıyor...');
        },
      );
      if (!yenidenGiris.basarili) throw Exception(yenidenGiris.hata);
      await _hesapSilVeYonlendir();
    } catch (e) {
      // Dialog artık hata anında açık olabilir (reauth ağ hatasında) ya da
      // hiç açılmamış olabilir (seçici iptali) — guard sayesinde ikisi de güvenli.
      _silmeDialogKapat();
      if (mounted) AppSnackBar.hata(context, 'Hata oluştu. Tekrar dene.');
    }
  }

  bool _silmeDialogAcik = false;

  void _silmeProgressGoster(String asama) {
    _silmeAsamasi.value = asama;
    if (_silmeDialogAcik) return; // metin zaten güncellendi, yeni dialog açma
    _silmeDialogAcik = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              const SizedBox(width: 20),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _silmeAsamasi,
                  builder: (_, metin, _) =>
                      Text(metin, style: GoogleFonts.manrope(fontSize: 14)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ).whenComplete(() => _silmeDialogAcik = false);
  }

  void _silmeDialogKapat() {
    if (_silmeDialogAcik) navigatorKey.currentState?.pop();
  }

  Future<void> _hesapSilVeYonlendir() async {
    if (!mounted) return;
    _silmeAsamasi.value = 'Hesabın siliniyor...'; // metin güncelle (dialog açıksa anında yansır)

    try {
      final silSonuc = await ref.read(authProvider.notifier).hesapSil();
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
      if (silSonuc.basarili) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ctx.go(AppRoutes.login);
          AppSnackBar.bilgi(ctx, 'Hesabın silindi. Seni tekrar aramızda görmek isteriz.');
        }
      } else {
        _silmeDialogKapat();
        if (mounted) AppSnackBar.hata(context, silSonuc.hata ?? 'Hesap silinemedi.');
      }
    } catch (e) {
      _silmeDialogKapat();
      if (mounted) AppSnackBar.hata(context, 'Hata oluştu. Tekrar dene.');
    }
  }
}

// ── 10 Saniyelik Geri Sayım Dialogu ──────────────────────

class _GeriSayimDialog extends StatefulWidget {
  const _GeriSayimDialog();

  @override
  State<_GeriSayimDialog> createState() => _GeriSayimDialogState();
}

class _GeriSayimDialogState extends State<_GeriSayimDialog> {
  static const _sure = 10;
  int _kalan = _sure;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _kalan--);
      if (_kalan <= 0) {
        t.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ilerleme = _kalan / _sure;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('10 saniye içinde iptal edebilirsin',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hesabın $_kalan saniye içinde kalıcı olarak silinecek.',
            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ilerleme,
              minHeight: 8,
              backgroundColor: const Color(0xFFFFCDD2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_kalan sn',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE53935),
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal Et',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ),
      ],
    );
  }
}

// ── Engellenenler Sayfası ─────────────────────────────────

class _EngellenenlerScreen extends ConsumerWidget {
  final List<String> engellenenUidler;
  const _EngellenenlerScreen({required this.engellenenUidler});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benimUid = ref.watch(currentUserProvider)?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Engellenen Kullanıcılar',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: engellenenUidler.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block_outlined,
                      size: 64, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text('Engellenen kullanıcı yok',
                      style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: engellenenUidler.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final hedefUid    = engellenenUidler[index];
                final profilAsync = ref.watch(kullaniciBilgiProvider(hedefUid));

                return profilAsync.when(
                  loading: () => const ListTile(
                    leading: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.red)),
                    title: Text('Yükleniyor...'),
                  ),
                  error: (_, _) => ListTile(
                    leading: AvatarWidget(isim: hedefUid, radius: 24),
                    title: Text('Kullanıcı',
                        style: GoogleFonts.manrope(fontSize: 14)),
                  ),
                  data: (profil) {
                    final ad = profil?.adSoyad ?? 'Kullanıcı';
                    return ListTile(
                      leading: AvatarWidget(isim: ad, radius: 24),
                      title: Text(ad,
                          style: GoogleFonts.manrope(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      trailing: TextButton(
                        onPressed: () async {
                          final onay = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              title: Text('Engeli Kaldır',
                                  style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              content: Text(
                                  '$ad adlı kullanıcının engelini kaldırmak istiyor musun?',
                                  style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: AppColors.textSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text('İptal',
                                      style: GoogleFonts.manrope(
                                          color: AppColors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text('Kaldır',
                                      style: GoogleFonts.manrope(
                                          color: AppColors.red,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                          if (onay == true) {
                            await ref
                                .read(engellemeProvider.notifier)
                                .engelKaldir(
                                  benimUid: benimUid,
                                  hedefUid: hedefUid,
                                );
                            if (context.mounted) {
                              AppSnackBar.bilgi(
                                  context, '$ad engeli kaldırıldı.');
                            }
                          }
                        },
                        child: Text('Engeli Kaldır',
                            style: GoogleFonts.manrope(
                                color: AppColors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                );
              },
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
        style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
  final Color iconColor;
  final Color labelColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool showArrow;

  const _SatirOge({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor  = AppColors.purple,
    this.labelColor = AppColors.textPrimary,
    this.trailing,
    this.showArrow  = true,
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
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: labelColor,
                      fontWeight: FontWeight.w400)),
            ),
            ?trailing,
            if (trailing == null && showArrow)
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchSatir extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool acik;
  final ValueChanged<bool> onChanged;

  const _SwitchSatir({
    required this.icon,
    required this.label,
    required this.acik,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400)),
          ),
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              value: acik,
              onChanged: onChanged,
              activeTrackColor: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

