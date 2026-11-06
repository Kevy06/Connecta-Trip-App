import 'package:flutter/material.dart';
import '../models/consultor.dart';
import '../services/consultor_service.dart';
import '../utils/app_colors.dart';

/// "Falar com consultor": escolhe um consultor e escreve a mensagem.
///
/// O envio real depende da API REST (ainda não existe); por ora a mensagem
/// só é confirmada na tela.
class ConsultorSheet {
  static Future<void> mostrar(BuildContext context, {String? assunto}) async {
    final consultor = await showModalBottomSheet<Consultor>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ListaConsultores(),
    );
    if (consultor == null || !context.mounted) return;

    final mensagem = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoMensagem(consultor: consultor, assunto: assunto),
    );
    if (mensagem == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mensagem para ${consultor.nome} registrada. O envio real será ligado à API.',
        ),
      ),
    );
  }
}

class _ListaConsultores extends StatelessWidget {
  const _ListaConsultores();

  @override
  Widget build(BuildContext context) {
    final consultores = ConsultorService().obterConsultores();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Falar com um consultor',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escolha quem vai te atender.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            for (final c in consultores)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryTeal,
                  child: Text(
                    c.iniciais,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  c.nome,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Especialista em ${c.especialidade}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogoMensagem extends StatefulWidget {
  final Consultor consultor;
  final String? assunto;

  const _DialogoMensagem({required this.consultor, this.assunto});

  @override
  State<_DialogoMensagem> createState() => _DialogoMensagemState();
}

class _DialogoMensagemState extends State<_DialogoMensagem> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.assunto == null
        ? ''
        : 'Olá! Gostaria de saber mais sobre ${widget.assunto}.',
  );
  String? _erro;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) {
      setState(() => _erro = 'Escreva uma mensagem.');
      return;
    }
    Navigator.of(context).pop(texto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mensagem para ${widget.consultor.nome}'),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Como podemos ajudar?',
          errorText: _erro,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _enviar, child: const Text('Enviar')),
      ],
    );
  }
}
