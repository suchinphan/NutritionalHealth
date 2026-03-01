// removed unused import: dart:convert
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  final String baseUrl;
  ApiClient(this.baseUrl);

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    int timeoutSeconds = 8,
  }) {
    return _send(
      'POST',
      path,
      headers: headers,
      body: body,
      timeoutSeconds: timeoutSeconds,
    );
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    int timeoutSeconds = 8,
  }) {
    return _send('GET', path, headers: headers, timeoutSeconds: timeoutSeconds);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    int timeoutSeconds = 8,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final authToken = AuthService().token;
    // Merge headers; allow caller to request skipping automatic Authorization
    final skipAuth =
        headers != null &&
        (headers['X-Skip-Auth'] == '1' || headers['X-Skip-Auth'] == 'true');
    final h = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    // Remove control header before sending
    if (h.containsKey('X-Skip-Auth')) h.remove('X-Skip-Auth');
    // Add Authorization only when not skipped and not already provided
    if (!skipAuth && authToken != null && !h.containsKey('Authorization')) {
      h['Authorization'] = 'Bearer $authToken';
    }
    try {
      if (method == 'POST') {
        final fut = http.post(uri, headers: h, body: body);
        return await fut.timeout(Duration(seconds: timeoutSeconds));
      }
      final fut = http.get(uri, headers: h);
      return await fut.timeout(Duration(seconds: timeoutSeconds));
    } on TimeoutException catch (e) {
      rethrow;
    }
  }
}
