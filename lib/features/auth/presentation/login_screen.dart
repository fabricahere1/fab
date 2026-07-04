import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../router/app_router.dart' show AppRoutes, navigatorKey;
import '../../profil/presentation/kullanim_kosullari_screen.dart';
import '../../profil/presentation/gizlilik_politikasi_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _hata = '';

  void _girissonrasiGit(BuildContext ctx) {
    final returnRoute = GoRouterState.of(ctx).uri.queryParameters['returnRoute'];
    final profil = ref.read(benimKullaniciProfilProvider).value;
    if (profil?.profilTamamlandi == true) {
      ctx.go(returnRoute ?? AppRoutes.home);
    } else if (returnRoute != null) {
      ctx.go('${AppRoutes.profilTamamla}?returnRoute=${Uri.encodeComponent(returnRoute)}');
    } else {
      ctx.go(AppRoutes.profilTamamla);
    }
  }

  Future<void> _googleIleGiris() async {
    setState(() => _hata = '');
    // Zaten giriş yapılmışsa Firebase yeni auth event fırlatmaz — sonradan kontrol et
    final dejaGiris = ref.read(currentUserProvider) != null;
    final sonuc = await ref.read(authProvider.notifier).googleIleGiris();
    if (!mounted) return;
    if (!sonuc.basarili) {
      setState(() => _hata = sonuc.hata ?? 'Google girişi başarısız.');
      return;
    }
    if (mounted) _girissonrasiGit(context);
  }

  void _telefonIleGiris() {
    final returnRoute = GoRouterState.of(context).uri.queryParameters['returnRoute'];
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
          final profil = ref.read(benimKullaniciProfilProvider).value;
          if (profil?.profilTamamlandi == true) {
            ctx.go(returnRoute ?? AppRoutes.home);
          } else if (returnRoute != null) {
            ctx.go('${AppRoutes.profilTamamla}?returnRoute=${Uri.encodeComponent(returnRoute)}');
          } else {
            ctx.go(AppRoutes.profilTamamla);
          }
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
                      const Icon(Icons.error_outline,
                          color: Colors.white70, size: 14),
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
                  icon: const Icon(Icons.phone_rounded,
                      color: Colors.white, size: 22),
                  label: 'Telefon ile devam et',
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
    final style = GoogleFonts.dmSans(fontSize: 11, color: Colors.white38, height: 1.7);
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
  ConsumerState<_TelefonGirisSheet> createState() =>
      _TelefonGirisSheetState();
}

class _TelefonGirisSheetState extends ConsumerState<_TelefonGirisSheet> {
  final _telefonCtrl = TextEditingController();
  final _kodCtrl     = TextEditingController();

  bool   _kodAsamasi  = false;
  bool   _yukleniyor  = false;
  String _hata        = '';
  String _verificationId = '';

  @override
  void dispose() {
    _telefonCtrl.dispose();
    _kodCtrl.dispose();
    super.dispose();
  }

  // Android otomatik SMS okuyunca kodu alana yapıştırma sorusu
  Future<void> _otomatikGirisDialog(String smsKodu) async {
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final yapistir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
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
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.2)),
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
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (yapistir == true && mounted) {
      setState(() {
        _kodCtrl.text = smsKodu;
        _kodAsamasi = true;
      });
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

    try {
      await ref.read(authProvider.notifier).telefonKoduGonder(
        telefon: '+90$numara',
        onKodGonderildi: (vId) {
          if (mounted) {
            setState(() {
              _verificationId = vId;
              _kodAsamasi     = true;
              _yukleniyor     = false;
            });
          }
        },
        onOtomatikGiris: (smsKodu) {
          _otomatikGirisDialog(smsKodu);
        },
        onHata: (msg) {
          if (mounted) {
            setState(() {
              _hata       = msg;
              _yukleniyor = false;
            });
          }
        },
      );
    } finally {
      if (mounted && _yukleniyor) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _girisYap() async {
    if (_kodCtrl.text.trim().length < 6) {
      setState(() => _hata = '6 haneli kodu eksiksiz gir.');
      return;
    }
    setState(() {
      _yukleniyor = true;
      _hata       = '';
    });

    final dejaGiris = ref.read(currentUserProvider) != null;
    final sonuc = await ref.read(authProvider.notifier).telefonIleGiris(
      verificationId: _verificationId,
      smsKodu:        _kodCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _yukleniyor = false);

    if (!sonuc.basarili) {
      setState(() => _hata = sonuc.hata ?? 'Doğrulama başarısız.');
    } else {
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
          topLeft:  Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(28, 20, 28, 28 + bottomInset),
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
                  onTap: () =>
                      setState(() { _kodAsamasi = false; _hata = ''; }),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary, size: 22),
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
                fontSize: 13, color: AppColors.textSecondary),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇹🇷',
                          style: TextStyle(fontSize: 18)),
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
                      Container(
                          width: 1,
                          height: 20,
                          color: AppColors.divider),
                    ],
                  ),
                ),
                hintText: '5XX XXX XX XX',
                hintStyle:
                    GoogleFonts.dmSans(color: AppColors.textHint),
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
                const Icon(Icons.error_outline,
                    color: AppColors.red, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _hata,
                    style: GoogleFonts.dmSans(
                        color: AppColors.red, fontSize: 12),
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
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _kodAsamasi
                          ? 'Doğrula ve Giriş Yap'
                          : 'Kod Gönder',
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