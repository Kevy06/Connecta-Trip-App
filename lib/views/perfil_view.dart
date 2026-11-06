import 'package:flutter/material.dart';
import '../services/destino_service.dart';
import '../services/sessao_service.dart';
import '../services/viagem_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';

/// Aba Perfil: dados do usuário, resumo e atalhos.
class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = SessaoService().usuarioAtual;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([ViagemService(), DestinoService()]),
          builder: (context, _) {
            final totalViagens = ViagemService().obterViagens().length;
            final totalFavoritos = DestinoService().obterFavoritos().length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryTeal,
                    child: Text(
                      usuario.iniciais,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    usuario.nome,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${usuario.email} • ${usuario.perfil.rotulo}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _estatistica('$totalViagens', 'Solicitações'),
                    const SizedBox(width: 12),
                    _estatistica('$totalFavoritos', 'Favoritos'),
                  ],
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.luggage_outlined, color: AppColors.primaryTeal),
                        title: const Text('Minhas viagens'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => AppNavigation.irParaAba(AppNavigation.viagens),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.favorite_border, color: AppColors.primaryTeal),
                        title: const Text('Meus favoritos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => AppRoutes.abrirFavoritos(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.explore_outlined, color: AppColors.primaryTeal),
                        title: const Text('Explorar destinos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => AppNavigation.irParaAba(AppNavigation.destinos),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: AppColors.primaryTeal),
                        title: const Text('Sobre o Connecta Trip'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'Connecta Trip',
                          applicationVersion: '1.0.0',
                          children: const [
                            Text(
                              'Organize solicitações e propostas de viagem em um só lugar. '
                              'O app não emite bilhetes, não processa pagamentos e não mostra '
                              'preços em tempo real.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _estatistica(String valor, String rotulo) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              rotulo,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
