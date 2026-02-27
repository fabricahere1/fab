

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'ilan_olustur_page.dart';
import '../auth_gate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _aktifIlanTipi = 0;

  void _onTabTapped(int index) {
    if (index == 1 || index == 3) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        loginGerekli(context);
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _IlanlarPage(
        onTabChanged: (tip) {
          setState(() => _aktifIlanTipi = tip);
        },
      ),
      IlanOlusturPage(initialTip: _aktifIlanTipi),
      const _FavorilerPage(),
      const _ProfilPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.deepOrangeAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'İlan Ver'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoriler'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}

class _IlanlarPage extends StatefulWidget {
  final ValueChanged<int> onTabChanged;
  const _IlanlarPage({required this.onTabChanged});

  @override
  State<_IlanlarPage> createState() => _IlanlarPageState();
}

class _IlanlarPageState extends State<_IlanlarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Glocal',
          style: GoogleFonts.lobster(fontSize: 26, color: Colors.deepOrangeAccent),
        ),
        actions: [
          // Mesajlar ikonu
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _MesajlarPage()),
              );
            },
          ),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                final isim = user.displayName ?? user.email?.split('@')[0] ?? 'Kullanıcı';
                return GestureDetector(
                  onTap: () {
                    // Ana sayfadaki HomeScreen'in state'ine erişip profil sekmesine geç
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.setState(() => homeState._currentIndex = 3);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                      child: Text(
                        isim[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => loginGerekli(context),
                    child: const Text(
                      'Giriş Yap',
                      style: TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrangeAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrangeAccent,
          tabs: const [
            Tab(text: '✈️  Taşıyıcılar'),
            Tab(text: '🛍️  İstekler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TasiyicilarTab(),
          _IsteklerTab(),
        ],
      ),
    );
  }
}

void _favoriToast(BuildContext context) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => _FavoriToastWidget(),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1800), () => entry.remove());
}

class _FavoriToastWidget extends StatefulWidget {
  @override
  State<_FavoriToastWidget> createState() => _FavoriToastWidgetState();
}

class _FavoriToastWidgetState extends State<_FavoriToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Favorilere eklendi!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _ilanDetayGoster(BuildContext context, String docId, Map<String, dynamic> data,
    {required String tip}) {
  final isim = data['kullaniciAd'] ?? 'Kullanıcı';
  final tarih = (data['tarih'] as Timestamp?)?.toDate();
  final tarihYazi = tarih != null ? '${tarih.day}.${tarih.month}.${tarih.year}' : '';
  final benimIlanim = FirebaseAuth.instance.currentUser?.uid == data['kullaniciId'];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: tip == 'tasiyici'
                    ? Colors.deepOrangeAccent.withValues(alpha: 0.15)
                    : Colors.blue.shade50,
                child: Text(isim[0].toUpperCase(),
                    style: TextStyle(
                      color: tip == 'tasiyici'
                          ? Colors.deepOrangeAccent
                          : Colors.blue.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isim,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(
                    tip == 'tasiyici' ? '✈️ Taşıyıcı' : '🛍️ İstek',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nereden', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(data['nereden'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.deepOrangeAccent, size: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Nereye', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(data['nereye'] ?? '',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tip == 'istek' && data['urun'] != null && data['urun'] != '') ...[
            const Text('Ürün', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(data['urun'],
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              if (tarihYazi.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tarih', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(tarihYazi,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              const Spacer(),
              if (data['ucret'] != null && data['ucret'] != '')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Ücret', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('₺${data['ucret']}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.orange.shade700)),
                  ],
                ),
            ],
          ),
          if (data['notlar'] != null && data['notlar'] != '') ...[
            const SizedBox(height: 16),
            const Text('Notlar', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(data['notlar'],
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ],
          if (tip == 'istek' && data['link'] != null && data['link'] != '') ...[
            const SizedBox(height: 16),
            const Text('Ürün Linki', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(data['link'],
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                    decoration: TextDecoration.underline),
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 24),
          if (!benimIlanim)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Row(
                children: [
                  // Favori butonu
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseAuth.instance.currentUser == null
                        ? const Stream.empty()
                        : FirebaseFirestore.instance
                            .collection('favoriler')
                            .where('kullaniciId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                            .where('ilanId', isEqualTo: docId)
                            .snapshots(),
                    builder: (context, snap) {
                      final favori = (snap.data?.docs ?? []).isNotEmpty;
                      return IconButton(
                        icon: Icon(
                          favori ? Icons.favorite : Icons.favorite_outline,
                          color: favori ? Colors.red : Colors.grey,
                        ),
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            loginGerekli(context);
                            return;
                          }
                          if (favori) {
                            final docs = snap.data?.docs ?? [];
                            if (docs.isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('favoriler')
                                  .doc(docs.first.id)
                                  .delete();
                            }
                          } else {
                            await FirebaseFirestore.instance
                                .collection('favoriler')
                                .add({
                              'kullaniciId': user.uid,
                              'ilanId': docId,
                              'tip': tip,
                              'kullaniciAd': data['kullaniciAd'],
                              'nereden': data['nereden'],
                              'nereye': data['nereye'],
                              'urun': data['urun'] ?? '',
                              'ucret': data['ucret'] ?? '',
                              'eklemeTarihi': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) {
                              _favoriToast(context);
                            }
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        loginGerekli(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        tip == 'tasiyici' ? 'İletişime Geç' : 'Ben Getirebilirim',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
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

void ilanMenuGoster(BuildContext context, String docId, Map<String, dynamic> data) {
  final mevcutKullanici = FirebaseAuth.instance.currentUser;
  final bool benimIlanim = mevcutKullanici?.uid == data['kullaniciId'];
  if (!benimIlanim) return;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.black54),
            title: const Text('Düzenle', style: TextStyle(fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
              ilanDuzenle(context, docId, data);
            },
          ),
          ListTile(
            leading: Icon(
              data['aktif'] == false
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.black54,
            ),
            title: Text(
              data['aktif'] == false ? 'Aktif Et' : 'Pasife Al',
              style: const TextStyle(fontSize: 15),
            ),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('ilanlar')
                  .doc(docId)
                  .update({'aktif': data['aktif'] == false ? true : false});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(data['aktif'] == false
                        ? 'İlan aktif edildi.'
                        : 'İlan pasife alındı.'),
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Sil', style: TextStyle(fontSize: 15, color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              ilanSilOnay(context, docId);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void ilanSilOnay(BuildContext context, String docId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: const Text('İlanı sil?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      content: const Text('Bu işlem geri alınamaz.',
          style: TextStyle(fontSize: 14, color: Colors.black54)),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İPTAL',
              style: TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await FirebaseFirestore.instance.collection('ilanlar').doc(docId).delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('İlan silindi.'), backgroundColor: Colors.black87),
              );
            }
          },
          child: const Text('SİL',
              style: TextStyle(
                  color: Colors.deepOrangeAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      ],
    ),
  );
}

void ilanDuzenle(BuildContext context, String docId, Map<String, dynamic> data) {
  final neredenController = TextEditingController(text: data['nereden']);
  final nereyeController = TextEditingController(text: data['nereye']);
  final ucretController = TextEditingController(text: data['ucret']);
  final kapasiteController = TextEditingController(text: data['kapasite'] ?? '');
  final urunController = TextEditingController(text: data['urun'] ?? '');
  final notlarController = TextEditingController(text: data['notlar'] ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('İlanı Düzenle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _DuzenleAlani(label: 'Nereden', controller: neredenController),
            const SizedBox(height: 12),
            _DuzenleAlani(label: 'Nereye', controller: nereyeController),
            const SizedBox(height: 12),
            _DuzenleAlani(
                label: 'Ücret (₺)',
                controller: ucretController,
                klavye: TextInputType.number),
            if (data['tip'] == 'tasiyici') ...[
              const SizedBox(height: 12),
              _DuzenleAlani(
                  label: 'Kapasite (kg)',
                  controller: kapasiteController,
                  klavye: TextInputType.number),
            ],
            if (data['tip'] == 'istek') ...[
              const SizedBox(height: 12),
              _DuzenleAlani(label: 'Ürün Adı', controller: urunController),
            ],
            const SizedBox(height: 12),
            _DuzenleAlani(label: 'Notlar', controller: notlarController, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final guncelleme = {
                    'nereden': neredenController.text.trim(),
                    'nereye': nereyeController.text.trim(),
                    'ucret': ucretController.text.trim(),
                    'notlar': notlarController.text.trim(),
                    if (data['tip'] == 'tasiyici')
                      'kapasite': kapasiteController.text.trim(),
                    if (data['tip'] == 'istek') 'urun': urunController.text.trim(),
                  };
                  await FirebaseFirestore.instance
                      .collection('ilanlar')
                      .doc(docId)
                      .update(guncelleme);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('İlan güncellendi! ✅'),
                          backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Kaydet',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DuzenleAlani extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType klavye;
  final int maxLines;

  const _DuzenleAlani({
    required this.label,
    required this.controller,
    this.klavye = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: klavye,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.deepOrangeAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _TasiyicilarTab extends StatelessWidget {
  const _TasiyicilarTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ilanlar')
          .where('tip', isEqualTo: 'tasiyici')
          .where('aktif', isEqualTo: true)
          .orderBy('olusturmaTarihi', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrangeAccent));
        }
        if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu.'));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flight, size: 60, color: Colors.grey),
                SizedBox(height: 12),
                Text('Henüz taşıyıcı ilanı yok.',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                SizedBox(height: 4),
                Text('İlk ilanı sen ver!',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _TasiyiciKarti(docId: doc.id, data: data);
          },
        );
      },
    );
  }
}

class _TasiyiciKarti extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _TasiyiciKarti({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final tarih = (data['tarih'] as Timestamp?)?.toDate();
    final tarihYazi =
        tarih != null ? '${tarih.day}.${tarih.month}.${tarih.year}' : '';
    final isim = data['kullaniciAd'] ?? 'Kullanıcı';
    final benimIlanim =
        FirebaseAuth.instance.currentUser?.uid == data['kullaniciId'];
    final pasif = data['aktif'] == false;

    return Opacity(
      opacity: pasif ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: () => _ilanDetayGoster(context, docId, data, tip: 'tasiyici'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                  child: Text(isim[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(isim,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          if (tarihYazi.isNotEmpty)
                            Text(tarihYazi,
                                style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${data['nereden'] ?? ''} → ${data['nereye'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (data['kapasite'] != null && data['kapasite'] != '')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('${data['kapasite']} kg',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ),
                          if (data['ucret'] != null && data['ucret'] != '') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('₺${data['ucret']}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                          const Spacer(),
                          if (!benimIlanim)
                            SizedBox(
                              height: 26,
                              child: ElevatedButton(
                                onPressed: () => loginGerekli(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrangeAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                child: const Text('İletişime Geç',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          if (benimIlanim)
                            GestureDetector(
                              onTap: () => ilanMenuGoster(context, docId, data),
                              child: const Icon(Icons.more_vert,
                                  color: Colors.grey, size: 18),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IsteklerTab extends StatelessWidget {
  const _IsteklerTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ilanlar')
          .where('tip', isEqualTo: 'istek')
          .where('aktif', isEqualTo: true)
          .orderBy('olusturmaTarihi', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrangeAccent));
        }
        if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu.'));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 12),
                Text('Henüz istek ilanı yok.',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                SizedBox(height: 4),
                Text('İlk isteği sen oluştur!',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _IstekKarti(docId: doc.id, data: data);
          },
        );
      },
    );
  }
}

class _IstekKarti extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _IstekKarti({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final isim = data['kullaniciAd'] ?? 'Kullanıcı';
    final benimIlanim =
        FirebaseAuth.instance.currentUser?.uid == data['kullaniciId'];
    final pasif = data['aktif'] == false;

    return Opacity(
      opacity: pasif ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: () => _ilanDetayGoster(context, docId, data, tip: 'istek'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(isim[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.blue.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(isim,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          if (data['ucret'] != null && data['ucret'] != '')
                            Text('₺${data['ucret']}',
                                style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(data['urun'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87)),
                      const SizedBox(height: 2),
                      // FIX: overflow hatası burada düzeltildi
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${data['nereden'] ?? ''} → ${data['nereye'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                          if (!benimIlanim)
                            SizedBox(
                              height: 24,
                              child: OutlinedButton(
                                onPressed: () => loginGerekli(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.deepOrangeAccent),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: const Text('Getiririm',
                                    style: TextStyle(
                                        color: Colors.deepOrangeAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          if (benimIlanim)
                            GestureDetector(
                              onTap: () => ilanMenuGoster(context, docId, data),
                              child: const Icon(Icons.more_vert,
                                  color: Colors.grey, size: 18),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MesajlarPage extends StatelessWidget {
  const _MesajlarPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mesajlar',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: const Center(
          child: Text('Mesajlar — yakında',
              style: TextStyle(color: Colors.grey))),
    );
  }
}

class _FavorilerPage extends StatelessWidget {
  const _FavorilerPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Favorilerim',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Favorileri görmek için giriş yapın.',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => loginGerekli(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Giriş Yap',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('favoriler')
                  .where('kullaniciId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.deepOrangeAccent));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_outline, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Henüz favori eklemediniz.',
                            style: TextStyle(color: Colors.grey, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('İlanlara tıklayarak favoriye ekleyebilirsiniz.',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tip = data['tip'] ?? 'tasiyici';
                    final isim = data['kullaniciAd'] ?? 'Kullanıcı';
                    final baslik = tip == 'tasiyici'
                        ? '${data['nereden']} → ${data['nereye']}'
                        : data['urun'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: tip == 'tasiyici'
                                ? Colors.deepOrangeAccent.withValues(alpha: 0.15)
                                : Colors.blue.shade50,
                            child: Text(isim[0].toUpperCase(),
                                style: TextStyle(
                                    color: tip == 'tasiyici'
                                        ? Colors.deepOrangeAccent
                                        : Colors.blue.shade400,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tip == 'tasiyici' ? '✈️ Taşıyıcı' : '🛍️ İstek',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(baslik,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(isim,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('favoriler')
                                  .doc(doc.id)
                                  .delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Favorilerden kaldırıldı.'),
                                      backgroundColor: Colors.black87),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ProfilPage extends StatelessWidget {
  const _ProfilPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profilim',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              final onay = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  title: const Text('Çıkış yap?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  content: const Text(
                    'Hesabından çıkmak istediğine emin misin?',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İPTAL',
                          style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ÇIKIŞ YAP',
                          style: TextStyle(
                              color: Colors.deepOrangeAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ],
                ),
              );
              if (onay == true) {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final profilData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final adSoyad = profilData['adSoyad'] ?? user?.displayName ?? 'Kullanıcı';
          final sehir = profilData['sehir'] ?? '';
          final telefon = profilData['telefon'] ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                      child: Text(
                        adSoyad[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => _profilDuzenle(context, user?.uid, profilData),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.deepOrangeAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(adSoyad,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(user?.email ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                if (sehir.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(sehir, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                if (telefon.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(telefon,
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _profilDuzenle(context, user?.uid, profilData),
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.deepOrangeAccent, size: 18),
                      label: const Text('Profili Düzenle',
                          style: TextStyle(color: Colors.deepOrangeAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrangeAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('İlanlarım',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('ilanlar')
                            .where('kullaniciId', isEqualTo: user?.uid)
                            .orderBy('olusturmaTarihi', descending: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.deepOrangeAccent));
                          }
                          final docs = snap.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('Henüz ilan vermediniz.',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            );
                          }
                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final pasif = data['aktif'] == false;
                              final tip = data['tip'] == 'tasiyici'
                                  ? '✈️ Taşıyıcı'
                                  : '🛍️ İstek';
                              final baslik = data['tip'] == 'tasiyici'
                                  ? '${data['nereden']} → ${data['nereye']}'
                                  : data['urun'] ?? '';

                              return Opacity(
                                opacity: pasif ? 0.5 : 1.0,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(tip,
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.grey)),
                                            const SizedBox(height: 2),
                                            Text(baslik,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14)),
                                            if (pasif)
                                              const Text('Pasif',
                                                  style: TextStyle(
                                                      color: Colors.orange, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            ilanMenuGoster(context, doc.id, data),
                                        child: const Icon(Icons.more_vert,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  void _profilDuzenle(BuildContext context, String? uid,
      Map<String, dynamic> mevcutData) {
    if (uid == null) return;

    final adController = TextEditingController(text: mevcutData['adSoyad'] ?? '');
    final sehirController = TextEditingController(text: mevcutData['sehir'] ?? '');
    final telefonController = TextEditingController(text: mevcutData['telefon'] ?? '');
    final notlarController = TextEditingController(text: mevcutData['notlar'] ?? '');
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Profili Düzenle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _DuzenleAlani(label: 'Ad Soyad', controller: adController),
            const SizedBox(height: 12),
            // Email - sadece göster, düzenlenemez
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('E-posta',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(width: 8),
                    Text('Değiştirilemez',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(email, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DuzenleAlani(label: 'Şehir / Ülke', controller: sehirController),
            const SizedBox(height: 12),
            _DuzenleAlani(
                label: 'Telefon',
                controller: telefonController,
                klavye: TextInputType.phone),
            const SizedBox(height: 12),
            _DuzenleAlani(label: 'Hakkımda / Notlar', controller: notlarController, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('kullanicilar')
                      .doc(uid)
                      .set({
                    'adSoyad': adController.text.trim(),
                    'sehir': sehirController.text.trim(),
                    'telefon': telefonController.text.trim(),
                    'notlar': notlarController.text.trim(),
                  }, SetOptions(merge: true));

                  await FirebaseAuth.instance.currentUser
                      ?.updateDisplayName(adController.text.trim());

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profil güncellendi! ✅'),
                          backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Kaydet',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}