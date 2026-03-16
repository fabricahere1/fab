import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'g_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'degerlendirme_screen.dart';
import 'kullanici_profil_screen.dart';
 
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
  bool _ilkYukleme = true;
 
  // Tek stream — AppBar ve body paylaşır
  late Stream<DocumentSnapshot> _sohbetStream;
 
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
    _sohbetStream = FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .snapshots();
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
 
  void _mesajGonder() {
    final metin = _mesajController.text.trim();
    if (metin.isEmpty) return;
    _mesajController.clear();
    final benimAd = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
        'Kullanici';
 
    final simdi = Timestamp.now();
 
    // await YOK — hemen gönder, stream zaten dinliyor
    FirebaseFirestore.instance
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
    FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .update({
      'sonMesaj': metin,
      'sonMesajZamani': simdi,
      'sonGondereId': _benimId,
      'okunmamis.${widget.karsiKullaniciId}': FieldValue.increment(1),
    });
    _scrollEnAlt();
  }
 
  bool get _enAlttaMi {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.pixels >= pos.maxScrollExtent - 100;
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
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Bu mesajı silmek istediğine emin misin?',
            style:
                GoogleFonts.dmSans(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil',
                style: GoogleFonts.dmSans(
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
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => KullaniciProfilScreen(
                kullaniciId: widget.karsiKullaniciId,
                isim: widget.karsiKullaniciAd,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    GColors.red.withValues(alpha: 0.15),
                child: Text(
                  widget.karsiKullaniciAd[0].toUpperCase(),
                  style: const TextStyle(
                      color: GColors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.karsiKullaniciAd,
                        style: GoogleFonts.dmSans(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(widget.ilanBaslik,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                            color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: const [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox.shrink(),
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
                            color: GColors.red));
                  }
                  final mesajlar = snapshot.data?.docs ?? [];
 
                  final yeniMesajVar =
                      mesajlar.length != _sonMesajSayisi;
 
                  if (snapshot.hasData && yeniMesajVar) {
                    _sonMesajSayisi = mesajlar.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _okunduIsaretle();
                    });
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
                              style: GoogleFonts.dmSans(
                                  color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('İlk mesajı sen gönder!',
                              style: GoogleFonts.dmSans(
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
 
                      return _MesajBalonu(
                          metin: metin,
                          benimMesajim: benimMesajim,
                          zaman: zamanYazi,
                          gondereAd: benimMesajim
                              ? null
                              : widget.karsiKullaniciAd,
                          onAvatarTap: benimMesajim
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => KullaniciProfilScreen(
                                        kullaniciId:
                                            widget.karsiKullaniciId,
                                        isim: widget.karsiKullaniciAd,
                                      ),
                                    ),
                                  ),
                          onLongPress: benimMesajim
                              ? () => _mesajSil(context, doc.id, metin)
                              : null,
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
                            GoogleFonts.dmSans(color: Colors.grey),
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
                        color: GColors.red,
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
            style: GoogleFonts.dmSans(
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
 
  final VoidCallback? onLongPress;
 
  const _MesajBalonu({
    required this.metin,
    required this.benimMesajim,
    required this.zaman,
    this.gondereAd,
    this.onAvatarTap,
    this.onLongPress,
  });
 
  @override
  Widget build(BuildContext context) {
    final balon = Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: benimMesajim ? GColors.red : Colors.white,
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
                  color: benimMesajim ? Colors.white : Colors.black87,
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
 
    return InkWell(
      onLongPress: onLongPress,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
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
                      backgroundColor: GColors.red
                          .withValues(alpha: 0.15),
                      child: Text(
                        gondereAd?.isNotEmpty == true
                            ? gondereAd![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: GColors.red,
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
      ),
    );
  }
}