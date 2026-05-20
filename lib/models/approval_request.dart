class ApprovalRequest {
  final String id;
  final String title;
  final String sourceName;
  final String operationType;
  final int affectedRecords;
  final ApprovalPriority priority;
  final ApprovalStatus status;
  final DateTime requestedAt;
  final String impactSummary;

  const ApprovalRequest({
    required this.id,
    required this.title,
    required this.sourceName,
    required this.operationType,
    required this.affectedRecords,
    required this.priority,
    required this.status,
    required this.requestedAt,
    required this.impactSummary,
  });
}

enum ApprovalPriority { low, medium, high }

enum ApprovalStatus { pending, approved, rejected }

extension ApprovalPriorityExtension on ApprovalPriority {
  String get label {
    switch (this) {
      case ApprovalPriority.low:
        return 'Rendah';
      case ApprovalPriority.medium:
        return 'Sedang';
      case ApprovalPriority.high:
        return 'Tinggi';
    }
  }
}

extension ApprovalStatusExtension on ApprovalStatus {
  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Menunggu';
      case ApprovalStatus.approved:
        return 'Disetujui';
      case ApprovalStatus.rejected:
        return 'Ditolak';
    }
  }
}
