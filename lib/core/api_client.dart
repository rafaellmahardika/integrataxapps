// lib/core/api_client.dart
//
// IntegraTax API Client
// Handles ALL communication with the SIMPBB oRPC backend.
//
// CRITICAL PROTOCOL RULES (from SRS REQ-OTH-010 & REQ-NF-115):
//   1. Method   : Always HTTP POST
//   2. Header   : Content-Type: application/json
//   3. Request  : Body MUST be wrapped as {"json": { ...params... }}
//   4. Response : Data lives inside response.body["json"]["data"]
//
// Usage example:
//   final client = ApiClient();
//   final result = await client.post(
//     '/objekPajak/search',
//     params: {'query': 'BUDI', 'limit': 5},
//   );

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─── Custom Exceptions ────────────────────────────────────────────────────────

/// Thrown when the server returns a non-2xx status code.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? endpoint;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.endpoint,
  });

  @override
  String toString() => 'ApiException[$statusCode] on $endpoint: $message';
}

/// Thrown when the oRPC response wrapper is malformed.
class MalformedResponseException implements Exception {
  final String message;
  const MalformedResponseException(this.message);

  @override
  String toString() => 'MalformedResponseException: $message';
}

/// Thrown when the device has no internet connectivity.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

// ─── Response Model ───────────────────────────────────────────────────────────

/// Strongly-typed wrapper for a successful oRPC response.
class ApiResponse<T> {
  /// The unwrapped data from response["json"]["data"].
  final T data;

  /// The message field from the response, if present.
  final String? message;

  const ApiResponse({required this.data, this.message});
}

// ─── API Client ───────────────────────────────────────────────────────────────

class ApiClient {
  // Base URL for the SIMPBB oRPC API.
  // All requests are relative to this prefix.
  static const String _baseUrl = 'https://simpbb.technosmart.id/api/rpc';

  // Default timeout duration per request.
  static const Duration _timeout = Duration(seconds: 15);

  // Shared http.Client for connection reuse.
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  // ── Core Request Method ─────────────────────────────────────────────────────

  /// Sends a POST request to [path] (relative to base URL).
  ///
  /// [params] will be automatically wrapped into the oRPC format:
  ///   { "json": { ...params... } }
  ///
  /// The returned [ApiResponse.data] is the unwrapped value from:
  ///   response["json"]["data"]  (if it exists)
  ///   or response["json"]       (if "data" key is absent)
  ///
  /// Throws [NetworkException], [ApiException], or [MalformedResponseException].
  Future<ApiResponse<dynamic>> post(
    String path, {
    Map<String, dynamic> params = const {},
  }) async {
    final Uri uri = Uri.parse('$_baseUrl$path');

    // ── Step 1: Build the oRPC-compliant request body ──────────────────────
    // RULE: Every request body MUST be wrapped in {"json": { ...params... }}
    final Map<String, dynamic> requestBody = {'json': params};

    final String encodedBody = jsonEncode(requestBody);

    try {
      // ── Step 2: Execute HTTP POST ─────────────────────────────────────────
      final http.Response response = await _httpClient
          .post(
            uri,
            headers: {
              // RULE: Content-Type must always be application/json
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: encodedBody,
          )
          .timeout(_timeout);

      // ── Step 3: Handle HTTP-level errors ─────────────────────────────────
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: _extractErrorMessage(response.body),
          endpoint: path,
        );
      }

      // ── Step 4: Decode and unwrap the oRPC response ───────────────────────
      // RULE: Response data lives inside response["json"]["data"]
      return _unwrapResponse(response.body, path);
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Koneksi gagal: ${e.message}');
    } on FormatException catch (e) {
      throw MalformedResponseException(
        'Respons tidak valid (bukan JSON): ${e.message}',
      );
    }
    // ApiException, MalformedResponseException, NetworkException propagate up
  }

  // ── Convenience Typed Wrappers ──────────────────────────────────────────────

  /// POST and cast the response data as a [List].
  Future<ApiResponse<List<dynamic>>> postForList(
    String path, {
    Map<String, dynamic> params = const {},
  }) async {
    final response = await post(path, params: params);
    final data = response.data;
    if (data is List) {
      return ApiResponse(data: data, message: response.message);
    }
    // Some SIMPBB endpoints wrap list inside an object
    if (data is Map && data.containsKey('data')) {
      final inner = data['data'];
      if (inner is List) {
        return ApiResponse(data: inner, message: response.message);
      }
    }
    throw MalformedResponseException(
      'Expected List response from $path, got ${data.runtimeType}',
    );
  }

  /// POST and cast the response data as a [Map].
  Future<ApiResponse<Map<String, dynamic>>> postForMap(
    String path, {
    Map<String, dynamic> params = const {},
  }) async {
    final response = await post(path, params: params);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiResponse(data: data, message: response.message);
    }
    throw MalformedResponseException(
      'Expected Map response from $path, got ${data.runtimeType}',
    );
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  /// Unwraps the oRPC response envelope.
  ///
  /// Expected shape: { "json": { "data": <payload>, "message": "..." } }
  /// Fallback shape: { "json": <payload> }   (some endpoints omit "data")
  ApiResponse<dynamic> _unwrapResponse(String rawBody, String path) {
    late final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      throw MalformedResponseException(
        'Response from $path is not a JSON object.',
      );
    }

    // Outer "json" wrapper is required by oRPC spec
    if (!decoded.containsKey('json')) {
      throw MalformedResponseException(
        'Response from $path is missing the "json" wrapper field.',
      );
    }

    final dynamic jsonWrapper = decoded['json'];

    // Best case: jsonWrapper is a map with "data" key
    if (jsonWrapper is Map<String, dynamic>) {
      final dynamic data = jsonWrapper.containsKey('data')
          ? jsonWrapper['data']
          : jsonWrapper;
      final String? message = jsonWrapper['message'] as String?;
      return ApiResponse(data: data, message: message);
    }

    // Fallback: jsonWrapper IS the data (e.g., a raw list)
    return ApiResponse(data: jsonWrapper, message: null);
  }

  /// Attempts to parse an error message from a non-2xx response body.
  String _extractErrorMessage(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      return decoded['message'] as String? ??
          decoded['error'] as String? ??
          'Unknown server error';
    } catch (_) {
      return rawBody.isNotEmpty ? rawBody : 'Unknown server error';
    }
  }

  /// Releases the underlying HTTP client.
  void dispose() => _httpClient.close();
}

// ─── Singleton Instance ───────────────────────────────────────────────────────

/// Global singleton API client. Use this throughout the app.
/// Riverpod providers can also wrap this in a Provider for testability.
final apiClient = ApiClient();
