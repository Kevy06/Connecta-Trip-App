import 'package:flutter/material.dart';
import '../models/destino.dart';
import '../models/opcao_catalogo.dart';
import '../presenters/home_presenter.dart';
import '../utils/app_routes.dart';
import '../services/sessao_service.dart';
import '../services/viagem_service.dart';
import '../widgets/imagem_rede.dart';
import '../utils/app_colors.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Instância do Presenter seguindo o padrão arquitetural MVP do projeto
  final HomePresenter _presenter = HomePresenter();
  
  // Controla a aba de categoria ativa (0: Pacotes, 1: Passagens, 2: Hotéis)
  int _categoriaSelecionada = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _busca = '';

  void _abrirDetalhesDestino(Destino destino) =>
      AppRoutes.abrirDetalhesDestino(context, destino);

  @override
  Widget build(BuildContext context) {
    // Busca os dados dinâmicos através da camada Presenter
    final destaque = _presenter.obterDestinoDestaque();
    final recomendados = _presenter.obterRecomendados().where((d) =>
      '${d.nome} ${d.pais}'.toLowerCase().contains(_busca.toLowerCase())).toList();
    final nomeUsuario = SessaoService().usuarioAtual?.primeiroNome ?? 'viajante';

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(child: SafeArea(child: ListView(children: [
        const DrawerHeader(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.travel_explore, size: 48, color: AppColors.primaryTeal),
            Text('Connecta Trip', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))])),
        ListTile(leading: const Icon(Icons.explore), title: const Text('Destinos'),
          onTap: () { Navigator.pop(context); AppNavigation.irParaAba(AppNavigation.destinos); }),
        ListTile(leading: const Icon(Icons.luggage), title: const Text('Minhas viagens'),
          onTap: () { Navigator.pop(context); AppNavigation.irParaAba(AppNavigation.viagens); }),
        ListTile(leading: const Icon(Icons.person), title: const Text('Meu perfil'),
          onTap: () { Navigator.pop(context); AppNavigation.irParaAba(AppNavigation.perfil); }),
        ListTile(leading: const Icon(Icons.favorite), title: const Text('Favoritos'),
          onTap: () { Navigator.pop(context); AppRoutes.abrirFavoritos(context); }),
      ]))),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primaryDark),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Image.asset(
          'assets/logo.jpg', 
          height: 45,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primaryDark),
            onPressed: () {
              final lista = ViagemService().obterViagens();
              showDialog<void>(context: context, builder: (context) => AlertDialog(
                title: const Text('Notificações'),
                content: Text(lista.isEmpty ? 'Nenhuma solicitação ainda.' :
                  'Você tem ${lista.length} solicitação(ões). Confira o status na aba Viagens.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))],
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SEÇÃO 1: Saudação Dinâmica e Título Principal ---
            Text(
              'Olá, $nomeUsuario 👋',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Qual é o seu\npróximo destino?',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // --- SEÇÃO 2: Barra de Pesquisa ---
            TextField(
              onChanged: (valor) {
                setState(() => _busca = valor);
              },
              decoration: InputDecoration(
                hintText: 'Para onde você quer ir?',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.searchBarBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Botões de Categoria  ---
            Row(
              children: [
                _buildCategoriaChip(0, Icons.luggage_outlined, 'Pacotes'),
                const SizedBox(width: 10),
                _buildCategoriaChip(1, Icons.flight_takeoff, 'Passagens'),
                const SizedBox(width: 10),
                _buildCategoriaChip(2, Icons.bed_outlined, 'Hotéis'),
              ],
            ),
            if (_categoriaSelecionada == 0) ...[
              const SizedBox(height: 24),
            // ---  Cartão Principal "Em Destaque" ---
            // Alimentado dinamicamente pelo objeto 'destaque' vindo do Presenter
            GestureDetector(
              onTap: () => _abrirDetalhesDestino(destaque),
              child: Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(destaque.imagemUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tag Laranja "Em destaque"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Em destaque',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Textos dinâmicos e botão "Conhecer destino"
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore ${destaque.nome}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destaque.subtitulo,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Conhecer destino',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, size: 14, color: AppColors.primaryDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ---  Cabeçalho "Feito para você" ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Feito para você',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppNavigation.irParaAba(AppNavigation.destinos);
                  },
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- SEÇÃO 6: Lista de Destinos Recomendados (Ex: Paris, Orlando) ---
            if (recomendados.isEmpty)
              const Text('Nenhum destino encontrado. Veja todos na aba Destinos.'),
            if (recomendados.isNotEmpty) Row(
              children: recomendados.map((destino) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: destino == recomendados.first ? 12.0 : 0.0,
                    ),
                    child: _buildRecomendadoCard(destino),
                  ),
                );
              }).toList(),
            ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                _categoriaSelecionada == 2
                    ? 'Hotéis para sua estadia'
                    : 'Passagens para sua viagem',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _categoriaSelecionada == 2
                    ? 'Escolha o destino e peça opções de hospedagem a um consultor.'
                    : 'Consulte rotas aéreas de referência por destino e origem.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ..._presenter.obterTodosDestinos()
                  .where((d) => '${d.nome} ${d.pais}'.toLowerCase()
                      .contains(_busca.toLowerCase()))
                  .map((destino) => _buildCardServico(
                    destino,
                    tipo: _categoriaSelecionada == 2 ? TipoServico.hospedagem : TipoServico.passagem,
                  )),
              if (_presenter.obterTodosDestinos().where((d) =>
                  '${d.nome} ${d.pais}'.toLowerCase()
                      .contains(_busca.toLowerCase())).isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Nenhum destino encontrado para a busca.'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Cartões grandes da aba Hotéis/Passagens, como no protótipo do grupo.
  Widget _buildCardServico(Destino destino, {required TipoServico tipo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => AppRoutes.abrirCatalogo(
            context, destino: destino, tipo: tipo),
          child: SizedBox(
            height: 130,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImagemRede(url: destino.imagemUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.30, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 12,
                  bottom: 13,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${destino.nome}, ${destino.pais}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tipo == TipoServico.hospedagem
                                ? 'Hotéis de referência • consultar disponibilidade'
                                : 'Rotas aéreas • consultar passagens',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.83),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tipo == TipoServico.hospedagem
                                  ? 'Ver hotéis' : 'Ver rotas',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward,
                                  size: 13, color: AppColors.primaryTeal),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Componente interno para os botões de categoria 
  Widget _buildCategoriaChip(int index, IconData icon, String label) {
    final bool selecionado = _categoriaSelecionada == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _categoriaSelecionada = index);
          // Alterna o conteúdo da Home de acordo com a categoria selecionada.
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selecionado ? AppColors.primaryTeal : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: selecionado ? AppColors.primaryTeal : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selecionado ? Colors.white : AppColors.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selecionado ? Colors.white : AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Componente interno para os cards menores 
  Widget _buildRecomendadoCard(Destino destino) {
    return GestureDetector(
      onTap: () => _abrirDetalhesDestino(destino),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ImagemRede(url: destino.imagemUrl,
                height: 100, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${destino.nome}, ${destino.pais}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destino.subtitulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}