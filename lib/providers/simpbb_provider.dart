import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/backend_client.dart';
import '../models/objek_pajak.dart';

/// Minimum characters required for a SIMPBB search query.
const int simpbbMinQueryLength = 2;

/// Injected HTTP client — override in tests to avoid real network calls.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// Backend client provider — injectable and testable.
final backendClientProvider = Provider<BackendClient>((ref) {
  return BackendClient(httpClient: ref.watch(httpClientProvider));
});

final simpbbRepositoryProvider = Provider<SimpbbRepository>((ref) {
  return SimpbbRepository(ref.watch(backendClientProvider));
});

final objekPajakSearchProvider =
    StateNotifierProvider<
      ObjekPajakSearchNotifier,
      AsyncValue<List<ObjekPajakSearchResult>>
    >((ref) {
      return ObjekPajakSearchNotifier(ref.watch(simpbbRepositoryProvider));
    });

final objekPajakListProvider =
    StateNotifierProvider<
      ObjekPajakListNotifier,
      AsyncValue<List<ObjekPajakListItem>>
    >((ref) {
      return ObjekPajakListNotifier(ref.watch(simpbbRepositoryProvider));
    });

class SimpbbRepository {
  final BackendClient _client;

  const SimpbbRepository(this._client);

  Future<List<ObjekPajakSearchResult>> searchObjekPajak(String query) async {
    final decoded = await _client.postJson('/api/simpbb/search', {
      'query': query,
      'limit': 8,
    });
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ObjekPajakSearchResult.fromJson)
        .toList();
  }

  Future<List<ObjekPajakListItem>> listObjekPajak({String? search}) async {
    final decoded = await _client.postJson('/api/simpbb/list-details', {
      'kdPropinsi': '51',
      'limit': 10,
      'offset': 0,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    final rows = data is Map<String, dynamic> ? data['rows'] : null;
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ObjekPajakListItem.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> health() async {
    final decoded = await _client.getJson('/health');
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}

class ObjekPajakSearchNotifier
    extends StateNotifier<AsyncValue<List<ObjekPajakSearchResult>>> {
  final SimpbbRepository _repository;

  ObjekPajakSearchNotifier(this._repository) : super(const AsyncData([]));

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      // Field is blank — reset to empty without error.
      state = const AsyncData([]);
      return;
    }
    if (trimmed.length < simpbbMinQueryLength) {
      // Query too short — surface a user-friendly error rather than silently
      // returning an empty list (fixes BUG-005).
      state = AsyncError(
        'Kata kunci minimal $simpbbMinQueryLength karakter.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.searchObjekPajak(trimmed));
  }
}

class ObjekPajakListNotifier
    extends StateNotifier<AsyncValue<List<ObjekPajakListItem>>> {
  final SimpbbRepository _repository;

  ObjekPajakListNotifier(this._repository) : super(const AsyncData([]));

  Future<void> load({String? search}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.listObjekPajak(search: search),
    );
  }
}
