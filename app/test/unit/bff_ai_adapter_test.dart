import 'dart:convert';

import 'package:calorie_counter_app/services/ai_adapter/ai_adapter.dart';
import 'package:calorie_counter_app/services/ai_adapter/bff_ai_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BffAiAdapter', () {
    test('envia descrição para endpoint público com X-App-Api-Key', () async {
      late Uri capturedEndpoint;
      late Map<String, String> capturedHeaders;
      late Map<String, Object?> capturedBody;

      final adapter = BffAiAdapter(
        transport: ({
          required endpoint,
          required headers,
          required body,
          required timeout,
        }) async {
          capturedEndpoint = endpoint;
          capturedHeaders = headers;
          capturedBody = body;

          return BffAiResponse(
            statusCode: 200,
            body: jsonEncode({
              'descricaoInterpretada': 'banana e ovo mexido',
              'calorias': 230,
              'observacao': 'Estimativa por porção média.',
              'confidence': 0.88,
              'iconKey': 'breakfast',
            }),
          );
        },
      );

      final estimate = await adapter.estimateCalories(' banana e ovo mexido ');

      expect(
        capturedEndpoint.toString(),
        'https://nutrity-bff-695228964694.southamerica-east1.run.app/bff-service/ai/meal-estimates',
      );
      expect(capturedHeaders['X-App-Api-Key'], isNotEmpty);
      expect(
          capturedHeaders['content-type'], 'application/json; charset=utf-8');
      expect(capturedBody['descricao'], 'banana e ovo mexido');
      expect(capturedBody.keys, ['descricao']);
      expect(estimate.descricaoInterpretada, 'banana e ovo mexido');
      expect(estimate.calorias, 230);
      expect(estimate.confidence, 0.88);
      expect(estimate.iconKey, 'breakfast');
    });

    test('converte erro do BFF em AiAdapterException', () async {
      final adapter = BffAiAdapter(
        apiKey: 'api_test_123456789',
        transport: ({
          required endpoint,
          required headers,
          required body,
          required timeout,
        }) async {
          return BffAiResponse(
            statusCode: 401,
            body: jsonEncode({'mensagem': 'API key inválida'}),
          );
        },
      );

      await expectLater(
        () => adapter.estimateCalories('arroz e feijão'),
        throwsA(
          isA<AiAdapterException>()
              .having((e) => e.message, 'message', contains('API key inválida'))
              .having((e) => e.message, 'method', contains('"method": "POST"'))
              .having(
                (e) => e.message,
                'url',
                contains(
                  '"url": "https://nutrity-bff-695228964694.southamerica-east1.run.app/bff-service/ai/meal-estimates"',
                ),
              )
              .having(
                (e) => e.message,
                'headers',
                contains('"X-App-Api-Key": "api_...6789"'),
              )
              .having(
                (e) => e.message,
                'body',
                contains('"descricao": "arroz e feijão"'),
              )
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
