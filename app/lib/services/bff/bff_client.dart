import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BffResponse {
  final int statusCode;
  final String body;

  const BffResponse({
    required this.statusCode,
    required this.body,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class BffClient {
  static const defaultBaseUrl = String.fromEnvironment(
    'NUTRITY_BFF_BASE_URL',
    defaultValue:
        'https://nutrity-bff-695228964694.southamerica-east1.run.app/bff-service',
  );

  static const defaultApiKey = String.fromEnvironment(
    'NUTRITY_BFF_API_KEY',
    defaultValue: 'api_PD9d1LwncDiOINv6q2vyYxzTrVVyvEGc',
  );

  static const defaultApiKeyHeader = String.fromEnvironment(
    'NUTRITY_BFF_API_KEY_HEADER',
    defaultValue: 'X-App-Api-Key',
  );

  final Uri baseUri;
  final String apiKey;
  final String apiKeyHeader;
  final Duration timeout;

  BffClient({
    Uri? baseUri,
    this.apiKey = defaultApiKey,
    this.apiKeyHeader = defaultApiKeyHeader,
    this.timeout = const Duration(seconds: 30),
  }) : baseUri = baseUri ?? Uri.parse(defaultBaseUrl);

  Uri resolve(String path) {
    final normalizedBase = baseUri.toString().endsWith('/')
        ? baseUri.toString()
        : '${baseUri.toString()}/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(normalizedBase).resolve(normalizedPath);
  }

  Future<BffResponse> get(String path, {String? bearerToken}) {
    return _send(
        method: 'GET', endpoint: resolve(path), bearerToken: bearerToken);
  }

  Future<BffResponse> post(
    String path,
    Map<String, Object?> body, {
    String? bearerToken,
  }) {
    return _send(
      method: 'POST',
      endpoint: resolve(path),
      body: body,
      bearerToken: bearerToken,
    );
  }

  Future<BffResponse> put(
    String path,
    Map<String, Object?> body, {
    String? bearerToken,
  }) {
    return _send(
      method: 'PUT',
      endpoint: resolve(path),
      body: body,
      bearerToken: bearerToken,
    );
  }

  Future<BffResponse> _send({
    required String method,
    required Uri endpoint,
    Map<String, Object?>? body,
    String? bearerToken,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.openUrl(method, endpoint).timeout(timeout);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.headers.set(apiKeyHeader, apiKey);
      if (bearerToken != null && bearerToken.trim().isNotEmpty) {
        request.headers.set(
            HttpHeaders.authorizationHeader, 'Bearer ${bearerToken.trim()}');
      }

      if (body != null) {
        final encodedBody = utf8.encode(jsonEncode(body));
        request.headers.contentLength = encodedBody.length;
        request.add(encodedBody);
      }

      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decodeStream(response).timeout(timeout);
      return BffResponse(statusCode: response.statusCode, body: responseBody);
    } finally {
      client.close(force: true);
    }
  }
}
