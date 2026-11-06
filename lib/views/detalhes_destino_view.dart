import 'package:flutter/material.dart';
import '../models/destino.dart';
import '../presenters/detalhes_destino_presenter.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/botao_personalizado.dart';
import '../widgets/consultor_sheet.dart';
import '../widgets/imagem_rede.dart';

/// Tela 03 – Pacote ("Cancún do seu jeito").
class DetalhesDestinoView extends StatefulWidget {
  final Destino destino;

  /// Interesses pré-selecionados (vindos dos chips da Home) para o pedido de orçamento.
  final Set<String>? interessesIniciais;

  const DetalhesDestinoView({
    super.key,
    required this.destino,
    this.interessesIniciais,
  });

  @override
  State<DetalhesDestinoView> createState() => _DetalhesDestinoViewState();
}

class _DetalhesDestinoViewState extends State<DetalhesDestinoView> {
  late final DetalhesDestinoPresenter _presenter =
      DetalhesDestinoPresenter(widget.destino);

  IconData _iconeInclusao(String nome) {
    switch (nome) {
      case 'Hotel':
        return Icons.bed_outlined;
      case 'Traslado':
        return Icons.directions_car_outlined;
      case 'Seguro':
        return Icons.shield_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  static const List<IconData> _iconesDetalhe = [
    Icons.bed_outlined,
    Icons.directions_car_outlined,
    Icons.headset_mic_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: ImagemRede(url: widget.destino.imagemUrl),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 270),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: _conteudo(),
                ),
              ],
            ),
          ),
          Positioned(
            top: topo + 8,
            left: 16,
            child: _botaoCircular(
              Icons.arrow_back_ios_new,
              () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: topo + 8,
            right: 16,
            child: ListenableBuilder(
              listenable: _presenter.favoritosListenable,
              builder: (context, _) => _botaoCircular(
                _presenter.favorito ? Icons.favorite : Icons.favorite_border,
                _presenter.alternarFavorito,
                cor: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoCircular(IconData icone, VoidCallback onTap, {Color cor = AppColors.primaryDark}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icone, size: 20, color: cor),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _presenter.titulo,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _presenter.localizacao,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < widget.destino.inclusoes.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconeInclusao(widget.destino.inclusoes[i]),
                        size: 16,
                        color: AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.destino.inclusoes[i],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Sua viagem inclui',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _presenter.detalhesIncluidos.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(_iconesDetalhe[i % _iconesDetalhe.length], color: AppColors.primaryTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _presenter.detalhesIncluidos[i].titulo,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _presenter.detalhesIncluidos[i].descricao,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              _presenter.avisoValores,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        BotaoPersonalizado(
          texto: 'Solicitar orçamento',
          icone: Icons.arrow_forward,
          iconeAposTexto: true,
          onPressed: () => AppRoutes.abrirSolicitacao(
            context,
            destino: widget.destino,
            interessesIniciais: widget.interessesIniciais,
          ),
        ),
        const SizedBox(height: 12),
        BotaoPersonalizado(
          texto: 'Falar com consultor',
          icone: Icons.chat_bubble_outline,
          outlined: true,
          onPressed: () => ConsultorSheet.mostrar(context, assunto: widget.destino.nome),
        ),
      ],
    );
  }
}
