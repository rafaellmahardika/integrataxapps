import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class BackendException implements Exception {
  final int? statusCode;
  final String message;

  const BackendException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'BackendException: $message'
      : 'BackendException[$statusCode]: $message';
}

class BackendClient {
  static const String _baseUrl = String.fromEnvironment(
    'INTEGRATAX_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _httpClient;

  BackendClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<dynamic> getJson(String path) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      return _decode(response);
    } on SocketException catch (e) {
      throw BackendException(
        'Tidak dapat terhubung ke middleware: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw BackendException('Koneksi middleware gagal: ${e.message}');
    }
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _decode(response);
    } on SocketException catch (e) {
      throw BackendException(
        'Tidak dapat terhubung ke middleware: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw BackendException('Koneksi middleware gagal: ${e.message}');
    }
  }

  dynamic _decode(http.Response response) {
    late final dynamic decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      throw BackendException(
        'Respons middleware bukan JSON valid.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Request middleware gagal.'
          : 'Request middleware gagal.';
      throw BackendException(message, statusCode: response.statusCode);
    }

    return decoded;
  }
}

final backendClient = BackendClient();
