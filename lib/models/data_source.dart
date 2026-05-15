// lib/models/data_source.dart
//
// Data models for the IntegraTax Dashboard.
// These are plain Dart classes (no code generation needed for simplicity).

import 'package:flutter/material.dart';
import '../core/theme.dart';

// ─── SyncStatus Enum ─────────────────────────────────────────────────────────

/// Represents the possible states of a data source connection.
enum SyncStatus {
  /// Connection healthy, last sync completed successfully.
  connected,

  /// Sync process is currently running.
  syncing,

  /// Connection failed or sync timed out.
  failed,

  /// Status unknown — could not reach the source.
  offline,
}

extension SyncStatusExtension on SyncStatus {
  /// Human-readable Bahasa Indonesia label.
  String get label {
    switch (this) {
      case SyncStatus.connected:
        return 'Terhubung';
      case SyncStatus.syncing:
        return 'Sinkronisasi...';
      case SyncStatus.failed:
        return 'Gagal';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  /// The semantic color for this status.
  Color get color {
    switch (this) {
      case SyncStatus.connected:
        return AppColors.statusOk;
      case SyncStatus.syncing:
        return AppColors.statusWarning;
      case SyncStatus.failed:
        return AppColors.statusError;
      case SyncStatus.offline:
        return AppColors.statusOffline;
    }
  }

  /// The glow/shadow color for this status.
  Color get glowColor {
    switch (this) {
      case SyncStatus.connected:
        return AppColors.statusOkGlow;
      case SyncStatus.syncing:
        return AppColors.statusWarningGlow;
      case SyncStatus.failed:
        return AppColors.statusErrorGlow;
      case SyncStatus.offline:
        return AppColors.statusOfflineSubtle;
    }
  }

  /// The subtle background tint for status badges.
  Color get subtleColor {
    switch (this) {
      case SyncStatus.connected:
        return AppColors.statusOkSubtle;
      case SyncStatus.syncing:
        return AppColors.statusWarningSubtle;
      case SyncStatus.failed:
        return AppColors.statusErrorSubtle;
      case SyncStatus.offline:
        return AppColors.statusOfflineSubtle;
    }
  }

  /// Material icon representing this status.
  IconData get icon {
    switch (this) {
      case SyncStatus.connected:
        return Icons.check_circle_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.failed:
        return Icons.error_rounded;
      case SyncStatus.offline:
        return Icons.cloud_off_rounded;
    }
  }
}

// ─── DataSource Model ─────────────────────────────────────────────────────────

/// Represents one external data source (e.g., BPN, Disdukcapil, BPJS).
class DataSource {
  /// Unique identifier for the data source.
  final String id;

  /// Display name (e.g., "BPN", "Disdukcapil").
  final String name;

  /// Full institutional name.
  final String fullName;

  /// Short description of the data provided.
  final String dataDescription;

  /// Current synchronization status.
  final SyncStatus status;

  /// Timestamp of the last SUCCESSFUL synchronization.
  final DateTime? lastSyncAt;

  /// Number of records synced in the last cycle.
  final int? lastSyncRecords;

  /// Duration of the last sync operation in seconds.
  final int? lastSyncDurationSec;

  /// Count of records that failed during last sync.
  final int? lastSyncFailed;

  /// Optional error message if status is failed.
  final String? errorMessage;

  const DataSource({
    required this.id,
    required this.name,
    required this.fullName,
    required this.dataDescription,
    required this.status,
    this.lastSyncAt,
    this.lastSyncRecords,
    this.lastSyncDurationSec,
    this.lastSyncFailed,
    this.errorMessage,
  });

  /// Creates a copy of this DataSource with updated fields.
  DataSource copyWith({
    String? id,
    String? name,
    String? fullName,
    String? dataDescription,
    SyncStatus? status,
    DateTime? lastSyncAt,
    int? lastSyncRecords,
    int? lastSyncDurationSec,
    int? lastSyncFailed,
    String? errorMessage,
  }) {
    return DataSource(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      dataDescription: dataDescription ?? this.dataDescription,
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncRecords: lastSyncRecords ?? this.lastSyncRecords,
      lastSyncDurationSec: lastSyncDurationSec ?? this.lastSyncDurationSec,
      lastSyncFailed: lastSyncFailed ?? this.lastSyncFailed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Formatted string for last sync time (e.g., "10:45 WIB" or "3 menit lalu").
  String get lastSyncFormatted {
    if (lastSyncAt == null) return 'Belum pernah';
    final now = DateTime.now();
    final diff = now.difference(lastSyncAt!);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  /// Formatted record count string.
  String get recordsFormatted {
    if (lastSyncRecords == null) return '—';
    final n = lastSyncRecords!;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  /// Returns true if there were any failed records.
  bool get hasFailures => lastSyncFailed != null && lastSyncFailed! > 0;
}

// ─── PerformanceDataPoint Model ───────────────────────────────────────────────

/// A single data point for the 24-hour performance chart.
class PerformancePoint {
  /// Hour of the day (0–23).
  final int hour;

  /// API response time in milliseconds.
  final double responseTimeMs;

  const PerformancePoint({required this.hour, required this.responseTimeMs});
}

// ─── DashboardState ───────────────────────────────────────────────────────────

/// The complete state object for the Dashboard screen.
class DashboardState {
  final bool isLoading;
  final String? errorMessage;
  final List<DataSource> dataSources;
  final List<PerformancePoint> performanceData;
  final DateTime? lastRefreshedAt;

  const DashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.dataSources = const [],
    this.performanceData = const [],
    this.lastRefreshedAt,
  });

  /// Shortcut: count of connected sources.
  int get activeCount =>
      dataSources.where((s) => s.status == SyncStatus.connected).length;

  /// Shortcut: count of sources in error or offline state.
  int get errorCount => dataSources
      .where(
        (s) => s.status == SyncStatus.failed || s.status == SyncStatus.offline,
      )
      .length;

  /// Shortcut: count of sources currently syncing.
  int get syncingCount =>
      dataSources.where((s) => s.status == SyncStatus.syncing).length;

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<DataSource>? dataSources,
    List<PerformancePoint>? performanceData,
    DateTime? lastRefreshedAt,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      dataSources: dataSources ?? this.dataSources,
      performanceData: performanceData ?? this.performanceData,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}
