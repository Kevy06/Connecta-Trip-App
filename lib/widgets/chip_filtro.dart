import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Pílula de filtro (Todos / Praias / Europa / Resorts).
class ChipFiltro extends StatelessWidget {
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  const ChipFiltro({
    super.key,
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selecionado ? AppColors.primaryTeal : AppColors.border,
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: selecionado ? Colors.white : AppColors.primaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
