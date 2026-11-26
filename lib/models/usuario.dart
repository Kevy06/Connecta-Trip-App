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
  const Usuario({required this.id, required this.nome, required this.email,
    this.perfil = PerfilUsuario.viajante});
  String get primeiroNome => nome.trim().split(' ').first;
  String get iniciais {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return (partes.first[0] + (partes.length == 1 ? '' : partes.last[0])).toUpperCase();
  }
  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as String, nome: json['nome'] as String,
    email: json['email'] as String,
    perfil: PerfilUsuario.values.firstWhere((v) => v.name == json['perfil'],
      orElse: () => PerfilUsuario.viajante),
  );
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'email': email, 'perfil': perfil.name};
}
