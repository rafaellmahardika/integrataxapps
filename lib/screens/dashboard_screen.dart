// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/data_source.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/status_card.dart';
import '../widgets/performance_chart.dart';
import 'approval_screen.dart';
import 'log_screen.dart';
import 'notification_screen.dart';
import 'simpbb_explorer_screen.dart';
import 'source_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _enableDevTools = bool.fromEnvironment('ENABLE_DEV_TOOLS');
  int _selectedIndex = 0;

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(dashboardProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Memantau data dari state management Riverpod
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor:
          AppColors.bgBase, // Latar belakang sangat gelap (0xFF070B14)
      body: Stack(
        children: [
          // ── 1. BACKGROUND HEADER LENGKUNG (SWOOSH) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                height: 190,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF009B74), // Emerald Dark
                      Color(0xFF00E6A0), // Emerald Light
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

          // ── 2. KONTEN UTAMA (SCROLLABLE) ──
          SafeArea(
            bottom: false,
            child: _selectedIndex == 0
                ? _buildDashboardTab(state)
                : _buildSelectedTab(),
          ),

          // ── 3. CUSTOM BOTTOM NAVIGATION BAR ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  // ─── WIDGET BANTUAN ────────────────────────────────────────────────────────

  Widget _buildDashboardTab(DashboardState state) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF00C689),
      backgroundColor: AppColors.bgSurface,
      child: state.isLoading && state.dataSources.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C689)),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'INTEGRATAX.',
                          style: GoogleFonts.barlow(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'MODE DEMO',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Halo, ',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: 'Admin!',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_enableDevTools)
                        IconButton(
                          tooltip: 'SIMPBB Explorer',
                          onPressed: _openSimpbbExplorer,
                          icon: const Icon(
                            Icons.api_rounded,
                            color: Colors.white,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Logout',
                        onPressed: () => _confirmLogout(context, ref),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsRow(state),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...state.dataSources.map(
                  (source) => Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 16,
                    ),
                    child: StatusCard(
                      source: source,
                      onTap: () => _openSourceDetail(source),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildChartSection(state),
                ),
              ],
            ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 1:
        return const NotificationScreen();
      case 2:
        return const ApprovalScreen();
      case 3:
        return const LogScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _openSourceDetail(DataSource source) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SourceDetailScreen(source: source),
      ),
    );
  }

  void _openSimpbbExplorer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SimpbbExplorerScreen()),
    );
  }

  /// Membangun baris kotak statistik (Sumber Aktif, Error Aktif, Terakhir Update)
  Widget _buildStatsRow(DashboardState state) {
    final activeCount = state.dataSources
        .where((s) => s.status == SyncStatus.connected)
        .length;
    final errorCount = state.dataSources.where((s) => s.hasFailures).length;

    // Kalkulasi format waktu "Terakhir Update"
    String updateText = 'Baru saja';
    if (state.lastRefreshedAt != null) {
      final diff = DateTime.now().difference(state.lastRefreshedAt!);
      if (diff.inMinutes > 0 && diff.inMinutes < 60) {
        updateText = '${diff.inMinutes}m lalu';
      } else if (diff.inHours > 0) {
        updateText = '${diff.inHours}j lalu';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderNormal, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildStatItem(
              'Sumber Aktif',
              activeCount.toString(),
              const Color(0xFF00C689),
            ),
            const VerticalDivider(color: AppColors.borderNormal, thickness: 1),
            _buildStatItem(
              'Error Aktif',
              errorCount.toString(),
              AppColors.statusError,
            ),
            const VerticalDivider(color: AppColors.borderNormal, thickness: 1),
            _buildStatItem('Terakhir Update', updateText, Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun bagian wadah (container) untuk grafik performa
  Widget _buildChartSection(DashboardState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderNormal, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMA RESPON API (24 JAM)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          if (state.performanceData.isNotEmpty)
            SizedBox(
              height: 160,
              child: PerformanceChart(data: state.performanceData),
            )
          else
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Tidak ada data performa',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Membangun navigasi bawah bergaya kapsul (pill) melayang yang modern
  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00C689), // Emerald Green Utama
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C689).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_rounded, 'Dashboard', 0),
            _buildNavItem(Icons.notifications_rounded, 'Notifikasi', 1),
            _buildNavItem(Icons.check_rounded, 'Approval', 2),
            _buildNavItem(Icons.format_list_bulleted_rounded, 'Log', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    const unselectedColor = Color(0xFF02543B); // Hijau sangat gelap
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF00C689) : unselectedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF00C689) : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout confirmation ───────────────────────────────────────────────────

  static Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.statusWarning,
          size: 36,
        ),
        title: const Text('Keluar dari sesi?'),
        content: const Text(
          'Anda akan keluar dari dashboard. Semua data sesi saat ini akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusError,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(authProvider.notifier).logout();
    }
  }
}

// ─── CLIPPER KUSTOM UNTUK BACKGROUND MELENGKUNG ──────────────────────────────

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50); // Titik awal lengkungan kiri

    // Tarikan kurva (x kontrol, y kontrol, x akhir, y akhir)
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 90, // Titik akhir lengkungan kanan
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
