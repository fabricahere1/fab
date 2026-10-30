import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:iste_v3/core/firebase/app_firestore.dart';
import 'package:iste_v3/features/profil/domain/kullanici_model.dart';

class KullaniciDetayScreen extends StatefulWidget {
  const KullaniciDetayScreen({required this.uid, super.key});

  final String uid;

  @override
  State<KullaniciDetayScreen> createState() => _KullaniciDetayScreenState();
}

class _KullaniciDetayScreenState extends State<KullaniciDetayScreen> {
  final _sebepController = TextEditingController();
  bool _islemYapiliyor = false;

  Future<void> _banKarariVer(bool banli) async {
    setState(() => _islemYapiliyor = true);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('kullaniciBanKarari');
      await callable.call({
        'uid': widget.uid,
        'banli': banli,
        if (banli) 'banSebebi': _sebepController.text,
      });
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _islemYapiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Detayı')),
      body: FutureBuilder<DocumentSnapshot>(
        future: AppFirestore.instance.collection('kullanicilar').doc(widget.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Kullanıcı bulunamadı'));
          }
          final k = KullaniciModel.fromFirestore(snapshot.data!);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(k.adSoyad, style: Theme.of(context).textTheme.headlineSmall),
                Text(k.email ?? ''),
                const SizedBox(height: 12),
                Text('Güven skoru: ${k.guvenSkoru} (${k.guvenSkoruEtiketi})'),
                Text('Ortalama puan: ${k.ortalamaPuan} (${k.degerlendirmeSayisi} değerlendirme)'),
                Text('Rozetler: ${k.rozetler.map((r) => k.rozetAdi(r)).join(', ')}'),
                const SizedBox(height: 12),
                if (k.banli)
                  Text('BANLI — sebep: ${k.banSebebi}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (!k.banli) ...[
                  TextField(
                    controller: _sebepController,
                    decoration: const InputDecoration(labelText: 'Ban sebebi'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _islemYapiliyor ? null : () => _banKarariVer(true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Kullanıcıyı Banla'),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: _islemYapiliyor ? null : () => _banKarariVer(false),
                    child: const Text('Ban Kaldır'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
