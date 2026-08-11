import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

/// Minimal API client for the POS backend.
///
/// Init-phase scaffolding only: single [http.Client] wrapped around the
/// backend base URL from [AppConfig]. Concrete business endpoints are
/// added by later tasks.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String baseUrl;

  Future<dynamic> get(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'));
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}