import 'package:flutter/material.dart';
import '../models/destino.dart';
import '../models/viagem.dart';
import '../presenters/solicitacao_presenter.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/botao_personalizado.dart';
import '../widgets/chip_filtro.dart';

/// Formulário por etapas para solicitar um orçamento (documento, seção 2.2).
class SolicitacaoView extends StatefulWidget {
  final Destino? destino;
  final Set<String>? interessesIniciais;

  const SolicitacaoView({super.key, this.destino, this.interessesIniciais});

  @override
  State<SolicitacaoView> createState() => _SolicitacaoViewState();
}

class _SolicitacaoViewState extends State<SolicitacaoView> {
  late final SolicitacaoPresenter _presenter = SolicitacaoPresenter(
    destino: widget.destino,
    interessesIniciais: widget.interessesIniciais,
  );
  final TextEditingController _observacoes = TextEditingController();

  int _etapa = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  StepState _estado(int i) => _etapa > i ? StepState.complete : StepState.indexed;

  void _continuar() {
    if (!_presenter.validarEtapa(_etapa)) {
      setState(() {});
      return;
    }
    setState(() => _etapa++);
  }

  Future<void> _escolherPeriodo() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ini = _presenter.inicio;
    final fim = _presenter.fim;
    final resultado = await showDateRangePicker(
      context: context,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 730)),
      initialDateRange: (ini != null && fim != null && !ini.isBefore(hoje))
          ? DateTimeRange(start: ini, end: fim)
          : null,
      helpText: 'Período da viagem',
      saveText: 'Confirmar',
    );
    if (resultado == null || !mounted) return;
    setState(() => _presenter.definirPeriodo(resultado.start, resultado.end));
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    Viagem? viagem;
    try {
      viagem = await _presenter.enviar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar. Seus dados foram mantidos, tente novamente.'),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _enviando = false);

    if (viagem == null) {
      final etapaComErro = _presenter.primeiraEtapaComErro();
      if (etapaComErro != null) setState(() => _etapa = etapaComErro);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((rota) => rota.isFirst);
    AppNavigation.irParaAba(AppNavigation.viagens);
    messenger.showSnackBar(
      const SnackBar(content: Text('Solicitação enviada! Acompanhe o andamento em Viagens.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryDark,
        title: const Text(
          'Solicitar orçamento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stepper(
        currentStep: _etapa,
        onStepTapped: (i) {
          if (i < _etapa && !_enviando) setState(() => _etapa = i);
        },
        controlsBuilder: _controles,
        steps: [
          Step(
            title: const Text('Destino e datas'),
            isActive: _etapa >= 0,
            state: _estado(0),
            content: _etapaDestino(),
          ),
          Step(
            title: const Text('Viajantes e orçamento'),
            isActive: _etapa >= 1,
            state: _estado(1),
            content: _etapaViajantes(),
          ),
          Step(
            title: const Text('Serviços e observações'),
            isActive: _etapa >= 2,
            state: _estado(2),
            content: _etapaServicos(),
          ),
          Step(
            title: const Text('Revisar e enviar'),
            isActive: _etapa >= 3,
            state: _estado(3),
            content: _etapaRevisao(),
          ),
        ],
      ),
    );
  }

  Widget _controles(BuildContext context, ControlsDetails detalhes) {
    final ultima = _etapa == SolicitacaoPresenter.totalEtapas - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: BotaoPersonalizado(
              texto: ultima ? 'Enviar solicitação' : 'Continuar',
              carregando: _enviando,
              onPressed: ultima ? _enviar : _continuar,
            ),
          ),
          if (_etapa > 0) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: _enviando ? null : () => setState(() => _etapa--),
              child: const Text('Voltar'),
            ),
          ],
        ],
      ),
    );
  }

  // --- Conteúdo das etapas ---

  Widget _etapaDestino() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Rotulo('Para onde você quer ir?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _presenter.destinosDisponiveis)
              ChipFiltro(
                rotulo: '${d.nome}, ${d.pais}',
                selecionado: _presenter.destino?.id == d.id,
                onTap: () => setState(() {
                  _presenter.destino = d;
                  _presenter.erros.remove('destino');
                }),
              ),
          ],
        ),
        _Erro(_presenter.erros['destino']),
        const SizedBox(height: 16),
        const _Rotulo('Quando?'),
        InkWell(
          onTap: _escolherPeriodo,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              errorText: _presenter.erros['periodo'],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _presenter.periodoTexto ?? 'Selecionar ida e volta',
              style: TextStyle(
                color: _presenter.periodoTexto == null
                    ? AppColors.textSecondary
                    : AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _etapaViajantes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Rotulo('Quantos viajantes?'),
        Row(
          children: [
            IconButton.outlined(
              onPressed: () => setState(() => _presenter.alterarViajantes(-1)),
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                '${_presenter.viajantes}',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.outlined(
              onPressed: () => setState(() => _presenter.alterarViajantes(1)),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        _Erro(_presenter.erros['viajantes']),
        const SizedBox(height: 16),
        const _Rotulo('Faixa de orçamento'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final faixa in faixasOrcamento)
              ChipFiltro(
                rotulo: faixa,
                selecionado: _presenter.orcamento == faixa,
                onTap: () => setState(() {
                  _presenter.orcamento = faixa;
                  _presenter.erros.remove('orcamento');
                }),
              ),
          ],
        ),
        _Erro(_presenter.erros['orcamento']),
      ],
    );
  }

  Widget _etapaServicos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Rotulo('O que você quer incluir?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final interesse in interessesDisponiveis)
              ChipFiltro(
                rotulo: interesse,
                selecionado: _presenter.interesses.contains(interesse),
                onTap: () => setState(() => _presenter.alternarInteresse(interesse)),
              ),
          ],
        ),
        _Erro(_presenter.erros['interesses']),
        if (_presenter.interesses.contains('Milhas'))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Milhas: registramos seu interesse e o consultor sugere uma alternativa. '
              'O app não consulta saldo nem cotação automática.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        const _Rotulo('Observações (opcional)'),
        TextField(
          controller: _observacoes,
          maxLines: 4,
          maxLength: SolicitacaoPresenter.maxObservacoes,
          onChanged: (valor) => _presenter.observacoes = valor,
          decoration: InputDecoration(
            hintText: 'Ex.: datas flexíveis, hotel perto da praia...',
            errorText: _presenter.erros['observacoes'],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _etapaRevisao() {
    final p = _presenter;
    final linhas = <(String, String)>[
      ('Destino', p.destino == null ? '-' : '${p.destino!.nome}, ${p.destino!.pais}'),
      ('Período', p.periodoTexto ?? '-'),
      ('Viajantes', '${p.viajantes}'),
      ('Orçamento', p.orcamento ?? '-'),
      ('Serviços', p.interesses.isEmpty ? '-' : p.interesses.join(', ')),
      ('Observações', p.observacoes.trim().isEmpty ? '-' : p.observacoes.trim()),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (rotulo, valor) in linhas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Valores e disponibilidade sob consulta. O app não emite bilhetes nem faz pagamentos.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;
  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
}

class _Erro extends StatelessWidget {
  final String? mensagem;
  const _Erro(this.mensagem);

  @override
  Widget build(BuildContext context) {
    if (mensagem == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        mensagem!,
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
      ),
    );
  }
}
