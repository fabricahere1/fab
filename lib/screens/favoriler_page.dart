import 'g_colors.dart';
import 'profil_karti_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'sohbet_screen.dart';
import 'degerlendirme_screen.dart';
import '../auth_gate.dart';
 
class FavorilerPage extends StatelessWidget {
  const FavorilerPage({super.key});
 
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
 
    return Scaffold(
      backgroundColor: GColors.surface,
      appBar: AppBar(
        backgroundColor: GColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GColors.divider,
        title: Text('Favoriler',
            style: GoogleFonts.dmSans(
                color: GColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),
      body: user == null
          ? GirisGerekli(
              icon: Icons.bookmark_outline,
              mesaj: 'Favorileri görmek için giriş yapın.',
              onGirisYap: () => loginGerekli(context),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('favoriler')
                  .where('kullaniciId', isEqualTo: user.uid)
                  .orderBy('eklemeTarihi', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: GColors.red, strokeWidth: 2));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const BosEkran(
                    icon: Icons.bookmark_outline,
                    mesaj: 'Henüz favori eklemediniz.',
                    altMesaj: 'İlanlarda 🔖 simgesine tıklayarak ekleyin.',
                    renk: GColors.blue,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tip = data['tip'] ?? 'istek';
                    final isim = data['kullaniciAd'] ?? 'Kullanıcı';
 
                    return GestureDetector(
                      onTap: () {
                        FirebaseFirestore.instance
                            .collection('ilanlar')
                            .doc(data['ilanId'])
                            .get()
                            .then((ilanDoc) {
                          if (!context.mounted) return;
                          if (ilanDoc.exists) {
                            _ilanDetayGoster(
                              context,
                              ilanDoc.id,
                              ilanDoc.data() as Map<String, dynamic>,
                              tip: tip,
                              favoriDocId: doc.id,
                            );
                          } else {
                            _silinmisIlanGoster(context, doc.id, data);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: GColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GColors.divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: (data['resimUrl'] != null &&
                                        (data['resimUrl'] as String).isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: data['resimUrl'] as String,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        fadeInDuration: Duration.zero,
                                        placeholder: (_, __) =>
                                            _avatarKutu(isim, 48),
                                        errorWidget: (_, __, ___) =>
                                            _avatarKutu(isim, 48),
                                      )
                                    : _avatarKutu(isim, 48),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(isim,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.dmSans(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: GColors.textPrimary)),
                                        ),
                                        GChip(
                                          label: tip == 'tasiyici'
                                              ? '✈️ Gelen'
                                              : '🛍️ İstek',
                                          icon: tip == 'tasiyici'
                                              ? Icons.flight
                                              : Icons.shopping_bag_outlined,
                                          bgColor: GColors.chipBg,
                                          textColor: GColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 12,
                                            color: GColors.textSecondary),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            '${data['nereden'] ?? ''} → ${data['nereye'] ?? ''}',
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                                color: GColors.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tip == 'istek' &&
                                        data['urun'] != null &&
                                        data['urun'] != '') ...[
                                      const SizedBox(height: 3),
                                      Text(data['urun'],
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: GColors.textPrimary)),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final onay = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      title: Text('Favoriden Kaldır',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                      content: Text(
                                          'Bu ilanı favorilerden kaldırmak istiyor musunuz?',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              color: GColors.textSecondary)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text('İptal',
                                              style: GoogleFonts.dmSans(
                                                  color:
                                                      GColors.textSecondary)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text('Kaldır',
                                              style: GoogleFonts.dmSans(
                                                  color: GColors.red,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (onay == true) {
                                    await FirebaseFirestore.instance
                                        .collection('favoriler')
                                        .doc(doc.id)
                                        .delete();
                                  }
                                },
                                child: const Icon(Icons.bookmark,
                                    color: GColors.yellow, size: 22),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
 
// ── Avatar kutu ───────────────────────────────────────────
 
Widget _avatarKutu(String isim, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: avatarRenk(isim),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Text(
        isim[0].toUpperCase(),
        style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.33),
      ),
    ),
  );
}
 
// ── Silinmiş ilan sheet'i ─────────────────────────────────
 
void _silinmisIlanGoster(
    BuildContext context, String favoriDocId, Map<String, dynamic> data) {
  final tip = data['tip'] ?? 'istek';
  final isim = data['kullaniciAd'] ?? 'Kullanıcı';
  final urun = data['urun'] ?? '';
  final nereden = data['nereden'] ?? '';
  final nereye = data['nereye'] ?? '';
 
  showModalBottomSheet(
    context: context,
    backgroundColor: GColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 28),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                tip == 'tasiyici' ? '✈️' : '🛍️',
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu ilan kaldırıldı',
            style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: GColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            urun.isNotEmpty ? urun : '$nereden → $nereye',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: GColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            isim,
            style: GoogleFonts.dmSans(
                fontSize: 12, color: GColors.textHint),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('favoriler')
                    .doc(favoriDocId)
                    .delete();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GColors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('Favorilerden Kaldır',
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat',
                style: GoogleFonts.dmSans(
                    color: GColors.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    ),
  );
}
 
// ── İlan Detay Sheet ──────────────────────────────────────
 
void _ilanDetayGoster(
  BuildContext context,
  String docId,
  Map<String, dynamic> data, {
  required String tip,
  required String favoriDocId,
}) {
  final resimUrl = data['resimUrl'] as String?;
  final resimVar = resimUrl != null && resimUrl.isNotEmpty;
  final isim = data['kullaniciAd'] ?? 'Kullanıcı';
  final kullaniciId = data['kullaniciId'] ?? '';
  final urun = data['urun'] ?? '';
  final nereden = data['nereden'] ?? '';
  final nereye = data['nereye'] ?? '';
  final ucret = data['ucret'] ?? '';
  final notlar = data['notlar'] ?? '';
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  final benimIlanim = currentUid != null && currentUid == kullaniciId;
 
  showModalBottomSheet(
    context: context,
    backgroundColor: GColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (resimVar)
                    CachedNetworkImage(
                      imageUrl: resimUrl,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      placeholder: (_, __) =>
                          Container(height: 240, color: GColors.surface),
                      errorWidget: (_, __, ___) =>
                          Container(height: 240, color: GColors.surface),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 14),
                        if (urun.isNotEmpty)
                          Text(urun,
                              style: GoogleFonts.dmSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: GColors.textPrimary)),
                        const SizedBox(height: 12),
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
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
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
                          const SizedBox(height: 16),
                          Text('₺$ucret',
                              style: GoogleFonts.dmSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: GColors.red)),
                        ],
                        Builder(builder: (context) {
                          final t = data['olusturmaTarihi'];
                          if (t == null) return const SizedBox.shrink();
                          final dt = (t as Timestamp).toDate();
                          final str = '${dt.day}.${dt.month}.${dt.year}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 13, color: GColors.textSecondary),
                                const SizedBox(width: 5),
                                Text('$str tarihinde eklendi',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: GColors.textSecondary)),
                              ],
                            ),
                          );
                        }),
                        if (notlar.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(notlar,
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: GColors.textSecondary,
                                  height: 1.5)),
                        ],
                        const SizedBox(height: 20),
                        // Kullanıcı satırı
                        Row(
                          children: [
                            avatarWidget(isim: isim, radius: 18, fontSize: 13),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(isim,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: GColors.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!benimIlanim)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('favoriler')
                              .doc(favoriDocId)
                              .delete();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: GColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GColors.divider),
                          ),
                          child: const Icon(Icons.bookmark,
                              color: GColors.yellow, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              Navigator.pop(context);
                              loginGerekli(context);
                              return;
                            }
                            await profilKartiGoster(
                              context,
                              kullaniciId: kullaniciId,
                              isim: isim,
                              docId: docId,
                              ilanTip: tip,
                              urun: urun,
                              nereden: nereden,
                              nereye: nereye,
                            );
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                tip == 'istek'
                                    ? '✈️  Ben Getiririm'
                                    : '💬  İletişime Geç',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        sikayetGonder(context,
                            hedefId: kullaniciId,
                            hedefAd: isim,
                            ilanId: docId);
                      },
                      icon: const Icon(Icons.flag_outlined,
                          color: GColors.textHint, size: 15),
                      label: Text('Şikayet Et',
                          style: GoogleFonts.dmSans(
                              color: GColors.textHint, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}