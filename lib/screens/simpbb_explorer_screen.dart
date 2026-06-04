import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/objek_pajak.dart';
import '../providers/simpbb_provider.dart';

class SimpbbExplorerScreen extends ConsumerStatefulWidget {
  const SimpbbExplorerScreen({super.key});

  @override
  ConsumerState<SimpbbExplorerScreen> createState() =>
      _SimpbbExplorerScreenState();
}

class _SimpbbExplorerScreenState extends ConsumerState<SimpbbExplorerScreen> {
  final _queryController = TextEditingController(text: 'BUDI');
  bool _showSearchResults = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(objekPajakSearchProvider.notifier).search(_queryController.text);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(objekPajakSearchProvider);
    final listState = ref.watch(objekPajakListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(title: const Text('Objek Pajak SIMPBB')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Pencarian Objek Pajak',
            style: GoogleFonts.barlow(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data diambil melalui middleware IntegraTax, bukan langsung dari aplikasi mobile ke SIMPBB.',
            style: AppTypography.bodyMedium(context),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _queryController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            style: AppTypography.bodyLarge(context),
            decoration: InputDecoration(
              labelText: 'Nama WP atau kata kunci',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderNormal),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _runSearch,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.person_search_rounded),
                  label: const Text('Search'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadListDetails,
                  icon: const Icon(Icons.table_rows_rounded),
                  label: const Text('List Details'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showSearchResults
                ? _SearchResultsView(state: searchState, onRetry: _runSearch)
                : _ListDetailsView(state: listState, onRetry: _loadListDetails),
          ),
        ],
      ),
    );
  }

  void _runSearch() {
    setState(() => _showSearchResults = true);
    ref.read(objekPajakSearchProvider.notifier).search(_queryController.text);
  }

  void _loadListDetails() {
    setState(() => _showSearchResults = false);
    ref
        .read(objekPajakListProvider.notifier)
        .load(search: _queryController.text);
  }
}

class _SearchResultsView extends StatelessWidget {
  final AsyncValue<List<ObjekPajakSearchResult>> state;
  final VoidCallback onRetry;

  const _SearchResultsView({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const _LoadingCard(label: 'Mencari objek pajak...'),
      error: (error, stackTrace) =>
          _ErrorCard(message: '$error', onRetry: onRetry),
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyCard(message: 'Belum ada hasil pencarian.');
        }
        return Column(
          key: const ValueKey('search-results'),
          children: items.map((item) => _ObjekPajakCard(item: item)).toList(),
        );
      },
    );
  }
}

class _ListDetailsView extends StatelessWidget {
  final AsyncValue<List<ObjekPajakListItem>> state;
  final VoidCallback onRetry;

  const _ListDetailsView({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const _LoadingCard(label: 'Memuat daftar objek pajak...'),
      error: (error, stackTrace) =>
          _ErrorCard(message: '$error', onRetry: onRetry),
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyCard(message: 'Tidak ada data untuk filter ini.');
        }
        return Column(
          key: const ValueKey('list-details'),
          children: items.map((item) => _ObjekPajakCard(item: item)).toList(),
        );
      },
    );
  }
}

class _ObjekPajakCard extends StatelessWidget {
  final ObjekPajakSearchResult item;

  const _ObjekPajakCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final listItem = item is ObjekPajakListItem
        ? item as ObjekPajakListItem
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardElevated(accentColor: AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.namaWajibPajak, style: AppTypography.bodyLarge(context)),
          const SizedBox(height: 6),
          Text(item.jalanObjekPajak, style: AppTypography.bodyMedium(context)),
          const SizedBox(height: 12),
          _InfoRow(label: 'NOP', value: item.nop),
          if (listItem != null) ...[
            _InfoRow(label: 'Luas Bumi', value: '${listItem.luasBumi} m2'),
            _InfoRow(
              label: 'Luas Bangunan',
              value: '${listItem.totalLuasBangunan} m2',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium(context)),
          ),
          Text(value, style: AppTypography.dataMedium(context)),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String label;

  const _LoadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTypography.bodyMedium(context)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Text(message, style: AppTypography.bodyMedium(context)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorCard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('error'),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(borderColor: AppColors.statusError),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTypography.bodyMedium(
              context,
            ).copyWith(color: AppColors.statusError),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ],
      ),
    );
  }
}
