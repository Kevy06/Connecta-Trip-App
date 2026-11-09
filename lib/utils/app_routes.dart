import 'package:flutter/material.dart';
import '../models/destino.dart';
import '../models/opcao_catalogo.dart';
import '../views/catalogo_servicos_view.dart';
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
  final String observacoesIniciais;
  const SolicitacaoArgs({this.destino, this.interessesIniciais, this.observacoesIniciais = ''});
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
            observacoesIniciais: args.observacoesIniciais,
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
    String observacoesIniciais = '',
  }) {
    return Navigator.of(context).pushNamed<void>(
      solicitacao,
      arguments: SolicitacaoArgs(destino: destino, interessesIniciais: interessesIniciais,
        observacoesIniciais: observacoesIniciais),
    );
  }

  static Future<void> abrirCatalogo(BuildContext context, {
    required Destino destino, required TipoServico tipo,
  }) => Navigator.of(context).push<void>(MaterialPageRoute(
    builder: (_) => CatalogoServicosView(destino: destino, tipo: tipo),
  ));

  static Future<void> abrirFavoritos(BuildContext context) {
    return Navigator.of(context).pushNamed<void>(favoritos);
  }
}
