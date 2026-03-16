import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'g_colors.dart';
import 'sohbet_screen.dart';
import 'degerlendirme_screen.dart';
import '../auth_gate.dart';
 
 
 
 
 
 
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
 
class KullaniciProfilScreen extends StatelessWidget {
  final String kullaniciId;
  final String isim;
 
  const KullaniciProfilScreen({
    super.key,
    required this.kullaniciId,
    required this.isim,
  });
 
  @override
  Widget build(BuildContext context) {
    final benimUid = FirebaseAuth.instance.currentUser?.uid;
    final benimProfil = benimUid == kullaniciId;
 
    return Scaffold(
      backgroundColor: GColors.surface,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(kullaniciId)
            .snapshots(),
        builder: (context, snapshot) {
          final data =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final adSoyad = data['adSoyad']?.toString() ?? isim;
          final fotoUrl = data['fotoUrl']?.toString();
          final kullaniciTipi = data['kullaniciTipi']?.toString() ?? '';
          final yasadigiUlke =
              data['yasadigiUlke']?.toString().trim() ?? '';
          final bulunduguSehir =
              data['bulunduguSehir']?.toString().trim() ?? '';
          final geldigiSehirler =
              List<String>.from(data['geldigiSehirler'] ?? []);
          final hakkinda = data['hakkinda']?.toString().trim() ?? '';
          final telefon = data['telefon']?.toString().trim() ?? '';
          final ortalamaPuan =
              ((data['ortalamaPuan']) as num?)?.toDouble() ?? 0.0;
          final degerlendirmeSayisi =
              ((data['degerlendirmeSayisi']) as num?)?.toInt() ?? 0;
 
          return CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: GColors.white,
                foregroundColor: GColors.textPrimary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          GColors.red.withValues(alpha: 0.08),
                          GColors.white,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        avatarWidget(
                          isim: adSoyad,
                          fotoUrl: fotoUrl,
                          radius: 44,
                          fontSize: 30,
                        ),
                        const SizedBox(height: 12),
                        Text(adSoyad,
                            style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: GColors.textPrimary)),
                        if (kullaniciTipi.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _TipBadge(tip: kullaniciTipi),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
 
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Puan ──────────────────────────────
                    if (degerlendirmeSayisi > 0) ...[
                      Container(
                        color: GColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFB300), size: 22),
                            const SizedBox(width: 6),
                            Text(
                              ortalamaPuan.toStringAsFixed(1),
                              style: GoogleFonts.dmSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: GColors.textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($degerlendirmeSayisi değerlendirme)',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: GColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: GColors.divider),
                    ],
 
                    // ── Hakkında ──────────────────────────
                    if (hakkinda.isNotEmpty) ...[
                      _BilgiBolum(
                        baslik: 'Hakkında',
                        child: Text(hakkinda,
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: GColors.textSecondary,
                                height: 1.5)),
                      ),
                    ],
 
                    // ── Konum bilgileri ───────────────────
                    if (yasadigiUlke.isNotEmpty ||
                        bulunduguSehir.isNotEmpty ||
                        geldigiSehirler.isNotEmpty) ...[
                      _BilgiBolum(
                        baslik: 'Konum',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (yasadigiUlke.isNotEmpty)
                              _BilgiSatir(
                                icon: Icons.public_outlined,
                                etiket: 'Yaşadığı ülke',
                                deger: yasadigiUlke,
                              ),
                            if (bulunduguSehir.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _BilgiSatir(
                                icon: Icons.location_on_outlined,
                                etiket: 'Bulunduğu şehir',
                                deger: bulunduguSehir,
                              ),
                            ],
                            if (geldigiSehirler.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                        color: GColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    child: Icon(
                                        Icons.flight_land_outlined,
                                        size: 18,
                                        color: GColors.textSecondary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Geldiği şehirler',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                color:
                                                    GColors.textSecondary)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: geldigiSehirler
                                              .map((s) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: GColors.chipBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color:
                                                              GColors.divider),
                                                    ),
                                                    child: Text(s,
                                                        style: GoogleFonts
                                                            .dmSans(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: GColors
                                                                    .textPrimary)),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
 
                    // ── İletişim ──────────────────────────
                    if (telefon.isNotEmpty) ...[
                      _BilgiBolum(
                        baslik: 'İletişim',
                        child: GestureDetector(
                          onTap: () async {
                            final uri = Uri(scheme: 'tel', path: telefon);
                            try {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                          onLongPress: () {
                            Clipboard.setData(
                                ClipboardData(text: telefon));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Telefon numarası kopyalandı.')),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color:
                                        GColors.red.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                child: Icon(Icons.phone_outlined,
                                    size: 18, color: GColors.red),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Telefon (Aramak için tıkla)',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: GColors.textSecondary)),
                                    Text(telefon,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: GColors.red)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: GColors.red, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
 
                    // ── Aktif İlanlar ─────────────────────
                    _AktifIlanlar(kullaniciId: kullaniciId),
 
                    // ── Değerlendirmeler ──────────────────
                    if (degerlendirmeSayisi > 0)
                      _DegerlendirmelerBolum(kullaniciId: kullaniciId),
 
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // ── Alt buton ────────────────────────────────────────
      bottomNavigationBar: benimProfil
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    // Şikayet
                    GestureDetector(
                      onTap: () {
                        sikayetGonder(
                          context,
                          hedefId: kullaniciId,
                          hedefAd: isim,
                          ilanId: '',
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 52,
                        decoration: BoxDecoration(
                          color: GColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GColors.divider),
                        ),
                        child: Icon(Icons.flag_outlined,
                            color: GColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Mesaj gönder
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            loginGerekli(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SohbetScreen(
                                karsiKullaniciId: kullaniciId,
                                karsiKullaniciAd: isim,
                                ilanId: 'profil_$kullaniciId',
                                ilanBaslik: isim,
                              ),
                            ),
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
                              '💬  Mesaj Gönder',
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
              ),
            ),
    );
  }
}
 
// ── Aktif İlanlar ─────────────────────────────────────────
 
class _AktifIlanlar extends StatelessWidget {
  final String kullaniciId;
  const _AktifIlanlar({required this.kullaniciId});
 
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('ilanlar')
          .where('kullaniciId', isEqualTo: kullaniciId)
          .where('aktif', isEqualTo: true)
          .orderBy('olusturmaTarihi', descending: true)
          .limit(10)
          .get(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
 
        return _BilgiBolum(
          baslik: 'Aktif İlanlar',
          child: Column(
            children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final tip = d['tip'] ?? 'istek';
              final urun = d['urun'] ?? '';
              final nereden = d['nereden'] ?? '';
              final nereye = d['nereye'] ?? '';
              final ucret = d['ucret'] ?? '';
              final resimUrl = d['resimUrl'] as String?;
              final resimVar = resimUrl != null && resimUrl.isNotEmpty;
 
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: GColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GColors.divider),
                  ),
                  child: Row(
                    children: [
                      // Resim veya emoji
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10)),
                        child: resimVar
                            ? CachedNetworkImage(
                                imageUrl: resimUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                placeholder: (_, __) => Container(
                                    width: 64,
                                    height: 64,
                                    color: GColors.divider),
                                errorWidget: (_, __, ___) => _IlanEmoji(tip),
                              )
                            : _IlanEmoji(tip),
                      ),
                      // Bilgi
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tip == 'istek' && urun.isNotEmpty)
                                Text(urun,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: GColors.textPrimary)),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(nereden,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: GColors.textSecondary)),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.arrow_forward,
                                        size: 10, color: GColors.red),
                                  ),
                                  Flexible(
                                    child: Text(nereye,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: GColors.red,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              if (d['kategori'] != null)
                                Text(
                                  kategoriAdi(d['kategori']),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: GColors.textSecondary),
                                ),
                              if (ucret.isNotEmpty)
                                Text('₺$ucret',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: GColors.red)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
 
// ── Değerlendirmeler Bölümü ───────────────────────────────
 
class _DegerlendirmelerBolum extends StatelessWidget {
  final String kullaniciId;
  const _DegerlendirmelerBolum({required this.kullaniciId});
 
  @override
  Widget build(BuildContext context) {
    return _BilgiBolum(
      baslik: 'Değerlendirmeler',
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('degerlendirmeler')
            .where('hedefId', isEqualTo: kullaniciId)
            .orderBy('tarih', descending: true)
            .limit(10)
            .get(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const SizedBox.shrink();
 
          return Column(
            children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final puan = ((d['puan']) as num?)?.toInt() ?? 0;
              final yorum = d['yorum']?.toString() ?? '';
              final ad =
                  d['degerlendiriciAd']?.toString() ?? 'Kullanıcı';
 
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        avatarWidget(isim: ad, radius: 16, fontSize: 12),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ad,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: GColors.textPrimary)),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < puan
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: const Color(0xFFFFB300),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (yorum.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 42),
                        child: Text(yorum,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: GColors.textSecondary,
                                height: 1.4)),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: GColors.divider),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
 
// ── Yardımcı Widget'lar ───────────────────────────────────
 
class _BilgiBolum extends StatelessWidget {
  final String baslik;
  final Widget child;
  const _BilgiBolum({required this.baslik, required this.child});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: GColors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
 
class _BilgiSatir extends StatelessWidget {
  final IconData icon;
  final String etiket;
  final String deger;
  const _BilgiSatir(
      {required this.icon, required this.etiket, required this.deger});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: GColors.surface,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: GColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiket,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: GColors.textSecondary)),
              Text(deger,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
 
class _TipBadge extends StatelessWidget {
  final String tip;
  const _TipBadge({required this.tip});
 
  @override
  Widget build(BuildContext context) {
    final String label;
    final Color renk;
    switch (tip) {
      case 'tasiyici':
        label = '✈️  Taşıyıcı';
        renk = const Color(0xFF1565C0);
        break;
      case 'istek':
        label = '🛍️  İstek Veren';
        renk = const Color(0xFF6A1B9A);
        break;
      case 'her_ikisi':
        label = '🔄  Taşıyıcı & İstek Veren';
        renk = const Color(0xFF2E7D32);
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: renk)),
    );
  }
}
 
class _IlanEmoji extends StatelessWidget {
  final String tip;
  const _IlanEmoji(this.tip);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: GColors.chipBg,
      child: Center(
        child: Text(
          tip == 'tasiyici' ? '✈️' : '🛍️',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}