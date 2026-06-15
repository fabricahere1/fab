import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';

class SssScreen extends StatefulWidget {
  const SssScreen({super.key});

  @override
  State<SssScreen> createState() => _SssScreenState();
}

class _SssScreenState extends State<SssScreen> {
  final _acik = <int>{};

  static const _sorular = [
    (
      soru: 'İlan nasıl veririm?',
      cevap:
          'Ana sayfadaki "+" butonuna basarak ilan oluşturabilirsin. İstek ilanı (bir şey taşıtmak istiyorsan) veya taşıyıcı ilanı (seyahat edip taşıma yapacaksan) seçeneğinden birini seç, bilgileri doldur ve gönder. İlanın kısa sürede incelenerek yayına alınır.',
    ),
    (
      soru: 'Taşıyıcı kimdir?',
      cevap:
          'Taşıyıcı, bir ülkeden diğerine seyahat eden ve bagajında yer olan kişidir. İste üzerinden ilan vererek başkalarının ürünlerini taşıyabilir, karşılığında anlaştıkları ücreti alabilir.',
    ),
    (
      soru: 'Ödeme nasıl yapılır?',
      cevap:
          'Ödeme tamamen taraflar arasında gerçekleşir. İste bu konuda aracılık yapmaz. Taşıyıcı ve gönderen kendi aralarında anlaşır.',
    ),
    (
      soru: 'İlanım neden yayınlanmadı?',
      cevap:
          'İlanlar yayına alınmadan önce içerik kontrolünden geçer. Uygunsuz ifade, yanıltıcı bilgi veya kurallara aykırı içerik tespit edilirse ilan yayınlanmaz. Bildirimi kontrol edip ilanını düzenleyerek tekrar deneyebilirsin.',
    ),
    (
      soru: 'Eşleşme nasıl çalışır?',
      cevap:
          'İstek ilanı verenler ile taşıyıcı ilanı verenler birbirinin ilanlarını görebilir. Beğendiğin ilanı bulunca mesaj göndererek iletişime geçebilirsin. Anlaşma tamamen sizin aranızda gerçekleşir.',
    ),
    (
      soru: 'Güvenli teslimat nasıl yapılır?',
      cevap:
          'Teslimat şekli taraflara bırakılmıştır. Tanımadığın biriyle işlem yapıyorsan kalabalık ve güvenli bir yerde buluşmanı, ürünü teslim almadan ödeme yapmamanı öneririz.',
    ),
    (
      soru: 'Taşıyıcının güvenilir olduğunu nasıl anlarım?',
      cevap:
          'Her kullanıcının profilinde önceki işlemlerden gelen puan ve değerlendirmeler görünür. İşlem yapmadan önce karşı tarafın profilini ve puanını incelemeni öneririz.',
    ),
    (
      soru: 'Kargo sigortası var mı?',
      cevap:
          'Hayır. İste bir sigorta hizmeti sunmamaktadır. Ürünün taşınması sürecindeki risk taraflar arasındaki anlaşmaya göre belirlenir.',
    ),
    (
      soru: 'İlanımı nasıl düzenlerim veya silerim?',
      cevap:
          'Profil > İlanlarım bölümünden aktif ilanlarını görebilir, düzenleyebilir veya silebilirsin.',
    ),
    (
      soru: 'Kaç ilan verebilirim?',
      cevap: 'Şu an için ilan sayısında bir sınır bulunmamaktadır.',
    ),
    (
      soru: 'Bildirim almıyorum, ne yapmalıyım?',
      cevap:
          'Telefon ayarlarından İste uygulamasına bildirim izninin verildiğini kontrol et. Ayarlar > Uygulama > İste > Bildirimler yolunu takip edebilirsin.',
    ),
    (
      soru: 'Hesabımı nasıl silerim?',
      cevap:
          'Profil > Ayarlar > Hesabı Sil bölümünden hesabını kalıcı olarak silebilirsin.',
    ),
    (
      soru: 'Duty free ürün nedir, nasıl çalışır?',
      cevap:
          'Duty free, gümrük vergisinden muaf tutulan alışveriş noktalarından (havalimanı gibi) alınan ürünlerdir. Taşıyıcı, seyahati sırasında duty free\'den ürün alıp taşıyabilir. Bu tercihini profilinde belirtebilirsin.',
    ),
    (
      soru: 'Anlaşmazlık durumunda ne yapmalıyım?',
      cevap:
          'İste\'nin anlaşmazlıklarda doğrudan müdahale yetkisi sınırlıdır. Sorun yaşadığın durumda ekran görüntüleriyle birlikte destek ekibimize ulaşabilirsin.',
    ),
    (
      soru: 'Uygulama hangi rotaları destekliyor?',
      cevap:
          'İste şu an Türkiye merkezli uluslararası rotalar için aktiftir. Farklı ülkeler arasında seyahat eden herkes ilan verebilir ve eşleşme arayabilir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Sık Sorulan Sorular',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: _sorular.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final acik = _acik.contains(i);
          final item = _sorular[i];
          return GestureDetector(
            onTap: () => setState(() => acik ? _acik.remove(i) : _acik.add(i)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.soru,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: acik ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down,
                              size: 20, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (acik) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),
                      Text(
                        item.cevap,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.85,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
