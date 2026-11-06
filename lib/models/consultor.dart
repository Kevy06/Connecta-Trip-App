class Consultor {
  final String id;
  final String nome;
  final String especialidade;

  const Consultor({
    required this.id,
    required this.nome,
    required this.especialidade,
  });

  String get iniciais {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.length < 2) return partes.isEmpty ? '?' : partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
