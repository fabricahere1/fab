import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/kullanici_model.dart';
import '../providers/profil_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';
import 'kullanici_profil_screen.dart';
import '../../../shared/utils/app_hata_yonetici.dart';

enum TakipListeTipi { takipcilar, takipEdilenler }

class TakipListesiScreen extends ConsumerStatefulWidget {
  final String kullaniciId;
  final TakipListeTipi baslangicTab;

  const TakipListesiScreen({
    super.key,
    required this.kullaniciId,
    required this.baslangicTab,
  });

  @override
  ConsumerState<TakipListesiScreen> createState() => _TakipListesiScreenState();
}

class _TakipListesiScreenState extends ConsumerState<TakipListesiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.baslangicTab == TakipListeTipi.takipcilar ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tabCtrl,
            labelStyle: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.textPrimary,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: 'Takipçiler'),
              Tab(text: 'Takip Edilenler'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _TakipListesi(
            kullaniciId: widget.kullaniciId,
            tip: TakipListeTipi.takipcilar,
          ),
          _TakipListesi(
            kullaniciId: widget.kullaniciId,
            tip: TakipListeTipi.takipEdilenler,
          ),
        ],
      ),
    );
  }
}

class _TakipListesi extends ConsumerStatefulWidget {
  final String kullaniciId;
  final TakipListeTipi tip;

  const _TakipListesi({required this.kullaniciId, required this.tip});

  @override
  ConsumerState<_TakipListesi> createState() => _TakipListesiState();
}

class _TakipListesiState extends ConsumerState<_TakipListesi> {
  // Listeyi bir kez sabitliyoruz — stream güncellemesi satır SİLMESİN,
  // sadece yeni eklenenler görünsün (Instagram davranışı).
  List<String>? _sabitIdler;

  @override
  Widget build(BuildContext context) {
    final idlerAsync = widget.tip == TakipListeTipi.takipcilar
        ? ref.watch(takipciIdleriProvider(widget.kullaniciId))
        : ref.watch(takipEdilenIdleriProvider(widget.kullaniciId));

    return idlerAsync.when(
      loading: () {
        if (_sabitIdler != null) {
          return _liste(_sabitIdler!);
        }
        return const Center(
          child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
        );
      },
      error: (_, _) => Center(
        child: Text('Yüklenemedi.',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
      ),
      data: (idler) {
        if (_sabitIdler == null) {
          // İlk yükleme — listeyi sabitle
          _sabitIdler = List<String>.from(idler);
        } else {
          // Yeni eklenenler varsa ekle, ama mevcut satırları silme
          for (final id in idler) {
            if (!_sabitIdler!.contains(id)) {
              _sabitIdler!.add(id);
            }
          }
        }

        if (_sabitIdler!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.tip == TakipListeTipi.takipcilar
                      ? Icons.people_outline_rounded
                      : Icons.person_search_outlined,
                  size: 56,
                  color: AppColors.divider,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.tip == TakipListeTipi.takipcilar
                      ? 'Henüz takipçi yok'
                      : 'Henüz kimse takip edilmiyor',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return _liste(_sabitIdler!);
      },
    );
  }

  // KRİTİK DÜZELTME: her satıra uid'ye dayalı ValueKey eklendi. Önceden
  // key verilmiyordu — Flutter, liste her yeniden çizildiğinde (her
  // Firestore anlık görüntüsünde tetiklenir) satırların kimliğini
  // pozisyona göre karıştırabiliyordu. Bu da, satır widget'larının
  // gereksiz yere yok edilip yeniden oluşturulmasına, ve bağlı
  // kullaniciBilgiProvider'ın sıfırdan yeniden veri çekip "yanıp sönme"
  // (kısa süreli loading skeleton) etkisi yaratmasına sebep oluyordu.
  Widget _liste(List<String> idler) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: idler.length,
        itemBuilder: (context, i) => _KullaniciSatiri(
          key: ValueKey(idler[i]),
          uid: idler[i],
        ),
      );
}

class _KullaniciSatiri extends ConsumerWidget {
  final String uid;
  const _KullaniciSatiri({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // KRİTİK DÜZELTME: 'kullaniciBilgisiProvider' (keepAlive YOKTU) yerine
    // 'kullaniciBilgiProvider' (keepAlive VAR) kullanılıyor artık. Önceki
    // provider'ın watcher sayısı sıfıra düştüğü an (örn. yukarıdaki key
    // eksikliği yüzünden widget'lar yeniden oluştuğunda) dispose oluyor,
    // sıradaki watch çağrısı SIFIRDAN bir Firestore okuması tetikliyordu —
    // bu da görünür bir loading→data döngüsüne (yanıp sönme) sebep oluyordu.
    final profilAsync = ref.watch(kullaniciBilgiProvider(uid));

    return profilAsync.when(
      loading: () => const _SatirSkeleton(),
      error: (e, s) { AppHataYonetici.logla(e, s, etiket: 'takipListesi.kullaniciBilgi'); return const SizedBox.shrink(); },
      data: (profil) {
        if (profil == null) return const SizedBox.shrink();
        return _ProfilSatiri(profil: profil);
      },
    );
  }
}

class _ProfilSatiri extends ConsumerWidget {
  final KullaniciModel profil;
  const _ProfilSatiri({required this.profil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takipAsync = ref.watch(takipEdiyorMuProvider(profil.id));

    final Widget takipButonu = takipAsync.when(
      loading: () => Container(
        width: 108,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      error: (e, s) { AppHataYonetici.logla(e, s, etiket: 'takipListesi.takipDurumu'); return const SizedBox.shrink(); },
      data: (takipEdiyor) => GestureDetector(
        onTap: () {
          if (takipEdiyor) {
            ref.read(takipIslemleriProvider.notifier).takipiBirak(profil.id);
          } else {
            ref.read(takipIslemleriProvider.notifier).takipEt(profil.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: takipEdiyor ? Colors.transparent : AppColors.textPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: takipEdiyor ? AppColors.divider : AppColors.textPrimary,
            ),
          ),
          child: Text(
            takipEdiyor ? 'Takip Ediliyor' : 'Takip Et',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: takipEdiyor ? AppColors.textSecondary : Colors.white,
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KullaniciProfilScreen(
            kullaniciId: profil.id,
            kullaniciAd: profil.adSoyad,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AvatarWidget(
              isim: profil.adSoyad,
              fotoUrl: profil.fotoUrl,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profil.adSoyad,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (profil.bulunduguSehir.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profil.bulunduguSehir,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            takipButonu,
          ],
        ),
      ),
    );
  }
}

class _SatirSkeleton extends StatelessWidget {
  const _SatirSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120, height: 12,
                  decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 6),
              Container(width: 80, height: 10,
                  decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(5))),
            ],
          ),
        ],
      ),
    );
  }
}