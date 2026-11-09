import 'consultor.dart';
import 'destino.dart';

const List<String> interessesDisponiveis =
  ['Passagem', 'Hospedagem', 'Traslado', 'Seguro', 'Milhas'];
const List<String> faixasOrcamento = [
  'Até R\$ 5 mil', 'R\$ 5 mil a R\$ 10 mil',
  'R\$ 10 mil a R\$ 20 mil', 'Acima de R\$ 20 mil',
];

enum StatusViagem {
  enviada('Enviada'), emAnalise('Em análise'),
  propostaRecebida('Proposta recebida'), aceita('Aceita'),
  encerrada('Encerrada');
  final String rotulo;
  const StatusViagem(this.rotulo);
  bool get confirmada => index >= StatusViagem.aceita.index;
}

class ItemRoteiro {
  final int dia;
  final String titulo;
  final String descricao;
  const ItemRoteiro({required this.dia, required this.titulo, required this.descricao});
  Map<String, dynamic> toJson() => {'dia': dia, 'titulo': titulo, 'descricao': descricao};
  factory ItemRoteiro.fromJson(Map<String, dynamic> json) => ItemRoteiro(
    dia: (json['dia'] as num).toInt(), titulo: json['titulo'] as String,
    descricao: json['descricao'] as String,
  );
}

class Proposta {
  final String id;
  final Consultor consultor;
  final double valorEstimado;
  final List<String> itensIncluidos;
  final String condicoes;
  final DateTime validade;
  const Proposta({required this.id, required this.consultor,
    required this.valorEstimado, required this.itensIncluidos,
    required this.condicoes, required this.validade});
  Map<String, dynamic> toJson() => {
    'id': id, 'consultorId': consultor.id, 'consultorNome': consultor.nome,
    'consultorEspecialidade': consultor.especialidade,
    'valorEstimado': valorEstimado, 'itensIncluidos': itensIncluidos,
    'condicoes': condicoes, 'validade': validade.toIso8601String(),
  };
  factory Proposta.fromJson(Map<String, dynamic> json) => Proposta(
    id: json['id'] as String,
    consultor: Consultor(
      id: json['consultorId'] as String,
      nome: json['consultorNome'] as String,
      especialidade: json['consultorEspecialidade'] as String? ?? 'Consultoria de viagens',
    ),
    valorEstimado: (json['valorEstimado'] as num).toDouble(),
    itensIncluidos: List<String>.from(json['itensIncluidos'] as List),
    condicoes: json['condicoes'] as String,
    validade: DateTime.parse(json['validade'] as String),
  );
}

class Avaliacao {
  final int nota;
  final String comentario;
  const Avaliacao({required this.nota, this.comentario = ''});
  Map<String, dynamic> toJson() => {'nota': nota, 'comentario': comentario};
  factory Avaliacao.fromJson(Map<String, dynamic> json) => Avaliacao(
    nota: (json['nota'] as num).toInt(),
    comentario: json['comentario'] as String? ?? '',
  );
}

class EventoViagem {
  final DateTime quando;
  final String descricao;
  const EventoViagem(this.quando, this.descricao);
  Map<String, dynamic> toJson() => {'quando': quando.toIso8601String(), 'descricao': descricao};
  factory EventoViagem.fromJson(Map<String, dynamic> json) => EventoViagem(
    DateTime.parse(json['quando'] as String), json['descricao'] as String,
  );
}

/// Solicitação associada a um dono, com propostas independentes e rastreabilidade.
class Viagem {
  final String id;
  final String donoId;
  final Destino destino;
  final DateTime inicio;
  final DateTime fim;
  final int viajantes;
  final String orcamento;
  final Set<String> interesses;
  final String observacoes;
  final DateTime criadaEm;
  final List<ItemRoteiro> roteiro;
  final List<Proposta> propostas;
  final List<EventoViagem> historico;
  StatusViagem status;
  String? propostaAceitaId;
  Avaliacao? avaliacao;

  Viagem({required this.id, required this.destino, required this.inicio,
    required this.fim, required this.viajantes, required this.orcamento,
    required this.interesses, required this.criadaEm, this.donoId = 'u1',
    this.observacoes = '', this.roteiro = const [],
    this.status = StatusViagem.enviada, List<Proposta>? propostas,
    List<EventoViagem>? historico, this.propostaAceitaId, this.avaliacao})
      : propostas = propostas ?? [], historico = historico ?? [];

  int get noites => fim.difference(inicio).inDays;
  Proposta? get proposta {
    if (propostaAceitaId != null) {
      for (final p in propostas) { if (p.id == propostaAceitaId) return p; }
    }
    return propostas.isEmpty ? null : propostas.first;
  }
  set proposta(Proposta? valor) {
    if (valor != null && !propostas.any((p) => p.id == valor.id)) propostas.add(valor);
  }
  void registrarEvento(String descricao) => historico.add(EventoViagem(DateTime.now(), descricao));

  Map<String, dynamic> toJson() => {
    'id': id, 'donoId': donoId, 'destinoId': destino.id,
    'inicio': inicio.toIso8601String(), 'fim': fim.toIso8601String(),
    'viajantes': viajantes, 'orcamento': orcamento,
    'interesses': interesses.toList(), 'observacoes': observacoes,
    'criadaEm': criadaEm.toIso8601String(), 'status': status.name,
    'roteiro': roteiro.map((e) => e.toJson()).toList(),
    'propostas': propostas.map((p) => p.toJson()).toList(),
    'historico': historico.map((e) => e.toJson()).toList(),
    'propostaAceitaId': propostaAceitaId, 'avaliacao': avaliacao?.toJson(),
  };

  factory Viagem.fromJson(Map<String, dynamic> json, List<Destino> destinos) {
    final destinoId = json['destinoId'] as String;
    final destino = destinos.firstWhere((d) => d.id == destinoId,
      orElse: () => destinos.first);
    final roteiroBruto = json['roteiro'] as List? ?? [];
    final propostasBrutas = json['propostas'] as List? ?? [];
    final historicoBruto = json['historico'] as List? ?? [];
    final avaliacaoBruta = json['avaliacao'];
    return Viagem(
      id: json['id'] as String, donoId: json['donoId'] as String,
      destino: destino, inicio: DateTime.parse(json['inicio'] as String),
      fim: DateTime.parse(json['fim'] as String),
      viajantes: (json['viajantes'] as num).toInt(),
      orcamento: json['orcamento'] as String,
      interesses: Set<String>.from(json['interesses'] as List),
      observacoes: json['observacoes'] as String? ?? '',
      criadaEm: DateTime.parse(json['criadaEm'] as String),
      status: StatusViagem.values.firstWhere((s) => s.name == json['status'],
        orElse: () => StatusViagem.enviada),
      roteiro: roteiroBruto.map((e) => ItemRoteiro.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      propostas: propostasBrutas.map((e) => Proposta.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      historico: historicoBruto.map((e) => EventoViagem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      propostaAceitaId: json['propostaAceitaId'] as String?,
      avaliacao: avaliacaoBruta == null ? null :
        Avaliacao.fromJson(Map<String, dynamic>.from(avaliacaoBruta as Map)),
    );
  }
}
