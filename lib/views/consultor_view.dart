import 'package:flutter/material.dart';
import '../models/viagem.dart';
import '../models/mensagem.dart';
import '../services/mensagem_service.dart';
import '../services/consultor_service.dart';
import '../services/sessao_service.dart';
import '../services/viagem_service.dart';
import '../utils/app_colors.dart';
import '../utils/formatadores.dart';
import '../widgets/status_chip.dart';

/// Fila real de solicitações, propostas e conclusão do atendimento.
class ConsultorView extends StatefulWidget {
  const ConsultorView({super.key});
  @override
  State<ConsultorView> createState() => _ConsultorViewState();
}

class _ConsultorViewState extends State<ConsultorView> {
  String _filtro = 'Todas';
  bool _atualizando = false;

  Future<void> _recarregar() async {
    setState(() => _atualizando = true);
    await ViagemService().carregar();
    await MensagemService().carregar();
    await ConsultorService().carregar();
    if (mounted) setState(() => _atualizando = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([ViagemService(), MensagemService()]),
    builder: (context, _) {
      final mensagens = MensagemService().obterMinhas();
      final todas = ViagemService().obterViagens();
      final filtradas = todas.where((v) => _filtro == 'Todas' || v.status.rotulo == _filtro).toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Painel do consultor'),
          actions: [
            IconButton(tooltip: 'Atualizar',
              onPressed: _atualizando ? null : _recarregar,
              icon: const Icon(Icons.refresh)),
            IconButton(tooltip: 'Sair', onPressed: () async {
              await SessaoService().sair();
              await ViagemService().carregar();
              await MensagemService().carregar();
              await ConsultorService().carregar();
            }, icon: const Icon(Icons.logout)),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('Olá, ${SessaoService().usuarioAtual?.primeiroNome ?? 'consultor'}!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark)),
              const SizedBox(height: 4),
              const Text('Solicitações disponíveis para análise e proposta.'),
              const SizedBox(height: 18),
              Row(children: [
                _contador('Solicitações', '${todas.length}'),
                const SizedBox(width: 10),
                _contador('Aguardando', '${todas.where((v) => v.status == StatusViagem.enviada).length}'),
              ]),
              if (_atualizando) const LinearProgressIndicator(),
              if (ViagemService().erroConexao != null) ...[
                const SizedBox(height: 10),
                Text(ViagemService().erroConexao!,
                  style: const TextStyle(color: Colors.deepOrange)),
                TextButton(onPressed: _recarregar, child: const Text('Repetir conexão')),
              ],
              const SizedBox(height: 18),
              Text('Mensagens recebidas (${mensagens.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark)),
              const SizedBox(height: 7),
              if (mensagens.isEmpty)
                const Text('Nenhuma mensagem recebida até agora.',
                  style: TextStyle(color: AppColors.textSecondary)),
              for (final m in mensagens.take(8))
                Card(child: ListTile(
                  leading: const Icon(Icons.chat_outlined, color: AppColors.primaryTeal),
                  title: Text(m.assunto.isNotEmpty ? m.assunto : 'Consulta de viagem'),
                  subtitle: Text(m.resposta == null ? m.texto : 'Respondida: ${m.resposta}',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: m.resposta == null ? const Icon(Icons.reply) :
                    const Icon(Icons.done, color: Colors.green),
                  onTap: m.resposta == null ? () => _responderMensagem(m) : null,
                )),
              const SizedBox(height: 22),
              const Text('Fila de solicitações',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in ['Todas', ...StatusViagem.values.map((s) => s.rotulo)])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text(f), selected: _filtro == f,
                        onSelected: (_) => setState(() => _filtro = f)),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              if (filtradas.isEmpty)
                const Padding(padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhuma solicitação neste filtro.'))),
              for (final v in filtradas)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: const CircleAvatar(child: Icon(Icons.flight)),
                    title: Text('${v.destino.nome} • ${v.viajantes} viajante(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Formatadores.periodo(v.inicio, v.fim)),
                        const SizedBox(height: 5), StatusChip(status: v.status),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => _AtendimentoView(viagemId: v.id),
                    )),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _responderMensagem(Mensagem mensagem) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Responder mensagem'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(mensagem.texto),
        const SizedBox(height: 12),
        TextField(controller: controller, maxLines: 4,
          maxLength: 1000, decoration: const InputDecoration(
            labelText: 'Sua resposta', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Responder')),
      ],
    ));
    if (ok == true) {
      try {
        final respondida = await MensagemService().responder(mensagem, controller.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
          Text(respondida ? 'Resposta salva e disponível para o viajante.' :
            'Resposta vazia ou mensagem já respondida.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Não foi possível responder: $e')));
      }
    }
    controller.dispose();
  }

  Widget _contador(String titulo, String numero) => Expanded(
    child: Card(child: Padding(padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text(numero, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
          color: AppColors.primaryTeal)),
        Text(titulo, style: const TextStyle(fontSize: 12)),
      ]))),
  );
}

class _AtendimentoView extends StatefulWidget {
  final String viagemId;
  const _AtendimentoView({required this.viagemId});
  @override
  State<_AtendimentoView> createState() => _AtendimentoViewState();
}

class _AtendimentoViewState extends State<_AtendimentoView> {
  bool _aguardando = false;
  Future<void> _executar(Future<bool> Function() executar) async {
    setState(() => _aguardando = true);
    try {
      final ok = await executar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Atualização registrada com sucesso.' :
          'Operação não permitida para este atendimento.'),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível concluir: $e')),
      );
    } finally { if (mounted) setState(() => _aguardando = false); }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ViagemService(),
    builder: (context, _) {
      final v = ViagemService().obterPorId(widget.viagemId);
      if (v == null) return const Scaffold(body: Center(child: Text('Solicitação não encontrada.')));
      final usuarioId = SessaoService().usuarioAtual?.id;
      final minhaProposta = v.propostas.any((p) => p.consultor.id == usuarioId);
      final possoPropor = !minhaProposta &&
          (v.status == StatusViagem.enviada || v.status == StatusViagem.emAnalise ||
           v.status == StatusViagem.propostaRecebida);
      return Scaffold(
        appBar: AppBar(title: Text('Atendimento • ${v.destino.nome}')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(v.destino.nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), StatusChip(status: v.status),
          const SizedBox(height: 16),
          _linha('Datas', Formatadores.periodo(v.inicio, v.fim)),
          _linha('Viajantes', '${v.viajantes}'),
          _linha('Orçamento', v.orcamento),
          _linha('Serviços', v.interesses.join(', ')),
          _linha('Observações', v.observacoes.isEmpty ? 'Não informadas' : v.observacoes),
          const SizedBox(height: 18),
          if (v.status == StatusViagem.enviada)
            FilledButton.icon(
              onPressed: _aguardando ? null : () => _executar(() => ViagemService().iniciarAnalise(v.id)),
              icon: const Icon(Icons.search), label: const Text('Iniciar análise'),
            ),
          if (possoPropor)
            FilledButton.icon(
              onPressed: _aguardando ? null : () async {
                await Navigator.push<void>(context, MaterialPageRoute(
                  builder: (_) => _FormularioProposta(viagemId: v.id)));
              },
              icon: const Icon(Icons.add_card), label: const Text('Enviar proposta'),
            ),
          if (v.status == StatusViagem.aceita && v.proposta?.consultor.id == usuarioId)
            FilledButton.icon(
              onPressed: _aguardando ? null : () => _executar(() => ViagemService().encerrar(v.id)),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Encerrar atendimento'),
            ),
          const SizedBox(height: 16),
          Text('Propostas recebidas (${v.propostas.length})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          for (final p in v.propostas)
            Card(child: ListTile(
              title: Text(p.consultor.nome),
              subtitle: Text('${Formatadores.moeda(p.valorEstimado)} • ${p.condicoes}'),
              trailing: v.propostaAceitaId == p.id ?
                const Icon(Icons.check_circle, color: Colors.green) : null,
            )),
          const SizedBox(height: 12),
          const Text('Histórico', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          for (final evento in v.historico.reversed)
            ListTile(dense: true, leading: const Icon(Icons.history),
              title: Text(evento.descricao),
              subtitle: Text('${Formatadores.data(evento.quando)} • ${TimeOfDay.fromDateTime(evento.quando).format(context)}')),
        ]),
      );
    },
  );

  Widget _linha(String titulo, String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text('$titulo: $texto'),
  );
}

class _FormularioProposta extends StatefulWidget {
  final String viagemId;
  const _FormularioProposta({required this.viagemId});
  @override
  State<_FormularioProposta> createState() => _FormularioPropostaState();
}

class _FormularioPropostaState extends State<_FormularioProposta> {
  final _form = GlobalKey<FormState>();
  final _valor = TextEditingController();
  final _itens = TextEditingController();
  final _condicoes = TextEditingController();
  DateTime _validade = DateTime.now().add(const Duration(days: 7));
  bool _salvando = false;

  @override
  void dispose() { _valor.dispose(); _itens.dispose(); _condicoes.dispose(); super.dispose(); }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    final valor = double.parse(_valor.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    final itens = _itens.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    setState(() => _salvando = true);
    try {
      final ok = await ViagemService().enviarProposta(widget.viagemId,
        valor, itens, _condicoes.text.trim(), _validade);
      if (!mounted) return;
      if (ok) { Navigator.pop(context); return; }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível registrar a proposta. Confira o status ou se já enviou uma.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => _salvando = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nova proposta')),
    body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Informe os mesmos campos para permitir comparação entre propostas.',
        style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 18),
      TextFormField(controller: _valor, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Valor estimado (R\$)',
          hintText: 'Ex.: 12500,00', border: OutlineInputBorder()),
        validator: (s) {
          final n = double.tryParse((s ?? '').replaceAll('.', '').replaceAll(',', '.'));
          return n == null || n <= 0 || n > 100000000 ? 'Informe um valor positivo válido.' : null;
        }),
      const SizedBox(height: 14),
      TextFormField(controller: _itens, maxLines: 4,
        decoration: const InputDecoration(labelText: 'Itens incluídos (um por linha)',
          hintText: 'Hospedagem\nPassagem\nTraslado', border: OutlineInputBorder()),
        validator: (s) => (s ?? '').trim().isEmpty ? 'Liste ao menos um item.' : null),
      const SizedBox(height: 14),
      TextFormField(controller: _condicoes, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Condições comerciais', border: OutlineInputBorder()),
        validator: (s) => (s ?? '').trim().isEmpty ? 'Informe as condições.' : null),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () async {
          final data = await showDatePicker(context: context, initialDate: _validade,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)));
          if (data != null) setState(() => _validade = DateTime(data.year, data.month, data.day, 23, 59));
        },
        icon: const Icon(Icons.calendar_month),
        label: Text('Validade: ${Formatadores.data(_validade)}'),
      ),
      const SizedBox(height: 18),
      FilledButton(onPressed: _salvando ? null : _enviar,
        child: _salvando ? const CircularProgressIndicator() : const Text('Enviar proposta')),
    ])),
  );
}
