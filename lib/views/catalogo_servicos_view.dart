import 'package:flutter/material.dart';
import '../models/destino.dart';
import '../models/opcao_catalogo.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';

/// Seleção real no aplicativo, usando catálogo offline com opções referenciais.
/// Escolhas são transportadas como observações para a proposta do consultor.
class CatalogoServicosView extends StatefulWidget {
  final Destino destino;
  final TipoServico tipo;
  const CatalogoServicosView({super.key, required this.destino, required this.tipo});

  @override
  State<CatalogoServicosView> createState() => _CatalogoServicosViewState();
}

class _CatalogoServicosViewState extends State<CatalogoServicosView> {
  String _filtro = 'Todos';
  String _classe = 'Econômica';
  String _transfer = 'Privativo';
  int _bagagens = 1;
  String _plano = 'Essencial';
  final TextEditingController _local = TextEditingController();

  @override
  void dispose() { _local.dispose(); super.dispose(); }

  void _pedirOrcamento(String detalhes) {
    AppRoutes.abrirSolicitacao(context,
      destino: widget.destino,
      interessesIniciais: {widget.tipo.interesse},
      observacoesIniciais: detalhes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.tipo;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${tipo.rotulo} • ${widget.destino.nome}'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryDark,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Text(switch (tipo) {
            TipoServico.hospedagem => 'Escolha uma referência de hospedagem',
            TipoServico.passagem => 'Escolha uma rota para consultar',
            TipoServico.traslado => 'Personalize seu traslado',
            TipoServico.seguro => 'Personalize seu seguro viagem',
          }, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
            color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          const Text('Catálogo demonstrativo: valores, condições e disponibilidade '
              'serão confirmados pelo consultor. Não há reserva automática.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 18),
          if (tipo == TipoServico.hospedagem || tipo == TipoServico.passagem)
            _catalogo(),
          if (tipo == TipoServico.traslado) _traslado(),
          if (tipo == TipoServico.seguro) _seguro(),
        ],
      ),
    );
  }

  Widget _catalogo() {
    final hotel = widget.tipo == TipoServico.hospedagem;
    final opcoes = CatalogoServicos.paraDestino(widget.tipo, widget.destino.id);
    final filtros = hotel ? ['Todos', 'Hotel', 'Resort'] : ['Todos', 'GRU', 'GIG'];
    final visiveis = opcoes.where((o) => _filtro == 'Todos' || o.categoria == _filtro).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, children: [
        for (final filtro in filtros)
          ChoiceChip(label: Text(filtro), selected: filtro == _filtro,
            onSelected: (_) => setState(() => _filtro = filtro)),
      ]),
      if (!hotel) ...[
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _classe,
          decoration: const InputDecoration(labelText: 'Classe de preferência',
            border: OutlineInputBorder()),
          items: const ['Econômica','Premium Economy','Executiva']
            .map((e) => DropdownMenuItem(value:e,child:Text(e))).toList(),
          onChanged: (v) => setState(() => _classe = v ?? 'Econômica'),
        ),
      ],
      const SizedBox(height: 15),
      for (final opcao in visiveis)
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(hotel ? Icons.hotel_outlined : Icons.flight_takeoff,
                  color: AppColors.primaryTeal),
                const SizedBox(width: 10),
                Expanded(child: Text(opcao.nome,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark))),
              ]),
              const SizedBox(height: 8),
              Text(opcao.descricao, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 5, children: [
                for (final item in opcao.facilidades)
                  Chip(label: Text(item, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact),
              ]),
              Align(alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _pedirOrcamento(hotel
                    ? 'Hospedagem de referência: ${opcao.nome}. '
                      'Destino: ${widget.destino.nome}. Consultar tarifa, disponibilidade e condições.'
                    : 'Rota aérea de referência: ${opcao.nome}. Classe: $_classe. '
                      'Consultar datas, conexões, bagagem, tarifas e disponibilidade.'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(hotel ? 'Solicitar este hotel' : 'Consultar esta rota'),
                ),
              ),
            ]),
          ),
        ),
      if (visiveis.isEmpty)
        const Padding(padding: EdgeInsets.all(24),
          child: Text('Nenhuma opção para o filtro selecionado.')),
    ]);
  }

  Widget _traslado() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SegmentedButton<String>(
      segments: const [
        ButtonSegment(value:'Privativo',label:Text('Privativo'),icon:Icon(Icons.local_taxi)),
        ButtonSegment(value:'Compartilhado',label:Text('Compartilhado'),icon:Icon(Icons.groups)),
      ],
      selected: {_transfer},
      onSelectionChanged: (v) => setState(() => _transfer = v.first),
    ),
    const SizedBox(height: 18),
    TextField(controller: _local, maxLength: 140,
      decoration: const InputDecoration(labelText: 'Aeroporto / local de embarque',
        hintText: 'Ex.: Aeroporto internacional',border:OutlineInputBorder())),
    const SizedBox(height: 15),
    Row(children: [
      const Expanded(child: Text('Bagagens estimadas',
        style: TextStyle(fontWeight:FontWeight.w600))),
      IconButton(onPressed: _bagagens > 0 ? () => setState(() => _bagagens--) : null,
        icon: const Icon(Icons.remove_circle_outline)),
      Text('$_bagagens'),
      IconButton(onPressed: _bagagens < 20 ? () => setState(() => _bagagens++) : null,
        icon: const Icon(Icons.add_circle_outline)),
    ]),
    const SizedBox(height: 18),
    FilledButton.icon(
      onPressed: () => _pedirOrcamento('Traslado $_transfer em ${widget.destino.nome}. '
        'Embarque: ${_local.text.trim().isEmpty ? 'a definir' : _local.text.trim()}. '
        'Bagagens estimadas: $_bagagens. Consultar disponibilidade.'),
      icon: const Icon(Icons.arrow_forward),label: const Text('Solicitar traslado')),
  ]);

  Widget _seguro() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Wrap(spacing: 8, children: [
      for (final opcao in ['Essencial', 'Ampliado'])
        ChoiceChip(label: Text(opcao), selected: _plano == opcao,
          onSelected: (_) => setState(() => _plano = opcao)),
    ]),
    const SizedBox(height: 8),
    Text(_plano == 'Essencial'
      ? 'Solicitar proteção básica e atendimento.'
      : 'Solicitar avaliação de coberturas adicionais.'),
    const SizedBox(height: 10),
    const Text('As coberturas, exclusões, seguradora e preço serão definidos '
      'somente na proposta do consultor.',
      style: TextStyle(color:AppColors.textSecondary)),
    const SizedBox(height: 18),
    FilledButton.icon(
      onPressed: () => _pedirOrcamento('Seguro viagem para ${widget.destino.nome}. '
        'Perfil de cobertura solicitado: $_plano. '
        'Confirmar coberturas, exclusões, seguradora e preço.'),
      icon: const Icon(Icons.arrow_forward),label: const Text('Solicitar seguro')),
  ]);
}
