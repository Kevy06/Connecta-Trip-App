import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/banco_local.dart';

/// Configurar com: flutter run --dart-define=API_URL=http://10.0.2.2:3000
/// Sem API_URL o app funciona completamente offline, no SQLite do dispositivo.
class ApiService {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static bool get habilitada => baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> requisitar(String metodo, String caminho,
      {Map<String, dynamic>? corpo}) async {
    final token = await BancoLocal().preferencia('token_api');
    final resposta = http.Request(metodo, Uri.parse('$baseUrl$caminho'));
    resposta.headers.addAll({
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (corpo != null) resposta.body = jsonEncode(corpo);
    final cliente = http.Client();
    try {
      final fluxo = await cliente.send(resposta).timeout(const Duration(seconds: 12));
      final texto = await fluxo.stream.bytesToString();
      final dados = texto.isEmpty ? <String, dynamic>{} :
          Map<String, dynamic>.from(jsonDecode(texto) as Map);
      if (fluxo.statusCode < 200 || fluxo.statusCode >= 300) {
        throw Exception(dados['erro'] ?? 'Erro HTTP ${fluxo.statusCode}');
      }
      return dados;
    } finally { cliente.close(); }
  }

  Future<Map<String, dynamic>> registrar(String nome, String email, String senha, String perfil) =>
      requisitar('POST', '/auth/register', corpo: {
        'nome': nome, 'email': email, 'senha': senha, 'perfil': perfil,
      });
  Future<Map<String, dynamic>> entrar(String email, String senha) =>
      requisitar('POST', '/auth/login', corpo: {'email': email, 'senha': senha});
}
