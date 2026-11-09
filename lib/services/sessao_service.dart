import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../data/banco_local.dart';
import '../models/usuario.dart';
import 'api_service.dart';

/// Autenticação educacional offline; API opcional com token quando configurada.
class SessaoService extends ChangeNotifier {
  static final SessaoService _instancia = SessaoService._();
  factory SessaoService() => _instancia;
  SessaoService._();

  Usuario? _usuario;
  Usuario? get usuarioAtual => _usuario;
  bool get logado => _usuario != null;

  Future<void> iniciar() async {
    if (!kIsWeb) await BancoLocal().db;
    final id = await BancoLocal().preferencia('sessao_id');
    if (id != null) {
      final registro = await BancoLocal().usuarioPorId(id);
      if (registro != null) {
        _usuario = Usuario.fromJson(Map<String, dynamic>.from(registro));
      }
    }
    notifyListeners();
  }

  static String _hash(String senha, String salt) =>
      sha256.convert(utf8.encode('$salt:$senha')).toString();

  Future<String?> cadastrar(String nome, String email, String senha, PerfilUsuario perfil) async {
    nome = nome.trim();
    email = email.trim().toLowerCase();
    if (nome.length < 3) return 'Digite seu nome completo (mínimo de 3 letras).';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Informe um e-mail válido.';
    if (senha.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    if (!ApiService.habilitada && await BancoLocal().usuarioPorEmail(email) != null) {
      return 'E-mail já cadastrado.';
    }
    try {
      if (ApiService.habilitada) {
        final resposta = await ApiService().registrar(nome, email, senha, perfil.name);
        final usuario = Usuario.fromJson(Map<String, dynamic>.from(resposta['usuario'] as Map));
        await _salvarRegistroLocal(usuario, senha);
        await _definirSessao(usuario, token: resposta['token'] as String);
      } else {
        final usuario = Usuario(id: 'u${DateTime.now().microsecondsSinceEpoch}',
          nome: nome, email: email, perfil: perfil);
        await _salvarRegistroLocal(usuario, senha);
        await _definirSessao(usuario);
      }
      return null;
    } catch (e) { return 'Falha ao cadastrar: $e'; }
  }

  Future<void> _salvarRegistroLocal(Usuario usuario, String senha) async {
    // Gera bytes de forma portável: deslocamentos de 32 bits viram zero no JavaScript.
    final gerador = Random.secure();
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => gerador.nextInt(256)),
    );
    await BancoLocal().salvarUsuario({
      ...usuario.toJson(), 'salt': salt, 'senha_hash': _hash(senha, salt),
    });
  }

  Future<String?> entrar(String email, String senha) async {
    email = email.trim().toLowerCase();
    try {
      if (ApiService.habilitada) {
        final resposta = await ApiService().entrar(email, senha);
        final usuario = Usuario.fromJson(Map<String, dynamic>.from(resposta['usuario'] as Map));
        if (await BancoLocal().usuarioPorId(usuario.id) == null) {
          await _salvarRegistroLocal(usuario, senha);
        }
        await _definirSessao(usuario, token: resposta['token'] as String);
        return null;
      }
      final registro = await BancoLocal().usuarioPorEmail(email);
      if (registro == null || _hash(senha, registro['salt'] as String) != registro['senha_hash']) {
        return 'E-mail ou senha incorretos.';
      }
      await _definirSessao(Usuario.fromJson(Map<String, dynamic>.from(registro)));
      return null;
    } catch (e) { return 'Falha ao entrar: $e'; }
  }

  Future<void> _definirSessao(Usuario usuario, {String? token}) async {
    _usuario = usuario;
    await BancoLocal().configurar('sessao_id', usuario.id);
    await BancoLocal().configurar('token_api', token);
    notifyListeners();
  }

  Future<void> sair() async {
    _usuario = null;
    if (ApiService.habilitada) await BancoLocal().limparCacheApi();
    await BancoLocal().configurar('sessao_id', null);
    await BancoLocal().configurar('token_api', null);
    notifyListeners();
  }
}
