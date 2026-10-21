import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/app/app.dart';
import 'package:neighbour_shield_mobile/core/session/app_session.dart';
import 'package:neighbour_shield_mobile/core/session/user_role.dart';
import 'package:neighbour_shield_mobile/features/auth/models/user_session.dart';
import 'package:neighbour_shield_mobile/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('Login page renders correctly', (tester) async {
    final session = AppSession();

    await tester.pumpWidget(NeighbourShieldApp(session: session));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('HomePage renders Community Safety Reports banner for residents', (tester) async {
    final session = AppSession();
    addTearDown(() => session.signOut());
    session.signIn(const UserSession(
      id: 1,
      username: 'resident_jane',
      email: 'jane@example.com',
      role: UserRole.resident,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          email: 'jane@example.com',
          session: session,
        ),
      ),
    );

    expect(find.text('Community Safety Reports'), findsOneWidget);
    expect(
      find.text('Report hazards & view neighbourhood safety alerts'),
      findsOneWidget,
    );

    session.signOut();
  });
}

