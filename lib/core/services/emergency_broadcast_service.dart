import 'package:flutter/material.dart';

/// Global service for handling real-time emergency broadcasts and driving
/// severity-based UI overlays across the entire application.
class EmergencyBroadcastService {
  EmergencyBroadcastService._();

  /// Global navigator key attached to MaterialApp.
  /// Allows displaying overlays from background/push event callbacks regardless
  /// of which screen the resident is currently viewing.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Dispatches the broadcast payload to the correct severity presentation.
  /// Matches the FCM data payload contract from the Django backend.
  static void handleBroadcastPayload(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final severity = (data['severity'] ?? 'info').toString().toLowerCase();
    final title = (data['title'] as String?)?.trim() ?? 'Emergency Broadcast';
    final description = (data['description'] as String?)?.trim() ?? '';
    final broadcastId = data['broadcast_id']?.toString() ?? '';

    switch (severity) {
      case 'critical':
        showCriticalFullScreenOverlay(
          context: context,
          title: title,
          description: description,
          broadcastId: broadcastId,
        );
        break;
      case 'warning':
        showWarningModal(
          context: context,
          title: title,
          description: description,
        );
        break;
      case 'info':
      default:
        showInfoTopBanner(
          context: context,
          title: title,
          description: description,
        );
        break;
    }
  }

  /// Convenience method to simulate incoming broadcasts for testing & demo.
  static void simulate({
    required String severity,
    String? title,
    String? description,
    String? broadcastId,
  }) {
    final defaultTitle = switch (severity) {
      'critical' => 'FLASH FLOOD EMERGENCY - SECTOR 4',
      'warning' => 'Severe Weather Advisory: Heavy Storm Expected',
      _ => 'Community Maintenance: Water Supply Schedule',
    };

    final defaultDescription = switch (severity) {
      'critical' =>
        'River embankment breached. Evacuate ground floor units immediately to Community Hall. Follow directives from response volunteers.',
      'warning' =>
        'High wind gusts and flooding risks anticipated between 16:00 and 19:00. Secure outdoor items and avoid unnecessary travel.',
      _ =>
        'Scheduled water pressure testing will occur tomorrow between 09:00 and 12:00 for Blocks A through D.',
    };

    handleBroadcastPayload({
      'type': 'emergency_broadcast',
      'broadcast_id': broadcastId ?? '105',
      'severity': severity,
      'title': title ?? defaultTitle,
      'description': description ?? defaultDescription,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Critical Severity: Full-Screen Modal Barrier.
  /// Completely covers the entire screen (including AppBar and BottomNavigation).
  /// Strictly non-dismissible (`barrierDismissible: false`, `PopScope(canPop: false)`).
  /// Requires explicit user acknowledgment to dismiss.
  static void showCriticalFullScreenOverlay({
    required BuildContext context,
    required String title,
    required String description,
    String? broadcastId,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return PopScope(
          canPop: false, // Disables Android hardware/gesture back button
          child: Scaffold(
            backgroundColor: const Color(0xFF8B0000), // Dark Crimson Emergency Red
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 28.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Emergency Header with warning iconography
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.amberAccent,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amberAccent,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'CRITICAL EMERGENCY ALERT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Title & Description Body
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Text(
                                    description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Mandatory User Acknowledgement Action
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.black,
                              size: 24,
                            ),
                            label: const Text(
                              'I ACKNOWLEDGE & UNDERSTAND',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You must acknowledge receipt to resume app navigation.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Warning Severity: Modal Bottom Sheet with Amber Alert card.
  /// Dismissible by tapping "Understood" or tapping outside.
  static void showWarningModal({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Safety Warning',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text(
                    'Understood',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Info Severity: Top In-App Banner (Toast).
  /// Auto-dismisses in 6 seconds or can be swiped away.
  static void showInfoTopBanner({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
