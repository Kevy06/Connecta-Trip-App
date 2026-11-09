import 'package:flutter/foundation.dart';
import '../data/banco_local.dart';
import '../models/consultor.dart';
import 'api_service.dart';
import 'sessao_service.dart';

/// Exibe somente consultores que realmente possuem cadastro no MVP.
class ConsultorService extends ChangeNotifier {
  static final ConsultorService _instancia = ConsultorService._();
  factory ConsultorService() => _instancia;
  ConsultorService._();
  final List<Consultor> _consultores = [];
  String? erroConexao;

  List<Consultor> obterConsultores() => List.unmodifiable(_consultores);

  Future<void> carregar() async {
    _consultores.clear();
    erroConexao = null;
    final usuario = SessaoService().usuarioAtual;
    if (usuario == null) { notifyListeners(); return; }
    if (ApiService.habilitada) {
      try {
        final resposta = await ApiService().requisitar('GET', '/consultants');
        for (final registro in resposta['consultores'] as List) {
          final dados = Map<String, dynamic>.from(registro as Map);
          _consultores.add(Consultor(
            id: dados['id'] as String,
            nome: dados['nome'] as String,
            especialidade: dados['especialidade'] as String? ?? 'Viagens personalizadas',
          ));
        }
      } catch (e) { erroConexao = 'Erro ao listar consultores: $e'; }
    } else {
      for (final linha in await BancoLocal().listarUsuariosConsultores()) {
        _consultores.add(Consultor(
          id: linha['id'] as String, nome: linha['nome'] as String,
          especialidade: 'Viagens personalizadas',
        ));
      }
    }
    notifyListeners();
  }
}
