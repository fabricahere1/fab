import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      emoji: '🌍',
      title: 'Dünyanın her yerinden',
      subtitle: '',
    ),
    _OnboardingData(
      emoji: '🛍️',
      title: 'Ne istersen iste',
      subtitle: 'Elektronik, kozmetik, kıyafet...\nAklına gelen her şeyi talep et.',
    ),
    _OnboardingData(
      emoji: '✈️',
      title: 'Yeterki sen iste',
      subtitle: 'Yurt dışından gelenler sana ulaşsın,\nsen de onlara.',
    ),
  ];

  Future<void> _tamamla() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_tamamlandi', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip butonu
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: _tamamla,
                  child: Text(
                    'Geç',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          page.emoji,
                          style: const TextStyle(fontSize: 72),
                        ),
                        SizedBox(height: h * 0.04),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212121),
                            height: 1.2,
                          ),
                        ),
                        if (page.subtitle.isNotEmpty) ...[
                          SizedBox(height: h * 0.02),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              color: const Color(0xFF757575),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF3C3C3C)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // İleri / Başla butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
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
                      _tamamla();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C3C3C),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'İleri' : 'Başla',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  const _OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}














