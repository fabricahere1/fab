import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'ilan_olustur_page.dart';
import 'package:yeni_proje/screens/sohbet_screen.dart';
import '../auth_gate.dart';
import 'register_screen.dart';

// ── Gri Renk Paleti ─────────────────────────────────────
class GColors {
  static const primary = Color(0xFF3C3C3C);      // Ana koyu gri
  static const accent = Color(0xFF5C5C5C);        // Vurgu gri
  static const red = Color(0xFFE53935);           // Sadece hata/silme
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);       // Arka plan
  static const surfaceAlt = Color(0xFFEEEEEE);    // Kart hover
  static const divider = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);
  static const avatarBg = Color(0xFFEEEEEE);      // Avatar arka plan
  static const chipBg = Color(0xFFE8E8E8);        // Chip arka plan
  // Geriye dönük uyumluluk için alias'lar
  static const blue = primary;
  static const green = accent;
  static const yellow = Color(0xFF9E9E9E);
  static const blueLight = avatarBg;
  static const greenLight = chipBg;
  static const redLight = Color(0xFFFFEBEE);
}

// Tarihe göre "X GÜN SONRA GELİYOR" yazısı
String _gunFarki(DateTime tarih) {
  final bugun = DateTime.now();
  final fark = tarih.difference(DateTime(bugun.year, bugun.month, bugun.day)).inDays;
  if (fark < 0) return 'GEÇMİŞ TARİH';
  if (fark == 0) return 'BUGÜN GELİYOR';
  if (fark == 1) return 'YARIN GELİYOR';
  return '$fark GÜN SONRA GELİYOR';
}

// İsme göre sabit avatar rengi
Color _avatarRenk(String isim) {
  final renkler = [
    const Color(0xFFE53935), // kırmızı
    const Color(0xFF8E24AA), // mor
    const Color(0xFF1E88E5), // mavi
    const Color(0xFF00897B), // teal
    const Color(0xFF43A047), // yeşil
    const Color(0xFFE67E22), // turuncu
    const Color(0xFF6D4C41), // kahve
    const Color(0xFF546E7A), // slate
  ];
  final index = isim.codeUnitAt(0) % renkler.length;
  return renkler[index];
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _aktifIlanTipi = 0;

  void _onTabTapped(int index) {
    if (index == 2 || index == 3) {
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
        onTabChanged: (tip) => setState(() => _aktifIlanTipi = tip),
      ),
      const _FavorilerPage(),
      IlanOlusturPage(initialTip: _aktifIlanTipi),
      const _MesajlarPage(),
      const _ProfilPage(),
    ];

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: GColors.surface,
      body: Stack(
        children: [
          // Sayfa içeriği - alt padding ile floating nav'a yer aç
          Padding(
            padding: user == null
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: 80),
            child: pages[_currentIndex],
          ),
          // Floating Nav Bar
          if (user != null)
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: _FloatingNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Ana İlanlar Sayfası ────────────────────────────────────

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
      backgroundColor: GColors.surface,
      appBar: AppBar(
        backgroundColor: GColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GColors.divider,
        titleSpacing: 16,
        title: Row(
          children: [
            Text(
              'İSTE',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: GColors.red,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                final isim = user.displayName ??
                    user.email?.split('@')[0] ??
                    'Kullanıcı';
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() => homeState._currentIndex = 4);
                    },
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: _avatarRenk(isim),
                      child: Text(
                        isim[0].toUpperCase(),
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => loginGerekli(context),
                      style: TextButton.styleFrom(
                        foregroundColor: GColors.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: GColors.divider),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                      child: Text(
                        'Giriş Yap',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: GColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: GColors.avatarBg,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                        child: Text(
                          'Kayıt Ol',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: GColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: GColors.divider)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: GColors.primary,
              unselectedLabelColor: GColors.textSecondary,
              indicatorColor: GColors.primary,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.roboto(fontSize: 14),
              tabs: const [
                Tab(text: '✈️  Taşıyıcılar'),
                Tab(text: '🛍️  İstekler'),
              ],
            ),
          ),
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

// ── Taşıyıcı Kartı ────────────────────────────────────────

class _TasiyicilarTab extends StatelessWidget {
  const _TasiyicilarTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ilanlar')
          .where('tip', isEqualTo: 'tasiyici')
          .orderBy('olusturmaTarihi', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GColors.blue,
              strokeWidth: 2,
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Bir hata oluştu.',
              style: GoogleFonts.roboto(color: GColors.textSecondary),
            ),
          );
        }
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['aktif'] != false;
        }).toList();
        if (docs.isEmpty) {
          return _BosEkran(
            icon: Icons.flight,
            mesaj: 'Henüz taşıyıcı ilanı yok.',
            altMesaj: 'İlk ilanı sen ver!',
            renk: GColors.blue,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
    final isim = data['kullaniciAd'] ?? 'Kullanıcı';

    return GestureDetector(
      onTap: () => _ilanDetayGoster(context, docId, data, tip: 'tasiyici'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: GColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _avatarRenk(isim),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isim[0].toUpperCase(),
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isim,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: GColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.flight_takeoff,
                            size: 13, color: Color(0xFF43A047)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${data['nereden'] ?? ''} → ${data['nereye'] ?? ''}',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: GColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (data['ucret'] != null && data['ucret'] != '')
                          _Chip(
                            label: '₺${data['ucret']}',
                            icon: Icons.payments_outlined,
                            bgColor: GColors.chipBg,
                            textColor: GColors.textSecondary,
                          ),
                        const Spacer(),
                        if (tarih != null)
                          _Chip(
                            label: _gunFarki(tarih),
                            icon: Icons.calendar_today_outlined,
                            bgColor: const Color(0xFFE8F5E9),
                            textColor: const Color(0xFF2E7D32),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: GColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── İstek Kartı ───────────────────────────────────────────

class _IsteklerTab extends StatelessWidget {
  const _IsteklerTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ilanlar')
          .where('tip', isEqualTo: 'istek')
          .orderBy('olusturmaTarihi', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: GColors.blue, strokeWidth: 2),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Bir hata oluştu.',
                style: GoogleFonts.roboto(color: GColors.textSecondary)),
          );
        }
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['aktif'] != false;
        }).toList();
        if (docs.isEmpty) {
          return _BosEkran(
            icon: Icons.shopping_bag_outlined,
            mesaj: 'Henüz istek ilanı yok.',
            altMesaj: 'İlk isteği sen oluştur!',
            renk: GColors.green,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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

    return GestureDetector(
      onTap: () => _ilanDetayGoster(context, docId, data, tip: 'istek'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: GColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _avatarRenk(isim),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isim[0].toUpperCase(),
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isim,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: GColors.textPrimary,
                            ),
                          ),
                        ),
                        if (data['ucret'] != null && data['ucret'] != '')
                          Text(
                            '₺${data['ucret']}',
                            style: GoogleFonts.roboto(
                              color: GColors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data['urun'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: GColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data['nereden'] ?? ''}' ,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!benimIlanim)
                _OutlineButton(
                  label: 'Getiririm',
                  color: GColors.green,
                  onTap: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      loginGerekli(context);
                      return;
                    }
                    _getiririmPopupGoster(context, docId, data);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Getiririm Popup ───────────────────────────────────────

void _getiririmPopupGoster(BuildContext context, String docId, Map<String, dynamic> ilanData) {
  final kullaniciId = ilanData['kullaniciId'] ?? '';
  final kullaniciAd = ilanData['kullaniciAd'] ?? 'Kullanıcı';
  final ilanBaslik = ilanData['urun'] ?? 'İstek';

  showModalBottomSheet(
    context: context,
    backgroundColor: GColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(kullaniciId)
            .snapshots(),
        builder: (context, snapshot) {
          final profil = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final adSoyad = profil['adSoyad'] ?? kullaniciAd;
          final sehir = profil['sehir'] ?? '';
          final telefon = profil['telefon'] ?? '';
          final email = profil['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
          final notlar = profil['notlar'] ?? '';

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: GColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              // Avatar + isim
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _avatarRenk(adSoyad),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(adSoyad[0].toUpperCase(),
                          style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adSoyad,
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600, fontSize: 16,
                              color: GColors.textPrimary)),
                      Text('İlan Sahibi',
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: GColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: GColors.divider),
              const SizedBox(height: 16),
              // Bilgiler
              if (sehir.isNotEmpty)
                _ProfilBilgiSatiri(icon: Icons.location_on_outlined, deger: sehir),
              if (telefon.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ProfilBilgiSatiri(icon: Icons.phone_outlined, deger: telefon),
              ],
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ProfilBilgiSatiri(icon: Icons.email_outlined, deger: email),
              ],
              if (notlar.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ProfilBilgiSatiri(icon: Icons.info_outline, deger: notlar),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SohbetScreen(
                          karsiKullaniciId: kullaniciId,
                          karsiKullaniciAd: adSoyad,
                          ilanId: docId,
                          ilanBaslik: ilanBaslik,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white, size: 18),
                  label: Text('Mesaj Gönder',
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GColors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _ProfilBilgiSatiri extends StatelessWidget {
  final IconData icon;
  final String deger;
  const _ProfilBilgiSatiri({required this.icon, required this.deger});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: GColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(deger,
              style: GoogleFonts.roboto(
                  fontSize: 14, color: GColors.textPrimary)),
        ),
      ],
    );
  }
}

// ── Mesajlar Sayfası ──────────────────────────────────────

class _MesajlarPage extends StatelessWidget {
  const _MesajlarPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: GColors.surface,
      appBar: AppBar(
        backgroundColor: GColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GColors.divider,
        title: Text(
          'Mesajlar',
          style: GoogleFonts.roboto(
            color: GColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: user == null
          ? _GirisGerekli(
              icon: Icons.chat_bubble_outline,
              mesaj: 'Mesajları görmek için giriş yapın.',
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sohbetler')
                  .where('kullanicilar', arrayContains: user.uid)
                  .orderBy('sonMesajZamani', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: GColors.blue, strokeWidth: 2),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _BosEkran(
                    icon: Icons.chat_bubble_outline,
                    mesaj: 'Henüz mesajınız yok.',
                    altMesaj: 'İlanlara tıklayarak iletişime geçebilirsiniz.',
                    renk: GColors.blue,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final kullaniciAdlari =
                        data['kullaniciAdlari'] as Map<String, dynamic>? ?? {};
                    final kullanicilar =
                        List<String>.from(data['kullanicilar'] ?? []);
                    final karsiId = kullanicilar.firstWhere(
                      (id) => id != user.uid,
                      orElse: () => '',
                    );
                    final karsiAd = kullaniciAdlari[karsiId] ?? 'Kullanıcı';
                    final sonMesaj = data['sonMesaj'] ?? '';
                    final ilanBaslik = data['ilanBaslik'] ?? '';
                    final okunmamisSayisi = ((data['okunmamis'] as Map<String, dynamic>?)?[user.uid] as int?) ?? 0;
                    final okunmamis = okunmamisSayisi > 0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SohbetScreen(
                              karsiKullaniciId: karsiId,
                              karsiKullaniciAd: karsiAd,
                              ilanId: data['ilanId'] ?? '',
                              ilanBaslik: ilanBaslik,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: GColors.white,
                          border: okunmamis ? const Border(
                            left: BorderSide(color: GColors.red, width: 3),
                          ) : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _avatarRenk(karsiAd),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    karsiAd[0].toUpperCase(),
                                    style: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(karsiAd,
                                              style: GoogleFonts.roboto(
                                                fontWeight: okunmamis ? FontWeight.w700 : FontWeight.w500,
                                                fontSize: 14,
                                                color: GColors.textPrimary,
                                              )),
                                        ),
                                        if (okunmamis)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: GColors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(ilanBaslik,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: GColors.blue,
                                        )),
                                    const SizedBox(height: 2),
                                    Text(
                                      sonMesaj.isEmpty
                                          ? 'Henüz mesaj yok'
                                          : sonMesaj,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: 13,
                                        fontWeight: okunmamis ? FontWeight.w600 : FontWeight.w400,
                                        color: okunmamis ? GColors.textPrimary : GColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ── Favoriler Sayfası ─────────────────────────────────────

class _FavorilerPage extends StatelessWidget {
  const _FavorilerPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: GColors.surface,
      appBar: AppBar(
        backgroundColor: GColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GColors.divider,
        title: Text(
          'Favorilerim',
          style: GoogleFonts.roboto(
            color: GColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: user == null
          ? _GirisGerekli(
              icon: Icons.bookmark_outline,
              mesaj: 'Favorileri görmek için giriş yapın.',
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('favoriler')
                  .where('kullaniciId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: GColors.blue, strokeWidth: 2),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _BosEkran(
                    icon: Icons.bookmark_outline,
                    mesaj: 'Henüz favori eklemediniz.',
                    altMesaj: 'İlanlara tıklayarak favoriye ekleyebilirsiniz.',
                    renk: GColors.yellow,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tip = data['tip'] ?? 'tasiyici';
                    final isim = data['kullaniciAd'] ?? 'Kullanıcı';
                    final baslik = tip == 'tasiyici'
                        ? '${data['nereden']} → ${data['nereye']}'
                        : data['urun'] ?? '';

                    return GestureDetector(
                      onTap: () => _ilanDetayGoster(
                          context, data['ilanId'] ?? doc.id, data,
                          tip: tip),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: GColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GColors.divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _kullaniciProfilGoster(
                                    context, data['kullaniciId'] ?? '', isim),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _avatarRenk(isim),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isim[0].toUpperCase(),
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tip == 'tasiyici'
                                          ? '✈️ Taşıyıcı'
                                          : '🛍️ İstek',
                                      style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        color: GColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      baslik,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: GColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      isim,
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: GColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (data['kullaniciId'] !=
                                  FirebaseAuth.instance.currentUser?.uid)
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline,
                                      color: GColors.blue, size: 20),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SohbetScreen(
                                          karsiKullaniciId:
                                              data['kullaniciId'] ?? '',
                                          karsiKullaniciAd: isim,
                                          ilanId: data['ilanId'] ?? doc.id,
                                          ilanBaslik: baslik,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.bookmark,
                                    color: GColors.textSecondary, size: 20),
                                onPressed: () async {
                                  final onay = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                      title: Text('Favoriden çıkar?',
                                          style: GoogleFonts.roboto(
                                              fontSize: 16, fontWeight: FontWeight.w500)),
                                      content: Text('Bu ilanı favorilerden kaldırmak istediğine emin misin?',
                                          style: GoogleFonts.roboto(
                                              fontSize: 14, color: GColors.textSecondary)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('İPTAL',
                                              style: GoogleFonts.roboto(
                                                  color: GColors.textSecondary,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text('KALDIR',
                                              style: GoogleFonts.roboto(
                                                  color: GColors.red,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (onay == true) {
                                    await FirebaseFirestore.instance
                                        .collection('favoriler')
                                        .doc(doc.id)
                                        .delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Favorilerden kaldırıldı.',
                                              style: GoogleFonts.roboto()),
                                          backgroundColor: GColors.textPrimary,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ── Profil Sayfası ────────────────────────────────────────

class _ProfilPage extends StatelessWidget {
  const _ProfilPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: GColors.surface,
      appBar: AppBar(
        backgroundColor: GColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: GColors.divider,
        title: Text(
          'Profilim',
          style: GoogleFonts.roboto(
            color: GColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: GColors.textSecondary),
            onPressed: () async {
              final onay = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  title: Text('Çıkış yap?',
                      style: GoogleFonts.roboto(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  content: Text(
                    'Hesabından çıkmak istediğine emin misin?',
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: GColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('İPTAL',
                          style: GoogleFonts.roboto(
                              color: GColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('ÇIKIŞ YAP',
                          style: GoogleFonts.roboto(
                              color: GColors.red,
                              fontWeight: FontWeight.w600)),
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
          final profilData =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final adSoyad =
              profilData['adSoyad'] ?? user?.displayName ?? 'Kullanıcı';
          final sehir = profilData['sehir'] ?? '';
          final telefon = profilData['telefon'] ?? '';
          final fotoUrl = profilData['fotoUrl'] as String?;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profil header
                Container(
                  color: GColors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _profilFotoYukle(context, user?.uid),
                        child: Stack(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: _avatarRenk(adSoyad),
                                shape: BoxShape.circle,
                              ),
                              child: fotoUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        fotoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            adSoyad[0].toUpperCase(),
                                            style: GoogleFonts.roboto(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        adSoyad[0].toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: GColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adSoyad,
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: GColors.textPrimary,
                                )),
                            const SizedBox(height: 2),
                            Text(user?.email ?? '',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: GColors.textSecondary,
                                )),
                            if (sehir.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 13, color: GColors.textHint),
                                  const SizedBox(width: 2),
                                  Text(sehir,
                                      style: GoogleFonts.roboto(
                                          color: GColors.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                            if (telefon.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined,
                                      size: 13, color: GColors.textHint),
                                  const SizedBox(width: 2),
                                  Text(telefon,
                                      style: GoogleFonts.roboto(
                                          color: GColors.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _profilDuzenle(context, user?.uid, profilData),
                        icon: const Icon(Icons.edit_outlined,
                            color: GColors.blue, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // İlanlarım (Aktif)
                Container(
                  color: GColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'İLANLARIM',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: GColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ilanlar')
                      .where('kullaniciId', isEqualTo: user?.uid)
                      .orderBy('olusturmaTarihi', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: GColors.blue, strokeWidth: 2),
                        ),
                      );
                    }
                    final tumDocs = snap.data?.docs ?? [];
                    // aktif: true olanlar + aktif alanı hiç set edilmemişler
                    final docs = tumDocs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return d['aktif'] != false;
                    }).toList();
                    if (docs.isEmpty) {
                      return Container(
                        color: GColors.white,
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Aktif ilanınız yok.',
                            style: GoogleFonts.roboto(
                                color: GColors.textSecondary),
                          ),
                        ),
                      );
                    }
                    return Container(
                      color: GColors.white,
                      child: Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final tip = data['tip'] == 'tasiyici'
                              ? '✈️ Taşıyıcı'
                              : '🛍️ İstek';
                          final baslik = data['tip'] == 'tasiyici'
                              ? '${data['nereden']} → ${data['nereye']}'
                              : data['urun'] ?? '';
                          return Column(
                            children: [
                              const Divider(height: 1, color: GColors.divider),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(tip,
                                              style: GoogleFonts.roboto(
                                                  fontSize: 12,
                                                  color: GColors.textSecondary)),
                                          const SizedBox(height: 2),
                                          Text(baslik,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: GColors.textPrimary,
                                              )),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          ilanMenuGoster(context, doc.id, data),
                                      icon: const Icon(Icons.more_vert,
                                          color: GColors.textHint, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Pasif İlanlarım
                Container(
                  color: GColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'PASİF İLANLARIM',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: GColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ilanlar')
                      .where('kullaniciId', isEqualTo: user?.uid)
                      .orderBy('olusturmaTarihi', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    final tumDocs = snap.data?.docs ?? [];
                    // sadece aktif: false olanlar (null veya true olanlar aktif sayılır)
                    final docs = tumDocs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return d['aktif'] == false;
                    }).toList();
                    if (docs.isEmpty) {
                      return Container(
                        color: GColors.white,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Pasif ilanınız yok.',
                            style: GoogleFonts.roboto(
                                color: GColors.textHint, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return Container(
                      color: GColors.white,
                      child: Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final tip = data['tip'] == 'tasiyici'
                              ? '✈️ Taşıyıcı'
                              : '🛍️ İstek';
                          final baslik = data['tip'] == 'tasiyici'
                              ? '${data['nereden']} → ${data['nereye']}'
                              : data['urun'] ?? '';
                          return Opacity(
                            opacity: 0.6,
                            child: Column(
                              children: [
                                const Divider(height: 1, color: GColors.divider),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(tip,
                                                style: GoogleFonts.roboto(
                                                    fontSize: 12,
                                                    color: GColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            Text(baslik,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.roboto(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: GColors.textPrimary,
                                                )),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _pasifIlanMenuGoster(
                                            context, doc.id),
                                        icon: const Icon(Icons.more_vert,
                                            color: GColors.textHint, size: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
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

    final adController =
        TextEditingController(text: mevcutData['adSoyad'] ?? '');
    final sehirController =
        TextEditingController(text: mevcutData['sehir'] ?? '');
    final telefonController =
        TextEditingController(text: mevcutData['telefon'] ?? '');
    final notlarController =
        TextEditingController(text: mevcutData['notlar'] ?? '');
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: GColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Profili Düzenle',
                  style: GoogleFonts.roboto(
                      fontSize: 17, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              _DuzenleAlani(label: 'Ad Soyad', controller: adController),
              const SizedBox(height: 12),
              _DuzenleAlani(
                label: 'E-posta',
                controller: TextEditingController(text: email),
                readonly: true,
              ),
              const SizedBox(height: 12),
              _DuzenleAlani(
                  label: 'Şehir / Ülke', controller: sehirController),
              const SizedBox(height: 12),
              _DuzenleAlani(
                  label: 'Telefon',
                  controller: telefonController,
                  klavye: TextInputType.phone),
              const SizedBox(height: 12),
              _DuzenleAlani(
                  label: 'Hakkımda',
                  controller: notlarController,
                  maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
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
                        SnackBar(
                          content: Text('Profil güncellendi!',
                              style: GoogleFonts.roboto()),
                          backgroundColor: GColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GColors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Kaydet',
                      style: GoogleFonts.roboto(
                          color: GColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── İlan Detay ────────────────────────────────────────────

void _ilanDetayGoster(BuildContext context, String docId,
    Map<String, dynamic> data,
    {required String tip}) {
  final isim = data['kullaniciAd'] ?? 'Kullanıcı';
  final tarih = (data['tarih'] as Timestamp?)?.toDate();
  final tarihYazi =
      tarih != null ? '${tarih.day}.${tarih.month}.${tarih.year}' : '';
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  final benimIlanim = currentUid != null && currentUid == data['kullaniciId'];
  final renk = tip == 'tasiyici' ? const Color(0xFF43A047) : GColors.primary;

  showModalBottomSheet(
    context: context,
    backgroundColor: GColors.white,
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: GColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: _avatarRenk(isim), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    isim[0].toUpperCase(),
                    style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isim,
                      style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w500, fontSize: 16)),
                  Text(
                    tip == 'tasiyici' ? '✈️ Taşıyıcı' : '🛍️ İstek',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: GColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: GColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nereden',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: GColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(data['nereden'] ?? '',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: renk, size: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Nereye',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: GColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(data['nereye'] ?? '',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          if (tip == 'istek' &&
              data['urun'] != null &&
              data['urun'] != '') ...[
            const SizedBox(height: 16),
            Text('Ürün',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: GColors.textSecondary)),
            const SizedBox(height: 4),
            Text(data['urun'],
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500, fontSize: 15)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (tarihYazi.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarih',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: GColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(tarihYazi,
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                  ],
                ),
              const Spacer(),
              if (data['ucret'] != null && data['ucret'] != '')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Ücret',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: GColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('₺${data['ucret']}',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: renk)),
                  ],
                ),
            ],
          ),
          if (data['notlar'] != null && data['notlar'] != '') ...[
            const SizedBox(height: 16),
            Text('Notlar',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: GColors.textSecondary)),
            const SizedBox(height: 4),
            Text(data['notlar'],
                style: GoogleFonts.roboto(
                    fontSize: 14, color: GColors.textPrimary)),
          ],
          const SizedBox(height: 24),
          if (!benimIlanim)
            Row(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseAuth.instance.currentUser == null
                      ? const Stream.empty()
                      : FirebaseFirestore.instance
                          .collection('favoriler')
                          .where('kullaniciId',
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser!.uid)
                          .where('ilanId', isEqualTo: docId)
                          .snapshots(),
                  builder: (context, snap) {
                    final favori = (snap.data?.docs ?? []).isNotEmpty;
                    return IconButton(
                      icon: Icon(
                        favori ? Icons.bookmark : Icons.bookmark_outline,
                        color: favori ? GColors.yellow : GColors.textSecondary,
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Favorilere eklendi!',
                                    style: GoogleFonts.roboto()),
                                backgroundColor: GColors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      Navigator.pop(context);
                      if (user == null) {
                        loginGerekli(context);
                        return;
                      }
                      _getiririmPopupGoster(context, docId, data);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GColors.textSecondary,
                      side: const BorderSide(color: GColors.divider, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      tip == 'tasiyici' ? 'İletişime Geç' : 'Ben Getirebilirim',
                      style: GoogleFonts.roboto(
                          color: GColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

// ── İlan Menü / Sil / Düzenle ─────────────────────────────

Future<void> _profilFotoYukle(BuildContext context, String? uid) async {
  if (uid == null) return;
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profil_fotolari')
        .child('$uid.jpg');
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .set({'fotoUrl': url}, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil fotoğrafı güncellendi!',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf yüklenemedi.',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: GColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

void ilanMenuGoster(BuildContext context, String docId,
    Map<String, dynamic> data) {
  final mevcutKullanici = FirebaseAuth.instance.currentUser;
  final bool benimIlanim = mevcutKullanici?.uid == data['kullaniciId'];
  if (!benimIlanim) return;

  showModalBottomSheet(
    context: context,
    backgroundColor: GColors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: GColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading:
                const Icon(Icons.edit_outlined, color: GColors.textSecondary),
            title: Text('Düzenle',
                style: GoogleFonts.roboto(fontSize: 15)),
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
              color: GColors.textSecondary,
            ),
            title: Text(
              data['aktif'] == false ? 'Aktif Et' : 'Pasife Al',
              style: GoogleFonts.roboto(fontSize: 15),
            ),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('ilanlar')
                  .doc(docId)
                  .update({'aktif': data['aktif'] == false ? true : false});
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: GColors.red),
            title: Text('Sil',
                style: GoogleFonts.roboto(
                    fontSize: 15, color: GColors.red)),
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

void _pasifIlanMenuGoster(BuildContext context, String docId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: GColors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: GColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.visibility_outlined, color: GColors.textSecondary),
            title: Text('Tekrar Yayınla',
                style: GoogleFonts.roboto(fontSize: 15)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('ilanlar')
                  .doc(docId)
                  .update({'aktif': true});
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: GColors.red),
            title: Text('Sil',
                style: GoogleFonts.roboto(fontSize: 15, color: GColors.red)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text('İlanı sil?',
          style: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.w500)),
      content: Text('Bu işlem geri alınamaz.',
          style: GoogleFonts.roboto(
              fontSize: 14, color: GColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İPTAL',
              style: GoogleFonts.roboto(
                  color: GColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await FirebaseFirestore.instance
                .collection('ilanlar')
                .doc(docId)
                .delete();
          },
          child: Text('SİL',
              style: GoogleFonts.roboto(
                  color: GColors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

void ilanDuzenle(BuildContext context, String docId,
    Map<String, dynamic> data) {
  final neredenController =
      TextEditingController(text: data['nereden']);
  final nereyeController =
      TextEditingController(text: data['nereye']);
  final ucretController =
      TextEditingController(text: data['ucret']);
  final urunController =
      TextEditingController(text: data['urun'] ?? '');
  final notlarController =
      TextEditingController(text: data['notlar'] ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: GColors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: GColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('İlanı Düzenle',
                style: GoogleFonts.roboto(
                    fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            _DuzenleAlani(label: 'Nereden', controller: neredenController),
            const SizedBox(height: 12),
            _DuzenleAlani(label: 'Nereye', controller: nereyeController),
            const SizedBox(height: 12),
            _DuzenleAlani(
                label: 'Ücret (₺)',
                controller: ucretController,
                klavye: TextInputType.number),
            if (data['tip'] == 'istek') ...[
              const SizedBox(height: 12),
              _DuzenleAlani(
                  label: 'Ürün Adı', controller: urunController),
            ],
            const SizedBox(height: 12),
            _DuzenleAlani(
                label: 'Notlar', controller: notlarController, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final guncelleme = {
                    'nereden': neredenController.text.trim(),
                    'nereye': nereyeController.text.trim(),
                    'ucret': ucretController.text.trim(),
                    'notlar': notlarController.text.trim(),
                    if (data['tip'] == 'istek')
                      'urun': urunController.text.trim(),
                  };
                  await FirebaseFirestore.instance
                      .collection('ilanlar')
                      .doc(docId)
                      .update(guncelleme);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('İlan güncellendi!',
                            style: GoogleFonts.roboto()),
                        backgroundColor: GColors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GColors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Kaydet',
                    style: GoogleFonts.roboto(
                        color: GColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Kullanıcı Profil Dialog ───────────────────────────────

void _kullaniciProfilGoster(BuildContext context, String kullaniciId, String isim) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kullanicilar')
                  .doc(kullaniciId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final adSoyad = data['adSoyad'] ?? isim;
                final sehir = data['sehir'] ?? '';
                final telefon = data['telefon'] ?? '';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: _avatarRenk(adSoyad), shape: BoxShape.circle),
                      child: Center(
                        child: Text(adSoyad[0].toUpperCase(),
                            style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 30)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(adSoyad,
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w500, fontSize: 18)),
                    if (sehir.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: GColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(sehir,
                              style: GoogleFonts.roboto(
                                  color: GColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                    if (telefon.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 14, color: GColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(telefon,
                              style: GoogleFonts.roboto(
                                  color: GColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SohbetScreen(
                                karsiKullaniciId: kullaniciId,
                                karsiKullaniciAd: adSoyad,
                                ilanId: 'profil_$kullaniciId',
                                ilanBaslik: 'Genel Sohbet',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: GColors.white, size: 16),
                        label: Text('İletişime Geç',
                            style: GoogleFonts.roboto(
                                color: GColors.white,
                                fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GColors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
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
              icon: const Icon(Icons.close, color: GColors.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Yardımcı Widget'lar ───────────────────────────────────

class _BosEkran extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  final String altMesaj;
  final Color renk;
  const _BosEkran({
    required this.icon,
    required this.mesaj,
    required this.altMesaj,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: GColors.divider),
          const SizedBox(height: 16),
          Text(mesaj,
              style: GoogleFonts.roboto(
                  color: GColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 4),
          Text(altMesaj,
              style: GoogleFonts.roboto(
                  color: GColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }
}

class _GirisGerekli extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  const _GirisGerekli({required this.icon, required this.mesaj});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: GColors.divider),
          const SizedBox(height: 16),
          Text(mesaj,
              style: GoogleFonts.roboto(
                  color: GColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => loginGerekli(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: GColors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text('Giriş Yap',
                style: GoogleFonts.roboto(
                    color: GColors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  const _Chip({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: GoogleFonts.roboto(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _DuzenleAlani extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType klavye;
  final int maxLines;
  final bool readonly;

  const _DuzenleAlani({
    required this.label,
    required this.controller,
    this.klavye = TextInputType.text,
    this.maxLines = 1,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: GColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: klavye,
          maxLines: maxLines,
          readOnly: readonly,
          style: GoogleFonts.roboto(fontSize: 14, color: GColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: readonly ? GColors.surface : GColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: GColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: GColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: GColors.blue, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Floating Nav Bar ─────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: GColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Ana Sayfa', index: 0, currentIndex: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.bookmark_outline, activeIcon: Icons.bookmark, label: 'Favoriler', index: 1, currentIndex: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'İlan Ver', index: 2, currentIndex: currentIndex, onTap: onTap),
          _NavItemBadge(index: 3, currentIndex: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', index: 4, currentIndex: currentIndex, onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final aktif = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              aktif ? activeIcon : icon,
              size: 24,
              color: aktif ? const Color(0xFF757575) : GColors.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                color: aktif ? const Color(0xFF757575) : GColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemBadge extends StatefulWidget {
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _NavItemBadge({required this.index, required this.currentIndex, required this.onTap});

  @override
  State<_NavItemBadge> createState() => _NavItemBadgeState();
}

class _NavItemBadgeState extends State<_NavItemBadge> {
  int _okunmamis = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('sohbetler')
          .where('kullanicilar', arrayContains: user.uid)
          .snapshots()
          .listen((snapshot) {
        int toplam = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final okunmamis = data['okunmamis'] as Map<String, dynamic>?;
          if (okunmamis != null) {
            toplam += (okunmamis[user.uid] as int? ?? 0);
          }
        }
        if (mounted) setState(() => _okunmamis = toplam);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aktif = widget.currentIndex == widget.index;
    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  aktif ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  size: 24,
                  color: aktif ? const Color(0xFF757575) : GColors.textHint,
                ),
                if (_okunmamis > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: GColors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _okunmamis > 99 ? '99+' : '$_okunmamis',
                        style: const TextStyle(color: GColors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Mesajlar',
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                color: aktif ? const Color(0xFF757575) : GColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mesaj Badge (eski - artık kullanılmıyor) ──────────────

class _MesajBadge extends StatefulWidget {
  final bool aktif;
  const _MesajBadge({required this.aktif});

  @override
  State<_MesajBadge> createState() => _MesajBadgeState();
}

class _MesajBadgeState extends State<_MesajBadge> {
  int _okunmamis = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('sohbetler')
          .where('kullanicilar', arrayContains: user.uid)
          .snapshots()
          .listen((snapshot) {
        int toplam = 0;
        final uid = user.uid;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final okunmamis = data['okunmamis'] as Map<String, dynamic>?;
          if (okunmamis != null) {
            toplam += (okunmamis[uid] as int? ?? 0);
          }
        }
        if (mounted) setState(() => _okunmamis = toplam);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.aktif ? Icons.chat_bubble : Icons.chat_bubble_outline,
    );
    if (_okunmamis == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: GColors.red, shape: BoxShape.circle),
            constraints:
                const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              _okunmamis > 99 ? '99+' : '$_okunmamis',
              style: const TextStyle(
                  color: GColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}












