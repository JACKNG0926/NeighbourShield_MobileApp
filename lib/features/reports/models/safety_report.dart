import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class SafetyReport {
  const SafetyReport({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    required this.postType,
    required this.authorUsername,
    this.authorRole,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String severity;
  final String status;
  final String postType;
  final String authorUsername;
  final String? authorRole;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final DateTime createdAt;

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final authorData = json['author'];
    String authorName = 'Anonymous';
    String? authorRole;
    if (authorData is Map) {
      authorName = authorData['username'] as String? ?? 'Resident';
      authorRole = authorData['role'] as String?;
    }

    DateTime createdDate;
    if (json['created_at'] != null) {
      createdDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    return SafetyReport(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled Report',
      description: json['description'] as String? ?? '',
      category: (json['category'] as String? ?? 'other').toLowerCase(),
      severity: (json['severity'] as String? ?? 'info').toLowerCase(),
      status: (json['status'] as String? ?? 'open').toLowerCase(),
      postType: (json['post_type'] as String? ?? 'hazard').toLowerCase(),
      authorUsername: authorName,
      authorRole: authorRole,
      latitude: parseCoord(json['latitude']),
      longitude: parseCoord(json['longitude']),
      isVerified: json['is_verified'] == true,
      createdAt: createdDate,
    );
  }

  String get categoryLabel {
    return switch (category) {
      'broken_light' => 'Street Light',
      'suspicious' => 'Suspicious Activity',
      'road' => 'Road Damage',
      'flood' => 'Flooding',
      'fire' => 'Fire Hazard',
      'road_closure' => 'Road Closure',
      'maintenance' => 'Maintenance',
      _ => 'General Hazard',
    };
  }

  IconData get categoryIcon {
    return switch (category) {
      'broken_light' => Icons.lightbulb_outline,
      'suspicious' => Icons.visibility_outlined,
      'road' => Icons.edit_road_outlined,
      'flood' => Icons.water_drop_outlined,
      'fire' => Icons.local_fire_department_outlined,
      'road_closure' => Icons.do_not_disturb_on_outlined,
      'maintenance' => Icons.build_circle_outlined,
      _ => Icons.warning_amber_rounded,
    };
  }

  Color get severityColor {
    return switch (severity) {
      'critical' => AppTheme.dangerColor,
      'warning' => const Color(0xFFD97706),
      _ => const Color(0xFF2563EB),
    };
  }

  String get severityLabel {
    return switch (severity) {
      'critical' => 'Critical',
      'warning' => 'Warning',
      _ => 'Low',
    };
  }

  Color get statusColor {
    return switch (status) {
      'resolved' => const Color(0xFF16A34A),
      'in_progress' => const Color(0xFF0284C7),
      'rejected' => const Color(0xFF6B7280),
      _ => const Color(0xFFEA580C),
    };
  }

  String get statusLabel {
    return switch (status) {
      'resolved' => 'Resolved',
      'in_progress' => 'In Progress',
      'rejected' => 'Rejected',
      _ => 'Open',
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
