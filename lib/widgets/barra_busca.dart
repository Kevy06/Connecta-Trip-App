import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Campo "Para onde você quer ir?" usado na Home e em Destinos.
class BarraBusca extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const BarraBusca({super.key, required this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Para onde você quer ir?',
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.searchBarBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
