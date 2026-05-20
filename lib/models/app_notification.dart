import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String sourceId;
  final DateTime createdAt;
  final NotificationSeverity severity;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.sourceId,
    required this.createdAt,
    required this.severity,
  });
}

enum NotificationSeverity { info, success, warning, critical }

extension NotificationSeverityExtension on NotificationSeverity {
  String get label {
    switch (this) {
      case NotificationSeverity.info:
        return 'Info';
      case NotificationSeverity.success:
        return 'Berhasil';
      case NotificationSeverity.warning:
        return 'Peringatan';
      case NotificationSeverity.critical:
        return 'Kritis';
    }
  }

  Color get color {
    switch (this) {
      case NotificationSeverity.info:
        return const Color(0xFF5CC2E6);
      case NotificationSeverity.success:
        return const Color(0xFF00C689);
      case NotificationSeverity.warning:
        return const Color(0xFFFFC107);
      case NotificationSeverity.critical:
        return const Color(0xFFFF4D4D);
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationSeverity.info:
        return Icons.info_rounded;
      case NotificationSeverity.success:
        return Icons.check_circle_rounded;
      case NotificationSeverity.warning:
        return Icons.warning_rounded;
      case NotificationSeverity.critical:
        return Icons.error_rounded;
    }
  }
}
