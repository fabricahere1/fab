import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _hedefler = [
    ('/', 'Dashboard', Icons.dashboard_outlined),
    ('/ilanlar', 'İlanlar', Icons.list_alt_outlined),
    ('/kullanicilar', 'Kullanıcılar', Icons.people_outline),
    ('/degerlendirmeler', 'Şikayetler', Icons.flag_outlined),
    ('/bildirim', 'Bildirim', Icons.campaign_outlined),
  ];

  int get _seciliIndex {
    final i = _hedefler.indexWhere((h) => location.startsWith(h.$1) && h.$1 != '/');
    if (i != -1) return i;
    return location == '/' ? 0 : -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _seciliIndex < 0 ? 0 : _seciliIndex,
            onDestinationSelected: (i) => context.go(_hedefler[i].$1),
            labelType: NavigationRailLabelType.all,
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Çıkış',
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ),
              ),
            ),
            destinations: _hedefler
                .map((h) => NavigationRailDestination(
                      icon: Icon(h.$3),
                      label: Text(h.$2),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
