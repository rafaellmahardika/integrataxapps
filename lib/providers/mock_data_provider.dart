import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../models/approval_request.dart';
import '../models/sync_log.dart';

// Wrap the notification with read/unread state locally.
class _NotificationEntry {
  final AppNotification notification;
  final bool isRead;
  const _NotificationEntry({required this.notification, this.isRead = false});
  _NotificationEntry copyWith({bool? isRead}) =>
      _NotificationEntry(notification: notification, isRead: isRead ?? this.isRead);
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<_NotificationEntry>>(
      (ref) => NotificationsNotifier(),
    );

class NotificationsNotifier extends StateNotifier<List<_NotificationEntry>> {
  NotificationsNotifier() : super(_buildInitialNotifications());

  void markAsRead(String id) {
    state = [
      for (final e in state)
        if (e.notification.id == id) e.copyWith(isRead: true) else e,
    ];
  }

  void markAllAsRead() {
    state = [for (final e in state) e.copyWith(isRead: true)];
  }

  void dismiss(String id) {
    state = [for (final e in state) if (e.notification.id != id) e];
  }
}

List<_NotificationEntry> _buildInitialNotifications() {
  final now = DateTime.now();
  return [
    _NotificationEntry(
      notification: AppNotification(
        id: 'notif-bpjs-timeout',
        title: 'BPJS gagal sinkronisasi',
        message: 'Timeout middleware BPJS melebihi 5 menit.',
        sourceId: 'bpjs',
        createdAt: now.subtract(const Duration(minutes: 10)),
        severity: NotificationSeverity.critical,
      ),
    ),
    _NotificationEntry(
      notification: AppNotification(
        id: 'notif-disdukcapil-syncing',
        title: 'Disdukcapil sedang sinkronisasi',
        message: 'Proses pencocokan NIK wajib pajak sedang berjalan.',
        sourceId: 'disdukcapil',
        createdAt: now.subtract(const Duration(minutes: 24)),
        severity: NotificationSeverity.warning,
      ),
    ),
    _NotificationEntry(
      notification: AppNotification(
        id: 'notif-bpn-success',
        title: 'BPN selesai sinkronisasi',
        message: '142.380 record objek pajak berhasil diperbarui.',
        sourceId: 'bpn',
        createdAt: now.subtract(const Duration(hours: 1)),
        severity: NotificationSeverity.success,
      ),
    ),
  ];
}

final approvalRequestsProvider =
    StateNotifierProvider<ApprovalRequestsNotifier, List<ApprovalRequest>>(
      (ref) => ApprovalRequestsNotifier(),
    );

class ApprovalRequestsNotifier extends StateNotifier<List<ApprovalRequest>> {
  ApprovalRequestsNotifier() : super(_buildInitialApprovalRequests());

  void approve(String id) {
    state = [
      for (final request in state)
        if (request.id == id)
          request.copyWith(
            status: ApprovalStatus.approved,
            decidedAt: DateTime.now(),
            decisionNote: 'Disetujui melalui mode demo.',
          )
        else
          request,
    ];
  }

  void reject(String id, String reason) {
    state = [
      for (final request in state)
        if (request.id == id)
          request.copyWith(
            status: ApprovalStatus.rejected,
            decidedAt: DateTime.now(),
            decisionNote: reason,
          )
        else
          request,
    ];
  }
}

List<ApprovalRequest> _buildInitialApprovalRequests() {
  final now = DateTime.now();
  return [
    ApprovalRequest(
      id: 'appr-bpn-merge-001',
      title: 'Merge data kepemilikan BPN',
      sourceName: 'BPN',
      operationType: 'Data Merge',
      affectedRecords: 1248,
      priority: ApprovalPriority.high,
      status: ApprovalStatus.pending,
      requestedAt: now.subtract(const Duration(minutes: 38)),
      impactSummary: 'Menggabungkan data tanah BPN dengan objek pajak SIMPBB.',
    ),
    ApprovalRequest(
      id: 'appr-dukcapil-nik-002',
      title: 'Pencocokan NIK Disdukcapil',
      sourceName: 'Disdukcapil',
      operationType: 'Identity Match',
      affectedRecords: 620,
      priority: ApprovalPriority.medium,
      status: ApprovalStatus.pending,
      requestedAt: now.subtract(const Duration(hours: 2)),
      impactSummary:
          'Memperbarui relasi NIK wajib pajak yang belum tervalidasi.',
    ),
  ];
}

final syncLogsProvider = Provider<List<SyncLog>>((ref) {
  final now = DateTime.now();
  return [
    SyncLog(
      id: 'log-bpn-ok-001',
      sourceName: 'BPN',
      action: 'Sync Complete',
      message: 'Sinkronisasi objek pajak selesai.',
      status: SyncLogStatus.success,
      timestamp: now.subtract(const Duration(minutes: 18)),
    ),
    SyncLog(
      id: 'log-bpjs-failed-001',
      sourceName: 'BPJS',
      action: 'API Timeout',
      message: 'Timeout saat mengambil profil ekonomi WP.',
      status: SyncLogStatus.failed,
      timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
    ),
    SyncLog(
      id: 'log-dukcapil-review-001',
      sourceName: 'Disdukcapil',
      action: 'Manual Review',
      message: '620 NIK membutuhkan tinjauan manual.',
      status: SyncLogStatus.review,
      timestamp: now.subtract(const Duration(hours: 1, minutes: 35)),
    ),
    SyncLog(
      id: 'log-simpbb-access-001',
      sourceName: 'SIMPBB',
      action: 'Sensitive Access',
      message: 'Akses profil objek pajak oleh Administrator IT.',
      // Privacy: NOP disamarkan sebagian di sisi klien.
      // Di produksi, penyamaran harus dilakukan di sisi server.
      nop: maskNop('32.04.010.001.001.0001.0'),
      status: SyncLogStatus.success,
      timestamp: now.subtract(const Duration(hours: 2, minutes: 18)),
    ),
  ];
});

String relativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

/// Partially masks a NOP (Nomor Objek Pajak) for display in logs.
///
/// Keeps the province and city prefix (first 2 dot-separated segments) to
/// provide geographic context, and replaces the remaining segments with
/// asterisk placeholders so the specific object cannot be identified.
///
/// Example: `32.04.010.001.001.0001.0` → `32.04.***.***.***.****.*`
///
/// NOTE: In production, masking must also be enforced server-side.
/// Client-side masking alone is not sufficient for compliance.
String maskNop(String nop) {
  final parts = nop.split('.');
  if (parts.length < 3) return nop; // Too short to mask meaningfully
  final visible = parts.take(2).join('.');
  final masked = parts.skip(2).map((p) => '*' * p.length).join('.');
  return '$visible.$masked';
}
