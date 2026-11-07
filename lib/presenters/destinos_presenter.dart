import '../models/destino.dart';
import '../services/destino_service.dart';
import '../utils/formatadores.dart';

/// Estado da tela 02 (Destinos): categoria ativa + texto de busca.
class DestinosPresenter {
  static const String todos = 'Todos';

  final DestinoService _service = DestinoService();

  String categoriaSelecionada = todos;
  String busca = '';

  List<String> get categorias {
    final nomes = <String>[];
    for (final d in _service.obterDestinos()) {
      if (!nomes.contains(d.categoria)) nomes.add(d.categoria);
    }
    return [todos, ...nomes];
  }

  List<Destino> get destinosFiltrados {
    final termo = Formatadores.normalizar(busca.trim());
    return _service.obterDestinos().where((d) {
      final categoriaOk = categoriaSelecionada == todos || d.categoria == categoriaSelecionada;
      final buscaOk = termo.isEmpty ||
          Formatadores.normalizar('${d.nome} ${d.pais} ${d.subtitulo}').contains(termo);
      return categoriaOk && buscaOk;
    }).toList();
  }
}
