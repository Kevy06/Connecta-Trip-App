class Destino {
  final String id;
  final String nome;
  final String pais;
  final String subtitulo;
  final String descricaoCurta;
  final String imagemUrl;
  final String categoria; // Praias, Europa, Resorts, 
  final int noites;
  final bool emDestaque;
  final List<String> inclusoes;

  Destino({
    required this.id,
    required this.nome,
    required this.pais,
    required this.subtitulo,
    required this.descricaoCurta,
    required this.imagemUrl,
    required this.categoria,
    this.noites = 7,
    this.emDestaque = false,
    this.inclusoes = const ['Hotel', 'Traslado', 'Seguro'],
  });
}