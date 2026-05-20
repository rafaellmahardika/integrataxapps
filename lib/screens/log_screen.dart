import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/sync_log.dart';
import '../providers/mock_data_provider.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(syncLogsProvider);

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
        const Row(
          children: [
            _FilterChip(label: 'Semua', selected: true),
            SizedBox(width: 8),
            _FilterChip(label: 'Gagal'),
            SizedBox(width: 8),
            _FilterChip(label: 'Review'),
          ],
        ),
        const SizedBox(height: 18),
        ...logs.map((log) => _LogCard(item: log)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
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
