import 'package:flutter/foundation.dart';

import '../models/destino.dart';
import '../models/viagem.dart';
import 'consultor_service.dart';
import 'destino_service.dart';

/// Repositório em memória das solicitações/viagens do viajante.
///
/// Segue o fluxo do documento: enviada → em análise → proposta recebida →
/// aceita → encerrada. Não emite bilhetes, não cobra e não consulta tarifas.
/// Ao integrar a API REST, os métodos públicos mantêm a mesma assinatura.
class ViagemService extends ChangeNotifier {
  static final ViagemService _instance = ViagemService.isolado();
  factory ViagemService() => _instance;

  /// Instância independente (usada nos testes) já com os dados de exemplo.
  ViagemService.isolado() {
    _popularExemplos();
  }

  final List<Viagem> _viagens = [];
  int _contadorViagem = 0;
  int _contadorProposta = 0;

  DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  /// Mais recentes primeiro.
  List<Viagem> obterViagens() {
    final copia = [..._viagens];
    copia.sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
    return List.unmodifiable(copia);
  }

  Viagem? obterPorId(String id) {
    for (final v in _viagens) {
      if (v.id == id) return v;
    }
    return null;
  }

  Viagem criar({
    required Destino destino,
    required DateTime inicio,
    required DateTime fim,
    required int viajantes,
    required String orcamento,
    required Set<String> interesses,
    String observacoes = '',
  }) {
    final viagem = _registrar(
      destino: destino,
      inicio: inicio,
      fim: fim,
      viajantes: viajantes,
      orcamento: orcamento,
      interesses: interesses,
      observacoes: observacoes,
      criadaEm: DateTime.now(),
      status: StatusViagem.enviada,
    );
    notifyListeners();
    return viagem;
  }

  /// O viajante aceita a proposta recebida.
  bool aceitarProposta(String id) {
    final viagem = obterPorId(id);
    if (viagem == null || viagem.status != StatusViagem.propostaRecebida) return false;
    viagem.status = StatusViagem.aceita;
    notifyListeners();
    return true;
  }

  /// Avaliação só após o encerramento e uma única vez.
  bool avaliar(String id, int nota, String comentario) {
    final viagem = obterPorId(id);
    if (viagem == null ||
        viagem.status != StatusViagem.encerrada ||
        viagem.avaliacao != null ||
        nota < 1 ||
        nota > 5) {
      return false;
    }
    viagem.avaliacao = Avaliacao(nota: nota, comentario: comentario.trim());
    notifyListeners();
    return true;
  }

  /// Simula o lado do consultor (que ainda não existe sem backend), avançando
  /// o status um passo. Usado só em modo debug para demonstrar a jornada.
  void avancarStatusDemo(String id) {
    final viagem = obterPorId(id);
    if (viagem == null) return;
    switch (viagem.status) {
      case StatusViagem.enviada:
        viagem.status = StatusViagem.emAnalise;
      case StatusViagem.emAnalise:
        viagem.proposta = _gerarProposta(viagem);
        viagem.status = StatusViagem.propostaRecebida;
      case StatusViagem.propostaRecebida:
        viagem.status = StatusViagem.aceita;
      case StatusViagem.aceita:
        viagem.status = StatusViagem.encerrada;
      case StatusViagem.encerrada:
        return;
    }
    notifyListeners();
  }

  // --- Internos ---

  Viagem _registrar({
    required Destino destino,
    required DateTime inicio,
    required DateTime fim,
    required int viajantes,
    required String orcamento,
    required Set<String> interesses,
    required DateTime criadaEm,
    required StatusViagem status,
    String observacoes = '',
  }) {
    _contadorViagem++;
    final viagem = Viagem(
      id: 'v$_contadorViagem',
      destino: destino,
      inicio: inicio,
      fim: fim,
      viajantes: viajantes,
      orcamento: orcamento,
      interesses: Set.of(interesses),
      observacoes: observacoes,
      criadaEm: criadaEm,
      roteiro: _montarRoteiro(destino),
      status: status,
    );
    _viagens.add(viagem);
    return viagem;
  }

  /// Roteiro de exemplo (a tela marca como "Exemplo de roteiro").
  List<ItemRoteiro> _montarRoteiro(Destino d) {
    final (titulo, descricao) = switch (d.categoria) {
      'Praias' => ('Praia e descanso', 'Dia livre para aproveitar as praias de ${d.nome}.'),
      'Europa' => ('Cultura e história', 'Dia livre para conhecer os principais pontos de ${d.nome}.'),
      'Resorts' => ('Parques e diversão', 'Dia para aproveitar as atrações de ${d.nome}.'),
      _ => ('Dia livre', 'Dia livre para explorar ${d.nome}.'),
    };
    return [
      const ItemRoteiro(
        dia: 1,
        titulo: 'Chegada e traslado',
        descricao: 'Recepção no aeroporto e traslado até o hotel.',
      ),
      ItemRoteiro(dia: 2, titulo: titulo, descricao: descricao),
      const ItemRoteiro(
        dia: 3,
        titulo: 'Passeio a escolher',
        descricao: 'Sugestões de passeios opcionais.',
      ),
    ];
  }

  Proposta _gerarProposta(Viagem viagem) {
    final consultores = ConsultorService().obterConsultores();
    final consultor = consultores[_contadorProposta % consultores.length];
    _contadorProposta++;

    final noites = viagem.noites < 1 ? 1 : viagem.noites;
    var valor = 650.0 * noites * viagem.viajantes;
    if (viagem.interesses.contains('Passagem')) valor += 2200.0 * viagem.viajantes;

    final itens = <String>[
      ...viagem.destino.inclusoes,
      if (viagem.interesses.contains('Passagem')) 'Passagens aéreas (valor estimado)',
      if (viagem.interesses.contains('Milhas')) 'Alternativa com milhas, a combinar com o consultor',
      'Consultoria personalizada',
    ];

    return Proposta(
      id: 'p$_contadorProposta',
      consultor: consultor,
      valorEstimado: valor,
      itensIncluidos: itens,
      condicoes: 'Valores estimados e sujeitos à disponibilidade. '
          'A reserva e o pagamento são combinados diretamente com o consultor.',
      validade: _hoje().add(const Duration(days: 5)),
    );
  }

  void _popularExemplos() {
    final destinos = DestinoService().obterDestinos();
    final hoje = _hoje();

    final cancun = destinos.firstWhere((d) => d.id == '1', orElse: () => destinos.first);
    final inicioCancun = hoje.add(const Duration(days: 8));
    final v1 = _registrar(
      destino: cancun,
      inicio: inicioCancun,
      fim: inicioCancun.add(Duration(days: cancun.noites)),
      viajantes: 2,
      orcamento: faixasOrcamento[1],
      interesses: {'Passagem', 'Hospedagem'},
      criadaEm: hoje.subtract(const Duration(days: 10)),
      status: StatusViagem.aceita,
    );
    v1.proposta = _gerarProposta(v1);

    final paris = destinos.firstWhere((d) => d.id == '2', orElse: () => destinos.first);
    final inicioParis = hoje.add(const Duration(days: 45));
    final v2 = _registrar(
      destino: paris,
      inicio: inicioParis,
      fim: inicioParis.add(Duration(days: paris.noites)),
      viajantes: 2,
      orcamento: faixasOrcamento[2],
      interesses: {'Passagem', 'Hospedagem', 'Milhas'},
      observacoes: 'Quero incluir um passeio em Versalhes.',
      criadaEm: hoje.subtract(const Duration(days: 3)),
      status: StatusViagem.propostaRecebida,
    );
    v2.proposta = _gerarProposta(v2);
  }
}
