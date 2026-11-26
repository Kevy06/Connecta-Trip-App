import '../models/destino.dart';
import '../models/viagem.dart';
import '../services/destino_service.dart';
import '../services/viagem_service.dart';
import '../utils/formatadores.dart';

/// Estado e regras do formulário de solicitação (documento, seções 3.2 e 3.3):
/// valida os campos, guarda o que foi digitado (para nova tentativa em caso
/// de erro) e grava a solicitação pelo serviço.
class SolicitacaoPresenter {
  static const int totalEtapas = 4;
  static const int maxViajantes = 20;
  static const int maxObservacoes = 500;

  static const List<List<String>> _camposPorEtapa = [
    ['destino', 'periodo'],
    ['viajantes', 'orcamento'],
    ['interesses', 'observacoes'],
  ];

  final ViagemService _service;
  final DateTime? _hojeFixo;
  final Duration atrasoSimulado;

  Destino? destino;
  DateTime? inicio;
  DateTime? fim;
  int viajantes = 2;
  String? orcamento;
  String observacoes = '';
  final Set<String> interesses;

  /// Mensagens de erro por campo.
  final Map<String, String> erros = {};

  SolicitacaoPresenter({
    this.destino,
    Set<String>? interessesIniciais,
    String observacoesIniciais = '',
    ViagemService? service,
    DateTime? hoje,
    this.atrasoSimulado = const Duration(milliseconds: 600),
  })  : _service = service ?? ViagemService(),
        _hojeFixo = hoje,
        interesses = <String>{...?interessesIniciais} {
    observacoes = observacoesIniciais;
  }

  List<Destino> get destinosDisponiveis => DestinoService().obterDestinos();

  DateTime get _hoje {
    final h = _hojeFixo ?? DateTime.now();
    return DateTime(h.year, h.month, h.day);
  }

  String? get periodoTexto =>
      (inicio == null || fim == null) ? null : Formatadores.periodo(inicio!, fim!);

  // --- Alterações ---

  void definirPeriodo(DateTime ida, DateTime volta) {
    inicio = ida;
    fim = volta;
    erros.remove('periodo');
  }

  void alterarViajantes(int delta) {
    viajantes = (viajantes + delta).clamp(1, maxViajantes);
    erros.remove('viajantes');
  }

  void alternarInteresse(String interesse) {
    if (!interesses.remove(interesse)) interesses.add(interesse);
    erros.remove('interesses');
  }

  // --- Validação ---

  String? _validar(String campo) {
    switch (campo) {
      case 'destino':
        return destino == null ? 'Escolha um destino.' : null;
      case 'periodo':
        if (inicio == null || fim == null) return 'Selecione o período da viagem.';
        if (inicio!.isBefore(_hoje)) return 'A data de ida não pode estar no passado.';
        if (!fim!.isAfter(inicio!)) return 'A volta precisa ser depois da ida.';
        return null;
      case 'viajantes':
        return (viajantes < 1 || viajantes > maxViajantes)
            ? 'Informe de 1 a $maxViajantes viajantes.'
            : null;
      case 'orcamento':
        return orcamento == null ? 'Selecione uma faixa de orçamento.' : null;
      case 'interesses':
        return interesses.isEmpty ? 'Selecione ao menos um serviço.' : null;
      case 'observacoes':
        return observacoes.length > maxObservacoes
            ? 'Use no máximo $maxObservacoes caracteres.'
            : null;
    }
    return null;
  }

  /// Valida uma etapa (0 a 2) ou, com 3, o formulário inteiro.
  /// Preenche [erros] e devolve `true` se está tudo certo.
  bool validarEtapa(int etapa) {
    final campos = etapa < _camposPorEtapa.length
        ? _camposPorEtapa[etapa]
        : _camposPorEtapa.expand((c) => c).toList();
    var ok = true;
    for (final campo in campos) {
      final erro = _validar(campo);
      if (erro == null) {
        erros.remove(campo);
      } else {
        erros[campo] = erro;
        ok = false;
      }
    }
    return ok;
  }

  /// Primeira etapa (0 a 2) com campo inválido, ou null se tudo estiver certo.
  int? primeiraEtapaComErro() {
    for (var i = 0; i < _camposPorEtapa.length; i++) {
      if (!validarEtapa(i)) return i;
    }
    return null;
  }

  // --- Envio ---

  /// Devolve a viagem criada, ou null se houver campos inválidos.
  Future<Viagem?> enviar() async {
    if (!validarEtapa(totalEtapas - 1)) return null;
    if (atrasoSimulado > Duration.zero) {
      await Future<void>.delayed(atrasoSimulado); // simula a chamada à API
    }
    return await _service.criar(
      destino: destino!,
      inicio: inicio!,
      fim: fim!,
      viajantes: viajantes,
      orcamento: orcamento!,
      interesses: Set.of(interesses),
      observacoes: observacoes.trim(),
    );
  }
}
