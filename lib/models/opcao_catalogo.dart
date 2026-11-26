/// Opções referenciais de demonstração. Não indicam preços, disponibilidade
/// nem parceria com hotéis, seguradoras, operadoras ou companhias aéreas.
enum TipoServico { hospedagem, passagem, traslado, seguro }

extension TipoServicoDescricao on TipoServico {
  String get rotulo => switch (this) {
    TipoServico.hospedagem => 'Hotéis',
    TipoServico.passagem => 'Passagens',
    TipoServico.traslado => 'Traslado',
    TipoServico.seguro => 'Seguro viagem',
  };

  String get interesse => switch (this) {
    TipoServico.hospedagem => 'Hospedagem',
    TipoServico.passagem => 'Passagem',
    TipoServico.traslado => 'Traslado',
    TipoServico.seguro => 'Seguro',
  };
}

class OpcaoCatalogo {
  final String id;
  final String destinoId;
  final TipoServico tipo;
  final String nome;
  final String descricao;
  final String categoria;
  final List<String> facilidades;

  const OpcaoCatalogo({required this.id, required this.destinoId,
    required this.tipo, required this.nome, required this.descricao,
    required this.categoria, this.facilidades = const []});
}

/// Dados referenciais offline. Nomes de hotéis são exemplos de estabelecimentos
/// conhecidos; a base NÃO consulta seus preços ou sua disponibilidade atual.
class CatalogoServicos {
  static const List<OpcaoCatalogo> hoteis = [
    OpcaoCatalogo(id:'h1',destinoId:'1',tipo:TipoServico.hospedagem,
      nome:'Hyatt Ziva Cancun',descricao:'Referência de hospedagem em Cancún',
      categoria:'Resort',facilidades:['Praia','Piscina','Restaurantes']),
    OpcaoCatalogo(id:'h2',destinoId:'1',tipo:TipoServico.hospedagem,
      nome:'Fiesta Americana Condesa Cancun',descricao:'Referência de resort em Cancún',
      categoria:'Resort',facilidades:['Piscina','Restaurantes','Lazer']),
    OpcaoCatalogo(id:'h3',destinoId:'2',tipo:TipoServico.hospedagem,
      nome:'Novotel Paris Les Halles',descricao:'Referência de hospedagem em Paris',
      categoria:'Hotel',facilidades:['Localização central','Quartos','Recepção']),
    OpcaoCatalogo(id:'h4',destinoId:'2',tipo:TipoServico.hospedagem,
      nome:'ibis Paris Tour Eiffel Cambronne',descricao:'Referência de hospedagem em Paris',
      categoria:'Hotel',facilidades:['Transporte próximo','Quartos','Recepção']),
    OpcaoCatalogo(id:'h5',destinoId:'3',tipo:TipoServico.hospedagem,
      nome:'Universal’s Cabana Bay Beach Resort',descricao:'Referência de hospedagem em Orlando',
      categoria:'Resort',facilidades:['Piscina','Lazer','Quartos']),
    OpcaoCatalogo(id:'h6',destinoId:'3',tipo:TipoServico.hospedagem,
      nome:'Rosen Inn International',descricao:'Referência de hospedagem em Orlando',
      categoria:'Hotel',facilidades:['Piscina','Quartos','Recepção']),
  ];

  /// Rotas de pesquisa; NÃO há promessa de voo direto, horário ou companhia.
  static const List<OpcaoCatalogo> passagens = [
    OpcaoCatalogo(id:'p1',destinoId:'1',tipo:TipoServico.passagem,
      nome:'São Paulo (GRU) → Cancún (CUN)',descricao:'Rota de pesquisa de passagens',
      categoria:'GRU',facilidades:['Ida e volta','Conexões a confirmar']),
    OpcaoCatalogo(id:'p2',destinoId:'1',tipo:TipoServico.passagem,
      nome:'Rio de Janeiro (GIG) → Cancún (CUN)',descricao:'Rota de pesquisa de passagens',
      categoria:'GIG',facilidades:['Ida e volta','Conexões a confirmar']),
    OpcaoCatalogo(id:'p3',destinoId:'2',tipo:TipoServico.passagem,
      nome:'São Paulo (GRU) → Paris (CDG)',descricao:'Rota de pesquisa de passagens',
      categoria:'GRU',facilidades:['Ida e volta','Conexões a confirmar']),
    OpcaoCatalogo(id:'p4',destinoId:'2',tipo:TipoServico.passagem,
      nome:'Rio de Janeiro (GIG) → Paris (CDG)',descricao:'Rota de pesquisa de passagens',
      categoria:'GIG',facilidades:['Ida e volta','Conexões a confirmar']),
    OpcaoCatalogo(id:'p5',destinoId:'3',tipo:TipoServico.passagem,
      nome:'São Paulo (GRU) → Orlando (MCO)',descricao:'Rota de pesquisa de passagens',
      categoria:'GRU',facilidades:['Ida e volta','Conexões a confirmar']),
    OpcaoCatalogo(id:'p6',destinoId:'3',tipo:TipoServico.passagem,
      nome:'Rio de Janeiro (GIG) → Orlando (MCO)',descricao:'Rota de pesquisa de passagens',
      categoria:'GIG',facilidades:['Ida e volta','Conexões a confirmar']),
  ];

  static List<OpcaoCatalogo> paraDestino(TipoServico tipo, String destinoId) =>
    (tipo == TipoServico.hospedagem ? hoteis : passagens)
      .where((o) => o.destinoId == destinoId).toList(growable:false);
}
