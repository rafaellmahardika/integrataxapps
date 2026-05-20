import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/app_notification.dart';
import '../providers/mock_data_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 120),
      children: [
        const _PageHeader(
          title: 'Notifikasi',
          subtitle: 'Riwayat alert sinkronisasi dan anomali data.',
        ),
        const SizedBox(height: 20),
        ...items.map((item) => _NotificationCard(item: item)),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardElevated(accentColor: item.severity.color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.severity.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.severity.icon,
              color: item.severity.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.bodyLarge(context)),
                const SizedBox(height: 6),
                Text(item.message, style: AppTypography.bodyMedium(context)),
                const SizedBox(height: 10),
                Text(
                  '${item.severity.label} • ${relativeTime(item.createdAt)}',
                  style: AppTypography.dataSmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.barlow(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTypography.bodyMedium(context)),
      ],
    );
  }
}
