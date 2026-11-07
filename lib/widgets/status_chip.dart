import 'package:flutter/material.dart';
import '../models/viagem.dart';
import '../utils/app_colors.dart';

class StatusChip extends StatelessWidget {
  final StatusViagem status;
  const StatusChip({super.key, required this.status});

  Color get _cor => switch (status) {
        StatusViagem.enviada => AppColors.textSecondary,
        StatusViagem.emAnalise => AppColors.accentOrange,
        StatusViagem.propostaRecebida => AppColors.primaryTeal,
        StatusViagem.aceita => AppColors.success,
        StatusViagem.encerrada => AppColors.primaryDark,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.rotulo,
        style: TextStyle(color: _cor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
