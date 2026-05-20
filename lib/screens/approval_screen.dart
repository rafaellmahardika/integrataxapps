import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/approval_request.dart';
import '../providers/mock_data_provider.dart';

class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(approvalRequestsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 120),
      children: [
        Text(
          'Approval',
          style: GoogleFonts.barlow(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Request operasi sensitif yang menunggu keputusan.',
          style: AppTypography.bodyMedium(context),
        ),
        const SizedBox(height: 20),
        ...items.map((item) => _ApprovalCard(item: item)),
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalRequest item;

  const _ApprovalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardElevated(accentColor: _priorityColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.bodyLarge(context),
                ),
              ),
              _Badge(label: item.priority.label, color: _priorityColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${item.sourceName} • ${item.affectedRecords} record • ${item.status.label}',
            style: AppTypography.bodyMedium(context),
          ),
          const SizedBox(height: 8),
          Text(item.impactSummary, style: AppTypography.bodyMedium(context)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusError,
                    side: const BorderSide(color: AppColors.statusError),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Setujui'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _priorityColor {
    switch (item.priority) {
      case ApprovalPriority.low:
        return AppColors.textAccent;
      case ApprovalPriority.medium:
        return AppColors.statusWarning;
      case ApprovalPriority.high:
        return AppColors.statusError;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppDecorations.sectionBadge(color),
      child: Text(
        label,
        style: AppTypography.dataSmall(context).copyWith(color: color),
      ),
    );
  }
}
