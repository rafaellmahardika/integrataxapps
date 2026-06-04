import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// A full-screen error page shown when an unrecoverable or unexpected error occurs.
///
/// Usage:
///   - Wrap in [ErrorBoundary] for automatic catching.
///   - Or navigate to it explicitly: `Navigator.push(context, MaterialPageRoute(builder: (_) => ErrorPage(error: e)))`.
class ErrorPage extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorPage({
    super.key,
    this.error,
    this.stackTrace,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ?? 'Terjadi Kesalahan';
    final displayMessage = message ??
        (error != null
            ? _humanize(error!)
            : 'Operasi tidak dapat diselesaikan. Silakan coba lagi.');

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // ── Error Icon ─────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.statusError.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.statusError,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),
              // ── Title ──────────────────────────────────────────────────────
              Text(
                displayTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.barlow(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              // ── Message ────────────────────────────────────────────────────
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(context),
              ),
              // ── Technical detail (collapsed by default) ────────────────────
              if (error != null) ...[
                const SizedBox(height: 20),
                _TechDetail(error: error, stackTrace: stackTrace),
              ],
              const Spacer(),
              // ── Actions ────────────────────────────────────────────────────
              if (onRetry != null) ...[
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (Navigator.canPop(context))
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderNormal),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Converts a raw exception into a user-readable message in Indonesian.
  String _humanize(Object error) {
    final str = error.toString();
    if (str.contains('BackendException')) {
      // Strip class prefix for readability
      return str.replaceFirst(RegExp(r'BackendException\[?\d*\]?:\s*'), '');
    }
    if (str.contains('SocketException') || str.contains('ClientException')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    if (str.contains('TimeoutException') || str.contains('timeout')) {
      return 'Koneksi timeout. Server membutuhkan waktu terlalu lama untuk merespons.';
    }
    if (str.contains('FormatException') || str.contains('JSON')) {
      return 'Data yang diterima dari server tidak valid.';
    }
    // Fallback: show the raw message but truncated
    return str.length > 200 ? '${str.substring(0, 200)}…' : str;
  }
}

// ── Collapsible technical detail widget ──────────────────────────────────────

class _TechDetail extends StatefulWidget {
  final Object? error;
  final StackTrace? stackTrace;

  const _TechDetail({this.error, this.stackTrace});

  @override
  State<_TechDetail> createState() => _TechDetailState();
}

class _TechDetailState extends State<_TechDetail> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                _expanded ? 'Sembunyikan detail teknis' : 'Lihat detail teknis',
                style: AppTypography.dataSmall(context).copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderNormal),
            ),
            child: SelectableText(
              widget.error.toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppColors.statusError.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── ErrorBoundary widget ──────────────────────────────────────────────────────

/// Wraps a widget subtree and catches Flutter framework errors.
///
/// ```dart
/// ErrorBoundary(
///   child: MyScreen(),
///   onRetry: () { /* rebuild */ },
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const ErrorBoundary({super.key, required this.child, this.onRetry});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  void _reset() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorPage(
        error: _error,
        stackTrace: _stackTrace,
        onRetry: _reset,
      );
    }
    return widget.child;
  }

  // Called by Flutter when the widget tree under this widget throws.
  static _ErrorBoundaryState? _maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<_ErrorBoundaryState>();

  /// Report an error to the nearest [ErrorBoundary] ancestor.
  // ignore: unused_element
  static void report(BuildContext context, Object error,
      [StackTrace? stackTrace]) {
    _maybeOf(context)?._setState(error, stackTrace);
  }

  void _setState(Object error, StackTrace? stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }
}

// ── Inline error card (for use inside screens, not full page) ────────────────

/// A compact error card for inline display within a screen (e.g., a list item
/// or a section that failed to load). Less disruptive than a full [ErrorPage].
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.statusError.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.statusError, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTypography.bodyMedium(context).copyWith(
                    color: AppColors.statusError,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onRetry,
                    child: Text(
                      'Coba lagi →',
                      style: AppTypography.dataSmall(context).copyWith(
                        color: AppColors.statusError,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
