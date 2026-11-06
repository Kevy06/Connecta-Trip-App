import '../models/consultor.dart';

/// Consultores de exemplo. Substituir por dados da API quando existir.
class ConsultorService {
  static final ConsultorService _instance = ConsultorService._interno();
  factory ConsultorService() => _instance;
  ConsultorService._interno();

  final List<Consultor> _consultores = const [
    Consultor(
      id: 'c1',
      nome: 'Ana Beatriz Lima',
      especialidade: 'Caribe e Américas',
    ),
    Consultor(
      id: 'c2',
      nome: 'Carlos Mendes',
      especialidade: 'Europa e roteiros culturais',
    ),
    Consultor(
      id: 'c3',
      nome: 'Marina Souza',
      especialidade: 'Resorts, parques e viagens em família',
    ),
  ];

  List<Consultor> obterConsultores() => List.unmodifiable(_consultores);
}
