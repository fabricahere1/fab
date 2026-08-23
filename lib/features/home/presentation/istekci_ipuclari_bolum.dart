// lib/features/home/presentation/istekci_ipuclari_bolum.dart
//
// Taşıyıcı ipuçları bölümüyle (tasiyici_ipuclari_bolum.dart) AYNI görsel
// dili kullanır — aynı renkler/fontlar, aynı genişleyip-daralan kart
// deseni. Tek fark: taşıyıcı bölümü çok kategorili (tab'lı) ve her
// kartın içinde birden fazla rozetli alt satır varken, burada 11 madde
// düz bir liste — her biri kendi başlığı+açıklamasıyla TEK bir
// genişleyen kart. Bu yüzden tab bar ve rozet (badge) YOK; ihtiyaç
// olmayan karmaşıklığı tekrar etmiyoruz.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';

// ── Veri modeli ───────────────────────────────────────────────────────────────

class _Madde {
  final String baslik;
  final String aciklama;
  final IconData ikon;
  const _Madde(this.baslik, this.aciklama, this.ikon);
}

// ── Veriler ───────────────────────────────────────────────────────────────────

const _maddeler = [
  _Madde(
    'Net ve Detaylı İstek Yaz',
    'Ürünün tam modelini, rengini, bedenini belirt — mümkünse bir görsel/link ekle. Belirsiz istekler, yanlış ürün gelmesine yol açabilir.',
    Icons.checklist_outlined,
  ),
  _Madde(
    'Gerçekçi Bütçe Belirle',
    'Ürünün yurt dışındaki fiyatını araştır, taşıyıcının emeği için makul bir ek ücret öngör — çok düşük teklifler kimseyi ilgilendirmeyebilir.',
    Icons.savings_outlined,
  ),
  _Madde(
    'Gümrük/İthalat Kurallarını Bil',
    'Bazı ürünlerin kişisel eşya limitleri veya yasakları olabilir — istemeden önce ürünün Türkiye\'ye getirilmesinin serbest olduğundan emin ol.',
    Icons.gavel,
  ),
  _Madde(
    'Profil ve Değerlendirmelere Bak',
    'Taşıyıcının geçmiş değerlendirmelerini incele — yeni bir kullanıcıysa, küçük bir istekle başlamak daha güvenli olabilir.',
    Icons.how_to_reg_outlined,
  ),
  _Madde(
    'Ödemeyi Güvenli Yap',
    'Tüm ücreti önceden göndermek yerine, mümkünse teslimat anında ya da kısmi ödeme gibi güvenli yöntemler tercih et.',
    Icons.payments_outlined,
  ),
  _Madde(
    'Buluşmayı Güvenli Bir Yerde Planla',
    'Teslimat için kalabalık, halka açık bir yer seç — kişisel bilgilerini gereğinden fazla paylaşma.',
    Icons.verified_user_outlined,
  ),
  _Madde(
    'Kargo ile Gönderiliyorsa, Şubeden Teslim Alma Seçeneğini de Değerlendirebilirsin',
    'Güvenliğin ön planda tutmak istiyorsan, ev adresini paylaşmak yerine ürünün en yakın kargo şubesine gönderilmesini isteyebilirsin — bu, kişisel bilgilerini korurken teslimatı yine de sorunsuz tamamlamanı sağlar.',
    Icons.inventory_2_outlined,
  ),
  _Madde(
    'Esnek Ol, Seyahat Planları Değişebilir',
    'Taşıyıcının uçuş/seyahat tarihleri bazen kayabilir — sabırlı iletişim, ilişkiyi kolaylaştırır.',
    Icons.flight_outlined,
  ),
  _Madde(
    'Hızlı ve Net Yanıt Ver',
    'Taşıyıcı sorularına (ölçü, renk onayı gibi) hızlı cevap vermek, işlemin sorunsuz ilerlemesini sağlar.',
    Icons.chat_bubble_outline,
  ),
  _Madde(
    'Teslim Alırken Kontrol Et',
    'Ürünü teslim alırken hasar/uyumsuzluk var mı kontrol et — sorun varsa hemen belirt.',
    Icons.warning_amber_outlined,
  ),
  _Madde(
    'Dürüst Değerlendirme Bırak',
    'İşlem bittikten sonra gerçek deneyimini paylaş — bu, gelecekteki istekçilere yardımcı olur.',
    Icons.rate_review_outlined,
  ),
];

// ── Ana widget ────────────────────────────────────────────────────────────────

class IstekciIpuclariBolum extends StatelessWidget {
  const IstekciIpuclariBolum({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(children: [
            const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.red),
            const SizedBox(width: 6),
            Text('İstekçi ipuçları',
                style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ]),
        ),

        // İçerik
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _maddeler.map((m) => _IstekciIpucuKarti(madde: m)).toList(),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── İpucu kartı ───────────────────────────────────────────────────────────────

class _IstekciIpucuKarti extends StatefulWidget {
  final _Madde madde;
  const _IstekciIpucuKarti({required this.madde});

  @override
  State<_IstekciIpucuKarti> createState() => _IstekciIpucuKartiState();
}

class _IstekciIpucuKartiState extends State<_IstekciIpucuKarti> {
  bool _acik = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _acik = !_acik),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(children: [
                Icon(widget.madde.ikon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.madde.baslik,
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                AnimatedRotation(
                  turns: _acik ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
                ),
              ]),
            ),
          ),
          if (_acik)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Text(widget.madde.aciklama,
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
            ),
        ],
      ),
    );
  }
}
