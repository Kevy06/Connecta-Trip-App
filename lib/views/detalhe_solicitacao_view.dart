import 'package:flutter/material.dart';
import '../models/viagem.dart';
import '../services/viagem_service.dart';
import '../utils/app_colors.dart';
import '../utils/formatadores.dart';
import '../widgets/status_chip.dart';

/// Tela completa de acompanhamento, comparação e aceite de propostas.
class DetalheSolicitacaoView extends StatefulWidget {
  final String viagemId;
  const DetalheSolicitacaoView({super.key, required this.viagemId});
  @override
  State<DetalheSolicitacaoView> createState() => _DetalheSolicitacaoViewState();
}

class _DetalheSolicitacaoViewState extends State<DetalheSolicitacaoView> {
  bool _ocupado = false;

  Future<void> _aceitar(String id, String propostaId) async {
    setState(() => _ocupado = true);
    try {
      final ok = await ViagemService().aceitarPropostaEscolhida(id, propostaId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        ok ? 'Proposta aceita! Acompanhe o andamento.' :
          'Não é possível aceitar esta proposta (verifique a validade).')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => _ocupado = false); }
  }

  Future<void> _avaliar(Viagem v) async {
    int nota = 5;
    final comentario = TextEditingController();
    final confirmado = await showDialog<bool>(context: context, builder: (context) =>
      StatefulBuilder(builder: (context, atualizar) => AlertDialog(
        title: const Text('Avaliar atendimento'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(children: [for (var i = 1; i <= 5; i++) IconButton(
            onPressed: () => atualizar(() => nota = i),
            icon: Icon(i <= nota ? Icons.star : Icons.star_border),
            color: AppColors.accentOrange,
          )]),
          TextField(controller: comentario, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comentário (opcional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enviar')),
        ],
      )),
    );
    if (confirmado == true) {
      setState(() => _ocupado = true);
      try {
        final ok = await ViagemService().avaliarAsync(v.id, nota, comentario.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Avaliação enviada.' : 'Não foi possível avaliar.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      } finally { if (mounted) setState(() => _ocupado = false); }
    }
    comentario.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ViagemService(),
    builder: (context, _) {
      final v = ViagemService().obterPorId(widget.viagemId);
      if (v == null) return const Scaffold(body: Center(child: Text('Solicitação não encontrada.')));
      final propostas = [...v.propostas]..sort((a, b) => a.valorEstimado.compareTo(b.valorEstimado));
      return Scaffold(
        appBar: AppBar(title: Text('Viagem • ${v.destino.nome}')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('${v.destino.nome}, ${v.destino.pais}',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold,
              color: AppColors.primaryDark)),
          const SizedBox(height: 10), StatusChip(status: v.status),
          const SizedBox(height: 12),
          Text('Período: ${Formatadores.periodo(v.inicio, v.fim)}'),
          Text('Viajantes: ${v.viajantes} • Faixa: ${v.orcamento}'),
          Text('Serviços: ${v.interesses.join(', ')}'),
          if (v.observacoes.isNotEmpty) Text('Observações: ${v.observacoes}'),
          const SizedBox(height: 24),
          Text('Comparar propostas (${propostas.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Os valores são estimativas, não reservas confirmadas.',
            style: TextStyle(color: AppColors.textSecondary)),
          if (propostas.isEmpty) const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Aguardando o envio de propostas pelos consultores.')),
          for (final p in propostas)
            Card(margin: const EdgeInsets.symmetric(vertical: 8), child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(p.consultor.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  if (v.propostaAceitaId == p.id)
                    const Icon(Icons.verified, color: Colors.green),
                ]),
                const SizedBox(height: 6),
                Text(Formatadores.moeda(p.valorEstimado), style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                const SizedBox(height: 8),
                Text('Inclui: ${p.itensIncluidos.join(', ')}'),
                Text('Condições: ${p.condicoes}'),
                Text('Validade: ${Formatadores.data(p.validade)}'),
                if (v.status == StatusViagem.propostaRecebida)
                  SizedBox(width: double.infinity, child: FilledButton(
                    onPressed: _ocupado ? null : () => _aceitar(v.id, p.id),
                    child: const Text('Aceitar esta proposta'),
                  )),
              ]),
            )),
          const SizedBox(height: 20),
          const Text('Histórico e rastreabilidade',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          for (final evento in v.historico.reversed)
            ListTile(contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, color: AppColors.primaryTeal),
              title: Text(evento.descricao),
              subtitle: Text('${Formatadores.data(evento.quando)} • ${TimeOfDay.fromDateTime(evento.quando).format(context)}')),
          if (v.status == StatusViagem.encerrada && v.avaliacao == null)
            FilledButton.icon(onPressed: _ocupado ? null : () => _avaliar(v),
              icon: const Icon(Icons.star), label: const Text('Avaliar atendimento')),
          if (v.avaliacao != null)
            Card(child: ListTile(leading: const Icon(Icons.star, color: AppColors.accentOrange),
              title: Text('Sua nota: ${v.avaliacao!.nota}/5'),
              subtitle: Text(v.avaliacao!.comentario))),
        ]),
      );
    },
  );
}
