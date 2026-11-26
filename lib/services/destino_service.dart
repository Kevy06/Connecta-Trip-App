import 'package:flutter/foundation.dart';
import '../models/destino.dart';
import '../data/banco_local.dart';
import 'sessao_service.dart';

/// Catálogo de destinos e favoritos, isolados por viajante.
class DestinoService extends ChangeNotifier {
  static final DestinoService _instancia = DestinoService._();
  factory DestinoService() => _instancia;
  DestinoService._();

  final Set<String> _favoritos = {};

  Future<void> carregar() async {
    _favoritos.clear();
    final usuario = SessaoService().usuarioAtual;
    if (usuario != null) {
      _favoritos.addAll(await BancoLocal().listarFavoritos(usuario.id));
    }
    notifyListeners();
  }

  bool ehFavorito(String id) => _favoritos.contains(id);

  void alternarFavorito(String id) {
    final usuario = SessaoService().usuarioAtual;
    if (usuario == null) return;
    if (!_favoritos.remove(id)) _favoritos.add(id);
    notifyListeners();
    BancoLocal().gravarFavorito(usuario.id, id, _favoritos.contains(id));
  }

  List<Destino> obterFavoritos() => obterDestinos()
      .where((d) => _favoritos.contains(d.id)).toList(growable: false);

  List<Destino> obterDestinos() => [
        Destino(
          id: '1', nome: 'Cancún', pais: 'México',
          subtitulo: 'Experiências para guardar na memória',
          descricaoCurta: 'Pacotes sob medida',
          imagemUrl: 'https://images.unsplash.com/photo-1552074284-5e88ef1aef18?auto=format&fit=crop&w=800&q=80',
          categoria: 'Praias', noites: 7, emDestaque: true,
        ),
        Destino(
          id: '2', nome: 'Paris', pais: 'França',
          subtitulo: 'Cultura, história e experiências únicas',
          descricaoCurta: 'Pacotes sob medida',
          imagemUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=800&q=80',
          categoria: 'Europa', noites: 5,
        ),
        Destino(
          id: '3', nome: 'Orlando', pais: 'EUA',
          subtitulo: 'Diversão para toda a família',
          descricaoCurta: 'Pacotes sob medida',
          imagemUrl: 'https://images.unsplash.com/photo-1575089776834-8be34696ffb9?auto=format&fit=crop&w=800&q=80',
          categoria: 'Resorts', noites: 10,
        ),
      ];
}
