import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/constants/app_colors.dart';

class GizlilikPolitikasiScreen extends StatelessWidget {
  const GizlilikPolitikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Gizlilik Politikası',
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
              'İste Uygulaması Gizlilik Politikası',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Son güncelleme: Haziran 2025',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'İste, kullanıcıların gizliliğini ciddiye alır. Bu politika, hangi verilerin toplandığını, nasıl kullanıldığını ve nasıl korunduğunu açıklar.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.85,
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
    baslik: '1. Toplanan Veriler',
    icerik:
        'Uygulama, aşağıdaki verileri toplayabilir:\n\n'
        '• Ad, soyad ve profil fotoğrafı (Google hesabından veya kullanıcı tarafından girilmiş)\n'
        '• E-posta adresi veya telefon numarası\n'
        '• Kullanıcının oluşturduğu ilanlar ve mesajlar\n'
        '• Uygulama kullanım istatistikleri (anonim)\n'
        '• Cihaz bilgileri (işletim sistemi, uygulama sürümü)\n\n'
        'Ayrıca, size daha uygun bir deneyim sunabilmek için:\n\n'
        '• Bulunduğunuz/yaşadığınız şehir ve ülke bilgisi ile seyahat ettiğiniz şehirler\n'
        '• Giyim/beden tercihleri ve ilgi alanı kategorileriniz\n'
        '• Duty-free alışveriş tercihiniz\n'
        '• Uygulama içi takip ettiğiniz ve sizi takip eden kullanıcı bilgileri\n'
        '• Platform içi güvenilirlik skorunuz (diğer kullanıcılarla etkileşimlerinize dayalı)\n\n'
        'toplanmaktadır. Bu bilgiler yalnızca hizmet kalitesini artırmak ve size uygun eşleşmeler sunmak amacıyla kullanılır, üçüncü taraflarla paylaşılmaz.',
  ),
  (
    baslik: '2. Verilerin Kullanım Amacı',
    icerik:
        'Toplanan veriler yalnızca şu amaçlarla kullanılır:\n\n'
        '• Hesap oluşturma ve kimlik doğrulama\n'
        '• İlan eşleştirme ve mesajlaşma hizmetinin sunulması\n'
        '• Uygulama içi bildirimlerin iletilmesi\n'
        '• Kullanıcı güvenliğinin ve platform kalitesinin korunması\n\n'
        'Veriler, reklam amaçlı üçüncü taraflarla paylaşılmaz.',
  ),
  (
    baslik: '3. Verilerin Saklanması',
    icerik:
        'Kullanıcı verileri, Google Firebase altyapısı üzerinde güvenli biçimde saklanır. Firebase, endüstri standardı şifreleme ve erişim denetimi protokollerine uymaktadır. Veriler, hesap aktif olduğu sürece saklanır; hesap silindiğinde tüm kişisel veriler kalıcı olarak kaldırılır.',
  ),
  (
    baslik: '4. Üçüncü Taraf Hizmetler',
    icerik:
        'İste, aşağıdaki üçüncü taraf hizmetlerden yararlanmaktadır:\n\n'
        '• Google Firebase — veritabanı, kimlik doğrulama ve bildirim altyapısı\n'
        '• Google Sign-In — hesap girişi\n\n'
        'Bu hizmetlerin kendi gizlilik politikaları geçerlidir. İste, bu hizmetlerin veri işleme pratiklerinden sorumlu tutulamaz.',
  ),
  (
    baslik: '5. Çerezler ve İzleme',
    icerik:
        'İste mobil uygulaması çerez kullanmaz. Oturum yönetimi, Firebase Authentication tarafından güvenli token\'lar aracılığıyla sağlanır.',
  ),
  (
    baslik: '6. Kullanıcı Hakları',
    icerik:
        'Her kullanıcı aşağıdaki haklara sahiptir:\n\n'
        '• Kişisel verilerine erişim talep etme\n'
        '• Yanlış veya eksik bilgilerin düzeltilmesini isteme\n'
        '• Hesabını ve tüm verilerini kalıcı olarak silme (Profil > Ayarlar > Hesabı Sil)\n\n'
        'Bu haklardan herhangi birini kullanmak için uygulama içi destek kanalına ulaşılabilir.',
  ),
  (
    baslik: '7. Çocukların Gizliliği',
    icerik:
        'İste, 13 yaşın altındaki bireylere yönelik değildir ve bu yaş grubuna ait kişisel veri bilinçli olarak toplanmaz. Böyle bir durumun fark edilmesi halinde ilgili veriler derhal silinir.',
  ),
  (
    baslik: '8. Güvenlik',
    icerik:
        'Kullanıcı verilerini yetkisiz erişime, değiştirilmeye veya ifşa edilmeye karşı korumak için endüstri standardı güvenlik önlemleri uygulanmaktadır. Ancak internet üzerinden yapılan hiçbir veri iletiminin %100 güvenli olduğu garanti edilemez.',
  ),
  (
    baslik: '9. Politika Değişiklikleri',
    icerik:
        'Bu gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikler olduğunda kullanıcılar uygulama içinden bilgilendirilmeye çalışılır. Güncel politikaya uygulama içinden her zaman ulaşılabilir.',
  ),
  (
    baslik: '10. İletişim',
    icerik:
        'Gizlilik ile ilgili soru ve talepler için Ayarlar > Bize Ulaşın bölümünden destek ekibine ulaşılabilir.',
  ),
];
