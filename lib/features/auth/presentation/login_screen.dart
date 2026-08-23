import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../router/app_router.dart'
    show AppRoutes, navigatorKey, girisYapiliyorProvider;
import '../../profil/presentation/kullanim_kosullari_screen.dart';
import '../../profil/presentation/gizlilik_politikasi_screen.dart';
import '../../../shared/widgets/tam_ekran_yukleniyor.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _hata = '';

  // ÖNEMLİ: burada profilTamamlandi kararını KENDİMİZ vermiyoruz —
  // benimKullaniciProfilProvider'ın .value'su, giriş az önce başarılı
  // olduğu için henüz sunucudan gelmemiş/yanlış (cache-miss) olabilir.
  // Bunun yerine splash'e gönderiyoruz; router'ın redirect'i zaten aynı
  // kararı sunucu-onaylı, race-condition korumalı, offline-timeout'lu
  // şekilde veriyor (bkz. app_router.dart _hedefBelirle) — mantığı burada
  // tekrar yazıp aynı bug'ı ikinci kez üretmek yerine tek kaynağa güveniyoruz.
  void _girissonrasiGit(BuildContext ctx) {
    final returnRoute = GoRouterState.of(
      ctx,
    ).uri.queryParameters['returnRoute'];
    ctx.go(
      returnRoute != null
          ? '${AppRoutes.splash}?returnRoute=${Uri.encodeComponent(returnRoute)}'
          : AppRoutes.splash,
    );
  }

  Future<void> _googleIleGiris() async {
    setState(() => _hata = '');
    final sonuc = await ref.read(authProvider.notifier).googleIleGiris();
    if (!mounted) return;
    if (!sonuc.basarili) {
      setState(() => _hata = sonuc.hata ?? 'Google girişi başarısız.');
      return;
    }
    if (mounted) _girissonrasiGit(context);
  }

  void _emailIleGiris() {
    final returnRoute = GoRouterState.of(
      context,
    ).uri.queryParameters['returnRoute'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmailGirisSheet(
        onHata: (msg) {
          if (mounted) setState(() => _hata = msg);
        },
        onBasari: () {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;
          ctx.go(
            returnRoute != null
                ? '${AppRoutes.splash}?returnRoute=${Uri.encodeComponent(returnRoute)}'
                : AppRoutes.splash,
          );
        },
      ),
    );
  }

  void _telefonIleGiris() {
    final returnRoute = GoRouterState.of(
      context,
    ).uri.queryParameters['returnRoute'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TelefonGirisSheet(
        onHata: (msg) {
          if (mounted) setState(() => _hata = msg);
        },
        onBasari: () {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;
          // bkz. _girissonrasiGit yorumu — aynı gerekçeyle karar burada
          // verilmiyor, splash'e (router'ın _hedefBelirle'sine) devrediliyor.
          ctx.go(
            returnRoute != null
                ? '${AppRoutes.splash}?returnRoute=${Uri.encodeComponent(returnRoute)}'
                : AppRoutes.splash,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yukleniyor = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.red,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Image.asset(
                  'assets/images/logo_seffaf.png',
                  height: 120,
                  fit: BoxFit.contain,
                  color: Colors.white,
                ),
                const SizedBox(height: 14),
                Text(
                  'Yeter ki Sen İste',
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(flex: 3),

                if (_hata.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _hata,
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                _GirisButonu(
                  onTap: yukleniyor ? null : _googleIleGiris,
                  yukleniyor: yukleniyor,
                  icon: const _GoogleIkon(),
                  label: 'Google ile devam et',
                  renk: Colors.white,
                  yaziRengi: AppColors.textPrimary,
                ),
                const SizedBox(height: 12),

                _GirisButonu(
                  onTap: yukleniyor ? null : _telefonIleGiris,
                  yukleniyor: false,
                  icon: const Icon(
                    Icons.phone_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: 'Telefon ile devam et',
                  renk: Colors.black26,
                  yaziRengi: Colors.white,
                ),
                const SizedBox(height: 12),

                _GirisButonu(
                  onTap: yukleniyor ? null : _emailIleGiris,
                  yukleniyor: false,
                  icon: const Icon(
                    Icons.email_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: 'E-posta ile devam et',
                  renk: Colors.black26,
                  yaziRengi: Colors.white,
                ),

                const SizedBox(height: 32),
                _KosullarMetni(context: context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Koşullar Metni ─────────────────────────────────────────

class _KosullarMetni extends StatelessWidget {
  final BuildContext context;
  const _KosullarMetni({required this.context});

  void _ac(Widget ekran) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ekran));
  }

  @override
  Widget build(BuildContext ctx) {
    final style = GoogleFonts.dmSans(
      fontSize: 11,
      color: Colors.white38,
      height: 1.7,
    );
    const linkStyle = TextStyle(
      decoration: TextDecoration.underline,
      decorationColor: Colors.white38,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text('Devam ederek ', style: style),
        GestureDetector(
          onTap: () => _ac(const KullanimKosullariScreen()),
          child: Text('Kullanım Koşulları', style: style.merge(linkStyle)),
        ),
        Text('\'nı ve ', style: style),
        GestureDetector(
          onTap: () => _ac(const GizlilikPolitikasiScreen()),
          child: Text('Gizlilik Politikası', style: style.merge(linkStyle)),
        ),
        Text('\'nı kabul etmiş olursun.', style: style),
      ],
    );
  }
}

// ── Giriş Butonu ───────────────────────────────────────────

class _GirisButonu extends StatelessWidget {
  final VoidCallback? onTap;
  final bool yukleniyor;
  final Widget icon;
  final String label;
  final Color renk;
  final Color yaziRengi;

  const _GirisButonu({
    required this.onTap,
    required this.yukleniyor,
    required this.icon,
    required this.label,
    required this.renk,
    required this.yaziRengi,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: renk,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              SizedBox(width: 24, child: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: yaziRengi,
                  ),
                ),
              ),
              if (yukleniyor)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: yaziRengi,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google İkon ────────────────────────────────────────────

class _GoogleIkon extends StatelessWidget {
  const _GoogleIkon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF4285F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

// ── Telefon Giriş Bottom Sheet ─────────────────────────────

class _TelefonGirisSheet extends ConsumerStatefulWidget {
  final void Function(String) onHata;
  final VoidCallback onBasari;
  const _TelefonGirisSheet({required this.onHata, required this.onBasari});

  @override
  ConsumerState<_TelefonGirisSheet> createState() => _TelefonGirisSheetState();
}

class _TelefonGirisSheetState extends ConsumerState<_TelefonGirisSheet> {
  final _telefonCtrl = TextEditingController();
  final _kodCtrl = TextEditingController();

  bool _kodAsamasi = false;
  bool _yukleniyor = false;
  String _hata = '';
  String _verificationId = '';
  bool _otpDialogAcik = false;

  final _yukleniyorOverlay = TamEkranYukleniyorController();

  @override
  void dispose() {
    _yukleniyorOverlay.gizle();
    _telefonCtrl.dispose();
    _kodCtrl.dispose();
    super.dispose();
  }

  // Android otomatik SMS okuyunca kodu alana yapıştırma sorusu
  Future<void> _otomatikGirisDialog(String smsKodu) async {
    if (!mounted || _otpDialogAcik) return;
    _otpDialogAcik = true;

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      _otpDialogAcik = false;
      return;
    }

    final yapistir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'SMS Kodu Alındı',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doğrulama kodun hazır. Kodu alana yapıştıralım mı?',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                smsKodu,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hayır',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(
              'Evet, Yapıştır',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
    _otpDialogAcik = false;

    if (yapistir == true && mounted) {
      setState(() {
        _kodCtrl.text = smsKodu;
        _kodAsamasi = true;
      });
      await _girisYap();
    }
  }

  Future<void> _kodGonder() async {
    final numara = _telefonCtrl.text.trim().replaceAll(' ', '');
    if (numara.length < 10) {
      setState(() => _hata = 'Geçerli bir telefon numarası gir.');
      return;
    }
    setState(() {
      _yukleniyor = true;
      _hata = '';
    });
    _yukleniyorOverlay.goster(
      context,
      'Kod gönderiliyor, bu işlem birkaç saniye sürebilir.',
      renk: Colors.lightBlue,
      spinnerBoyutu: 72,
      strokeGenisligi: 5,
      fontBoyutu: 28,
    );
    // Android, verifyPhoneNumber'ın tetiklediği native CAPTCHA/reCAPTCHA
    // Activity'sine bazen o kadar hızlı geçiyor ki, Flutter'ın az önce
    // kuyruğa aldığı "_yukleniyor" frame'i ekrana hiç basılamadan pencere
    // odağı native tarafa geçiyor — kullanıcı hiçbir ara kare görmüyor.
    // Bu kısa bekleme, frame'in gerçekten ekrana sunulmasını garantiliyor.
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    try {
      await ref
          .read(authProvider.notifier)
          .telefonKoduGonder(
            telefon: '+90$numara',
            onKodGonderildi: (vId) {
              if (mounted) {
                setState(() {
                  _verificationId = vId;
                  _kodAsamasi = true;
                  _yukleniyor = false;
                });
                _yukleniyorOverlay.gizle();
              }
            },
            onOtomatikGiris: (smsKodu) {
              _otomatikGirisDialog(smsKodu);
            },
            onHata: (msg) {
              if (mounted) {
                setState(() {
                  _hata = msg;
                  _yukleniyor = false;
                });
                _yukleniyorOverlay.gizle();
              }
            },
          );
    } catch (e) {
      // verifyPhoneNumber, verificationFailed callback'i yerine doğrudan
      // bir exception fırlatabiliyor (ör. geçersiz numara formatı) — bu,
      // onHata'yı hiç tetiklemediği için _hata boş kalıp kullanıcıya
      // hiçbir geri bildirim verilmeden formun sessizce sıfırlanmasına
      // yol açıyordu.
      if (mounted) {
        setState(() {
          _hata = 'Hata oluştu. Tekrar dene.';
          _yukleniyor = false;
        });
        _yukleniyorOverlay.gizle();
      }
    }
    // finally YOK: verifyPhoneNumber'ın Future'ı yalnızca native tarafa
    // callback kaydı tamamlandığında biter — CAPTCHA/SMS süreci hâlâ
    // arka planda sürüyor olabilir. _yukleniyor artık yalnızca gerçek
    // sonuç callback'lerinde (onKodGonderildi, onHata) veya yukarıdaki
    // catch'te kapatılıyor; erken kapatmak formun CAPTCHA bitmeden geri
    // gelmesine (kısa süreli flicker) yol açıyordu.
  }

  Future<void> _girisYap() async {
    if (_kodCtrl.text.trim().length < 6) {
      setState(() => _hata = '6 haneli kodu eksiksiz gir.');
      return;
    }
    setState(() {
      _yukleniyor = true;
      _hata = '';
    });
    _yukleniyorOverlay.goster(
      context,
      'Giriş yapılıyor...',
      renk: Colors.blue,
      spinnerBoyutu: 72,
      strokeGenisligi: 5,
      fontBoyutu: 28,
    );

    // Başarılı girişte authStateProvider değişip GoRouter'ın kendi
    // redirect'i otomatik tetikleniyor — bu, aşağıdaki manuel
    // Navigator.pop + onBasari() navigasyonuyla AYNI navigatorKey
    // üzerinde çakışıp kısa süreli siyah ekrana yol açabiliyordu.
    // Bu flag, manuel navigasyon tamamlanana kadar router'ın araya
    // girmesini engelliyor (hesap silme akışındaki
    // yenidenKimlikDogrulamaSuruyorProvider ile aynı desen).
    ref.read(girisYapiliyorProvider.notifier).state = true;
    try {
      final sonuc = await ref
          .read(authProvider.notifier)
          .telefonIleGiris(
            verificationId: _verificationId,
            smsKodu: _kodCtrl.text.trim(),
          );

      if (!mounted) return;
      setState(() => _yukleniyor = false);
      _yukleniyorOverlay.gizle();

      if (!sonuc.basarili) {
        setState(() => _hata = sonuc.hata ?? 'Doğrulama başarısız.');
      } else {
        Navigator.pop(context);
        widget.onBasari();
      }
    } finally {
      ref.read(girisYapiliyorProvider.notifier).state = false;
      _yukleniyorOverlay.gizle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(28, 20, 28, 28 + bottomInset),
      // Yükleniyor durumu artık sheet sınırlarını aşan, tam ekranı
      // kaplayan bir OverlayEntry ile gösteriliyor (_yukleniyorOverlay) —
      // bkz. tam_ekran_yukleniyor.dart. Sheet'in kendi içeriği bu yüzden
      // her zaman form halinde kalıyor, ayrıca bir loading dalı yok.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              if (_kodAsamasi)
                GestureDetector(
                  onTap: () => setState(() {
                    _kodAsamasi = false;
                    _hata = '';
                  }),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              Text(
                _kodAsamasi ? 'Kodu gir' : 'Telefon numaranı gir',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _kodAsamasi
                ? '+90${_telefonCtrl.text.trim()} numarasına SMS gönderdik.'
                : 'Sana 6 haneli bir doğrulama kodu göndereceğiz.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          if (!_kodAsamasi)
            TextField(
              controller: _telefonCtrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: GoogleFonts.dmSans(fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇹🇷', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        '+90',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 20, color: AppColors.divider),
                    ],
                  ),
                ),
                hintText: '5XX XXX XX XX',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textHint),
              ),
            )
          else
            TextField(
              controller: _kodCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '······',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 28,
                  letterSpacing: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),

          if (_hata.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _hata,
                    style: GoogleFonts.dmSans(
                      color: AppColors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _yukleniyor
                  ? null
                  : (_kodAsamasi ? _girisYap : _kodGonder),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _yukleniyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _kodAsamasi ? 'Doğrula ve Giriş Yap' : 'Kod Gönder',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          if (_kodAsamasi) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _yukleniyor ? null : _kodGonder,
                child: Text(
                  'Kodu tekrar gönder',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── E-posta Giriş/Kayıt Bottom Sheet ───────────────────────

class _EmailGirisSheet extends ConsumerStatefulWidget {
  final void Function(String) onHata;
  final VoidCallback onBasari;
  const _EmailGirisSheet({required this.onHata, required this.onBasari});

  @override
  ConsumerState<_EmailGirisSheet> createState() => _EmailGirisSheetState();
}

class _EmailGirisSheetState extends ConsumerState<_EmailGirisSheet> {
  final _adSoyadCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();

  bool _kayitModu = false;
  bool _yukleniyor = false;
  bool _dogrulamaBekleniyor = false;
  String _hata = '';

  final _yukleniyorOverlay = TamEkranYukleniyorController();

  @override
  void dispose() {
    _yukleniyorOverlay.gizle();
    _adSoyadCtrl.dispose();
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final email = _emailCtrl.text.trim();
    final sifre = _sifreCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _hata = 'Geçerli bir e-posta adresi gir.');
      return;
    }
    if (sifre.length < 6) {
      setState(() => _hata = 'Şifre en az 6 karakter olmalı.');
      return;
    }
    if (_kayitModu && _adSoyadCtrl.text.trim().isEmpty) {
      setState(() => _hata = 'Ad soyad gir.');
      return;
    }

    setState(() {
      _yukleniyor = true;
      _hata = '';
    });
    _yukleniyorOverlay.goster(
      context,
      _kayitModu ? 'Hesap oluşturuluyor...' : 'Giriş yapılıyor...',
      renk: Colors.blue,
      spinnerBoyutu: 72,
      strokeGenisligi: 5,
      fontBoyutu: 28,
    );

    final notifier = ref.read(authProvider.notifier);

    // bkz. _TelefonGirisSheet._girisYap yorumu — giriş başarılı olunca
    // authStateProvider değişip GoRouter'ın kendi redirect'i otomatik
    // tetikleniyor; bu, aşağıdaki manuel Navigator.pop + onBasari()
    // navigasyonuyla AYNI navigatorKey üzerinde çakışıp
    // '_elements.contains(element)' assertion'ına yol açabiliyor. Kayıtta
    // signOut yüzünden de auth state değiştiği için aynı guard kayıt
    // akışını da kapsıyor.
    ref.read(girisYapiliyorProvider.notifier).state = true;
    final AuthSonuc sonuc;
    try {
      sonuc = _kayitModu
          ? await notifier.emailIleKayit(
              adSoyad: _adSoyadCtrl.text.trim(),
              email: email,
              sifre: sifre,
            )
          : await notifier.emailIleGiris(email: email, sifre: sifre);
    } finally {
      ref.read(girisYapiliyorProvider.notifier).state = false;
    }

    if (!mounted) return;
    setState(() => _yukleniyor = false);
    _yukleniyorOverlay.gizle();

    if (!sonuc.basarili) {
      setState(() => _hata = sonuc.hata ?? 'İşlem başarısız.');
      return;
    }

    if (_kayitModu) {
      // Kayıt sonrası doğrulama e-postası gönderildi ama emailVerified
      // henüz false — kullanıcı, e-postasını doğrulamadan giriş
      // yapamayacağı için burada bilgilendirip sheet'i kapatıyoruz;
      // login flow'una (girişte email-not-verified kontrolü) tekrar
      // takılmadan net bir mesaj görsün.
      setState(() => _dogrulamaBekleniyor = true);
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onBasari();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(28, 20, 28, 28 + bottomInset),
      child: _dogrulamaBekleniyor
          ? _buildDogrulamaMesaji(context)
          : _buildForm(context),
    );
  }

  Widget _buildDogrulamaMesaji(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Icon(Icons.mark_email_unread_rounded, color: AppColors.red, size: 40),
        const SizedBox(height: 16),
        Text(
          'E-postanı doğrulaman gerekiyor',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_emailCtrl.text.trim()} adresine bir doğrulama bağlantısı gönderdik. Gelen kutunu kontrol et, doğruladıktan sonra giriş yapabilirsin.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Tamam',
              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _kayitModu ? 'Hesap oluştur' : 'E-posta ile giriş yap',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        if (_kayitModu) ...[
          TextField(
            controller: _adSoyadCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.dmSans(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Ad Soyad',
              hintStyle: GoogleFonts.dmSans(color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 14),
        ],

        TextField(
          controller: _emailCtrl,
          autofocus: !_kayitModu,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.dmSans(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'E-posta',
            hintStyle: GoogleFonts.dmSans(color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _sifreCtrl,
          obscureText: true,
          style: GoogleFonts.dmSans(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Şifre',
            hintStyle: GoogleFonts.dmSans(color: AppColors.textHint),
          ),
        ),

        if (_hata.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _hata,
                  style: GoogleFonts.dmSans(color: AppColors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _yukleniyor ? null : _gonder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _yukleniyor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _kayitModu ? 'Hesap Oluştur' : 'Giriş Yap',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _yukleniyor
                ? null
                : () => setState(() {
                      _kayitModu = !_kayitModu;
                      _hata = '';
                    }),
            child: Text(
              _kayitModu
                  ? 'Zaten hesabın var mı? Giriş Yap'
                  : 'Hesabın yok mu? Kayıt Ol',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
