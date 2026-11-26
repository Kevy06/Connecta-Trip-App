import 'package:flutter/material.dart';

Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String confirmar,
}) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            scrollable: true,
            title: Text(titulo),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmar),
              ),
            ],
          ),
    ) ??
    false;
