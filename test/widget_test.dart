import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/app/app.dart';
import 'package:neighbour_shield_mobile/core/session/app_session.dart';

void main() {
  testWidgets('Login page renders correctly', (tester) async {
    final session = AppSession();

    await tester.pumpWidget(NeighbourShieldApp(session: session));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
