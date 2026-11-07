import 'package:flutter/material.dart';
import '../models/destino.dart';
import 'imagem_rede.dart';

/// Cartão grande de destino (tela 02: "Cancún, México · Pacotes sob medida").
class DestinoCard extends StatelessWidget {
  final Destino destino;
  final VoidCallback onTap;
  final double altura;

  /// Quando informado, mostra um coração no canto para remover dos favoritos.
  final VoidCallback? onRemoverFavorito;

  const DestinoCard({
    super.key,
    required this.destino,
    required this.onTap,
    this.altura = 150,
    this.onRemoverFavorito,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: altura,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImagemRede(url: destino.imagemUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              if (onRemoverFavorito != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemoverFavorito,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.favorite, size: 18, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${destino.nome}, ${destino.pais}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            destino.descricaoCurta,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Consultar opções',
                            style: TextStyle(
                              color: Color(0xFF0A2540),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 14, color: Color(0xFF009688)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
