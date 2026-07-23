// lib/features/ilanlar/presentation/ilan_form_screen.dart
//
// İstek ve taşıyıcı (gelenler) ilanı verme/düzenleme akışlarının ikisini de
// tek bir ekranda, tam ekran "adım adım" sade/beyaz tasarımla yöneten dosya.
// gelenler_form_screen.dart artık kullanılmıyor, bu dosya onun yerini alıyor.

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/ilan_model.dart';
import '../providers/ilan_provider.dart';
import 'widgets/ilan_overlay_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import 'ilanlar_screen.dart' show kategoriIkon;
import '../../../shared/constants/app_constants.dart';
import '../../../core/cache/app_cache_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/widgets/autocomplete_alan.dart';

// ── Adım tanımı ────────────────────────────────────────────────────────────────

class _AdimTanimi {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  const _AdimTanimi(this.ikon, this.baslik, this.aciklama);
}

class IlanFormScreen extends ConsumerStatefulWidget {
  final String tip;
  final IlanModel? duzenlenecekIlan;

  const IlanFormScreen({
    super.key,
    required this.tip,
    this.duzenlenecekIlan,
  });

  @override
  ConsumerState<IlanFormScreen> createState() => _IlanFormScreenState();
}

class _IlanFormScreenState extends ConsumerState<IlanFormScreen> {
  int _adim = 0;

  final _urunCtrl    = TextEditingController(); // "Ürün adı" (istek) / "İlan adı" (taşıyıcı)
  final _neredenCtrl = TextEditingController();
  final _nereyeCtrl  = TextEditingController();
  final _notlarCtrl  = TextEditingController();

  List<String> _kategoriYolu = [];
  String _cinsiyet = '';
  String _beden = '';
  String _pantolonBel = '';
  String _pantolonBoy = '';
  bool _neredenFarketmez = false;       // sadece istek
  DateTime? _seciliTarih;               // sadece taşıyıcı
  String _tasimaTercihi = 'istekler';   // sadece taşıyıcı
  bool _sadeceGeliyorum = false;        // sadece taşıyıcı — "sadece geliyorum, isteklere açığım"

  final List<File> _yeniResimler   = [];
  List<String>     _mevcutResimler = [];
  final _picker = ImagePicker();

  bool? _basarili;
  bool  _overlayAktif = false;
  String? _hataMesaji;

  // "Nereye" için öneri listesi: tüm Türkiye illeri (81) + yabancı şehirler.
  // Listede olmayan bir değer de artık serbestçe kabul ediliyor (bkz. _adimGecerli).
  static final List<String> _nereyeOneriListesi = [
    ...kTurkiyeSehirleri,
    ...kDunyaSehirleri.where((s) => !kTurkiyeSehirleri.contains(s)),
  ];

  bool get _istekMi         => widget.tip == IlanTip.istek;
  bool get _duzenlemeModuMu => widget.duzenlenecekIlan != null;
  int  get _toplamAdim      => _istekMi ? 3 : 4;

  String get _kayitKategoriKey =>
      _kategoriYolu.isNotEmpty ? _kategoriYolu.last : 'diger';

  String get _kayitAnaKategoriKey =>
      _kategoriYolu.isNotEmpty ? _kategoriYolu.first : '';

  String get _kategoriGorunumAdi =>
      _kategoriYolu.isEmpty ? '' : kategoriYoluMetni(_kategoriYolu);

  @override
  void initState() {
    super.initState();
    if (_duzenlemeModuMu) {
      final ilan = widget.duzenlenecekIlan!;
      _urunCtrl.text    = ilan.urun;
      _neredenCtrl.text = ilan.nereden == 'Farketmez' ? '' : ilan.nereden;
      _nereyeCtrl.text  = ilan.nereye;
      _notlarCtrl.text  = ilan.notlar;
      _neredenFarketmez = ilan.nereden == 'Farketmez';
      _seciliTarih      = ilan.tarih;
      _sadeceGeliyorum  = ilan.sadeceGeliyorum;
      _mevcutResimler   = List<String>.from(ilan.tumResimler);
      if (ilan.kategoriYolu.isNotEmpty) {
        _kategoriYolu = List<String>.from(ilan.kategoriYolu);
      } else if (ilan.kategori.isNotEmpty) {
        _kategoriYolu = [ilan.kategori];
      }
      _cinsiyet = ilan.cinsiyet;
      final tipi = bedenTipiGetir(_kategoriYolu);
      if (tipi == BedenTipi.pantolon && ilan.beden.contains('/')) {
        final parcalar = ilan.beden.split('/');
        _pantolonBel = parcalar[0];
        _pantolonBoy = parcalar[1];
      } else {
        _beden = ilan.beden;
      }
    }
  }

  @override
  void dispose() {
    _urunCtrl.dispose();
    _neredenCtrl.dispose();
    _nereyeCtrl.dispose();
    _notlarCtrl.dispose();
    super.dispose();
  }

  // ── Adım içerikleri / doğrulama ─────────────────────────────────────────────

  _AdimTanimi _adimTanimi(int adim) {
    if (_istekMi) {
      switch (adim) {
        case 0: return const _AdimTanimi(Icons.label_outline,
            'Ne istiyorsun?', 'İstediğin ürünü ve kategorisini belirt.');
        case 1: return const _AdimTanimi(Icons.route_outlined,
            'Güzergahını paylaş', 'Ürünün nereden geleceğini ve nereye ulaşacağını belirt.');
        default: return const _AdimTanimi(Icons.photo_library_outlined,
            'Son detaylar', 'Ek notlar ve fotoğraf ekleyerek ilanını tamamla.');
      }
    }
    switch (adim) {
      case 0: return const _AdimTanimi(Icons.label_outline,
          'İlanını tanıt', 'İlan adı ve varsa kategorisini belirt.');
      case 1: return const _AdimTanimi(Icons.route_outlined,
          'Güzergahını paylaş', 'Hangi rotada seyahat ettiğini belirt.');
      case 2: return const _AdimTanimi(Icons.calendar_today_outlined,
          'Ne zaman, ne taşıyabilirsin?', 'Seyahat tarihini ve taşıma tercihini belirt.');
      default: return const _AdimTanimi(Icons.photo_library_outlined,
          'Son detaylar', 'Ek notlar ve fotoğraf ekleyerek ilanını tamamla.');
    }
  }

  bool _adimGecerli(int adim) {
    if (adim == 0) {
      if (_istekMi && _urunCtrl.text.trim().isEmpty) {
        _snack('Ürün adını girin.'); return false;
      }
      if (_istekMi && _urunCtrl.text.trim().length < 3) {
        _snack('Ürün adı en az 3 karakter olmalı.'); return false;
      }
      if (!_istekMi && !_sadeceGeliyorum && _urunCtrl.text.trim().isNotEmpty &&
          _urunCtrl.text.trim().length < 3) {
        _snack('İlan adı en az 3 karakter olmalı.'); return false;
      }
      if (_istekMi && _kategoriYolu.isEmpty) {
        _snack('Kategori seçin.'); return false;
      }
      final tipi = bedenTipiGetir(_kategoriYolu);
      if (tipi != BedenTipi.yok) {
        if (_cinsiyet.isEmpty) { _snack('Cinsiyet seçin.'); return false; }
        if (tipi == BedenTipi.pantolon) {
          if (_pantolonBel.isEmpty || _pantolonBoy.isEmpty) {
            _snack('Bel ve boy değerlerini seçin.'); return false;
          }
        } else if (_beden.isEmpty) {
          _snack(tipi == BedenTipi.ayakkabi ? 'Numara seçin.' : 'Beden seçin.');
          return false;
        }
      }
      return true;
    }
    if (adim == 1) {
      if (_istekMi && !_neredenFarketmez) {
        if (_neredenCtrl.text.trim().isEmpty) {
          _snack('Nereden alanını doldurun.'); return false;
        }
        if (!kDunyaUlkeleri.any((u) =>
            u.toLowerCase() == _neredenCtrl.text.trim().toLowerCase())) {
          _snack('Listeden geçerli bir ülke seçin.'); return false;
        }
      }
      if (!_istekMi) {
        if (_neredenCtrl.text.trim().isEmpty) {
          _snack('Nereden alanını doldurun.'); return false;
        }
        if (!kDunyaUlkeleri.any((u) =>
            u.toLowerCase() == _neredenCtrl.text.trim().toLowerCase())) {
          _snack('Listeden geçerli bir ülke seçin.'); return false;
        }
      }
      if (_nereyeCtrl.text.trim().isEmpty) {
        _snack('Nereye alanını doldurun.'); return false;
      }
      if (!_nereyeOneriListesi.any((s) =>
          s.toLowerCase() == _nereyeCtrl.text.trim().toLowerCase())) {
        _snack('Listeden geçerli bir şehir seçin.'); return false;
      }
      return true;
    }
    if (!_istekMi && adim == 2) {
      if (_seciliTarih == null) { _snack('Seyahat tarihini seçin.'); return false; }
      return true;
    }
    return true;
  }

  void _ileri() {
    if (!_adimGecerli(_adim)) return;
    if (_adim < _toplamAdim - 1) {
      setState(() => _adim += 1);
    } else {
      _kaydet();
    }
  }

  void _geri() {
    if (_adim > 0) {
      setState(() => _adim -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  // altBosluk: alt "Devam et"/"Yayınla" butonu (48 yükseklik + 20 alt padding)
  // ile çakışmaması için SnackBar'ı yeterince yukarı it.
  void _snack(String m) => AppSnackBar.hata(context, m, altBosluk: 80);

  // ── Resim seçimi ─────────────────────────────────────────────────────────────

  Future<void> _resimEkle() async {
    final toplam = _mevcutResimler.length + _yeniResimler.length;
    if (toplam >= Pagination.maxResimSayisi) {
      _snack('En fazla ${Pagination.maxResimSayisi} resim ekleyebilirsin.');
      return;
    }

    final kaynak = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32, height: 3, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('Kamera', style: GoogleFonts.dmSans(fontSize: 15)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Galeri', style: GoogleFonts.dmSans(fontSize: 15)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (kaynak == null) return;

    if (kaynak == ImageSource.camera) {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() => _yeniResimler.add(File(picked.path)));
      }
    } else {
      final picked = await _picker.pickMultiImage(
        imageQuality: 80,
        limit: Pagination.maxResimSayisi - toplam,
      );
      if (!mounted) return;
      if (picked.isNotEmpty) {
        setState(() {
          for (final img in picked) {
            if (_mevcutResimler.length + _yeniResimler.length < Pagination.maxResimSayisi) {
              _yeniResimler.add(File(img.path));
            }
          }
        });
      }
    }
  }

  // ── Tarih / kategori seçim sayfaları ──────────────────────────────────────────

  /// "Nereden" alanı için ülke arama akışı. Algolia'dan öneri gelir
  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final s = await showDatePicker(
      context: context,
      initialDate: _seciliTarih ?? bugun.add(const Duration(days: 1)),
      firstDate: bugun,
      lastDate: bugun.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.red, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (s != null) setState(() => _seciliTarih = s);
  }

  void _kategoriSec() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => KategoriSecimSheet(
        seciliYol: _kategoriYolu,
        onSecildi: (yol) {
          setState(() {
            _kategoriYolu = yol;
            _beden = '';
            _pantolonBel = '';
            _pantolonBoy = '';
            _cinsiyet = cinsiyetTahminiGetir(yol);
          });
          Navigator.pop(ctx);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) FocusScope.of(context).unfocus();
          });
        },
      ),
    );
  }

  // ── Kaydetme ───────────────────────────────────────────────────────────────────

  /// "Sadece geliyorum" seçiliyken ve hiç gerçek fotoğraf eklenmediğinde,
  /// bundle edilmiş varsayılan görseli normal bir kullanıcı fotoğrafı gibi
  /// (geçici bir File'a kopyalayarak) işleme sokar — bu sayede mevcut
  /// sıkıştırma/yükleme/kart gösterimi mantığına HİÇ dokunmaya gerek kalmaz,
  /// her yer zaten 'resimUrl' ile çalışmayı biliyor.
  Future<File?> _varsayilanResimYukle() async {
    try {
      final bytes = await rootBundle.load('assets/images/sadece_geliyorum_default.png');
      final tempDir = await getTemporaryDirectory();
      final dosya = File('${tempDir.path}/sadece_geliyorum_default.png');
      await dosya.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return dosya;
    } catch (_) {
      return null; // yüklenemezse sessizce resimsiz devam et, ilan vermeyi bloklamasın
    }
  }

  Future<void> _kaydet() async {
    final user = ref.read(currentUserProvider);
    if (user == null) { _snack('Giriş yapmanız gerekiyor.'); return; }

    final tipi = bedenTipiGetir(_kategoriYolu);
    final bedenDeger = tipi == BedenTipi.pantolon
        ? (_pantolonBel.isNotEmpty && _pantolonBoy.isNotEmpty
            ? '$_pantolonBel/$_pantolonBoy'
            : '')
        : _beden;
    final nereden = (_istekMi && _neredenFarketmez)
        ? 'Farketmez' : _neredenCtrl.text.trim();
    final urunDeger = _sadeceGeliyorum
        ? (nereden.isNotEmpty && nereden != 'Farketmez'
            ? '$nereden\'${_turkceAblatifEki(nereden)} geliyorum'
            : 'İsteklere açığım')
        : _urunCtrl.text.trim();

    if (_duzenlemeModuMu) {
      setState(() => _overlayAktif = true);
      final basarili = await ref.read(ilanOlusturProvider.notifier).guncelle(
        widget.duzenlenecekIlan!.id,
        {
          'nereden':      nereden,
          'nereye':       _nereyeCtrl.text.trim(),
          'notlar':       _notlarCtrl.text.trim(),
          'kategori':     _kayitKategoriKey,
          'anaKategori':  _kayitAnaKategoriKey,
          'kategoriYolu': _kategoriYolu,
          'urun':         urunDeger,
          'sadeceGeliyorum': _sadeceGeliyorum,
          if (_seciliTarih != null) 'tarih': _seciliTarih,
          'cinsiyet': _cinsiyet,
          'beden':    bedenDeger,
        },
        yeniResimler: _yeniResimler,
        mevcutResimler: _mevcutResimler,
      );
      if (!mounted) return;

      if (!basarili) {
        // Yeni-ilan akışındaki (satır ~479-485) teknik hata deseniyle birebir
        // aynı — overlay KAPATILMIYOR, _basarili=false ile overlay'in kendi
        // "reddedildi" sonuç ekranına geçmesi sağlanıyor. IlanYuklemeOverlay
        // her zaman mount durumda (Stack'in sabit çocuğu) olduğu için bu,
        // gerçek bir didUpdateWidget tetikler, _gosterSonuc() zinciri güvenle
        // çalışır. _overlayAktif=false ile kapatmak, overlay aktif=true
        // geçtikten sonra artık stuck-loading bırakır — yanlış olur.
        final teknikHata = ref.read(ilanOlusturProvider).hata;
        setState(() {
          _basarili = false;
          _hataMesaji = teknikHata;
        });
        return;
      }

      // Yazma başarılı — şimdi sunucudaki yeniden moderasyon sonucunu
      // bekliyoruz (CREATE akışındaki aynı mekanizma, durumBekle). Eskiden
      // burada hemen "güncellendi, incelenecek" diye anlık bir snackbar
      // gösterilip ekran kapatılıyordu — gerçek sonucu (onaylandı/reddedildi)
      // hiç beklemiyordu. Artık aynı progres ekranı, gerçek sonucu gösterene
      // kadar açık kalıyor — push bildirim zamanlamasına bağımlı değil.
      final yayinda = await ref.read(ilanOlusturProvider.notifier).durumBekle(
        widget.duzenlenecekIlan!.id,
      );
      if (!mounted) return;
      setState(() => _basarili = yayinda ?? true);
      return;
    }

    setState(() => _overlayAktif = true);
    final profilSnapshot = await ref.read(kullaniciBilgiProvider(user.uid).future);

    var resimler = _yeniResimler;
    if (_sadeceGeliyorum && _mevcutResimler.isEmpty && _yeniResimler.isEmpty) {
      final varsayilan = await _varsayilanResimYukle();
      if (varsayilan != null) resimler = [varsayilan];
    }

    final ilan = IlanModel(
      id: '', tip: widget.tip,
      nereden:      nereden,
      nereye:       _nereyeCtrl.text.trim(),
      urun:         urunDeger,
      ucret:        '', notlar: _notlarCtrl.text.trim(),
      kategori:     _kayitKategoriKey,
      anaKategori:  _kayitAnaKategoriKey,
      kategoriYolu: _kategoriYolu,
      kullaniciId:  user.uid,
      kullaniciAd:  profilSnapshot?.adSoyad.isNotEmpty == true
          ? profilSnapshot!.adSoyad
          : (user.displayName ?? user.email ?? ''),
      tarih:        _seciliTarih,
      cinsiyet:     _cinsiyet,
      beden:        bedenDeger,
      kullaniciPuan: profilSnapshot?.ortalamaPuan ?? 0.0,
      sahipIstekTeslimatTercihi:
          _istekMi ? profilSnapshot?.istekTeslimatTercihi : null,
      sahipDutyFree: _istekMi ? false : (profilSnapshot?.dutyFreeIlgileniyor ?? false),
      sadeceGeliyorum: _sadeceGeliyorum,
    );
    try {
      final id = await ref.read(ilanOlusturProvider.notifier).olustur(
        ilan: ilan, resimler: resimler,
      );
      if (!mounted) return;
      if (id == null) {
        final teknikHata = ref.read(ilanOlusturProvider).hata;
        setState(() {
          _basarili = false;
          _hataMesaji = teknikHata;
        });
        return;
      }
      final yayinda = await ref.read(ilanOlusturProvider.notifier).durumBekle(id);
      if (!mounted) return;
      setState(() => _basarili = yayinda ?? true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _basarili = false;
          _hataMesaji = e.toString();
        });
      }
    }
  }

  void _overlayTamamlandi() {
    final basarili = _basarili ?? true;
    final hataMesaji = _hataMesaji;
    setState(() { _overlayAktif = false; _basarili = null; _hataMesaji = null; });
    Navigator.pop(context);
    if (basarili) {
      if (_istekMi) {
        ref.read(istekIlanlarProvider.notifier).yenile();
      } else {
        ref.read(tasiyiciIlanlarProvider.notifier).yenile();
      }
    } else if (hataMesaji != null && hataMesaji.isNotEmpty) {
      // Teknik bir hata (yükleme/ağ/yetki sorunu) — içerik moderasyonuyla ilgisi yok.
      AppSnackBar.hata(context, 'Bir sorun oluştu: $hataMesaji');
    } else {
      // Teknik hata yok, durumBekle 'reddedildi' döndü — gerçek moderasyon reddi.
      AppSnackBar.hata(context,
          'İlanınız yayın için uygun değildir, lütfen kontrol edip yeniden deneyin');
    }
  }

  // ── Arayüz ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tanim = _adimTanimi(_adim);
    final sonAdimMi = _adim == _toplamAdim - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: Color(0xFF999999)),
                        onPressed: _geri,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_toplamAdim, (i) {
                            return Container(
                              width: 18, height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              decoration: BoxDecoration(
                                color: i <= _adim
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 20, color: Color(0xFF999999)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: SingleChildScrollView(
                        key: ValueKey(_adim),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Icon(tanim.ikon, size: 34, color: AppColors.primary),
                                  const SizedBox(height: 18),
                                  Text('ADIM ${_adim + 1} / $_toplamAdim',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12, color: const Color(0xFFAAAAAA),
                                          letterSpacing: 0.3)),
                                  const SizedBox(height: 6),
                                  Text(tanim.baslik,
                                      textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 20, fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1A1A1A))),
                                const SizedBox(height: 8),
                                Text(tanim.aciklama,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13, color: const Color(0xFF999999),
                                        height: 1.5)),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                          _adimIcerigi(_adim),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ref.watch(ilanOlusturProvider).yukleniyor ? null : _ileri,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(sonAdimMi ? 'Yayınla' : 'Devam et',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IlanYuklemeOverlay(
            aktif: _overlayAktif,
            basarili: _basarili,
            onTamamlandi: _overlayTamamlandi,
            duzenlemeModu: _duzenlemeModuMu,
          ),
        ],
      ),
    );
  }

  Widget _adimIcerigi(int adim) {
    final beden = bedenTipiGetir(_kategoriYolu);

    if (adim == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_istekMi) ...[
            _SadeceGeliyorumToggle(
              secili: _sadeceGeliyorum,
              onTap: () => setState(() {
                _sadeceGeliyorum = !_sadeceGeliyorum;
                if (_sadeceGeliyorum) {
                  _urunCtrl.clear();
                  _kategoriYolu = [];
                  _cinsiyet = '';
                  _beden = '';
                  _pantolonBel = '';
                  _pantolonBoy = '';
                }
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8),
              child: Text(
                '*Sadece seyahat ediyorsan ve isteklere açıksan',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Row(
                children: [
                  Expanded(child: Container(height: 0.6, color: const Color(0xFFEEEEEE))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('YA DA',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFFBBBBBB),
                          letterSpacing: 0.5,
                        )),
                  ),
                  Expanded(child: Container(height: 0.6, color: const Color(0xFFEEEEEE))),
                ],
              ),
            ),
          ],
          AbsorbPointer(
            absorbing: _sadeceGeliyorum,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _sadeceGeliyorum ? 0.4 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _alanEtiket(_istekMi ? 'Ürün adı *' : 'İlan adı'),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _urunCtrl,
                    builder: (context, val, _) {
                      final text = val.text.trim();
                      final hata = text.isNotEmpty && text.length < 3
                          ? 'En az 3 karakter girin'
                          : null;
                      return _altCizgiAlan(
                        controller: _urunCtrl,
                        hint: _istekMi
                            ? 'Örn: iPhone 15 Pro, Nike Air Max...'
                            : 'Örn: Elektronik, Kozmetik, Giyim...',
                        errorText: _sadeceGeliyorum ? null : hata,
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _alanEtiket(_istekMi ? 'Kategori *' : 'Kategori'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _kategoriSec,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _kategoriGorunumAdi.isNotEmpty
                                  ? _kategoriGorunumAdi
                                  : 'Kategori seç...${_istekMi ? '' : ' (opsiyonel)'}',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: _kategoriGorunumAdi.isNotEmpty
                                    ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBBBBBB)),
                        ],
                      ),
                    ),
                  ),
                  if (!_istekMi) ...[
                    const SizedBox(height: 8),
                    Text(
                      '*Seyahat ediyor ve istekçiler için ürün ilanı vermek istiyorsan',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFBBBBBB),
                      ),
                    ),
                  ],
                  if (beden != BedenTipi.yok) ...[
                    const SizedBox(height: 24),
                    BedenCinsiyetBolum(
                      tip: beden,
                      cinsiyet: _cinsiyet,
                      beden: _beden,
                      pantolonBel: _pantolonBel,
                      pantolonBoy: _pantolonBoy,
                      onCinsiyetDegis: (v) => setState(() => _cinsiyet = v),
                      onBedenDegis: (v) => setState(() => _beden = v),
                      onPantolonBelDegis: (v) => setState(() => _pantolonBel = v),
                      onPantolonBoyDegis: (v) => setState(() => _pantolonBoy = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (adim == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _alanEtiket('Nereden *'),
          const SizedBox(height: 6),
          if (!_neredenFarketmez)
            AutocompleteAlan(
              controller: _neredenCtrl,
              hint: 'Ülke ara...',
              icon: Icons.flight_takeoff_outlined,
              secenekler: kDunyaUlkeleri,
            ),
          if (_istekMi) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() {
                _neredenFarketmez = !_neredenFarketmez;
                if (_neredenFarketmez) _neredenCtrl.clear();
              }),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: _neredenFarketmez ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _neredenFarketmez
                            ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD)),
                    ),
                    child: _neredenFarketmez
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text('Nereden farketmez',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: const Color(0xFF999999))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          _alanEtiket('Nereye *'),
          const SizedBox(height: 6),
          AutocompleteAlan(
            controller: _nereyeCtrl,
            hint: 'Şehir ara...',
            icon: Icons.flight_land_outlined,
            secenekler: _nereyeOneriListesi,
          ),
        ],
      );
    }

    if (!_istekMi && adim == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _alanEtiket('Seyahat tarihi *'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _tarihSec,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: Color(0xFFBBBBBB)),
                  const SizedBox(width: 10),
                  Text(
                    _seciliTarih != null
                        ? '${_seciliTarih!.day}.${_seciliTarih!.month}.${_seciliTarih!.year}'
                        : 'Tarih seç...',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: _seciliTarih != null
                          ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          _alanEtiket('Taşıma tercihi'),
          const SizedBox(height: 10),
          ...[
            ('istekler',      'İsteklere açığım',     Icons.search_outlined),
            ('getirebilirim', 'Bunları getirebilirim', Icons.inventory_2_outlined),
            ('hepsi',         'Her ikisi de',          Icons.swap_horiz_outlined),
          ].map((item) {
            final secili = _tasimaTercihi == item.$1;
            return GestureDetector(
              onTap: () => setState(() => _tasimaTercihi = item.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: secili ? const Color(0xFFFAFAFA) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: secili ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    Icon(item.$3, size: 18,
                        color: secili ? const Color(0xFF1A1A1A) : const Color(0xFF999999)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.$2,
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: secili ? FontWeight.w500 : FontWeight.w400,
                              color: secili ? const Color(0xFF1A1A1A) : const Color(0xFF666666))),
                    ),
                    if (secili)
                      const Icon(Icons.check_circle, size: 18, color: Color(0xFF1A1A1A)),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }

    // ── Detaylar (her iki tip için ortak son adım) ──────────────────────────────
    final toplamFoto = _mevcutResimler.length + _yeniResimler.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alanEtiket('Notlar'),
        const SizedBox(height: 6),
        _altCizgiAlan(
          controller: _notlarCtrl,
          hint: 'Ek bilgi, özel istekler...',
          maxLines: 3,
          maxLength: 300,
        ),
        const SizedBox(height: 22),
        if (_sadeceGeliyorum) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff_outlined,
                    size: 20, color: Color(0xFFE24B4A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Belirli bir ürün eklemediğin için ilanına varsayılan bir görsel ekleyeceğiz.',
                    style: GoogleFonts.dmSans(
                        fontSize: 12.5, color: const Color(0xFF777777), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
        Row(
          children: [
            _alanEtiket('Fotoğraflar'),
            const Spacer(),
            Text('$toplamFoto / ${Pagination.maxResimSayisi}',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: const Color(0xFF999999))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (toplamFoto < Pagination.maxResimSayisi)
                GestureDetector(
                  onTap: _resimEkle,
                  child: Container(
                    width: 96, height: 96,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        size: 22, color: Color(0xFFBBBBBB)),
                  ),
                ),
              ..._mevcutResimler.asMap().entries.map((e) => _ResimKutu(
                ilkMi: e.key == 0,
                onSil: () => setState(() => _mevcutResimler.removeAt(e.key)),
                child: CachedNetworkImage(
                  cacheManager: AppCacheManager.instance,
                  imageUrl: e.value,
                  width: 96, height: 96, fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                ),
              )),
              ..._yeniResimler.asMap().entries.map((e) => _ResimKutu(
                ilkMi: _mevcutResimler.isEmpty && e.key == 0,
                onSil: () => setState(() => _yeniResimler.removeAt(e.key)),
                child: Image.file(e.value,
                    width: 96, height: 96, fit: BoxFit.cover),
              )),
            ],
          ),
        ),
        ],
      ],
    );
  }
}

// ── Türkçe ünlü uyumu — "-dan/-den/-tan/-ten" eki ────────────────────────────
//
// "Amerika'dan", "İngiltere'den", "Irak'tan" gibi doğru ek seçimi için.
// Son sesli harf ön/art ünlüyü, son harf ise sert/yumuşak sessizi belirler.
String _turkceAblatifEki(String kelime) {
  if (kelime.isEmpty) return 'dan';
  const onSesliler   = {'e', 'i', 'ö', 'ü'};
  const sertSesizler = {'p', 'ç', 't', 'k', 's', 'ş', 'h', 'f'};

  String sonSesli = 'a';
  for (var i = kelime.length - 1; i >= 0; i--) {
    final c = kelime[i].toLowerCase();
    if ('aeıioöuü'.contains(c)) { sonSesli = c; break; }
  }

  final on   = onSesliler.contains(sonSesli);
  final sert = sertSesizler.contains(kelime[kelime.length - 1].toLowerCase());

  if (on) return sert ? 'ten' : 'den';
  return sert ? 'tan' : 'dan';
}

// ── Sadece geliyorum toggle'ı ─────────────────────────────────────────────────

class _SadeceGeliyorumToggle extends StatelessWidget {
  final bool secili;
  final VoidCallback onTap;

  const _SadeceGeliyorumToggle({required this.secili, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: secili ? const Color(0xFFFFF0EF) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? const Color(0xFFE24B4A) : const Color(0xFFEEEEEE),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.flight_takeoff_outlined,
                size: 20,
                color: secili ? const Color(0xFFE24B4A) : const Color(0xFF999999)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Geliyorum, isteklere açığım',
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      )),
                  const SizedBox(height: 2),
                  Text('İstekçiler için ulaşılabilir ol',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: const Color(0xFF999999),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44, height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: secili ? const Color(0xFFE24B4A) : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: secili ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Küçük yardımcı arayüz parçaları ─────────────────────────────────────────────

Widget _alanEtiket(String text) => Text(text,
    style: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF999999)));

Widget _altCizgiAlan({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
  int? maxLength,
  String? errorText,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    maxLength: maxLength,
    style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF1A1A1A)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFFBBBBBB)),
      errorText: errorText,
      errorStyle: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFE53935)),
      counterText: '',
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFEEEEEE))),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFEEEEEE))),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 1.5)),
      errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE53935))),
      focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE53935), width: 1.5)),
    ),
  );
}

// ── Resim kutusu ─────────────────────────────────────────────────────────────────

class _ResimKutu extends StatelessWidget {
  final Widget child;
  final bool ilkMi;
  final VoidCallback onSil;
  const _ResimKutu({
    required this.child, required this.ilkMi, required this.onSil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
          if (ilkMi)
            Positioned(
              bottom: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Kapak',
                    style: GoogleFonts.dmSans(
                        fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onSil,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Beden / Cinsiyet Seçici ───────────────────────────────────────────────────

class BedenCinsiyetBolum extends StatelessWidget {
  final BedenTipi tip;
  final String cinsiyet;
  final String beden;
  final String pantolonBel;
  final String pantolonBoy;
  final ValueChanged<String> onCinsiyetDegis;
  final ValueChanged<String> onBedenDegis;
  final ValueChanged<String> onPantolonBelDegis;
  final ValueChanged<String> onPantolonBoyDegis;

  const BedenCinsiyetBolum({super.key,
    required this.tip,
    required this.cinsiyet,
    required this.beden,
    required this.pantolonBel,
    required this.pantolonBoy,
    required this.onCinsiyetDegis,
    required this.onBedenDegis,
    required this.onPantolonBelDegis,
    required this.onPantolonBoyDegis,
  });

  List<String> get _cinsiyetler => tip == BedenTipi.cocuk
      ? ['Kız', 'Erkek', 'Unisex']
      : ['Kadın', 'Erkek', 'Unisex'];

  List<String> get _bedenler {
    switch (tip) {
      case BedenTipi.standart: return kBedenStandart;
      case BedenTipi.ayakkabi: return kBedenAyakkabi;
      case BedenTipi.cocuk:    return kBedenCocuk;
      default:                 return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alanEtiket('Cinsiyet *'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _cinsiyetler.map((c) {
            final secili = cinsiyet == c;
            return GestureDetector(
              onTap: () => onCinsiyetDegis(secili ? '' : c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: secili ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: secili ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Text(
                  c,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secili ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (tip == BedenTipi.pantolon) ...[
          _alanEtiket('Beden (Bel / Boy) *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownBeden(
                  hint: 'Bel',
                  secili: pantolonBel,
                  secenekler: kBedenPantolonBel,
                  onDegis: onPantolonBelDegis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownBeden(
                  hint: 'Boy',
                  secili: pantolonBoy,
                  secenekler: kBedenPantolonBoy,
                  onDegis: onPantolonBoyDegis,
                ),
              ),
            ],
          ),
        ] else ...[
          _alanEtiket(tip == BedenTipi.ayakkabi ? 'Numara *' : 'Beden *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bedenler.map((b) {
              final secili = beden == b;
              return GestureDetector(
                onTap: () => onBedenDegis(secili ? '' : b),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: secili ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: secili ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Text(
                    b,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secili ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class DropdownBeden extends StatelessWidget {
  final String hint;
  final String secili;
  final List<String> secenekler;
  final ValueChanged<String> onDegis;

  const DropdownBeden({super.key,
    required this.hint,
    required this.secili,
    required this.secenekler,
    required this.onDegis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: secili.isEmpty ? null : secili,
          hint: Text(hint,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: const Color(0xFFBBBBBB))),
          isExpanded: true,
          style: GoogleFonts.dmSans(
              fontSize: 14, color: const Color(0xFF1A1A1A)),
          items: secenekler
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => onDegis(v ?? ''),
        ),
      ),
    );
  }
}

// ── Kategori Seçim Sheet ──────────────────────────────────────────────────────

class KategoriSecimSheet extends StatefulWidget {
  final List<String> seciliYol;
  final void Function(List<String> yol) onSecildi;

  const KategoriSecimSheet({
    super.key,
    required this.seciliYol,
    required this.onSecildi,
  });

  @override
  State<KategoriSecimSheet> createState() => _KategoriSecimSheetState();
}

class _KategoriSecimSheetState extends State<KategoriSecimSheet> {
  late List<String> _yol;

  @override
  void initState() {
    super.initState();
    final yol = List<String>.from(widget.seciliYol);
    if (yol.isNotEmpty) {
      final lastNode = kategoriNodeBul(yol.last);
      if (lastNode == null || lastNode.yaprakMi) yol.removeLast();
    }
    _yol = yol;
  }

  List<KategoriNode> _mevcutSeviyeNodes() {
    if (_yol.isEmpty) return kKategoriAgaci;
    List<KategoriNode> liste = kKategoriAgaci;
    for (final key in _yol) {
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
    if (_yol.isEmpty) return 'Kategori Seç';
    final node = kategoriNodeBul(_yol.last);
    return node?.ad ?? 'Kategori Seç';
  }

  String _breadcrumb() {
    if (_yol.isEmpty) return '';
    return _yol.map((key) {
      final node = kategoriNodeBul(key);
      return node?.ad ?? key;
    }).join(' › ');
  }

  void _nodeSecildi(KategoriNode node) {
    if (node.yaprakMi) {
      final yeniYol = [..._yol, node.key];
      widget.onSecildi(yeniYol);
    } else {
      setState(() => _yol = [..._yol, node.key]);
    }
  }

  void _geriGit() {
    if (_yol.isNotEmpty) {
      setState(() => _yol = _yol.sublist(0, _yol.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes      = _mevcutSeviyeNodes();
    final breadcrumb = _breadcrumb();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(
            width: 32, height: 3,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_yol.isNotEmpty)
                  GestureDetector(
                    onTap: _geriGit,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_back_ios_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _seviyeBasligi(),
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (widget.seciliYol.isNotEmpty)
                  GestureDetector(
                    onTap: () => widget.onSecildi([]),
                    child: Text('Temizle',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          if (breadcrumb.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Text(
                breadcrumb,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: nodes.length,
              itemBuilder: (ctx, i) {
                final node   = nodes[i];
                final secili = widget.seciliYol.contains(node.key);
                return InkWell(
                  onTap: () => _nodeSecildi(node),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: secili
                          ? AppColors.red.withValues(alpha: 0.05)
                          : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(kategoriIkon(node.key),
                            size: 18, color: const Color(0xFF666666)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            node.ad,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: secili
                                  ? FontWeight.w600 : FontWeight.w400,
                              color: secili
                                  ? AppColors.red : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (secili)
                          const Icon(Icons.check,
                              size: 18, color: AppColors.red)
                        else if (!node.yaprakMi)
                          const Icon(Icons.chevron_right,
                              size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}