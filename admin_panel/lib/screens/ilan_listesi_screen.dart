import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iste_v3/core/firebase/app_firestore.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';

class IlanListesiScreen extends StatefulWidget {
  const IlanListesiScreen({super.key});

  @override
  State<IlanListesiScreen> createState() => _IlanListesiScreenState();
}

class _IlanListesiScreenState extends State<IlanListesiScreen> {
  String _durumFiltresi = IlanDurum.onayBekliyor;

  Future<void> _kararVer(String ilanId, String karar) async {
    String? redSebebi;
    if (karar == 'reddet') {
      final controller = TextEditingController();
      redSebebi = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Red Sebebi'),
          content: TextField(controller: controller, maxLines: 3),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Reddet'),
            ),
          ],
        ),
      );
      if (redSebebi == null) return;
    }
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('ilanModerasyonKarari');
      await callable.call({
        'ilanId': ilanId,
        'karar': karar,
        if (redSebebi != null) 'redSebebi': redSebebi,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Stream<List<IlanModel>> _ilanlarStream() {
    Query q = AppFirestore.instance
        .collection(Collections.ilanlar)
        .where('durum', isEqualTo: _durumFiltresi)
        .orderBy('ilanNo', descending: true)
        .limit(100);
    return q.snapshots().map(
      (snap) => snap.docs.map((d) => IlanModel.fromFirestore(d)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: IlanDurum.onayBekliyor, label: Text('Onay Bekliyor')),
                ButtonSegment(value: IlanDurum.yayinda, label: Text('Yayında')),
                ButtonSegment(value: IlanDurum.reddedildi, label: Text('Reddedildi')),
              ],
              selected: {_durumFiltresi},
              onSelectionChanged: (s) => setState(() => _durumFiltresi = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<IlanModel>>(
              stream: _ilanlarStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                final ilanlar = snapshot.data ?? [];
                if (ilanlar.isEmpty) {
                  return const Center(child: Text('İlan yok'));
                }
                return ListView.builder(
                  itemCount: ilanlar.length,
                  itemBuilder: (context, i) {
                    final ilan = ilanlar[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text('#${ilan.ilanNo}')),
                      title: Text(ilan.urun.isNotEmpty ? ilan.urun : '${ilan.nereden} → ${ilan.nereye}'),
                      subtitle: Text('${ilan.kullaniciAd} · ${ilan.tarih ?? ''}'),
                      onTap: () => context.go('/ilanlar/${ilan.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ilan.durum != IlanDurum.yayinda)
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              tooltip: 'Onayla',
                              onPressed: () => _kararVer(ilan.id, 'onayla'),
                            ),
                          if (ilan.durum != IlanDurum.reddedildi)
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                              tooltip: ilan.durum == IlanDurum.yayinda
                                  ? 'Yayından Kaldır'
                                  : 'Reddet',
                              onPressed: () => _kararVer(ilan.id, 'reddet'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Detaya Git',
                            onPressed: () => context.go('/ilanlar/${ilan.id}'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
