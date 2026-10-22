import 'package:flutter/material.dart';

import '../core/session/app_session.dart';
import '../features/profile/presentation/pages/profile_page.dart';

/// Wraps a role's home page with a bottom bar: Home | Profile.
/// IndexedStack keeps the home page alive, so polling and the siren keep
/// working while the user looks at their profile.
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.session, required this.home});

  final AppSession session;
  final Widget home;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          widget.home,
          ProfilePage(session: widget.session),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
