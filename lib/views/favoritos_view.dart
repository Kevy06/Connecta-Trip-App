import 'package:flutter/material.dart';
import '../presenters/favoritos_presenter.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/destino_card.dart';
import '../widgets/estado_vazio.dart';

/// Destinos marcados com o coração na tela do pacote.
class FavoritosView extends StatefulWidget {
  const FavoritosView({super.key});

  @override
  State<FavoritosView> createState() => _FavoritosViewState();
}

class _FavoritosViewState extends State<FavoritosView> {
  final FavoritosPresenter _presenter = FavoritosPresenter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryDark,
        title: const Text(
          'Meus favoritos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListenableBuilder(
        listenable: _presenter.listenable,
        builder: (context, _) {
          final favoritos = _presenter.favoritos;
          if (favoritos.isEmpty) {
            return EstadoVazio(
              icone: Icons.favorite_border,
              titulo: 'Nenhum favorito ainda',
              mensagem: 'Toque no coração na página de um destino para guardá-lo aqui.',
              textoBotao: 'Explorar destinos',
              onBotao: () {
                Navigator.of(context).popUntil((rota) => rota.isFirst);
                AppNavigation.irParaAba(AppNavigation.destinos);
              },
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: favoritos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) => DestinoCard(
              destino: favoritos[i],
              onTap: () => AppRoutes.abrirDetalhesDestino(context, favoritos[i]),
              onRemoverFavorito: () => _presenter.remover(favoritos[i].id),
            ),
          );
        },
      ),
    );
  }
}
