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
    if (fark.inHours < 24) return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (fark.inDays == 1) return 'Dün';
    if (fark.inDays < 7) {
      const gunler = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
      return gunler[dt.weekday - 1];
    }
    return '${dt.day}.${dt.month}';
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
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const BosEkran(
                    icon: Icons.chat_bubble_outline,
                    mesaj: 'Henüz mesajınız yok.',
                    altMesaj: 'İlanlara tıklayarak iletişime geçebilirsiniz.',
                    renk: GColors.blue,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final kullaniciAdlari =
                        data['kullaniciAdlari'] as Map<String, dynamic>? ?? {};
                    final kullanicilar =
                        List<String>.from(data['kullanicilar'] ?? []);
                    final karsiId = kullanicilar.firstWhere(
                      (id) => id != user.uid,
                      orElse: () => '',
                    );
                    final karsiAd = kullaniciAdlari[karsiId] ?? 'Kullanıcı';
                    final sonMesaj = data['sonMesaj'] ?? '';
                    final ilanBaslik = data['ilanBaslik'] ?? '';
                    final sonZaman = data['sonMesajZamani'];
                    final okunmamisSayisi =
                        ((data['okunmamis'] as Map<String, dynamic>?)?[
                                user.uid] as int?) ??
                            0;
                    final okunmamis = okunmamisSayisi > 0;

                    return InkWell(
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
                          color: okunmamis
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
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: avatarRenk(karsiAd),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  karsiAd[0].toUpperCase(),
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // İçerik
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // İlan başlık — caps küçük
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
                                  // İsim
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
                                  // Son mesaj
                                  Text(
                                    sonMesaj.isEmpty
                                        ? 'Henüz mesaj yok'
                                        : sonMesaj,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: okunmamis
                                            ? GColors.textSecondary
                                            : const Color(0xFFAAAAAA),
                                        fontWeight: okunmamis
                                            ? FontWeight.w600
                                            : FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sağ: saat + nokta
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
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                        color: GColors.red,
                                        shape: BoxShape.circle),
                                  ),
                                ],
                              ],
                            ),
                          ],
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