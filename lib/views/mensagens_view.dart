import 'package:flutter/material.dart';
import '../services/mensagem_service.dart';
import '../utils/app_colors.dart';
import '../utils/formatadores.dart';
import '../widgets/consultor_sheet.dart';

class MensagensView extends StatelessWidget {
  const MensagensView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mensagens')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        await ConsultorSheet.mostrar(context);
        await MensagemService().carregar();
      },
      icon: const Icon(Icons.add_comment_outlined),
      label: const Text('Nova mensagem'),
    ),
    body: ListenableBuilder(
      listenable: MensagemService(),
      builder: (context, _) {
        final mensagens = MensagemService().obterMinhas();
        return RefreshIndicator(
          onRefresh: MensagemService().carregar,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (MensagemService().erroConexao != null)
              Text(MensagemService().erroConexao!,
                style: const TextStyle(color: Colors.deepOrange)),
            if (mensagens.isEmpty)
              const Padding(padding: EdgeInsets.all(30),
                child: Text('Ainda não há mensagens. Inicie um contato com um consultor.')),
            for (final m in mensagens)
              Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.consultorNome, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark)),
                  if (m.assunto.isNotEmpty) Text('Assunto: ${m.assunto}'),
                  Text(m.texto),
                  const SizedBox(height: 8),
                  Text('Enviada em ${Formatadores.data(m.criadaEm)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Divider(),
                  Text(m.resposta == null ? 'Aguardando resposta do consultor.' :
                    'Resposta: ${m.resposta}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                ]),
              )),
            const SizedBox(height: 70),
          ]),
        );
      },
    ),
  );
}
