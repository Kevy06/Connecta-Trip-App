import '../models/usuario.dart';

/// Usuário logado. Por enquanto é fixo; será substituído pela autenticação
/// da API (semana 5 do plano de implementação).
class SessaoService {
  static final SessaoService _instance = SessaoService._interno();
  factory SessaoService() => _instance;
  SessaoService._interno();

  final Usuario usuarioAtual = const Usuario(
    id: 'u1',
    nome: 'Luiz Henrique',
    email: 'luiz@exemplo.com',
  );
}
