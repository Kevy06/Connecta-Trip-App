import 'package:flutter/foundation.dart';
import '../models/viagem.dart';
import '../services/viagem_service.dart';

/// Estado da tela 04 (Minhas viagens).
class ViagensPresenter {
  final ViagemService _service = ViagemService();

  Listenable get listenable => _service;

  List<Viagem> get viagens => _service.obterViagens();

  /// Viagem mostrada no topo: a próxima já aceita; senão a solicitação mais recente em aberto.
  Viagem? get viagemDestaque {
    final todas = viagens;
    final hoje = DateTime.now();
    final aceitas = todas
        .where((v) => v.status == StatusViagem.aceita && v.fim.isAfter(hoje))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    if (aceitas.isNotEmpty) return aceitas.first;
    for (final v in todas) {
      if (v.status != StatusViagem.encerrada) return v;
    }
    return todas.isEmpty ? null : todas.first;
  }

  bool get temViagemConfirmada => viagemDestaque?.status.confirmada ?? false;

}
