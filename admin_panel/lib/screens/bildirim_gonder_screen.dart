import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class BildirimGonderScreen extends StatefulWidget {
  const BildirimGonderScreen({super.key});

  @override
  State<BildirimGonderScreen> createState() => _BildirimGonderScreenState();
}

class _BildirimGonderScreenState extends State<BildirimGonderScreen> {
  final _baslikController = TextEditingController();
  final _icerikController = TextEditingController();
  bool _gonderiliyor = false;
  String? _sonuc;
  String? _hata;

  Future<void> _gonder() async {
    if (_baslikController.text.trim().isEmpty || _icerikController.text.trim().isEmpty) {
      return;
    }
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misin?'),
        content: Text(
            'Bu bildirim TÜM kullanıcılara gönderilecek:\n\n"${_baslikController.text}"\n${_icerikController.text}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (onay != true) return;

    setState(() {
      _gonderiliyor = true;
      _sonuc = null;
      _hata = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('topluBildirimGonder');
      final sonuc = await callable.call({
        'baslik': _baslikController.text.trim(),
        'icerik': _icerikController.text.trim(),
      });
      final data = Map<String, dynamic>.from(sonuc.data as Map);
      setState(() => _sonuc =
          '${data['gonderilen']} kullanıcıya gönderildi, ${data['basarisiz']} başarısız (toplam ${data['toplamToken']} cihaz).');
      _baslikController.clear();
      _icerikController.clear();
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toplu Bildirim Gönder')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu bildirim uygulamayı yüklemiş, bildirim izni vermiş TÜM kullanıcılara push olarak gider. Dikkatli kullan.',
                  style: TextStyle(color: Colors.orange),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _baslikController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _icerikController,
                  decoration: const InputDecoration(labelText: 'İçerik'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _gonderiliyor ? null : _gonder,
                  child: _gonderiliyor
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Tüm Kullanıcılara Gönder'),
                ),
                if (_sonuc != null) ...[
                  const SizedBox(height: 16),
                  Text(_sonuc!, style: const TextStyle(color: Colors.green)),
                ],
                if (_hata != null) ...[
                  const SizedBox(height: 16),
                  Text('Hata: $_hata', style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
