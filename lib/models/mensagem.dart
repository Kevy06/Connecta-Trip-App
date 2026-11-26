/// Mensagem iniciada pelo viajante e resposta única do consultor escolhido.
class Mensagem {
  final String id;
  final String viajanteId;
  final String consultorId;
  final String consultorNome;
  final String assunto;
  final String texto;
  final DateTime criadaEm;
  String? resposta;
  DateTime? respondidaEm;

  Mensagem({required this.id, required this.viajanteId, required this.consultorId,
    required this.consultorNome, required this.assunto, required this.texto,
    required this.criadaEm, this.resposta, this.respondidaEm});

  Map<String, dynamic> toJson() => {
    'id': id, 'viajanteId': viajanteId, 'consultorId': consultorId,
    'consultorNome': consultorNome, 'assunto': assunto, 'texto': texto,
    'criadaEm': criadaEm.toIso8601String(), 'resposta': resposta,
    'respondidaEm': respondidaEm?.toIso8601String(),
  };
  factory Mensagem.fromJson(Map<String, dynamic> dados) => Mensagem(
    id: dados['id'] as String,
    viajanteId: dados['viajanteId'] as String,
    consultorId: dados['consultorId'] as String,
    consultorNome: dados['consultorNome'] as String,
    assunto: dados['assunto'] as String? ?? '',
    texto: dados['texto'] as String,
    criadaEm: DateTime.parse(dados['criadaEm'] as String),
    resposta: dados['resposta'] as String?,
    respondidaEm: dados['respondidaEm'] == null ? null :
      DateTime.parse(dados['respondidaEm'] as String),
  );
}
