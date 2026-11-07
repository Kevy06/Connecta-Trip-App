import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PassoLinhaTempo {
  final String titulo;
  final String descricao;
  final bool ativo;

  const PassoLinhaTempo({
    required this.titulo,
    required this.descricao,
    this.ativo = true,
  });
}

/// Linha do tempo vertical ("Seu roteiro" e acompanhamento de status).
class LinhaTempo extends StatelessWidget {
  final List<PassoLinhaTempo> passos;

  const LinhaTempo({super.key, required this.passos});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < passos.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      _Ponto(ativo: passos[i].ativo),
                      if (i < passos.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passos[i].titulo,
                          style: TextStyle(
                            color: passos[i].ativo
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          passos[i].descricao,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Ponto extends StatelessWidget {
  final bool ativo;
  const _Ponto({required this.ativo});

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? AppColors.primaryTeal : AppColors.border;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
      ),
    );
  }
}
