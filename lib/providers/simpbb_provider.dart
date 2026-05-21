import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/backend_client.dart';
import '../models/objek_pajak.dart';

final simpbbRepositoryProvider = Provider<SimpbbRepository>((ref) {
  return SimpbbRepository(backendClient);
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
    if (query.trim().length < 2) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.searchObjekPajak(query));
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
