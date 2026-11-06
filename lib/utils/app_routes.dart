import 'package:flutter/material.dart';
import '../models/destino.dart';
import '../views/detalhes_destino_view.dart';
import '../views/favoritos_view.dart';
import '../views/solicitacao_view.dart';

/// Troca de aba da barra inferior a partir de qualquer tela
/// (ex.: "Ver todos" na Home leva para Destinos).
class AppNavigation {
  static const int inicio = 0;
  static const int destinos = 1;
  static const int viagens = 2;
  static const int perfil = 3;

  static final ValueNotifier<int> abaAtual = ValueNotifier<int>(inicio);

  static void irParaAba(int indice) => abaAtual.value = indice;
}

class DetalhesDestinoArgs {
  final Destino destino;
  final Set<String>? interessesIniciais;
  const DetalhesDestinoArgs(this.destino, {this.interessesIniciais});
}

class SolicitacaoArgs {
  final Destino? destino;
  final Set<String>? interessesIniciais;
  const SolicitacaoArgs({this.destino, this.interessesIniciais});
}

class AppRoutes {
  static const String detalhesDestino = '/destino';
  static const String solicitacao = '/solicitacao';
  static const String favoritos = '/favoritos';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case detalhesDestino:
        final args = settings.arguments as DetalhesDestinoArgs;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => DetalhesDestinoView(
            destino: args.destino,
            interessesIniciais: args.interessesIniciais,
          ),
        );
      case solicitacao:
        final args = (settings.arguments as SolicitacaoArgs?) ?? const SolicitacaoArgs();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SolicitacaoView(
            destino: args.destino,
            interessesIniciais: args.interessesIniciais,
          ),
        );
      case favoritos:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const FavoritosView(),
        );
    }
    return null;
  }

  static Future<void> abrirDetalhesDestino(
    BuildContext context,
    Destino destino, {
    Set<String>? interessesIniciais,
  }) {
    return Navigator.of(context).pushNamed<void>(
      detalhesDestino,
      arguments: DetalhesDestinoArgs(destino, interessesIniciais: interessesIniciais),
    );
  }

  static Future<void> abrirSolicitacao(
    BuildContext context, {
    Destino? destino,
    Set<String>? interessesIniciais,
  }) {
    return Navigator.of(context).pushNamed<void>(
      solicitacao,
      arguments: SolicitacaoArgs(destino: destino, interessesIniciais: interessesIniciais),
    );
  }

  static Future<void> abrirFavoritos(BuildContext context) {
    return Navigator.of(context).pushNamed<void>(favoritos);
  }
}
