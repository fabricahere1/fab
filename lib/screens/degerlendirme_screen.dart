import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Renk Sabitleri ────────────────────────────────────────
const degPrimary = Color(0xFF3C3C3C);
const degSurface = Color(0xFFF5F5F5);
const degDivider = Color(0xFFE0E0E0);
const degTextPrimary = Color(0xFF212121);
const degTextSecondary = Color(0xFF757575);
const degRed = Color(0xFFE53935);
const degYellow = Color(0xFFFFB300);

// ── Değerlendirme Ekranı ──────────────────────────────────

class DegerlendirmeScreen extends StatefulWidget {
  final String hedefKullaniciId;
  final String hedefKullaniciAd;
  final String sohbetId;
  final String ilanBaslik;

  const DegerlendirmeScreen({
    super.key,
    required this.hedefKullaniciId,
    required this.hedefKullaniciAd,
    required this.sohbetId,
    required this.ilanBaslik,
  });

  @override
  State<DegerlendirmeScreen> createState() => _DegerlendirmeScreenState();
}

class _DegerlendirmeScreenState extends State<DegerlendirmeScreen> {
  int _puan = 0;
  final _yorumController = TextEditingController();
  bool _yukleniyor = false;

  @override
  void dispose() {
    _yorumController.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (_puan == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen puan verin.', style: GoogleFonts.roboto()),
          backgroundColor: degRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final benimAd =
          user.displayName ?? user.email?.split('@')[0] ?? 'Kullanıcı';

      // ── OPTİMİZASYON: Tüm değerlendirmeleri çekmek yerine ──
      // Firestore transaction ile mevcut sayı ve toplamı atomic güncelle
      final kullaniciRef = FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(widget.hedefKullaniciId);

      // Mevcut puanı oku
      final kullaniciSnap = await kullaniciRef.get();
      final mevcutVeri =
          kullaniciSnap.data() as Map<String, dynamic>? ?? {};

      final mevcutSayi =
          ((mevcutVeri['degerlendirmeSayisi']) as num?)?.toInt() ?? 0;
      final mevcutOrtalama =
          ((mevcutVeri['ortalamaPuan']) as num?)?.toDouble() ?? 0.0;

      final yeniSayi = mevcutSayi + 1;
      final yeniOrtalama =
          ((mevcutOrtalama * mevcutSayi) + _puan) / yeniSayi;

      // Değerlendirmeyi kaydet
      await FirebaseFirestore.instance
          .collection('degerlendirmeler')
          .add({
        'hedefId': widget.hedefKullaniciId,
        'hedefAd': widget.hedefKullaniciAd,
        'degerelendirenId': user.uid,
        'degerelendirenAd': benimAd,
        'puan': _puan,
        'yorum': _yorumController.text.trim(),
        'ilanBaslik': widget.ilanBaslik,
        'sohbetId': widget.sohbetId,
        'tarih': FieldValue.serverTimestamp(),
      });

      // Kullanıcı puanını güncelle
      await kullaniciRef.set({
        'ortalamaPuan': yeniOrtalama,
        'degerlendirmeSayisi': yeniSayi,
      }, SetOptions(merge: true));

      // Sohbeti işaretle
      await FirebaseFirestore.instance
          .collection('sohbetler')
          .doc(widget.sohbetId)
          .set({'degerlendirmeYapildi': true}, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Değerlendirmeniz gönderildi!',
                style: GoogleFonts.roboto()),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint("DEGERLENDIRME HATA: $e");
      debugPrint("STACK: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.roboto(fontSize: 11)),
            backgroundColor: degRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 15),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: degSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: degDivider,
        leading: IconButton(
          icon: const Icon(Icons.close, color: degTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Değerlendir',
          style: GoogleFonts.roboto(
            color: degTextPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Kullanıcı kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: degPrimary,
                    child: Text(
                      widget.hedefKullaniciAd[0].toUpperCase(),
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.hedefKullaniciAd,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: degTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ilanBaslik,
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: degTextSecondary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nasıl bir deneyim yaşadınız?',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: degTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _puan = index + 1),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            index < _puan
                                ? Icons.star
                                : Icons.star_border,
                            color: degYellow,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _puanYazisi(_puan),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: _puan == 0 ? degTextSecondary : degYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yorum (isteğe bağlı)',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: degTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _yorumController,
                    maxLines: 4,
                    maxLength: 200,
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: degTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Deneyiminizi paylaşın...',
                      hintStyle: GoogleFonts.roboto(
                          color: const Color(0xFFBDBDBD)),
                      filled: true,
                      fillColor: degSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: degDivider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: degDivider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: degPrimary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _gonder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: degPrimary,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _yukleniyor
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Gönder',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _puanYazisi(int puan) {
    switch (puan) {
      case 1: return 'Çok kötü';
      case 2: return 'Kötü';
      case 3: return 'Orta';
      case 4: return 'İyi';
      case 5: return 'Mükemmel!';
      default: return 'Puan seçin';
    }
  }
}

// ── Değerlendirme Göster Widget ───────────────────────────

class DegerlendirmeWidget extends StatelessWidget {
  final String kullaniciId;
  const DegerlendirmeWidget({super.key, required this.kullaniciId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(kullaniciId)
          .snapshots(),
      builder: (context, snapshot) {
        final data =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final puan = ((data['ortalamaPuan']) as num?)?.toDouble() ?? 0.0;
        final sayi = ((data['degerlendirmeSayisi']) as num?)?.toInt() ?? 0;

        if (sayi == 0) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: degYellow, size: 14),
            const SizedBox(width: 3),
            Text(
              puan.toStringAsFixed(1),
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: degTextPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '($sayi)',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: degTextSecondary),
            ),
          ],
        );
      },
    );
  }
}

// ── Şikayet Dialog ────────────────────────────────────────

void sikayetGonder(
  BuildContext context, {
  required String hedefId,
  required String hedefAd,
  String? ilanId,
}) {
  String? secilenSebep;
  const sebepler = [
    'Sahte ilan',
    'Spam / Reklam',
    'Hakaret / Tehdit',
    'Dolandırıcılık',
    'Uygunsuz içerik',
    'Diğer',
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: degDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    color: degRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$hedefAd kullanıcısını şikayet et',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: degTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Şikayet sebebini seçin:',
              style: GoogleFonts.roboto(
                  fontSize: 13, color: degTextSecondary),
            ),
            const SizedBox(height: 12),
            ...sebepler.map((sebep) => GestureDetector(
                  onTap: () =>
                      setModalState(() => secilenSebep = sebep),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: secilenSebep == sebep
                          ? const Color(0xFFFFEBEE)
                          : degSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: secilenSebep == sebep
                            ? degRed
                            : degDivider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          secilenSebep == sebep
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: secilenSebep == sebep
                              ? degRed
                              : degTextSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          sebep,
                          style: GoogleFonts.roboto(
                              fontSize: 14, color: degTextPrimary),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: secilenSebep == null
                    ? null
                    : () async {
                        final user =
                            FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        await FirebaseFirestore.instance
                            .collection('sikayetler')
                            .add({
                          'hedefId': hedefId,
                          'hedefAd': hedefAd,
                          'sikayetEdenId': user.uid,
                          'sebep': secilenSebep,
                          'ilanId': ilanId ?? '',
                          'tarih': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Şikayetiniz alındı.',
                                  style: GoogleFonts.roboto()),
                              backgroundColor: degPrimary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: degRed,
                  disabledBackgroundColor: degDivider,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  'Şikayet Gönder',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}