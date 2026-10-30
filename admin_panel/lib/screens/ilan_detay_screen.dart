import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iste_v3/core/firebase/app_firestore.dart';
import 'package:iste_v3/features/ilanlar/domain/ilan_model.dart';
import 'package:iste_v3/shared/constants/app_constants.dart';

class IlanDetayScreen extends StatefulWidget {
  const IlanDetayScreen({required this.ilanId, super.key});

  final String ilanId;

  @override
  State<IlanDetayScreen> createState() => _IlanDetayScreenState();
}

class _IlanDetayScreenState extends State<IlanDetayScreen> {
  bool _islemYapiliyor = false;
  final _redSebebiController = TextEditingController();

  Future<void> _kararVer(String karar) async {
    setState(() => _islemYapiliyor = true);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('ilanModerasyonKarari');
      await callable.call({
        'ilanId': widget.ilanId,
        'karar': karar,
        if (karar == 'reddet') 'redSebebi': _redSebebiController.text,
      });
      if (mounted) context.go('/ilanlar');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _islemYapiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlan Detayı')),
      body: FutureBuilder<DocumentSnapshot>(
        future: AppFirestore.instance
            .collection(Collections.ilanlar)
            .doc(widget.ilanId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('İlan bulunamadı'));
          }
          final ilan = IlanModel.fromFirestore(snapshot.data!);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text('#${ilan.ilanNo}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(ilan.urun.isNotEmpty ? ilan.urun : '${ilan.nereden} → ${ilan.nereye}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Kullanıcı: ${ilan.kullaniciAd}'),
                Text('Durum: ${ilan.durum}'),
                if (ilan.notlar.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notlar: ${ilan.notlar}'),
                ],
                if (ilan.resimUrller.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ilan.resimUrller
                        .map((u) => Image.network(u, width: 120, height: 120, fit: BoxFit.cover))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: _redSebebiController,
                  decoration: const InputDecoration(labelText: 'Red sebebi (reddedilirse)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _islemYapiliyor ? null : () => _kararVer('onayla'),
                      child: const Text('Onayla'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _islemYapiliyor ? null : () => _kararVer('reddet'),
                      child: Text(ilan.durum == 'yayinda' ? 'Yayından Kaldır' : 'Reddet'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
