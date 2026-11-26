import 'package:flutter/material.dart';
import '../models/viagem.dart';
import '../services/viagem_service.dart';
import '../presenters/viagens_presenter.dart';
import 'detalhe_solicitacao_view.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../utils/formatadores.dart';
import '../widgets/botao_personalizado.dart';
import '../widgets/consultor_sheet.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/imagem_rede.dart';
import '../widgets/linha_tempo.dart';
import '../widgets/status_chip.dart';

/// Tela 04 – Minhas viagens ("Tudo pronto para embarcar?").
class ViagensView extends StatefulWidget {
  const ViagensView({super.key});

  @override
  State<ViagensView> createState() => _ViagensViewState();
}

class _ViagensViewState extends State<ViagensView> {
  final ViagensPresenter _presenter = ViagensPresenter();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _presenter.listenable,
      builder: (context, _) {
        final viagens = _presenter.viagens;
        final destaque = _presenter.viagemDestaque;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: destaque == null
                ? EstadoVazio(
                    icone: Icons.luggage_outlined,
                    titulo: 'Nenhuma viagem por aqui ainda',
                    mensagem: 'Escolha um destino e peça um orçamento para acompanhar tudo neste lugar.',
                    textoBotao: 'Explorar destinos',
                    onBotao: () => AppNavigation.irParaAba(AppNavigation.destinos),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _cabecalho(),
                      if (ViagemService().erroConexao != null) ...[
                        Text(ViagemService().erroConexao!,
                          style: const TextStyle(color: Colors.deepOrange)),
                        TextButton(onPressed: () => ViagemService().carregar(),
                          child: const Text('Tentar novamente')),
                      ],
                      const SizedBox(height: 16),
                      _cartaoDestaque(destaque),
                      const SizedBox(height: 14),
                      _acoesRapidas(destaque),
                      const SizedBox(height: 24),
                      const _Titulo('Seu roteiro'),
                      const SizedBox(height: 12),
                      LinhaTempo(
                        passos: [
                          for (final item in destaque.roteiro)
                            PassoLinhaTempo(
                              titulo: 'Dia ${item.dia} • ${item.titulo}',
                              descricao: item.descricao,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _Titulo('Minhas solicitações'),
                      const SizedBox(height: 12),
                      for (final v in viagens) _itemSolicitacao(v),
                      const SizedBox(height: 12),
                      _bannerAjuda(),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _cabecalho() {
    final confirmada = _presenter.temViagemConfirmada;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flight, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Text(
              confirmada ? 'Tudo pronto para embarcar?' : 'Acompanhe sua solicitação',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          confirmada
              ? 'Acompanhe os detalhes da sua próxima viagem.'
              : 'Veja o andamento do atendimento e as propostas recebidas.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _cartaoDestaque(Viagem v) {
    return GestureDetector(
      onTap: () => _abrirViagem(v),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImagemRede(url: v.destino.imagemUrl),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Exemplo de roteiro',
                          style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sua viagem a ${v.destino.nome}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          v.destino.pais,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryDark),
                            const SizedBox(width: 6),
                            Text(
                              Formatadores.periodo(v.inicio, v.fim),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            StatusChip(status: v.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acoesRapidas(Viagem v) {
    return Row(
      children: [
        _acao(Icons.confirmation_number_outlined, 'Voucher', () => _abrirDocumento(v, 'Voucher')),
        const SizedBox(width: 10),
        _acao(Icons.description_outlined, 'Roteiro', () => _abrirViagem(v)),
        const SizedBox(width: 10),
        _acao(Icons.folder_outlined, 'Documentos', () => _abrirDocumento(v, 'Documentos')),
      ],
    );
  }

  Widget _acao(IconData icone, String rotulo, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icone, color: AppColors.primaryDark),
              const SizedBox(height: 6),
              Text(
                rotulo,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemSolicitacao(Viagem v) {
    return GestureDetector(
      onTap: () => _abrirViagem(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImagemRede(url: v.destino.imagemUrl, height: 52, width: 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.destino.nome}, ${v.destino.pais}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatadores.periodo(v.inicio, v.fim)} • ${v.viajantes} viajante${v.viajantes == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusChip(status: v.status),
          ],
        ),
      ),
    );
  }

  Widget _bannerAjuda() {
    return GestureDetector(
      onTap: () => ConsultorSheet.mostrar(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.primaryTeal, shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precisa de ajuda?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Converse com a Connecta Trip',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // --- Folhas inferiores ---

  /// Detalhes da solicitação: status, proposta recebida e aceite.
  void _abrirViagem(Viagem v) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DetalheSolicitacaoView(viagemId: v.id),
    ));
  }

  void _abrirDocumento(Viagem v, String tipo) {
    final liberado = v.status.confirmada;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$tipo • ${v.destino.nome}',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              liberado
                  ? 'Seu consultor enviará os arquivos por aqui assim que estiverem prontos. Nada foi emitido pelo app.'
                  : 'Disponível depois que você aceitar a proposta do consultor.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            BotaoPersonalizado(texto: 'Fechar', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
}

