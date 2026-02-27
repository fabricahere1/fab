

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      emoji: '🌍',
      baslik: 'Dünyanın her yerinden',
      altBaslik: 'Yurt dışında olan biri mi var?\nOnlardan bir şeyler getirtebilirsin.',
    ),
    _OnboardingData(
      emoji: '🛍️',
      baslik: 'Ne istersen iste',
      altBaslik: 'Elektronik, kozmetik, kıyafet...\nAklına gelen her şeyi talep et.',
    ),
    _OnboardingData(
      emoji: '✈️',
      baslik: 'Yeterki sen iste',
      altBaslik: 'Yurt dışından gelenler sana\nulaşsın, sen de onlara.',
    ),
  ];

  void _devamEt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_tamamlandi', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Atla butonu
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _devamEt,
                child: const Text(
                  'Atla',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),

            // Sayfa içeriği
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji / İllüstrasyon
                        Container(
                          width: w * 0.45,
                          height: w * 0.45,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              page.emoji,
                              style: TextStyle(fontSize: h * 0.1),
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.06),

                        // Başlık
                        Text(
                          page.baslik,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lobster(
                            fontSize: 28,
                            color: Colors.deepOrangeAccent,
                          ),
                        ),
                        SizedBox(height: h * 0.02),

                        // Alt başlık
                        Text(
                          page.altBaslik,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Nokta göstergesi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.deepOrangeAccent
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: h * 0.04),

            // Buton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _devamEt();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Devam' : 'Başla',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            SizedBox(height: h * 0.05),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String emoji;
  final String baslik;
  final String altBaslik;

  const _OnboardingData({
    required this.emoji,
    required this.baslik,
    required this.altBaslik,
  });
}