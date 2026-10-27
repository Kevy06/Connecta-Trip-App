import '../models/destino.dart';
import '../services/destino_service.dart';

class HomePresenter {
  final DestinoService _service = DestinoService();

  Destino obterDestinoDestaque() {
    final destinos = _service.obterDestinos();
    return destinos.firstWhere((d) => d.emDestaque, orElse: () => destinos.first);
  }

  List<Destino> obterRecomendados() {
    return _service.obterDestinos().where((d) => !d.emDestaque).toList();
  }

  List<Destino> obterTodosDestinos() {
    return _service.obterDestinos();
  }
}