import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Persistência SQLite. O banco é exclusivo da instalação/dispositivo.
/// As credenciais são apenas para demonstração acadêmica offline.
class BancoLocal {
  static final BancoLocal _instancia = BancoLocal._();
  factory BancoLocal() => _instancia;
  BancoLocal._();
  Database? _db;

  // Na web, shared_preferences persiste registros JSON no armazenamento local.
  // No Android/iOS, os mesmos metodos continuam usando SQLite.
  Future<List<Map<String, dynamic>>> _lerWeb(String colecao) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString('connecta_web_$colecao');
    if (texto == null) return [];
    return (jsonDecode(texto) as List)
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _gravarWeb(String colecao, List<Map<String, dynamic>> registros) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('connecta_web_$colecao', jsonEncode(registros))) {
      throw StateError('Falha ao gravar dados no navegador.');
    }
  }


  Future<Database> get db async {
    if (_db != null) return _db!;
    final caminho = p.join(await getDatabasesPath(), 'connecta_trip_v2.db');
    _db = await openDatabase(caminho, version: 1, onCreate: (database, _) async {
      await database.execute('''CREATE TABLE usuarios (
        id TEXT PRIMARY KEY, nome TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
        perfil TEXT NOT NULL, senha_hash TEXT NOT NULL, salt TEXT NOT NULL
      )''');
      await database.execute('''CREATE TABLE solicitacoes (
        id TEXT PRIMARY KEY, dono_id TEXT NOT NULL, payload TEXT NOT NULL
      )''');
      await database.execute('''CREATE TABLE favoritos (
        usuario_id TEXT NOT NULL, destino_id TEXT NOT NULL,
        PRIMARY KEY (usuario_id, destino_id)
      )''');
      await database.execute('''CREATE TABLE mensagens (
        id TEXT PRIMARY KEY, viajante_id TEXT NOT NULL, consultor_id TEXT NOT NULL,
        payload TEXT NOT NULL
      )''');
      await database.execute('''CREATE TABLE preferencias (
        chave TEXT PRIMARY KEY, valor TEXT NOT NULL
      )''');
    });
    return _db!;
  }

  Future<void> configurar(String chave, String? valor) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final nome = 'connecta_web_pref_$chave';
      if (valor == null) {
        await prefs.remove(nome);
      } else {
        await prefs.setString(nome, valor);
      }
      return;
    }
    final database = await db;
    if (valor == null) {
      await database.delete('preferencias', where: 'chave = ?', whereArgs: [chave]);
    } else {
      await database.insert('preferencias', {'chave': chave, 'valor': valor},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<String?> preferencia(String chave) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('connecta_web_pref_$chave');
    }
    final linhas = await (await db).query('preferencias', where: 'chave = ?',
        whereArgs: [chave], limit: 1);
    return linhas.isEmpty ? null : linhas.first['valor'] as String;
  }

  Future<void> salvarUsuario(Map<String, Object?> usuario) async {
    if (kIsWeb) {
      final usuarios = await _lerWeb('usuarios');
      if (usuarios.any((u) => u['id'] == usuario['id'] || u['email'] == usuario['email'])) {
        throw StateError('Usuario ja cadastrado.');
      }
      usuarios.add(Map<String, dynamic>.from(usuario));
      await _gravarWeb('usuarios', usuarios);
      return;
    }
    await (await db).insert('usuarios', usuario,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Map<String, Object?>?> usuarioPorEmail(String email) async {
    if (kIsWeb) {
      final usuarios = await _lerWeb('usuarios');
      for (final u in usuarios) {
        if (u['email'] == email.trim().toLowerCase()) return u;
      }
      return null;
    }
    final linhas = await (await db).query('usuarios', where: 'email = ?',
        whereArgs: [email.trim().toLowerCase()], limit: 1);
    return linhas.isEmpty ? null : linhas.first;
  }

  Future<Map<String, Object?>?> usuarioPorId(String id) async {
    if (kIsWeb) {
      final usuarios = await _lerWeb('usuarios');
      for (final u in usuarios) {
        if (u['id'] == id) return u;
      }
      return null;
    }
    final linhas = await (await db).query('usuarios', where: 'id = ?',
        whereArgs: [id], limit: 1);
    return linhas.isEmpty ? null : linhas.first;
  }

  Future<void> salvarSolicitacao(String id, String dono, Map<String, dynamic> dados) async {
    if (kIsWeb) {
      final registros = await _lerWeb('solicitacoes');
      registros.removeWhere((r) => r['id'] == id);
      registros.add(dados);
      await _gravarWeb('solicitacoes', registros);
      return;
    }
    await (await db).insert('solicitacoes', {
      'id': id, 'dono_id': dono, 'payload': jsonEncode(dados),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> listarSolicitacoes() async {
    if (kIsWeb) return _lerWeb('solicitacoes');
    final linhas = await (await db).query('solicitacoes');
    return linhas.map((linha) =>
        Map<String, dynamic>.from(jsonDecode(linha['payload'] as String) as Map)).toList();
  }

  Future<List<String>> listarFavoritos(String usuarioId) async {
    if (kIsWeb) {
      final registros = await _lerWeb('favoritos');
      return registros.where((r) => r['usuario_id'] == usuarioId)
          .map((r) => r['destino_id'] as String).toList();
    }
    final linhas = await (await db).query('favoritos', where: 'usuario_id = ?',
        whereArgs: [usuarioId]);
    return linhas.map((v) => v['destino_id'] as String).toList();
  }

  Future<void> gravarFavorito(String usuario, String destino, bool favorito) async {
    if (kIsWeb) {
      final registros = await _lerWeb('favoritos');
      registros.removeWhere((r) => r['usuario_id'] == usuario && r['destino_id'] == destino);
      if (favorito) registros.add({'usuario_id': usuario, 'destino_id': destino});
      await _gravarWeb('favoritos', registros);
      return;
    }
    final database = await db;
    if (favorito) {
      await database.insert('favoritos', {'usuario_id': usuario, 'destino_id': destino},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await database.delete('favoritos',
          where: 'usuario_id = ? AND destino_id = ?', whereArgs: [usuario, destino]);
    }
  }
  Future<List<Map<String, Object?>>> listarUsuariosConsultores() async {
    if (kIsWeb) {
      final usuarios = await _lerWeb('usuarios');
      return usuarios.where((u) => u['perfil'] == 'consultor').toList();
    }
    return (await db).query('usuarios', where: 'perfil = ?', whereArgs: ['consultor']);
  }

  Future<void> salvarMensagem(String id, String viajante, String consultor,
      Map<String, dynamic> dados) async {
    if (kIsWeb) {
      final registros = await _lerWeb('mensagens');
      registros.removeWhere((r) => r['id'] == id);
      registros.add(dados);
      await _gravarWeb('mensagens', registros);
      return;
    }
    await (await db).insert('mensagens' , {
      'id': id, 'viajante_id': viajante, 'consultor_id': consultor,
      'payload': jsonEncode(dados),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> listarMensagens() async {
    if (kIsWeb) return _lerWeb('mensagens');
    final linhas = await (await db).query('mensagens');
    return linhas.map((linha) =>
        Map<String, dynamic>.from(jsonDecode(linha['payload'] as String) as Map)).toList();
  }

  Future<void> limparCacheApi() async {
    if (kIsWeb) {
      await _gravarWeb('solicitacoes', []);
      await _gravarWeb('mensagens', []);
      return;
    }
    final database = await db;
    await database.delete('solicitacoes');
    await database.delete('mensagens');
  }
}
