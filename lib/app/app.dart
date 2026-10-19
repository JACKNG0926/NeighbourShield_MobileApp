import 'package:flutter/material.dart';

import '../core/session/app_session.dart';
import '../core/session/user_role.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/volunteer/presentation/pages/volunteer_home_page.dart';
import 'app_theme.dart';

class NeighbourShieldApp extends StatelessWidget {
  const NeighbourShieldApp({super.key, required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeighbourShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SessionGate(session: session),
    );
  }
}

/// The root page listens for session updates and shows the correct role UI.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key, required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, child) {
        final user = session.currentUser;

        if (user == null) {
          return LoginPage(session: session);
        }

        switch (user.role) {
          case UserRole.resident:
            return HomePage(
              email: user.email ?? user.username,
              session: session,
            );
          case UserRole.volunteer:
            return VolunteerHomePage(session: session);
          case UserRole.security:
          case UserRole.townshipAdmin:
            return _RolePlaceholderPage(role: user.role, session: session);
        }
      },
    );
  }
}

/// Temporary placeholder for privileged roles that are not implemented yet.
class _RolePlaceholderPage extends StatelessWidget {
  const _RolePlaceholderPage({required this.role, required this.session});

  final UserRole role;
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeighbourShield'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: session.signOut,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                '${role.label} Dashboard',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This dashboard will be implemented in the next phase.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: session.signOut,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
