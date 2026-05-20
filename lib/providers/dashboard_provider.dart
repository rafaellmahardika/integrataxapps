// lib/providers/dashboard_provider.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import http dimatikan sementara karena kita pakai dummy data
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../models/data_source.dart';

// ─── Dashboard State ─────────────────────────────────────────────────────────

class DashboardState {
  final bool isLoading;
  final String? errorMessage;
  final List<DataSource> dataSources;
  final List<PerformancePoint> performanceData;
  final DateTime? lastRefreshedAt;

  const DashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.dataSources = const [],
    this.performanceData = const [],
    this.lastRefreshedAt,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<DataSource>? dataSources,
    List<PerformancePoint>? performanceData,
    DateTime? lastRefreshedAt,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dataSources: dataSources ?? this.dataSources,
      performanceData: performanceData ?? this.performanceData,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}

// ─── Provider Declaration ───────────────────────────────────────────────────

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier(),
    );

// ─── DashboardNotifier ──────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState()) {
    refresh();
  }

  Future<void> refresh() async {
    // Ubah status menjadi loading dan bersihkan error lama
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Simulasi delay jaringan selama 1.2 detik agar animasi loading di UI terlihat
      await Future.delayed(const Duration(milliseconds: 1200));

      // TODO: Replace with DashboardRepository backed by the IntegraTax middleware.

      // Mengambil data tiruan
      final sources = _buildDummyDataSources();
      final performance = _buildDummyPerformanceData();

      state = state.copyWith(
        isLoading: false,
        dataSources: sources,
        performanceData: performance,
        lastRefreshedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan sistem: ${e.toString()}',
      );
    }
  }

  void simulateStatusChange(String sourceId, SyncStatus newStatus) {
    final updated = state.dataSources.map((source) {
      if (source.id == sourceId) {
        return source.copyWith(
          status: newStatus,
          lastSyncAt: newStatus == SyncStatus.connected
              ? DateTime.now()
              : source.lastSyncAt,
          errorMessage: newStatus == SyncStatus.failed
              ? 'Koneksi timeout (HTTP 503)'
              : null,
        );
      }
      return source;
    }).toList();

    state = state.copyWith(dataSources: updated);
  }

  // ─── Data Tiruan (Dummy) ────────────────────────────────────────────────────

  List<DataSource> _buildDummyDataSources() {
    final now = DateTime.now();
    return [
      DataSource(
        id: 'bpn',
        name: 'BPN',
        fullName: 'Badan Pertanahan Nasional (Dummy Mode)',
        dataDescription: 'Data Objek Pajak (Simulasi Offline)',
        status: SyncStatus.connected,
        lastSyncAt: now,
        lastSyncRecords: 142380,
        lastSyncDurationSec: 2,
        lastSyncFailed: 0,
      ),
      DataSource(
        id: 'disdukcapil',
        name: 'Disdukcapil',
        fullName: 'Dinas Kependudukan & Catatan Sipil',
        dataDescription: 'Data identitas & NIK Wajib Pajak',
        status: SyncStatus.syncing,
        lastSyncAt: now.subtract(const Duration(minutes: 1)),
        lastSyncRecords: 98210,
        lastSyncDurationSec: null,
        lastSyncFailed: 0,
      ),
      DataSource(
        id: 'bpjs',
        name: 'BPJS',
        fullName: 'Badan Penyelenggara Jaminan Sosial',
        dataDescription: 'Data profil ekonomi Wajib Pajak',
        status: SyncStatus.failed,
        lastSyncAt: now.subtract(const Duration(hours: 3)),
        lastSyncRecords: 76540,
        lastSyncDurationSec: 30,
        lastSyncFailed: 205,
        errorMessage: 'Gagal terhubung ke middleware BPJS. Timeout.',
      ),
    ];
  }

  List<PerformancePoint> _buildDummyPerformanceData() {
    final rng = Random(42);
    final now = DateTime.now();
    final currentHour = now.hour;

    return List.generate(24, (i) {
      final hour = (currentHour - 23 + i) % 24;
      final bool isOfficeHour = hour >= 8 && hour <= 17;
      final bool isPeakHour =
          hour >= 10 && hour <= 12 || hour >= 14 && hour <= 16;

      double baseMs = isPeakHour
          ? (350 + rng.nextDouble() * 400)
          : isOfficeHour
          ? (150 + rng.nextDouble() * 200)
          : (60 + rng.nextDouble() * 80);
      if (rng.nextDouble() > 0.85) baseMs += 300 + rng.nextDouble() * 500;
      baseMs = baseMs.clamp(50.0, 1500.0);

      return PerformancePoint(
        hour: hour,
        responseTimeMs: double.parse(baseMs.toStringAsFixed(1)),
      );
    });
  }
}
