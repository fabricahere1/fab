import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'g_colors.dart';
import 'profil_karti_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'degerlendirme_screen.dart';
import 'register_screen.dart';
import '../auth_gate.dart';
 
class IlanlarPage extends StatefulWidget {
  final ValueChanged<int> onTabChanged;
  final TabController tabController;
  const IlanlarPage(
      {super.key,
      required this.onTabChanged,
      required this.tabController});
 
  @override
  State<IlanlarPage> createState() => _IlanlarPageState();
}
 
class _IlanlarPageState extends State<IlanlarPage> {
  late TabController _tabController;
 
  @override
  void initState() {
    super.initState();
    _tabController = widget.tabController;
  }
 
  @override
  void dispose() {
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
        title: Text(
          'İSTE',
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: GColors.red,
            letterSpacing: 2,
          ),
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
                    onTap: () => widget.onTabChanged(3),
                    child: avatarWidget(
                        isim: isim,
                        fotoUrl: user.photoURL,
                        radius: 17,
                        fontSize: 13),
                  ),
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => loginGerekli(context),
                    child: Text('Giriş Yap',
                        style: GoogleFonts.dmSans(
                            color: GColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      style: TextButton.styleFrom(
                        backgroundColor: GColors.chipBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                      ),
                      child: Text('Kayıt Ol',
                          style: GoogleFonts.dmSans(
                              color: GColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: GColors.divider, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: GColors.textPrimary,
              unselectedLabelColor: GColors.textSecondary,
              indicatorColor: GColors.red,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
              tabs: const [
                Tab(text: '🛍️  İstiyorum'),
                Tab(text: '✈️  Geliyorum'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MasonryBoard(tip: 'istek'),
          _MasonryBoard(tip: 'tasiyici'),
        ],
      ),
    );
  }
}
 
// ── Masonry Board ─────────────────────────────────────────
 
class _MasonryBoard extends StatefulWidget {
  final String tip;
  const _MasonryBoard({required this.tip});
 
  @override
  State<_MasonryBoard> createState() => _MasonryBoardState();
}
 
class _MasonryBoardState extends State<_MasonryBoard> {
  static const int _sayfaBoyutu = 20;
  final List<QueryDocumentSnapshot> _docs = [];
  final ScrollController _scrollController = ScrollController();
  bool _yukleniyor = false;
  bool _hepsiyuklendi = false;
  DocumentSnapshot? _sonDoc;
  String _siralama = 'tarih';
 
  @override
  void initState() {
    super.initState();
    _ilkYukle();
    _scrollController.addListener(_scrollDinle);
  }
 
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
 
  void _scrollDinle() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _dahaFazlaYukle();
    }
  }
 
  Future<void> _ilkYukle() async {
    if (_yukleniyor) return;
    setState(() => _yukleniyor = true);
    try {
      List<QueryDocumentSnapshot> yeniDocs = [];
 
      if (widget.tip == 'tasiyici' && _siralama == 'tarih') {
        final bugun = Timestamp.fromDate(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day));
        final gelecek = await FirebaseFirestore.instance
            .collection('ilanlar')
            .where('tip', isEqualTo: widget.tip)
            .where('aktif', isEqualTo: true)
            .where('tarih', isGreaterThanOrEqualTo: bugun)
            .orderBy('tarih', descending: false)
            .limit(_sayfaBoyutu)
            .get();
        final gecmis = await FirebaseFirestore.instance
            .collection('ilanlar')
            .where('tip', isEqualTo: widget.tip)
            .where('aktif', isEqualTo: true)
            .where('tarih', isLessThan: bugun)
            .orderBy('tarih', descending: true)
            .limit(10)
            .get();
        yeniDocs = [...gelecek.docs, ...gecmis.docs];
        _sonDoc = gelecek.docs.isNotEmpty ? gelecek.docs.last : null;
        _hepsiyuklendi = gelecek.docs.length < _sayfaBoyutu;
      } else {
        final query = await FirebaseFirestore.instance
            .collection('ilanlar')
            .where('tip', isEqualTo: widget.tip)
            .where('aktif', isEqualTo: true)
            .orderBy('olusturmaTarihi', descending: true)
            .limit(_sayfaBoyutu)
            .get();
        yeniDocs = query.docs;
        _sonDoc = query.docs.isNotEmpty ? query.docs.last : null;
        _hepsiyuklendi = query.docs.length < _sayfaBoyutu;
      }
 
      if (mounted) {
        setState(() {
          _docs.addAll(yeniDocs);
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _yukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlanlar yüklenirken hata oluştu.')),
        );
      }
    }
  }
 
  Future<void> _dahaFazlaYukle() async {
    if (_yukleniyor || _hepsiyuklendi || _sonDoc == null) return;
    setState(() => _yukleniyor = true);
    try {
      final orderField =
          (widget.tip == 'tasiyici' && _siralama == 'tarih')
              ? 'tarih'
              : 'olusturmaTarihi';
      final query = await FirebaseFirestore.instance
          .collection('ilanlar')
          .where('tip', isEqualTo: widget.tip)
          .where('aktif', isEqualTo: true)
          .orderBy(orderField, descending: orderField == 'olusturmaTarihi')
          .startAfterDocument(_sonDoc!)
          .limit(_sayfaBoyutu)
          .get();
      if (mounted) {
        setState(() {
          _docs.addAll(query.docs);
          _sonDoc = query.docs.isNotEmpty ? query.docs.last : _sonDoc;
          _hepsiyuklendi = query.docs.length < _sayfaBoyutu;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _yukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daha fazla ilan yüklenemedi.')),
        );
      }
    }
  }
 
  Future<void> _yenile() async {
    setState(() {
      _docs.clear();
      _sonDoc = null;
      _hepsiyuklendi = false;
    });
    await _ilkYukle();
  }
 
  @override
  Widget build(BuildContext context) {
    if (_yukleniyor && _docs.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
              color: GColors.red, strokeWidth: 2));
    }
 
    if (_docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.tip == 'istek' ? '🛍️' : '✈️',
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              widget.tip == 'istek'
                  ? 'Henüz istek ilanı yok.'
                  : 'Henüz gelen ilanı yok.',
              style: GoogleFonts.dmSans(
                  color: GColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }
 
    if (widget.tip == 'tasiyici') {
      return RefreshIndicator(
        color: GColors.red,
        onRefresh: _yenile,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount:
              _docs.length + 1 + (_yukleniyor || _hepsiyuklendi ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: GColors.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16))),
                          builder: (_) => Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 36,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE0E0E0),
                                        borderRadius:
                                            BorderRadius.circular(2)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Sıralama',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF777777),
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                const Divider(color: Color(0xFFEEEEEE)),
                                _SiralaSecenegi(
                                  label: 'Gelmesine en az gün kalan',
                                  secili: _siralama == 'tarih',
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (_siralama != 'tarih') {
                                      setState(() => _siralama = 'tarih');
                                      _yenile();
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                _SiralaSecenegi(
                                  label: 'İlan giriş tarihine göre',
                                  secili: _siralama == 'olusturma',
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (_siralama != 'olusturma') {
                                      setState(
                                          () => _siralama = 'olusturma');
                                      _yenile();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: GColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort,
                                size: 16, color: GColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              _siralama == 'tarih'
                                  ? 'En yakın tarih'
                                  : 'Giriş tarihi',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: GColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
 
            final realIndex = index - 1;
            if (realIndex == _docs.length) {
              if (_yukleniyor) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: GColors.red, strokeWidth: 2)),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Tüm ilanlar yüklendi.',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: GColors.textHint)),
                ),
              );
            }
            final doc = _docs[realIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _IlanKarti(
                docId: doc.id,
                data: doc.data() as Map<String, dynamic>,
                tip: widget.tip,
              ),
            );
          },
        ),
      );
    }
 
    return RefreshIndicator(
      color: GColors.red,
      onRefresh: _yenile,
      child: MasonryGridView.count(
        controller: _scrollController,
        crossAxisCount: 2,
        mainAxisSpacing: 0,
        crossAxisSpacing: 6,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 80),
        itemCount: _docs.length + (_yukleniyor || _hepsiyuklendi ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _docs.length) {
            if (_yukleniyor) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: GColors.red, strokeWidth: 2)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text('Tüm ilanlar yüklendi.',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: GColors.textHint))),
            );
          }
          final doc = _docs[index];
          final offset = (index == 1) ? 32.0 : 0.0;
          return Padding(
            padding: EdgeInsets.only(top: offset),
            child: _IlanKarti(
              docId: doc.id,
              data: doc.data() as Map<String, dynamic>,
              tip: widget.tip,
            ),
          );
        },
      ),
    );
  }
}
 
// ── İlan Kartı ────────────────────────────────────────────
 
class _IlanKarti extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String tip;
 
  const _IlanKarti({
    required this.docId,
    required this.data,
    required this.tip,
  });
 
  @override
  Widget build(BuildContext context) {
    final resimUrl = data['resimUrl'] as String?;
    final resimVar = resimUrl != null && resimUrl.isNotEmpty;
    final isim = data['kullaniciAd'] ?? 'Kullanıcı';
    final urun = data['urun'] ?? '';
    final nereden = data['nereden'] ?? '';
    final nereye = data['nereye'] ?? '';
    final ucret = data['ucret'] ?? '';
    final tarih = data['tarih'] as Timestamp?;
 
    return GestureDetector(
      onTap: () => _detayGoster(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: resimVar
            ? _ResimliKart(
                resimUrl: resimUrl,
                urun: urun,
                nereden: nereden,
                nereye: nereye,
                ucret: ucret,
                tip: tip,
                isim: isim,
                docId: docId)
            : _PlaceholderKart(
                isim: isim,
                nereden: nereden,
                nereye: nereye,
                ucret: ucret,
                tip: tip,
                urun: urun,
                docId: docId,
                tarih: tarih),
      ),
    );
  }
 
  Future<void> _detayGoster(BuildContext context) async {
    final resimUrl = data['resimUrl'] as String?;
    final resimVar = resimUrl != null && resimUrl.isNotEmpty;
    final isim = data['kullaniciAd'] ?? 'Kullanıcı';
    final kullaniciId = data['kullaniciId'] ?? '';
    final urun = data['urun'] ?? '';
    final nereden = data['nereden'] ?? '';
    final nereye = data['nereye'] ?? '';
    final ucret = data['ucret'] ?? '';
    final notlar = data['notlar'] ?? '';
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final benimIlanim = currentUid != null && currentUid == kullaniciId;
 
    if (!context.mounted) return;
 
    showModalBottomSheet(
      context: context,
      backgroundColor: GColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: GColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resimVar)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: resimUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          memCacheWidth: 800,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (_, __) =>
                              Container(height: 200, color: GColors.surface),
                          errorWidget: (_, __, ___) =>
                              Container(height: 200, color: GColors.surface),
                        ),
                      ),
                    if (resimVar) const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: GColors.chipBg,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        tip == 'tasiyici' ? '✈️  TAŞIYICI' : '🛍️  İSTEK',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: GColors.textSecondary,
                            letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (urun.isNotEmpty)
                      Text(urun,
                          style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: GColors.textPrimary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(nereden.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: GColors.textSecondary,
                                  letterSpacing: 1)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              color: GColors.red, size: 14),
                        ),
                        Flexible(
                          child: Text(nereye.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: GColors.red,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ),
                    if (ucret.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('₺$ucret',
                          style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: GColors.red)),
                    ],
                    Builder(builder: (context) {
                      final tarih = data['tarih'];
                      if (tarih == null) return const SizedBox.shrink();
                      final dt = (tarih as Timestamp).toDate();
                      final simdi = DateTime.now();
                      final fark = dt
                          .difference(DateTime(
                              simdi.year, simdi.month, simdi.day))
                          .inDays;
                      final String tarihStr;
                      if (fark < 0) {
                        tarihStr = 'Geçti';
                      } else if (fark == 0) {
                        tarihStr = 'Bugün geliyor';
                      } else if (fark == 1) {
                        tarihStr = 'Yarın geliyor';
                      } else {
                        tarihStr = '$fark gün sonra geliyor';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 14, color: GColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(tarihStr,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: GColors.textSecondary)),
                          ],
                        ),
                      );
                    }),
                    if (notlar.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(notlar,
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: GColors.textSecondary,
                              height: 1.5)),
                    ],
                    if (!benimIlanim) ...[
                      const SizedBox(height: 14),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseAuth.instance.currentUser == null
                            ? const Stream.empty()
                            : FirebaseFirestore.instance
                                .collection('favoriler')
                                .where('kullaniciId',
                                    isEqualTo: FirebaseAuth
                                        .instance.currentUser?.uid ?? '')
                                .where('ilanId', isEqualTo: docId)
                                .snapshots(),
                        builder: (context, snap) {
                          final favori =
                              (snap.data?.docs ?? []).isNotEmpty;
                          return GestureDetector(
                            onTap: () async {
                              final user =
                                  FirebaseAuth.instance.currentUser;
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
                                  'nereden': nereden,
                                  'nereye': nereye,
                                  'urun': urun,
                                  'ucret': ucret,
                                  if (resimUrl != null &&
                                      resimUrl.isNotEmpty)
                                    'resimUrl': resimUrl,
                                  'eklemeTarihi':
                                      FieldValue.serverTimestamp(),
                                });
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  favori
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                  color: favori
                                      ? GColors.yellow
                                      : GColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  favori ? 'Favorilerde' : 'Favoriye Ekle',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: favori
                                          ? GColors.yellow
                                          : GColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (!benimIlanim)
                      TextButton.icon(
                        style:
                            TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () {
                          Navigator.pop(context);
                          sikayetGonder(context,
                              hedefId: kullaniciId,
                              hedefAd: isim,
                              ilanId: docId);
                        },
                        icon: Icon(Icons.flag_outlined,
                            color: GColors.textHint, size: 14),
                        label: Text('Şikayet Et',
                            style: GoogleFonts.dmSans(
                                color: GColors.textHint, fontSize: 12)),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (!benimIlanim)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: GestureDetector(
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      Navigator.pop(context);
                      loginGerekli(context);
                      return;
                    }
                    await profilKartiGoster(
                      context,
                      kullaniciId: kullaniciId,
                      isim: isim,
                      docId: docId,
                      ilanTip: tip,
                      urun: urun,
                      nereden: nereden,
                      nereye: nereye,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        tip == 'istek'
                            ? '✈️  Ben Getiririm'
                            : '💬  İletişime Geç',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
 
// ── Resimli Kart ──────────────────────────────────────────
 
class _ResimliKart extends StatelessWidget {
  final String resimUrl, urun, nereden, nereye, ucret, tip, isim, docId;
 
  const _ResimliKart({
    required this.resimUrl,
    required this.urun,
    required this.nereden,
    required this.nereye,
    required this.ucret,
    required this.tip,
    required this.isim,
    required this.docId,
  });
 
  @override
  Widget build(BuildContext context) {
    const resimYukseklik = 160.0;
 
    return Container(
      decoration: BoxDecoration(
        color: GColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: resimYukseklik,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: resimUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (_, __) => Container(color: GColors.surface),
                    errorWidget: (_, __, ___) =>
                        Container(color: GColors.surface),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Text(tip == 'tasiyici' ? '✈️' : '🛍️',
                        style: const TextStyle(fontSize: 16)),
                  ),
                  if (ucret.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: GColors.red,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('₺$ucret',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (urun.isNotEmpty)
                  Text(urun,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: GColors.textPrimary,
                          height: 1.3)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(nereden.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: GColors.textSecondary,
                              letterSpacing: 0.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward,
                          size: 9, color: GColors.red),
                    ),
                    Flexible(
                      child: Text(nereye.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: GColors.red,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    avatarWidget(isim: isim, radius: 10, fontSize: 8),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(isim,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: GColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Placeholder Kart ──────────────────────────────────────
 
class _PlaceholderKart extends StatelessWidget {
  final String isim, nereden, nereye, ucret, tip, urun, docId;
  final Timestamp? tarih;
 
  const _PlaceholderKart({
    required this.isim,
    required this.nereden,
    required this.nereye,
    required this.ucret,
    required this.tip,
    required this.urun,
    required this.docId,
    this.tarih,
  });
 
  String _tarihYazi() {
    if (tarih == null) return '';
    final dt = tarih!.toDate();
    final simdi = DateTime.now();
    final fark =
        dt.difference(DateTime(simdi.year, simdi.month, simdi.day)).inDays;
    if (fark < 0) return 'Geçti';
    if (fark == 0) return 'Bugün geliyor';
    if (fark == 1) return 'Yarın geliyor';
    return '$fark gün sonra geliyor';
  }
 
  int _kalanGun() {
    if (tarih == null) return -1;
    final dt = tarih!.toDate();
    final simdi = DateTime.now();
    return dt
        .difference(DateTime(simdi.year, simdi.month, simdi.day))
        .inDays;
  }
 
  bool _yakinGeliyor() => _kalanGun() >= 0;
 
  @override
  Widget build(BuildContext context) {
    final tarihYazi = _tarihYazi();
 
    // ── Taşıyıcı kartı — Seçenek B stili ──────────────────
    if (tip == 'tasiyici') {
      final gun = _kalanGun();
      final tarihColor = tarihYazi == 'Geçti'
          ? GColors.textHint
          : const Color(0xFF3B6D11);
      final tarihBg = tarihYazi == 'Geçti'
          ? GColors.surface
          : const Color(0xFFEAF3DE);
 
      return Container(
        decoration: BoxDecoration(
          color: GColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GColors.divider),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Satır 1: şehirler + ücret
            Row(
              children: [
                Flexible(
                  child: Text(nereden.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GColors.textSecondary)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      size: 13, color: GColors.textSecondary),
                ),
                Flexible(
                  child: Text(nereye.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GColors.textSecondary)),
                ),
                if (ucret.isNotEmpty) ...[
                  const Spacer(),
                  Text('₺$ucret',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: GColors.textPrimary)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Satır 2: avatar + isim + tarih
            Row(
              children: [
                avatarWidget(isim: isim, radius: 9, fontSize: 7),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(isim,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: GColors.textSecondary)),
                ),
                if (tarihYazi.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: tarihBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tarihYazi,
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tarihColor)),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
 
    // ── İstek kartı — değişmedi ────────────────────────────
    final yakinGeliyor = _yakinGeliyor();
    const pastelGradients = [
      [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
      [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
    ];
    final istekRenkler = yakinGeliyor
        ? [const Color(0xFFEEF8EE), const Color(0xFFD6EED6)]
        : pastelGradients[isim.codeUnitAt(0) % pastelGradients.length];
 
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: istekRenkler,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: yakinGeliyor ? const Color(0xFF81C784) : GColors.divider,
          width: yakinGeliyor ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🛍️', style: TextStyle(fontSize: 16)),
              if (ucret.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GColors.redLight,
                    borderRadius: BorderRadius.circular(5),
                    border:
                        Border.all(color: GColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text('₺$ucret',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: GColors.red)),
                ),
            ],
          ),
          if (urun.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(urun,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: GColors.textPrimary,
                    height: 1.3)),
          ],
          const SizedBox(height: 6),
          Text(nereden.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: GColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.arrow_downward, size: 8, color: GColors.red),
              const SizedBox(width: 2),
              Expanded(
                child: Text(nereye.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.dmSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: GColors.red,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              avatarWidget(isim: isim, radius: 8, fontSize: 7),
              const SizedBox(width: 4),
              Expanded(
                child: Text(isim,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 9, color: GColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ── Sıralama Seçeneği ─────────────────────────────────────
 
class _SiralaSecenegi extends StatelessWidget {
  final String label;
  final bool secili;
  final VoidCallback onTap;
 
  const _SiralaSecenegi({
    required this.label,
    required this.secili,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(
              secili
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: secili
                  ? const Color(0xFF1A73E8)
                  : const Color(0xFF777777),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight:
                          secili ? FontWeight.w600 : FontWeight.w400,
                      color: secili
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF444444))),
            ),
          ],
        ),
      ),
    );
  }
}