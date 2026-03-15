import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'degerlendirme_screen.dart';
 
const _siparisAsamalari = [
  'Anlaşıldı',
  'Satın Alındı',
  'Yolda',
  'Teslim Edildi',
];
 
const _siparisIkonlari = [
  Icons.handshake_outlined,
  Icons.shopping_cart_checkout,
  Icons.local_shipping_outlined,
  Icons.check_circle_outline,
];
 
class SohbetScreen extends StatefulWidget {
  final String karsiKullaniciId;
  final String karsiKullaniciAd;
  final String ilanId;
  final String ilanBaslik;
 
  const SohbetScreen({
    super.key,
    required this.karsiKullaniciId,
    required this.karsiKullaniciAd,
    required this.ilanId,
    required this.ilanBaslik,
  });
 
  @override
  State<SohbetScreen> createState() => _SohbetScreenState();
}
 
class _SohbetScreenState extends State<SohbetScreen> {
  final _mesajController = TextEditingController();
  final _scrollController = ScrollController();
  late String _sohbetId;
  late String _benimId;
 
  int _sonMesajSayisi = -1;
  // İlk yükleme mi? İlk açılışta her zaman en alta git
  bool _ilkYukleme = true;
 
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    _benimId = user.uid;
    final ids = [_benimId, widget.karsiKullaniciId]..sort();
    _sohbetId = '${ids[0]}_${ids[1]}_${widget.ilanId}';
    _sohbetOlustur();
    _okunduIsaretle();
  }
 
  Future<void> _sohbetOlustur() async {
    final benimAd = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
        'Kullanici';
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .set({
      'kullanicilar': [_benimId, widget.karsiKullaniciId],
      'kullaniciAdlari': {
        _benimId: benimAd,
        widget.karsiKullaniciId: widget.karsiKullaniciAd,
      },
      'ilanId': widget.ilanId,
      'ilanBaslik': widget.ilanBaslik,
      'sonMesajZamani': FieldValue.serverTimestamp(),
      'okunmamis': {
        widget.karsiKullaniciId: 0,
        _benimId: 0,
      },
      'degerlendirmeYapildi': false,
    }, SetOptions(merge: true));
  }
 
  Future<void> _mesajGonder() async {
    final metin = _mesajController.text.trim();
    if (metin.isEmpty) return;
    _mesajController.clear();
    final benimAd = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
        'Kullanici';
 
    final simdi = Timestamp.now();
 
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .collection('mesajlar')
        .add({
      'metin': metin,
      'gondereId': _benimId,
      'gondereAd': benimAd,
      'zaman': simdi,
      'tip': 'mesaj',
    });
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .update({
      'sonMesaj': metin,
      'sonMesajZamani': simdi,
      'sonGondereId': _benimId,
      'okunmamis.${widget.karsiKullaniciId}': FieldValue.increment(1),
    });
    // Mesaj gönderince her zaman en alta git
    _scrollEnAlt();
  }
 
  // Kullanıcı en altta mı?
  bool get _enAlttaMi {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.pixels >= pos.maxScrollExtent - 100;
  }
 
  Future<void> _siparisGuncelle(int yeniAsama) async {
    final benimAd = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
        'Kullanici';
 
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .update({'siparisAsamasi': yeniAsama});
 
    final asamaAdi = _siparisAsamalari[yeniAsama];
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .collection('mesajlar')
        .add({
      'metin': '$benimAd sipariş durumunu güncelledi: $asamaAdi',
      'gondereId': _benimId,
      'gondereAd': benimAd,
      'zaman': Timestamp.now(),
      'tip': 'sistem',
    });
 
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .update({
      'sonMesaj': 'Sipariş durumu: $asamaAdi',
      'sonMesajZamani': FieldValue.serverTimestamp(),
      'okunmamis.${widget.karsiKullaniciId}': FieldValue.increment(1),
    });
 
    if (yeniAsama == 3 && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _degerlendirmeOner();
    }
    _scrollEnAlt();
  }
 
  void _degerlendirmeOner() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB300), size: 36),
            ),
            const SizedBox(height: 16),
            Text('Teslimat tamamlandı! 🎉',
                style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              '${widget.karsiKullaniciAd} ile olan deneyiminizi\npaylaşmak ister misiniz?',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DegerlendirmeScreen(
                        hedefKullaniciId: widget.karsiKullaniciId,
                        hedefKullaniciAd: widget.karsiKullaniciAd,
                        sohbetId: _sohbetId,
                        ilanBaslik: widget.ilanBaslik,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Değerlendir',
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Daha sonra',
                  style: GoogleFonts.dmSans(
                      color: Colors.black45, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
 
  void _siparisBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sohbetler')
            .doc(_sohbetId)
            .snapshots(),
        builder: (context, snapshot) {
          final data =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final mevcutAsama = (data['siparisAsamasi'] as int?) ?? -1;
 
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('📦 Sipariş Takibi',
                    style: GoogleFonts.roboto(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(widget.ilanBaslik,
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),
                ...List.generate(_siparisAsamalari.length, (index) {
                  final aktif = mevcutAsama >= index;
                  final mevcutMu = mevcutAsama == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: aktif
                                ? const Color(0xFF3C3C3C)
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_siparisIkonlari[index],
                              color: aktif ? Colors.white : Colors.grey,
                              size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _siparisAsamalari[index],
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: mevcutMu
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: aktif
                                  ? const Color(0xFF212121)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        if (mevcutMu)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Mevcut',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w500)),
                          ),
                        if (!aktif && mevcutAsama == index - 1)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _siparisGuncelle(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3C3C3C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Güncelle',
                                  style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (mevcutAsama == -1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _siparisGuncelle(0);
                      },
                      icon: const Icon(Icons.handshake_outlined,
                          color: Colors.white, size: 18),
                      label: Text('Süreci Başlat',
                          style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C3C3C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
                if (mevcutAsama == 3) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DegerlendirmeScreen(
                              hedefKullaniciId: widget.karsiKullaniciId,
                              hedefKullaniciAd: widget.karsiKullaniciAd,
                              sohbetId: _sohbetId,
                              ilanBaslik: widget.ilanBaslik,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star_outline,
                          color: Colors.white, size: 18),
                      label: Text('Değerlendir',
                          style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
 
  void _scrollEnAlt() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
 
  Future<void> _okunduIsaretle() async {
    try {
      await FirebaseFirestore.instance
          .collection('sohbetler')
          .doc(_sohbetId)
          .update({'okunmamis.$_benimId': 0});
    } catch (_) {}
  }
 
  Future<void> _mesajSil(
      BuildContext context, String mesajId, String metin) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Mesajı Sil',
            style: GoogleFonts.roboto(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Bu mesajı silmek istediğine emin misin?',
            style:
                GoogleFonts.roboto(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: GoogleFonts.roboto(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil',
                style: GoogleFonts.roboto(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay != true) return;
 
    final mesajlarRef = FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .collection('mesajlar');
 
    final sohbetDoc = await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .get();
    final sonMesaj = sohbetDoc.data()?['sonMesaj'] as String?;
 
    await mesajlarRef.doc(mesajId).delete();
 
    if (sonMesaj == metin) {
      final oncekiMesajlar = await mesajlarRef
          .orderBy('zaman', descending: true)
          .limit(1)
          .get();
 
      if (oncekiMesajlar.docs.isNotEmpty) {
        final oncekiMetin =
            oncekiMesajlar.docs.first.data()['metin'] as String? ?? '';
        await FirebaseFirestore.instance
            .collection('sohbetler')
            .doc(_sohbetId)
            .update({'sonMesaj': oncekiMetin});
      } else {
        await FirebaseFirestore.instance
            .collection('sohbetler')
            .doc(_sohbetId)
            .update({'sonMesaj': ''});
      }
    }
  }
 
  void _kullaniciProfilGoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('kullanicilar')
                    .doc(widget.karsiKullaniciId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data()
                          as Map<String, dynamic>? ??
                      {};
                  final adSoyad =
                      data['adSoyad'] ?? widget.karsiKullaniciAd;
                  final sehir = data['sehir'] ?? '';
                  final telefon = data['telefon'] ?? '';
                  final telefonGizli = data['telefonGizli'] == true;
                  final puan =
                      ((data['ortalamaPuan']) as num?)?.toDouble() ?? 0.0;
                  final puanSayisi =
                      ((data['degerlendirmeSayisi']) as num?)?.toInt() ??
                          0;
 
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF3C3C3C),
                        child: Text(
                          adSoyad[0].toUpperCase(),
                          style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(adSoyad,
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      if (puanSayisi > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFFB300), size: 16),
                            const SizedBox(width: 4),
                            Text(puan.toStringAsFixed(1),
                                style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            Text(' ($puanSayisi değerlendirme)',
                                style: GoogleFonts.roboto(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                      if (sehir.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(sehir,
                                style: GoogleFonts.roboto(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                      if (telefon.isNotEmpty && !telefonGizli) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(telefon,
                                style: GoogleFonts.roboto(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          sikayetGonder(
                            context,
                            hedefId: widget.karsiKullaniciId,
                            hedefAd: adSoyad,
                            ilanId: widget.ilanId,
                          );
                        },
                        icon: const Icon(Icons.flag_outlined,
                            color: Colors.red, size: 16),
                        label: Text('Şikayet Et',
                            style: GoogleFonts.roboto(
                                color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _kullaniciProfilGoster(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                    Colors.deepOrangeAccent.withValues(alpha: 0.15),
                child: Text(
                  widget.karsiKullaniciAd[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.karsiKullaniciAd,
                      style: GoogleFonts.roboto(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(widget.ilanBaslik,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                          color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sohbetler')
                .doc(_sohbetId)
                .snapshots(),
            builder: (context, snapshot) {
              final data =
                  snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final asama = (data['siparisAsamasi'] as int?) ?? -1;
              return IconButton(
                onPressed: _siparisBottomSheet,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: Colors.black87),
                    if (asama >= 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Sipariş Takibi',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sohbetler')
                  .doc(_sohbetId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final asama = (data['siparisAsamasi'] as int?) ?? -1;
                final degerlendirmeYapildi =
                    data['degerlendirmeYapildi'] == true;
 
                if (asama == 3 && !degerlendirmeYapildi) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DegerlendirmeScreen(
                          hedefKullaniciId: widget.karsiKullaniciId,
                          hedefKullaniciAd: widget.karsiKullaniciAd,
                          sohbetId: _sohbetId,
                          ilanBaslik: widget.ilanBaslik,
                        ),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: const Color(0xFFFFF8E1),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFFFB300)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Teslimat tamamlandı · ${widget.karsiKullaniciAd} kullanıcısını değerlendir',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: const Color(0xFF8B6914),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Değerlendir',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  );
                }
 
                if (asama < 0) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: _siparisBottomSheet,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: const Color(0xFFE8F5E9),
                    child: Row(
                      children: [
                        Icon(_siparisIkonlari[asama],
                            size: 16, color: const Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Text(
                          'Sipariş: ${_siparisAsamalari[asama]}',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text('Detay →',
                            style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: const Color(0xFF2E7D32))),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sohbetler')
                    .doc(_sohbetId)
                    .collection('mesajlar')
                    .orderBy('zaman', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.deepOrangeAccent));
                  }
                  final mesajlar = snapshot.data?.docs ?? [];
 
                  // Yeni mesaj geldi mi?
                  final yeniMesajVar =
                      mesajlar.length != _sonMesajSayisi;
 
                  if (snapshot.hasData && yeniMesajVar) {
                    _sonMesajSayisi = mesajlar.length;
                    // Okundu işaretle
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _okunduIsaretle();
                    });
                    // İlk yükleme → her zaman en alta git
                    // Sonraki mesajlar → sadece en alttaysa git
                    if (_ilkYukleme || _enAlttaMi) {
                      _ilkYukleme = false;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _scrollEnAlt();
                      });
                    }
                  }
 
                  if (mesajlar.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 50, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('Henüz mesaj yok.',
                              style: GoogleFonts.roboto(
                                  color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('İlk mesajı sen gönder!',
                              style: GoogleFonts.roboto(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }
 
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: mesajlar.length,
                    itemBuilder: (context, index) {
                      final doc = mesajlar[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final tip = data['tip'] ?? 'mesaj';
 
                      if (tip == 'sistem') {
                        return _SistemMesaji(metin: data['metin'] ?? '');
                      }
 
                      final benimMesajim =
                          data['gondereId'] == _benimId;
                      final zaman =
                          (data['zaman'] as Timestamp?)?.toDate();
                      final zamanYazi = zaman != null
                          ? '${zaman.hour.toString().padLeft(2, '0')}:${zaman.minute.toString().padLeft(2, '0')}'
                          : '';
                      final metin = data['metin'] ?? '';
 
                      return GestureDetector(
                        onLongPress: benimMesajim
                            ? () => _mesajSil(context, doc.id, metin)
                            : null,
                        child: _MesajBalonu(
                          metin: metin,
                          benimMesajim: benimMesajim,
                          zaman: zamanYazi,
                          gondereAd: benimMesajim
                              ? null
                              : widget.karsiKullaniciAd,
                          onAvatarTap: benimMesajim
                              ? null
                              : () => _kullaniciProfilGoster(context),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mesajController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _mesajGonder(),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        hintStyle:
                            GoogleFonts.roboto(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _mesajGonder,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.deepOrangeAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
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
}
 
// ── Sistem Mesajı ─────────────────────────────────────────
 
class _SistemMesaji extends StatelessWidget {
  final String metin;
  const _SistemMesaji({required this.metin});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            metin,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
 
// ── Mesaj Balonu ──────────────────────────────────────────
 
class _MesajBalonu extends StatelessWidget {
  final String metin;
  final bool benimMesajim;
  final String zaman;
  final String? gondereAd;
  final VoidCallback? onAvatarTap;
 
  const _MesajBalonu({
    required this.metin,
    required this.benimMesajim,
    required this.zaman,
    this.gondereAd,
    this.onAvatarTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final balon = Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: benimMesajim ? Colors.deepOrangeAccent : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(benimMesajim ? 16 : 4),
          bottomRight: Radius.circular(benimMesajim ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: benimMesajim
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(metin,
              style: TextStyle(
                  color:
                      benimMesajim ? Colors.white : Colors.black87,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(zaman,
              style: TextStyle(
                  color: benimMesajim
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey,
                  fontSize: 10)),
        ],
      ),
    );
 
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: benimMesajim
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: benimMesajim
            ? balon
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.deepOrangeAccent
                          .withValues(alpha: 0.15),
                      child: Text(
                        gondereAd?.isNotEmpty == true
                            ? gondereAd![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  balon,
                ],
              ),
      ),
    );
  }
}