// lib/features/home/presentation/tasiyici_ipuclari_bolum.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:iste_v3/shared/constants/app_colors.dart';

// ── Veri modeli ───────────────────────────────────────────────────────────────

enum _BadgeTipi { yesil, kirmizi, mavi, sari }

class _Satir {
  final String baslik;
  final String aciklama;
  final String? badge;
  final _BadgeTipi? badgeTipi;
  const _Satir(this.baslik, this.aciklama, {this.badge, this.badgeTipi});
}

class _Kart {
  final String baslik;
  final IconData ikon;
  final List<_Satir> satirlar;
  const _Kart(this.baslik, this.ikon, this.satirlar);
}

class _Tab {
  final String baslik;
  final IconData ikon;
  final List<_Kart> kartlar;
  const _Tab(this.baslik, this.ikon, this.kartlar);
}

// ── Veriler ───────────────────────────────────────────────────────────────────

const _tablar = [
  _Tab('Gümrük', Symbols.gavel, [
    _Kart('Yolcu beraberinde getirme', Symbols.person_check, [
      _Satir('430 Euro muafiyet hakkı',
          '18 yaş üstü her yolcu beraberinde 430 Euro değerinde eşyayı vergisiz getirebilir. 15 yaş altı için 150 Euro.',
          badge: '2026 güncel', badgeTipi: _BadgeTipi.yesil),
      _Satir('Kargo ile gelen eşyada muafiyet YOK',
          'Şubat 2026 itibarıyla kargo/posta yoluyla gelen eşyada muafiyet sıfırlandı. Tüm kargolar normal ithalat rejimine tabi.',
          badge: 'Önemli', badgeTipi: _BadgeTipi.kirmizi),
      _Satir('430-1500 Euro arası eşya',
          'Bu aralıktaki eşyaya tek ve maktu vergi uygulanır. 1500 Euro üzeri için tam gümrük vergisi + KDV + varsa ÖTV ödenir.'),
      _Satir('Cep telefonu harcı',
          'Yolcu beraberinde getirilen cep telefonu için yaklaşık 45.000 TL harç ödenerek IMEI kaydı yaptırılması gerekir.',
          badge: 'Dikkat', badgeTipi: _BadgeTipi.sari),
    ]),
    _Kart('Yasak ve kısıtlı ürünler', Symbols.warning, [
      _Satir('Et ve süt ürünleri yasak',
          'Tarım Bakanlığı düzenlemesine göre et ve süt ürünlerinin kişisel sevkiyat olarak getirilmesi yasaktır. El konulabilir.',
          badge: 'Yasak', badgeTipi: _BadgeTipi.kirmizi),
      _Satir('Sigara — 200 adet (1 karton)',
          'Yolcu beraberinde 1 karton sigara getirilebilir. Fazlası vergiye tabi veya el koyma riski.'),
      _Satir('Alkol — 1 litre',
          'Kişisel kullanım için 1 litre alkollü içecek getirilebilir.'),
      _Satir('Orijinal faturayı sakla',
          'Gümrük memurları ürün değerini faturaya göre belirler. Pahalı ürünlerde fatura gösteremezsen beyan değeri yüksek tutulabilir.',
          badge: 'İpucu', badgeTipi: _BadgeTipi.sari),
    ]),
    _Kart('Pratik gümrük ipuçları', Symbols.lightbulb, [
      _Satir('Ambalajı aç',
          'Yeni ürünlerin orijinal kutusu açılmamışsa ticari mal sayılma riski artar. Kullanılmış görünmesi avantaj sağlar.',
          badge: 'Strateji', badgeTipi: _BadgeTipi.mavi),
      _Satir('Ürünleri dağıt',
          'Aynı üründen çok sayıda taşıma ticari görünür. Farklı valiz bölmelerine dağıtmak fark yaratır.',
          badge: 'Strateji', badgeTipi: _BadgeTipi.mavi),
      _Satir('Kıyafetleri giyin',
          'Getirdiğin kıyafetleri valiz yerine üstünde giyerek geçmek yaygın bir yöntemdir.',
          badge: 'Strateji', badgeTipi: _BadgeTipi.mavi),
    ]),
  ]),

  _Tab('Bagaj', Symbols.luggage, [
    _Kart('Havayolu bagaj hakları', Symbols.flight, [
      _Satir('THY — 20-30 kg',
          'Ekonomi sınıfı dış hat uçuşlarda genellikle 20-30 kg. Kabin bagajı max 8 kg, 55x40x23 cm.',
          badge: 'En yüksek hak', badgeTipi: _BadgeTipi.yesil),
      _Satir('Pegasus — 20-30 kg (bilete göre)',
          'Super Eko: 20 kg, Avantaj: 30 kg. Bazı ucuz biletlerde sadece kabin bagajı dahil.'),
      _Satir('SunExpress — 20-40 kg',
          'Dış hat uçuşlarında 20-40 kg arasında değişir. Sınıfa göre farklılık gösterir.'),
      _Satir('Tek parça max 32 kg',
          'Tüm havayollarında tek bir valiz 32 kg\'ı geçemez. Fazlası için en az 2 parçaya bölünmeli.',
          badge: 'Kural', badgeTipi: _BadgeTipi.kirmizi),
    ]),
    _Kart('Ekstra bagaj stratejisi', Symbols.savings, [
      _Satir('Online al, havalimanında alma',
          'Ekstra bagaj hakkını uçuştan önce online almak çok daha ucuz. Havalimanı kontuarında %50-100 fazla ücret alınır.',
          badge: 'Tasarruf', badgeTipi: _BadgeTipi.yesil),
      _Satir('Kargo vs. bagaj karşılaştır',
          'Bazen ekstra bagaj yerine ayrı kargo göndermek daha ucuz olabilir. Ağır eşyalarda hesapla.',
          badge: 'İpucu', badgeTipi: _BadgeTipi.mavi),
      _Satir('Miles&Smiles ile ekstra hak',
          'THY sadakat programı üyeleri sınıfa göre ekstra bagaj hakkı kazanır.'),
    ]),
    _Kart('Kabinde taşınamaz', Symbols.block, [
      _Satir('Sıvılar max 100 ml',
          'Kabinde her sıvı ürün 100 ml\'yi geçemez. Şeffaf plastik torbada taşınmalı.',
          badge: 'Kural', badgeTipi: _BadgeTipi.kirmizi),
      _Satir('Kesici aletler valize',
          'Makas, çakı, tıraş bıçağı gibi kesici aletler kabin bagajında yasak.',
          badge: 'Yasak', badgeTipi: _BadgeTipi.kirmizi),
      _Satir('Power bank — max 100Wh',
          '100Wh üzeri power bank valize alınamaz, kabinde taşınmalıdır.',
          badge: 'Dikkat', badgeTipi: _BadgeTipi.sari),
    ]),
  ]),

  _Tab('Paketleme', Symbols.inventory_2, [
    _Kart('Kırılabilir ürünler', Symbols.inventory_2, [
      _Satir('Kıyafet ile sar',
          'Kırılabilir ürünleri kıyafetlerin arasına sararak valizin ortasına yerleştir. En güvenli yöntem.',
          badge: 'İpucu', badgeTipi: _BadgeTipi.yesil),
      _Satir('Bubble wrap kullan',
          'Parfüm ve kozmetik ürünler için baloncuklu ambalaj kullan, sızdırmazlığını kontrol et.'),
      _Satir('Sıvıları poşetle',
          'Tüm sıvı ürünleri ziplock poşet içine koy. Basınç değişiminde sızıntı olabilir.',
          badge: 'Dikkat', badgeTipi: _BadgeTipi.sari),
    ]),
    _Kart('Ağırlık yönetimi', Symbols.scale, [
      _Satir('Bagaj tartısı al',
          'Seyahat tartısı ile evde tartarak git. Havalimanı sürprizlerinden kaçın.',
          badge: 'Tavsiye', badgeTipi: _BadgeTipi.yesil),
      _Satir('Kutuları çıkar',
          'Ayakkabı ve ürün kutuları çok yer kaplar. Ürünü çıkarıp poşetle sararak taşı.'),
      _Satir('Vakumlu torba',
          'Kıyafetler için vakumlu torba kullanmak valiz hacmini %40-50 azaltır.',
          badge: 'İpucu', badgeTipi: _BadgeTipi.mavi),
    ]),
  ]),

  _Tab('Ücret', Symbols.payments, [
    _Kart('İstekçiden nasıl ücret alınır', Symbols.payments, [
      _Satir('Ürün fiyatı + taşıma ücreti',
          'Ürün maliyetini ve taşıma ücretini ayrı belirt. Anlaşma yapılmadan önce her ikisi de netleştirilmeli.',
          badge: 'Standart', badgeTipi: _BadgeTipi.mavi),
      _Satir('Peşin al, riske girme',
          'Ürün bedelini önceden al. Karşılıklı güven oluşana kadar peşin çalış.',
          badge: 'Önemli', badgeTipi: _BadgeTipi.sari),
      _Satir('Gümrük riskini açıkla',
          'Gümrükte sorun çıkarsa ek maliyet doğabilir. Bunu önceden istekçiyle konuş ve anlaşmaya yaz.'),
      _Satir('İlan üzerinde fiyat belirt',
          'Taşıma ücretini ilana açıkça yaz. Müzakere sürecini kısaltır.',
          badge: 'Tavsiye', badgeTipi: _BadgeTipi.yesil),
    ]),
    _Kart('Güvenli teslimat', Symbols.verified_user, [
      _Satir('Halka açık yerde buluş',
          'İlk teslimatı AVM, kafe gibi kalabalık ortamlarda yap.',
          badge: 'Güvenlik', badgeTipi: _BadgeTipi.yesil),
      _Satir('Fotoğraflı teslim et',
          'Teslimat anında ürünün fotoğrafını çek. Anlaşmazlık çıkarsa kanıt olarak kullanırsın.'),
      _Satir('Uygulama üzerinden iletişim',
          'Tüm yazışmaları uygulama içinde yürüt. Kayıt altında olan mesajlar koruma sağlar.',
          badge: 'Tavsiye', badgeTipi: _BadgeTipi.mavi),
    ]),
  ]),

  _Tab('VAT İadesi', Symbols.receipt_long, [
    _Kart('VAT iadesi nedir?', Symbols.receipt_long, [
      _Satir('Ne kadar geri alırsın?',
          'AB ülkelerinde ödenen KDV\'nin %10-12\'sini iade alabilirsin. Aracı komisyon düşürüldükten sonra net iade bu kadardır.',
          badge: 'Bilgi', badgeTipi: _BadgeTipi.yesil),
      _Satir('Minimum tutar şartı',
          'Çoğu AB ülkesinde tek faturada minimum 50-100 Euro alışveriş yapman gerekir.'),
      _Satir('Dubai\'de VAT iadesi',
          'Dubai\'de %5 KDV var, havalimanında kolayca iade alınabilir. Minimum 250 AED alışveriş şartı.',
          badge: 'Dubai', badgeTipi: _BadgeTipi.mavi),
    ]),
    _Kart('VAT iadesi nasıl alınır?', Symbols.checklist, [
      _Satir('1. Mağazadan form al',
          'Alışveriş yaparken kasadan Tax Free formu doldurmasını iste. Pasaport gerekebilir.'),
      _Satir('2. Havalimanında onaylat',
          'Gümrük kontrol noktasında formu damgalat. Ürünü gösterirler, açmamış olması önemli.'),
      _Satir('3. Global Blue / Planet',
          'Havalimanındaki Global Blue veya Planet noktasından nakit veya karta iade al.',
          badge: 'Son adım', badgeTipi: _BadgeTipi.yesil),
      _Satir('Dikkat: ürünü kullanma',
          'İade için ürünün kullanılmamış ve orijinal ambalajında olması gerekir.',
          badge: 'Dikkat', badgeTipi: _BadgeTipi.kirmizi),
    ]),
  ]),
];

// ── Ana widget ────────────────────────────────────────────────────────────────

class TasiyiciIpuclariBolum extends StatefulWidget {
  const TasiyiciIpuclariBolum({super.key});

  @override
  State<TasiyiciIpuclariBolum> createState() => _TasiyiciIpuclariBolumState();
}

class _TasiyiciIpuclariBolumState extends State<TasiyiciIpuclariBolum> {
  int _aktifTab = 0;

  @override
  Widget build(BuildContext context) {
    final tab = _tablar[_aktifTab];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(children: [
            const Icon(Symbols.travel, size: 16, color: AppColors.red),
            const SizedBox(width: 6),
            Text('Taşıyıcı ipuçları',
                style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ]),
        ),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 0.8)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tablar.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final aktif = _aktifTab == i;
                return GestureDetector(
                  onTap: () => setState(() => _aktifTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: aktif ? AppColors.textPrimary : Colors.white,
                      border: i < _tablar.length - 1
                          ? Border(right: BorderSide(color: AppColors.divider, width: 0.8))
                          : null,
                    ),
                    child: Row(children: [
                      Icon(t.ikon, size: 14,
                          color: aktif ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(t.baslik,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                              color: aktif ? Colors.white : AppColors.textSecondary)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // İçerik
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: tab.kartlar.map((k) => _IpucuKarti(kart: k)).toList(),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── İpucu kartı ───────────────────────────────────────────────────────────────

class _IpucuKarti extends StatefulWidget {
  final _Kart kart;
  const _IpucuKarti({required this.kart});

  @override
  State<_IpucuKarti> createState() => _IpucuKartiState();
}

class _IpucuKartiState extends State<_IpucuKarti> {
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
                Icon(widget.kart.ikon, size: 20, weight: 300, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.kart.baslik,
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                AnimatedRotation(
                  turns: _acik ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Symbols.expand_more, size: 18, color: AppColors.textSecondary),
                ),
              ]),
            ),
          ),
          if (_acik)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: Column(
                children: widget.kart.satirlar.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: i < widget.kart.satirlar.length - 1
                          ? Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))
                          : null,
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.baslik,
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(s.aciklama,
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                        if (s.badge != null) ...[
                          const SizedBox(height: 4),
                          _Badge(s.badge!, s.badgeTipi!),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String metin;
  final _BadgeTipi tip;
  const _Badge(this.metin, this.tip);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color renk;
    switch (tip) {
      case _BadgeTipi.yesil:
        bg = const Color(0xFFE1F5EE); renk = const Color(0xFF0F6E56); break;
      case _BadgeTipi.kirmizi:
        bg = const Color(0xFFFCE4EC); renk = const Color(0xFF880E4F); break;
      case _BadgeTipi.mavi:
        bg = const Color(0xFFE3F2FD); renk = const Color(0xFF0D47A1); break;
      case _BadgeTipi.sari:
        bg = const Color(0xFFFFF8E1); renk = const Color(0xFFB45309); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(metin, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: renk)),
    );
  }
}