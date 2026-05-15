// lib/widgets/status_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/data_source.dart';

class StatusCard extends StatefulWidget {
  final DataSource source;
  final VoidCallback? onTap;

  const StatusCard({super.key, required this.source, this.onTap});

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.source.status == SyncStatus.syncing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source.status == SyncStatus.syncing) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    // Menggunakan warna khusus yang lebih cerah untuk UI Dark Mode
    Color statusColor;
    switch (source.status) {
      case SyncStatus.connected:
        statusColor = AppColors.statusOk;
        break;
      case SyncStatus.syncing:
        statusColor = AppColors.statusWarning;
        break;
      case SyncStatus.failed:
        statusColor = AppColors.statusError;
        break;
      default:
        statusColor = AppColors.statusOffline;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated, // Latar kartu gelap
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderNormal, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── GARIS WARNA (STRIPE) KIRI ──
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
              ),

              // ── KONTEN TENGAH ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul & Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            source.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _buildBadge(statusColor, source.status),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Subjudul (Nama Instansi Lengkap)
                      Text(
                        source.fullName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Deskripsi Data (Warna Biru/Cyan Terang)
                      Text(
                        source.dataDescription,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textAccent,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderNormal, height: 1),
                      const SizedBox(height: 12),

                      // Statistik Bawah (Terakhir & Record)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatColumn(
                              'Sinkronisasi Terakhir',
                              source.lastSyncFormatted,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.borderNormal,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatColumn(
                              'Record',
                              source.recordsFormatted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── IKON CHEVRON KANAN ──
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons
                      .keyboard_double_arrow_right_rounded, // Panah ganda ala UI modern
                  color: AppColors.textMuted,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk Badge Kapsul di Pojok Kanan Atas
  Widget _buildBadge(Color color, SyncStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SyncStatus.syncing) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Opacity(
                opacity: _pulseAnimation.value,
                child: const Icon(
                  Icons.sync_rounded,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Kolom Statistik Bawah
  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
