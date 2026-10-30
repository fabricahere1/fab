import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iste_v3/features/auth/data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _yukleniyor = false;
  String? _hata;

  Future<void> _girisYap() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.epostaIleGiris(
        email: _emailController.text,
        sifre: _sifreController.text,
      );
      // go_router'ın redirect'i bir navigasyon olayı olmadan authState
      // değişikliğini kendiliğinden tetiklemiyor — bu yüzden burada açıkça
      // yönlendiriyoruz. redirect() '/ilanlar' hedefinde admin claim'ini
      // kontrol edip admin değilse zaten '/login'e geri atacak.
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('İSTE Admin', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sifreController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  onSubmitted: (_) => _girisYap(),
                ),
                const SizedBox(height: 16),
                if (_hata != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_hata!, style: const TextStyle(color: Colors.red)),
                  ),
                FilledButton(
                  onPressed: _yukleniyor ? null : _girisYap,
                  child: _yukleniyor
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Giriş Yap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
