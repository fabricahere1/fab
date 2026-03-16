import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'g_colors.dart';
import 'sohbet_screen.dart';
import '../auth_gate.dart';
 
class MesajlarPage extends StatelessWidget {
  const MesajlarPage({super.key});
 
  String _zamanYazi(dynamic zaman) {
    if (zaman == null) return '';
    final dt = (zaman as Timestamp).toDate();
    final simdi = DateTime.now();
    final fark = simdi.difference(dt);
    if (fark.inMinutes < 1) return 'Şimdi';
    if (fark.inMinutes < 60) return '${fark.inMinutes}dk';
    if (fark.inHours < 24)
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (fark.inDays == 1) return 'Dün';
    if (fark.inDays < 7) {
      const gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return gunler[dt.weekday - 1];
    }
    return '${dt.day}.${dt.month}';
  }
 
  Future<void> _menuGoster(
    BuildContext context,
    String sohbetId,
    String karsiAd,
    bool sabitlenmis,
    String uid,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: GColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: avatarRenk(karsiAd),
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text(karsiAd[0].toUpperCase(),
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(karsiAd,
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: GColors.textPrimary)),
                ],
              ),
            ),
            const Divider(color: GColors.divider),
            // Sabitle / Sabitlemeyi kaldır
            ListTile(
              leading: Icon(
                sabitlenmis ? Icons.push_pin_outlined : Icons.push_pin,
                color: sabitlenmis ? GColors.textSecondary : GColors.textPrimary,
              ),
              title: Text(
                sabitlenmis ? 'Sabitlemeyi Kaldır' : 'Sohbeti Sabitle',
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: sabitlenmis
                        ? GColors.textSecondary
                        : GColors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final sabitlenmisMap =
                    <String, dynamic>{uid: !sabitlenmis};
                await FirebaseFirestore.instance
                    .collection('sohbetler')
                    .doc(sohbetId)
                    .update({'sabitlenmis': sabitlenmisMap});
              },
            ),
            // Sil
            ListTile(
              leading: const Icon(Icons.delete_outline, color: GColors.red),
              title: Text('Sohbeti Sil',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: GColors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final onay = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text('Sohbeti Sil',
                        style: GoogleFonts.dmSans(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    content: Text(
                        '$karsiAd ile olan sohbet listeden kaldırılacak.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: GColors.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: Text('İptal',
                            style: GoogleFonts.dmSans(
                                color: GColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(d, true),
                        child: Text('Sil',
                            style: GoogleFonts.dmSans(
                                color: GColors.red,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
                if (onay == true) {
                  await FirebaseFirestore.instance
                      .collection('sohbetler')
                      .doc(sohbetId)
                      .update({'gizli': {uid: true}});
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
 
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Text('Mesajlar',
            style: GoogleFonts.dmSans(
                color: GColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
      ),
      body: user == null
          ? GirisGerekli(
              icon: Icons.chat_bubble_outline,
              mesaj: 'Mesajları görmek için giriş yapın.',
              onGirisYap: () => loginGerekli(context),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sohbetler')
                  .where('kullanicilar', arrayContains: user.uid)
                  .orderBy('sonMesajZamani', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: GColors.red, strokeWidth: 2));
                }
 
                final tumDocs = snapshot.data?.docs ?? [];
 
                // Gizli sohbetleri filtrele
                final gorunenDocs = tumDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final gizli =
                      (data['gizli'] as Map<String, dynamic>?) ?? {};
                  return gizli[user.uid] != true;
                }).toList();
 
                // Sabitlenenler üste
                gorunenDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aSabit = ((aData['sabitlenmis']
                          as Map<String, dynamic>?)?[user.uid]) ==
                      true;
                  final bSabit = ((bData['sabitlenmis']
                          as Map<String, dynamic>?)?[user.uid]) ==
                      true;
                  if (aSabit && !bSabit) return -1;
                  if (!aSabit && bSabit) return 1;
                  return 0;
                });
 
                if (gorunenDocs.isEmpty) {
                  return const BosEkran(
                    icon: Icons.chat_bubble_outline,
                    mesaj: 'Henüz mesajınız yok.',
                    altMesaj:
                        'İlanlara tıklayarak iletişime geçebilirsiniz.',
                    renk: GColors.blue,
                  );
                }
 
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: gorunenDocs.length,
                  itemBuilder: (context, index) {
                    final doc = gorunenDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final kullaniciAdlari = data['kullaniciAdlari']
                            as Map<String, dynamic>? ??
                        {};
                    final kullanicilar =
                        List<String>.from(data['kullanicilar'] ?? []);
                    final karsiId = kullanicilar.firstWhere(
                      (id) => id != user.uid,
                      orElse: () => '',
                    );
                    final karsiAd =
                        kullaniciAdlari[karsiId] ?? 'Kullanıcı';
                    final sonMesaj = data['sonMesaj'] ?? '';
                    final ilanBaslik = data['ilanBaslik'] ?? '';
                    final sonZaman = data['sonMesajZamani'];
                    final okunmamisSayisi =
                        ((data['okunmamis'] as Map<String, dynamic>?)?[
                                user.uid] as int?) ??
                            0;
                    final okunmamis = okunmamisSayisi > 0;
                    final sabitlenmis =
                        ((data['sabitlenmis'] as Map<String, dynamic>?)?[
                                user.uid]) ==
                            true;
 
                    // Okundu göstergesi — son mesajı ben mi gönderdim?
                    final sonGondereId =
                        data['sonGondereId'] as String? ?? '';
                    final benGonderdim = sonGondereId == user.uid;
                    final karsiOkunmamis =
                        ((data['okunmamis'] as Map<String, dynamic>?)?[
                                karsiId] as int?) ??
                            0;
                    final karsiOkudu = benGonderdim && karsiOkunmamis == 0;
 
                    return GestureDetector(
                      onLongPress: () => _menuGoster(
                          context, doc.id, karsiAd, sabitlenmis, user.uid),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SohbetScreen(
                              karsiKullaniciId: karsiId,
                              karsiKullaniciAd: karsiAd,
                              ilanId: data['ilanId'] ?? '',
                              ilanBaslik: ilanBaslik,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: sabitlenmis
                                ? const Color(0xFFFFF8F0)
                                : okunmamis
                                    ? Colors.white
                                    : const Color(0xFFFAFAFA),
                            border: const Border(
                              bottom: BorderSide(
                                  color: Color(0xFFF0F0F0), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                        color: avatarRenk(karsiAd),
                                        shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        karsiAd[0].toUpperCase(),
                                        style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                    ),
                                  ),
                                  if (sabitlenmis)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                            color: GColors.red,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.push_pin,
                                            color: Colors.white, size: 10),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // İçerik
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (ilanBaslik.isNotEmpty)
                                      Text(
                                        ilanBaslik.toUpperCase(),
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: GColors.red,
                                            letterSpacing: 0.8),
                                      ),
                                    const SizedBox(height: 1),
                                    Text(
                                      karsiAd,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: okunmamis
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: GColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        // ✓✓ okundu göstergesi
                                        if (benGonderdim) ...[
                                          Icon(
                                            Icons.done_all,
                                            size: 14,
                                            color: karsiOkudu
                                                ? const Color(0xFF2196F3)
                                                : GColors.textHint,
                                          ),
                                          const SizedBox(width: 3),
                                        ],
                                        Expanded(
                                          child: Text(
                                            sonMesaj.isEmpty
                                                ? 'Henüz mesaj yok'
                                                : sonMesaj,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                color: okunmamis
                                                    ? GColors.textSecondary
                                                    : const Color(
                                                        0xFFAAAAAA),
                                                fontWeight: okunmamis
                                                    ? FontWeight.w600
                                                    : FontWeight.w400),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Sağ: saat + okunmamış nokta
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _zamanYazi(sonZaman),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        color: const Color(0xFFCCCCCC)),
                                  ),
                                  if (okunmamis) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: GColors.red,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Text(
                                        okunmamisSayisi > 9
                                            ? '9+'
                                            : '$okunmamisSayisi',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ],
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