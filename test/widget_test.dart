import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/app/app.dart';

void main() {
  testWidgets('Login page renders correctly', (tester) async {
    await tester.pumpWidget(const NeighbourShieldApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
