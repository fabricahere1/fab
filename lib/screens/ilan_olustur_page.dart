

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Popüler şehirler listesi
const List<String> _sehirler = [
  // Türkiye
  'İstanbul, Türkiye', 'Ankara, Türkiye', 'İzmir, Türkiye', 'Bursa, Türkiye',
  'Antalya, Türkiye', 'Adana, Türkiye', 'Konya, Türkiye', 'Gaziantep, Türkiye',
  'Mersin, Türkiye', 'Kayseri, Türkiye', 'Eskişehir, Türkiye', 'Trabzon, Türkiye',

  // İngiltere
  'Londra, İngiltere', 'Manchester, İngiltere', 'Birmingham, İngiltere',
  'Leeds, İngiltere', 'Glasgow, İngiltere', 'Liverpool, İngiltere',
  'Bristol, İngiltere', 'Edinburgh, İngiltere',

  // Almanya
  'Berlin, Almanya', 'Hamburg, Almanya', 'Münih, Almanya', 'Frankfurt, Almanya',
  'Köln, Almanya', 'Stuttgart, Almanya', 'Düsseldorf, Almanya', 'Dortmund, Almanya',

  // Fransa
  'Paris, Fransa', 'Marsilya, Fransa', 'Lyon, Fransa', 'Toulouse, Fransa',
  'Nice, Fransa', 'Nantes, Fransa', 'Strasbourg, Fransa',

  // ABD
  'New York, ABD', 'Los Angeles, ABD', 'Chicago, ABD', 'Houston, ABD',
  'Phoenix, ABD', 'San Francisco, ABD', 'Seattle, ABD', 'Miami, ABD',
  'Boston, ABD', 'Washington DC, ABD', 'Las Vegas, ABD', 'Dallas, ABD',

  // Hollanda
  'Amsterdam, Hollanda', 'Rotterdam, Hollanda', 'Lahey, Hollanda',
  'Utrecht, Hollanda', 'Eindhoven, Hollanda',

  // Belçika
  'Brüksel, Belçika', 'Antwerp, Belçika', 'Gent, Belçika',

  // İsviçre
  'Zürih, İsviçre', 'Cenevre, İsviçre', 'Basel, İsviçre', 'Bern, İsviçre',

  // Avusturya
  'Viyana, Avusturya', 'Salzburg, Avusturya', 'Innsbruck, Avusturya',

  // İtalya
  'Roma, İtalya', 'Milano, İtalya', 'Napoli, İtalya', 'Turin, İtalya',
  'Floransa, İtalya', 'Venedik, İtalya', 'Bologna, İtalya',

  // İspanya
  'Madrid, İspanya', 'Barselona, İspanya', 'Sevilla, İspanya', 'Valencia, İspanya',
  'Bilbao, İspanya', 'Malaga, İspanya',

  // Portekiz
  'Lizbon, Portekiz', 'Porto, Portekiz',

  // Yunanistan
  'Atina, Yunanistan', 'Selanik, Yunanistan',

  // Polonya
  'Varşova, Polonya', 'Krakow, Polonya', 'Wroclaw, Polonya',

  // Çek Cumhuriyeti
  'Prag, Çek Cumhuriyeti', 'Brno, Çek Cumhuriyeti',

  // Macaristan
  'Budapeşte, Macaristan',

  // Romanya
  'Bükreş, Romanya', 'Cluj, Romanya',

  // İsveç
  'Stockholm, İsveç', 'Göteborg, İsveç', 'Malmö, İsveç',

  // Norveç
  'Oslo, Norveç', 'Bergen, Norveç',

  // Danimarka
  'Kopenhag, Danimarka',

  // Finlandiya
  'Helsinki, Finlandiya',

  // Rusya
  'Moskova, Rusya', 'St. Petersburg, Rusya',

  // BAE
  'Dubai, BAE', 'Abu Dabi, BAE', 'Şarjah, BAE',

  // Suudi Arabistan
  'Riyad, Suudi Arabistan', 'Cidde, Suudi Arabistan', 'Mekke, Suudi Arabistan',

  // Japonya
  'Tokyo, Japonya', 'Osaka, Japonya', 'Kyoto, Japonya', 'Nagoya, Japonya',

  // Çin
  'Pekin, Çin', 'Şangay, Çin', 'Guangzhou, Çin', 'Shenzhen, Çin',

  // Güney Kore
  'Seul, Güney Kore', 'Busan, Güney Kore',

  // Hindistan
  'Mumbai, Hindistan', 'Delhi, Hindistan', 'Bangalore, Hindistan',
  'Hyderabad, Hindistan', 'Chennai, Hindistan',

  // Kanada
  'Toronto, Kanada', 'Vancouver, Kanada', 'Montreal, Kanada', 'Calgary, Kanada',

  // Avustralya
  'Sydney, Avustralya', 'Melbourne, Avustralya', 'Brisbane, Avustralya',
  'Perth, Avustralya',

  // Mısır
  'Kahire, Mısır', 'İskenderiye, Mısır',

  // Azerbaycan
  'Bakü, Azerbaycan',

  // Gürcistan
  'Tiflis, Gürcistan',

  // Ukrayna
  'Kiev, Ukrayna', 'Lviv, Ukrayna',

  // Kazakistan
  'Almatı, Kazakistan', 'Nur-Sultan, Kazakistan',

  // Brezilya
  'São Paulo, Brezilya', 'Rio de Janeiro, Brezilya', 'Brasilia, Brezilya',

  // Arjantin
  'Buenos Aires, Arjantin',

  // Meksika
  'Mexico City, Meksika', 'Guadalajara, Meksika',

  // Singapur
  'Singapur',

  // Tayland
  'Bangkok, Tayland', 'Phuket, Tayland',

  // Malezya
  'Kuala Lumpur, Malezya',

  // Endonezya
  'Jakarta, Endonezya', 'Bali, Endonezya',
];

class IlanOlusturPage extends StatefulWidget {
  final int initialTip;

  const IlanOlusturPage({super.key, this.initialTip = 0});

  @override
  State<IlanOlusturPage> createState() => _IlanOlusturPageState();
}

class _IlanOlusturPageState extends State<IlanOlusturPage> {
  late int _ilanTipi;

  final _neredenController = TextEditingController();
  final _nereyeController = TextEditingController();
  final _kapasiteController = TextEditingController();
  final _ucretController = TextEditingController();
  final _urunController = TextEditingController();
  final _linkController = TextEditingController();
  final _notlarController = TextEditingController();

  DateTime? _secilenTarih;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ilanTipi = widget.initialTip;
  }

  @override
  void dispose() {
    _neredenController.dispose();
    _nereyeController.dispose();
    _kapasiteController.dispose();
    _ucretController.dispose();
    _urunController.dispose();
    _linkController.dispose();
    _notlarController.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final tarih = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepOrangeAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (tarih != null) setState(() => _secilenTarih = tarih);
  }

  String _tarihFormatla(DateTime tarih) {
    return '${tarih.day}.${tarih.month}.${tarih.year}';
  }

  Future<void> _ilanVer() async {
    if (_neredenController.text.trim().isEmpty ||
        _nereyeController.text.trim().isEmpty) {
      _hataGoster('Lütfen nereden ve nereye alanlarını doldurun.');
      return;
    }
    if (_secilenTarih == null) {
      _hataGoster('Lütfen tarih seçin.');
      return;
    }
    if (_ilanTipi == 0 && _kapasiteController.text.trim().isEmpty) {
      _hataGoster('Lütfen kapasite girin.');
      return;
    }
    if (_ilanTipi == 1 && _urunController.text.trim().isEmpty) {
      _hataGoster('Lütfen ürün adını girin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final veri = {
        'tip': _ilanTipi == 0 ? 'tasiyici' : 'istek',
        'nereden': _neredenController.text.trim(),
        'nereye': _nereyeController.text.trim(),
        'tarih': Timestamp.fromDate(_secilenTarih!),
        'ucret': _ucretController.text.trim(),
        'notlar': _notlarController.text.trim(),
        'kullaniciId': user?.uid,
        'kullaniciEmail': user?.email,
        'kullaniciAd': user?.displayName ?? user?.email?.split('@')[0] ?? 'Kullanıcı',
        'olusturmaTarihi': FieldValue.serverTimestamp(),
        'aktif': true,
        if (_ilanTipi == 0) 'kapasite': _kapasiteController.text.trim(),
        if (_ilanTipi == 1) 'urun': _urunController.text.trim(),
        if (_ilanTipi == 1) 'link': _linkController.text.trim(),
      };

      await FirebaseFirestore.instance.collection('ilanlar').add(veri);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlanınız başarıyla yayınlandı! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        _formuTemizle();
      }
    } catch (e) {
      _hataGoster('İlan yayınlanırken hata oluştu. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: Colors.red),
    );
  }

  void _formuTemizle() {
    _neredenController.clear();
    _nereyeController.clear();
    _kapasiteController.clear();
    _ucretController.clear();
    _urunController.clear();
    _linkController.clear();
    _notlarController.clear();
    setState(() => _secilenTarih = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'İlan Ver',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ToggleButon(
                    label: '✈️  Taşıyıcıyım',
                    aktif: _ilanTipi == 0,
                    onTap: () => setState(() => _ilanTipi = 0),
                  ),
                  _ToggleButon(
                    label: '🛍️  İstek Var',
                    aktif: _ilanTipi == 1,
                    onTap: () => setState(() => _ilanTipi = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ilanTipi == 0
                  ? 'Yurt dışından geliyorsunuz ve yer açıksa ilan verin.'
                  : 'Yurt dışından bir şey getirtmek istiyorsunuz.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),

            _BaslikText('Nereden'),
            const SizedBox(height: 8),
            _SehirAutocomplete(
              controller: _neredenController,
              hint: 'Örn: Londra, İngiltere',
              ikon: Icons.flight_takeoff,
            ),
            const SizedBox(height: 16),

            _BaslikText('Nereye'),
            const SizedBox(height: 8),
            _SehirAutocomplete(
              controller: _nereyeController,
              hint: 'Örn: İstanbul, Türkiye',
              ikon: Icons.flight_land,
            ),
            const SizedBox(height: 16),

            _BaslikText('Tarih'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _tarihSec,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _secilenTarih != null
                          ? _tarihFormatla(_secilenTarih!)
                          : 'Tarih seçin',
                      style: TextStyle(
                        color: _secilenTarih != null ? Colors.black87 : Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_ilanTipi == 0) ...[
              _BaslikText('Kapasite (kg)'),
              const SizedBox(height: 8),
              _InputAlani(
                controller: _kapasiteController,
                hint: 'Örn: 5',
                ikon: Icons.luggage,
                klavye: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _BaslikText('Taşıma Ücreti (₺)'),
              const SizedBox(height: 8),
              _InputAlani(
                controller: _ucretController,
                hint: 'Örn: 200',
                ikon: Icons.payments_outlined,
                klavye: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
            ],

            if (_ilanTipi == 1) ...[
              _BaslikText('Ürün Adı'),
              const SizedBox(height: 8),
              _InputAlani(
                controller: _urunController,
                hint: 'Örn: Nike Air Max 90',
                ikon: Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: 16),
              _BaslikText('Ürün Linki (opsiyonel)'),
              const SizedBox(height: 8),
              _InputAlani(
                controller: _linkController,
                hint: 'Örn: amazon.com/...',
                ikon: Icons.link,
                klavye: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _BaslikText('Ödeyeceğiniz Ücret (₺)'),
              const SizedBox(height: 8),
              _InputAlani(
                controller: _ucretController,
                hint: 'Örn: 500',
                ikon: Icons.payments_outlined,
                klavye: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
            ],

            _BaslikText('Notlar (opsiyonel)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notlarController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Eklemek istediğiniz bilgiler...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.deepOrangeAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _ilanVer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  disabledBackgroundColor:
                      Colors.deepOrangeAccent.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'İlanı Yayınla',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Şehir Autocomplete Widget ─────────────────────────────

class _SehirAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData ikon;

  const _SehirAutocomplete({
    required this.controller,
    required this.hint,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        final query = textEditingValue.text.toLowerCase();
        return _sehirler.where((sehir) =>
            sehir.toLowerCase().contains(query));
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Dışarıdan gelen controller ile senkronize et
        textController.text = controller.text;
        textController.addListener(() {
          controller.text = textController.text;
        });
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(ikon, color: Colors.grey, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () {
                      textController.clear();
                      controller.clear();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Colors.deepOrangeAccent, width: 1.5),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.deepOrangeAccent),
                          const SizedBox(width: 8),
                          Text(option,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────

class _ToggleButon extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;
  const _ToggleButon({required this.label, required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: aktif ? Colors.deepOrangeAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: aktif ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _BaslikText extends StatelessWidget {
  final String baslik;
  const _BaslikText(this.baslik);

  @override
  Widget build(BuildContext context) {
    return Text(baslik,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87));
  }
}

class _InputAlani extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData ikon;
  final TextInputType klavye;
  final List<TextInputFormatter>? inputFormatters;

  const _InputAlani({
    required this.controller,
    required this.hint,
    required this.ikon,
    this.klavye = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: klavye,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(ikon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Colors.deepOrangeAccent, width: 1.5),
        ),
      ),
    );
  }
}