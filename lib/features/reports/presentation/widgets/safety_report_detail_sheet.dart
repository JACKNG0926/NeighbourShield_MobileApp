import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';
import '../../models/safety_report.dart';

class SafetyReportDetailSheet extends StatelessWidget {
  const SafetyReportDetailSheet({super.key, required this.report});

  final SafetyReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header with Category Icon & Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: report.severityColor.withValues(alpha: 0.12),
                child: Icon(
                  report.categoryIcon,
                  color: report.severityColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.categoryLabel,
                      style: TextStyle(
                        color: report.severityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status & Severity Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: report.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: report.statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  report.statusLabel,
                  style: TextStyle(
                    color: report.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: report.severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: report.severityColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      report.severity == 'critical'
                          ? Icons.priority_high
                          : Icons.info_outline,
                      size: 13,
                      color: report.severityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${report.severityLabel} Severity',
                      style: TextStyle(
                        color: report.severityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (report.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 28),

          // Description Section
          const Text(
            'Report Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5EDE9)),
            ),
            child: Text(
              report.description.trim().isEmpty
                  ? 'No detailed description provided.'
                  : report.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textColor,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata Info
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: AppTheme.mutedColor),
              const SizedBox(width: 6),
              Text(
                'Reported by ${report.authorUsername}',
                style: const TextStyle(color: AppTheme.mutedColor, fontSize: 13),
              ),
              const Spacer(),
              const Icon(Icons.access_time, size: 18, color: AppTheme.mutedColor),
              const SizedBox(width: 6),
              Text(
                report.timeAgo,
                style: const TextStyle(color: AppTheme.mutedColor, fontSize: 13),
              ),
            ],
          ),

          // Location Section (if coordinates present)
          if (report.latitude != null && report.longitude != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6F4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4E7E1)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS: ${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${report.latitude},${report.longitude}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coordinates copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
