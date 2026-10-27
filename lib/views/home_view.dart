import 'package:flutter/material.dart';
import '../models/destino.dart';
import '../presenters/home_presenter.dart';
import '../utils/app_colors.dart';
// Descomentar o import abaixo quando a Tela 03 for implementada
// import 'detalhes_destino_view.dart';

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

  //  Substituir pelo nome vindo do usuário autenticado / sessão
  String nomeUsuario = "Luiz";

  // Função centralizada para lidar com o clique nos cartões de destino (Destaque e Recomendados)
  void _abrirDetalhesDestino(Destino destino) {
    // Descomentar o Navigator abaixo quando DetalhesDestinoView estiver pronta
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesDestinoView(destino: destino),
      ),
    );
    */
    debugPrint('Navegando para o pacote: ${destino.nome}');
  }

  @override
  Widget build(BuildContext context) {
    // Busca os dados dinâmicos através da camada Presenter
    final destaque = _presenter.obterDestinoDestaque();
    final recomendados = _presenter.obterRecomendados();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primaryDark),
          onPressed: () {
            // Implementar abertura do Drawer (menu lateral)
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
              // Implementar navegação para a tela/modal de notificações
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
                // TODO (Equipe): Conectar filtro de busca ao HomePresenter
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
                    //  Redirecionar para a aba de Destinos (Tela 02) ou exibir lista completa
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
            Row(
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
          ],
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
          //  Filtrar conteúdo exibido conforme a categoria selecionada
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
              child: Image.network(
                destino.imagemUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
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