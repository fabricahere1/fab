import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _benimId = FirebaseAuth.instance.currentUser!.uid;
    final ids = [_benimId, widget.karsiKullaniciId]..sort();
    _sohbetId = '${ids[0]}_${ids[1]}_${widget.ilanId}';
    _sohbetOlustur();
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
    }, SetOptions(merge: true));
    _okunduIsaretle();
  }

  Future<void> _mesajGonder() async {
    final metin = _mesajController.text.trim();
    if (metin.isEmpty) return;
    _mesajController.clear();
    final benimAd = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
        'Kullanici';
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .collection('mesajlar')
        .add({
      'metin': metin,
      'gondereId': _benimId,
      'gondereAd': benimAd,
      'zaman': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('sohbetler')
        .doc(_sohbetId)
        .update({
      'sonMesaj': metin,
      'sonMesajZamani': FieldValue.serverTimestamp(),
      'sonGondereId': _benimId,
      'okunmamis.${widget.karsiKullaniciId}': FieldValue.increment(1),
    });
    _scrollEnAlt();
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

  Future<void> _mesajSil(BuildContext context, String mesajId) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Mesaji Sil',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('Bu mesaji silmek istedigine emin misin?',
            style: TextStyle(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (onay == true) {
      await FirebaseFirestore.instance
          .collection('sohbetler')
          .doc(_sohbetId)
          .collection('mesajlar')
          .doc(mesajId)
          .delete();
    }
  }

  void _kullaniciProfilGoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final adSoyad = data['adSoyad'] ?? widget.karsiKullaniciAd;
                  final sehir = data['sehir'] ?? '';
                  final telefon = data['telefon'] ?? '';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                        child: Text(
                          adSoyad[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.deepOrangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(adSoyad,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      if (sehir.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(sehir, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                      if (telefon.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(telefon, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
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
    _okunduIsaretle();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _kullaniciProfilGoster(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepOrangeAccent.withValues(alpha: 0.15),
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
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(widget.ilanBaslik,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                        child: CircularProgressIndicator(color: Colors.deepOrangeAccent));
                  }
                  final mesajlar = snapshot.data?.docs ?? [];
                  if (mesajlar.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Henuz mesaj yok.',
                              style: TextStyle(color: Colors.grey, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('Ilk mesaji sen gonder!',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollEnAlt());
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: mesajlar.length,
                    itemBuilder: (context, index) {
                      final doc = mesajlar[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final benimMesajim = data['gondereId'] == _benimId;
                      final zaman = (data['zaman'] as Timestamp?)?.toDate();
                      final zamanYazi = zaman != null
                          ? '${zaman.hour.toString().padLeft(2, '0')}:${zaman.minute.toString().padLeft(2, '0')}'
                          : '';
                      return GestureDetector(
                        onLongPress: benimMesajim
                            ? () => _mesajSil(context, doc.id)
                            : null,
                        child: _MesajBalonu(
                          metin: data['metin'] ?? '',
                          benimMesajim: benimMesajim,
                          zaman: zamanYazi,
                          gondereAd: benimMesajim ? null : widget.karsiKullaniciAd,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        crossAxisAlignment:
            benimMesajim ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: benimMesajim ? Alignment.centerRight : Alignment.centerLeft,
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
                      backgroundColor:
                          Colors.deepOrangeAccent.withValues(alpha: 0.15),
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