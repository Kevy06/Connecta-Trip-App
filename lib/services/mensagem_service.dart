import 'package:flutter/foundation.dart';
import '../data/banco_local.dart';
import '../models/mensagem.dart';
import '../models/consultor.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'sessao_service.dart';

/// Mensagens de atendimento com persistência local ou API, por titularidade.
class MensagemService extends ChangeNotifier {
  static final MensagemService _instancia = MensagemService._();
  factory MensagemService() => _instancia;
  MensagemService._();
  final List<Mensagem> _mensagens = [];
  String? erroConexao;

  List<Mensagem> obterMinhas() {
    final u = SessaoService().usuarioAtual;
    if (u == null) return [];
    final filtradas = _mensagens.where((m) => u.perfil == PerfilUsuario.consultor
        ? m.consultorId == u.id : m.viajanteId == u.id).toList();
    filtradas.sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
    return List.unmodifiable(filtradas);
  }

  Future<void> carregar() async {
    erroConexao = null;
    _mensagens.clear();
    if (SessaoService().usuarioAtual == null) { notifyListeners(); return; }
    try {
      final armazenadas = await BancoLocal().listarMensagens();
      _mensagens.addAll(armazenadas.map(Mensagem.fromJson));
      if (ApiService.habilitada) {
        try {
          final resposta = await ApiService().requisitar('GET', '/messages');
          _mensagens.clear();
          for (final r in resposta['mensagens'] as List) {
            final m = Mensagem.fromJson(Map<String, dynamic>.from(r as Map));
            _mensagens.add(m);
            await BancoLocal().salvarMensagem(m.id, m.viajanteId, m.consultorId, m.toJson());
          }
        } catch (e) { erroConexao = 'Falha de conexão: $e'; }
      }
    } catch (e) { erroConexao = 'Erro ao ler mensagens: $e'; }
    notifyListeners();
  }

  Future<void> enviar(Consultor consultor, String texto, {String assunto = ''}) async {
    final u = SessaoService().usuarioAtual;
    if (u == null || u.perfil != PerfilUsuario.viajante) {
      throw StateError('Entre como viajante para enviar uma mensagem.');
    }
    if (texto.trim().isEmpty || texto.trim().length > 1000) {
      throw ArgumentError('Escreva uma mensagem de até 1000 caracteres.');
    }
    Mensagem mensagem;
    if (ApiService.habilitada) {
      final dados = await ApiService().requisitar('POST', '/messages', corpo: {
        'consultorId': consultor.id, 'assunto': assunto, 'texto': texto.trim(),
      });
      mensagem = Mensagem.fromJson(Map<String, dynamic>.from(dados['mensagem'] as Map));
    } else {
      mensagem = Mensagem(id: 'm${DateTime.now().microsecondsSinceEpoch}',
        viajanteId: u.id, consultorId: consultor.id,
        consultorNome: consultor.nome, assunto: assunto, texto: texto.trim(),
        criadaEm: DateTime.now());
    }
    await BancoLocal().salvarMensagem(mensagem.id, mensagem.viajanteId,
      mensagem.consultorId, mensagem.toJson());
    _mensagens.add(mensagem);
    notifyListeners();
  }

  Future<bool> responder(Mensagem mensagem, String resposta) async {
    final u = SessaoService().usuarioAtual;
    if (u == null || u.perfil != PerfilUsuario.consultor ||
        u.id != mensagem.consultorId || mensagem.resposta != null ||
        resposta.trim().isEmpty || resposta.length > 1000) return false;
    if (ApiService.habilitada) {
      final dados = await ApiService().requisitar('POST',
        '/messages/${mensagem.id}/reply', corpo: {'resposta': resposta.trim()});
      final nova = Mensagem.fromJson(Map<String, dynamic>.from(dados['mensagem'] as Map));
      _mensagens.removeWhere((m) => m.id == mensagem.id);
      _mensagens.add(nova);
      mensagem = nova;
    } else {
      mensagem.resposta = resposta.trim();
      mensagem.respondidaEm = DateTime.now();
    }
    await BancoLocal().salvarMensagem(mensagem.id, mensagem.viajanteId,
      mensagem.consultorId, mensagem.toJson());
    notifyListeners();
    return true;
  }
}
