import 'package:flutter/material.dart';

/// Identidade visual compartilhada entre os pontos de entrada do aplicativo.
class AppLogo extends StatelessWidget {
  final double height;
  const AppLogo({super.key, this.height = 88});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/logo.jpg',
    height: height,
    fit: BoxFit.contain,
    semanticLabel: 'Logo Connecta Trip',
  );
}
