import 'g_colors.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'degerlendirme_screen.dart';
import 'login_screen.dart';
import '../auth_gate.dart';
import 'sohbet_screen.dart';
 
// ── Kategori Sabitleri ────────────────────────────────────
const Map<String, String> kKategoriler = {
  'giyim': '👗 Giyim & Aksesuar',
  'elektronik': '📱 Elektronik',
  'guzellik': '💄 Güzellik & Sağlık',
  'ev': '🏠 Ev & Yaşam',
  'spor': '⚽ Spor & Outdoor',
  'kultur': '📚 Kültür & Eğlence',
  'gida': '🍫 Gıda & İçecek',
  'diger': '📦 Diğer',
};
 
String kategoriAdi(String? key) {
  if (key == null || key.isEmpty) return '';
  return kKategoriler[key] ?? '📦 Diğer';
}
 
class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
 
  @override
  State<ProfilPage> createState() => _ProfilPageState();
}
 
class _ProfilPageState extends State<ProfilPage> {
  bool _yukleniyor = false;
 
  Future<void> _fotoDegistir() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final file = File(picked.path);
    final boyut = await file.length();
    if (boyut > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fotoğraf 2 MB\'dan büyük olamaz.',
              style: GoogleFonts.dmSans()),
          backgroundColor: GColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    setState(() => _yukleniyor = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profil_fotograflari/${user.uid}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .update({'fotoUrl': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Fotoğraf güncellendi!', style: GoogleFonts.dmSans()),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: $e', style: GoogleFonts.dmSans()),
          backgroundColor: GColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }
 
  Future<void> _cikisYap() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Çıkış Yap',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Hesabınızdan çıkmak istiyor musunuz?',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: GColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: GColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Çıkış Yap',
                style: GoogleFonts.dmSans(
                    color: GColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
 
  void _ilanDuzenle(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final urunCtrl =
        TextEditingController(text: data['urun']?.toString() ?? '');
    final neredenCtrl =
        TextEditingController(text: data['nereden']?.toString() ?? '');
    final nereyeCtrl =
        TextEditingController(text: data['nereye']?.toString() ?? '');
    final ucretCtrl =
        TextEditingController(text: data['ucret']?.toString() ?? '');
    final notlarCtrl =
        TextEditingController(text: data['notlar']?.toString() ?? '');
    bool aktif = data['aktif'] != false;
    final bool isIstek = data['tip'] == 'istek';
    String secilenKategori = data['kategori']?.toString() ?? 'diger';
 
    final mevcutUrller = List<String>.from(data['resimUrller'] ?? []);
    if (mevcutUrller.isEmpty &&
        data['resimUrl'] != null &&
        (data['resimUrl'] as String).isNotEmpty) {
      mevcutUrller.add(data['resimUrl'] as String);
    }
    final List<String> kalanUrller = List.from(mevcutUrller);
    final List<File> yeniResimler = [];
 
    showModalBottomSheet(
      context: context,
      backgroundColor: GColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final toplamResim = kalanUrller.length + yeniResimler.length;
 
          Future<void> resimEkle() async {
            if (toplamResim >= 4) return;
            final picker = ImagePicker();
            final picked = await picker.pickImage(
                source: ImageSource.gallery, imageQuality: 80);
            if (picked != null) {
              setModalState(() => yeniResimler.add(File(picked.path)));
            }
          }
 
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: GColors.divider,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('İlanı Düzenle',
                      style: GoogleFonts.dmSans(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  if (isIstek) ...[
                    DuzenleAlani(label: 'Ürün', controller: urunCtrl),
                    const SizedBox(height: 12),
                  ],
                  DuzenleAlani(label: 'Nereden', controller: neredenCtrl),
                  const SizedBox(height: 12),
                  DuzenleAlani(label: 'Nereye', controller: nereyeCtrl),
                  const SizedBox(height: 12),
                  DuzenleAlani(
                      label: 'Ücret (₺)',
                      controller: ucretCtrl,
                      klavye: TextInputType.number),
                  const SizedBox(height: 12),
                  DuzenleAlani(
                      label: 'Notlar',
                      controller: notlarCtrl,
                      maxLines: 3),
                  if (isIstek) ...[
                    const SizedBox(height: 16),
                    Text('Kategori',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: GColors.textSecondary)),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (context, setCatState) => Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: kKategoriler.entries.map((e) {
                          final secili = secilenKategori == e.key;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => secilenKategori = e.key);
                              setCatState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: secili
                                    ? GColors.textPrimary
                                    : GColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: secili
                                        ? GColors.textPrimary
                                        : GColors.divider),
                              ),
                              child: Text(e.value,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: secili
                                          ? Colors.white
                                          : GColors.textSecondary,
                                      fontWeight: secili
                                          ? FontWeight.w600
                                          : FontWeight.w400)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (isIstek) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Resimler',
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: GColors.textSecondary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: toplamResim == 4
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$toplamResim/4',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: toplamResim == 4
                                      ? GColors.red
                                      : const Color(0xFF2E7D32))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...kalanUrller.asMap().entries.map((e) {
                            final i = e.key;
                            final url = e.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      fadeInDuration: Duration.zero,
                                      placeholder: (_, __) => Container(
                                          width: 90,
                                          height: 90,
                                          color: GColors.surface),
                                      errorWidget: (_, __, ___) => Container(
                                          width: 90,
                                          height: 90,
                                          color: GColors.surface),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setModalState(
                                          () => kalanUrller.removeAt(i)),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                  if (i == 0)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text('Ana',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 9,
                                                color: Colors.white)),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          ...yeniResimler.asMap().entries.map((e) {
                            final i = e.key;
                            final file = e.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(file,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setModalState(
                                          () => yeniResimler.removeAt(i)),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withValues(alpha: 0.8),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text('Yeni',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 9,
                                              color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (toplamResim < 4)
                            GestureDetector(
                              onTap: resimEkle,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: GColors.surface,
                                  border: Border.all(color: GColors.divider),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 24,
                                        color: GColors.textSecondary),
                                    const SizedBox(height: 4),
                                    Text('Ekle',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 10,
                                            color: GColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('İlan aktif',
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: GColors.textPrimary)),
                      const Spacer(),
                      Switch(
                        value: aktif,
                        onChanged: (v) => setModalState(() => aktif = v),
                        activeColor: GColors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          final List<String> tumUrller =
                              List.from(kalanUrller);
                          if (user != null && yeniResimler.isNotEmpty) {
                            for (int i = 0; i < yeniResimler.length; i++) {
                              final ref = FirebaseStorage.instance
                                  .ref()
                                  .child('ilan_resimleri')
                                  .child(
                                      '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
                              await ref.putFile(yeniResimler[i]);
                              final url = await ref.getDownloadURL();
                              tumUrller.add(url);
                            }
                          }
                          final updateData = <String, dynamic>{
                            if (isIstek) 'urun': urunCtrl.text.trim(),
                            'nereden': neredenCtrl.text.trim(),
                            'nereye': nereyeCtrl.text.trim(),
                            'ucret': ucretCtrl.text.trim(),
                            'notlar': notlarCtrl.text.trim(),
                            'aktif': aktif,
                            if (isIstek) 'kategori': secilenKategori,
                          };
                          if (isIstek) {
                            updateData['resimUrl'] =
                                tumUrller.isNotEmpty ? tumUrller.first : '';
                            updateData['resimUrller'] = tumUrller;
                          }
                          await FirebaseFirestore.instance
                              .collection('ilanlar')
                              .doc(docId)
                              .update(updateData);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('İlan güncellendi! ✓',
                                    style: GoogleFonts.dmSans()),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Kayıt hatası: $e',
                                    style: GoogleFonts.dmSans()),
                                backgroundColor: GColors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GColors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text('Kaydet',
                          style: GoogleFonts.dmSans(
                              color: GColors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
 
  Future<void> _ilanDetayGoster(
      BuildContext context, String docId, Map<String, dynamic> d) async {
    final tip = d['tip'] ?? 'istek';
    final urun = d['urun'] ?? '';
    final nereden = d['nereden'] ?? '';
    final nereye = d['nereye'] ?? '';
    final ucret = d['ucret'] ?? '';
    final notlar = d['notlar'] ?? '';
    final aktif = d['aktif'] != false;
    final resimUrl = d['resimUrl'] as String?;
    final resimVar = resimUrl != null && resimUrl.isNotEmpty;
 
    showModalBottomSheet(
      context: context,
      backgroundColor: GColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: GColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resimVar) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: resimUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          placeholder: (_, __) => Container(
                              height: 200, color: GColors.surface),
                          errorWidget: (_, __, ___) => Container(
                              height: 200, color: GColors.surface),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GColors.chipBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tip == 'tasiyici'
                                ? '✈️  TAŞIYICI'
                                : '🛍️  İSTEK',
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: GColors.textSecondary,
                                letterSpacing: 2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: aktif
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            aktif ? 'Aktif' : 'Pasif',
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: aktif
                                    ? const Color(0xFF2E7D32)
                                    : GColors.textHint),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (urun.isNotEmpty) ...[
                      Text(urun,
                          style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: GColors.textPrimary)),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Flexible(
                          child: Text(nereden.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: GColors.textSecondary,
                                  letterSpacing: 1)),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              color: GColors.red, size: 14),
                        ),
                        Flexible(
                          child: Text(nereye.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: GColors.red,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ),
                    if (ucret.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('₺$ucret',
                          style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: GColors.red)),
                    ],
                    Builder(builder: (context) {
                      final tarih = d['tarih'];
                      if (tarih == null) return const SizedBox.shrink();
                      final dt = (tarih as Timestamp).toDate();
                      final simdi = DateTime.now();
                      final fark = dt
                          .difference(DateTime(
                              simdi.year, simdi.month, simdi.day))
                          .inDays;
                      final String tarihStr;
                      if (fark < 0) {
                        tarihStr = 'Geçti';
                      } else if (fark == 0) {
                        tarihStr = 'Bugün';
                      } else if (fark == 1) {
                        tarihStr = 'Yarın';
                      } else {
                        tarihStr = '$fark gün sonra';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 14, color: GColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(tarihStr,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: GColors.textSecondary)),
                          ],
                        ),
                      );
                    }),
                    if (notlar.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(notlar,
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: GColors.textSecondary,
                              height: 1.5)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _ilanDuzenle(context, docId, d);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text('Düzenle',
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GColors.primary,
                          side: const BorderSide(color: GColors.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
 
    if (user == null) {
      return Scaffold(
        backgroundColor: GColors.surface,
        appBar: AppBar(
          backgroundColor: GColors.white,
          elevation: 0,
          title: Text('Profil',
              style: GoogleFonts.dmSans(
                  color: GColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 18)),
        ),
        body: GirisGerekli(
          icon: Icons.person_outline,
          mesaj: 'Profilinizi görmek için giriş yapın.',
          onGirisYap: () => loginGerekli(context),
        ),
      );
    }
 
    return Scaffold(
      backgroundColor: GColors.surface,
      appBar: AppBar(
        backgroundColor: GColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GColors.divider,
        title: Text('Profil',
            style: GoogleFonts.dmSans(
                color: GColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: GColors.textSecondary, size: 22),
            onPressed: _cikisYap,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final adSoyad =
              data['adSoyad'] ?? user.displayName ?? 'Kullanıcı';
          final email = data['email'] ?? user.email ?? '';
          final sehir = data['sehir'] ?? '';
          final telefon = data['telefon'] ?? '';
          final telefonGizli = data['telefonGizli'] == true;
          final telefonGosterilsin = telefon.isNotEmpty && !telefonGizli;
          final fotoUrl = data['fotoUrl'] ?? user.photoURL;
          final puanSayisi =
              ((data['degerlendirmeSayisi']) as num?)?.toInt() ?? 0;
 
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: GColors.white,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          _yukleniyor
                              ? Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: GColors.surface),
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          color: GColors.blue,
                                          strokeWidth: 2)),
                                )
                              : avatarWidget(
                                  isim: adSoyad,
                                  fotoUrl: fotoUrl,
                                  radius: 40,
                                  fontSize: 28,
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _fotoDegistir,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: GColors.blue,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt,
                                    color: GColors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(adSoyad,
                          style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: GColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: GColors.textSecondary)),
                      if (puanSayisi > 0) ...[
                        const SizedBox(height: 12),
                        DegerlendirmeWidget(kullaniciId: user.uid),
                      ],
                      if ((data['notlar'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            data['notlar'].toString(),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: GColors.textSecondary,
                                height: 1.4),
                          ),
                        ),
                      ],
                      if (sehir.isNotEmpty || telefonGosterilsin) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (sehir.isNotEmpty) ...[
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: GColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(sehir,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: GColors.textSecondary)),
                            ],
                            if (sehir.isNotEmpty && telefonGosterilsin)
                              const SizedBox(width: 16),
                            if (telefonGosterilsin) ...[
                              const Icon(Icons.phone_outlined,
                                  size: 14, color: GColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(telefon,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: GColors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ProfilDuzenleButonu(userId: user.uid, data: data),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _IlanlarimWidget(
                  userId: user.uid,
                  onDetay: _ilanDetayGoster,
                  onDuzenle: _ilanDuzenle,
                ),
                const SizedBox(height: 8),
                if (puanSayisi > 0)
                  _DegerlendirmelerListesi(userId: user.uid),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
 
// ── İlanlarım Widget ──────────────────────────────────────
 
class _IlanlarimWidget extends StatefulWidget {
  final String userId;
  final Function(BuildContext, String, Map<String, dynamic>) onDetay;
  final Function(BuildContext, String, Map<String, dynamic>) onDuzenle;
 
  const _IlanlarimWidget({
    required this.userId,
    required this.onDetay,
    required this.onDuzenle,
  });
 
  @override
  State<_IlanlarimWidget> createState() => _IlanlarimWidgetState();
}
 
class _IlanlarimWidgetState extends State<_IlanlarimWidget> {
  void _yenile() => setState(() {});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: GColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('İlanlarım',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: GColors.textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: _yenile,
                  child: const Icon(Icons.refresh,
                      size: 18, color: GColors.textSecondary),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ilanlar')
                .where('kullaniciId', isEqualTo: widget.userId)
                .orderBy('olusturmaTarihi', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: GColors.red, strokeWidth: 2)),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Henüz ilan vermediniz.',
                        style: GoogleFonts.dmSans(
                            color: GColors.textSecondary, fontSize: 14)),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d = doc.data() as Map<String, dynamic>;
                    final aktif = d['aktif'] != false;
                    final tip = d['tip'] ?? 'istek';
                    final resimUrl = d['resimUrl'] as String?;
                    final resimVar =
                        resimUrl != null && resimUrl.isNotEmpty;
                    final baslik = tip == 'tasiyici'
                        ? '${d['nereden']} → ${d['nereye']}'
                        : (d['urun'] ?? '');
 
                    return GestureDetector(
                      onTap: () =>
                          widget.onDetay(context, doc.id, d),
                      child: Container(
                        decoration: BoxDecoration(
                          color: GColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GColors.divider),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Resim bölümü
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    resimVar
                                        ? CachedNetworkImage(
                                            imageUrl: resimUrl,
                                            fit: BoxFit.cover,
                                            fadeInDuration: Duration.zero,
                                            placeholder: (_, __) =>
                                                Container(
                                                    color: GColors.surface),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                    color: GColors.surface,
                                                    child: Center(
                                                        child: Text(
                                                      tip == 'tasiyici'
                                                          ? '✈️'
                                                          : '🛍️',
                                                      style: const TextStyle(
                                                          fontSize: 32),
                                                    ))),
                                          )
                                        : Container(
                                            color: GColors.surface,
                                            child: Center(
                                                child: Text(
                                              tip == 'tasiyici'
                                                  ? '✈️'
                                                  : '🛍️',
                                              style: const TextStyle(
                                                  fontSize: 32),
                                            )),
                                          ),
                                    // Aktif/Pasif badge
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: aktif
                                              ? const Color(0xFF2E7D32)
                                              : GColors.textHint,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          aktif ? 'Aktif' : 'Pasif',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    // 3 nokta menü
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.white,
                                            size: 20),
                                        color: GColors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        onSelected: (value) async {
                                          if (value == 'duzenle') {
                                            widget.onDuzenle(
                                                context, doc.id, d);
                                            await Future.delayed(
                                                const Duration(
                                                    milliseconds: 500));
                                            _yenile();
                                          } else if (value == 'pasif') {
                                            await FirebaseFirestore.instance
                                                .collection('ilanlar')
                                                .doc(doc.id)
                                                .update(
                                                    {'aktif': !aktif});
                                            _yenile();
                                          } else if (value == 'sil') {
                                            final onay =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                shape:
                                                    RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    12)),
                                                title: Text('İlanı Sil',
                                                    style:
                                                        GoogleFonts.dmSans(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                content: Text(
                                                    'Bu ilanı silmek istediğinize emin misiniz?',
                                                    style:
                                                        GoogleFonts.dmSans(
                                                            fontSize: 14,
                                                            color: GColors
                                                                .textSecondary)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: Text('İptal',
                                                        style: GoogleFonts
                                                            .dmSans(
                                                                color: GColors
                                                                    .textSecondary)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child: Text('Sil',
                                                        style: GoogleFonts
                                                            .dmSans(
                                                                color: GColors
                                                                    .red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (onay == true) {
                                              await FirebaseFirestore
                                                  .instance
                                                  .collection('ilanlar')
                                                  .doc(doc.id)
                                                  .delete();
                                              _yenile();
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'duzenle',
                                            child: Row(children: [
                                              const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color:
                                                      GColors.textPrimary),
                                              const SizedBox(width: 10),
                                              Text('Düzenle',
                                                  style:
                                                      GoogleFonts.dmSans(
                                                          fontSize: 14)),
                                            ]),
                                          ),
                                          PopupMenuItem(
                                            value: 'pasif',
                                            child: Row(children: [
                                              Icon(
                                                aktif
                                                    ? Icons
                                                        .pause_circle_outline
                                                    : Icons
                                                        .play_circle_outline,
                                                size: 18,
                                                color: GColors.textPrimary,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                  aktif
                                                      ? 'Pasife Al'
                                                      : 'Aktife Al',
                                                  style:
                                                      GoogleFonts.dmSans(
                                                          fontSize: 14)),
                                            ]),
                                          ),
                                          PopupMenuItem(
                                            value: 'sil',
                                            child: Row(children: [
                                              const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: GColors.red),
                                              const SizedBox(width: 10),
                                              Text('Sil',
                                                  style:
                                                      GoogleFonts.dmSans(
                                                          fontSize: 14,
                                                          color:
                                                              GColors.red)),
                                            ]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Alt bilgi
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    baslik,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: aktif
                                            ? GColors.textPrimary
                                            : GColors.textSecondary,
                                        height: 1.3),
                                  ),
                                  if (tip == 'istek' &&
                                      (d['nereye'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.location_on_outlined,
                                            size: 11,
                                            color: GColors.red),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            d['nereye']
                                                .toString()
                                                .toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.dmSans(
                                                fontSize: 10,
                                                color: GColors.red,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if ((d['ucret'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '₺${d["ucret"]}',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: GColors.red),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
 
// ── Profil Düzenle Butonu ─────────────────────────────────
 
class _ProfilDuzenleButonu extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  const _ProfilDuzenleButonu({required this.userId, required this.data});
 
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _profilDuzenleGoster(context),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text('Profili Düzenle', style: GoogleFonts.dmSans(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: GColors.primary,
        side: const BorderSide(color: GColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
 
  void _profilDuzenleGoster(BuildContext context) {
    final adCtrl =
        TextEditingController(text: data['adSoyad']?.toString() ?? '');
    final sehirCtrl =
        TextEditingController(text: data['sehir']?.toString() ?? '');
    final telefonCtrl =
        TextEditingController(text: data['telefon']?.toString() ?? '');
    final notlarCtrl =
        TextEditingController(text: data['notlar']?.toString() ?? '');
 
    showModalBottomSheet(
      context: context,
      backgroundColor: GColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: GColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Profili Düzenle',
                  style: GoogleFonts.dmSans(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              DuzenleAlani(label: 'Ad Soyad', controller: adCtrl),
              const SizedBox(height: 12),
              DuzenleAlani(label: 'Şehir', controller: sehirCtrl),
              const SizedBox(height: 12),
              DuzenleAlani(
                  label: 'Telefon',
                  controller: telefonCtrl,
                  klavye: TextInputType.phone),
              const SizedBox(height: 12),
              DuzenleAlani(
                  label: 'Hakkımda',
                  controller: notlarCtrl,
                  maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final yeniAd = adCtrl.text.trim();
                    await FirebaseFirestore.instance
                        .collection('kullanicilar')
                        .doc(userId)
                        .update({
                      'adSoyad': yeniAd,
                      'sehir': sehirCtrl.text.trim(),
                      'telefon': telefonCtrl.text.trim(),
                      'notlar': notlarCtrl.text.trim(),
                    });
                    if (yeniAd.isNotEmpty) {
                      await FirebaseAuth.instance.currentUser
                          ?.updateDisplayName(yeniAd);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GColors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Kaydet',
                      style: GoogleFonts.dmSans(
                          color: GColors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
// ── Değerlendirmeler Listesi ──────────────────────────────
 
class _DegerlendirmelerListesi extends StatelessWidget {
  final String userId;
  const _DegerlendirmelerListesi({required this.userId});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: GColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Değerlendirmeler',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: GColors.textPrimary)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('degerlendirmeler')
                .where('hedefId', isEqualTo: userId)
                .orderBy('tarih', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox.shrink();
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final puan = ((d['puan']) as num?)?.toInt() ?? 0;
                  final yorum = d['yorum'] ?? '';
                  final ad = d['degerlendiriciAd'] ?? 'Kullanıcı';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: avatarWidget(isim: ad, radius: 20),
                    title: Row(
                      children: [
                        Text(ad,
                            style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < puan ? Icons.star : Icons.star_border,
                                  size: 13,
                                  color: const Color(0xFFFFB300),
                                )),
                      ],
                    ),
                    subtitle: yorum.isNotEmpty
                        ? Text(yorum,
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: GColors.textSecondary))
                        : null,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}