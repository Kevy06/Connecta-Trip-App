enum PerfilUsuario {
  viajante('Viajante'),
  consultor('Consultor');

  final String rotulo;
  const PerfilUsuario(this.rotulo);
}

class Usuario {
  final String id;
  final String nome;
  final String email;
  final PerfilUsuario perfil;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.perfil = PerfilUsuario.viajante,
  });

  String get primeiroNome => nome.trim().split(' ').first;

  String get iniciais {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
