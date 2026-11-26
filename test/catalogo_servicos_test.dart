import 'package:flutter_test/flutter_test.dart';
import 'package:connecta_trip_app/models/opcao_catalogo.dart';
import 'package:connecta_trip_app/models/destino.dart';
import 'package:connecta_trip_app/presenters/solicitacao_presenter.dart';
import 'package:connecta_trip_app/models/viagem.dart';

void main() {
  test('cada destino tem alternativas de hotéis e rotas de pesquisa', () {
    for (final id in ['1','2','3']) {
      expect(CatalogoServicos.paraDestino(TipoServico.hospedagem,id).length, 2);
      expect(CatalogoServicos.paraDestino(TipoServico.passagem,id).length, 2);
    }
  });
  test('seleções novas mapeiam para os interesses corretos', () {
    expect(TipoServico.hospedagem.interesse,'Hospedagem');
    expect(TipoServico.passagem.interesse,'Passagem');
    expect(TipoServico.traslado.interesse,'Traslado');
    expect(TipoServico.seguro.interesse,'Seguro');
    expect(interessesDisponiveis, containsAll(['Traslado','Seguro']));
  });
  test('preferências selecionadas ficam no formulário e seguem a serialização', () {
    final d = Destino(id:'1',nome:'Cancún',pais:'México',subtitulo:'',
      descricaoCurta:'',imagemUrl:'',categoria:'Praias');
    final p = SolicitacaoPresenter(destino:d,interessesIniciais:{'Seguro'},
      observacoesIniciais:'Seguro ampliado; consultar exclusões.',
      atrasoSimulado:Duration.zero);
    expect(p.interesses, contains('Seguro'));
    expect(p.observacoes, contains('ampliado'));
    final v = Viagem(id:'v-teste',donoId:'u-teste',destino:d,
      inicio:DateTime(2026,12,1),fim:DateTime(2026,12,8),viajantes:2,
      orcamento:faixasOrcamento.first,interesses:p.interesses,
      observacoes:p.observacoes,criadaEm:DateTime(2026,11,8));
    final recuperada=Viagem.fromJson(v.toJson(),[d]);
    expect(recuperada.interesses,contains('Seguro'));
    expect(recuperada.observacoes,contains('ampliado'));
  });
}
