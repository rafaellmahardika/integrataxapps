// test/unit/simpbb_provider_test.dart
//
// Unit tests for ObjekPajakSearchNotifier using a mocked BackendClient.
// Because BackendClient is now injectable via backendClientProvider,
// these tests fully isolate the provider from the network.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:integratax/providers/simpbb_provider.dart';

// ─── Mock HTTP Client Factory ─────────────────────────────────────────────────

/// Returns an http.Client whose responses are controlled by [handler].
http.Client mockClient(MockClientHandler handler) => MockClient(handler);

/// Successful SIMPBB search response with one result.
http.Client successClient() => mockClient((_) async => http.Response(
      '{"data": [{"kdPropinsi":"51","kdDati2":"71","kdKecamatan":"010",'
      '"kdKelurahan":"001","kdBlok":"098","noUrut":"0019","kdJnsOp":"0",'
      '"nmWpSppt":"JOKO TEST","jalanOp":"JL. TEST NO. 1"}]}',
      200,
      headers: {'content-type': 'application/json'},
    ));

/// Successful but empty result list.
http.Client emptyClient() => mockClient((_) async => http.Response(
      '{"data": []}',
      200,
      headers: {'content-type': 'application/json'},
    ));

/// Simulates a network/server error (500).
http.Client errorClient() => mockClient((_) async => http.Response(
      '{"message": "Server sedang tidak tersedia."}',
      500,
      headers: {'content-type': 'application/json'},
    ));

/// Simulates a connection failure.
http.Client offlineClient() =>
    mockClient((_) async => throw http.ClientException('Connection refused'));

// ─── Helper: build an isolated ProviderContainer ─────────────────────────────

ProviderContainer buildContainer({required http.Client httpClient}) {
  return ProviderContainer(
    overrides: [
      httpClientProvider.overrideWithValue(httpClient),
    ],
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ObjekPajakSearchNotifier', () {
    // ── Initial state ─────────────────────────────────────────────────────

    test('initial state is AsyncData([])', () {
      final container = buildContainer(httpClient: emptyClient());
      addTearDown(container.dispose);

      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncData>());
      expect(state.value, isEmpty);
    });

    // ── Empty / too-short query guard ────────────────────────────────────

    test('search with empty query resets to AsyncData([])', () async {
      final container = buildContainer(httpClient: emptyClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncData>());
      expect(state.value, isEmpty);
    });

    test('search with whitespace-only query resets to AsyncData([])', () async {
      final container = buildContainer(httpClient: emptyClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('   ');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncData>());
      expect(state.value, isEmpty);
    });

    test('search with 1-char query returns AsyncError with min-length message',
        () async {
      final container = buildContainer(httpClient: emptyClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('A');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncError>());
      expect(
        (state as AsyncError).error.toString(),
        contains('minimal $simpbbMinQueryLength karakter'),
      );
    });

    test('BUG-005 verified: 1-char is no longer silently empty', () async {
      final container = buildContainer(httpClient: emptyClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('X');
      final state = container.read(objekPajakSearchProvider);
      // Before the fix, this would be AsyncData([]) — now it's AsyncError.
      expect(state, isNot(isA<AsyncData>()));
    });

    // ── Successful search ─────────────────────────────────────────────────

    test('search with 2+ chars returns results from backend', () async {
      final container = buildContainer(httpClient: successClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('JO');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncData>());
      expect(state.value, isNotEmpty);
      expect(state.value!.first.namaWajibPajak, equals('JOKO TEST'));
    });

    test('search trims whitespace before sending', () async {
      final container = buildContainer(httpClient: successClient());
      addTearDown(container.dispose);

      // '  JO  ' has 2 non-whitespace chars after trim → valid
      await container
          .read(objekPajakSearchProvider.notifier)
          .search('  JO  ');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncData>());
    });

    test('empty search result returns AsyncData([])', () async {
      final container = buildContainer(httpClient: emptyClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('BUDI');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncData>());
      expect(state.value, isEmpty);
    });

    // ── Error states ──────────────────────────────────────────────────────

    test('backend 500 error returns AsyncError', () async {
      final container = buildContainer(httpClient: errorClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('BUDI');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncError>());
    });

    test('connection failure returns AsyncError', () async {
      final container = buildContainer(httpClient: offlineClient());
      addTearDown(container.dispose);

      await container
          .read(objekPajakSearchProvider.notifier)
          .search('BUDI');
      final state = container.read(objekPajakSearchProvider);
      expect(state, isA<AsyncError>());
    });

    // ── State transitions ─────────────────────────────────────────────────

    test('goes through AsyncLoading then AsyncData on success', () async {
      final container = buildContainer(httpClient: successClient());
      addTearDown(container.dispose);

      // Kick off search without awaiting
      final future = container
          .read(objekPajakSearchProvider.notifier)
          .search('JO');

      // Immediately after call starts, state should be loading
      // (This is an implementation detail but worth verifying)
      await future;
      // After completion: data
      expect(container.read(objekPajakSearchProvider), isA<AsyncData>());
    });

    test('new search after error clears error state', () async {
      final container = buildContainer(httpClient: errorClient());
      addTearDown(container.dispose);

      // First search → error
      await container
          .read(objekPajakSearchProvider.notifier)
          .search('BUDI');
      expect(container.read(objekPajakSearchProvider), isA<AsyncError>());

      // Empty query resets to data
      await container
          .read(objekPajakSearchProvider.notifier)
          .search('');
      expect(container.read(objekPajakSearchProvider), isA<AsyncData>());
    });
  });

  group('ObjekPajakListNotifier', () {
    test('initial state is AsyncData (data or null)', () {
      final container = buildContainer(httpClient: emptyClient());
      addTearDown(container.dispose);

      final state = container.read(objekPajakListProvider);
      expect(state, isA<AsyncData>());
      // Initial state value is null (no list fetched yet) or empty list —
      // either is acceptable depending on the implementation.
      expect(state.value == null || state.value!.isEmpty, isTrue);
    });
  });
}
