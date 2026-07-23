import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';

class KullanimKosullariScreen extends StatelessWidget {
  const KullanimKosullariScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Kullanım Koşulları',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İste Uygulaması Kullanım Koşulları',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Son güncelleme: Temmuz 2026',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ..._bolumler.map((b) => _Bolum(baslik: b.baslik, icerik: b.icerik)),
          ],
        ),
      ),
    );
  }
}

class _Bolum extends StatelessWidget {
  final String baslik;
  final String icerik;
  const _Bolum({required this.baslik, required this.icerik});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            icerik,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.85,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

const _bolumler = [
  (
    baslik: '1. Genel Bilgiler',
    icerik:
        'Bu kullanım koşulları, İste mobil uygulamasını ("Uygulama") kullanan kişiler ("Kullanıcı") ile uygulama geliştiricisi arasındaki ilişkiyi düzenler. Uygulamayı kullanmaya başlayarak bu koşullar okunmuş ve kabul edilmiş sayılır.',
  ),
  (
    baslik: '2. Yaş Sınırı',
    icerik:
        'Uygulamayı kullanabilmek için 18 yaşını doldurmuş olmanız '
        'gerekmektedir. 18 yaşından küçük kullanıcıların uygulamayı '
        'kullanması yasaktır. İste, kullanıcıların beyan ettiği yaş '
        'bilgisine güvenir; yanlış beyan durumunda oluşabilecek '
        'sonuçlardan kullanıcı sorumludur.',
  ),
  (
    baslik: '3. Hizmetin Kapsamı',
    icerik:
        'İste, uluslararası seyahat eden kişiler (taşıyıcılar) ile yurt dışından ürün taşıtmak isteyen kişileri (istek sahipleri) bir araya getiren bir platformdur. İste; taraflar arasındaki iletişimi kolaylaştırır ancak taraflar arasında gerçekleşen hiçbir anlaşmanın, ödemenin veya teslimatın tarafı değildir.',
  ),
  (
    baslik: '4. Kullanıcı Sorumlulukları',
    icerik:
        'Kullanıcıların aşağıdaki kurallara uyması zorunludur:\n\n• Gerçek ve doğru bilgi vermek\n• Başkasına ait kimlik veya iletişim bilgisi kullanmamak\n• Yasadışı, tehlikeli veya gümrük kurallarını ihlal eden ürünlerin taşınmasını talep etmemek veya kabul etmemek\n• Diğer kullanıcılara karşı saygılı davranmak\n• Uygulamayı yalnızca meşru amaçlar için kullanmak',
  ),
  (
    baslik: '5. İste\'nin Sorumluluk Sınırları',
    icerik:
        '• İste, kullanıcılar arasında gerçekleşen anlaşmaların, ödemelerin veya teslimatların sorumluluğunu üstlenmez.\n• Taraflar arasında yaşanan anlaşmazlıklarda İste\'nin müdahale yetkisi sınırlıdır. Anlaşmazlık durumunda ekran görüntüleriyle birlikte destek ekibine ulaşılabilir.\n• Kullanıcıların birbirlerine verdikleri zararlardan İste sorumlu tutulamaz.\n• Uygulama kesintisiz veya hatasız çalışacağının garantisi verilmez.',
  ),
  (
    baslik: '6. Yasaklanan Kullanımlar',
    icerik:
        'Aşağıdaki kullanımlar kesinlikle yasaktır:\n\n• Uyuşturucu, silah veya yasadışı madde taşınmasının talep edilmesi veya kabul edilmesi\n• Sahte ilan oluşturmak veya başkalarını yanıltmak\n• Başka kullanıcıları taciz etmek veya tehdit etmek\n• Uygulamayı otomatik araçlarla (bot vb.) kullanmak\n• Güvenlik sistemlerini aşmaya çalışmak\n\nBu kurallara aykırı davranan hesaplar önceden bildirilmeksizin askıya alınabilir veya silinebilir.',
  ),
  (
    baslik: '7. Hesap Askıya Alma ve Silme',
    icerik:
        'İste, kurallara aykırı davranan kullanıcıların hesabını önceden bildirmeksizin askıya alma veya silme hakkını saklı tutar. Kullanıcılar, Profil > Ayarlar > Hesabı Sil bölümünden hesaplarını istedikleri zaman kalıcı olarak silebilir.',
  ),
  (
    baslik: '8. Fikri Mülkiyet',
    icerik:
        'Uygulamaya ait logo, tasarım, kod ve içerikler İste\'ye aittir. İzinsiz kopyalanamaz, dağıtılamaz veya değiştirilemez.',
  ),
  (
    baslik: '9. Değişiklikler',
    icerik:
        'İste, bu kullanım koşullarını önceden haber vermeksizin güncelleme hakkını saklı tutar. Önemli değişikliklerde kullanıcılar bilgilendirilmeye çalışılır. Güncel koşullar uygulama içinden her zaman erişilebilir olacaktır. Uygulamayı kullanmaya devam etmek, güncel koşulların kabul edildiği anlamına gelir.',
  ),
  (
    baslik: '10. İletişim',
    icerik:
        'Soru ve şikayetler için Ayarlar > Bize Ulaşın bölümünden destek ekibine ulaşılabilir.',
  ),
];
