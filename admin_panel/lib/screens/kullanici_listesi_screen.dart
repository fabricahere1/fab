import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KullaniciListesiScreen extends StatefulWidget {
  const KullaniciListesiScreen({super.key});

  @override
  State<KullaniciListesiScreen> createState() => _KullaniciListesiScreenState();
}

class _KullaniciListesiScreenState extends State<KullaniciListesiScreen> {
  final _aramaController = TextEditingController();
  List<Map<String, dynamic>> _kullanicilar = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle({String? emailFiltre}) async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('kullanicilariListele');
      final sonuc = await callable.call({
        'limit': 50,
        if (emailFiltre != null && emailFiltre.isNotEmpty) 'emailFiltre': emailFiltre,
      });
      final data = Map<String, dynamic>.from(sonuc.data as Map);
      setState(() {
        _kullanicilar = (data['kullanicilar'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _banKarariVer(String uid, bool banli) async {
    String? banSebebi;
    if (banli) {
      final controller = TextEditingController();
      banSebebi = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ban Sebebi'),
          content: TextField(controller: controller, maxLines: 3),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Banla'),
            ),
          ],
        ),
      );
      if (banSebebi == null) return;
    }
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('kullaniciBanKarari');
      await callable.call({
        'uid': uid,
        'banli': banli,
        if (banSebebi != null) 'banSebebi': banSebebi,
      });
      _yukle(emailFiltre: _aramaController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcılar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aramaController,
                    decoration: const InputDecoration(
                        labelText: 'E-posta ile ara (tam eşleşme)'),
                    onSubmitted: (v) => _yukle(emailFiltre: v),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _yukle(emailFiltre: _aramaController.text),
                  child: const Text('Ara'),
                ),
                TextButton(
                  onPressed: () {
                    _aramaController.clear();
                    _yukle();
                  },
                  child: const Text('Temizle'),
                ),
              ],
            ),
          ),
          if (_yukleniyor) const LinearProgressIndicator(),
          if (_hata != null) Text('Hata: $_hata', style: const TextStyle(color: Colors.red)),
          Expanded(
            child: ListView.builder(
              itemCount: _kullanicilar.length,
              itemBuilder: (context, i) {
                final k = _kullanicilar[i];
                final banli = k['banli'] == true;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: banli ? Colors.red.shade100 : null,
                    child: Icon(banli ? Icons.block : Icons.person),
                  ),
                  title: Text((k['adSoyad'] as String?)?.isNotEmpty == true
                      ? k['adSoyad'] as String
                      : (k['email'] as String? ?? k['id'] as String)),
                  subtitle: Text(
                      '${k['email'] ?? ''} · güven: ${k['guvenSkoru'] ?? 0} · '
                      '${banli ? 'BANLI' : 'aktif'}'),
                  onTap: () => context.go('/kullanicilar/${k['id']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(banli ? Icons.lock_open : Icons.block,
                            color: banli ? Colors.green : Colors.red),
                        tooltip: banli ? 'Ban Kaldır' : 'Banla',
                        onPressed: () => _banKarariVer(k['id'] as String, !banli),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Detaya Git',
                        onPressed: () => context.go('/kullanicilar/${k['id']}'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
