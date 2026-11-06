import 'package:flutter/material.dart';
import '../presenters/destinos_presenter.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/barra_busca.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/destino_card.dart';
import '../widgets/estado_vazio.dart';

/// Tela 02 – Explore o mundo.
class DestinosView extends StatefulWidget {
  const DestinosView({super.key});

  @override
  State<DestinosView> createState() => _DestinosViewState();
}

class _DestinosViewState extends State<DestinosView> {
  final DestinosPresenter _presenter = DestinosPresenter();

  @override
  Widget build(BuildContext context) {
    final destinos = _presenter.destinosFiltrados;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Explore o mundo',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              BarraBusca(
                onChanged: (valor) => setState(() => _presenter.busca = valor),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presenter.categorias.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final categoria = _presenter.categorias[i];
                    return ChipFiltro(
                      rotulo: categoria,
                      selecionado: _presenter.categoriaSelecionada == categoria,
                      onTap: () => setState(() => _presenter.categoriaSelecionada = categoria),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: destinos.isEmpty
                    ? const EstadoVazio(
                        icone: Icons.search_off,
                        titulo: 'Nenhum destino encontrado',
                        mensagem: 'Tente outro nome ou escolha outra categoria.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: destinos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => DestinoCard(
                          destino: destinos[i],
                          onTap: () => AppRoutes.abrirDetalhesDestino(context, destinos[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
