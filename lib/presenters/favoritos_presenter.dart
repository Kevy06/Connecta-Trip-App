import 'package:flutter/foundation.dart';
import '../models/destino.dart';
import '../services/destino_service.dart';

class FavoritosPresenter {
  final DestinoService _service = DestinoService();

  Listenable get listenable => _service;

  List<Destino> get favoritos => _service.obterFavoritos();

  void remover(String id) {
    if (_service.ehFavorito(id)) _service.alternarFavorito(id);
  }
}
