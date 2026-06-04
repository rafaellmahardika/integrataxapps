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
    // Varied log templates — each entry has a distinct action and message
    // so the detail screen doesn't show 10 nearly identical lines.
    // The first entry reflects the current status of the source.
    final String firstAction;
    final String firstMessage;
    final Color firstColor;

    switch (source.status) {
      case SyncStatus.failed:
        firstAction = 'Sinkronisasi gagal';
        firstMessage = source.errorMessage ?? 'Timeout koneksi';
        firstColor = AppColors.statusError;
      case SyncStatus.syncing:
        firstAction = 'Sinkronisasi berjalan';
        firstMessage = 'Sedang memproses ${source.recordsFormatted} record...';
        firstColor = AppColors.statusWarning;
      case SyncStatus.connected:
      default:
        firstAction = 'Sinkronisasi selesai';
        firstMessage = '${source.recordsFormatted} record diproses';
        firstColor = AppColors.statusOk;
    }

    final templates = [
      (action: firstAction, message: firstMessage, color: firstColor),
      (
        action: 'Validasi data',
        message: '${source.recordsFormatted} record lulus validasi skema',
        color: AppColors.statusOk,
      ),
      (
        action: 'Deduplikasi',
        message: 'Proses penghapusan duplikat selesai',
        color: AppColors.statusOk,
      ),
      (
        action: 'Koneksi dibuka',
        message: 'Middleware berhasil terhubung ke sumber data',
        color: AppColors.statusOk,
      ),
      (
        action: 'Retry #1',
        message: 'Mencoba ulang koneksi setelah timeout singkat',
        color: AppColors.statusWarning,
      ),
      (
        action: 'Sinkronisasi selesai',
        message: 'Batch pertama ${source.recordsFormatted} record selesai',
        color: AppColors.statusOk,
      ),
      (
        action: 'Kompresi data',
        message: 'Payload dikompresi sebelum transfer',
        color: AppColors.statusOk,
      ),
      (
        action: 'Autentikasi',
        message: 'Token API sumber data diperbarui',
        color: AppColors.statusOk,
      ),
      (
        action: 'Pengecekan integritas',
        message: 'Checksum seluruh record cocok',
        color: AppColors.statusOk,
      ),
      (
        action: 'Sesi ditutup',
        message: 'Koneksi ke sumber data ditutup dengan bersih',
        color: AppColors.statusOk,
      ),
    ];

    return List.generate(templates.length, (index) {
      final t = templates[index];
      final hoursAgo = index == 0 ? 'Baru saja' : '${index + 1} jam lalu';
      return _DetailLog(
        title: t.action,
        message: t.message,
        time: hoursAgo,
        color: t.color,
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
