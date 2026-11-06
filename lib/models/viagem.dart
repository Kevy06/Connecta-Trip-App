import 'consultor.dart';
import 'destino.dart';

/// Serviços que o viajante pode registrar como interesse (documento, seção 3.1).
/// "Milhas" apenas registra o interesse: não há consulta de saldo nem cotação.
const List<String> interessesDisponiveis = ['Passagem', 'Hospedagem', 'Milhas'];

const List<String> faixasOrcamento = [
  'Até R\$ 5 mil',
  'R\$ 5 mil a R\$ 10 mil',
  'R\$ 10 mil a R\$ 20 mil',
  'Acima de R\$ 20 mil',
];

/// Estados do atendimento (documento, seção 3.1).
enum StatusViagem {
  enviada('Enviada'),
  emAnalise('Em análise'),
  propostaRecebida('Proposta recebida'),
  aceita('Aceita'),
  encerrada('Encerrada');

  final String rotulo;
  const StatusViagem(this.rotulo);

  /// Documentos, voucher e avaliação só fazem sentido após o aceite.
  bool get confirmada => index >= StatusViagem.aceita.index;
}

class ItemRoteiro {
  final int dia;
  final String titulo;
  final String descricao;

  const ItemRoteiro({
    required this.dia,
    required this.titulo,
    required this.descricao,
  });
}

class Proposta {
  final String id;
  final Consultor consultor;
  final double valorEstimado;
  final List<String> itensIncluidos;
  final String condicoes;
  final DateTime validade;

  const Proposta({
    required this.id,
    required this.consultor,
    required this.valorEstimado,
    required this.itensIncluidos,
    required this.condicoes,
    required this.validade,
  });
}

/// Avaliação: só é permitida após o encerramento de um serviço concluído.
class Avaliacao {
  final int nota; // 1 a 5
  final String comentario;

  const Avaliacao({required this.nota, this.comentario = ''});
}

/// Uma solicitação de viagem do viajante e todo o seu acompanhamento.
/// (Na tela "Minhas viagens" ela aparece como "viagem".)
class Viagem {
  final String id;
  final Destino destino;
  final DateTime inicio;
  final DateTime fim;
  final int viajantes;
  final String orcamento;
  final Set<String> interesses;
  final String observacoes;
  final DateTime criadaEm;
  final List<ItemRoteiro> roteiro;

  StatusViagem status;
  Proposta? proposta;
  Avaliacao? avaliacao;

  Viagem({
    required this.id,
    required this.destino,
    required this.inicio,
    required this.fim,
    required this.viajantes,
    required this.orcamento,
    required this.interesses,
    required this.criadaEm,
    this.observacoes = '',
    this.roteiro = const [],
    this.status = StatusViagem.enviada,
    this.proposta,
    this.avaliacao,
  });

  int get noites => fim.difference(inicio).inDays;
}
