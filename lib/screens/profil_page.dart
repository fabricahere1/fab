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
import 'ilanlar_page.dart';
import 'login_screen.dart';
import '../auth_gate.dart';
import 'sohbet_screen.dart';

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
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    final file = File(picked.path);
    final boyut = await file.length();
    const maxBoyut = 2 * 1024 * 1024; // 2 MB
    if (boyut > maxBoyut) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fotoğraf 2 MB\'dan büyük olamaz.',
              style: GoogleFonts.roboto()),
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
          content: Text('Fotoğraf güncellendi!',
              style: GoogleFonts.roboto()),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: $e', style: GoogleFonts.roboto()),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text('Çıkış Yap',
            style: GoogleFonts.roboto(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Hesabınızdan çıkmak istiyor musunuz?',
            style: GoogleFonts.roboto(
                fontSize: 14, color: GColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: GoogleFonts.roboto(color: GColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Çıkış Yap',
                style: GoogleFonts.roboto(
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

    showModalBottomSheet(
      context: context,
      backgroundColor: GColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                    style: GoogleFonts.roboto(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                if (data['tip'] == 'istek') ...[
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
                    label: 'Notlar', controller: notlarCtrl, maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('İlan aktif',
                        style: GoogleFonts.roboto(
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
                      await FirebaseFirestore.instance
                          .collection('ilanlar')
                          .doc(docId)
                          .update({
                        if (data['tip'] == 'istek')
                          'urun': urunCtrl.text.trim(),
                        'nereden': neredenCtrl.text.trim(),
                        'nereye': nereyeCtrl.text.trim(),
                        'ucret': ucretCtrl.text.trim(),
                        'notlar': notlarCtrl.text.trim(),
                        'aktif': aktif,
                      });
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GColors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text('Kaydet',
                        style: GoogleFonts.roboto(
                            color: GColors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // YENİ: Kendi ilanı için detay bottom sheet
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
                    // Resim
                    if (resimVar) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          resimUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Tip badge + aktiflik
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
                            tip == 'tasiyici' ? '✈️  TAŞIYICI' : '🛍️  İSTEK',
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
                    // Ürün adı
                    if (urun.isNotEmpty) ...[
                      Text(urun,
                          style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: GColors.textPrimary)),
                      const SizedBox(height: 10),
                    ],
                    // Rota
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
                    // Ücret
                    if (ucret.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('₺$ucret',
                          style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: GColors.red)),
                    ],
                    // Tarih
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
                    // Notlar
                    if (notlar.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(notlar,
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: GColors.textSecondary,
                              height: 1.5)),
                    ],
                    const SizedBox(height: 20),
                    // Düzenle butonu
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
              style: GoogleFonts.roboto(
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
            style: GoogleFonts.roboto(
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
          final telefonGosterilsin =
              telefon.isNotEmpty && !telefonGizli;
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
                          style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: GColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: GColors.textSecondary)),
                      if (puanSayisi > 0) ...[
                        const SizedBox(height: 12),
                        DegerlendirmeWidget(kullaniciId: user.uid),
                      ],
                      // Hakkımda
                      if ((data['notlar'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            data['notlar'].toString(),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
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
                                  style: GoogleFonts.roboto(
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
                                  style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: GColors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ProfilDuzenleButonu(
                          userId: user.uid, data: data),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: GColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('İlanlarım',
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: GColors.textPrimary)),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('ilanlar')
                            .where('kullaniciId', isEqualTo: user.uid)
                            .orderBy('olusturmaTarihi', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text('Henüz ilan vermediniz.',
                                    style: GoogleFonts.roboto(
                                        color: GColors.textSecondary,
                                        fontSize: 14)),
                              ),
                            );
                          }
                          return Column(
                            children: docs.map((doc) {
                              final d =
                                  doc.data() as Map<String, dynamic>;
                              final aktif = d['aktif'] != false;
                              final tip = d['tip'] ?? 'istek';

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                // YENİ: tıklayınca detay açılır
                                onTap: () => _ilanDetayGoster(
                                    context, doc.id, d),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (d['resimUrl'] != null && (d['resimUrl'] as String).isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: d['resimUrl'] as String,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                              width: 48, height: 48,
                                              color: GColors.surface,
                                              child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: GColors.divider))),
                                          errorWidget: (_, __, ___) => _ilanLeadingEmoji(tip, aktif),
                                        )
                                      : _ilanLeadingEmoji(tip, aktif),
                                ),
                                title: Text(
                                  tip == 'tasiyici'
                                      ? '${d['nereden']} → ${d['nereye']}'
                                      : d['urun'] ?? '',
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: aktif
                                          ? GColors.textPrimary
                                          : GColors.textSecondary),
                                ),
                                subtitle: Text(
                                  aktif ? 'Aktif' : 'Pasif',
                                  style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: aktif
                                          ? const Color(0xFF2E7D32)
                                          : GColors.textHint),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: GColors.textSecondary,
                                      size: 20),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  onSelected: (value) async {
                                    if (value == 'duzenle') {
                                      _ilanDuzenle(context, doc.id, d);
                                    } else if (value == 'pasif') {
                                      await FirebaseFirestore.instance
                                          .collection('ilanlar')
                                          .doc(doc.id)
                                          .update({'aktif': !aktif});
                                    } else if (value == 'sil') {
                                      final onay = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          title: Text('İlanı Sil',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600)),
                                          content: Text(
                                              'Bu ilanı silmek istediğinize emin misiniz?',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  color: GColors.textSecondary)),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: Text('İptal',
                                                  style: GoogleFonts.roboto(
                                                      color: GColors.textSecondary)),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: Text('Sil',
                                                  style: GoogleFonts.roboto(
                                                      color: GColors.red,
                                                      fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (onay == true) {
                                        await FirebaseFirestore.instance
                                            .collection('ilanlar')
                                            .doc(doc.id)
                                            .delete();
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'duzenle',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit_outlined,
                                              size: 18,
                                              color: GColors.textPrimary),
                                          const SizedBox(width: 10),
                                          Text('Düzenle',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'pasif',
                                      child: Row(
                                        children: [
                                          Icon(
                                            aktif
                                                ? Icons.pause_circle_outline
                                                : Icons.play_circle_outline,
                                            size: 18,
                                            color: GColors.textPrimary,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            aktif ? 'Pasife Al' : 'Aktife Al',
                                            style: GoogleFonts.roboto(
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'sil',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_outline,
                                              size: 18, color: GColors.red),
                                          const SizedBox(width: 10),
                                          Text('Sil',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  color: GColors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _BekleyenDegerlendirmeler(userId: user.uid),
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

// ── Profil Düzenle Butonu ─────────────────────────────────

class _ProfilDuzenleButonu extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;
  const _ProfilDuzenleButonu(
      {required this.userId, required this.data});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _profilDuzenleGoster(context),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text('Profili Düzenle',
          style: GoogleFonts.roboto(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: GColors.primary,
        side: const BorderSide(color: GColors.divider),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  void _profilDuzenleGoster(BuildContext context) {
    final adCtrl = TextEditingController(
        text: data['adSoyad']?.toString() ?? '');
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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
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
                  style: GoogleFonts.roboto(
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
                      style: GoogleFonts.roboto(
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

// ── Bekleyen Değerlendirmeler ─────────────────────────────

class _BekleyenDegerlendirmeler extends StatelessWidget {
  final String userId;
  const _BekleyenDegerlendirmeler({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sohbetler')
          .where('kullanicilar', arrayContains: userId)
          .where('siparisAsamasi', isEqualTo: 3)
          .where('degerlendirmeYapildi', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Container(
          color: GColors.white,
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB300), size: 18),
                    const SizedBox(width: 6),
                    Text('Bekleyen Değerlendirmeler',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: GColors.textPrimary)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${docs.length}',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final kullanicilar =
                    List<String>.from(data['kullanicilar'] ?? []);
                final karsiId =
                    kullanicilar.firstWhere((id) => id != userId,
                        orElse: () => '');
                final adlar = data['kullaniciAdlari'] as Map? ?? {};
                final karsiAd = adlar[karsiId]?.toString() ?? 'Kullanıcı';
                final ilanBaslik =
                    data['ilanBaslik']?.toString() ?? '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: avatarWidget(isim: karsiAd, radius: 20),
                  title: Text(karsiAd,
                      style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GColors.textPrimary)),
                  subtitle: ilanBaslik.isNotEmpty
                      ? Text(ilanBaslik,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: GColors.textSecondary))
                      : null,
                  trailing: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DegerlendirmeScreen(
                          hedefKullaniciId: karsiId,
                          hedefKullaniciAd: karsiAd,
                          sohbetId: doc.id,
                          ilanBaslik: ilanBaslik,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Değerlendir',
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SohbetScreen(
                        karsiKullaniciId: karsiId,
                        karsiKullaniciAd: karsiAd,
                        ilanId: data['ilanId']?.toString() ?? '',
                        ilanBaslik: ilanBaslik,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

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
                style: GoogleFonts.roboto(
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
                            style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < puan
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 13,
                                  color: const Color(0xFFFFB300),
                                )),
                      ],
                    ),
                    subtitle: yorum.isNotEmpty
                        ? Text(yorum,
                            style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: GColors.textSecondary))
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















Widget _ilanLeadingEmoji(String tip, bool aktif) {
  return Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      color: aktif ? GColors.chipBg : GColors.divider,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Text(
        tip == 'tasiyici' ? '✈️' : '🛍️',
        style: const TextStyle(fontSize: 20),
      ),
    ),
  );
}