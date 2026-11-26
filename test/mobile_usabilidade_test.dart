import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connecta_trip_app/views/autenticacao_view.dart';
import 'package:connecta_trip_app/widgets/confirmar_acao.dart';

void main() {
  testWidgets('login e cadastro cabem em tela estreita com texto ampliado', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: const AutenticacaoView(),
    ));
    expect(find.image(const AssetImage('assets/logo.jpg')), findsOneWidget);
    await tester.ensureVisible(find.text('Não tem conta? Cadastre-se'));
    await tester.tap(find.text('Não tem conta? Cadastre-se'));
    await tester.pumpAndSettle();
    expect(find.image(const AssetImage('assets/logo.jpg')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar confirmação preserva a ação pendente', (tester) async {
    bool? resultado;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      TextButton(onPressed: () async {
        resultado = await confirmarAcao(context, titulo: 'Aceitar proposta?',
          mensagem: 'Confira as condições.', confirmar: 'Aceitar');
      }, child: const Text('Abrir')))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(resultado, isFalse);
  });
}
