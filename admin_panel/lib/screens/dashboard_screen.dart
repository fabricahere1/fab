import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('dashboardIstatistikleriGetir');
      final sonuc = await callable.call();
      setState(() => _stats = Map<String, dynamic>.from(sonuc.data as Map));
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _yukle),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(child: Text('Hata: $_hata'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _kart('Toplam Kullanıcı', _stats?['kullaniciSayisi']),
                      _kart('Banlı Kullanıcı', _stats?['banliKullaniciSayisi']),
                      _kart('Onay Bekleyen İlan', _stats?['onayBekleyenSayisi']),
                      _kart('Yayındaki İlan', _stats?['yayindaSayisi']),
                      _kart('Reddedilen İlan', _stats?['reddedilenSayisi']),
                      _kart('Bugünkü Yeni İlan', _stats?['bugunkuIlanSayisi']),
                    ],
                  ),
                ),
    );
  }

  Widget _kart(String baslik, dynamic deger) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${deger ?? '-'}',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(baslik, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
