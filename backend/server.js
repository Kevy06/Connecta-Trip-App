'use strict';
/** API REST do Connecta Trip; executável com Node >=20, sem npm install. */
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const DATA_FILE = process.env.DATA_FILE || path.join(__dirname, 'data', 'connecta.json');
const PORT = Number(process.env.PORT || 3000);
const DESTINOS = new Set(['1', '2', '3']);
const STATUS = new Set(['enviada', 'emAnalise', 'propostaRecebida', 'aceita', 'encerrada']);
function novoId(prefix) { return `${prefix}${crypto.randomUUID()}`; }
function erro(status, message) { const e = new Error(message); e.status = status; throw e; }
function lerDB() {
  try { return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')); }
  catch (e) {
    if (e.code === 'ENOENT') return {users: [], sessions: [], viagens: []};
    throw e;
  }
}
function salvarDB(db) {
  fs.mkdirSync(path.dirname(DATA_FILE), {recursive: true});
  const temp = DATA_FILE + '.tmp';
  fs.writeFileSync(temp, JSON.stringify(db, null, 2), {mode: 0o600});
  fs.renameSync(temp, DATA_FILE);
}
function hashSenha(password, salt) {
  return crypto.scryptSync(password, salt, 64).toString('hex');
}
function emitirSessao(db, user) {
  const token = crypto.randomBytes(32).toString('hex');
  db.sessions.push({hash: crypto.createHash('sha256').update(token).digest('hex'),
    uid: user.id, validade: Date.now() + 7 * 86400000});
  return token;
}
function publico(user) { return {id: user.id, nome: user.nome,
  email: user.email, perfil: user.perfil}; }
function autenticar(req, db) {
  const recebido = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  const hash = crypto.createHash('sha256').update(recebido).digest('hex');
  const sessao = db.sessions.find(s => s.hash === hash && s.validade > Date.now());
  const user = sessao && db.users.find(u => u.id === sessao.uid);
  if (!user) erro(401, 'Sessão ausente ou expirada. Entre novamente.');
  return user;
}
function validarTexto(s, min, max) { return typeof s === 'string' && s.trim().length >= min && s.length <= max; }
function exigirPapel(user, perfil) { if (user.perfil !== perfil) erro(403, `Apenas ${perfil} pode executar esta operação.`); }
function exigirViagem(db, id, user) {
  const viagem = db.viagens.find(v => v.id === id);
  if (!viagem || (user.perfil === 'viajante' && viagem.donoId !== user.id)) {
    erro(404, 'Solicitação não encontrada.');
  }
  return viagem;
}
function registrar(v, msg) { v.historico.push({quando: new Date().toISOString(), descricao: msg}); }
function resposta(res, status, objeto) {
  res.writeHead(status, {'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store'});
  res.end(JSON.stringify(objeto));
}
async function corpoJSON(req) {
  const partes = [];
  let tamanho = 0;
  for await (const parte of req) {
    tamanho += parte.length;
    if (tamanho > 65536) erro(413, 'Requisição grande demais.');
    partes.push(parte);
  }
  try { return JSON.parse(Buffer.concat(partes).toString('utf8') || '{}'); }
  catch (_) { erro(400, 'JSON inválido.'); }
}

async function handle(req, res) {
  // Durante desenvolvimento, libera somente origens locais do Flutter Web.
  const origem = req.headers.origin || '';
  const permitido = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origem);
  if (permitido) {
    res.setHeader('Access-Control-Allow-Origin', origem);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.writeHead(permitido ? 204 : 403);
    res.end();
    return;
  }
  try {
    const rota = new URL(req.url, 'http://localhost');
    const pathname = rota.pathname;
    const method = req.method;
    if (method === 'GET' && pathname === '/health') return resposta(res, 200,
      {ok: true, projeto: 'Connecta Trip', armazenamento: 'JSON local no servidor'});
    const db = lerDB();
    if (!Array.isArray(db.mensagens)) db.mensagens = [];
    const body = method === 'POST' ? await corpoJSON(req) : {};
    if (method === 'POST' && pathname === '/auth/register') {
      const {nome, senha, perfil} = body;
      const email = String(body.email || '').trim().toLowerCase();
      if (!validarTexto(nome, 3, 120) || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) ||
          !validarTexto(senha, 6, 200) || !['viajante', 'consultor'].includes(perfil)) {
        erro(400, 'Nome, e-mail, senha ou perfil inválidos.');
      }
      if (db.users.some(u => u.email === email)) erro(409, 'E-mail já cadastrado.');
      const salt = crypto.randomBytes(16).toString('hex');
      const user = {id: novoId('u'), nome: nome.trim(), email, perfil,
        salt, hash: hashSenha(senha, salt)};
      db.users.push(user);
      const token = emitirSessao(db, user);
      salvarDB(db);
      return resposta(res, 201, {usuario: publico(user), token});
    }
    if (method === 'POST' && pathname === '/auth/login') {
      const email = String(body.email || '').trim().toLowerCase();
      const user = db.users.find(u => u.email === email);
      if (!user || typeof body.senha !== 'string' ||
          !crypto.timingSafeEqual(Buffer.from(user.hash, 'hex'),
            Buffer.from(hashSenha(body.senha, user.salt), 'hex'))) {
        erro(401, 'E-mail ou senha incorretos.');
      }
      const token = emitirSessao(db, user);
      salvarDB(db);
      return resposta(res, 200, {usuario: publico(user), token});
    }
    const user = autenticar(req, db);
    if (method === 'GET' && pathname === '/me') return resposta(res, 200, {usuario: publico(user)});
    if (method === 'GET' && pathname === '/trips') return resposta(res, 200, {
      viagens: db.viagens.filter(v => user.perfil === 'consultor' || v.donoId === user.id),
    });
    if (method === 'POST' && pathname === '/trips') {
      exigirPapel(user, 'viajante');
      const inicio = new Date(body.inicio), fim = new Date(body.fim);
      const hoje = new Date(); hoje.setHours(0, 0, 0, 0);
      if (!DESTINOS.has(body.destinoId) || !Number.isFinite(inicio.getTime()) ||
          !Number.isFinite(fim.getTime()) || inicio < hoje || fim <= inicio ||
          !Number.isInteger(body.viajantes) || body.viajantes < 1 || body.viajantes > 20 ||
          !validarTexto(body.orcamento, 2, 80) || !Array.isArray(body.interesses) ||
          !body.interesses.length || !body.interesses.every(i =>
            ['Passagem', 'Hospedagem', 'Traslado', 'Seguro', 'Milhas'].includes(i)) ||
          typeof body.observacoes !== 'string' || body.observacoes.length > 500) {
        erro(400, 'Destino, datas, viajantes, orçamento ou serviços inválidos.');
      }
      const v = {
        id: novoId('v'), donoId: user.id, destinoId: body.destinoId,
        inicio: inicio.toISOString(), fim: fim.toISOString(),
        viajantes: body.viajantes, orcamento: body.orcamento,
        interesses: [...new Set(body.interesses)], observacoes: body.observacoes,
        criadaEm: new Date().toISOString(), status: 'enviada',
        roteiro: Array.isArray(body.roteiro) ? body.roteiro.slice(0, 10) : [],
        propostas: [], historico: [], propostaAceitaId: null, avaliacao: null,
      };
      registrar(v, `Solicitação enviada por ${user.nome}`);
      db.viagens.push(v); salvarDB(db);
      return resposta(res, 201, {viagem: v});
    }
    if (method === 'GET' && pathname === '/consultants') {
      return resposta(res, 200, {consultores: db.users.filter(u => u.perfil === 'consultor')
        .map(u => ({id: u.id, nome: u.nome, especialidade: 'Viagens personalizadas'}))});
    }
    if (method === 'GET' && pathname === '/messages') {
      return resposta(res, 200, {mensagens: db.mensagens.filter(m =>
        user.perfil === 'consultor' ? m.consultorId === user.id : m.viajanteId === user.id)});
    }
    if (method === 'POST' && pathname === '/messages') {
      exigirPapel(user, 'viajante');
      const consultor = db.users.find(u => u.id === body.consultorId && u.perfil === 'consultor');
      if (!consultor || !validarTexto(body.texto, 1, 1000) ||
          typeof body.assunto !== 'string' || body.assunto.length > 150) {
        erro(400, 'Consultor ou mensagem inválidos.');
      }
      const mensagem = {id: novoId('m'), viajanteId: user.id,
        consultorId: consultor.id, consultorNome: consultor.nome,
        assunto: body.assunto, texto: body.texto.trim(),
        criadaEm: new Date().toISOString(), resposta: null, respondidaEm: null};
      db.mensagens.push(mensagem); salvarDB(db);
      return resposta(res, 201, {mensagem});
    }
    const mresp = pathname.match(/^\/messages\/([^/]+)\/reply$/);
    if (method === 'POST' && mresp) {
      exigirPapel(user, 'consultor');
      const mensagem = db.mensagens.find(m => m.id === mresp[1]);
      if (!mensagem) erro(404, 'Mensagem não encontrada.');
      if (mensagem.consultorId !== user.id) erro(403, 'Mensagem de outro consultor.');
      if (mensagem.resposta != null || !validarTexto(body.resposta, 1, 1000)) {
        erro(409, 'Mensagem já respondida ou resposta inválida.');
      }
      mensagem.resposta = body.resposta.trim();
      mensagem.respondidaEm = new Date().toISOString();
      salvarDB(db);
      return resposta(res, 200, {mensagem});
    }
    const match = pathname.match(/^\/trips\/([^/]+)(?:\/(analyze|proposals|accept|close|review))?$/);
    if (!match) erro(404, 'Rota não encontrada.');
    const [, id, acao] = match;
    const v = exigirViagem(db, id, user);
    if (method === 'GET' && !acao) return resposta(res, 200, {viagem: v});
    if (method !== 'POST') erro(405, 'Método não permitido.');
    if (acao === 'analyze') {
      exigirPapel(user, 'consultor');
      if (v.status !== 'enviada') erro(409, 'Esta solicitação já saiu da fila inicial.');
      v.status = 'emAnalise';
      registrar(v, `Atendimento iniciado por ${user.nome}`);
    } else if (acao === 'proposals') {
      exigirPapel(user, 'consultor');
      const validade = new Date(body.validade);
      if (!['enviada', 'emAnalise', 'propostaRecebida'].includes(v.status) ||
          v.propostas.some(p => p.consultorId === user.id) ||
          !Number.isFinite(body.valorEstimado) || body.valorEstimado <= 0 || body.valorEstimado > 1e8 ||
          !Array.isArray(body.itensIncluidos) || !body.itensIncluidos.length ||
          !body.itensIncluidos.every(i => validarTexto(i, 1, 120)) ||
          !validarTexto(body.condicoes, 1, 1000) ||
          !Number.isFinite(validade.getTime()) || validade <= new Date()) {
        erro(400, 'Proposta inválida, repetida ou atendimento já finalizado.');
      }
      v.propostas.push({id: novoId('p'), consultorId: user.id,
        consultorNome: user.nome, consultorEspecialidade: 'Consultoria personalizada de viagens',
        valorEstimado: body.valorEstimado, itensIncluidos: body.itensIncluidos,
        condicoes: body.condicoes.trim(), validade: validade.toISOString()});
      v.status = 'propostaRecebida';
      registrar(v, `Proposta recebida de ${user.nome}`);
    } else if (acao === 'accept') {
      exigirPapel(user, 'viajante');
      const p = v.propostas.find(p => p.id === body.propostaId);
      if (v.status !== 'propostaRecebida' || !p || new Date(p.validade) < new Date()) {
        erro(409, 'Proposta não encontrada, vencida ou indisponível.');
      }
      v.propostaAceitaId = p.id;
      v.status = 'aceita';
      registrar(v, `Proposta de ${p.consultorNome} aceita`);
    } else if (acao === 'close') {
      exigirPapel(user, 'consultor');
      const escolhida = v.propostas.find(p => p.id === v.propostaAceitaId);
      if (v.status !== 'aceita' || !escolhida || escolhida.consultorId !== user.id) {
        erro(403, 'Somente o consultor da proposta aceita pode encerrar.');
      }
      v.status = 'encerrada';
      registrar(v, `Atendimento encerrado por ${user.nome}`);
    } else if (acao === 'review') {
      exigirPapel(user, 'viajante');
      if (v.status !== 'encerrada' || v.avaliacao || !Number.isInteger(body.nota) ||
          body.nota < 1 || body.nota > 5 || typeof body.comentario !== 'string' ||
          body.comentario.length > 500) erro(409, 'Avaliação não permitida.');
      v.avaliacao = {nota: body.nota, comentario: body.comentario.trim()};
      registrar(v, `Avaliação registrada: ${body.nota} estrela(s)`);
    } else { erro(404, 'Rota não encontrada.'); }
    salvarDB(db);
    return resposta(res, 200, {viagem: v});
  } catch (e) {
    return resposta(res, e.status || 500, {erro: e.status ? e.message : 'Erro interno no servidor.'});
  }
}

function iniciarServidor(port = PORT) { return http.createServer(handle).listen(port, '0.0.0.0'); }
if (require.main === module) {
  const server = iniciarServidor();
  server.on('listening', () => console.log(`Connecta Trip API: http://localhost:${server.address().port}`));
}
module.exports = {handle, iniciarServidor, lerDB, DATA_FILE};
