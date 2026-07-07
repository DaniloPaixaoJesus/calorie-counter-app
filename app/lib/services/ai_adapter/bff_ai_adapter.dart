import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter.dart';

typedef BffAiTransport = Future<BffAiResponse> Function({
  required Uri endpoint,
  required Map<String, String> headers,
  required Map<String, Object?> body,
  required Duration timeout,
});

class BffAiResponse {
  final int statusCode;
  final String body;

  const BffAiResponse({
    required this.statusCode,
    required this.body,
  });
}

class BffAiAdapter implements AiAdapter {
  static const _defaultEndpoint = String.fromEnvironment(
    'NUTRITY_BFF_MEAL_ESTIMATE_URL',
    defaultValue:
        'https://nutrity-bff-695228964694.southamerica-east1.run.app/bff-service/ai/meal-estimates',
  );

  static const _defaultApiKey = String.fromEnvironment(
    'NUTRITY_BFF_API_KEY',
    defaultValue: 'api_PD9d1LwncDiOINv6q2vyYxzTrVVyvEGc',
  );

  static const _defaultApiKeyHeader = String.fromEnvironment(
    'NUTRITY_BFF_API_KEY_HEADER',
    defaultValue: 'X-App-Api-Key',
  );

  final Uri endpoint;
  final String apiKey;
  final String apiKeyHeader;
  final Duration timeout;
  final String Function()? localeProvider;
  final BffAiTransport _transport;

  BffAiAdapter({
    Uri? endpoint,
    this.apiKey = _defaultApiKey,
    this.apiKeyHeader = _defaultApiKeyHeader,
    this.timeout = const Duration(seconds: 30),
    this.localeProvider,
    BffAiTransport? transport,
  })  : endpoint = endpoint ?? Uri.parse(_defaultEndpoint),
        _transport = transport ?? _postWithHttpClient;

  @override
  Future<AiEstimate> estimateCalories(String descricao) async {
    final normalizedDescription = descricao.trim();
    if (normalizedDescription.length < 2) {
      throw const AiAdapterException('Descrição muito curta');
    }
    if (normalizedDescription.length > 1000) {
      throw const AiAdapterException('Descrição muito longa (máx 1.000 chars)');
    }
    if (apiKey.trim().isEmpty) {
      throw const AiAdapterException('Chave do BFF não configurada');
    }

    final requestHeaders = {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      apiKeyHeader: apiKey,
    };
    final requestBody = {
      'descricao': normalizedDescription,
      'locale': localeProvider?.call() ?? 'en_US',
    };

    final response = await _transport(
      endpoint: endpoint,
      headers: requestHeaders,
      body: requestBody,
      timeout: timeout,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiAdapterException(
        _formatErrorMessage(
          response: response,
          endpoint: endpoint,
          headers: requestHeaders,
          body: requestBody,
        ),
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Resposta inválida');
      }

      return AiEstimate(
        descricaoInterpretada: _readString(decoded, 'descricaoInterpretada') ??
            normalizedDescription,
        calorias: _readInt(decoded, 'calorias') ?? 0,
        observacao: _readString(decoded, 'observacao'),
        confidence: _readDouble(decoded, 'confidence') ?? 0.0,
        iconKey: _readString(decoded, 'iconKey') ?? 'default',
        macronutrients: _readMacronutrients(decoded),
      );
    } on FormatException {
      throw const AiAdapterException('Resposta inválida do BFF');
    }
  }

  static Future<BffAiResponse> _postWithHttpClient({
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, Object?> body,
    required Duration timeout,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(endpoint).timeout(timeout);
      final encodedBody = utf8.encode(jsonEncode(body));

      headers.forEach(request.headers.set);
      request.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      request.headers.contentLength = encodedBody.length;
      request.add(encodedBody);

      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decodeStream(response).timeout(timeout);

      return BffAiResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } on SocketException {
      throw const AiAdapterException('Não foi possível conectar ao BFF');
    } on TimeoutException {
      throw const AiAdapterException('Tempo esgotado ao chamar o BFF');
    } finally {
      client.close(force: true);
    }
  }

  static String _formatErrorMessage({
    required BffAiResponse response,
    required Uri endpoint,
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    final apiMessage = _extractErrorMessage(response);
    final diagnostics = {
      'method': 'POST',
      'url': endpoint.toString(),
      'headers': _maskSensitiveHeaders(headers),
      'body': body,
      'responseBody': _tryDecodeJson(response.body) ?? response.body,
    };

    return '$apiMessage\n\nDetalhes da chamada:\n'
        '${const JsonEncoder.withIndent('  ').convert(diagnostics)}';
  }

  static String _extractErrorMessage(BffAiResponse response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final mensagem = _readString(decoded, 'mensagem');
        if (mensagem != null && mensagem.trim().isNotEmpty) {
          return mensagem;
        }
        final message = _readString(decoded, 'message');
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }
    } on FormatException {
      final plainBody = response.body.trim();
      if (plainBody.isNotEmpty) {
        return plainBody;
      }
    }

    return 'Falha ao estimar calorias';
  }

  static Map<String, String> _maskSensitiveHeaders(
    Map<String, String> headers,
  ) {
    return headers.map((key, value) {
      if (_isSensitiveHeader(key)) {
        return MapEntry(key, _maskSecret(value));
      }
      return MapEntry(key, value);
    });
  }

  static bool _isSensitiveHeader(String key) {
    final lower = key.toLowerCase();
    return lower == 'authorization' || lower.contains('api-key');
  }

  static String _maskSecret(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  static Object? _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value : null;
  }

  static int? _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return null;
  }

  static Macronutrients _readMacronutrients(Map<String, dynamic> json) {
    final value = json['macronutrients'];
    if (value is! Map<String, dynamic>) {
      return Macronutrients.zero;
    }

    return Macronutrients.fromGramValues(
      proteinGrams: _readInt(value, 'proteinGrams') ?? 0,
      carbohydrateGrams: _readInt(value, 'carbohydrateGrams') ?? 0,
      fatGrams: _readInt(value, 'fatGrams') ?? 0,
    );
  }
}
