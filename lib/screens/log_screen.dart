import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/sync_log.dart';
import '../providers/mock_data_provider.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  SyncLogStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(syncLogsProvider);
    final logs = _selectedStatus == null
        ? allLogs
        : allLogs.where((log) => log.status == _selectedStatus).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 120),
      children: [
        Text(
          'Log',
          style: GoogleFonts.barlow(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Riwayat sinkronisasi dan akses data sensitif.',
          style: AppTypography.bodyMedium(context),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _FilterChip(
              label: 'Semua',
              selected: _selectedStatus == null,
              onTap: () => setState(() => _selectedStatus = null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Gagal',
              selected: _selectedStatus == SyncLogStatus.failed,
              onTap: () =>
                  setState(() => _selectedStatus = SyncLogStatus.failed),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Review',
              selected: _selectedStatus == SyncLogStatus.review,
              onTap: () =>
                  setState(() => _selectedStatus = SyncLogStatus.review),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card(),
            child: Text(
              'Tidak ada log untuk filter ini.',
              style: AppTypography.bodyMedium(context),
            ),
          )
        else
          ...logs.map((log) => _LogCard(item: log)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bgInput,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderNormal,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final SyncLog item;

  const _LogCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardElevated(accentColor: item.status.color),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 54,
            decoration: BoxDecoration(
              color: item.status.color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.sourceName, style: AppTypography.bodyLarge(context)),
                const SizedBox(height: 4),
                Text(item.message, style: AppTypography.bodyMedium(context)),
                if (item.nop != null) ...[
                  const SizedBox(height: 4),
                  Text(item.nop!, style: AppTypography.dataSmall(context)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.status.label,
                style: AppTypography.dataSmall(
                  context,
                ).copyWith(color: item.status.color),
              ),
              const SizedBox(height: 6),
              Text(
                relativeTime(item.timestamp),
                style: AppTypography.dataSmall(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
