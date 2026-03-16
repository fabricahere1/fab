import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'g_colors.dart';
import 'sohbet_screen.dart';
import 'kullanici_profil_screen.dart';
 
// ── Profil Cache (TTL: 5 dakika) ─────────────────────────
 
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime fetchedAt;
  _CacheEntry(this.data) : fetchedAt = DateTime.now();
  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 5);
}
 
final Map<String, _CacheEntry> _profilCache = {};
 
void clearProfilCache() => _profilCache.clear();
 
// ── Ana Fonksiyon ─────────────────────────────────────────
 
Future<void> profilKartiGoster(
  BuildContext context, {
  required String kullaniciId,
  required String isim,
  required String docId,
  required String ilanTip,
  required String urun,
  required String nereden,
  required String nereye,
}) async {
  if (!_profilCache.containsKey(kullaniciId) ||
      _profilCache[kullaniciId]!.isExpired) {
    final snap = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(kullaniciId)
        .get();
    _profilCache[kullaniciId] = _CacheEntry(snap.data() ?? {});
  }
 
  if (!context.mounted) return;
 
  final profilData = _profilCache[kullaniciId]!.data;
  final telefon = profilData['telefon']?.toString().trim() ?? '';
  final email = profilData['email']?.toString().trim() ?? '';
  final fotoUrl = profilData['fotoUrl']?.toString() ?? '';
  final kullaniciTipi = profilData['kullaniciTipi']?.toString() ?? '';
  final yasadigiUlke = profilData['yasadigiUlke']?.toString().trim() ?? '';
  final bulunduguSehir = profilData['bulunduguSehir']?.toString().trim() ?? '';
  final geldigiSehirler = List<String>.from(profilData['geldigiSehirler'] ?? []);
  final hakkinda = profilData['hakkinda']?.toString().trim() ?? '';
  final ortalamaPuan = ((profilData['ortalamaPuan']) as num?)?.toDouble() ?? 0.0;
  final degerlendirmeSayisi = ((profilData['degerlendirmeSayisi']) as num?)?.toInt() ?? 0;
 
  showModalBottomSheet(
    context: context,
    backgroundColor: GColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: GColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
 
          // Avatar + isim + tip badge
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KullaniciProfilScreen(
                    kullaniciId: kullaniciId,
                    isim: isim,
                  ),
                ),
              );
            },
            child: Row(
            children: [
              avatarWidget(
                  isim: isim,
                  fotoUrl: fotoUrl.isEmpty ? null : fotoUrl,
                  radius: 28,
                  fontSize: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isim,
                        style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: GColors.textPrimary)),
                    const SizedBox(height: 4),
                    if (degerlendirmeSayisi > 0) ...[
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFFFB300)),
                          const SizedBox(width: 3),
                          Text(
                            '${ortalamaPuan.toStringAsFixed(1)}  ($degerlendirmeSayisi değerlendirme)',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: GColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (kullaniciTipi.isNotEmpty)
                      KullaniciTipiBadge(tip: kullaniciTipi),
                    const SizedBox(height: 4),
                    Text('Tam profili gör →',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: GColors.red)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: GColors.red, size: 18),
            ],
          ),
          ),
 
          const SizedBox(height: 16),
          Divider(color: GColors.divider),
          const SizedBox(height: 12),
 
          // Taşıyıcı bilgileri
          if (kullaniciTipi == 'tasiyici' || kullaniciTipi == 'her_ikisi') ...[
            if (yasadigiUlke.isNotEmpty)
              ProfilSatir(
                  icon: Icons.public_outlined,
                  etiket: 'Yaşadığı ülke',
                  deger: yasadigiUlke),
            if (geldigiSehirler.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: GColors.surface,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.flight_land_outlined,
                        size: 18, color: GColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Geldiği şehirler',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: GColors.textSecondary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: geldigiSehirler
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: GColors.chipBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border:
                                          Border.all(color: GColors.divider),
                                    ),
                                    child: Text(s,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: GColors.textPrimary)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
          ],
 
          // İstek veren şehri
          if ((kullaniciTipi == 'istek' || kullaniciTipi == 'her_ikisi') &&
              bulunduguSehir.isNotEmpty)
            ProfilSatir(
                icon: Icons.location_on_outlined,
                etiket: 'Bulunduğu şehir',
                deger: bulunduguSehir),
 
          // Hakkında
          if (hakkinda.isNotEmpty) ...[
            const SizedBox(height: 10),
            ProfilSatir(
                icon: Icons.info_outline, etiket: 'Hakkında', deger: hakkinda),
          ],
 
          // Telefon
          if (telefon.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: telefon);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Arama başlatılamadı.')));
                  }
                }
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: telefon));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Telefon numarası kopyalandı.')));
              },
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: GColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child:
                        Icon(Icons.phone_outlined, size: 18, color: GColors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Telefon (Aramak için tıkla)',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: GColors.textSecondary)),
                        Text(telefon,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: GColors.red)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: GColors.red, size: 18),
                ],
              ),
            ),
          ],
 
          // Email
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            ProfilSatir(
                icon: Icons.email_outlined, etiket: 'E-posta', deger: email),
          ],
 
          const SizedBox(height: 16),
 
          // Mesaj gönder butonu
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SohbetScreen(
                    karsiKullaniciId: kullaniciId,
                    karsiKullaniciAd: isim,
                    ilanId: docId,
                    ilanBaslik: urun.isNotEmpty ? urun : '$nereden → $nereye',
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text('💬  Mesaj Gönder',
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
 
// ── Paylaşılan Widget'lar ─────────────────────────────────
 
class ProfilSatir extends StatelessWidget {
  final IconData icon;
  final String etiket;
  final String deger;
 
  const ProfilSatir({
    super.key,
    required this.icon,
    required this.etiket,
    required this.deger,
  });
 
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: GColors.surface, borderRadius: BorderRadius.circular(8)),
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
 
class KullaniciTipiBadge extends StatelessWidget {
  final String tip;
  const KullaniciTipiBadge({super.key, required this.tip});
 
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
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: renk)),
    );
  }
}