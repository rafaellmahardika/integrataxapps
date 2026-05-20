import 'package:flutter/material.dart';

class SyncLog {
  final String id;
  final String sourceName;
  final String action;
  final String message;
  final String? nop;
  final SyncLogStatus status;
  final DateTime timestamp;

  const SyncLog({
    required this.id,
    required this.sourceName,
    required this.action,
    required this.message,
    required this.status,
    required this.timestamp,
    this.nop,
  });
}

enum SyncLogStatus { success, failed, review }

extension SyncLogStatusExtension on SyncLogStatus {
  String get label {
    switch (this) {
      case SyncLogStatus.success:
        return 'Berhasil';
      case SyncLogStatus.failed:
        return 'Gagal';
      case SyncLogStatus.review:
        return 'Review';
    }
  }

  Color get color {
    switch (this) {
      case SyncLogStatus.success:
        return const Color(0xFF00C689);
      case SyncLogStatus.failed:
        return const Color(0xFFFF4D4D);
      case SyncLogStatus.review:
        return const Color(0xFFFFC107);
    }
  }
}
