import 'package:calorie_counter_app/features/sync/presentation/pending_logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('diálogo informa contagem e oferece ações acessíveis',
      (tester) async {
    PendingLogoutDecision? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return TextButton(
          onPressed: () async {
            result = await showPendingLogoutDialog(context, pendingCount: 3);
          },
          child: const Text('Abrir'),
        );
      }),
    ));

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 alterações serão perdidas'), findsOneWidget);
    expect(find.text('Continuar no app'), findsOneWidget);
    expect(find.text('Sair e apagar'), findsOneWidget);
    await tester.tap(find.text('Continuar no app'));
    await tester.pumpAndSettle();
    expect(result, PendingLogoutDecision.stay);
  });
}
