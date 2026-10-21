import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/core/services/emergency_broadcast_service.dart';

void main() {
  group('EmergencyBroadcastService UI Overlays', () {
    testWidgets('critical severity renders full-screen blocking barrier modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: EmergencyBroadcastService.navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Underlying Active Screen')),
          ),
        ),
      );

      expect(find.text('Underlying Active Screen'), findsOneWidget);

      // Trigger critical broadcast
      EmergencyBroadcastService.handleBroadcastPayload({
        'type': 'emergency_broadcast',
        'broadcast_id': '101',
        'severity': 'critical',
        'title': 'CRITICAL FLASH FLOOD',
        'description': 'Evacuate to Sector 2 Community Hall immediately.',
      });

      await tester.pumpAndSettle();

      // Verify full screen critical barrier is displayed
      expect(find.text('CRITICAL EMERGENCY ALERT'), findsOneWidget);
      expect(find.text('CRITICAL FLASH FLOOD'), findsOneWidget);
      expect(find.text('Evacuate to Sector 2 Community Hall immediately.'), findsOneWidget);
      expect(find.text('I ACKNOWLEDGE & UNDERSTAND'), findsOneWidget);

      // Verify PopScope blocks popping
      final popScopeFinder = find.byType(PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScopeWidget = tester.widget<PopScope>(popScopeFinder);
      expect(popScopeWidget.canPop, isFalse);

      // Tap acknowledgment button to dismiss
      await tester.tap(find.text('I ACKNOWLEDGE & UNDERSTAND'));
      await tester.pumpAndSettle();

      // Dialog is dismissed, returning to underlying screen
      expect(find.text('CRITICAL EMERGENCY ALERT'), findsNothing);
      expect(find.text('Underlying Active Screen'), findsOneWidget);
    });

    testWidgets('warning severity renders modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: EmergencyBroadcastService.navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Underlying Active Screen')),
          ),
        ),
      );

      // Trigger warning broadcast
      EmergencyBroadcastService.handleBroadcastPayload({
        'type': 'emergency_broadcast',
        'severity': 'warning',
        'title': 'Severe Wind Warning',
        'description': 'Secure loose items.',
      });

      await tester.pumpAndSettle();

      expect(find.text('Safety Warning'), findsOneWidget);
      expect(find.text('Severe Wind Warning'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Tap understood to dismiss
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(find.text('Safety Warning'), findsNothing);
    });

    testWidgets('info severity renders floating toast banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: EmergencyBroadcastService.navigatorKey,
          home: const Scaffold(
            body: Center(child: Text('Underlying Active Screen')),
          ),
        ),
      );

      // Trigger info broadcast
      EmergencyBroadcastService.handleBroadcastPayload({
        'type': 'emergency_broadcast',
        'severity': 'info',
        'title': 'Maintenance Notice',
        'description': 'Water pump inspection.',
      });

      await tester.pumpAndSettle();

      expect(find.text('Maintenance Notice'), findsOneWidget);
      expect(find.text('Water pump inspection.'), findsOneWidget);
    });
  });
}
