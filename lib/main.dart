import 'package:flutter/material.dart';
import 'services/destino_service.dart';
import 'services/consultor_service.dart';
import 'services/mensagem_service.dart';
import 'services/sessao_service.dart';
import 'services/viagem_service.dart';
import 'utils/app_colors.dart';
import 'utils/app_routes.dart';
import 'views/autenticacao_view.dart';
import 'views/consultor_view.dart';
import 'views/destinos_view.dart';
import 'views/home_view.dart';
import 'views/perfil_view.dart';
import 'views/viagens_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessaoService().iniciar();
  await DestinoService().carregar();
  await ViagemService().carregar();
  await ConsultorService().carregar();
  await MensagemService().carregar();
  runApp(const ConnectaTripApp());
}

class ConnectaTripApp extends StatelessWidget {
  const ConnectaTripApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Connecta Trip', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryTeal,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryTeal),
      useMaterial3: true,
    ),
    onGenerateRoute: AppRoutes.onGenerateRoute,
    home: ListenableBuilder(
      listenable: SessaoService(),
      builder: (context, _) {
        final usuario = SessaoService().usuarioAtual;
        if (usuario == null) return const AutenticacaoView();
        if (usuario.perfil.name == 'consultor') return const ConsultorView();
        return const MainNavigationScreen();
      },
    ),
  );
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppNavigation.abaAtual,
      builder: (context, aba, _) {
        final telas = <Widget>[
          const HomeView(), const DestinosView(),
          const ViagensView(), const PerfilView(),
        ];
        return Scaffold(
          body: IndexedStack(index: aba, children: telas),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: aba,
            onTap: AppNavigation.irParaAba,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primaryTeal,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home), label: 'Início'),
              BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on), label: 'Destinos'),
              BottomNavigationBarItem(icon: Icon(Icons.luggage_outlined),
                activeIcon: Icon(Icons.luggage), label: 'Viagens'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }
}
