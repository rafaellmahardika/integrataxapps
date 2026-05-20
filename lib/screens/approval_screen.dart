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
        ...items.map(
          (item) => _ApprovalCard(
            item: item,
            onApprove: () {
              ref.read(approvalRequestsProvider.notifier).approve(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.title} disetujui.')),
              );
            },
            onReject: (reason) {
              ref
                  .read(approvalRequestsProvider.notifier)
                  .reject(item.id, reason);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${item.title} ditolak.')));
            },
          ),
        ),
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalRequest item;
  final VoidCallback onApprove;
  final ValueChanged<String> onReject;

  const _ApprovalCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

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
          if (item.decisionNote != null) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: ${item.decisionNote}',
              style: AppTypography.bodyMedium(
                context,
              ).copyWith(color: AppColors.textAccent),
            ),
          ],
          const SizedBox(height: 16),
          if (item.status == ApprovalStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(context),
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
                    onPressed: () => _approve(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            )
          else
            _StatusBanner(status: item.status),
        ],
      ),
    );
  }

  void _approve(BuildContext context) {
    onApprove();
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgElevated,
              title: const Text('Tolak Approval'),
              content: TextField(
                controller: controller,
                minLines: 3,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Masukkan alasan penolakan',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.length < 10) {
                      setDialogState(() {
                        errorText = 'Alasan minimal 10 karakter.';
                      });
                      return;
                    }
                    Navigator.of(context).pop(text);
                  },
                  child: const Text('Tolak'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (reason == null) return;

    onReject(reason);
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

class _StatusBanner extends StatelessWidget {
  final ApprovalStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == ApprovalStatus.approved
        ? AppColors.statusOk
        : AppColors.statusError;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.sectionBadge(color),
      child: Text(
        'Status: ${status.label}',
        style: AppTypography.bodyMedium(context).copyWith(color: color),
      ),
    );
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
