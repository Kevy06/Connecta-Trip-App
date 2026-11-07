import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Botão principal (preenchido, teal) ou secundário (outlined) do app.
class BotaoPersonalizado extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool iconeAposTexto;
  final bool outlined;
  final bool carregando;

  const BotaoPersonalizado({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icone,
    this.iconeAposTexto = false,
    this.outlined = false,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = outlined ? AppColors.primaryTeal : Colors.white;
    final acao = carregando ? null : onPressed;
    final forma = const StadiumBorder();

    final rotulo = Text(
      texto,
      style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 15),
    );
    final Widget conteudo;
    if (carregando) {
      conteudo = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: cor),
      );
    } else if (icone == null) {
      conteudo = rotulo;
    } else {
      final icon = Icon(icone, size: 18, color: cor);
      conteudo = Row(
        mainAxisSize: MainAxisSize.min,
        children: iconeAposTexto
            ? [rotulo, const SizedBox(width: 8), icon]
            : [icon, const SizedBox(width: 8), rotulo],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton(
              onPressed: acao,
              style: OutlinedButton.styleFrom(
                shape: forma,
                side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
              ),
              child: conteudo,
            )
          : ElevatedButton(
              onPressed: acao,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.7),
                elevation: 0,
                shape: forma,
              ),
              child: conteudo,
            ),
    );
  }
}
