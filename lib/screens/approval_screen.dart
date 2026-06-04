import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/approval_request.dart';
import '../providers/mock_data_provider.dart';
import 'error_page.dart';

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
        // ── Empty state ──────────────────────────────────────────────────────
        if (items.isEmpty)
          _EmptyState()
        else
          ...items.map(
            (item) => _ApprovalCard(
              item: item,
              // Pass the screen-level context from ConsumerWidget.build so it
              // is always valid when ScaffoldMessenger is called after the dialog
              // closes (fixes the stale-context rejection bug).
              screenContext: context,
              onApprove: () {
                _safeApprove(context, ref, item);
              },
              onReject: (reason) {
                _safeReject(context, ref, item, reason);
              },
            ),
          ),
      ],
    );
  }

  // ── Guarded action helpers ───────────────────────────────────────────────

  static void _safeApprove(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest item,
  ) {
    try {
      ref.read(approvalRequestsProvider.notifier).approve(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} disetujui.'),
          backgroundColor: AppColors.statusOk,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, st) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Gagal menyetujui', e, st);
    }
  }

  static void _safeReject(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest item,
    String reason,
  ) {
    try {
      ref.read(approvalRequestsProvider.notifier).reject(item.id, reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} ditolak.'),
          backgroundColor: AppColors.statusError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, st) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Gagal menolak approval', e, st);
    }
  }

  static Future<void> _showErrorDialog(
    BuildContext context,
    String title,
    Object error,
    StackTrace stackTrace,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        icon: const Icon(
          Icons.error_outline_rounded,
          color: AppColors.statusError,
          size: 36,
        ),
        title: Text(title),
        content: ErrorCard(
          message: error.toString().length > 300
              ? '${error.toString().substring(0, 300)}…'
              : error.toString(),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusError,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 56,
            color: AppColors.statusOk.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada approval tertunda.',
            style: AppTypography.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalRequest item;
  final BuildContext screenContext;
  final VoidCallback onApprove;
  final ValueChanged<String> onReject;

  const _ApprovalCard({
    required this.item,
    required this.screenContext,
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
                    // Use screenContext so ScaffoldMessenger lookup is always
                    // valid — the card's own context may be stale after dialog.
                    onPressed: () => _showRejectDialog(screenContext),
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
                    onPressed: onApprove,
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

  Future<void> _showRejectDialog(BuildContext ctx) async {
    final controller = TextEditingController();
    String? errorText;
    int charCount = 0;
    const int minChars = 10;

    final reason = await showDialog<String>(
      context: ctx,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final bool meetsMinimum = charCount >= minChars;
            return AlertDialog(
              backgroundColor: AppColors.bgElevated,
              title: const Text('Tolak Approval'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 4,
                    autofocus: true,
                    onChanged: (value) {
                      setDialogState(() {
                        charCount = value.trim().length;
                        if (charCount >= minChars) errorText = null;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan alasan penolakan',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$charCount / $minChars karakter minimum',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      color: meetsMinimum
                          ? AppColors.statusOk
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.length < minChars) {
                      setDialogState(() {
                        errorText = 'Alasan minimal $minChars karakter.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(text);
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
