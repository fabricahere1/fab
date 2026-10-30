import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class DegerlendirmeModerasyonScreen extends StatefulWidget {
  const DegerlendirmeModerasyonScreen({super.key});

  @override
  State<DegerlendirmeModerasyonScreen> createState() =>
      _DegerlendirmeModerasyonScreenState();
}

class _DegerlendirmeModerasyonScreenState
    extends State<DegerlendirmeModerasyonScreen> {
  List<Map<String, dynamic>> _liste = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc =
          await _functions.httpsCallable('sikayetliDegerlendirmeleriListele').call();
      final data = Map<String, dynamic>.from(sonuc.data as Map);
      setState(() {
        _liste = (data['degerlendirmeler'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _sil(String id) async {
    await _functions.httpsCallable('degerlendirmeSil').call({'degerlendirmeId': id});
    _yukle();
  }

  Future<void> _temizle(String id) async {
    await _functions.httpsCallable('sikayetiTemizle').call({'degerlendirmeId': id});
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şikayet Edilen Değerlendirmeler'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _yukle)],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(child: Text('Hata: $_hata'))
              : _liste.isEmpty
                  ? const Center(child: Text('Şikayet edilen yorum yok'))
                  : ListView.builder(
                      itemCount: _liste.length,
                      itemBuilder: (context, i) {
                        final d = _liste[i];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Puan: ${d['puan']} · Şikayet: ${d['sikayetSayisi']}'),
                                if ((d['ilanBaslik'] as String? ?? '').isNotEmpty)
                                  Text('İlan: ${d['ilanBaslik']}'),
                                const SizedBox(height: 8),
                                Text(d['yorum'] as String? ?? '',
                                    style: const TextStyle(fontStyle: FontStyle.italic)),
                                const SizedBox(height: 8),
                                Text('Şikayet sebepleri: ${(d['sebepler'] as List).join(', ')}',
                                    style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _temizle(d['degerlendirmeId'] as String),
                                      child: const Text('Şikayeti Temizle'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => _sil(d['degerlendirmeId'] as String),
                                      child: const Text('Yorumu Sil'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
