import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/app_notification.dart';
import '../providers/mock_data_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  NotificationSeverity? _filter; // null = show all

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(notificationsProvider);
    final unreadCount = entries.where((e) => !e.isRead).length;

    // Apply severity filter
    final filtered = _filter == null
        ? entries
        : entries.where((e) => e.notification.severity == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 120),
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notifikasi',
                        style: GoogleFonts.barlow(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusError,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Riwayat alert sinkronisasi dan anomali data.',
                    style: AppTypography.bodyMedium(context),
                  ),
                ],
              ),
            ),
            // ── Mark all read button ────────────────────────────────────────
            if (unreadCount > 0)
              TextButton.icon(
                onPressed: () {
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                },
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Tandai semua'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textAccent,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Severity filter chips ────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Semua',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              const SizedBox(width: 8),
              ...NotificationSeverity.values.map(
                (sev) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: sev.label,
                    color: sev.color,
                    selected: _filter == sev,
                    onTap: () =>
                        setState(() => _filter = (_filter == sev) ? null : sev),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── List / empty state ───────────────────────────────────────────────
        if (filtered.isEmpty)
          _EmptyState(hasFilter: _filter != null)
        else
          ...filtered.map(
            (entry) => _NotificationCard(
              item: entry.notification,
              isRead: entry.isRead,
              onMarkRead: () {
                ref
                    .read(notificationsProvider.notifier)
                    .markAsRead(entry.notification.id);
              },
              onDismiss: () {
                ref
                    .read(notificationsProvider.notifier)
                    .dismiss(entry.notification.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifikasi dihapus.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Notification card with swipe-to-dismiss ──────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final bool isRead;
  final VoidCallback onMarkRead;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.item,
    required this.isRead,
    required this.onMarkRead,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.statusError.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.statusError,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: isRead ? null : onMarkRead,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration:
              AppDecorations.cardElevated(
                accentColor: item.severity.color,
              ).copyWith(
                color: isRead ? AppColors.bgSurface : AppColors.bgElevated,
              ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.severity.color.withValues(
                    alpha: isRead ? 0.08 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.severity.icon,
                  color: item.severity.color.withValues(
                    alpha: isRead ? 0.5 : 1.0,
                  ),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.bodyLarge(context).copyWith(
                              color: isRead
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.severity.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: AppTypography.bodyMedium(context).copyWith(
                        color: isRead
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.severity.label} • ${relativeTime(item.createdAt)}',
                          style: AppTypography.dataSmall(context),
                        ),
                        if (!isRead)
                          GestureDetector(
                            onTap: onMarkRead,
                            child: Text(
                              'Tandai dibaca',
                              style: AppTypography.dataSmall(context).copyWith(
                                color: AppColors.textAccent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.18)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : AppColors.borderNormal,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            hasFilter
                ? Icons.filter_list_off_rounded
                : Icons.notifications_off_outlined,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Tidak ada notifikasi untuk filter ini.'
                : 'Tidak ada notifikasi saat ini.',
            style: AppTypography.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
