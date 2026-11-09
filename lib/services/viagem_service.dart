import 'package:flutter/foundation.dart';
import '../data/banco_local.dart';
import '../models/destino.dart';
import '../models/consultor.dart';
import '../models/viagem.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'destino_service.dart';
import 'sessao_service.dart';

/// Repositório em memória sincronizado com SQLite; API REST opcional.
/// Regras de autorização são repetidas pelo servidor quando API_URL é usada.
class ViagemService extends ChangeNotifier {
  static final ViagemService _instancia = ViagemService.isolado();
  factory ViagemService() => _instancia;
  ViagemService.isolado();
  final List<Viagem> _viagens = [];
  String? erroConexao;
  bool carregando = false;
  Future<void> _filaGravacao = Future<void>.value();

  Usuario? get _usuario => SessaoService().usuarioAtual;
  List<Viagem> obterViagens() {
    final usuario = _usuario;
    if (usuario == null) return [];
    final copia = _viagens.where((v) =>
      usuario.perfil == PerfilUsuario.consultor || v.donoId == usuario.id).toList();
    copia.sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
    return List.unmodifiable(copia);
  }
  Viagem? obterPorId(String id) {
    for (final v in obterViagens()) { if (v.id == id) return v; }
    return null;
  }

  Future<void> carregar() async {
    carregando = true;
    erroConexao = null;
    notifyListeners();
    try {
      final registros = await BancoLocal().listarSolicitacoes();
      final destinos = DestinoService().obterDestinos();
      _viagens.clear();
      _viagens.addAll(registros.map((e) => Viagem.fromJson(e, destinos)));
      if (ApiService.habilitada && _usuario != null) {
        try {
          final resposta = await ApiService().requisitar('GET', '/trips');
          final lista = resposta['viagens'] as List;
          _viagens.clear();
          for (final item in lista) {
            final viagem = Viagem.fromJson(Map<String, dynamic>.from(item as Map), destinos);
            _viagens.add(viagem);
            await BancoLocal().salvarSolicitacao(viagem.id, viagem.donoId, viagem.toJson());
          }
        } catch (e) {
          erroConexao = 'Sem conexão com a API. Exibindo dados locais: $e';
        }
      }
    } catch (e) { erroConexao = 'Não foi possível ler o banco local: $e'; }
    carregando = false;
    notifyListeners();
  }

  void _guardar(Viagem v) {
    notifyListeners();
    _filaGravacao = _filaGravacao.catchError((Object _) {}).then<void>((_) async {
      await BancoLocal().salvarSolicitacao(v.id, v.donoId, v.toJson());
    });
  }
  Future<void> aguardarPersistencia() => _filaGravacao;

  Future<Viagem> criar({required Destino destino, required DateTime inicio,
    required DateTime fim, required int viajantes, required String orcamento,
    required Set<String> interesses, String observacoes = ''}) async {
    final usuario = _usuario;
    if (usuario == null || usuario.perfil != PerfilUsuario.viajante) {
      throw StateError('Somente viajantes podem enviar solicitações.');
    }
    if (inicio.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) ||
        !fim.isAfter(inicio) || viajantes < 1 || viajantes > 20 || interesses.isEmpty) {
      throw ArgumentError('Verifique datas, viajantes e serviços selecionados.');
    }
    final viagem = Viagem(
      id: 'v${DateTime.now().microsecondsSinceEpoch}', donoId: usuario.id,
      destino: destino, inicio: inicio, fim: fim, viajantes: viajantes,
      orcamento: orcamento, interesses: Set.of(interesses),
      observacoes: observacoes, criadaEm: DateTime.now(),
      roteiro: _roteiro(destino),
    )..registrarEvento('Solicitação enviada por ${usuario.nome}');
    if (ApiService.habilitada) {
      final resposta = await ApiService().requisitar('POST', '/trips', corpo: viagem.toJson());
      final criada = Viagem.fromJson(Map<String, dynamic>.from(resposta['viagem'] as Map),
        DestinoService().obterDestinos());
      _viagens.add(criada);
      _guardar(criada);
      await aguardarPersistencia();
      return criada;
    }
    _viagens.add(viagem);
    _guardar(viagem);
    await aguardarPersistencia();
    return viagem;
  }

  List<ItemRoteiro> _roteiro(Destino d) => [
    const ItemRoteiro(dia: 1, titulo: 'Chegada e traslado',
      descricao: 'Recepção no aeroporto, conforme disponibilidade.'),
    ItemRoteiro(dia: 2, titulo: 'Explorar ${d.nome}',
      descricao: 'Sugestão de passeio a combinar com o consultor.'),
    const ItemRoteiro(dia: 3, titulo: 'Dia livre',
      descricao: 'Atividades opcionais de acordo com seu perfil.'),
  ];

  Future<bool> iniciarAnalise(String id) async {
    final v = obterPorId(id);
    if (_usuario?.perfil != PerfilUsuario.consultor || v == null ||
        v.status != StatusViagem.enviada) return false;
    if (ApiService.habilitada) {
      final resposta = await ApiService().requisitar('POST', '/trips/$id/analyze');
      _substituirRemoto(resposta);
    } else {
      v.status = StatusViagem.emAnalise;
      v.registrarEvento('Atendimento iniciado por ${_usuario!.nome}');
      _guardar(v);
    }
    await aguardarPersistencia();
    return true;
  }

  Future<bool> enviarProposta(String id, double valor, List<String> itens,
      String condicoes, DateTime validade) async {
    final v = obterPorId(id);
    final usuario = _usuario;
    if (usuario == null || usuario.perfil != PerfilUsuario.consultor || v == null ||
        (v.status != StatusViagem.enviada && v.status != StatusViagem.emAnalise &&
         v.status != StatusViagem.propostaRecebida) ||
        valor <= 0 || itens.isEmpty || condicoes.trim().isEmpty ||
        !validade.isAfter(DateTime.now()) ||
        v.propostas.any((p) => p.consultor.id == usuario.id)) return false;
    if (ApiService.habilitada) {
      final resposta = await ApiService().requisitar('POST', '/trips/$id/proposals', corpo: {
        'valorEstimado': valor, 'itensIncluidos': itens,
        'condicoes': condicoes, 'validade': validade.toIso8601String(),
      });
      _substituirRemoto(resposta);
    } else {
      v.propostas.add(Proposta(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        consultor: ConsultorDoUsuario.criar(usuario),
        valorEstimado: valor, itensIncluidos: List.of(itens),
        condicoes: condicoes.trim(), validade: validade,
      ));
      v.status = StatusViagem.propostaRecebida;
      v.registrarEvento('Proposta recebida de ${usuario.nome}');
      _guardar(v);
    }
    await aguardarPersistencia();
    return true;
  }

  Future<bool> aceitarPropostaEscolhida(String id, String propostaId) async {
    final v = obterPorId(id);
    if (_usuario?.perfil != PerfilUsuario.viajante || v == null ||
        v.donoId != _usuario!.id || v.status != StatusViagem.propostaRecebida) return false;
    Proposta? escolhida;
    for (final p in v.propostas) { if (p.id == propostaId) escolhida = p; }
    if (escolhida == null || escolhida.validade.isBefore(DateTime.now())) return false;
    if (ApiService.habilitada) {
      final resposta = await ApiService().requisitar('POST', '/trips/$id/accept',
          corpo: {'propostaId': propostaId});
      _substituirRemoto(resposta);
    } else {
      v.propostaAceitaId = propostaId;
      v.status = StatusViagem.aceita;
      v.registrarEvento('Proposta de ${escolhida.consultor.nome} aceita');
      _guardar(v);
    }
    await aguardarPersistencia();
    return true;
  }

  Future<bool> encerrar(String id) async {
    final v = obterPorId(id);
    if (v == null || _usuario?.perfil != PerfilUsuario.consultor ||
        v.status != StatusViagem.aceita ||
        v.proposta?.consultor.id != _usuario?.id) return false;
    if (ApiService.habilitada) {
      final resposta = await ApiService().requisitar('POST', '/trips/$id/close');
      _substituirRemoto(resposta);
    } else {
      v.status = StatusViagem.encerrada;
      v.registrarEvento('Atendimento encerrado por ${_usuario!.nome}');
      _guardar(v);
    }
    await aguardarPersistencia();
    return true;
  }

  Future<bool> avaliarAsync(String id, int nota, String comentario) async {
    final v = obterPorId(id);
    if (_usuario?.perfil != PerfilUsuario.viajante || v == null ||
        v.donoId != _usuario!.id || v.status != StatusViagem.encerrada ||
        v.avaliacao != null || nota < 1 || nota > 5) return false;
    if (ApiService.habilitada) {
      final resposta = await ApiService().requisitar('POST', '/trips/$id/review',
          corpo: {'nota': nota, 'comentario': comentario});
      _substituirRemoto(resposta);
    } else {
      v.avaliacao = Avaliacao(nota: nota, comentario: comentario.trim());
      v.registrarEvento('Avaliação registrada: $nota estrela(s)');
      _guardar(v);
    }
    await aguardarPersistencia();
    return true;
  }

  void _substituirRemoto(Map<String, dynamic> resposta) {
    final atualizada = Viagem.fromJson(Map<String, dynamic>.from(resposta['viagem'] as Map),
      DestinoService().obterDestinos());
    _viagens.removeWhere((e) => e.id == atualizada.id);
    _viagens.add(atualizada);
    _guardar(atualizada);
  }


}

/// Converte uma conta de consultor para a entidade de proposta.
class ConsultorDoUsuario {
  static Consultor criar(Usuario usuario) => Consultor(
    id: usuario.id,
    nome: usuario.nome,
    especialidade: 'Consultoria personalizada de viagens',
  );
}
