import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_client.dart';
import '../core/theme.dart';

class SimpbbExplorerScreen extends StatefulWidget {
  const SimpbbExplorerScreen({super.key});

  @override
  State<SimpbbExplorerScreen> createState() => _SimpbbExplorerScreenState();
}

class _SimpbbExplorerScreenState extends State<SimpbbExplorerScreen> {
  final _queryController = TextEditingController(text: 'BUDI');
  bool _isLoading = false;
  String _selectedEndpoint = '/wilayah/listPropinsi';
  String _result = 'Pilih endpoint lalu tekan Jalankan Request.';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(title: const Text('SIMPBB Explorer')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Cek Endpoint Publik',
            style: GoogleFonts.barlow(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Request dikirim langsung dengan wrapper oRPC {"json": {...}}.',
            style: AppTypography.bodyMedium(context),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EndpointChip(
                label: 'Propinsi',
                endpoint: '/wilayah/listPropinsi',
                selectedEndpoint: _selectedEndpoint,
                onSelected: _selectEndpoint,
              ),
              _EndpointChip(
                label: 'Search OP',
                endpoint: '/objekPajak/search',
                selectedEndpoint: _selectedEndpoint,
                onSelected: _selectEndpoint,
              ),
              _EndpointChip(
                label: 'List Details',
                endpoint: '/objekPajak/listDetails',
                selectedEndpoint: _selectedEndpoint,
                onSelected: _selectEndpoint,
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _queryController,
            style: AppTypography.bodyLarge(context),
            decoration: InputDecoration(
              labelText: 'Query Search',
              helperText: 'Dipakai untuk /objekPajak/search dan listDetails.',
              filled: true,
              fillColor: AppColors.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderNormal),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isLoading ? null : _runRequest,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isLoading ? 'Mengirim...' : 'Jalankan Request'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.card(),
            child: SelectableText(
              _result,
              style: AppTypography.dataSmall(
                context,
              ).copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  void _selectEndpoint(String endpoint) {
    setState(() => _selectedEndpoint = endpoint);
  }

  Future<void> _runRequest() async {
    setState(() {
      _isLoading = true;
      _result = 'Mengirim request ke $_selectedEndpoint...';
    });

    try {
      final response = await apiClient.post(
        _selectedEndpoint,
        params: _paramsForSelectedEndpoint(),
      );
      const encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _result = encoder.convert({
          'endpoint': _selectedEndpoint,
          'message': response.message,
          'data': response.data,
        });
      });
    } catch (e) {
      setState(() => _result = 'Request gagal:\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _paramsForSelectedEndpoint() {
    final query = _queryController.text.trim();
    switch (_selectedEndpoint) {
      case '/objekPajak/search':
        return {'query': query.isEmpty ? 'BUDI' : query, 'limit': 5};
      case '/objekPajak/listDetails':
        return {
          'kdPropinsi': '51',
          'limit': 10,
          'offset': 0,
          if (query.isNotEmpty) 'search': query,
        };
      default:
        return {};
    }
  }
}

class _EndpointChip extends StatelessWidget {
  final String label;
  final String endpoint;
  final String selectedEndpoint;
  final ValueChanged<String> onSelected;

  const _EndpointChip({
    required this.label,
    required this.endpoint,
    required this.selectedEndpoint,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = endpoint == selectedEndpoint;
    return GestureDetector(
      onTap: () => onSelected(endpoint),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
      ),
    );
  }
}
