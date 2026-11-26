/// Funções de formatação em pt-BR (sem depender do pacote intl).
class Formatadores {
  static const List<String> _meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  static String _dois(int n) => n.toString().padLeft(2, '0');

  static String mes(int mes) => _meses[mes - 1];

  /// 04/11/2026
  static String data(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

  /// "12 a 19 de novembro", "28 de novembro a 3 de dezembro" ou datas completas
  /// quando o período atravessa anos.
  static String periodo(DateTime inicio, DateTime fim) {
    if (inicio.year == fim.year && inicio.month == fim.month) {
      return '${inicio.day} a ${fim.day} de ${mes(fim.month)}';
    }
    if (inicio.year == fim.year) {
      return '${inicio.day} de ${mes(inicio.month)} a ${fim.day} de ${mes(fim.month)}';
    }
    return '${data(inicio)} a ${data(fim)}';
  }

  /// R$ 9.100,00
  static String moeda(double valor) {
    final centavos = (valor * 100).round();
    final inteiro = (centavos ~/ 100).toString();
    final decimal = (centavos % 100).toString().padLeft(2, '0');
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
      buffer.write(inteiro[i]);
    }
    return 'R\$ $buffer,$decimal';
  }

  /// Minúsculas e sem acentos, para buscas.
  static String normalizar(String texto) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    final buffer = StringBuffer();
    for (final rune in texto.toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      final i = de.indexOf(c);
      buffer.write(i >= 0 ? para[i] : c);
    }
    return buffer.toString();
  }
}
