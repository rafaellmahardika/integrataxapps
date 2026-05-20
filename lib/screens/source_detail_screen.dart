import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/data_source.dart';

class SourceDetailScreen extends StatelessWidget {
  final DataSource source;

  const SourceDetailScreen({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final logs = _buildLogs(source);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(title: Text(source.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppDecorations.cardElevated(
              accentColor: source.status.color,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      source.status.icon,
                      color: source.status.color,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        source.fullName,
                        style: AppTypography.bodyLarge(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  source.dataDescription,
                  style: AppTypography.bodyMedium(context),
                ),
                const SizedBox(height: 18),
                _MetricRow(label: 'Status', value: source.status.label),
                _MetricRow(
                  label: 'Sinkronisasi Terakhir',
                  value: source.lastSyncFormatted,
                ),
                _MetricRow(
                  label: 'Record Terakhir',
                  value: source.recordsFormatted,
                ),
                _MetricRow(
                  label: 'Gagal',
                  value: '${source.lastSyncFailed ?? 0} record',
                ),
                if (source.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    source.errorMessage!,
                    style: AppTypography.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.statusError),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '10 Log Sinkronisasi Terakhir',
            style: AppTypography.displayMedium(context),
          ),
          const SizedBox(height: 14),
          ...logs.map((log) => _DetailLogCard(log: log)),
        ],
      ),
    );
  }

  List<_DetailLog> _buildLogs(DataSource source) {
    return List.generate(10, (index) {
      final failed = source.status == SyncStatus.failed && index == 0;
      return _DetailLog(
        title: failed ? 'Sinkronisasi gagal' : 'Sinkronisasi selesai',
        message: failed
            ? source.errorMessage ?? 'Timeout koneksi'
            : '${source.recordsFormatted} record diproses',
        time: '${index + 1} jam lalu',
        color: failed ? AppColors.statusError : AppColors.statusOk,
      );
    });
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium(context)),
          ),
          Text(
            value,
            style: AppTypography.dataMedium(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DetailLog {
  final String title;
  final String message;
  final String time;
  final Color color;

  const _DetailLog({
    required this.title,
    required this.message,
    required this.time,
    required this.color,
  });
}

class _DetailLogCard extends StatelessWidget {
  final _DetailLog log;

  const _DetailLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: log.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.title, style: AppTypography.bodyLarge(context)),
                const SizedBox(height: 4),
                Text(log.message, style: AppTypography.bodyMedium(context)),
              ],
            ),
          ),
          Text(log.time, style: AppTypography.dataSmall(context)),
        ],
      ),
    );
  }
}
