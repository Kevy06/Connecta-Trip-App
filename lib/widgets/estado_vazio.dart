import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'botao_personalizado.dart';

/// Estado "vazio" padrão das telas (documento, seção 3.3).
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? textoBotao;
  final VoidCallback? onBotao;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.textoBotao,
    this.onBotao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: AppColors.primaryTeal),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            if (textoBotao != null && onBotao != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: BotaoPersonalizado(texto: textoBotao!, onPressed: onBotao),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
