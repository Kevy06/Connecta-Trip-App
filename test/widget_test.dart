import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connecta_trip_app/models/viagem.dart';
import 'package:connecta_trip_app/models/destino.dart';
import 'package:connecta_trip_app/presenters/solicitacao_presenter.dart';
import 'package:connecta_trip_app/views/autenticacao_view.dart';

void main() {
  final hoje = DateTime(2026, 11, 7);
  final destino = Destino(id: '1', nome: 'Cancún', pais: 'México',
    subtitulo: 'Praias', descricaoCurta: 'Pacotes', imagemUrl: '', categoria: 'Praias');

  test('validação: destino e datas são obrigatórios', () {
    final p = SolicitacaoPresenter(hoje: hoje, atrasoSimulado: Duration.zero);
    expect(p.validarEtapa(0), false);
    expect(p.erros.containsKey('destino'), true);
    expect(p.erros.containsKey('periodo'), true);
  });

  test('validação: impede ida no passado', () {
    final p = SolicitacaoPresenter(destino: destino, hoje: hoje);
    p.definirPeriodo(DateTime(2026, 11, 6), DateTime(2026, 11, 10));
    expect(p.validarEtapa(0), false);
    expect(p.erros['periodo'], contains('passado'));
  });

  test('validação: impede volta antes da ida', () {
    final p = SolicitacaoPresenter(destino: destino, hoje: hoje);
    p.definirPeriodo(DateTime(2026, 11, 12), DateTime(2026, 11, 10));
    expect(p.validarEtapa(0), false);
  });

  test('validação: viajantes respeitam o limite', () {
    final p = SolicitacaoPresenter(hoje: hoje);
    p.alterarViajantes(100);
    expect(p.viajantes, SolicitacaoPresenter.maxViajantes);
    p.alterarViajantes(-100);
    expect(p.viajantes, 1);
  });

  test('validação: orçamento e serviços obrigatórios', () {
    final p = SolicitacaoPresenter(hoje: hoje);
    expect(p.validarEtapa(1), false);
    expect(p.validarEtapa(2), false);
    p.orcamento = faixasOrcamento.first;
    p.alternarInteresse('Hospedagem');
    expect(p.validarEtapa(1), true);
    expect(p.validarEtapa(2), true);
  });

  test('modelo: serialização preserva status, propostas e avaliação', () {
    final v = Viagem(
      id: 'v1', donoId: 'u1', destino: destino,
      inicio: DateTime(2026, 11, 12), fim: DateTime(2026, 11, 19),
      viajantes: 2, orcamento: faixasOrcamento[1],
      interesses: {'Passagem', 'Hospedagem'}, criadaEm: hoje,
      status: StatusViagem.encerrada,
      avaliacao: const Avaliacao(nota: 5, comentario: 'Excelente'),
    )..registrarEvento('Solicitação concluída');
    final restaurada = Viagem.fromJson(v.toJson(), [destino]);
    expect(restaurada.status, StatusViagem.encerrada);
    expect(restaurada.interesses.contains('Passagem'), true);
    expect(restaurada.avaliacao?.nota, 5);
    expect(restaurada.historico.length, 1);
  });

  testWidgets('tela de login e cadastro tem campos e perfis', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AutenticacaoView()));
    expect(find.text('Connecta Trip'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    await tester.tap(find.text('Não tem conta? Cadastre-se'));
    await tester.pump();
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Viajante'), findsOneWidget);
    expect(find.text('Consultor'), findsOneWidget);
  });
}
