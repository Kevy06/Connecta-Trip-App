import 'package:flutter/foundation.dart';
import '../models/destino.dart';
import '../services/destino_service.dart';

class ItemInclusao {
  final String titulo;
  final String descricao;
  const ItemInclusao(this.titulo, this.descricao);
}

/// Estado da tela 03 (Pacote).
class DetalhesDestinoPresenter {
  final Destino destino;
  final DestinoService _service = DestinoService();

  DetalhesDestinoPresenter(this.destino);

  Listenable get favoritosListenable => _service;

  String get titulo => '${destino.nome} do seu jeito';
  String get localizacao => '${destino.pais} • ${destino.noites} noites';
  String get avisoValores => 'Valores e disponibilidade sob consulta.';

  bool get favorito => _service.ehFavorito(destino.id);
  void alternarFavorito() => _service.alternarFavorito(destino.id);

  List<ItemInclusao> get detalhesIncluidos => const [
        ItemInclusao('Hospedagem selecionada', 'Conforto e excelente localização'),
        ItemInclusao('Traslado aeroporto / hotel', 'Mais comodidade para a sua viagem'),
        ItemInclusao('Consultoria personalizada', 'Suporte antes, durante e depois da viagem'),
      ];
}
