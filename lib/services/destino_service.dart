import '../models/destino.dart';

class DestinoService {
  List<Destino> obterDestinos() {
    return [
      Destino(
        id: '1',
        nome: 'Cancún',
        pais: 'México',
        subtitulo: 'Experiências para guardar na memória',
        descricaoCurta: 'Pacotes sob medida',
        imagemUrl: 'https://images.unsplash.com/photo-1552074284-5e88ef1aef18?auto=format&fit=crop&w=800&q=80',
        categoria: 'Praias',
        noites: 7,
        emDestaque: true,
      ),
      Destino(
        id: '2',
        nome: 'Paris',
        pais: 'França',
        subtitulo: 'Cultura, história e experiências únicas',
        descricaoCurta: 'Pacotes sob medida',
        imagemUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=800&q=80',
        categoria: 'Europa',
        noites: 5,
        emDestaque: false,
      ),
      Destino(
        id: '3',
        nome: 'Orlando',
        pais: 'EUA',
        subtitulo: 'Diversão para toda a família',
        descricaoCurta: 'Pacotes sob medida',
        imagemUrl: 'https://images.unsplash.com/photo-1575089776834-8be34696ffb9?auto=format&fit=crop&w=800&q=80',
        categoria: 'Resorts',
        noites: 10,
        emDestaque: false,
      ),
    ];
  }
}