import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Image.network com indicador de carregamento e fallback em caso de erro
/// (sem internet, URL quebrada), para a UI nunca ficar com buraco ou exceção.
class ImagemRede extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;

  const ImagemRede({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  Widget _caixa(Widget filho) => Container(
        height: height,
        width: width,
        color: AppColors.searchBarBackground,
        alignment: Alignment.center,
        child: filho,
      );

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, progresso) => progresso == null
          ? child
          : _caixa(const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
            )),
      errorBuilder: (context, erro, stack) =>
          _caixa(const Icon(Icons.landscape_outlined, color: AppColors.textSecondary, size: 32)),
    );
  }
}
