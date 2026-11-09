import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/destino_service.dart';
import '../services/consultor_service.dart';
import '../services/mensagem_service.dart';
import '../services/sessao_service.dart';
import '../services/viagem_service.dart';
import '../utils/app_colors.dart';

class AutenticacaoView extends StatefulWidget {
  const AutenticacaoView({super.key});
  @override
  State<AutenticacaoView> createState() => _AutenticacaoViewState();
}

class _AutenticacaoViewState extends State<AutenticacaoView> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _cadastro = false;
  bool _ocupado = false;
  bool _ocultarSenha = true;
  PerfilUsuario _perfil = PerfilUsuario.viajante;

  @override
  void dispose() { _nome.dispose(); _email.dispose(); _senha.dispose(); super.dispose(); }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate() || _ocupado) return;
    setState(() => _ocupado = true);
    String? erro;
    try {
      if (_cadastro) {
        erro = await SessaoService().cadastrar(_nome.text, _email.text, _senha.text, _perfil);
      } else {
        erro = await SessaoService().entrar(_email.text, _senha.text);
      }
      if (erro == null) {
        await DestinoService().carregar();
        await ViagemService().carregar();
        await ConsultorService().carregar();
        await MensagemService().carregar();
      }
    } catch (e) { erro = 'Não foi possível acessar sua conta: $e'; }
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (erro != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.travel_explore, color: AppColors.primaryTeal, size: 58),
                const SizedBox(height: 14),
                const Text('Connecta Trip', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark)),
                const SizedBox(height: 6),
                Text(_cadastro ? 'Crie sua conta para começar' : 'Entre para planejar sua próxima viagem',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                if (_cadastro) ...[
                  TextFormField(controller: _nome,
                    decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    validator: (v) => (v ?? '').trim().length < 3 ? 'Digite seu nome.' : null),
                  const SizedBox(height: 14),
                ],
                TextFormField(controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  validator: (v) => !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '') ? 'E-mail inválido.' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _senha, obscureText: _ocultarSenha,
                  decoration: InputDecoration(labelText: 'Senha (mínimo 6 caracteres)', border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha))),
                  validator: (v) => (v ?? '').length < 6 ? 'Informe pelo menos 6 caracteres.' : null),
                if (_cadastro) ...[
                  const SizedBox(height: 20),
                  const Text('Quero usar como', style: TextStyle(fontWeight: FontWeight.w600)),
                  SegmentedButton<PerfilUsuario>(
                    segments: const [
                      ButtonSegment(value: PerfilUsuario.viajante, label: Text('Viajante'), icon: Icon(Icons.flight_takeoff)),
                      ButtonSegment(value: PerfilUsuario.consultor, label: Text('Consultor'), icon: Icon(Icons.support_agent)),
                    ],
                    selected: {_perfil}, onSelectionChanged: (set) => setState(() => _perfil = set.first),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _ocupado ? null : _enviar,
                  icon: _ocupado ? const SizedBox(height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) :
                    Icon(_cadastro ? Icons.person_add_alt_1 : Icons.login),
                  label: Text(_cadastro ? 'Criar conta' : 'Entrar'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.primaryTeal),
                ),
                TextButton(
                  onPressed: _ocupado ? null : () => setState(() => _cadastro = !_cadastro),
                  child: Text(_cadastro ? 'Já tenho uma conta' : 'Não tem conta? Cadastre-se'),
                ),
                const SizedBox(height: 12),
                const Text('Modo acadêmico: dados ficam no seu dispositivo. Para acessar de outros aparelhos, configure a API local.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
